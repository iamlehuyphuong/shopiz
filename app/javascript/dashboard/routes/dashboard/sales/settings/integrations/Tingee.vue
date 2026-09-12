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
const checksumKey = ref('');

// Dummy integration object to match the props expected by Integration.vue
const integration = computed(() => {
  const active = !!(apiKey.value && checksumKey.value && clientId.value);
  return {
    id: 'tingee',
    logo: '/dashboard/images/integrations/tingee.png', // Assuming we have this logo or similar
    name: 'Tingee',
    description:
      'Kết nối Tingee để nhận thông báo thanh toán tự động qua chuyển khoản ngân hàng.',
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
        tingee: {
          active: !!(apiKey.value && checksumKey.value && clientId.value),
          client_id: clientId.value,
          api_key: apiKey.value,
          checksum_key: checksumKey.value,
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
  const tingeeConfig = paymentConfig.tingee || {};

  clientId.value = tingeeConfig.client_id || '';
  apiKey.value = tingeeConfig.api_key || '';
  checksumKey.value = checksumKey.value || tingeeConfig.checksum_key || ''; // Keep secret key if already entered? No, load it
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
                  disabled
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
            <Input
              v-model="clientId"
              :label="t('SALES.SETTINGS.PAYMENT.FORM.CLIENT_ID')"
              :placeholder="
                t('SALES.SETTINGS.PAYMENT.FORM.PLACEHOLDER_CLIENT_ID')
              "
            />
            <Input
              v-model="apiKey"
              :label="t('SALES.SETTINGS.PAYMENT.FORM.API_KEY')"
              :placeholder="
                t('SALES.SETTINGS.PAYMENT.FORM.PLACEHOLDER_API_KEY')
              "
            />
            <Input
              v-model="checksumKey"
              type="password"
              :label="t('SALES.SETTINGS.PAYMENT.FORM.CHECKSUM_KEY')"
              :placeholder="
                t('SALES.SETTINGS.PAYMENT.FORM.PLACEHOLDER_CHECKSUM_KEY')
              "
            />
          </div>
        </Dialog>
      </div>
    </template>
  </SettingsLayout>
</template>
