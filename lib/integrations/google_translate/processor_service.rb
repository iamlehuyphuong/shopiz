require 'google/cloud/translate/v3'

class Integrations::GoogleTranslate::ProcessorService
  pattr_initialize [:message!, :target_language!]

  def perform
    return if hook.blank?

    content = translation_content
    return if content.blank?

    response = client.translate_text(
      contents: [content],
      target_language_code: bcp47_language_code,
      parent: "projects/#{hook.merged_settings['project_id']}",
      mime_type: mime_type
    )

    return if response.translations.first.blank?

    response.translations.first.translated_text
  end

  private

  def bcp47_language_code
    target_language.tr('_', '-')
  end

  def translation_content
    message.content
  end

  def mime_type
    'text/plain'
  end

  def hook
    @hook ||= message.account.hooks.find_by(app_id: 'google_translate')
  end

  def client
    @client ||= ::Google::Cloud::Translate::V3::TranslationService::Client.new do |config|
      config.credentials = hook.merged_settings['credentials']
    end
  end
end
