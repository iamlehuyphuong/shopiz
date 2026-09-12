<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import Input from 'dashboard/components-next/input/Input.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import SettingsLayout from 'dashboard/routes/dashboard/settings/SettingsLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';

const store = useStore();
const { currentAccount } = useAccount();
const { t } = useI18n();

const dialogRef = ref(null);
const isLoading = ref(true);
const isSubmitting = ref(false);
const showDeletePopup = ref(false);

const companyName = ref('');
const companyCode = ref('');
const secretKey = ref('');

const webhookUrl = computed(() => {
  return `${window.shopizConfig.hostURL}/api/v1/webhooks/sales_payments/sepay/${currentAccount.value.id}`;
});

const copyWebhook = () => {
  navigator.clipboard.writeText(webhookUrl.value);
  useAlert(t('SALES.SETTINGS.PAYMENT.WEBHOOK_COPIED') || 'Đã sao chép Webhook URL');
};

// Dummy integration object to match the props expected by Integration.vue
const integration = computed(() => {
  const active = !!(companyCode.value && secretKey.value && companyName.value);
  return {
    id: 'sepay',
    logo: '/dashboard/images/integrations/sepay.png', // Assuming we have this logo or similar
    name: 'SePay',
    description: t('SALES.SETTINGS.PAYMENT.SEPAY_DESC'),
    enabled: active,
  };
});

const handleDisconnect = async () => {
  try {
    const existingConfig =
      currentAccount.value?.settings?.sales_payment_config || {};
    const payload = {
      sales_payment_config: {
        ...existingConfig,
        sepay: {
          ...existingConfig.sepay,
          active: false,
        },
      },
    };
    await store.dispatch('accounts/update', payload);
    useAlert(t('SALES.SETTINGS.PAYMENT.DISCONNECT_SUCCESS'));
    showDeletePopup.value = false;
    companyCode.value = '';
    secretKey.value = '';
    companyName.value = '';
  } catch (error) {
    useAlert(error.message || t('SALES.SETTINGS.PAYMENT.DISCONNECT_ERROR'));
  }
};

const hideConnectModal = () => {
  // Only clear inputs on close, Dialog handles native closing
  isSubmitting.value = false;
};

const openConnectDialog = () => {
  if (dialogRef.value) {
    dialogRef.value.open();
  }
};

const handleConnect = async () => {
  isSubmitting.value = true;
  try {
    const existingConfig =
      currentAccount.value?.settings?.sales_payment_config || {};

    const payload = {
      sales_payment_config: {
        ...existingConfig,
        sepay: {
          active: !!(companyCode.value && secretKey.value && companyName.value),
          company_name: companyName.value,
          company_code: companyCode.value,
          secret_key: secretKey.value,
        },
      },
    };

    await store.dispatch('accounts/update', payload);
    useAlert(t('GENERAL_SETTINGS.UPDATE.SUCCESS') || 'Updated successfully');
    dialogRef.value?.close();
    hideConnectModal();
  } catch (error) {
    useAlert(
      error.message ||
        t('GENERAL_SETTINGS.UPDATE.ERROR') ||
        'Error updating settings'
    );
  } finally {
    isSubmitting.value = false;
  }
};

const loadConfig = () => {
  const paymentConfig =
    currentAccount.value?.settings?.sales_payment_config || {};
  const sepayConfig = paymentConfig.sepay || {};

  companyName.value = sepayConfig.company_name || '';
  companyCode.value = sepayConfig.company_code || '';
  secretKey.value = secretKey.value || sepayConfig.secret_key || ''; // Keep secret key if already entered? No, load it
};

onMounted(() => {
  loadConfig();
  isLoading.value = false;
});
</script>

