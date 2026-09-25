<script setup>
import { useI18n } from 'vue-i18n';
import { useStoreGetters } from 'dashboard/composables/store';
import { computed } from 'vue';

const props = defineProps({
  channelType: {
    type: String,
    required: true,
  },
  medium: {
    type: String,
    default: '',
  },
});
const getters = useStoreGetters();
const { t } = useI18n();
const globalConfig = computed(() => getters['globalConfig/get'].value);

const i18nMap = {
  'Channel::FacebookPage': 'MESSENGER',
  'Channel::WebWidget': 'WEB_WIDGET',
  'Channel::Whatsapp': 'WHATSAPP',
  'Channel::Telegram': 'TELEGRAM',
  'Channel::Api': 'API',
  'Channel::Instagram': 'INSTAGRAM',
  'Channel::Tiktok': 'TIKTOK',
  'Channel::ZaloOa': 'ZALO_OA',
  'Channel::ZaloPersonal': 'ZALO_PERSONAL',
  'Channel::TiktokShop': 'TIKTOK_SHOP',
};

const readableChannelName = computed(() => {
  if (props.channelType === 'Channel::Api') {
    return globalConfig.value.apiChannelName || t('INBOX_MGMT.CHANNELS.API');
  }
  return t(`INBOX_MGMT.CHANNELS.${i18nMap[props.channelType]}`);
});
</script>

<template>
  <span>
    {{ readableChannelName }}
  </span>
</template>
