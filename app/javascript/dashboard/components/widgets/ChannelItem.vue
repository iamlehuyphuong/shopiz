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
  return (
    window.shopizConfig?.tiktokShopAppId || window.shopizConfig?.tiktokAppId
  );
});

const hasTiktokConfigured = computed(() => {
  return window.chatwootConfig?.tiktokAppId;
});

const isActive = computed(() => {
  const { key } = props.channel;
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

  return [
    'website',
    'twilio',
    'api',
    'whatsapp',
    'sms',
    'telegram',
    'line',
    'instagram',
    'zalo',
    'zalopersonal',
    'tiktok_shop',
    'tiktok',
    'voice',
  ].includes(key);
});

const isComingSoon = computed(() => {
  const { key } = props.channel;
  // Show "Coming Soon" only if the channel is marked as coming soon
  // and the corresponding feature flag is not enabled yet.
  return ['voice'].includes(key) && !isActive.value;
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
