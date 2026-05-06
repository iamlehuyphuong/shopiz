import ApiClient from '../ApiClient';

class SalesOrders extends ApiClient {
  constructor() {
    super('sales/orders', { accountScoped: true });
  }
}

export default new SalesOrders();
