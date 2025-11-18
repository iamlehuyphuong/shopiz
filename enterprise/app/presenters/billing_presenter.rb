class BillingPresenter
  def initialize(account)
    @account = account
  end

  def json_data
    {
      usage: usage_data,
      plans: plans_data,
      trial_plan: trial_data,
      enterprise_plan: enterprise_data,
      credits: credit_data,
      billing_histories: billing_histories_data,
      disabled_register_trial: disabled_register_trial
    }
  end

  private

  def custom_attributes
    @custom_attributes ||= @account.custom_attributes
  end

  def usage_data
    {
      agents: usage_agent,
      inboxes: usage_inbox,
      contacts: usage_contact,
      automations: usage_automation,
      captain_documents: usage_captain_document,
      captain_faqs: usage_captain_faq,
      captain_assistants: usage_captain_assistant,
      captain_credit: usage_captain_credit
    }
  end

  def plans_data
    %w[starter pro biz].index_with do |tier|
      %w[6 12].map { |m| normalize_plan(Polar::ProductService.by_name("#{tier}#{m}")) }
    end
  end

  def normalize_plan(plan)
    return {} unless plan

    sku = plan.dig('metadata', 'sku')
    {
      id: plan['id'],
      name: plan['name'],
      sku: sku,
      price: plan['prices'][0],
      description: plan['description'],
      benefits: plan['benefits']
    }
  end

  def trial_data
    normalize_plan(Polar::ProductService.by_name('trial'))
  end

  def enterprise_data
    normalize_plan(Polar::ProductService.by_name('premium'))
  end

  def credit_data
    data = Polar::ProductService.by_type('credit')
    data = data.sort_by { |item| item.dig('metadata', 'captain_responses_credit').to_i }

    data.map(&method(:normalize_credit))
  end

  def normalize_credit(credit)
    credit.slice('id', 'name', 'description').merge(price: credit['prices'][0])
  end

  def billing_histories_data
    I18n.with_locale(@account.locale || :en) do
      @account.billing_histories.order(id: :asc).as_json(
        only: [:id, :status],
        methods: [:status_text, :amount_formatted, :created_date_formatted, :content]
      )
    end
  end

  def disabled_register_trial
    @account.billing_histories.exists?(sku: 'trial')
  end

  def usage_agent
    format_percent(@account.agents.count, @account.limits['agents'])
  end

  def usage_inbox
    format_percent(@account.inboxes.count, @account.limits['inboxes'])
  end

  def usage_contact
    format_percent(@account.contacts.count, @account.limits['contacts'])
  end

  def usage_automation
    format_percent(@account.automation_rules.count, @account.limits['automations'])
  end

  def usage_captain_document
    format_percent(@account.captain_documents.count, @account.limits['captain_documents'])
  end

  def usage_captain_faq
    format_percent(@account.captain_assistant_responses.count, @account.limits['captain_responses'])
  end

  def usage_captain_assistant
    format_percent(@account.captain_assistants.count, @account.limits['captain_responses'])
  end

  def usage_captain_credit
    format_percent(@account.custom_attributes['captain_responses_usage'], @account.limits['captain_responses_credit'])
  end

  def format_percent(usage, limit)
    usage = usage.to_i
    limit = limit.to_i
    return 0 if limit.blank?

    [usage, limit].join(' / ')
  end
end
