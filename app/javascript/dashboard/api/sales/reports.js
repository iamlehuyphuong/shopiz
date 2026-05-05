import ApiClient from '../ApiClient';

class SalesReports extends ApiClient {
  constructor() {
    super('sales/reports', { accountScoped: true });
  }
}

export default new SalesReports();
