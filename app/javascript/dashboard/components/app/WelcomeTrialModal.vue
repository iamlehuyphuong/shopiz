<script setup>
import { computed, ref, onMounted, watch } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close']);
const store = useStore();
const { currentAccount } = useAccount();
const { t } = useI18n();

const isLoading = ref(false);
const isFetchingBilling = ref(false);

const trialPlan = computed(() => {
  const billing = currentAccount.value?.billing;
  if (!billing) return null;

  // Find Basic plan in plans list
  const plans = billing.plans || [];
  const basicTier = plans.find(t =>
    (t.tier_name_en || '').toLowerCase().includes('basic')
  );
  if (basicTier && basicTier.packages && basicTier.packages.length > 0) {
    return basicTier.packages[0]; // Use the first Basic package (e.g., 1 month or 6 months) to show limits
  }

  // Fallback
  return billing.trial_plan;
});
const disabledRegisterTrial = computed(
  () => currentAccount.value?.billing?.disabled_register_trial
);

onMounted(async () => {
  isFetchingBilling.value = true;
  try {
    await store.dispatch('accounts/billings');
  } finally {
    isFetchingBilling.value = false;
  }
});

watch(
  () => props.show,
  newVal => {
    if (newVal) {
      // Re-fetch billing if needed when reopened
      store.dispatch('accounts/billings');
    }
  }
);

const activateTrial = () => {
  emit('close');
};

const skipTrial = () => emit('close');
</script>

<template>
  <Teleport to="body">
    <Transition name="welcome-fade">
      <div
        v-if="show"
        class="fixed inset-0 z-[9999] flex items-center justify-center bg-n-alpha-black2 backdrop-blur-[4px]"
      >
        <div
          class="welcome-modal-box relative w-full max-w-md mx-4 rounded-2xl bg-n-solid-1 shadow-2xl outline outline-1 outline-n-container overflow-hidden"
        >
          <!-- Top gradient accent -->
          <div
            class="absolute top-0 left-0 right-0 h-1 bg-gradient-to-r from-orange-500 via-n-orange to-yellow-400"
          />

          <!-- Loading skeleton -->
          <div
            v-if="isFetchingBilling"
            class="p-8 pt-9 flex flex-col items-center gap-5"
          >
            <div class="w-16 h-16 rounded-2xl bg-n-alpha-2 animate-pulse" />
            <div class="w-3/4 h-6 rounded-lg bg-n-alpha-2 animate-pulse" />
            <div class="w-full h-4 rounded-lg bg-n-alpha-2 animate-pulse" />
            <div class="w-full space-y-2">
              <div
                v-for="i in 5"
                :key="i"
                class="h-4 rounded-lg bg-n-alpha-2 animate-pulse"
              />
            </div>
            <div class="w-full h-10 rounded-xl bg-n-alpha-2 animate-pulse" />
          </div>

          <!-- Content -->
          <div
            v-else
            class="p-8 pt-9 flex flex-col items-center text-center gap-5"
          >
            <!-- Icon -->
            <div class="flex items-center justify-center pt-2 pb-1">
              <span class="text-[56px] leading-none drop-shadow-md">🎁</span>
            </div>

            <!-- Heading -->
            <div class="space-y-2">
              <h2 class="text-[22px] font-bold text-n-slate-12 leading-tight">
                {{ t('COMPONENTS.WELCOME_TRIAL_MODAL.TITLE') }}
              </h2>
              <p class="text-sm text-n-slate-11 leading-relaxed">
                {{ t('COMPONENTS.WELCOME_TRIAL_MODAL.DESCRIPTION_PART_1') }}
                <span class="font-semibold text-n-orange">
                  {{
                    t('COMPONENTS.WELCOME_TRIAL_MODAL.DESCRIPTION_PART_TRIAL')
                  }}
                </span>
                {{ t('COMPONENTS.WELCOME_TRIAL_MODAL.DESCRIPTION_PART_2') }}
                <span class="font-semibold text-n-slate-12">Basic</span>
                {{ t('COMPONENTS.WELCOME_TRIAL_MODAL.DESCRIPTION_PART_3') }}
              </p>
            </div>

            <!-- CTA -->
            <div class="w-full pt-1">
              <Button
                v-if="trialPlan"
                class="w-full justify-center"
                size="md"
                solid
                :label="t('COMPONENTS.WELCOME_TRIAL_MODAL.BUTTON_CONFIRM')"
                @click="activateTrial"
              />
            </div>
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.welcome-fade-enter-active,
.welcome-fade-leave-active {
  transition: opacity 0.25s ease;
}

.welcome-fade-enter-active .welcome-modal-box {
  transition:
    transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1),
    opacity 0.25s ease;
}
.welcome-fade-leave-active .welcome-modal-box {
  transition:
    transform 0.2s ease,
    opacity 0.2s ease;
}

.welcome-fade-enter-from,
.welcome-fade-leave-to {
  opacity: 0;
}

.welcome-fade-enter-from .welcome-modal-box {
  transform: translateY(20px) scale(0.96);
}
.welcome-fade-leave-to .welcome-modal-box {
  transform: translateY(-10px) scale(0.97);
}
</style>
