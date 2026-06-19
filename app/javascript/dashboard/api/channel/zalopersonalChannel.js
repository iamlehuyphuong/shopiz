/* global axios */
import ApiClient from '../ApiClient';

class ZaloPersonalChannel extends ApiClient {
  constructor() {
    super('zalopersonal_indicators', { accountScoped: true });
  }

  create(params) {
    return axios.post(
      `${this.url.replace(this.resource, '')}channels/zalo_personal_channel`,
      params
    );
  }

  generateQR(params) {
    return axios.post(
      `${this.url.replace(this.resource, '')}channels/zalo_personal_channel/generate_qr`,
      params
    );
  }

  reauthorizeZaloOa({ omniauthToken, inboxId }) {
    return axios.post(`${this.baseUrl()}/zalopersonal/reauthorize_oa`, {
      omniauth_token: omniauthToken,
      inbox_id: inboxId,
    });
  }
}

export default new ZaloPersonalChannel();
