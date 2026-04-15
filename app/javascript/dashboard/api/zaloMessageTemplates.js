import ApiClient from './ApiClient';

class ZaloMessageTemplatesAPI extends ApiClient {
  constructor() {
    super('zalo_message_templates', { accountScoped: true });
  }

  getByChannel(channelId) {
    return this.axios.get(this.url, {
      params: { channel_id: channelId },
    });
  }
}

export default new ZaloMessageTemplatesAPI();
