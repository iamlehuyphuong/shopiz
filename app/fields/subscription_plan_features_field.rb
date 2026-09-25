require 'administrate/field/base'

class SubscriptionPlanFeaturesField < Administrate::Field::Base
  def to_s
    data.to_json
  end

  def features_list
    Featurable::FEATURE_LIST
  end

  def categorized_features
    # Map all system features to their current enabled status in this plan
    all_features_hash = Featurable::FEATURE_LIST.pluck('name').index_with do |feature_name|
      feature_enabled?(feature_name)
    end

    SuperAdmin::AccountFeaturesHelper.categorized_features_hash(all_features_hash)
  end

  def feature_enabled?(feature_name)
    (data || {})[feature_name.to_s].to_s == 'true'
  end
end
