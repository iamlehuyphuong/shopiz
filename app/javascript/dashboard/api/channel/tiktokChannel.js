/* global axios */
import ApiClient from '../ApiClient';

class TiktokClient extends ApiClient {
  constructor() {
    super('tiktok', { accountScoped: true });
  }

  create(params) {
    return axios.post(
      `${this.url.replace(this.resource, '')}channels/tiktok_channel`,
      params
    );
  }
}

export default new TiktokClient();
