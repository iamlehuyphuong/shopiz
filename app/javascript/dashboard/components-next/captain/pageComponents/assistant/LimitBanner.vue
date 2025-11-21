<script setup>
import { onMounted, computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useRouter } from 'vue-router';

import Banner from 'dashboard/components-next/banner/Banner.vue';

const router = useRouter();
const { accountId } = useAccount();

const { assistantLimits, responseLimits, fetchLimits } = useCaptain();

const openBilling = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
};

const overResponse = computed(() => {
  if (!responseLimits.value) return false;

  const { consumed, totalCount } = responseLimits.value;
  if (!consumed || !totalCount) return false;

  return consumed / totalCount >= 1.0;
});

const overAssistant = computed(() => {
  if (!assistantLimits.value) return false;

  const { currentAvailable } = assistantLimits.value;
  return currentAvailable === 0;
})

const showBanner = computed(() => {
  return overAssistant.value || overResponse.value;
});

onMounted(fetchLimits);
defineExpose({ overAssistant });
</script>

<template>
  <Banner
    v-show="showBanner"
    color="amber"
    :action-label="$t('CAPTAIN.PAYWALL.UPGRADE_NOW')"
    @action="openBilling"
  >
    {{ $t('CAPTAIN.BANNER.RESPONSES') }}
  </Banner>
</template>
