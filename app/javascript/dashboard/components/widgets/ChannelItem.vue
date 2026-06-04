<script setup>
import { computed } from 'vue';
import ChannelSelector from '../ChannelSelector.vue';

const props = defineProps({
  channel: {
    type: Object,
    required: true,
  },
  enabledFeatures: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['channelItemClick']);

const hasFbConfigured = computed(() => {
  return window.shopizConfig?.fbAppId;
});

const hasInstagramConfigured = computed(() => {
  return window.shopizConfig?.instagramAppId;
});

const hasZaloPersonalConfigured = computed(() => {
  return window.shopizConfig?.zaloApiUrl;
});

const hasZaloConfigured = computed(() => {
  return window.shopizConfig?.zaloAppId;
});

const hasTiktokShopConfigured = computed(() => {
  return window.shopizConfig?.tiktokShopAppId;
});

const hasTiktokConfigured = computed(() => {
  return window.shopizConfig?.tiktokAppId;
});

const isActive = computed(() => {
  const { key } = props.channel;

  // Check globalConfig toggles first
  const globalConfig = window.globalConfig || {};
  const isFalse = val => val === false || val === 'false';

  if (key === 'facebook' && isFalse(globalConfig.ENABLE_CHANNEL_FACEBOOK))
    return false;
  if (key === 'zalo' && isFalse(globalConfig.ENABLE_CHANNEL_ZALO_OA))
    return false;
  if (
    key === 'zalopersonal' &&
    isFalse(globalConfig.ENABLE_CHANNEL_ZALO_PERSONAL)
  )
    return false;
  if (key === 'tiktok' && isFalse(globalConfig.ENABLE_CHANNEL_TIKTOK))
    return false;
  if (key === 'tiktok_shop' && isFalse(globalConfig.ENABLE_CHANNEL_TIKTOK_SHOP))
    return false;
  if (key === 'whatsapp' && isFalse(globalConfig.ENABLE_CHANNEL_WHATSAPP))
    return false;
  if (key === 'instagram' && isFalse(globalConfig.ENABLE_CHANNEL_INSTAGRAM))
    return false;
  if (key === 'telegram' && isFalse(globalConfig.ENABLE_CHANNEL_TELEGRAM))
    return false;
  if (key === 'line' && isFalse(globalConfig.ENABLE_CHANNEL_LINE)) return false;
  if (key === 'twitter' && isFalse(globalConfig.ENABLE_CHANNEL_TWITTER))
    return false;
  if (key === 'website' && isFalse(globalConfig.ENABLE_CHANNEL_WEBSITE))
    return false;

  if (Object.keys(props.enabledFeatures).length === 0) {
    return false;
  }
  if (key === 'website') {
    return props.enabledFeatures.channel_website;
  }
  if (key === 'facebook') {
    return props.enabledFeatures.channel_facebook && hasFbConfigured.value;
  }
  if (key === 'email') {
    return props.enabledFeatures.channel_email;
  }

  if (key === 'zalo') {
    return props.enabledFeatures.channel_zalo && hasZaloConfigured.value;
  }

  if (key === 'zalopersonal') {
    return (
      props.enabledFeatures.channel_zalopersonal &&
      hasZaloPersonalConfigured.value
    );
  }

  if (key === 'tiktok_shop') {
    return (
      props.enabledFeatures.channel_tiktok_shop && hasTiktokShopConfigured.value
    );
  }

  if (key === 'instagram') {
    return (
      props.enabledFeatures.channel_instagram && hasInstagramConfigured.value
    );
  }

  if (key === 'tiktok') {
    return props.enabledFeatures.channel_tiktok && hasTiktokConfigured.value;
  }

  if (key === 'voice') {
    return props.enabledFeatures.channel_voice;
  }
  if (key === 'twitter') {
    return (
      props.enabledFeatures.channel_twitter &&
      window.shopizConfig?.twitterConsumerKey
    );
  }

  return [
    'website',
    'twilio',
    'api',
    'whatsapp',
    'sms',
    'telegram',
    'line',
    'instagram',
    'twitter',
    'zalo',
    'zalopersonal',
    'tiktok_shop',
    'tiktok',
    'voice',
  ].includes(key);
});

const isComingSoon = computed(() => {
  const { key } = props.channel;

  const globalConfig = window.globalConfig || {};
  const isFalse = val => val === false || val === 'false';

  const isGloballyDisabled =
    (key === 'facebook' && isFalse(globalConfig.ENABLE_CHANNEL_FACEBOOK)) ||
    (key === 'zalo' && isFalse(globalConfig.ENABLE_CHANNEL_ZALO_OA)) ||
    (key === 'zalopersonal' &&
      isFalse(globalConfig.ENABLE_CHANNEL_ZALO_PERSONAL)) ||
    (key === 'tiktok' && isFalse(globalConfig.ENABLE_CHANNEL_TIKTOK)) ||
    (key === 'tiktok_shop' &&
      isFalse(globalConfig.ENABLE_CHANNEL_TIKTOK_SHOP)) ||
    (key === 'whatsapp' && isFalse(globalConfig.ENABLE_CHANNEL_WHATSAPP)) ||
    (key === 'instagram' && isFalse(globalConfig.ENABLE_CHANNEL_INSTAGRAM)) ||
    (key === 'telegram' && isFalse(globalConfig.ENABLE_CHANNEL_TELEGRAM)) ||
    (key === 'line' && isFalse(globalConfig.ENABLE_CHANNEL_LINE)) ||
    (key === 'twitter' && isFalse(globalConfig.ENABLE_CHANNEL_TWITTER)) ||
    (key === 'website' && isFalse(globalConfig.ENABLE_CHANNEL_WEBSITE));

  // Show "Coming Soon" only if the channel is marked as coming soon
  // and the corresponding feature flag is not enabled yet.
  return (['voice'].includes(key) && !isActive.value) || isGloballyDisabled;
});

const onItemClick = () => {
  if (isActive.value) {
    emit('channelItemClick', props.channel.key);
  }
};
</script>

<template>
  <ChannelSelector
    :title="channel.title"
    :description="channel.description"
    :icon="channel.icon"
    :is-coming-soon="isComingSoon"
    :disabled="!isActive"
    @click="onItemClick"
  />
</template>
