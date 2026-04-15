class Captain::Tools::Copilot::CreateArticleService < Captain::Tools::BaseTool
  def self.name
    'create_article'
  end

  description 'Create a new article in a help center portal'
  param :portal_slug, type: :string, desc: 'The slug of the portal to create the article in', required: true
  param :title, type: :string, desc: 'Title of the article', required: true
  param :content, type: :string, desc: 'Full content/body of the article (supports HTML)', required: true
  param :description, type: :string, desc: 'Short description/summary of the article', required: false
  param :category_id, type: :integer, desc: 'ID of the category to assign the article to', required: false
  param :status, type: :string, desc: 'Article status - MUST BE ONE OF: draft, published, archived. Defaults to draft', required: false
  param :locale, type: :string, desc: 'Locale code for the article (e.g. en, vi). Defaults to portal default locale', required: false

  def execute(**params)
    portal = Portal.find_by(slug: params[:portal_slug], account_id: @assistant.account_id)
    return 'Portal not found' if portal.nil?

    author = resolve_author
    return 'No author available to create article' if author.nil?

    article = portal.articles.create!(build_article_params(params, author))

    <<~RESPONSE
      Article created successfully!
      #{article.to_llm_text}
    RESPONSE
  rescue ActiveRecord::RecordInvalid => e
    "Failed to create article: #{e.message}"
  end

  def active?
    user_has_permission('knowledge_base_manage')
  end

  private

  def resolve_author
    @user || User.joins(:account_users).where(account_users: { account_id: @assistant.account_id }).first
  end

  def build_article_params(params, author)
    result = { title: params[:title], content: params[:content], author_id: author.id }
    %i[description category_id status locale].each do |key|
      result[key] = params[key] if params[key].present?
    end
    result
  end
end
