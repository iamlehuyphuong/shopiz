<script setup>
import { computed, onMounted } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { format } from 'date-fns';
import { useI18n } from 'vue-i18n';
import BillingCard from './components/BillingCard.vue';
import BillingHeader from './components/BillingHeader.vue';
import DetailItem from './components/DetailItem.vue';
import PurchaseCreditsModal from './components/PurchaseCreditsModal.vue';
import SpecialItem from './components/SpecialPlanItem.vue';
import NormalItem from './components/NormalPlanItem.vue';
import CreditItem from './components/CreditItem.vue';
import BillingHistoryItem from './components/BillingHistoryItem.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ButtonV4 from 'next/button/Button.vue';

const router = useRouter();
const { currentAccount, isOnChatwootCloud } = useAccount();
const {
  captainEnabled,
  captainLimits,
  documentLimits,
  responseLimits,
  fetchLimits,
  isFetchingLimits,
} = useCaptain();

const uiFlags = useMapGetter('accounts/getUIFlags');
const store = useStore();

const BILLING_REFRESH_ATTEMPTED = 'billing_refresh_attempted';

// State for handling refresh attempts and loading
const isWaitingForBilling = ref(false);
const purchaseCreditsModalRef = ref(null);

const customAttributes = computed(() => {
  return currentAccount.value.custom_attributes || {};
});

const currentSubscription = computed(() => {
  return currentAccount.value?.billing?.current_subscription || {};
});

const currentAddons = computed(() => {
  return currentAccount.value?.billing?.current_addons || [];
});

const allAddonPackages = computed(() => {
  return currentAccount.value?.billing?.all_addon_packages || [];
});

const getActiveAddon = addonPackageId => {
  return currentAddons.value.find(
    item => item.addon_package_id === addonPackageId
  );
};

const planName = computed(() => {
  return (
    currentSubscription.value.plan_name || customAttributes.value.plan_name
  );
});

const hasABillingPlan = computed(() => {
  return (
    currentSubscription.value.plan_name || customAttributes.value.plan_name
  );
});

const canPurchaseCredits = computed(() => {
  const plan = planName.value?.toLowerCase();
  return plan && plan !== 'hacker';
});

const planId = computed(() => {
  return customAttributes.value.stripe_product_id;
});

const billingHistories = computed(() => {
  return currentAccount.value?.billing?.billing_histories || [];
});

const subscriptionRenewsOn = computed(() => {
  const endDateStr =
    currentSubscription.value.ends_at ||
    customAttributes.value.subscription_ends_on;
  if (!endDateStr) return '';

  const endDate = new Date(endDateStr);
  // return date as 12 Jan, 2034
  return format(endDate, 'dd MMM, yyyy');
});

const fetchAccountDetails = async () => {
  if (!hasABillingPlan.value) {
    await store.dispatch('accounts/subscription');
  }
  // Always fetch limits for billing page to show credit usage
  fetchLimits();
};

const enterpisePlan = computed(() => {
  return currentAccount.value?.billing?.enterprise_plan;
});

const trialPlan = computed(() => {
  return currentAccount.value?.billing?.trial_plan;
});

const usageData = computed(() => {
  return currentAccount.value?.billing?.usage;
});

const disabledRegisterTrial = computed(() => {
  return currentAccount.value?.billing?.disabled_register_trial;
});

const onClickBillingPortal = paymentInfo => {
  store.dispatch('accounts/checkout', paymentInfo);
};

const isFreePlan = plan => {
  return (plan?.price?.price_amount || 0) === 0 || plan?.is_free === true;
};

const allVisiblePlans = computed(() => {
  const result = [];
  const planData = currentAccount.value?.billing?.plans || {};
  Object.values(planData).forEach(tierPlans => {
    tierPlans.forEach(plan => {
      if (!isFreePlan(plan)) {
        result.push(plan);
      }
    });
  });
  return result;
});

const openPurchaseCreditsModal = () => {
  purchaseCreditsModalRef.value?.open();
};

const handleTopupSuccess = () => {
  // Refresh limits to show updated credit balance
  fetchLimits();
};

