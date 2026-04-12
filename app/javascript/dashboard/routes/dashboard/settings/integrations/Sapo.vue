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
const accessToken = ref('');
const storeName = ref('');
const isSubmitting = ref(false);
const formError = ref('');
const integration = useFunctionGetter('integrations/getIntegration', 'sapo');
const uiFlags = useMapGetter('integrations/getUIFlags');

const integrationAction = computed(() => {
  if (integration.value.enabled) {
    return 'disconnect';
  }
  return 'connect';
});

const hideConnectModal = () => {
  accessToken.value = '';
  storeName.value = '';
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
    if (!accessToken.value || !storeName.value) {
      formError.value = 'All fields are required';
      return;
    }

    isSubmitting.value = true;
    await integrationAPI.connectSapo({
      accessToken: accessToken.value,
      storeName: storeName.value,
    });

    useAlert(t('INTEGRATION_SETTINGS.SAPO.SUCCESS'));
    await store.dispatch('integrations/get', 'sapo');
    if (dialogRef.value) {
      dialogRef.value.close();
    }
    hideConnectModal();
  } catch {
    formError.value = t('INTEGRATION_SETTINGS.SAPO.ERROR');
  } finally {
    isSubmitting.value = false;
  }
};

const initializeSapoIntegration = async () => {
  await store.dispatch('integrations/get', 'sapo');
  integrationLoaded.value = true;
};

onMounted(() => {
  initializeSapoIntegration();
});
</script>

<template>
  <SettingsLayout :is-loading="!integrationLoaded || uiFlags.isCreatingSapo">
    <template #header>
      <BaseSettingsHeader
        :title="$t('INTEGRATION_SETTINGS.SAPO.HEADER')"
        description=""
        feature-name="sapo_integration"
        :back-button-label="$t('INTEGRATION_SETTINGS.HEADER')"
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
            title: t('INTEGRATION_SETTINGS.SAPO.DELETE.TITLE'),
            message: t('INTEGRATION_SETTINGS.SAPO.DELETE.MESSAGE'),
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
          :title="t('INTEGRATION_SETTINGS.SAPO.CONNECT.TITLE')"
          :is-loading="isSubmitting"
          @confirm="handleConnect"
          @close="hideConnectModal"
        >
          <div class="flex flex-col gap-4">
            <Input
              v-model="accessToken"
              type="password"
              :label="t('INTEGRATION_SETTINGS.SAPO.CONNECT.ACCESS_TOKEN.LABEL')"
              :placeholder="
                t('INTEGRATION_SETTINGS.SAPO.CONNECT.ACCESS_TOKEN.PLACEHOLDER')
              "
            />
            <Input
              v-model="storeName"
              :label="t('INTEGRATION_SETTINGS.SAPO.CONNECT.STORE_NAME.LABEL')"
              :placeholder="
                t('INTEGRATION_SETTINGS.SAPO.CONNECT.STORE_NAME.PLACEHOLDER')
              "
              :message="
                !formError
                  ? t('INTEGRATION_SETTINGS.SAPO.CONNECT.STORE_NAME.HELP')
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
