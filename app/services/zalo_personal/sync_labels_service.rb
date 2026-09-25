class ZaloPersonal::SyncLabelsService
  def initialize(inbox)
    @inbox = inbox
    @channel = inbox.channel
  end

  def perform
    return unless @channel.is_a?(Channel::ZaloPersonal)

    labels_data = fetch_labels_from_zalo
    return if labels_data.blank?

    sync_labels(labels_data)
  end

  private

  def fetch_labels_from_zalo
    body = { ownId: @channel.oa_id }

    res = HTTParty.post(
      "#{GlobalConfigService.load('ZALO_API_URL', nil)}/api/getLabels",
      headers: ZaloPersonal::ApiHelper.request_headers,
      body: body.to_json
    )

    return unless res['success']

    res.dig('data', 'labelData')
  rescue StandardError => e
    Rails.logger.error "ZaloPersonal SyncLabelsService fetch error for inbox #{@inbox.id}: #{e.message}"
    nil
  end

  def sync_labels(label_data)
    mappings = @inbox.inbox_label_mappings.includes(:label).to_a

    label_data.each do |zalo_label|
      native_label_id = zalo_label['id'].to_s
      conversations = zalo_label['conversations'] || []

      mapping = mappings.find { |m| m.native_label_id == native_label_id }
      next unless mapping && mapping.label

      shopiz_label = mapping.label

      # 1. Update Shopiz label status (color, description)
      update_shopiz_label(mapping, shopiz_label, zalo_label)

      # 2. Apply labels to conversations
      apply_label_to_conversations(shopiz_label, conversations)
    end
  end

  def update_shopiz_label(mapping, shopiz_label, zalo_label)
    mapping.update(native_label_name: zalo_label['text']) if zalo_label['text'].present? && mapping.native_label_name != zalo_label['text']

    updates = {}
    updates[:description] = zalo_label['text'] if zalo_label['text'].present?
    updates[:color] = zalo_label['color'] if zalo_label['color'].present?

    shopiz_label.update(updates) if updates.any?
  end

  def apply_label_to_conversations(shopiz_label, external_source_ids)
    target_conversation_ids = if external_source_ids.blank?
                                []
                              else
                                @inbox.conversations
                                      .left_joins(:contact_inbox)
                                      .where('conversations.external_source_id IN (:ids) OR contact_inboxes.source_id IN (:ids)', ids: external_source_ids)
                                      .pluck(:id)
                              end

    current_conversation_ids = @inbox.conversations.tagged_with(shopiz_label.title).pluck(:id)

    to_add_ids = target_conversation_ids - current_conversation_ids
    if to_add_ids.any?
      Conversation.where(id: to_add_ids).find_each do |conv|
        old_labels = conv.label_list.dup
        conv.label_list.add(shopiz_label.title)
        conv.save
        conv.send(:dispatch_label_update_event, old_labels, conv.label_list) if conv.respond_to?(:dispatch_label_update_event, true)
      end
    end

    to_remove_ids = current_conversation_ids - target_conversation_ids
    return unless to_remove_ids.any?

    Conversation.where(id: to_remove_ids).find_each do |conv|
      old_labels = conv.label_list.dup
      conv.label_list.remove(shopiz_label.title)
      conv.save
      conv.send(:dispatch_label_update_event, old_labels, conv.label_list) if conv.respond_to?(:dispatch_label_update_event, true)
    end
  end
end
