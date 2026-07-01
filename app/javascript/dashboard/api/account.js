/* global axios */
import ApiClient from './ApiClient';

class AccountAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true });
  }

  createAccount(data) {
    return axios.post(`${this.apiVersion}/accounts`, data);
  }

  async getCacheKeys() {
    const response = await axios.get(
      `/api/v1/accounts/${this.accountIdFromRoute}/cache_keys`
    );
    return response.data.cache_keys;
  }

  getOrderAnalytics(accountId, params = {}) {
    return axios.get(`/api/v1/accounts/${accountId}/order_analytics`, {
      params,
    });
  }

  testEmail(email) {
    return axios.post(`/api/v1/accounts/${this.accountIdFromRoute}/test_email`, { email });
  }
}

export default new AccountAPI();
