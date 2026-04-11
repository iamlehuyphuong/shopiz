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
  }
});

const emit = defineEmits(['checkout']);

const { t, locale } = useI18n();
const { uiSettings } = useUISettings();

const selectedPackageId = ref(null);

watch(() => props.tier.packages, (pkgs) => {
  if (pkgs && pkgs.length > 0) {
    const currentInTier = pkgs.find(p => p.id === props.currentPlanId);
    if (currentInTier) {
      selectedPackageId.value = currentInTier.id;
    } else {
      selectedPackageId.value = pkgs[0].id;
    }
  }
}, { immediate: true });

const selectedPackage = computed(() => {
  return props.tier.packages.find(p => p.id === selectedPackageId.value) || props.tier.packages[0];
});

const localizedTitle = computed(() => {
  const localeToUse = uiSettings.value?.locale || locale.value || 'en';
  const isVietnamese = localeToUse === 'vi';
  if (isVietnamese && props.tier.tier_name_vi) return props.tier.tier_name_vi;
  if (!isVietnamese && props.tier.tier_name_en) return props.tier.tier_name_en;
  return props.tier.tier_name;
});

const getDurationLabel = (durationDays) => {
  if (durationDays === 180) return '6 Tháng';
  if (durationDays === 365) return '1 Năm';
  if (durationDays === 730) return '2 Năm';
  return `${durationDays} Ngày`;
};

const monthlyPrice = computed(() => {
  const price = selectedPackage.value?.price?.price_amount || 0;
  const days = selectedPackage.value?.duration_days || 0;
  if (!price || days <= 0) return 0;
  
  const months = Math.round(days / 30.0);
  if (months <= 0) return 0;
  
  return price / months;
});

const isDowngrade = computed(() => {
  return props.tier.rank >= 0 && props.currentRank >= 0 && props.tier.rank < props.currentRank;
});

const isCurrentTier = computed(() => {
  return props.tier.rank === props.currentRank;
});

const buttonLabel = computed(() => {
  if (isCurrentTier.value) {
    if (selectedPackage.value.id === props.currentPlanId) {
      return t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.CURRENT_PACKAGE');
    }
    return t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.RENEW_NOW') || 'Sửa đổi chu kỳ';
  }
  return t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.UPGRADE_NOW');
});

const onCheckout = () => {
  emit('checkout', {
    product_id: selectedPackage.value.id,
    payment_method: 'payos',
  });
};

</script>

<template>
  <div class="trial-item flex flex-col rounded-xl shadow-sm border border-n-weak bg-n-solid-2 py-8 px-8">
    <div class="title text-center">
      <span class="text-base font-medium text-n-slate-12 uppercase">
        {{ localizedTitle }}
      </span>
      
      <div class="flex justify-center mt-3">
        <select 
          v-model="selectedPackageId"
          class="w-full max-w-[200px] text-sm font-medium text-n-slate-12 bg-white border border-n-weak rounded-md px-3 py-1.5 focus:outline-none focus:ring-2 focus:ring-n-brand"
        >
          <option v-for="pkg in tier.packages" :key="pkg.id" :value="pkg.id">
            {{ getDurationLabel(pkg.duration_days) }}
            <template v-if="pkg.discount_percent > 0">(-{{ pkg.discount_percent }}%)</template>
          </option>
        </select>
      </div>

      <div class="mt-4 flex flex-col items-center justify-center">
         <div class="flex items-center">
           <p class="text-2xl font-bold text-n-slate-12 m-0">
            {{ formatCurrency(selectedPackage.price) }}
           </p>
           <span v-if="selectedPackage.discount_percent > 0" class="ml-2 text-xs font-semibold text-green-600 bg-green-100 px-1.5 py-0.5 rounded">
             Giảm {{ selectedPackage.discount_percent }}%
           </span>
         </div>
         <p v-if="monthlyPrice > 0" class="text-xs text-n-slate-11 mt-1.5 font-medium">
           {{ formatCurrency({ price_amount: monthlyPrice, currency: selectedPackage.price.currency }) }}/tháng
         </p>
      </div>
      
      <p class="text-sm text-n-slate-11 mt-2 min-h-[40px]">
        {{ tier.description }}
      </p>
    </div>
    
    <div class="benefit mt-6 flex-1">
      <template v-for="benefit in tier.benefits" :key="benefit['id']">
        <BenefitItem class="text-center" :label="benefit['description']" />
      </template>
    </div>
    
    <div class="mt-6 flex justify-center">
      <ButtonV4
        md
        solid
        :color="isDowngrade ? 'slate' : 'ruby'"
        :disabled="isDowngrade || (isCurrentTier && selectedPackage.id === currentPlanId)"
        @click="onCheckout"
      >
        <span v-if="isDowngrade">{{ $t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.DOWNGRADE_NOT_SUPPORTED') || 'Không thể hạ cấp' }}</span>
        <span v-else>{{ buttonLabel }}</span>
      </ButtonV4>
    </div>
  </div>
</template>
