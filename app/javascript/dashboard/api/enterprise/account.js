/* global axios */
import ApiClient from '../ApiClient';

class EnterpriseAccountAPI extends ApiClient {
  constructor() {
    super('', { accountScoped: true, enterprise: true });
  }

  checkout(paymentInfo) {
    return axios.post(`${this.url}checkout`, paymentInfo);
  }

  subscription() {
    return axios.post(`${this.url}subscription`);
  }

  getLimits() {
    return axios.get(`${this.url}limits`);
  }

  getPlans() {
    return axios.get(`${this.url}plans`);
  }

  toggleDeletion(action) {
    return axios.post(`${this.url}toggle_deletion`, {
      action_type: action,
    });
  }
}

export default new EnterpriseAccountAPI();
