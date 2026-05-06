<script setup>
import { computed, ref, watch } from 'vue';
import BenefitItem from './BenefitItem.vue';
import { formatCurrency } from 'dashboard/helper/commons';
import { useI18n } from 'vue-i18n';
import { useUISettings } from 'dashboard/composables/useUISettings';
import ButtonV4 from 'next/button/Button.vue';

const props = defineProps({
  tier: {
    type: Object,
    required: true,
  },
  currentPlanId: {
    type: [Number, String],
    default: null,
  },
  currentRank: {
    type: Number,
    default: -1,
  },
  globalDuration: {
    type: Number,
    default: 365,
  },
  globalAiIncluded: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['checkout']);

const { t, locale } = useI18n();
const { uiSettings } = useUISettings();

const selectedPackage = computed(() => {
  if (!props.tier?.packages || props.tier.packages.length === 0) return null;
  let match = props.tier.packages.find(
    p =>
      p.duration_days === props.globalDuration &&
      !!p.ai_included === props.globalAiIncluded
  );
  if (match) return match;

  match = props.tier.packages.find(
    p => p.duration_days === props.globalDuration
  );
  if (match) return match;

  match = props.tier.packages.find(
    p => !!p.ai_included === props.globalAiIncluded
  );
  if (match) return match;

  return props.tier.packages[0];
});

const localizedTitle = computed(() => {
  const localeToUse = uiSettings.value?.locale || locale.value || 'en';
  const isVietnamese = localeToUse === 'vi';
  const pkg = selectedPackage.value;
  if (pkg) {
    if (isVietnamese && pkg.name_vi) return pkg.name_vi;
    if (!isVietnamese && pkg.name_en) return pkg.name_en;
    if (pkg.name) return pkg.name;
  }
  if (isVietnamese && props.tier.tier_name_vi) return props.tier.tier_name_vi;
  if (!isVietnamese && props.tier.tier_name_en) return props.tier.tier_name_en;
  return props.tier.tier_name;
});

const monthlyPrice = computed(() => {
  const price = selectedPackage.value?.price?.price_amount || 0;
  const days = selectedPackage.value?.duration_days || 0;
  if (!price || days <= 0) return 0;

  const months = Math.round(days / 30.0);
  if (months <= 0) return 0;

  return price / months;
});

const isDowngrade = computed(() => {
  return (
    props.tier.rank >= 0 &&
    props.currentRank >= 0 &&
    props.tier.rank < props.currentRank
  );
});

const isCurrentTier = computed(() => {
  return props.tier.rank === props.currentRank;
});

const buttonLabel = computed(() => {
  if (isCurrentTier.value) {
    if (selectedPackage.value?.id === props.currentPlanId) {
      return t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.CURRENT_PACKAGE');
    }
    return (
      t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.RENEW_NOW') ||
      'Sửa đổi chu kỳ'
    );
  }
  return t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.UPGRADE_NOW');
});

const onCheckout = () => {
  emit('checkout', {
    product_id: selectedPackage.value?.id,
    product_type: 'plan',
    payment_method: 'auto',
  });
};
</script>

<template>
  <div
    class="trial-item flex flex-col rounded-xl shadow-sm border border-n-weak bg-n-solid-2 py-8 px-8"
  >
    <div class="title text-center">
      <span class="text-base font-medium text-n-slate-12 uppercase">
        {{ localizedTitle }}
      </span>

      <template v-if="selectedPackage">
        <div class="mt-4 flex flex-col items-center justify-center">
          <div class="flex items-center">
            <p class="text-2xl font-bold text-n-slate-12 m-0">
              {{ formatCurrency(selectedPackage.price) }}
            </p>
            <span
              v-if="selectedPackage.discount_percent > 0"
              class="ml-2 text-xs font-semibold text-n-orange bg-n-orange/10 px-1.5 py-0.5 rounded"
            >
              {{
                $t('BILLING_SETTINGS.PRICING_PACKAGES.DISCOUNT', {
                  percent: selectedPackage.discount_percent,
                })
              }}
            </span>
          </div>
          <span class="text-xs text-n-slate-11 mt-1 block">
            {{
              $t('BILLING_SETTINGS.PRICING_PACKAGES.MONTHLY_EQUIVALENT', {
                price: formatCurrency({
                  price_amount: monthlyPrice,
                  currency: selectedPackage.price?.currency,
                }),
              })
            }}
          </span>
        </div>
      </template>

      <p class="text-sm text-n-slate-11 mt-2 min-h-[40px]">
        {{ tier.description }}
      </p>
    </div>

    <div class="benefit mt-6 mb-4 flex-1 w-full px-6">
      <template
        v-for="category in selectedPackage.benefits"
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
            />
          </div>
        </div>
      </template>
    </div>

    <div class="mt-6 flex flex-col items-center gap-2">
      <ButtonV4
        md
        solid
        :color="isDowngrade ? 'slate' : 'ruby'"
        :disabled="
          isDowngrade || (isCurrentTier && selectedPackage.id === currentPlanId)
        "
        @click="onCheckout"
      >
        <span v-if="isDowngrade">{{
          $t(
            'BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.DOWNGRADE_NOT_SUPPORTED'
          )
        }}</span>
        <span v-else>{{ buttonLabel }}</span>
      </ButtonV4>
      <p
        v-if="isDowngrade"
        class="text-xs text-n-slate-11 text-center mt-1 max-w-[220px]"
      >
        {{ $t('BILLING_SETTINGS.PRICING_PACKAGES.DOWNGRADE_NOTICE') }}
      </p>
    </div>
  </div>
</template>
