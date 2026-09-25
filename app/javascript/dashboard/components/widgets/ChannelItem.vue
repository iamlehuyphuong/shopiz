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
  // Now managed via CHANNEL_STATUS so global boolean checks are removed.

  if (Object.keys(props.enabledFeatures).length === 0) {
    return false;
  }
  if (key === 'website') {
    return props.enabledFeatures.channel_website;
  }
  if (key === 'facebook') {
    return props.enabledFeatures.channel_facebook && hasFbConfigured.value;
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

  return [
    'website',
    'api',
    'whatsapp',
    'telegram',
    'instagram',
    'zalo',
    'zalopersonal',
    'tiktok_shop',
    'tiktok',
  ].includes(key);
});

const computedStatus = computed(() => {
  if (props.channel.status === 'coming_soon') return 'coming_soon';
  if (!isActive.value) return 'coming_soon';
  return props.channel.status || 'published';
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
    :status="computedStatus"
    :disabled="!isActive || computedStatus === 'coming_soon'"
    @click="onItemClick"
  />
</template>
