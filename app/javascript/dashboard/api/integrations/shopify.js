/* global axios */

import ApiClient from '../ApiClient';

class ShopifyAPI extends ApiClient {
  constructor() {
    super('integrations/shopify', { accountScoped: true });
  }

  getOrders(contactId) {
    return axios.get(`${this.url}/orders`, {
      params: { contact_id: contactId },
    });
  }

  getProducts() {
    return axios.get(`${this.url}/products`);
  }
}

export default new ShopifyAPI();
