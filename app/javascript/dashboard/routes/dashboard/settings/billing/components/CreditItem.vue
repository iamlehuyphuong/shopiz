<script setup>
import { formatCurrency } from 'dashboard/helper/commons';
import { useI18n } from 'vue-i18n';
const { t } = useI18n();

defineProps({
  creditItem: {
    type: Object,
    required: true,
  },
});

</script>

<template>
  <div class="trial-item rounded-xl shadow-sm border border-n-weak bg-n-solid-2 py-8 px-8">
    <div class="title text-center">
      <span class="text-base font-medium text-n-slate-12">
        {{ creditItem.name }}
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
