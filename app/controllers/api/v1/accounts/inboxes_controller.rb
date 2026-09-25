class Api::V1::Accounts::InboxesController < Api::V1::Accounts::BaseController
  include Api::V1::InboxesHelper
  before_action :fetch_inbox, except: [:index, :create]
  before_action :fetch_agent_bot, only: [:set_agent_bot]
  before_action :validate_limit, only: [:create]
  # we are already handling the authorization in fetch inbox
  before_action :check_authorization, except: [:show]

  include Api::V1::Accounts::Concerns::WhatsappHealthManagement

  def index
    @inboxes = policy_scope(Current.account.inboxes.order_by_name.includes(index_includes))

    deleted_inbox_ids = $alfred.with { |conn| conn.smembers("deleted_inboxes_#{Current.account.id}") }

    return unless deleted_inbox_ids.any?

    @inboxes = @inboxes.where.not(id: deleted_inbox_ids)
  end

  def show; end

  # Deprecated: This API will be removed in 2.7.0
  def assignable_agents
    @assignable_agents = @inbox.assignable_agents
  end

  def campaigns
    @campaigns = @inbox.campaigns
  end

  def avatar
    @inbox.avatar.attachment.destroy! if @inbox.avatar.attached?
    head :ok
  end

  def bubble_avatar
    @inbox.channel.bubble_avatar.attachment.destroy! if @inbox.channel.bubble_avatar.attached?
    head :ok
  end

  def close_bubble_avatar
    @inbox.channel.close_bubble_avatar.attachment.destroy! if @inbox.channel.close_bubble_avatar.attached?
    head :ok
  end

  def sync_templates
    trigger_template_sync
    render status: :ok, json: { message: I18n.t('messages.template_sync_initiated') }
  rescue StandardError => e
    render status: :internal_server_error, json: { error: e.message }
  end

  def check_connection
    channel = @inbox.channel
    unless channel.respond_to?(:check_disconnection!)
      render status: :unprocessable_entity, json: { error: 'Channel does not support connection check' }
      return
    end

    channel.check_disconnection!
    render status: :ok, json: { reauthorization_required: channel.reauthorization_required? }
  rescue StandardError => e
    Rails.logger.error "check_connection failed for inbox #{@inbox.id}: #{e.message}"
    render status: :internal_server_error, json: { error: e.message }
  end

  def sync_friends
    unless @inbox.channel.is_a?(Channel::ZaloPersonal)
      render status: :unprocessable_entity, json: { error: 'Channel does not support syncing friends' }
      return
    end

    ZaloPersonal::SyncFriendsJob.perform_later(@inbox.id)
    render status: :ok, json: { message: I18n.t('messages.friends_sync_initiated', default: 'Friends sync has been initiated successfully') }
  rescue StandardError => e
    render status: :internal_server_error, json: { error: e.message }
  end

  def create
    ActiveRecord::Base.transaction do
      channel = create_channel
      @inbox = Current.account.inboxes.build(
        {
          name: inbox_name(channel),
          channel: channel
        }.merge(
          permitted_params.except(:channel)
        )
      )
      @inbox.save!
    end
  end

  def update
    if params[:auto_follow_up_config].is_a?(String)
      begin
        parsed_config = JSON.parse(params[:auto_follow_up_config])
        params[:auto_follow_up_config] = ActionController::Parameters.new(parsed_config)
      rescue JSON::ParserError
      end
    end

    inbox_params = permitted_params.except(:channel, :csat_config)
    inbox_params[:csat_config] = format_csat_config(permitted_params[:csat_config]) if permitted_params[:csat_config].present?

    begin
      @inbox.update!(inbox_params)
      update_inbox_working_hours
      update_channel if channel_update_required?
    rescue StandardError => e
      if params.key?(:ecommerce_integration_id)
        Rails.logger.error "\n[ECOMMERCE_INTEGRATION_ERROR] Failed to link ecommerce to inbox #{@inbox.id}"
        Rails.logger.error "Params: #{params.inspect}"
        Rails.logger.error "Inbox Params: #{inbox_params.inspect}"
        Rails.logger.error "Error Class: #{e.class}"
        Rails.logger.error "Error Message: #{e.message}"
        Rails.logger.error "Backtrace:\n#{e.backtrace.first(20).join("\n")}\n"
      end
      raise e
    end
  end

  def agent_bot
    @agent_bot = @inbox.agent_bot
  end

  def set_agent_bot
    if @agent_bot
      agent_bot_inbox = @inbox.agent_bot_inbox || AgentBotInbox.new(inbox: @inbox)
      agent_bot_inbox.agent_bot = @agent_bot
      agent_bot_inbox.save!
    elsif @inbox.agent_bot_inbox.present?
      @inbox.agent_bot_inbox.destroy!
    end
    head :ok
  end

  def destroy
    if @inbox.present?
      ::DeleteObjectJob.perform_later(@inbox, Current.user, request.ip)

      # Mark inbox as deleted in Redis to prevent it from showing up in the index
      $alfred.with do |conn|
        conn.sadd("deleted_inboxes_#{Current.account.id}", @inbox.id)
        conn.expire("deleted_inboxes_#{Current.account.id}", 1.day.to_i)
      end
    end
    render status: :ok, json: { message: I18n.t('messages.inbox_deletetion_response') }
  end

  def native_labels
    unless @inbox.channel.is_a?(Channel::ZaloPersonal)
      render json: { error: 'Not supported for this channel type' }, status: :unprocessable_entity and return
    end

    if ActiveModel::Type::Boolean.new.cast(params[:fetch])
      body = { ownId: @inbox.channel.oa_id }
      res = HTTParty.post(
        "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getLabels",
        headers: ZaloPersonal::ApiHelper.request_headers,
        body: body.to_json
      )

      parsed_res = begin
        JSON.parse(res.body)
      rescue StandardError
        {}
      end

      Rails.logger.info "[ZaloPersonal] getLabels response for inbox #{@inbox.id}: #{res.body}"

      if parsed_res['success']
        label_data = parsed_res.dig('data', 'labelData') || []

        mappings = @inbox.inbox_label_mappings.to_a

        label_data.each do |zalo_label|
          mapping = mappings.find { |m| m.native_label_id == zalo_label['id'].to_s }
          zalo_label['mapped_label_id'] = mapping&.label_id
        end

        render json: { data: label_data }, status: :ok
      else
        render json: { error: 'Failed to fetch labels from Zalo' }, status: :unprocessable_entity
      end
    else
      mappings = @inbox.inbox_label_mappings.includes(:label)
      label_data = mappings.map do |m|
        {
          id: m.native_label_id,
          text: m.native_label_name,
          color: m.label&.color || '#cccccc',
          mapped_label_id: m.label_id
        }
      end
      render json: { data: label_data }, status: :ok
    end
  rescue StandardError => e
    render json: { error: e.message }, status: :internal_server_error
  end

  def label_mappings
    mappings = params.permit(mappings: [:native_label_id, :native_label_name, :label_id, :color])[:mappings] || []

    Rails.logger.info "[ZaloPersonal] label_mappings called for inbox #{@inbox.id} with #{mappings.size} mappings"

    ActiveRecord::Base.transaction do
      mappings.each do |mapping|
        native_id = mapping[:native_label_id].to_s
        native_name = mapping[:native_label_name]
        label_id = mapping[:label_id]

        Rails.logger.info "[ZaloPersonal] Processing mapping: native_id=#{native_id}, native_name=#{native_name}, label_id=#{label_id}"

        if label_id.blank?
          sanitized_title = native_name.to_s.downcase.gsub(/\s+/, '_').gsub(/[^\p{L}\p{N}_-]/, '')
          Rails.logger.info "[ZaloPersonal] Creating/finding label with sanitized_title=#{sanitized_title}"
          label = Current.account.labels.find_or_create_by!(title: sanitized_title) do |l|
            l.color = mapping[:color].presence || '#E06720'
            l.description = native_name
          end
          label_id = label.id
        end

        inbox_mapping = @inbox.inbox_label_mappings.find_or_initialize_by(native_label_id: native_id)
        inbox_mapping.native_label_name = native_name
        inbox_mapping.label_id = label_id
        inbox_mapping.save!
      end
    end

    ZaloPersonal::SyncLabelsJob.perform_later(@inbox)

    render json: { message: I18n.t('messages.template_sync_initiated', default: 'Mappings updated and sync started') }, status: :ok
  rescue StandardError => e
    Rails.logger.error "[ZaloPersonal] label_mappings error for inbox #{@inbox.id}: #{e.class} - #{e.message}"
    Rails.logger.error e.backtrace&.first(5)&.join("\n")
    render json: { error: e.message }, status: :internal_server_error
  end

  private

  def fetch_inbox
    @inbox = Current.account.inboxes.find(params[:id])
    authorize @inbox, :show?
  end

  def trigger_template_sync
    if @inbox.whatsapp?
      Channels::Whatsapp::TemplatesSyncJob.perform_later(@inbox.channel)
    elsif @inbox.channel_type == 'Channel::ZaloOa'
      Channels::Zalo::TemplatesSyncJob.perform_later(@inbox.channel)
    elsif @inbox.channel_type == 'Channel::TiktokShop'
      Channels::TiktokShop::TemplatesSyncJob.perform_later(@inbox.channel)
    else
      raise StandardError, 'Template sync is only available for supported channels (WhatsApp, Zalo OA, TikTok Shop)'
    end
  end

  def fetch_agent_bot
    @agent_bot = AgentBot.find(params[:agent_bot]) if params[:agent_bot]
  end

  def create_channel
    return unless allowed_channel_types.include?(permitted_params[:channel][:type])

    account_channels_method.create!(permitted_params(channel_type_from_params::EDITABLE_ATTRS)[:channel].except(:type))
  end

  def allowed_channel_types
    %w[web_widget api telegram whatsapp]
  end

  def update_inbox_working_hours
    @inbox.update_working_hours(params.permit(working_hours: Inbox::OFFISABLE_ATTRS)[:working_hours]) if params[:working_hours]
  end

  def update_channel
    channel_attributes = get_channel_attributes(@inbox.channel_type)
    return if permitted_params(channel_attributes)[:channel].blank?

    reauthorize_and_update_channel(channel_attributes)
  end

  def channel_update_required?
    permitted_params(get_channel_attributes(@inbox.channel_type))[:channel].present?
  end

  def reauthorize_and_update_channel(channel_attributes)
    @inbox.channel.reauthorized! if @inbox.channel.respond_to?(:reauthorized!)
    @inbox.channel.update!(permitted_params(channel_attributes)[:channel])
  end

  def update_channel_feature_flags
    return unless @inbox.web_widget?
    return unless permitted_params(Channel::WebWidget::EDITABLE_ATTRS)[:channel].key? :selected_feature_flags

    @inbox.channel.selected_feature_flags = permitted_params(Channel::WebWidget::EDITABLE_ATTRS)[:channel][:selected_feature_flags]
    @inbox.channel.save!
  end

  def format_csat_config(config)
    formatted = {
      'display_type' => config['display_type'] || 'emoji',
      'message' => config['message'] || '',
      :survey_rules => {
        'operator' => config.dig('survey_rules', 'operator') || 'contains',
        'values' => config.dig('survey_rules', 'values') || []
      },
      'button_text' => config['button_text'] || 'Please rate us',
      'language' => config['language'] || 'en'
    }
    format_template_config(config, formatted)
    formatted
  end

  def format_template_config(config, formatted)
    formatted['template'] = config['template'] if config['template'].present?
  end

  def inbox_attributes
    [:name, :avatar, :greeting_enabled, :greeting_message, :csat_survey_enabled,
     :enable_auto_assignment, :working_hours_enabled, :out_of_office_message, :timezone, :allow_messages_after_resolved,
     :lock_to_single_conversation, :sender_name_type, :business_name, :ecommerce_integration_id, :auto_label_enabled, :label_suggestion_enabled,
     { auto_follow_up_config: [:enabled, :delay_seconds, :action_type, :ai_rewrite, :max_attempts, :interval_hours, :time_mode,
                               :fixed_time, :timezone, :predefined_message, :custom_ai_prompt, :macro_id,
                               { predefined_messages: [] }, { macros: [] }, { custom_ai_prompts: [] }] },
     { csat_config: [:display_type, :message, :button_text, :language,
                     { survey_rules: [:operator, { values: [] }],
                       template: [:name, :template_id, :created_at, :language, :status] }] },
     { sales_config: [:ai_allow_create_order, :platform,
                      { order_notification_templates: [:confirmed, :processing, :shipped, :delivered, :cancelled] }] },
     { zalo_auto_message_config: [:zalo_auto_message_enabled, { zalo_auto_message_inbox_ids: [] }] }]
  end

  def permitted_params(channel_attributes = [])
    # We will remove this line after fixing https://linear.app/chatwoot/issue/CW-1567/null-value-passed-as-null-string-to-backend
    sanitized_params = params.deep_dup
    sanitized_params.each { |k, v| sanitized_params[k] = nil if v == 'null' }
    sanitized_params.permit(*inbox_attributes, channel: [:type, *channel_attributes])
  end

  def index_includes
    [:channel, :agent_bot_inbox, :hooks, :ecommerce_integration, { avatar_attachment: [:blob] }]
  end

  def channel_type_from_params
    {
      'web_widget' => Channel::WebWidget,
      'api' => Channel::Api,
      'telegram' => Channel::Telegram,
      'whatsapp' => Channel::Whatsapp
    }[permitted_params[:channel][:type]]
  end

  def get_channel_attributes(channel_type)
    channel_type.constantize.const_defined?(:EDITABLE_ATTRS) ? channel_type.constantize::EDITABLE_ATTRS.presence : []
  end
end
