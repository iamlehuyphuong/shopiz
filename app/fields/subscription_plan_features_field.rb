require 'administrate/field/base'

class SubscriptionPlanFeaturesField < Administrate::Field::Base
  def to_s
    data.to_json
  end

  def features_list
    Featurable::FEATURE_LIST
  end

  def grouped_features
    raw_list = features_list
    
    groups = {
      'Channel' => [],
      'Basic' => [],
      'Enterprise' => []
    }
    
    raw_list.each do |feature|
      # next if feature['deprecated']
      
      if feature['name'].start_with?('channel_', 'whatsapp_') || feature['name'] == 'inbound_emails'
        groups['Channel'] << feature
      elsif feature['premium'] == true
        groups['Enterprise'] << feature
      else
        groups['Basic'] << feature
      end
    end
    
    groups.reject { |_k, v| v.empty? }
  end

  def feature_enabled?(feature_name)
    (data || {})[feature_name.to_s] == "true" || (data || {})[feature_name.to_s] == true
  end
end
