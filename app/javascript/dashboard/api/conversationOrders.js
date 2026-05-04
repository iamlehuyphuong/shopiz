/* global axios */
import ApiClient from './ApiClient';

class ConversationOrdersAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  getOrders(conversationId) {
    return axios.get(
      `${this.baseUrl()}/conversations/${conversationId}/orders`
    );
  }

  createOrder(conversationId, orderData) {
    return axios.post(
      `${this.baseUrl()}/conversations/${conversationId}/orders`,
      orderData
    );
  }

  updateOrder(conversationId, orderId, orderData) {
    return axios.patch(
      `${this.baseUrl()}/conversations/${conversationId}/orders/${orderId}`,
      orderData
    );
  }

  deleteOrder(conversationId, orderId) {
    return axios.delete(
      `${this.baseUrl()}/conversations/${conversationId}/orders/${orderId}`
    );
  }

  pushOrder(conversationId, orderId) {
    return axios.post(
      `${this.baseUrl()}/conversations/${conversationId}/orders/${orderId}/push`
    );
  }

  syncOrder(conversationId, orderId) {
    return axios.post(
      `${this.baseUrl()}/conversations/${conversationId}/orders/${orderId}/sync`
    );
  }

  searchProducts(query) {
    return axios.get(`${this.baseUrl()}/products_search`, {
      params: { q: query },
    });
  }
}

export default new ConversationOrdersAPI();
