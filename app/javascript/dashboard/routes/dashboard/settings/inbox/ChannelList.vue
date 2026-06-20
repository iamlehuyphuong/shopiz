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
  const channels = [
    {
      key: 'website',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.WEBSITE.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.WEBSITE.DESCRIPTION'),
      icon: 'i-woot-website',
    },
    {
      key: 'zalo',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.ZALO_OA.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.ZALO_OA.DESCRIPTION'),
      icon: 'i-woot-zalo-oa',
    },
    {
      key: 'zalopersonal',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.ZALO_PERSONAL.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.ZALO_PERSONAL.DESCRIPTION'),
      icon: 'i-woot-zalo-personal',
    },
    {
      key: 'facebook',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.FACEBOOK.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.FACEBOOK.DESCRIPTION'),
      icon: 'i-woot-messenger',
    },
    {
      key: 'whatsapp',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.WHATSAPP.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.WHATSAPP.DESCRIPTION'),
      icon: 'i-woot-whatsapp',
    },
    {
      key: 'instagram',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.INSTAGRAM.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.INSTAGRAM.DESCRIPTION'),
      icon: 'i-woot-instagram',
    },
    {
      key: 'tiktok',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.TIKTOK.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.TIKTOK.DESCRIPTION'),
      icon: 'i-woot-tiktok',
    },
    {
      key: 'tiktok_shop',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.TIKTOK_SHOP.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.TIKTOK_SHOP.DESCRIPTION'),
      icon: 'i-woot-tiktok-shop',
    },
    {
      key: 'telegram',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.TELEGRAM.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.TELEGRAM.DESCRIPTION'),
      icon: 'i-woot-telegram',
    },
    {
      key: 'line',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.LINE.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.LINE.DESCRIPTION'),
      icon: 'i-woot-line',
    },
    {
      key: 'twitter',
      title: t('INBOX_MGMT.ADD.AUTH.CHANNEL.TWITTER.TITLE'),
      description: t('INBOX_MGMT.ADD.AUTH.CHANNEL.TWITTER.DESCRIPTION'),
      icon: 'i-ri-twitter-x-fill',
    },
  ];

  const globalConfig = window.globalConfig || {};
  const isFalse = val => val === false || val === 'false';

  const isGloballyDisabled = key =>
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

  return channels.sort((a, b) => {
    const aComingSoon = isGloballyDisabled(a.key) || ['voice'].includes(a.key);
    const bComingSoon = isGloballyDisabled(b.key) || ['voice'].includes(b.key);

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
    class="grid max-w-3xl grid-cols-1 xs:grid-cols-2 mx-0 gap-6 sm:grid-cols-3 p-8"
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
