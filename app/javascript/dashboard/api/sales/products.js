import ApiClient from '../ApiClient';

class SalesProducts extends ApiClient {
  constructor() {
    super('sales/products', { accountScoped: true });
  }
}

export default new SalesProducts();
