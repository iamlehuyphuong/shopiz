/* global axios */
import ApiClient from '../ApiClient';

class SalesReports extends ApiClient {
  constructor() {
    super('sales/reports', { accountScoped: true });
  }

  getReports(params) {
    return axios.get(this.url, { params });
  }

  getHeatmap(params) {
    return axios.get(`${this.url}/heatmap`, { params });
  }
}

export default new SalesReports();
