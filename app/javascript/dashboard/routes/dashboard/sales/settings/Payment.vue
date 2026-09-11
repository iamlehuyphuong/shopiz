<script setup>
import { ref, computed, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import SectionLayout from 'dashboard/routes/dashboard/settings/account/components/SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextInput from 'next/input/Input.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import { useVuelidate } from '@vuelidate/core';
import { requiredIf } from '@vuelidate/validators';
import { copyTextToClipboard } from 'shared/helpers/clipboard';

const { t } = useI18n();
const store = useStore();
const { currentAccount } = useAccount();

const isLoading = computed(() => {
  return store.getters['accounts/getUIFlags'].isFetchingItem;
});

const isSaving = ref(false);
const isTesting = ref(false);

const tabs = computed(() => [
  { label: 'SePay', key: 'sepay' },
  { label: 'PayOS', key: 'payos' },
  { label: t('PAYMENT_SETTINGS.TINGEE.TAB_TITLE') || 'Tingee', key: 'tingee' },
]);

const activeTabIndex = ref(0);
const activeTabKey = computed(() => tabs.value[activeTabIndex.value].key);

const handleTabChange = tab => {
  activeTabIndex.value = tabs.value.findIndex(t => t.key === tab.key);
};

const defaultProvider = ref('');

const sepayConfig = reactive({
  active: false,
  company_name: '',
  company_code: '',
  secret_key: '',
});

const payosConfig = reactive({
  active: false,
  client_id: '',
  api_key: '',
  checksum_key: '',
});

const loadConfig = () => {
  const config = currentAccount.value?.settings?.sales_payment_config || {};
  defaultProvider.value = config.default_provider || '';

  const sepay = config.sepay || {};
  sepayConfig.active = !!sepay.active;
  sepayConfig.company_name = sepay.company_name || '';
  sepayConfig.company_code = sepay.company_code || '';
  sepayConfig.secret_key = sepay.secret_key || '';

  const payos = config.payos || {};
  payosConfig.active = !!payos.active;
  payosConfig.client_id = payos.client_id || '';
  payosConfig.api_key = payos.api_key || '';
  payosConfig.checksum_key = payos.checksum_key || '';
};

watch(
  currentAccount,
  () => {
    if (currentAccount.value) {
      loadConfig();
    }
  },
  { deep: true, immediate: true }
);

const handleDefaultProviderChange = (provider, value) => {
  if (value) {
    defaultProvider.value = provider;
  } else if (defaultProvider.value === provider) {
    defaultProvider.value = '';
  }
};

const rules = computed(() => {
  return {
    sepayConfig: {
      company_name: { required: requiredIf(() => defaultProvider.value === 'sepay' || !!sepayConfig.company_code || !!sepayConfig.secret_key) },
      company_code: { required: requiredIf(() => defaultProvider.value === 'sepay' || !!sepayConfig.company_name || !!sepayConfig.secret_key) },
      secret_key: { required: requiredIf(() => defaultProvider.value === 'sepay' || !!sepayConfig.company_name || !!sepayConfig.company_code) },
    },
    payosConfig: {
      client_id: { required: requiredIf(() => defaultProvider.value === 'payos' || !!payosConfig.api_key || !!payosConfig.checksum_key) },
      api_key: { required: requiredIf(() => defaultProvider.value === 'payos' || !!payosConfig.client_id || !!payosConfig.checksum_key) },
      checksum_key: { required: requiredIf(() => defaultProvider.value === 'payos' || !!payosConfig.client_id || !!payosConfig.api_key) },
    },
  };
});

const v$ = useVuelidate(rules, { sepayConfig, payosConfig });

const handleSave = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) {
    useAlert(t('GENERAL_SETTINGS.FORM.ERROR'));
    return;
  }

  isSaving.value = true;
  try {
    const payload = {
      sales_payment_config: {
        default_provider: defaultProvider.value,
        sepay: {
          active: !!(sepayConfig.company_code && sepayConfig.secret_key && sepayConfig.company_name),
          company_name: sepayConfig.company_name,
          company_code: sepayConfig.company_code,
          secret_key: sepayConfig.secret_key,
        },
        payos: {
          active: !!(payosConfig.client_id && payosConfig.api_key && payosConfig.checksum_key),
          client_id: payosConfig.client_id,
          api_key: payosConfig.api_key,
          checksum_key: payosConfig.checksum_key,
        },
      },
    };

    await store.dispatch('accounts/update', payload);
    useAlert(t('GENERAL_SETTINGS.UPDATE.SUCCESS'));
  } catch (error) {
    useAlert(error.message || t('GENERAL_SETTINGS.UPDATE.ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const handleTestPayment = async () => {
  isTesting.value = true;
  try {
    const response = await window.axios.post(`/api/v1/accounts/${currentAccount.value.id}/sales/payment_settings/test_payment`);
    if (response.data.checkout_url) {
      window.location.href = response.data.checkout_url;
    }
  } catch (error) {
    useAlert(error.response?.data?.error || error.message || t('GENERAL_SETTINGS.UPDATE.ERROR'));
  } finally {
    isTesting.value = false;
  }
};

const host = window.location.origin;
const sepayWebhookUrl = computed(() =>
  currentAccount.value
    ? `${host}/api/v1/webhooks/sales_payments/sepay/${currentAccount.value.id}`
    : ''
);
const payosWebhookUrl = computed(() =>
  currentAccount.value
    ? `${host}/api/v1/webhooks/sales_payments/payos/${currentAccount.value.id}`
    : ''
);

const handleCopy = async (text) => {
  await copyTextToClipboard(text);
  useAlert(t('COMPONENTS.CODE.COPIED') || 'Copied successfully');
};
</script>

<template>
  <div class="w-full h-full overflow-auto">
    <!-- Skeleton Loading -->
    <div v-if="isLoading" class="max-w-5xl mx-auto px-6 py-6 animate-pulse">
      <div class="h-6 w-48 rounded bg-n-slate-3 mb-6" />
      <div class="h-40 w-full rounded-xl bg-n-slate-3 mb-6" />
      <div class="h-40 w-full rounded-xl bg-n-slate-3" />
    </div>

    <div v-else class="max-w-5xl mx-auto px-6 py-6 flex flex-col gap-6">
      <div class="flex flex-col gap-1">
        <h3 class="text-lg font-semibold text-n-slate-12">
          {{ $t('PAYMENT_SETTINGS.TITLE') || 'Payment Settings' }}
        </h3>
        <p class="text-sm text-n-slate-11">
          {{
            $t('PAYMENT_SETTINGS.DESCRIPTION') ||
            'Configure payment gateways for your sales.'
          }}
        </p>
      </div>

      <div class="flex items-center gap-4">
        <TabBar
          :tabs="tabs"
          :initial-active-tab="activeTabIndex"
          @tab-changed="handleTabChange"
        />
      </div>

      <div class="flex flex-col gap-6">
        <!-- SePay -->
        <SectionLayout
          v-if="activeTabKey === 'sepay'"
          :title="$t('PAYMENT_SETTINGS.SEPAY.TITLE') || 'SePay Configuration'"
        >
          <form class="grid gap-4 mt-2" @submit.prevent="handleSave">
            <div class="grid gap-4">
              <div class="flex items-center justify-between">
                <span class="text-sm font-medium text-n-slate-12">{{ $t('PAYMENT_SETTINGS.DEFAULT_PROVIDER') || 'Default Payment Gateway' }}</span>
                <Switch
                  :model-value="defaultProvider === 'sepay'"
                  @update:model-value="val => handleDefaultProviderChange('sepay', val)"
                />
              </div>

              <WithLabel
                name="sepay-company-name"
                :has-error="v$.sepayConfig.company_name.$error"
                :label="$t('PAYMENT_SETTINGS.SEPAY.COMPANY_NAME') || 'Company Name'"
              >
                <NextInput
                  v-model="sepayConfig.company_name"
                  type="text"
                  class="w-full"
                  @blur="v$.sepayConfig.company_name.$touch"
                />
              </WithLabel>

              <WithLabel
                name="sepay-company-code"
                :has-error="v$.sepayConfig.company_code.$error"
                :label="
                  $t('PAYMENT_SETTINGS.SEPAY.COMPANY_CODE') || 'Company Code'
                "
              >
                <NextInput
                  v-model="sepayConfig.company_code"
                  type="text"
                  class="w-full"
                  @blur="v$.sepayConfig.company_code.$touch"
                />
              </WithLabel>

              <WithLabel
                name="sepay-secret-key"
                :has-error="v$.sepayConfig.secret_key.$error"
                :label="$t('PAYMENT_SETTINGS.SEPAY.SECRET_KEY') || 'Secret Key'"
              >
                <NextInput
                  v-model="sepayConfig.secret_key"
                  type="password"
                  class="w-full"
                  @blur="v$.sepayConfig.secret_key.$touch"
                />
              </WithLabel>

              <WithLabel name="sepay-webhook-url" :label="$t('PAYMENT_SETTINGS.WEBHOOK_URL') || 'Webhook URL (Read-only)'">
                <div class="flex items-center gap-2 w-full">
                  <NextInput
                    v-model="sepayWebhookUrl"
                    type="text"
                    class="w-full text-n-slate-9"
                    readonly
                  />
                  <NextButton
                    type="button"
                    icon="i-lucide-copy"
                    color="slate"
                    variant="faded"
                    class="shrink-0"
                    @click.prevent="handleCopy(sepayWebhookUrl)"
                  />
                </div>
              </WithLabel>
            </div>
          </form>
        </SectionLayout>

        <!-- PayOS -->
        <SectionLayout
          v-if="activeTabKey === 'payos'"
          :title="$t('PAYMENT_SETTINGS.PAYOS.TITLE') || 'PayOS Configuration'"
        >
          <form class="grid gap-4 mt-2" @submit.prevent="handleSave">
            <div class="grid gap-4">
              <div class="flex items-center justify-between">
                <span class="text-sm font-medium text-n-slate-12">{{ $t('PAYMENT_SETTINGS.DEFAULT_PROVIDER') || 'Default Payment Gateway' }}</span>
                <Switch
                  :model-value="defaultProvider === 'payos'"
                  @update:model-value="val => handleDefaultProviderChange('payos', val)"
                />
              </div>

              <WithLabel
                name="payos-client-id"
                :has-error="v$.payosConfig.client_id.$error"
                :label="$t('PAYMENT_SETTINGS.PAYOS.CLIENT_ID') || 'Client ID'"
              >
                <NextInput
                  v-model="payosConfig.client_id"
                  type="text"
                  class="w-full"
                  @blur="v$.payosConfig.client_id.$touch"
                />
              </WithLabel>

              <WithLabel
                name="payos-api-key"
                :has-error="v$.payosConfig.api_key.$error"
                :label="$t('PAYMENT_SETTINGS.PAYOS.API_KEY') || 'API Key'"
              >
                <NextInput
                  v-model="payosConfig.api_key"
                  type="password"
                  class="w-full"
                  @blur="v$.payosConfig.api_key.$touch"
                />
              </WithLabel>

              <WithLabel
                name="payos-checksum-key"
                :has-error="v$.payosConfig.checksum_key.$error"
                :label="
                  $t('PAYMENT_SETTINGS.PAYOS.CHECKSUM_KEY') || 'Checksum Key'
                "
              >
                <NextInput
                  v-model="payosConfig.checksum_key"
                  type="password"
                  class="w-full"
                  @blur="v$.payosConfig.checksum_key.$touch"
                />
              </WithLabel>

              <WithLabel name="payos-webhook-url" :label="$t('PAYMENT_SETTINGS.WEBHOOK_URL') || 'Webhook URL (Read-only)'">
                <div class="flex items-center gap-2 w-full">
                  <NextInput
                    v-model="payosWebhookUrl"
                    type="text"
                    class="w-full text-n-slate-9"
                    readonly
                  />
                  <NextButton
                    type="button"
                    icon="i-lucide-copy"
                    color="slate"
                    variant="faded"
                    class="shrink-0"
                    @click.prevent="handleCopy(payosWebhookUrl)"
                  />
                </div>
              </WithLabel>
            </div>
          </form>
        </SectionLayout>
        
        <!-- Tingee -->
        <SectionLayout
          v-if="activeTabKey === 'tingee'"
          :title="$t('PAYMENT_SETTINGS.TINGEE.TITLE') || 'Tingee Configuration'"
        >
          <div class="py-12 flex flex-col items-center justify-center bg-n-alpha-black2 rounded-lg border border-dashed border-n-weak">
            <div class="w-12 h-12 rounded-full bg-n-alpha-2 flex items-center justify-center mb-4">
              <fluent-icon icon="rocket" class="w-6 h-6 text-n-slate-11" />
            </div>
            <h4 class="text-n-slate-12 font-medium mb-2">{{ $t('PAYMENT_SETTINGS.TINGEE.EMPTY_STATE_TITLE') || 'Feature in development' }}</h4>
            <p class="text-sm text-n-slate-11 text-center max-w-md">
              {{ $t('PAYMENT_SETTINGS.TINGEE.EMPTY_STATE_DESC') }}
            </p>
          </div>
        </SectionLayout>

        <div class="flex items-center justify-end gap-3 mt-4">
          <NextButton
            variant="faded"
            color="slate"
            :disabled="activeTabKey === 'tingee'"
            :is-loading="isTesting"
            @click="handleTestPayment"
          >
            {{ $t('PAYMENT_SETTINGS.TEST_PAYMENT') || 'Test Payment' }}
          </NextButton>
          <NextButton blue :is-loading="isSaving" @click="handleSave">
            {{ $t('GENERAL_SETTINGS.SUBMIT') }}
          </NextButton>
        </div>
      </div>
    </div>
  </div>
</template>
