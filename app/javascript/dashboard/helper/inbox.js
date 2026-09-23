export const INBOX_TYPES = {
  WEB: 'Channel::WebWidget',
  FB: 'Channel::FacebookPage',
  TWITTER: 'Channel::TwitterProfile',
  TWILIO: 'Channel::TwilioSms',
  VOICE: 'Channel::Voice',
  WHATSAPP: 'Channel::Whatsapp',
  API: 'Channel::Api',
  TELEGRAM: 'Channel::Telegram',
  LINE: 'Channel::Line',
  SMS: 'Channel::Sms',
  ZALO_OA: 'Channel::ZaloOa',
  ZALO_PERSONAL: 'Channel::ZaloPersonal',
  INSTAGRAM: 'Channel::Instagram',
  TIKTOK: 'Channel::Tiktok',
  // VOICE: 'Channel::Voice',
  TIKTOK_SHOP: 'Channel::TiktokShop',
};

export const TWILIO_CHANNEL_MEDIUM = {
  WHATSAPP: 'whatsapp',
  SMS: 'sms',
};

const INBOX_ICON_MAP_FILL = {
  [INBOX_TYPES.WEB]: 'i-woot-website',
  [INBOX_TYPES.FB]: 'i-woot-messenger',
  [INBOX_TYPES.TWITTER]: 'i-woot-x',
  [INBOX_TYPES.WHATSAPP]: 'i-woot-whatsapp',
  [INBOX_TYPES.API]: 'i-woot-api',
  [INBOX_TYPES.TELEGRAM]: 'i-woot-telegram',
  [INBOX_TYPES.LINE]: 'i-woot-line',
  [INBOX_TYPES.ZALO_OA]: 'i-woot-zalo-oa',
  [INBOX_TYPES.ZALO_PERSONAL]: 'i-woot-zalo-personal',
  [INBOX_TYPES.INSTAGRAM]: 'i-woot-instagram',
  [INBOX_TYPES.TIKTOK]: 'i-woot-tiktok',
  [INBOX_TYPES.VOICE]: 'i-woot-voice',
  [INBOX_TYPES.TIKTOK_SHOP]: 'i-woot-tiktok-shop',
};

const DEFAULT_ICON_FILL = 'i-ri-chat-1-fill';

const INBOX_ICON_MAP_LINE = {
  [INBOX_TYPES.WEB]: 'i-woot-website',
  [INBOX_TYPES.FB]: 'i-woot-messenger',
  [INBOX_TYPES.TWITTER]: 'i-woot-x',
  [INBOX_TYPES.WHATSAPP]: 'i-woot-whatsapp',
  [INBOX_TYPES.API]: 'i-woot-api',
  [INBOX_TYPES.TELEGRAM]: 'i-woot-telegram',
  [INBOX_TYPES.LINE]: 'i-woot-line',
  [INBOX_TYPES.ZALO_OA]: 'i-woot-zalo-oa',
  [INBOX_TYPES.ZALO_PERSONAL]: 'i-woot-zalo-personal',
  [INBOX_TYPES.INSTAGRAM]: 'i-woot-instagram',
  [INBOX_TYPES.VOICE]: 'i-woot-voice',
  [INBOX_TYPES.TIKTOK]: 'i-woot-tiktok',
  [INBOX_TYPES.TIKTOK_SHOP]: 'i-woot-tiktok-shop',
};

const DEFAULT_ICON_LINE = 'i-ri-chat-1-line';

export const getInboxSource = (type, phoneNumber, inbox) => {
  switch (type) {
    case INBOX_TYPES.WEB:
      return inbox.website_url || '';

    case INBOX_TYPES.TWILIO:
    case INBOX_TYPES.WHATSAPP:
    case INBOX_TYPES.VOICE:
      return phoneNumber || '';

    default:
      return '';
  }
};
export const getReadableInboxByType = (type, phoneNumber) => {
  switch (type) {
    case INBOX_TYPES.WEB:
      return 'livechat';

    case INBOX_TYPES.FB:
      return 'facebook';

    case INBOX_TYPES.ZALO_OA:
      return 'zalo';

    case INBOX_TYPES.ZALO_PERSONAL:
      return 'zalopersonal';

    case INBOX_TYPES.TIKTOK_SHOP:
      return 'tiktok_shop';

    case INBOX_TYPES.TWITTER:
      return 'twitter';

    case INBOX_TYPES.TWILIO:
      return phoneNumber?.startsWith('whatsapp') ? 'whatsapp' : 'sms';

    case INBOX_TYPES.VOICE:
      return 'voice';

    case INBOX_TYPES.WHATSAPP:
      return 'whatsapp';

    case INBOX_TYPES.API:
      return 'api';

    case INBOX_TYPES.TELEGRAM:
      return 'telegram';

    case INBOX_TYPES.LINE:
      return 'line';

    // case INBOX_TYPES.VOICE:
    //   return 'voice';

    default:
      return 'chat';
  }
};

export const getInboxClassByType = (type, phoneNumber) => {
  switch (type) {
    case INBOX_TYPES.WEB:
      return 'globe-desktop';

    case INBOX_TYPES.FB:
      return 'brand-facebook';

    case INBOX_TYPES.TWITTER:
      return 'brand-twitter';

    case INBOX_TYPES.TWILIO:
      return phoneNumber?.startsWith('whatsapp')
        ? 'brand-whatsapp'
        : 'brand-sms';

    case INBOX_TYPES.VOICE:
      return 'phone';

    case INBOX_TYPES.WHATSAPP:
      return 'brand-whatsapp';

    case INBOX_TYPES.API:
      return 'cloud';

    case INBOX_TYPES.TELEGRAM:
      return 'brand-telegram';

    case INBOX_TYPES.LINE:
      return 'brand-line';

    case INBOX_TYPES.INSTAGRAM:
      return 'brand-instagram';

    case INBOX_TYPES.TIKTOK:
      return 'brand-tiktok';

    // case INBOX_TYPES.VOICE:
    //   return 'phone';

    case INBOX_TYPES.ZALO_OA:
      return 'brand-zalo-oa';

    case INBOX_TYPES.ZALO_PERSONAL:
      return 'brand-zalo';

    case INBOX_TYPES.TIKTOK_SHOP:
      return 'brand-tiktok-shop';

    default:
      return 'chat';
  }
};

export const getInboxIconByType = (type, medium, variant = 'fill') => {
  const iconMap =
    variant === 'fill' ? INBOX_ICON_MAP_FILL : INBOX_ICON_MAP_LINE;
  const defaultIcon =
    variant === 'fill' ? DEFAULT_ICON_FILL : DEFAULT_ICON_LINE;

  // Special case for Twilio (whatsapp and sms)
  if (type === INBOX_TYPES.TWILIO && medium === 'whatsapp') {
    return iconMap[INBOX_TYPES.WHATSAPP];
  }

  return iconMap[type] ?? defaultIcon;
};

export const getInboxWarningIconClass = (type, reauthorizationRequired) => {
  const allowedInboxTypes = [INBOX_TYPES.FB];
  if (allowedInboxTypes.includes(type) && reauthorizationRequired) {
    return 'warning';
  }
  return '';
};
