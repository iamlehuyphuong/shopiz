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

  activateTrial() {
    return axios.post(`${this.url}activate_trial`);
  }

  getLimits() {
    return axios.get(`${this.url}limits`);
  }

  getBillings() {
    return axios.get(`${this.url}billings`);
  }

  toggleDeletion(action) {
    return axios.post(`${this.url}toggle_deletion`, {
      action_type: action,
    });
  }

  createTopupCheckout(credits) {
    return axios.post(`${this.url}topup_checkout`, { credits });
  }
}

export default new EnterpriseAccountAPI();
