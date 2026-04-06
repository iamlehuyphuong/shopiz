/* global axios */
import ApiClient from '../ApiClient';

class TiktokShopClient extends ApiClient {
  constructor() {
    super('tiktok_shop', { accountScoped: true });
  }

  create(params) {
    return axios.post(
      `${this.url.replace(this.resource, '')}channels/tiktok_shop_channel`,
      params
    );
  }
}

export default new TiktokShopClient();