onMounted(fetchAccountDetails);
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetchingItem"
    :loading-message="$t('ATTRIBUTES_MGMT.LOADING')"
    :no-records-found="false"
    :no-records-message="$t('BILLING_SETTINGS.NO_BILLING_USER')"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('BILLING_SETTINGS.TITLE')"
        :description="$t('BILLING_SETTINGS.DESCRIPTION')"
        :link-text="$t('BILLING_SETTINGS.VIEW_PRICING')"
        feature-name="billing"
      />
    </template>
    <template #body>
      <section class="grid gap-4">
        <BillingCard
          :title="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.TITLE')"
          :description="$t('BILLING_SETTINGS.MANAGE_SUBSCRIPTION.DESCRIPTION')"
        >
          <div class="grid sm:grid-cols-3 grid-cols-1 gap-2 divide-n-weak">
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.TITLE')"
              :value="planName"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.RENEWS_ON')"
              :value="subscriptionRenewsOn"
            />
          </div>
        </BillingCard>

        <BillingCard
          v-if="captainEnabled"
          :title="$t('BILLING_SETTINGS.CAPTAIN.TITLE')"
          :description="$t('BILLING_SETTINGS.CAPTAIN.DESCRIPTION')"
        >
          <template #action>
            <div class="flex gap-2">
              <ButtonV4
                sm
                flushed
                slate
                icon="i-lucide-refresh-cw"
                :is-loading="isFetchingLimits"
                @click="fetchLimits"
              >
                {{ $t('BILLING_SETTINGS.CAPTAIN.REFRESH_CREDITS') }}
              </ButtonV4>
              <ButtonV4
                v-if="canPurchaseCredits"
                sm
                solid
                blue
                @click="openPurchaseCreditsModal"
              >
                {{ $t('BILLING_SETTINGS.TOPUP.BUY_CREDITS') }}
              </ButtonV4>
            </div>
          </template>
          <div v-if="captainLimits && responseLimits" class="px-5">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CAPTAIN.RESPONSES')"
              v-bind="responseLimits"
            />
          </div>
        </BillingCard>

        <BillingCard
          v-if="usageData"
          :title="$t('BILLING_SETTINGS.CURRENT_PLAN.ADDON_RESOURCE')"
        >
          <div class="grid sm:grid-cols-4 grid-cols-1 gap-2 mt-0">
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.AI_RESPONSE')"
              :value="usageData.captain_credit"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.INBOX')"
              :value="usageData.inboxes"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.AGENT')"
              :value="usageData.agents"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.CONTACT')"
              :value="usageData.contacts"
            />
          </div>
        </BillingCard>
        <BillingCard
          :title="$t('BILLING_SETTINGS.PRICING_PACKAGES.HEADING.TITLE')"
          :description="
            $t('BILLING_SETTINGS.PRICING_PACKAGES.HEADING.DESCRIPTION')
          "
        >
          <div
            v-if="trialPlan"
            class="grid grid-cols-1 md:grid-cols-2 gap-6 px-8"
          >
            <SpecialItem :plan="trialPlan">
              <ButtonV4
                md
                solid
                ruby
                :disabled="disabledRegisterTrial"
                @click="
                  onClickBillingPortal({
                    product_id: trialPlan.id,
                    payment_method: 'payos',
                  })
                "
              >
                {{
                  planId === trialPlan.id
                    ? $t(
                        'BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.CURRENT_PACKAGE'
                      )
                    : $t(
                        'BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.UPGRADE_NOW'
                      )
                }}
              </ButtonV4>
            </SpecialItem>
            <SpecialItem :plan="enterpisePlan">
              <a
                href="https://shopiz.pro/contact-us"
                target="_blank"
                rel="noopener noreferrer"
              >
                <ButtonV4 md solid blue>
                  {{ $t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.CONTACT') }}
                </ButtonV4>
              </a>
            </SpecialItem>
          </div>
          <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-8">
            <NormalItem
              v-for="plan in allVisiblePlans"
              :key="plan.id"
              :plan="plan"
            >
              <ButtonV4
                md
                solid
                ruby
                @click="
                  onClickBillingPortal({
                    product_id: plan.id,
                    payment_method: 'payos',
                  })
                "
              >
                {{
                  planId === plan.id
                    ? $t(
                        'BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.CURRENT_PACKAGE'
                      )
                    : $t(
                        'BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.UPGRADE_NOW'
                      )
                }}
              </ButtonV4>
            </NormalItem>
          </div>
        </BillingCard>

        <BillingCard
          v-if="allAddonPackages.length"
          :title="$t('BILLING_SETTINGS.CAPTAIN.GET_MORE')"
        >
          <div
            class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 p-8 pt-0"
          >
            <template v-for="addon in allAddonPackages" :key="addon.id">
              <CreditItem :credit-item="addon">
                <div v-if="getActiveAddon(addon.id)" class="text-center mb-4">
                  <span
                    class="px-2 py-0.5 rounded text-xs font-bold bg-n-blue-4 text-n-blue-11"
                  >
                    {{
                      $t('BILLING_SETTINGS.ADDON_QUANTITY', {
                        quantity: getActiveAddon(addon.id).quantity,
                      })
                    }}
                  </span>
                </div>
                <ButtonV4
                  md
                  solid
                  ruby
                  @click="
                    onClickBillingPortal({
                      product_id: addon.id,
                      payment_method: 'payos',
                    })
                  "
                >
                  {{ $t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.BUY_NOW') }}
                </ButtonV4>
              </CreditItem>
            </template>
          </div>
        </BillingCard>

        <BillingCard
          v-if="billingHistories"
          :title="$t('BILLING_SETTINGS.BILLING_HISTORY')"
        >
          <div class="p-8 pt-0 space-y-3">
            <template v-for="item in billingHistories" :key="item.id">
              <BillingHistoryItem :item="item" />
            </template>
          </div>
        </BillingCard>

        <BillingHeader
          class="px-1 mt-5"
          :title="$t('BILLING_SETTINGS.CHAT_WITH_US.TITLE')"
          :description="$t('BILLING_SETTINGS.CHAT_WITH_US.DESCRIPTION')"
        >
          <ButtonV4
            sm
            solid
            slate
            icon="i-lucide-life-buoy"
            @click="onToggleChatWindow"
          >
            {{ $t('BILLING_SETTINGS.CHAT_WITH_US.BUTTON_TXT') }}
          </ButtonV4>
        </BillingHeader>
      </section>
      <PurchaseCreditsModal
        ref="purchaseCreditsModalRef"
        @success="handleTopupSuccess"
      />
    </template>
  </SettingsLayout>
</template>
