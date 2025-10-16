<script setup>
import { computed, onMounted, ref } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { format } from 'date-fns';
import { useI18n } from 'vue-i18n';
import BillingMeter from './components/BillingMeter.vue';
import BillingCard from './components/BillingCard.vue';
import BillingCardWide from './components/BillingCardWide.vue';
import BillingHeader from './components/BillingHeader.vue';
import DetailItem from './components/DetailItem.vue';
import BenefitItem from './components/BenefitItem.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ButtonV4 from 'next/button/Button.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';

const { t } = useI18n();
const { currentAccount } = useAccount();
const {
  captainEnabled,
  captainLimits,
  documentLimits,
  responseLimits,
  fetchLimits,
} = useCaptain();

const uiFlags = useMapGetter('accounts/getUIFlags');
const store = useStore();

const BILLING_REFRESH_ATTEMPTED = 'billing_refresh_attempted';

// State for handling refresh attempts and loading
const isWaitingForBilling = ref(false);

const customAttributes = computed(() => {
  return currentAccount.value.custom_attributes || {};
});

/**
 * Computed property for plan name
 * @returns {string|undefined}
 */
const planName = computed(() => {
  return customAttributes.value.plan_name;
});

/**
 * Computed property for plan name
 * @returns {string|undefined}
 */
const planId = computed(() => {
  console.log('customAttributes.value', customAttributes.value);
  return customAttributes.value.stripe_product_id;
});

const plans = computed(() => {
  return currentAccount.value.plans?.filter(plan => plan.name !== 'Enterprise') || [];
});

/**
 * Computed property for subscribed quantity
 * @returns {number|undefined}
 */
const subscribedQuantity = computed(() => {
  return customAttributes.value.subscribed_quantity;
});

const subscriptionRenewsOn = computed(() => {
  if (!customAttributes.value.subscription_ends_on) return '';
  const endDate = new Date(customAttributes.value.subscription_ends_on);
  // return date as 12 Jan, 2034
  return format(endDate, 'dd MMM, yyyy');
});

/**
 * Computed property indicating if user has a billing plan
 * @returns {boolean}
 */
const hasABillingPlan = computed(() => {
  return !!planName.value;
});

const fetchAccountDetails = async () => {
  store.dispatch('accounts/plans');
  if (!hasABillingPlan.value) {
    await store.dispatch('accounts/subscription');
    fetchLimits();
  }
};

const enterpisePlan = computed(() => {
  if (!currentAccount.value.plans) return null;
  return currentAccount.value.plans.find(plan => plan.name === 'Enterprise');
});

const onClickBillingPortal = (paymentInfo) => {
  store.dispatch('accounts/checkout', paymentInfo);
};

const onToggleChatWindow = () => {
  if (window.$shopiz) {
    window.$shopiz.toggle();
  }
};

const tabs = computed(() => {
  const PLAN_TABS_OPTIONS = [
    {
      key: 'MONTH',
      value: 'MONTH',
      count: '',
    },
    {
      key: 'HALF-YEAR',
      value: 'HALF-YEAR',
      count: '-10%',
    },
    {
      key: 'YEAR',
      value: 'YEAR',
      count: '-20%',
    },
  ];
  return PLAN_TABS_OPTIONS.map(tab => ({
    label: t(`BILLING_SETTINGS.PRICING_PACKAGES.${tab.key}`),
    value: tab.value,
    count: tab.count,
  }));
});

const activeTab = ref(0);

const formatCurrency = (price) => {
  if (!price) return '';
  const { amount_type, price_amount, price_currency } = price;
  if(amount_type === 'free')
    return 'Free';
  if (amount_type === 'custom') {
    return 'Contact for consultation';
  }
  const amount = (price_amount / 100) * 25000;
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
    maximumFractionDigits: 0,
  }).format(amount) + ' / month';
};

const handleTabChange = selectedTab => {
  activeTab.value = tabs.value.findIndex(
    tabItem => tabItem.value === selectedTab.value
  );
};

