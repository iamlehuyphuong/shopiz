require 'administrate/field/base'

class SubscriptionPlanLimitsField < Administrate::Field::Base
  def to_s
    data.to_json
  end

  def limit_keys
    SubscriptionPlan::AVAILABLE_LIMIT_KEYS
  end

  def limit_value(key)
    (data || {})[key.to_s]
  end
end
