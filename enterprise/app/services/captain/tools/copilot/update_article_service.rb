class Captain::Tools::Copilot::UpdateArticleService < Captain::Tools::BaseTool
  def self.name
    'update_article'
  end

  description 'Update an existing article in the help center'
  param :article_id, type: :integer, desc: 'ID of the article to update', required: true
  param :title, type: :string, desc: 'New title for the article', required: false
  param :content, type: :string, desc: 'New content/body for the article (supports HTML)', required: false
  param :description, type: :string, desc: 'New short description/summary', required: false
  param :category_id, type: :integer, desc: 'New category ID to move the article to', required: false
  param :status, type: :string, desc: 'New status - MUST BE ONE OF: draft, published, archived', required: false

  def execute(**params)
    article = Article.find_by(id: params[:article_id], account_id: @assistant.account_id)
    return 'Article not found' if article.nil?

    update_params = build_update_params(params)
    return 'No fields to update. Provide at least one field to change.' if update_params.empty?

    article.update!(update_params)

    <<~RESPONSE
      Article updated successfully!
      #{article.reload.to_llm_text}
    RESPONSE
  rescue ActiveRecord::RecordInvalid => e
    "Failed to update article: #{e.message}"
  end

  def active?
    user_has_permission('knowledge_base_manage')
  end

  private

  def build_update_params(params)
    result = {}
    %i[title content description category_id status].each do |key|
      result[key] = params[key] if params[key].present?
    end
    result
  end
end
