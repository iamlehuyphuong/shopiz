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
const appId = ref('');
const accessToken = ref('');
const businessId = ref('');
const isSubmitting = ref(false);
const formError = ref('');
const integration = useFunctionGetter('integrations/getIntegration', 'nhanhvn');
const uiFlags = useMapGetter('integrations/getUIFlags');

const integrationAction = computed(() => {
  if (integration.value.enabled) {
    return 'disconnect';
  }
  return 'connect';
});

const hideConnectModal = () => {
  appId.value = '';
  accessToken.value = '';
  businessId.value = '';
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
    if (!appId.value || !accessToken.value || !businessId.value) {
      formError.value = 'All fields are required';
      return;
    }

    isSubmitting.value = true;
    await integrationAPI.connectNhanhvn({
      appId: appId.value,
      accessToken: accessToken.value,
      businessId: businessId.value,
    });

    useAlert(t('INTEGRATION_SETTINGS.NHANHVN.SUCCESS'));
    await store.dispatch('integrations/get', 'nhanhvn');
    if (dialogRef.value) {
      dialogRef.value.close();
    }
    hideConnectModal();
  } catch {
    formError.value = t('INTEGRATION_SETTINGS.NHANHVN.ERROR');
  } finally {
    isSubmitting.value = false;
  }
};

const initializeNhanhvnIntegration = async () => {
  await store.dispatch('integrations/get', 'nhanhvn');
  integrationLoaded.value = true;
};

onMounted(() => {
  initializeNhanhvnIntegration();
});
</script>

<template>
  <SettingsLayout :is-loading="!integrationLoaded || uiFlags.isCreatingNhanhvn">
    <template #header>
      <BaseSettingsHeader
        :title="$t('INTEGRATION_SETTINGS.NHANHVN.HEADER')"
        description=""
        feature-name="nhanhvn_integration"
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
            title: t('INTEGRATION_SETTINGS.NHANHVN.DELETE.TITLE'),
            message: t('INTEGRATION_SETTINGS.NHANHVN.DELETE.MESSAGE'),
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
        <div
          v-if="formError && !dialogRef"
          class="flex items-center justify-center flex-1 outline outline-n-container outline-1 bg-n-alpha-3 rounded-md shadow p-6"
        >
          <p class="text-n-ruby-9">
            {{ formError }}
          </p>
        </div>
        <Dialog
          ref="dialogRef"
          :title="t('INTEGRATION_SETTINGS.NHANHVN.CONNECT.TITLE')"
          :is-loading="isSubmitting"
          @confirm="handleConnect"
          @close="hideConnectModal"
        >
          <div class="flex flex-col gap-4">
            <Input
              v-model="appId"
              :label="t('INTEGRATION_SETTINGS.NHANHVN.CONNECT.APP_ID.LABEL')"
              :placeholder="
                t('INTEGRATION_SETTINGS.NHANHVN.CONNECT.APP_ID.PLACEHOLDER')
              "
            />
            <Input
              v-model="accessToken"
              type="password"
              :label="
                t('INTEGRATION_SETTINGS.NHANHVN.CONNECT.ACCESS_TOKEN.LABEL')
              "
              :placeholder="
                t(
                  'INTEGRATION_SETTINGS.NHANHVN.CONNECT.ACCESS_TOKEN.PLACEHOLDER'
                )
              "
            />
            <Input
              v-model="businessId"
              :label="
                t('INTEGRATION_SETTINGS.NHANHVN.CONNECT.BUSINESS_ID.LABEL')
              "
              :placeholder="
                t(
                  'INTEGRATION_SETTINGS.NHANHVN.CONNECT.BUSINESS_ID.PLACEHOLDER'
                )
              "
              :message="
                !formError
                  ? t('INTEGRATION_SETTINGS.NHANHVN.CONNECT.BUSINESS_ID.HELP')
                  : formError
              "
              :message-type="formError ? 'error' : 'info'"
            />
          </div>
        </Dialog>
      </div>
    </template>
  </SettingsLayout>
</template>
