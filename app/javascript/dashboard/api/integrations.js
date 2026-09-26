/* global axios */

import ApiClient from './ApiClient';

class IntegrationsAPI extends ApiClient {
  constructor() {
    super('integrations/apps', { accountScoped: true });
  }

  delete(integrationId) {
    return axios.delete(`${this.baseUrl()}/integrations/${integrationId}`);
  }

  createHook(hookData) {
    return axios.post(`${this.baseUrl()}/integrations/hooks`, hookData);
  }

  deleteHook(hookId) {
    return axios.delete(`${this.baseUrl()}/integrations/hooks/${hookId}`);
  }

  updateHook(hookId, hookData) {
    return axios.patch(
      `${this.baseUrl()}/integrations/hooks/${hookId}`,
      hookData
    );
  }

  connectShopify({ shopDomain }) {
    return axios.post(`${this.baseUrl()}/integrations/shopify/auth`, {
      shop_domain: shopDomain,
    });
  }

  connectKiotviet({ clientId, clientSecret, retailer }) {
    return axios.post(`${this.baseUrl()}/integrations/kiotviet/auth`, {
      client_id: clientId,
      client_secret: clientSecret,
      retailer,
    });
  }

  disconnectKiotviet() {
    return axios.delete(`${this.baseUrl()}/integrations/kiotviet`);
  }

  connectHaravan({ apiKey, storeName }) {
    return axios.post(`${this.baseUrl()}/integrations/haravan/auth`, {
      api_key: apiKey,
      store_name: storeName,
    });
  }

  disconnectHaravan() {
    return axios.delete(`${this.baseUrl()}/integrations/haravan`);
  }

  connectWoocommerce({ storeUrl, consumerKey, consumerSecret }) {
    return axios.post(`${this.baseUrl()}/integrations/woocommerce/auth`, {
      store_url: storeUrl,
      consumer_key: consumerKey,
      consumer_secret: consumerSecret,
    });
  }

  disconnectWoocommerce() {
    return axios.delete(`${this.baseUrl()}/integrations/woocommerce`);
  }

  connectSapo({ accessToken, storeName }) {
    return axios.post(`${this.baseUrl()}/integrations/sapo/auth`, {
      access_token: accessToken,
      store_name: storeName,
    });
  }

  disconnectSapo() {
    return axios.delete(`${this.baseUrl()}/integrations/sapo`);
  }

  connectNhanhvn({ appId, accessToken, businessId }) {
    return axios.post(`${this.baseUrl()}/integrations/nhanhvn/auth`, {
      app_id: appId,
      access_token: accessToken,
      business_id: businessId,
    });
  }

  disconnectNhanhvn() {
    return axios.delete(`${this.baseUrl()}/integrations/nhanhvn`);
  }

  connectGoogleCalendar() {
    return axios.post(
      `${this.baseUrl()}/integrations/google_calendar/authorization`
    );
  }

  disconnectGoogleCalendar(integrationId) {
    return axios.delete(
      `${this.baseUrl()}/calendar_integrations/${integrationId}`
    );
  }
}

export default new IntegrationsAPI();
