/* global axios */
import ApiClient from './ApiClient';

class ConversationProductsAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  getCategories(conversationId) {
    return axios.get(
      `${this.baseUrl()}/conversations/${conversationId}/products`,
      { params: { categories: true } }
    );
  }

  getProducts(conversationId, { query, categoryId, page } = {}) {
    const params = {};
    if (query) params.q = query;
    if (categoryId) params.category_id = categoryId;
    if (page) params.page = page;

    return axios.get(
      `${this.baseUrl()}/conversations/${conversationId}/products`,
      { params }
    );
  }
}

export default new ConversationProductsAPI();
