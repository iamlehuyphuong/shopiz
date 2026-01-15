<script setup>
import { computed, onMounted, ref } from 'vue';
import { useMapGetter, useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { format } from 'date-fns';
import { useI18n } from 'vue-i18n';
import BillingCard from './components/BillingCard.vue';
import BillingHeader from './components/BillingHeader.vue';
import DetailItem from './components/DetailItem.vue';
import SpecialItem from './components/SpecialPlanItem.vue';
import NormalItem from './components/NormalPlanItem.vue';
import CreditItem from './components/CreditItem.vue';
import BillingHistoryItem from './components/BillingHistoryItem.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import SettingsLayout from '../SettingsLayout.vue';
import ButtonV4 from 'next/button/Button.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';

const { t } = useI18n();
const { currentAccount } = useAccount();
const { captainEnabled } = useCaptain();

const uiFlags = useMapGetter('accounts/getUIFlags');
const store = useStore();

const customAttributes = computed(() => {
  return currentAccount.value.custom_attributes || {};
});

const planName = computed(() => {
  return customAttributes.value.plan_name;
});

const captainResponseCredit = computed(() => {
  return customAttributes.value.captain_responses_credit;
})

const planId = computed(() => {
  return customAttributes.value.stripe_product_id;
});

const plans = computed(() => {
  return currentAccount.value?.billing?.plans || [];
});

const credits = computed(() => {
  return currentAccount.value?.billing?.credits || [];
})

const billingHistories = computed(() => {
  return currentAccount.value?.billing?.billing_histories || [];
})

const subscriptionRenewsOn = computed(() => {
  if (!customAttributes.value.subscription_ends_on) return '';

  const endDate = new Date(customAttributes.value.subscription_ends_on);
  // return date as 12 Jan, 2034
  return format(endDate, 'dd MMM, yyyy');
});

const fetchAccountDetails = async () => {
  store.dispatch('accounts/billings');
};

const enterpisePlan = computed(() => {
  return currentAccount.value?.billing?.enterprise_plan;
});

const trialPlan = computed(() => {
  return currentAccount.value?.billing?.trial_plan;
})

const usageData = computed(() => {
  return currentAccount.value?.billing?.usage;
})

const disabledRegisterTrial = computed(() => {
  return currentAccount.value?.billing?.disabled_register_trial;
})

const onClickBillingPortal = (paymentInfo) => {
  store.dispatch('accounts/checkout', paymentInfo);
};

const onToggleChatWindow = () => {
  if (window.$shopiz) {
    window.$shopiz.toggle();
  }
};

const tabs = computed(() => {
  return ['HALF-YEAR', 'YEAR'].map(item => ({
    label: t(`BILLING_SETTINGS.PRICING_PACKAGES.${item}`),
    value: item,
  }));
});

const activeTab = ref(0);

const handleTabChange = selectedTab => {
  activeTab.value = tabs.value.findIndex(
    tabItem => tabItem.value === selectedTab.value
  );
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
          <div
            class="grid sm:grid-cols-3 grid-cols-1 gap-2 divide-n-weak"
          >
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.TITLE')"
              :value="planName"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.RENEWS_ON')"
              :value="subscriptionRenewsOn"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.AI_ADDON_MESSAGE')"
              :value="captainResponseCredit"
            />
          </div>
        </BillingCard>
        <BillingCard
          v-if="usageData"
          :title="$t('BILLING_SETTINGS.CURRENT_PLAN.RESOURCE')"
        >
          <div
            class="grid sm:grid-cols-4 grid-cols-1 gap-2 mt-0"
          >
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.AGENT')"
              :value="usageData.agents"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.INBOX')"
              :value="usageData.inboxes"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.CONTACT')"
              :value="usageData.contacts"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.AUTOMATION')"
              :value="usageData.automations"
            />
          </div>
          <BillingHeader
            class="px-5"
            :title="$t('BILLING_SETTINGS.CURRENT_PLAN.AI_RESOURCE')"
          />
          <div
            class="grid sm:grid-cols-4 grid-cols-1 gap-2 mt-0"
          >
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.AI_DOCUMENT')"
              :value="usageData.captain_documents"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.AI_FAQ')"
              :value="usageData.captain_faqs"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.AI_ASSISTANT')"
              :value="usageData.captain_assistants"
            />
            <DetailItem
              :label="$t('BILLING_SETTINGS.CURRENT_PLAN.AI_RESPONSE')"
              :value="usageData.captain_credit"
            />
          </div>
        </BillingCard>
        <BillingCard
          :title="$t('BILLING_SETTINGS.PRICING_PACKAGES.HEADING.TITLE')"
          :description="$t('BILLING_SETTINGS.PRICING_PACKAGES.HEADING.DESCRIPTION')"
        >
          <div class="grid grid-cols-1 md:grid-cols-2 gap-6 px-8" v-if="trialPlan">
            <SpecialItem :plan="trialPlan">
              <ButtonV4
                md
                solid
                ruby
                :disabled="disabledRegisterTrial"
                @click="onClickBillingPortal({
                  product_id: trialPlan.id,
                  payment_method: 'payos',
                })">
              {{ planId === trialPlan.id ? $t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.CURRENT_PACKAGE') : $t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.UPGRADE_NOW') }}
              </ButtonV4>
            </SpecialItem>
            <SpecialItem :plan="enterpisePlan">
              <a
                href="https://shopiz.pro/contact-us"
                target="_blank"
              >
                <ButtonV4
                  md
                  solid
                  blue
                  >
                  {{ $t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.CONTACT') }}
                </ButtonV4>
              </a>
            </SpecialItem>
          </div>
          <TabBar
            :tabs="tabs"
            :initial-active-tab="activeTab"
            class="min-w-[500px] mx-auto mt-5 [&>button]:w-full"
            @tab-changed="handleTabChange"
          />
          <template v-for="(tab, index) in tabs" :key="tab.key">
            <div
              v-show="activeTab === index"
              class="grid grid-cols-3 gap-6 p-8 pt-0"
            >
              <template v-for="plan in plans" :key="plan[index].id">
                <NormalItem :plan="plan[index]">
                  <ButtonV4
                    md
                    solid
                    ruby
                    @click="onClickBillingPortal({
                      product_id: plan[index].id,
                      payment_method: 'payos',
                    })">
                  {{ (planName || '').toUpperCase() === plan[index].name ? $t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.CURRENT_PACKAGE') : $t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.UPGRADE_NOW') }}
                  </ButtonV4>
                </NormalItem>
              </template>
            </div>
          </template>
        </BillingCard>

        <BillingCard
          v-if="captainEnabled && credits"
          :title="$t('BILLING_SETTINGS.CAPTAIN.GET_MORE')"
        >
          <div class="grid grid-cols-3 gap-6 p-8 pt-0">
            <template v-for="credit in credits" :key="credit.id">
              <CreditItem :creditItem="credit">
                <ButtonV4
                  md
                  solid
                  ruby
                  @click="onClickBillingPortal({
                    product_id: credit.id,
                    payment_method: 'payos',
                  })">
                  {{ $t('BILLING_SETTINGS.PRICING_PACKAGES.BUTTONS.BUY_NOW') }}
                  </ButtonV4>
              </CreditItem>
            </template>
          </div>
        </BillingCard>
        <BillingCard
          v-else
          :title="$t('BILLING_SETTINGS.CAPTAIN.TITLE')"
          :description="$t('BILLING_SETTINGS.CAPTAIN.UPGRADE')"
        >
          <template #action>
            <ButtonV4 sm solid slate>
              {{ $t('CAPTAIN.PAYWALL.UPGRADE_NOW') }}
            </ButtonV4>
          </template>
        </BillingCard>

        <BillingCard
          v-if="billingHistories"
          :title="$t('BILLING_SETTINGS.BILLING_HISTORY')"
        >
          <div class="p-8 pt-0 space-y-3">
            <template v-for="item in billingHistories" :key="item.id">
              <BillingHistoryItem :item="item">
              </BillingHistoryItem>
            </template>
          </div>
        </BillingCard>

        <BillingHeader
          class="px-1 mt-5"
          :title="$t('BILLING_SETTINGS.CHAT_WITH_US.TITLE')"
          :description="$t('BILLING_SETTINGS.CHAT_WITH_US.DESCRIPTION')"
        >
        </BillingHeader>
      </section>
    </template>
  </SettingsLayout>
</template>
