## Class to generate sample inboxes for a chatwoot test @Account.
############################################################
### Usage #####
#
#   # Seed an account with all data types in this class
#   Seeders::InboxSeeder.new(account: @Account.find(1), company_data:  {name: 'Shopiz', doamin: 'shopiz.pro'}).perform!
#
#
############################################################

class Seeders::InboxSeeder
  def initialize(account:, company_data:)
    raise 'Inbox Seeding is not allowed in production.' unless ENV.fetch('ENABLE_ACCOUNT_SEEDING', !Rails.env.production?)

    @account = account
    @company_data = company_data
  end

  def perform!
    seed_website_inbox
    seed_facebook_inbox
    seed_whatsapp_inbox
    seed_api_inbox
    seed_telegram_inbox
  end

  def seed_website_inbox
    channel = Channel::WebWidget.create!(account: @account, website_url: "https://#{@company_data['domain']}")
    Inbox.create!(
      channel: channel,
      account: @account,
      name: "#{@company_data['name']} Website",
      csat_survey_enabled: true,
      csat_config: {
        'display_type' => 'emoji',
        'message' => 'How would you rate your experience?'
      }
    )
  end

  def seed_facebook_inbox
    channel = Channel::FacebookPage.create!(account: @account, user_access_token: SecureRandom.hex, page_access_token: SecureRandom.hex,
                                            page_id: SecureRandom.hex)
    Inbox.create!(
      channel: channel,
      account: @account,
      name: "#{@company_data['name']} Facebook",
      csat_survey_enabled: true,
      csat_config: {
        'display_type' => 'star',
        'message' => 'Please rate your support experience'
      }
    )
  end

  def seed_whatsapp_inbox
    # rubocop:disable Rails/SkipsModelValidations
    Channel::Whatsapp.insert(
      {
        account_id: @account.id,
        phone_number: Faker::PhoneNumber.cell_phone_in_e164,
        created_at: Time.now.utc,
        updated_at: Time.now.utc
      },
      returning: %w[id]
    )
    # rubocop:enable Rails/SkipsModelValidations

    channel = Channel::Whatsapp.find_by(account_id: @account.id)

    Inbox.create!(channel: channel, account: @account, name: "#{@company_data['name']} Whatsapp")
  end

  def seed_api_inbox
    channel = Channel::Api.create!(account: @account)
    Inbox.create!(channel: channel, account: @account, name: "#{@company_data['name']} API")
  end

  def seed_telegram_inbox
    # rubocop:disable Rails/SkipsModelValidations
    bot_token = SecureRandom.hex
    Channel::Telegram.insert(
      {
        account_id: @account.id,
        bot_name: (@company_data['name']).to_s,
        bot_token: bot_token,
        created_at: Time.now.utc,
        updated_at: Time.now.utc
      },
      returning: %w[id]
    )
    channel = Channel::Telegram.find_by(bot_token: bot_token)
    Inbox.create!(channel: channel, account: @account, name: "#{@company_data['name']} Telegram")
    # rubocop:enable Rails/SkipsModelValidations
  end
end
