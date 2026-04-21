<script setup>
import { formatCurrency } from 'dashboard/helper/commons';
import { useI18n } from 'vue-i18n';
const props = defineProps({
  creditItem: {
    type: Object,
    required: true,
  },
});

import { computed } from 'vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
const { t, locale } = useI18n();
const { uiSettings } = useUISettings();

const localizedTitle = computed(() => {
  const localeToUse = uiSettings.value?.locale || locale.value || 'en';
  const isVietnamese = localeToUse === 'vi';
  if (isVietnamese && props.creditItem.name_vi) return props.creditItem.name_vi;
  if (!isVietnamese && props.creditItem.name_en)
    return props.creditItem.name_en;
  return props.creditItem.name;
});
</script>

<template>
  <div
    class="trial-item rounded-xl shadow-sm border border-n-weak bg-n-solid-2 py-8 px-8"
  >
    <div class="title text-center">
      <span class="text-base font-medium text-n-slate-12">
        {{ localizedTitle }}
      </span>
      <p class="text-base font-medium text-n-slate-12 mt-1">
        {{ formatCurrency(creditItem.price) }}
      </p>
      <p class="text-sm text-n-slate-11 mt-1">
        {{ creditItem.description }}
      </p>
      <p class="text-sm text-n-slate-11 mt-1">
        {{ $t('BILLING_SETTINGS.CAPTAIN.NO_EXPIRATION') }}
      </p>
    </div>
    <div class="mt-5 flex justify-center">
      <slot />
    </div>
  </div>
</template>
