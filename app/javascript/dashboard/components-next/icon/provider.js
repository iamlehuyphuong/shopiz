import { computed } from 'vue';

export function useChannelIcon(inbox) {
  const channelTypeIconMap = {
    'Channel::Api': 'i-woot-api',
    'Channel::FacebookPage': 'i-woot-messenger',
    'Channel::Telegram': 'i-woot-telegram',
    'Channel::WebWidget': 'i-woot-website',
    'Channel::Whatsapp': 'i-woot-whatsapp',
    'Channel::Instagram': 'i-woot-instagram',
    'Channel::Tiktok': 'i-woot-tiktok',
    'Channel::ZaloOa': 'i-woot-zalo-oa',
    'Channel::ZaloPersonal': 'i-woot-zalo-personal',
    'Channel::TiktokShop': 'i-woot-tiktok-shop',
  };

  const channelIcon = computed(() => {
    const inboxDetails = inbox.value || inbox;
    const type = inboxDetails.channel_type;
    let icon = channelTypeIconMap[type];

    return icon ?? 'i-ri-global-fill';
  });

  return channelIcon;
}
