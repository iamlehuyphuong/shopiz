/* global axios */
import ApiClient from '../ApiClient';

class SalesProducts extends ApiClient {
  constructor() {
    super('sales/products', { accountScoped: true });
  }

  get(params = {}) {
    return axios.get(this.url, { params });
  }

  sync(platform) {
    return axios.post(`${this.url}/sync`, { platform });
  }
}

export default new SalesProducts();
