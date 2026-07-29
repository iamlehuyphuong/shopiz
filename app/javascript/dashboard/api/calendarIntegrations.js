/* global axios */

import ApiClient from './ApiClient';

class CalendarIntegrationsAPI extends ApiClient {
  constructor() {
    super('calendar_integrations', { accountScoped: true });
  }

  get() {
    return axios.get(this.url);
  }

  delete(integrationId) {
    return axios.delete(`${this.url}/${integrationId}`);
  }
}

export default new CalendarIntegrationsAPI();
