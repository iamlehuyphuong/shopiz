/* global axios */

import ApiClient from '../ApiClient';

class OmicallAPI extends ApiClient {
  constructor() {
    super('integrations/omicall', { accountScoped: true });
  }

  getCallHistory({ phoneNumber, page = 1, size = 50 }) {
    return axios.post(`${this.url}/call_history`, {
      phone_number: phoneNumber,
      page,
      size,
    });
  }
}

export default new OmicallAPI();