onMounted(fetchAccountDetails);
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetchingItem || isWaitingForBilling"
    :loading-message="
      isWaitingForBilling
        ? $t('BILLING_SETTINGS.NO_BILLING_USER')
        : $t('ATTRIBUTES_MGMT.LOADING')
    "
    :no-records-found="!hasABillingPlan && !isWaitingForBilling"
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
          <div
            v-if="planName || subscribedQuantity || subscriptionRenewsOn"
            class="grid lg:grid-cols-4 sm:grid-cols-3 grid-cols-1 gap-2 divide-x divide-n-weak"
          >
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.TITLE')"
              :value="planName"
            />
            <DetailItem
              v-if="subscribedQuantity"
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.SEAT_COUNT')"
              :value="subscribedQuantity"
            />
            <DetailItem
              v-if="subscriptionRenewsOn"
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.RENEWS_ON')"
              :value="subscriptionRenewsOn"
            />
          </div>
        </BillingCard>
        <BillingHeader
          class="px-1"
          :title="$t('BILLING_SETTINGS.PRICING_PACKAGES.HEADING.TITLE')"
          :description="$t('BILLING_SETTINGS.PRICING_PACKAGES.HEADING.DESCRIPTION')"
        />
        <TabBar
          :tabs="tabs"
          :initial-active-tab="activeTab"
          class="w-full [&>button]:w-full"
          @tab-changed="handleTabChange"
        />
        <template v-for="(tab, index) in tabs" :key="tab.key">
          <div
            v-show="activeTab === index"
            class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4"
          >
            <template v-for="plan in plans" :key="plan.products[index].id">
              <BillingCard
                :title="plan.products[index].name"
                :price="formatCurrency(plan.products[index]?.prices[0])"
                :description="plan.products[index].description"
              >
                <template #action>
                  <div class="flex justify-center">
                    <ButtonV4
                      md
                      solid
                      ruby
                      @disabled="planId === plan.products[index].id"
                      @click="onClickBillingPortal({
                        product_id: plan.products[index].id,
                        payment_method: 'vnpay',
                      })">
                    {{ planId === plan.products[index].id ? $t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.CURRENT_PACKAGE') : $t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.UPGRADE_NOW') }}
                    </ButtonV4>
                  </div>
                </template>
                <template v-for="benefit in plan.products[index].benefits" :key="benefit.id">
                  <div class="grid lg:grid-cols-1 sm:grid-cols-1 grid-cols-1 gap-2 divide-x divide-n-weak">
                    <BenefitItem :label="benefit.description" />
                  </div>
                </template>
              </BillingCard>
          </template>
          </div>
        </template>
        <BillingCardWide
          v-if="enterpisePlan"
          :title="enterpisePlan.products[0].name"
          :price="formatCurrency(enterpisePlan.products[0]?.prices[0])"
          :description="enterpisePlan.products[0].description"
        >
          <template #action>
            <div class="flex justify-start">
              <ButtonV4
                sm
                solid
                blue
                width="100%"
                @click="onToggleChatWindow"
              >
                {{ $t('CONTACTS_LAYOUT.HEADER.TITLE') }}
              </ButtonV4>
            </div>
          </template>
          <div class="grid lg:grid-cols-1 sm:grid-cols-1 grid-cols-1 gap-2 divide-x divide-n-weak">
            <span><strong>{{$t('BILLING_SETTINGS.PRICING_PACKAGES.HEADING.FEATURES')}}</strong></span>
            <template v-for="benefit in enterpisePlan.products[0].benefits" :key="benefit.id">
              <BenefitItem :label="benefit.description" />
            </template>
          </div>
        </BillingCardWide>
        <BillingCard
          v-if="captainEnabled"
          :title="$t('BILLING_SETTINGS.CAPTAIN.TITLE')"
          :description="$t('BILLING_SETTINGS.CAPTAIN.DESCRIPTION')"
        >
          <template #action>
            <ButtonV4 sm faded slate disabled>
              {{ $t('BILLING_SETTINGS.CAPTAIN.BUTTON_TXT') }}
            </ButtonV4>
          </template>
          <div v-if="captainLimits && responseLimits" class="px-5">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CAPTAIN.RESPONSES')"
              v-bind="responseLimits"
            />
          </div>
          <div v-if="captainLimits && documentLimits" class="px-5">
            <BillingMeter
              :title="$t('BILLING_SETTINGS.CAPTAIN.DOCUMENTS')"
              v-bind="documentLimits"
            />
          </div>
        </BillingCard>
        <BillingCard
          v-else
          :title="$t('BILLING_SETTINGS.CAPTAIN.TITLE')"
          :description="$t('BILLING_SETTINGS.CAPTAIN.UPGRADE')"
        >
          <template #action>
            <ButtonV4 sm solid slate @click="onClickBillingPortal">
              {{ $t('CAPTAIN.PAYWALL.UPGRADE_NOW') }}
            </ButtonV4>
          </template>
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
    </template>
  </SettingsLayout>
</template>
