<script setup>
import BenefitItem from './BenefitItem.vue';
import { formatCurrency } from 'dashboard/helper/commons';

const props = defineProps({
  plan: {
    type: Object,
    required: true,
  },
});

import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useUISettings } from 'dashboard/composables/useUISettings';
const { locale } = useI18n();
const { uiSettings } = useUISettings();

const localizedTitle = computed(() => {
  const localeToUse = uiSettings.value?.locale || locale.value || 'en';
  const isVietnamese = localeToUse === 'vi';
  if (isVietnamese && props.plan.name_vi) return props.plan.name_vi;
  if (!isVietnamese && props.plan.name_en) return props.plan.name_en;
  return props.plan.name;
});
</script>

<template>
  <div
    class="trial-item rounded-xl shadow-sm border border-n-weak bg-n-solid-2 py-8 px-8"
  >
    <div class="grid grid-cols-2 gap-8">
      <div class="title">
        <span class="text-base font-medium text-n-slate-12">
          {{ localizedTitle }}
        </span>
        <p class="text-base font-medium text-n-slate-12">
          {{ formatCurrency(plan.price) }}
        </p>
        <p class="text-sm text-n-slate-11 mt-5">
          {{ plan.description }}
        </p>
      </div>
      <div class="benefit mt-6 mb-4 flex-1 w-full px-6">
        <template
          v-for="category in plan.benefits"
          :key="category.name"
        >
          <div class="mt-6 mb-3">
            <h4
              class="text-xs font-semibold text-n-slate-12 uppercase tracking-wide border-b border-n-weak pb-1.5 mb-3"
            >
              {{ $t(category.name) }}
            </h4>
            <div class="flex flex-col gap-1">
              <BenefitItem
                v-for="benefit in category.items"
                :key="benefit['id']"
                class="justify-start text-left"
                :label="benefit['description']"
                :count="benefit['count']"
                :included="benefit['included'] !== false"
                :status="benefit['status']"
              />
            </div>
          </div>
        </template>
      </div>
    </div>
    <div class="button-group mt-5">
      <slot />
    </div>
  </div>
</template>
