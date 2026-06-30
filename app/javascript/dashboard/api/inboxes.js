/* global axios */
import CacheEnabledApiClient from './CacheEnabledApiClient';

class Inboxes extends CacheEnabledApiClient {
  constructor() {
    super('inboxes', { accountScoped: true });
  }

  // eslint-disable-next-line class-methods-use-this
  get cacheModelName() {
    return 'inbox';
  }

  getCampaigns(inboxId) {
    return axios.get(`${this.url}/${inboxId}/campaigns`);
  }

  deleteInboxAvatar(inboxId) {
    return axios.delete(`${this.url}/${inboxId}/avatar`);
  }

  deleteBubbleAvatar(inboxId) {
    return axios.delete(`${this.url}/${inboxId}/bubble_avatar`);
  }

  deleteCloseBubbleAvatar(inboxId) {
    return axios.delete(`${this.url}/${inboxId}/close_bubble_avatar`);
  }

  getAgentBot(inboxId) {
    return axios.get(`${this.url}/${inboxId}/agent_bot`);
  }

  setAgentBot(inboxId, botId) {
    return axios.post(`${this.url}/${inboxId}/set_agent_bot`, {
      agent_bot: botId,
    });
  }

  syncTemplates(inboxId) {
    return axios.post(`${this.url}/${inboxId}/sync_templates`);
  }

  checkConnection(inboxId) {
    return axios.post(`${this.url}/${inboxId}/check_connection`);
  }

  syncFriends(inboxId) {
    return axios.post(`${this.url}/${inboxId}/sync_friends`);
  }

  createCSATTemplate(inboxId, template) {
    return axios.post(`${this.url}/${inboxId}/csat_template`, {
      template,
    });
  }

  getCSATTemplateStatus(inboxId) {
    return axios.get(`${this.url}/${inboxId}/csat_template`);
  }

  analyzeCSATTemplateUtility(inboxId, template) {
    return axios.post(`${this.url}/${inboxId}/csat_template/analyze`, {
      template,
    });
  }

  getNativeLabels(inboxId, fetch = false) {
    return axios.get(`${this.url}/${inboxId}/native_labels`, {
      params: { fetch },
    });
  }

  updateLabelMappings(inboxId, data) {
    return axios.post(`${this.url}/${inboxId}/label_mappings`, data);
  }
}

export default new Inboxes();
