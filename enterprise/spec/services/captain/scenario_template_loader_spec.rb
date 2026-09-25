require 'rails_helper'

RSpec.describe Captain::ScenarioTemplateLoader do
  let(:account) { create(:account) }
  let(:assistant) { create(:captain_assistant, account: account) }

  before do
    allow_any_instance_of(Captain::Assistant).to receive(:available_tool_ids).and_return(
      %w[faq_lookup lookup_order initiate_return handoff book_appointment manage_appointment]
    )
  end

  describe '.load_templates' do
    it 'loads templates from the yaml file' do
      templates = described_class.load_templates
      expect(templates).to be_a(Hash)
      expect(templates.keys).to include('case_studies')
      expect(templates['case_studies'].keys).to include('ecommerce_pack', 'spa_pack')
    end
  end

  describe '.apply_pack!' do
    context 'when pack exists' do
      it 'creates scenarios for the assistant' do
        expect do
          described_class.apply_pack!('ecommerce_pack', assistant: assistant)
        end.to change { assistant.scenarios.count }.by(4)

        # Audit some values of the created scenarios
        scenario = assistant.scenarios.find_by(title: 'Sales Assistant & General FAQ')
        expect(scenario).to be_present
        expect(scenario.tools).to include('faq_lookup')
        expect(scenario.instruction).to include('[faq_lookup](tool://faq_lookup)')
      end

      it 'does not duplicate scenarios if applied twice' do
        described_class.apply_pack!('ecommerce_pack', assistant: assistant)

        expect do
          described_class.apply_pack!('ecommerce_pack', assistant: assistant)
        end.not_to(change { assistant.scenarios.count })
      end
    end

    context 'when pack does not exist' do
      it 'raises an error' do
        expect do
          described_class.apply_pack!('non_existent_pack', assistant: assistant)
        end.to raise_error(RuntimeError, /Pack not found: non_existent_pack/)
      end
    end
  end
end
