<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useI18n } from 'vue-i18n';
import ButtonV4 from 'next/button/Button.vue';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  featureName: {
    type: String,
    default: '',
  },
  featureFlag: {
    type: String,
    default: '',
  },
});

const router = useRouter();
const { t, te } = useI18n();
const { accountId, currentAccount } = useAccount();
const { isAdmin } = useAdmin();

const routeToBilling = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
};

const upgradeMessage = computed(() => {
  const flag = props.featureFlag?.toLowerCase() || '';

  // Handle CRM (Contacts) limit specifically as it might have dynamic data
  if (flag === 'crm' || flag === 'contacts') {
    const usageStr = currentAccount.value?.billing?.usage?.contacts || '';
    const allowed = usageStr.split(' / ')[1] || '0';
    return t('GENERAL_SETTINGS.LIMIT_MESSAGES.UPGRADE_PROMPT_CRM', { allowed });
  }

  // Handle ShopizAI (Captain) features
  if (flag.startsWith('captain_')) {
    return t('GENERAL_SETTINGS.LIMIT_MESSAGES.UPGRADE_PROMPT_CAPTAIN');
  }

  // Handle other dynamic prompts based on feature flag
  const promptKey = `GENERAL_SETTINGS.LIMIT_MESSAGES.UPGRADE_PROMPT_${flag.toUpperCase()}`;
  if (te(promptKey)) {
    return t(promptKey, { feature: props.featureName });
  }

  // Default fallback
  return t('GENERAL_SETTINGS.LIMIT_MESSAGES.UPGRADE_PROMPT_GENERIC', {
    feature: props.featureName,
  });
});
</script>

<template>
  <div
    class="absolute inset-0 z-40 bg-white/50 backdrop-blur-[1px] flex items-center justify-center p-6 text-center"
  >
    <div
      class="flex flex-col gap-6 p-8 bg-n-alpha-3 border border-n-weak rounded-2xl shadow-xl max-w-md w-full text-left"
    >
      <div class="flex items-center gap-4">
        <div
          class="flex items-center justify-center size-10 rounded-full bg-n-solid-orange/20 shrink-0"
        >
          <Icon icon="i-lucide-lock-keyhole" class="size-4 text-n-orange" />
        </div>
        <h3 class="text-lg font-bold text-n-slate-12">
          {{ t('GENERAL_SETTINGS.UPGRADE') }}
        </h3>
      </div>
      <div class="flex flex-col gap-2">
        <p class="text-sm text-n-slate-11 leading-relaxed">
          {{ upgradeMessage }}
        </p>
        <p v-if="!isAdmin" class="mt-2 text-sm text-n-slate-11 italic">
          {{ t('GENERAL_SETTINGS.LIMIT_MESSAGES.NON_ADMIN') }}
        </p>
      </div>
      <div class="flex w-full gap-3 mt-2">
        <ButtonV4
          v-if="isAdmin"
          solid
          blue
          md
          class="flex-1"
          :label="t('GENERAL_SETTINGS.OPEN_BILLING')"
          icon="i-lucide-credit-card"
          @click="routeToBilling"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
/* Ensure the overlay covers everything in its relative parent */
.absolute {
  height: 100%;
  width: 100%;
}
</style>
