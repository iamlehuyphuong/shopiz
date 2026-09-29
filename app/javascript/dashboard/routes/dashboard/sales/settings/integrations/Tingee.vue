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

const clientId = ref('');
const apiKey = ref('');
const bankBin = ref('');
const accountNumber = ref('');
const isActive = ref(false);

// Dummy integration object to match the props expected by Integration.vue
const webhookUrl = computed(() => {
  return `${window.shopizConfig.hostURL}/api/v1/webhooks/sales_payments/tingee/${currentAccount.value.id}`;
});

const copyWebhook = () => {
  navigator.clipboard.writeText(webhookUrl.value);
  useAlert(
    t('SALES.SETTINGS.PAYMENT.WEBHOOK_COPIED') || 'Đã sao chép Webhook URL'
  );
};

const integration = computed(() => {
  return {
    id: 'tingee',
    logo: '/dashboard/images/integrations/tingee.png', // Assuming we have this logo or similar
    name: 'Tingee',
    description: t('SALES.SETTINGS.PAYMENT.TINGEE_DESC'),
    enabled: isActive.value,
  };
});

const handleDisconnect = async () => {
  try {
    const existingConfig =
      currentAccount.value?.settings?.sales_payment_config || {};
    const payload = {
      sales_payment_config: {
        ...existingConfig,
        tingee: {
          ...existingConfig.tingee,
          active: false,
        },
      },
    };
    await store.dispatch('accounts/update', payload);
    useAlert(t('SALES.SETTINGS.PAYMENT.DISCONNECT_SUCCESS'));
    showDeletePopup.value = false;
    clientId.value = '';
    isActive.value = false;
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

    const isFormValid = !!(
      apiKey.value &&
      clientId.value &&
      bankBin.value &&
      accountNumber.value
    );

    const payload = {
      sales_payment_config: {
        ...existingConfig,
        tingee: {
          active: isFormValid,
          client_id: clientId.value,
          api_key: apiKey.value,
          bank_bin: bankBin.value,
          account_number: accountNumber.value,
        },
      },
    };

    await store.dispatch('accounts/update', payload);
    isActive.value = isFormValid;
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
  const tingeeConfig = paymentConfig.tingee || {};

  clientId.value = tingeeConfig.client_id || '';
  apiKey.value = tingeeConfig.api_key || '';
  bankBin.value = tingeeConfig.bank_bin || '';
  accountNumber.value = tingeeConfig.account_number || '';
  isActive.value = !!tingeeConfig.active;
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
        :title="t('SALES.SETTINGS.PAYMENT.TITLE_TINGEE')"
        description=""
        feature-name="sales_payment_tingee"
        :back-button-label="t('SALES.SETTINGS.PAYMENT.BACK_BUTTON')"
        :back-button-link="`/app/accounts/${currentAccount.id}/sales/settings`"
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
          :title="t('SALES.SETTINGS.PAYMENT.DISCONNECT_TINGEE_TITLE')"
          :message="t('SALES.SETTINGS.PAYMENT.DISCONNECT_TINGEE_MSG')"
          :confirm-text="t('SALES.SETTINGS.PAYMENT.CONFIRM')"
          :reject-text="t('SALES.SETTINGS.PAYMENT.CANCEL')"
        />

        <Dialog
          ref="dialogRef"
          :title="t('SALES.SETTINGS.PAYMENT.TITLE_TINGEE')"
          :is-loading="isSubmitting"
          :confirm-button-label="t('SALES.SETTINGS.PAYMENT.CONFIRM')"
          :cancel-button-label="t('SALES.SETTINGS.PAYMENT.CANCEL')"
          @confirm="handleConnect"
          @close="hideConnectModal"
        >
          <div class="flex flex-col gap-4">
            <div class="flex flex-col min-w-0 gap-1">
              <label class="mb-0.5 text-heading-3 text-n-slate-12">{{
                t('SALES.SETTINGS.PAYMENT.WEBHOOK_URL')
              }}</label>
              <div
                class="flex items-center gap-2 px-3 py-2 rounded-lg bg-n-alpha-black2 border border-n-weak"
              >
                <span
                  class="flex-1 text-sm text-n-slate-11 truncate select-all"
                  >{{ webhookUrl }}</span>
                <button
                  type="button"
                  class="p-1 rounded flex items-center justify-center hover:bg-n-alpha-2 transition-colors"
                  @click="copyWebhook"
                >
                  <i class="i-lucide-copy text-sm text-n-slate-11" />
                </button>
              </div>
              <p class="text-xs text-n-slate-10 mt-1">
                {{ t('SALES.SETTINGS.PAYMENT.TINGEE_WEBHOOK_HELPER') }}
              </p>
            </div>
            <Input
              v-model="clientId"
              :label="t('SALES.SETTINGS.PAYMENT.FORM.CLIENT_ID')"
              :placeholder="
                t('SALES.SETTINGS.PAYMENT.FORM.PLACEHOLDER_CLIENT_ID')
              "
            />
            <Input
              v-model="apiKey"
              :label="t('SALES.SETTINGS.PAYMENT.FORM.TINGEE_SECRET_TOKEN')"
              :placeholder="
                t('SALES.SETTINGS.PAYMENT.FORM.PLACEHOLDER_TINGEE_SECRET_TOKEN')
              "
            />
            <Input
              v-model="bankBin"
              :label="t('SALES.SETTINGS.PAYMENT.FORM.BANK_BIN')"
              :placeholder="
                t('SALES.SETTINGS.PAYMENT.FORM.PLACEHOLDER_BANK_BIN')
              "
            />
            <Input
              v-model="accountNumber"
              :label="t('SALES.SETTINGS.PAYMENT.FORM.ACCOUNT_NUMBER')"
              :placeholder="
                t('SALES.SETTINGS.PAYMENT.FORM.PLACEHOLDER_ACCOUNT_NUMBER')
              "
            />
          </div>
        </Dialog>
      </div>
    </template>
  </SettingsLayout>
</template>