<!-- eslint-disable vue/no-bare-strings-in-template -->
<template>
  <SettingsLayout :is-loading="isLoading">
    <template #header>
      <BaseSettingsHeader
        :title="t('SALES.SETTINGS.PAYMENT.TITLE_SEPAY')"
        description=""
        feature-name="sales_payment_sepay"
        :back-button-label="t('SALES.SETTINGS.PAYMENT.BACK_BUTTON')"
        back-button-link="/app/accounts/1/sales/settings"
      />
    </template>
    <template #body>
      <div class="flex flex-col gap-6">
        <div
          class="outline outline-n-container outline-1 bg-n-card rounded-xl flex-grow overflow-auto p-4"
        >
          <div class="flex items-center justify-center">
            <div class="flex h-16 w-16 items-center justify-center">
              <img
                :src="integration.logo"
                class="max-w-full rounded-md border border-n-weak shadow-sm block dark:hidden bg-n-alpha-3 dark:bg-n-alpha-2"
              />
              <img
                :src="integration.logo"
                class="max-w-full rounded-md border border-n-weak shadow-sm hidden dark:block bg-n-alpha-3 dark:bg-n-alpha-2"
              />
            </div>
            <div class="flex flex-col justify-center m-0 mx-4 flex-1">
              <h3 class="mb-1 text-heading-1 text-n-slate-12">
                {{ integration.name }}
              </h3>
              <p class="text-n-slate-11 text-body-main">
                {{ integration.description }}
              </p>
            </div>
            <div class="flex justify-center gap-2 items-center mb-0">
              <div v-if="integration.enabled" class="flex gap-2">
                <Button
                  blue
                  faded
                  :label="t('SALES.SETTINGS.PAYMENT.CONFIGURE')"
                  @click="openConnectDialog"
                />
                <Button
                  ruby
                  faded
                  :label="t('SALES.SETTINGS.PAYMENT.DISCONNECT')"
                  @click="showDeletePopup = true"
                />
              </div>
              <div v-else>
                <Button
                  blue
                  faded
                  :label="t('SALES.SETTINGS.PAYMENT.CONNECT')"
                  @click="openConnectDialog"
                />
              </div>
            </div>
          </div>
        </div>

        <woot-delete-modal
          v-model:show="showDeletePopup"
          :on-close="() => (showDeletePopup = false)"
          :on-confirm="handleDisconnect"
          :title="t('SALES.SETTINGS.PAYMENT.DISCONNECT_SEPAY_TITLE')"
          :message="t('SALES.SETTINGS.PAYMENT.DISCONNECT_SEPAY_MSG')"
          :confirm-text="t('SALES.SETTINGS.PAYMENT.CONFIRM')"
          :reject-text="t('SALES.SETTINGS.PAYMENT.CANCEL')"
        />

        <Dialog
          ref="dialogRef"
          :title="t('SALES.SETTINGS.PAYMENT.TITLE_SEPAY')"
          :is-loading="isSubmitting"
          :confirm-button-label="t('SALES.SETTINGS.PAYMENT.CONFIRM')"
          :cancel-button-label="t('SALES.SETTINGS.PAYMENT.CANCEL')"
          @confirm="handleConnect"
          @close="hideConnectModal"
        >
          <div class="flex flex-col gap-4">
            <div class="flex flex-col min-w-0 gap-1">
              <label class="mb-0.5 text-heading-3 text-n-slate-12">{{ t('SALES.SETTINGS.PAYMENT.WEBHOOK_URL') }}</label>
              <div class="flex items-center gap-2 px-3 py-2 rounded-lg bg-n-alpha-black2 border border-n-weak">
                <span class="flex-1 text-sm text-n-slate-11 truncate select-all">{{ webhookUrl }}</span>
                <button type="button" @click="copyWebhook" class="p-1 rounded flex items-center justify-center hover:bg-n-alpha-2 transition-colors">
                  <i class="i-lucide-copy text-sm text-n-slate-11"></i>
                </button>
              </div>
            </div>
            <Input
              v-model="companyName"
              :label="t('SALES.SETTINGS.PAYMENT.FORM.COMPANY_NAME')"
              :placeholder="
                t('SALES.SETTINGS.PAYMENT.FORM.PLACEHOLDER_CLIENT_ID')
              "
            />
            <Input
              v-model="companyCode"
              :label="t('SALES.SETTINGS.PAYMENT.FORM.COMPANY_CODE')"
              :placeholder="
                t('SALES.SETTINGS.PAYMENT.FORM.PLACEHOLDER_API_KEY')
              "
            />
            <Input
              v-model="secretKey"
              type="password"
              :label="t('SALES.SETTINGS.PAYMENT.FORM.SECRET_KEY')"
              :placeholder="
                t('SALES.SETTINGS.PAYMENT.FORM.PLACEHOLDER_SECRET_KEY')
              "
            />
          </div>
        </Dialog>
      </div>
    </template>
  </SettingsLayout>
</template>
