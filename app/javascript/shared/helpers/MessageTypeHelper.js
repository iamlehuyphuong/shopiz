export const isAFormMessage = message => message.content_type === 'form';
export const isASubmittedFormMessage = (message = {}) =>
  isAFormMessage(message) && !!message.content_attributes?.submitted_values;

export const MESSAGE_MAX_LENGTH = {
  GENERAL: 10000,
  // https://developers.facebook.com/docs/messenger-platform/reference/send-api#request
  FACEBOOK: 2000,
  // https://developers.facebook.com/docs/instagram-platform/instagram-api-with-instagram-login/messaging-api#send-a-text-message
  INSTAGRAM: 1000,
  // https://business-api.tiktok.com/portal/docs?id=1832184403754242
  TIKTOK: 6000,

  // https://developers.facebook.com/docs/whatsapp/cloud-api/reference/messages#text-object
  WHATSAPP_CLOUD: 4096,
  // https://core.telegram.org/bots/api#sendmessage
  TELEGRAM: 4096,

};
