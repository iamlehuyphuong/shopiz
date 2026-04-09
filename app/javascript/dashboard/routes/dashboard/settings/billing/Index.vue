<script setup>
import { computed, onMounted, ref } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useAccount } from 'dashboard/composables/useAccount';
import { format, differenceInDays } from 'date-fns';
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
import BillingMeter from './components/BillingMeter.vue';

const { currentAccount } = useAccount();
const { fetchLimits } = useCaptain();

const uiFlags = useMapGetter('accounts/getUIFlags');
const store = useStore();

// State for handling loading
const purchaseCreditsModalRef = ref(null);

const customAttributes = computed(() => {
  return currentAccount.value.custom_attributes || {};
});

const usageData = computed(() => {
  return currentAccount.value?.billing?.usage;
});

const parseUsage = usageString => {
  if (!usageString) return { consumed: 0, totalCount: 0 };
  if (typeof usageString === 'number')
    return { consumed: usageString, totalCount: 0 };
  const [consumed, totalCount] = usageString.split(' / ').map(v => Number(v));
  return { consumed: consumed || 0, totalCount: totalCount || 0 };
};

const registrationLimitations = computed(() => {
  if (!usageData.value) return [];
  return [
    { key: 'agents', label: 'BILLING_SETTINGS.CURRENT_PLAN.AGENT' },
    { key: 'inboxes', label: 'BILLING_SETTINGS.CURRENT_PLAN.INBOX' },
    { key: 'contacts', label: 'BILLING_SETTINGS.CURRENT_PLAN.CONTACT' },
    { key: 'automations', label: 'BILLING_SETTINGS.CURRENT_PLAN.AUTOMATION' },
  ].filter(item => usageData.value[item.key]);
});

const aiLimitations = computed(() => {
  if (!usageData.value) return [];
  return [
    {
      key: 'captain_assistants',
      label: 'BILLING_SETTINGS.CURRENT_PLAN.AI_ASSISTANT',
    },
    {
      key: 'captain_credit',
      label: 'BILLING_SETTINGS.CURRENT_PLAN.AI_RESPONSE',
    },
    {
      key: 'captain_documents',
      label: 'BILLING_SETTINGS.CURRENT_PLAN.AI_DOCUMENT',
    },
    { key: 'captain_faqs', label: 'BILLING_SETTINGS.CURRENT_PLAN.AI_FAQ' },
  ].filter(item => usageData.value[item.key]);
});

const currentSubscription = computed(() => {
  return currentAccount.value?.billing?.current_subscription || {};
});

const currentAddons = computed(() => {
  return currentAccount.value?.billing?.current_addons || [];
});

