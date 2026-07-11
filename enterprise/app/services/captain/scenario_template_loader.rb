module Captain
  class ScenarioTemplateLoader
    class << self
      def templates_path
        Rails.root.join('enterprise', 'config', 'captain', 'scenario_templates.yml')
      end

      def load_templates
        return {} unless File.exist?(templates_path)

        YAML.load_file(templates_path) || {}
      end

      # Load a specific pack and create scenarios for the given assistant
      def apply_pack!(pack_key, assistant:, locale: I18n.default_locale)
        templates = load_templates
        pack = templates.dig('case_studies', pack_key.to_s)
        
        raise "Pack not found: #{pack_key}" unless pack

        account = assistant.account

        pack['scenarios'].each do |scenario_data|
          scenario_id = scenario_data['id']
          
          # Fetch translations based on locale
          title = I18n.t("captain.scenario_templates.case_studies.#{pack_key}.scenarios.#{scenario_id}.title", locale: locale)
          description = I18n.t("captain.scenario_templates.case_studies.#{pack_key}.scenarios.#{scenario_id}.description", locale: locale)
          instruction = I18n.t("captain.scenario_templates.case_studies.#{pack_key}.scenarios.#{scenario_id}.instruction", locale: locale)

          # Try to find existing scenario with the same title to avoid duplicates
          scenario = assistant.scenarios.find_or_initialize_by(title: title)
          
          scenario.assign_attributes(
            account: account,
            description: description,
            instruction: instruction,
            tools: scenario_data['tools'],
            enabled: true
          )

          scenario.save!
        end

        true
      end
    end
  end
end
