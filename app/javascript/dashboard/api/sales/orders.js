/* global axios */
import ApiClient from '../ApiClient';

class SalesOrders extends ApiClient {
  constructor() {
    super('sales/orders', { accountScoped: true });
  }

  sync(platform, timeframe = '1_month') {
    return axios.post(`${this.url}/sync`, { platform, timeframe });
  }
}

export default new SalesOrders();
