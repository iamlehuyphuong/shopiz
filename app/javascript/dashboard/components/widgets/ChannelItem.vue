<script>
import ChannelSelector from '../ChannelSelector.vue';
export default {
  components: { ChannelSelector },
  props: {
    channel: {
      type: Object,
      required: true,
    },
    enabledFeatures: {
      type: Object,
      required: true,
    },
  },
  emits: ['channelItemClick'],
  computed: {
    hasZaloPersonalConfigured() {
      return window.shopizConfig?.zaloAppId;
    },
    hasZaloConfigured() {
      return window.shopizConfig?.zaloAppId;
    },
    hasZaloPersonalConfigured() {
      return window.shopizConfig?.zaloApiUrl;
    },
    hasTiktokConfigured() {
      return window.shopizConfig?.tiktokAppId;
    },
    hasFbConfigured() {
      return window.shopizConfig?.fbAppId;
    },
    hasInstagramConfigured() {
      return window.shopizConfig?.instagramAppId;
    },
    isActive() {
      const { key } = this.channel;
      if (Object.keys(this.enabledFeatures).length === 0) {
        return false;
      }
      if (key === 'website') {
        return this.enabledFeatures.channel_website;
      }
      if (key === 'facebook') {
        return this.enabledFeatures.channel_facebook && this.hasFbConfigured;
      }
      if (key === 'zalo') {
        return this.enabledFeatures.channel_zalo && this.hasZaloConfigured;
      }
      if (key === 'zalopersonal') {
        return this.enabledFeatures.channel_zalopersonal && this.hasZaloPersonalConfigured;
      }
      if (key === 'tiktok') {
        return this.enabledFeatures.channel_tiktok && this.hasTiktokConfigured;
      }
      if (key === 'email') {
        return this.enabledFeatures.channel_email;
      }
      if (key === 'sms') {
        return this.enabledFeatures.channel_sms;
      }
      if (key === 'line') {
        return this.enabledFeatures.channel_line;
      }
      if (key === 'voice') {
        return this.enabledFeatures.channel_voice;
      }
      if (key === 'telegram') {
        return this.enabledFeatures.channel_telegram;
      }
      if (key === 'api') {
        return this.enabledFeatures.channel_api;
      }
      if (key === 'whatsapp') {
        return this.enabledFeatures.channel_whatsapp;
      }
      if (key === 'instagram') {
        return (
          this.enabledFeatures.channel_instagram && this.hasInstagramConfigured
        );
      }
      return [
        'website',
        'twilio',
        'voice',
        'zalo',
        'zalopersonal',
        'api',
        'whatsapp',
        'sms',
        'telegram',
        'line',
        'instagram',
        'tiktok',
      ].includes(key);
    },
  },
  methods: {
    getChannelThumbnail() {
      if (this.channel.key === 'api' && this.channel.thumbnail) {
        return this.channel.thumbnail;
      }
      const specialKeys = ["zalo", "zalopersonal", "tiktok"];
      const ext = specialKeys.includes(this.channel.key) ? "svg" : "png";

      return `/assets/images/dashboard/channels/${this.channel.key}.${ext}`;
    },
    onItemClick() {
      if (this.isActive) {
        this.$emit('channelItemClick', this.channel.key);
      }
    },
  },
};
</script>

<template>
  <ChannelSelector
    :class="{ inactive: !isActive }"
    :title="channel.name"
    :src="getChannelThumbnail()"
    @click="onItemClick"
  />
</template>
