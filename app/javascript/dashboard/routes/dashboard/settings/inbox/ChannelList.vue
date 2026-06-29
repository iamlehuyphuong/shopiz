<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';

import { useAccount } from 'dashboard/composables/useAccount';

import ChannelItem from 'dashboard/components/widgets/ChannelItem.vue';

const { t } = useI18n();
const router = useRouter();
const { accountId, currentAccount } = useAccount();

const enabledFeatures = ref({});

// const hasTiktokConfigured = computed(() => {
//   return window.chatwootConfig?.tiktokAppId;
// });

const channelList = computed(() => {
  const globalConfig = window.globalConfig || {};

  const channels = [
    {
      key: 'website',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.WEBSITE.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.WEBSITE.DESCRIPTION'),
      icon: 'i-woot-website',
      status: globalConfig.CHANNEL_STATUS_WEBSITE || 'published',
    },
    {
      key: 'zalo',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.ZALO_OA.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.ZALO_OA.DESCRIPTION'),
      icon: 'i-woot-zalo-oa',
      status: globalConfig.CHANNEL_STATUS_ZALO_OA || 'published',
    },
    {
      key: 'zalopersonal',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.ZALO_PERSONAL.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.ZALO_PERSONAL.DESCRIPTION'),
      icon: 'i-woot-zalo-personal',
      status: globalConfig.CHANNEL_STATUS_ZALO_PERSONAL || 'published',
    },
    {
      key: 'facebook',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.FACEBOOK.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.FACEBOOK.DESCRIPTION'),
      icon: 'i-woot-messenger',
      status: globalConfig.CHANNEL_STATUS_FACEBOOK || 'published',
    },
    {
      key: 'whatsapp',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.WHATSAPP.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.WHATSAPP.DESCRIPTION'),
      icon: 'i-woot-whatsapp',
      status: globalConfig.CHANNEL_STATUS_WHATSAPP || 'published',
    },
    {
      key: 'instagram',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.INSTAGRAM.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.INSTAGRAM.DESCRIPTION'),
      icon: 'i-woot-instagram',
      status: globalConfig.CHANNEL_STATUS_INSTAGRAM || 'published',
    },
    {
      key: 'tiktok',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.TIKTOK.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.TIKTOK.DESCRIPTION'),
      icon: 'i-woot-tiktok',
      status: globalConfig.CHANNEL_STATUS_TIKTOK || 'published',
    },
    {
      key: 'tiktok_shop',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.TIKTOK_SHOP.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.TIKTOK_SHOP.DESCRIPTION'),
      icon: 'i-woot-tiktok-shop',
      status: globalConfig.CHANNEL_STATUS_TIKTOK_SHOP || 'published',
    },
    {
      key: 'telegram',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.TELEGRAM.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.TELEGRAM.DESCRIPTION'),
      icon: 'i-woot-telegram',
      status: globalConfig.CHANNEL_STATUS_TELEGRAM || 'published',
    },
    {
      key: 'line',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.LINE.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.LINE.DESCRIPTION'),
      icon: 'i-woot-line',
      status: globalConfig.CHANNEL_STATUS_LINE || 'published',
    },
    {
      key: 'twitter',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.TWITTER.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.TWITTER.DESCRIPTION'),
      icon: 'i-ri-twitter-x-fill',
      status: globalConfig.CHANNEL_STATUS_TWITTER || 'published',
    },
  ];

  const filteredChannels = channels.filter(
    c => !['draft', 'deprecated'].includes(c.status)
  );

  return filteredChannels.sort((a, b) => {
    const aComingSoon = a.status === 'coming_soon' || ['voice'].includes(a.key);
    const bComingSoon = b.status === 'coming_soon' || ['voice'].includes(b.key);

    if (aComingSoon && !bComingSoon) return 1;
    if (!aComingSoon && bComingSoon) return -1;
    return 0;
  });
});

const initializeEnabledFeatures = async () => {
  enabledFeatures.value = currentAccount.value.features;
};

const initChannelAuth = channel => {
  const params = {
    sub_page: channel,
    accountId: accountId.value,
  };
  router.push({ name: 'settings_inboxes_page_channel', params });
};

onMounted(() => {
  initializeEnabledFeatures();
});
</script>

<template>
  <div
    class="grid max-w-5xl grid-cols-1 md:grid-cols-2 lg:grid-cols-3 mx-0 gap-6 p-8"
  >
    <ChannelItem
      v-for="channel in channelList"
      :key="channel.key"
      :channel="channel"
      :enabled-features="enabledFeatures"
      @channel-item-click="initChannelAuth"
    />
  </div>
</template>
