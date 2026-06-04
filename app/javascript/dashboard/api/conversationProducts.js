/* global axios */
import ApiClient from './ApiClient';

class ConversationProductsAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  getProducts(conversationId, { query, page, source } = {}) {
    const params = {};
    if (query) params.q = query;
    if (page) params.page = page;
    if (source) params.source = source;

    return axios.get(
      `${this.baseUrl()}/conversations/${conversationId}/products`,
      { params }
    );
  }
}

export default new ConversationProductsAPI();