const allAddonPackages = computed(() => {
  return (currentAccount.value?.billing?.all_addon_packages || []).filter(
    addon => addon.visible
  );
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

const planId = computed(() => {
  return customAttributes.value.stripe_product_id;
});

const billingHistories = computed(() => {
  return (currentAccount.value?.billing?.billing_histories || []).filter(
    history => history.price_amount > 0
  );
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

const daysUntilRefresh = computed(() => {
  const startsAtStr = currentSubscription.value.starts_at;
  const endsAtStr =
    currentSubscription.value.ends_at ||
    customAttributes.value.subscription_ends_on;

  if (!startsAtStr && !endsAtStr) return null;

  const now = new Date();

  // If we have starts_at, AI resources reset monthly on the same day of the month
  if (startsAtStr) {
    const startsAt = new Date(startsAtStr);
    const resetDay = startsAt.getDate();

    // Try current month first
    let nextReset = new Date(now.getFullYear(), now.getMonth(), resetDay);

    // If already passed or today, move to next month
    if (nextReset <= now) {
      nextReset = new Date(now.getFullYear(), now.getMonth() + 1, resetDay);
    }

    // Handle end-of-month overflow (e.g., reset on 31st but next month only has 30 days)
    // If the date changed because of overflow (e.g. became 1st of following month),
    // set it to the last day of the intended month.
    if (nextReset.getDate() !== resetDay && resetDay > 28) {
      nextReset = new Date(nextReset.getFullYear(), nextReset.getMonth(), 0);
    }

    const diff = differenceInDays(nextReset, now);
    return diff >= 0 ? diff : 0;
  }

  // Fallback to subscription end date
  const endDate = new Date(endsAtStr);
  const diff = differenceInDays(endDate, now);
  return diff > 0 ? diff : 0;
});

const isFreePlan = p => {
  if (!p) return true;
  const pAmount = p.price?.price_amount ?? 0;
  return Number(pAmount) === 0 || p.is_free === true;
};

const fetchAccountDetails = async () => {
  if (!hasABillingPlan.value) {
    await store.dispatch('accounts/subscription');
  }
  // Fetch available plans and other billing details
  store.dispatch('accounts/billings');
  // Always fetch limits for billing page to show credit usage
  fetchLimits();
};

const enterpisePlan = computed(() => {
  const plan = currentAccount.value?.billing?.enterprise_plan;
  return plan && !isFreePlan(plan) && plan.visible ? plan : null;
});

const trialPlan = computed(() => {
  const plan = currentAccount.value?.billing?.trial_plan;
  return plan && !isFreePlan(plan) && plan.visible ? plan : null;
});

const disabledRegisterTrial = computed(() => {
  return currentAccount.value?.billing?.disabled_register_trial;
});

const onClickBillingPortal = paymentInfo => {
  store.dispatch('accounts/checkout', paymentInfo);
};

const allVisiblePlans = computed(() => {
  const billingObj = currentAccount.value?.billing || {};
  const plansObj = billingObj.plans || {};
  
  return Object.keys(plansObj).reduce((acc, tier) => {
    const tierPlans = plansObj[tier] || [];
    const filtered = tierPlans.filter(p => !isFreePlan(p) && p.visible);
    return [...acc, ...filtered];
  }, []);
});

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
              :value="
                isFreePlan(currentSubscription) ? '---' : subscriptionRenewsOn
              "
            />
            <div class="flex items-center justify-center">
              <ButtonV4
                sm
                solid
                :color="isFreePlan(currentSubscription) ? 'slate' : 'ruby'"
                :disabled="isFreePlan(currentSubscription)"
                @click="
                  onClickBillingPortal({
                    product_id: currentSubscription.plan_id,
                    payment_method: 'payos',
                  })
                "
              >
                {{ $t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.RENEW_NOW') }}
              </ButtonV4>
            </div>
          </div>
        </BillingCard>
        <!-- Registration Management Section -->
        <BillingCard
          v-if="registrationLimitations.length"
          :title="$t('BILLING_SETTINGS.REGISTRATION_MANAGEMENT.TITLE')"
          :description="
            $t('BILLING_SETTINGS.REGISTRATION_MANAGEMENT.DESCRIPTION')
          "
        >
          <div class="grid sm:grid-cols-2 grid-cols-1 gap-x-12 gap-y-6 px-5">
            <template v-for="item in registrationLimitations" :key="item.key">
              <div v-if="usageData[item.key]">
                <BillingMeter
                  :title="$t(item.label)"
                  v-bind="parseUsage(usageData[item.key])"
                />
              </div>
            </template>
          </div>
        </BillingCard>

        <!-- AI Resources Section -->
        <BillingCard
          v-if="aiLimitations.length"
          :title="$t('BILLING_SETTINGS.AI_RESOURCE_MANAGEMENT.TITLE')"
          :description="
            $t('BILLING_SETTINGS.AI_RESOURCE_MANAGEMENT.DESCRIPTION')
          "
        >
          <div class="grid sm:grid-cols-2 grid-cols-1 gap-x-12 gap-y-6 px-5">
            <template v-for="item in aiLimitations" :key="item.key">
              <div v-if="usageData[item.key]">
                <BillingMeter
                  :title="$t(item.label)"
                  v-bind="parseUsage(usageData[item.key])"
                />
              </div>
            </template>
          </div>
          <div
            v-if="daysUntilRefresh !== null && !isFreePlan(currentSubscription)"
            class="mt-6 px-5 border-t border-n-weak pt-4"
          >
            <span class="text-xs font-medium text-n-slate-11">
              {{
                $t(
                  'BILLING_SETTINGS.AI_RESOURCE_MANAGEMENT.REFRESHES_IN_DAYS',
                  {
                    days: daysUntilRefresh,
                  }
                )
              }}
            </span>
          </div>
        </BillingCard>
        <BillingCard
          :title="$t('BILLING_SETTINGS.PRICING_PACKAGES.HEADING.TITLE')"
          :description="
            $t('BILLING_SETTINGS.PRICING_PACKAGES.HEADING.DESCRIPTION')
          "
        >
          <!-- Special Plans (Trial / Enterprise) -->
          <div
            v-if="trialPlan || enterpisePlan"
            class="grid grid-cols-1 md:grid-cols-2 gap-6 px-8 mb-8"
          >
            <SpecialItem v-if="trialPlan" :plan="trialPlan">
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
            <SpecialItem v-if="enterpisePlan" :plan="enterpisePlan">
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

          <!-- Divider if needed -->
          <div
            v-if="(trialPlan || enterpisePlan) && allVisiblePlans.length"
            class="px-8 pb-8"
          >
            <div class="border-t border-n-weak" />
          </div>

          <!-- Normal Plans -->
          <div
            v-if="allVisiblePlans.length"
            class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 px-8 pb-8"
          >
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
          description=""
        >
          <div
            class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6 px-8 pb-8"
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
          v-if="billingHistories.length"
          :title="$t('BILLING_SETTINGS.BILLING_HISTORY')"
          description=""
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
          <div class="flex flex-wrap gap-3 mt-4">
            <a
              href="https://m.me/shopiz.pro"
              target="_blank"
              rel="noopener noreferrer"
            >
              <ButtonV4 sm solid blue icon="i-woot-messenger">
                {{ $t('BILLING_SETTINGS.FACEBOOK_SUPPORT') }}
              </ButtonV4>
            </a>
            <a
              href="https://zalo.me/0878982525"
              target="_blank"
              rel="noopener noreferrer"
            >
              <ButtonV4 sm solid blue icon="i-ri-zalo-fill">
                {{ $t('BILLING_SETTINGS.ZALO_SUPPORT') }}
              </ButtonV4>
            </a>
          </div>
        </BillingHeader>
      </section>
      <PurchaseCreditsModal
        ref="purchaseCreditsModalRef"
        @success="handleTopupSuccess"
      />
    </template>
  </SettingsLayout>
</template>
