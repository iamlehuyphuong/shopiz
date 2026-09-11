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
  { label: 'Tingee (sắp tích hợp)', key: 'tingee' },
]);

const activeTabIndex = ref(0);
const activeTabKey = computed(() => tabs.value[activeTabIndex.value].key);

const handleTabChange = tab => {
  activeTabIndex.value = tabs.value.findIndex(t => t.key === tab.key);
};

const defaultProvider = ref('');

const sepayConfig = reactive({
  active: false,
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
      company_code: { required: requiredIf(() => sepayConfig.active) },
      secret_key: { required: requiredIf(() => sepayConfig.active) },
    },
    payosConfig: {
      client_id: { required: requiredIf(() => payosConfig.active) },
      api_key: { required: requiredIf(() => payosConfig.active) },
      checksum_key: { required: requiredIf(() => payosConfig.active) },
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
          active: sepayConfig.active,
          company_code: sepayConfig.company_code,
          secret_key: sepayConfig.secret_key,
        },
        payos: {
          active: payosConfig.active,
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

      <div class="flex items-center gap-4 border-b border-n-weak pb-4">
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
          with-border
        >
          <template #headerActions>
            <div class="flex items-center gap-4">
              <div class="flex items-center gap-2">
                <span class="text-sm font-medium text-n-slate-11">Kênh thanh toán mặc định</span>
                <Switch
                  :model-value="defaultProvider === 'sepay'"
                  @update:model-value="val => handleDefaultProviderChange('sepay', val)"
                />
              </div>
              <div class="w-px h-4 bg-n-strong" />
              <Switch v-model="sepayConfig.active" />
            </div>
          </template>

          <form class="grid gap-4 mt-2" @submit.prevent="handleSave">
            <div
              v-if="sepayConfig.active"
              class="grid gap-4 bg-n-alpha-black2 p-4 rounded-lg"
            >
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

              <WithLabel name="sepay-webhook-url" label="Webhook URL (Read-only)">
                <NextInput
                  v-model="sepayWebhookUrl"
                  type="text"
                  class="w-full bg-n-slate-2 opacity-70"
                  readonly
                />
              </WithLabel>
            </div>
          </form>
        </SectionLayout>

        <!-- PayOS -->
        <SectionLayout
          v-if="activeTabKey === 'payos'"
          :title="$t('PAYMENT_SETTINGS.PAYOS.TITLE') || 'PayOS Configuration'"
          with-border
        >
          <template #headerActions>
            <div class="flex items-center gap-4">
              <div class="flex items-center gap-2">
                <span class="text-sm font-medium text-n-slate-11">Kênh thanh toán mặc định</span>
                <Switch
                  :model-value="defaultProvider === 'payos'"
                  @update:model-value="val => handleDefaultProviderChange('payos', val)"
                />
              </div>
              <div class="w-px h-4 bg-n-strong" />
              <Switch v-model="payosConfig.active" />
            </div>
          </template>

          <form class="grid gap-4 mt-2" @submit.prevent="handleSave">
            <div
              v-if="payosConfig.active"
              class="grid gap-4 bg-n-alpha-black2 p-4 rounded-lg"
            >
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

              <WithLabel name="payos-webhook-url" label="Webhook URL (Read-only)">
                <NextInput
                  v-model="payosWebhookUrl"
                  type="text"
                  class="w-full bg-n-slate-2 opacity-70"
                  readonly
                />
              </WithLabel>
            </div>
          </form>
        </SectionLayout>
        
        <!-- Tingee -->
        <SectionLayout
          v-if="activeTabKey === 'tingee'"
          title="Tingee Configuration"
          with-border
        >
          <div class="py-12 flex flex-col items-center justify-center bg-n-alpha-black2 rounded-lg border border-dashed border-n-weak">
            <div class="w-12 h-12 rounded-full bg-n-alpha-2 flex items-center justify-center mb-4">
              <fluent-icon icon="rocket" class="w-6 h-6 text-n-slate-11" />
            </div>
            <h4 class="text-n-slate-12 font-medium mb-2">Tính năng đang được phát triển</h4>
            <p class="text-sm text-n-slate-11 text-center max-w-md">
              Cổng thanh toán Tingee sẽ sớm được tích hợp để bạn có thêm lựa chọn thu tiền từ khách hàng.
            </p>
          </div>
        </SectionLayout>

        <div class="flex items-center justify-between mt-4">
          <NextButton
            variant="faded"
            color="slate"
            :disabled="activeTabKey === 'tingee'"
            :is-loading="isTesting"
            @click="handleTestPayment"
          >
            Test thanh toán
          </NextButton>
          <NextButton blue :is-loading="isSaving" @click="handleSave">
            {{ $t('GENERAL_SETTINGS.SUBMIT') }}
          </NextButton>
        </div>
      </div>
    </div>
  </div>
</template>
