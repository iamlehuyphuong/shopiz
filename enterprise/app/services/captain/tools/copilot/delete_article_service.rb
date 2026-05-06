class Captain::Tools::Copilot::DeleteArticleService < Captain::Tools::BaseTool
  def self.name
    'delete_article'
  end

  description 'Delete an article from the help center. This action is irreversible.'
  param :article_id, type: :integer, desc: 'ID of the article to delete', required: true

  def execute(article_id:)
    article = Article.find_by(id: article_id, account_id: @assistant.account_id)
    return 'Article not found' if article.nil?

    title = article.title
    portal_name = article.portal.name
    article.destroy!

    "Article '#{title}' from portal '#{portal_name}' has been deleted successfully."
  end

  def active?
    user_has_permission('knowledge_base_manage')
  end
end
