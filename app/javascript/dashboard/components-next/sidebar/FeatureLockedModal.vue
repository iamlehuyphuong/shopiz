<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useI18n } from 'vue-i18n';
import ModalV4 from 'next/dialog/Dialog.vue';
import ButtonV4 from 'next/button/Button.vue';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
  featureName: {
    type: String,
    default: '',
  },
  featureFlag: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['close']);

const router = useRouter();
const { t, te } = useI18n();
const { accountId, currentAccount } = useAccount();
const { isAdmin } = useAdmin();

const routeToBilling = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
  emit('close');
};

const upgradeMessage = computed(() => {
  const flag = props.featureFlag?.toLowerCase() || '';

  // Handle CRM (Contacts) limit specifically
  if (flag === 'crm' || flag === 'contacts') {
    const usageStr = currentAccount.value?.billing?.usage?.contacts || '';
    const allowed = usageStr.split(' / ')[1] || '0';
    return t('GENERAL_SETTINGS.LIMIT_MESSAGES.UPGRADE_PROMPT_CRM', { allowed });
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
  <ModalV4 :show="show" @close="emit('close')">
    <div class="flex flex-col gap-4 p-6">
      <div class="flex items-center gap-3">
        <div
          class="flex items-center justify-center size-8 rounded-full bg-n-solid-orange"
        >
          <Icon icon="i-lucide-lock-keyhole" class="size-4 text-n-orange" />
        </div>
        <h3 class="text-lg font-semibold text-n-slate-12">
          {{ t('GENERAL_SETTINGS.UPGRADE') }}
        </h3>
      </div>
      <div>
        <p class="text-sm text-n-slate-11">
          {{ upgradeMessage }}
        </p>
        <p v-if="!isAdmin" class="mt-2 text-sm text-n-slate-11 italic">
          {{ t('GENERAL_SETTINGS.LIMIT_MESSAGES.NON_ADMIN') }}
        </p>
      </div>
      <div class="flex gap-3 mt-2">
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
        <ButtonV4
          outline
          slate
          md
          class="flex-1"
          :label="t('GENERAL_SETTINGS.CLOSE')"
          @click="emit('close')"
        />
      </div>
    </div>
  </ModalV4>
</template>
