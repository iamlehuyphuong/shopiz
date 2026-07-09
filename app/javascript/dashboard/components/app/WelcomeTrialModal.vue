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
const { locale } = useI18n();

const isLoading = ref(false);
const isFetchingBilling = ref(false);

const isVietnamese = computed(() => locale.value === 'vi');

const trialPlan = computed(() => {
  const billing = currentAccount.value?.billing;
  if (!billing) return null;

  // Find Basic plan in plans list
  const plans = billing.plans || [];
  const basicTier = plans.find(t => (t.tier_name_en || '').toLowerCase().includes('basic'));
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
  (newVal) => {
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

const features = computed(() => {
  const plan = trialPlan.value;
  if (!plan || !plan.benefits) return [];

  // benefits is an array of categories, we need LIMITATIONS
  const limitCategory = plan.benefits.find(cat => cat.name && cat.name.includes('LIMITATIONS'));
  const limitItems = limitCategory ? limitCategory.items : [];

  const getLimit = (key) => {
    const item = limitItems.find(i => i.id === `limit_${key}`);
    return item ? item.count : 0;
  };

  const inboxes = getLimit('inboxes');
  const agents = getLimit('agents');
  const captainResponses = getLimit('captain_responses');
  const automations = getLimit('automations');

  const list = [];
  
  if (inboxes) {
    list.push(
      isVietnamese.value
        ? `${inboxes} hộp thư (kênh)`
        : `${inboxes} inboxes (channels)`
    );
  }
  
  if (agents) {
    list.push(
      isVietnamese.value
        ? `${agents} tài khoản nhân viên`
        : `${agents} agent accounts`
    );
  }
  
  if (captainResponses) {
    list.push(
      isVietnamese.value
        ? `Chatbot AI (${captainResponses} phản hồi/tháng)`
        : `AI Chatbot (${captainResponses} responses/month)`
    );
  }
  
  if (automations) {
    list.push(
      isVietnamese.value
        ? `${automations} Automations (Tự động hóa)`
        : `${automations} Automations`
    );
  }
  
  return list;
});
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
            <div v-if="isFetchingBilling" class="p-8 pt-9 flex flex-col items-center gap-5">
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
            <div v-else class="p-8 pt-9 flex flex-col items-center text-center gap-5">
              <!-- Icon -->
              <div class="flex items-center justify-center pt-2 pb-1">
                <span class="text-[56px] leading-none drop-shadow-md">🎁</span>
              </div>

              <!-- Heading -->
              <div class="space-y-2">
                <h2 class="text-[22px] font-bold text-n-slate-12 leading-tight">
                  {{
                    isVietnamese
                      ? 'Chào mừng bạn đến với Shopiz!'
                      : 'Welcome to Shopiz!'
                  }}
                </h2>
                <p class="text-sm text-n-slate-11 leading-relaxed">
                  {{
                    isVietnamese
                      ? 'Cảm ơn bạn đã tham gia. Chúng tôi tặng bạn'
                      : "Thanks for joining! We'd like to gift you"
                  }}
                  <span class="font-semibold text-n-orange">
                    {{
                      isVietnamese
                        ? '1 tháng dùng thử miễn phí'
                        : '1 month free trial'
                    }}
                  </span>
                  {{ isVietnamese ? 'gói' : 'of the' }}
                  <span class="font-semibold text-n-slate-12">Basic</span>
                  {{ isVietnamese ? 'để bắt đầu.' : 'plan to get started.' }}
                </p>
              </div>

              <!-- CTA -->
              <div class="w-full pt-1">
                <Button
                  v-if="trialPlan"
                  class="w-full justify-center"
                  size="md"
                  solid
                  :label="isVietnamese ? 'Xác nhận' : 'Confirm'"
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
  transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1), opacity 0.25s ease;
}
.welcome-fade-leave-active .welcome-modal-box {
  transition: transform 0.2s ease, opacity 0.2s ease;
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
