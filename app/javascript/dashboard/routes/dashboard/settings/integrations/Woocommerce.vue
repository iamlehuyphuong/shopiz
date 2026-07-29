<script setup>
import { ref, computed, onMounted } from 'vue';
import {
  useFunctionGetter,
  useMapGetter,
  useStore,
} from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Integration from './Integration.vue';
import integrationAPI from 'dashboard/api/integrations';

import Input from 'dashboard/components-next/input/Input.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

const store = useStore();
const { t } = useI18n();
const dialogRef = ref(null);
const integrationLoaded = ref(false);
const storeUrl = ref('');
const consumerKey = ref('');
const consumerSecret = ref('');
const isSubmitting = ref(false);
const formError = ref('');
const integration = useFunctionGetter(
  'integrations/getIntegration',
  'woocommerce'
);
const uiFlags = useMapGetter('integrations/getUIFlags');

const integrationAction = computed(() => {
  if (integration.value.enabled) {
    return 'disconnect';
  }
  return 'connect';
});

const hideConnectModal = () => {
  storeUrl.value = '';
  consumerKey.value = '';
  consumerSecret.value = '';
  formError.value = '';
  isSubmitting.value = false;
};

const openConnectDialog = () => {
  if (dialogRef.value) {
    dialogRef.value.open();
  }
};

const handleConnect = async () => {
  try {
    formError.value = '';
    if (!storeUrl.value || !consumerKey.value || !consumerSecret.value) {
      formError.value = 'All fields are required';
      return;
    }

    isSubmitting.value = true;
    await integrationAPI.connectWoocommerce({
      storeUrl: storeUrl.value,
      consumerKey: consumerKey.value,
      consumerSecret: consumerSecret.value,
    });

    useAlert(t('INTEGRATION_SETTINGS.WOOCOMMERCE.SUCCESS'));
    await store.dispatch('integrations/get', 'woocommerce');
    if (dialogRef.value) {
      dialogRef.value.close();
    }
    hideConnectModal();
  } catch {
    formError.value = t('INTEGRATION_SETTINGS.WOOCOMMERCE.ERROR');
  } finally {
    isSubmitting.value = false;
  }
};

const initializeWoocommerceIntegration = async () => {
  await store.dispatch('integrations/get', 'woocommerce');
  integrationLoaded.value = true;
};

onMounted(() => {
  initializeWoocommerceIntegration();
});
</script>

<template>
  <SettingsLayout
    :is-loading="!integrationLoaded || uiFlags.isCreatingWoocommerce"
  >
    <template #header>
      <BaseSettingsHeader
        :title="$t('INTEGRATION_SETTINGS.WOOCOMMERCE.HEADER')"
        description=""
        feature-name="woocommerce_integration"
        :back-button-label="
          $route.path.includes('/sales/')
            ? $t('SALES.MODULE_TOOLS.HEADER.TITLE')
            : $t('INTEGRATION_SETTINGS.HEADER')
        "
      />
    </template>
    <template #body>
      <div class="flex flex-col gap-6">
        <Integration
          :integration-id="integration.id"
          :integration-logo="integration.logo"
          :integration-name="integration.name"
          :integration-description="integration.description"
          :integration-enabled="integration.enabled"
          :integration-action="integrationAction"
          :delete-confirmation-text="{
            title: t('INTEGRATION_SETTINGS.WOOCOMMERCE.DELETE.TITLE'),
            message: t('INTEGRATION_SETTINGS.WOOCOMMERCE.DELETE.MESSAGE'),
          }"
        >
          <template #action>
            <Button
              blue
              :label="t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT')"
              @click="openConnectDialog"
            />
          </template>
        </Integration>
        <Dialog
          ref="dialogRef"
          :title="t('INTEGRATION_SETTINGS.WOOCOMMERCE.CONNECT.TITLE')"
          :is-loading="isSubmitting"
          @confirm="handleConnect"
          @close="hideConnectModal"
        >
          <div class="flex flex-col gap-4">
            <Input
              v-model="storeUrl"
              :label="
                t('INTEGRATION_SETTINGS.WOOCOMMERCE.CONNECT.STORE_URL.LABEL')
              "
              :placeholder="
                t(
                  'INTEGRATION_SETTINGS.WOOCOMMERCE.CONNECT.STORE_URL.PLACEHOLDER'
                )
              "
              :message="
                t('INTEGRATION_SETTINGS.WOOCOMMERCE.CONNECT.STORE_URL.HELP')
              "
              message-type="info"
            />
            <Input
              v-model="consumerKey"
              :label="
                t('INTEGRATION_SETTINGS.WOOCOMMERCE.CONNECT.CONSUMER_KEY.LABEL')
              "
              :placeholder="
                t(
                  'INTEGRATION_SETTINGS.WOOCOMMERCE.CONNECT.CONSUMER_KEY.PLACEHOLDER'
                )
              "
            />
            <Input
              v-model="consumerSecret"
              type="password"
              :label="
                t(
                  'INTEGRATION_SETTINGS.WOOCOMMERCE.CONNECT.CONSUMER_SECRET.LABEL'
                )
              "
              :placeholder="
                t(
                  'INTEGRATION_SETTINGS.WOOCOMMERCE.CONNECT.CONSUMER_SECRET.PLACEHOLDER'
                )
              "
              :message="formError"
              :message-type="formError ? 'error' : ''"
            />
          </div>
        </Dialog>
      </div>
    </template>
  </SettingsLayout>
</template>
