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

  importProducts(file) {
    const formData = new FormData();
    formData.append('import_file', file);
    return axios.post(`${this.url}/import`, formData, {
      headers: {
        'Content-Type': 'multipart/form-data',
      },
    });
  }

  exportProducts(payload) {
    return axios.post(`${this.url}/export`, payload);
  }
}

export default new SalesProducts();
