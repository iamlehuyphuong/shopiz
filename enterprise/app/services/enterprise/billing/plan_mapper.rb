class Enterprise::Billing::PlanMapper
  DURATIONS = { 0 => '1T', 1 => '6T', 2 => '12T' }.freeze
  PLAN_MAPPING = { 'STARTER' => 'Startups', 'PRO' => 'Pro', 'BUSINESS' => 'Business', 'ENTERPRISE' => 'Enterprise' }.freeze

  class << self
    def get_duration(product_id)
      plans.each do |plan|
        plan['product_id'].each_with_index do |pid, idx|
          return "#{DURATIONS[idx]}" if pid == product_id
        end
      end

      nil
    end

    def get_product_id(name, duration)
      idx = DURATIONS.key(duration)
      plan_name = PLAN_MAPPING[name]
      plan = plans.find { |p| p['name'] == plan_name }
      return nil unless plan && idx && plan['product_id'][idx]

      plan['product_id'][idx]
    end

    private

    def plans
      @plans ||= InstallationConfig.find_by(name: 'CHATWOOT_CLOUD_PLANS').value
    end
  end
end
