import { parseBoolean } from '@chatwoot/utils';
import { resolveMaximumFileUploadSize } from 'shared/helpers/FileHelper';

const {
  API_CHANNEL_NAME: apiChannelName,
  API_CHANNEL_THUMBNAIL: apiChannelThumbnail,
  APP_VERSION: appVersion,
  BRAND_NAME: brandName,
  CHATWOOT_INBOX_TOKEN: chatwootInboxToken,
  CREATE_NEW_ACCOUNT_FROM_DASHBOARD: createNewAccountFromDashboard,
  DIRECT_UPLOADS_ENABLED: directUploadsEnabled,
  DISPLAY_MANIFEST: displayManifest,
  GIT_SHA: gitSha,
  MAXIMUM_FILE_UPLOAD_SIZE: maximumFileUploadSize,
  HCAPTCHA_SITE_KEY: hCaptchaSiteKey,
  INSTALLATION_NAME: installationName,
  LOGO_THUMBNAIL: logoThumbnail,
  LOGO: logo,
  LOGO_DARK: logoDark,
  PRIVACY_URL: privacyURL,
  IS_ENTERPRISE: isEnterprise,
  TERMS_URL: termsURL,
  WIDGET_BRAND_URL: widgetBrandURL,
  DISABLE_USER_PROFILE_UPDATE: disableUserProfileUpdate,
  DEPLOYMENT_ENV: deploymentEnv,
  ENABLE_CHANNEL_FACEBOOK: enableChannelFacebook,
  ENABLE_CHANNEL_ZALO_OA: enableChannelZaloOa,
  ENABLE_CHANNEL_ZALO_PERSONAL: enableChannelZaloPersonal,
  ENABLE_CHANNEL_TIKTOK: enableChannelTiktok,
  ENABLE_CHANNEL_TIKTOK_SHOP: enableChannelTiktokShop,
  ENABLE_CHANNEL_WHATSAPP: enableChannelWhatsapp,
  ENABLE_CHANNEL_INSTAGRAM: enableChannelInstagram,
  ENABLE_CHANNEL_TELEGRAM: enableChannelTelegram,
  ENABLE_CHANNEL_LINE: enableChannelLine,
  ENABLE_CHANNEL_TWITTER: enableChannelTwitter,
  ENABLE_CHANNEL_WEBSITE: enableChannelWebsite,
} = window.globalConfig || {};

const state = {
  apiChannelName,
  apiChannelThumbnail,
  appVersion,
  brandName,
  chatwootInboxToken,
  deploymentEnv,
  createNewAccountFromDashboard,
  directUploadsEnabled: parseBoolean(directUploadsEnabled),
  disableUserProfileUpdate: parseBoolean(disableUserProfileUpdate),
  displayManifest,
  gitSha,
  maximumFileUploadSize: resolveMaximumFileUploadSize(maximumFileUploadSize),
  hCaptchaSiteKey,
  installationName,
  logo,
  logoDark,
  logoThumbnail,
  privacyURL,
  termsURL,
  widgetBrandURL,
  isEnterprise: parseBoolean(isEnterprise),
  enableChannelFacebook: parseBoolean(enableChannelFacebook ?? true),
  enableChannelZaloOa: parseBoolean(enableChannelZaloOa ?? true),
  enableChannelZaloPersonal: parseBoolean(enableChannelZaloPersonal ?? true),
  enableChannelTiktok: parseBoolean(enableChannelTiktok ?? true),
  enableChannelTiktokShop: parseBoolean(enableChannelTiktokShop ?? true),
  enableChannelWhatsapp: parseBoolean(enableChannelWhatsapp ?? true),
  enableChannelInstagram: parseBoolean(enableChannelInstagram ?? true),
  enableChannelTelegram: parseBoolean(enableChannelTelegram ?? true),
  enableChannelLine: parseBoolean(enableChannelLine ?? true),
  enableChannelTwitter: parseBoolean(enableChannelTwitter ?? true),
  enableChannelWebsite: parseBoolean(enableChannelWebsite ?? true),
};

export const getters = {
  get: $state => $state,
  isOnChatwootCloud: $state => $state.deploymentEnv === 'cloud',
  isACustomBrandedInstance: $state => $state.installationName !== 'Chatwoot',
  isAChatwootInstance: $state => $state.installationName === 'Chatwoot',
};

export const actions = {};

export const mutations = {};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
