<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import integrationsAPI from 'dashboard/api/integrations';
import calendarIntegrationsAPI from 'dashboard/api/calendarIntegrations';

import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

const { t } = useI18n();
const integrationLoaded = ref(false);
const isSubmitting = ref(false);
const connectedIntegration = ref(null);

const integration = computed(() => {
  return {
    id: 'google_calendar',
    logo: 'google_calendar.png',
    name: 'Google Calendar',
    description: 'Kết nối tài khoản Google Calendar để tự động đặt lịch hẹn và kiểm tra giờ trống.',
    enabled: !!connectedIntegration.value,
  };
});

const integrationAction = computed(() => {
  if (integration.value.enabled) {
    return 'disconnect';
  }
  return 'connect';
});

const handleConnect = async () => {
  try {
    isSubmitting.value = true;
    const response = await integrationsAPI.connectGoogleCalendar();
    if (response.data && response.data.url) {
      window.location.href = response.data.url;
    } else {
      useAlert(t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.ERROR') || 'Cannot connect to Google Calendar');
    }
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.ERROR') || 'Cannot connect to Google Calendar');
  } finally {
    isSubmitting.value = false;
  }
};

const handleDisconnect = async () => {
  if (!connectedIntegration.value) return;
  
  try {
    isSubmitting.value = true;
    await calendarIntegrationsAPI.delete(connectedIntegration.value.id);
    useAlert(t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.DISCONNECT_SUCCESS') || 'Disconnected successfully');
    connectedIntegration.value = null;
  } catch (error) {
    useAlert(t('INTEGRATION_SETTINGS.GOOGLE_CALENDAR.ERROR') || 'An error occurred');
  } finally {
    isSubmitting.value = false;
  }
};

const fetchIntegration = async () => {
  try {
    const response = await calendarIntegrationsAPI.get();
    const integrations = response.data || [];
    connectedIntegration.value = integrations.find(i => i.provider === 'google');
  } catch (error) {
    // Error silently
  } finally {
    integrationLoaded.value = true;
  }
};

onMounted(() => {
  fetchIntegration();
});
</script>

<template>
  <SettingsLayout :is-loading="!integrationLoaded || isSubmitting">
    <template #header>
      <BaseSettingsHeader
        title="Google Calendar"
        description="Kết nối tài khoản Google Calendar"
        feature-name="google_calendar_integration"
        :back-button-label="
          $route.path.includes('/sales/')
            ? $t('SALES.MODULE_TOOLS.HEADER.TITLE')
            : $t('INTEGRATION_SETTINGS.HEADER')
        "
      />
    </template>
    <template #body>
      <div class="flex flex-col gap-6">
        <div class="flex flex-col items-start justify-between lg:flex-row lg:items-center p-6 outline outline-n-container outline-1 bg-n-card rounded-xl gap-6">
          <div class="flex items-start lg:items-center justify-start flex-1 m-0 gap-6 flex-col lg:flex-row">
            <div class="flex h-16 w-16 items-center justify-center flex-shrink-0">
              <img
                :src="`/dashboard/images/integrations/${integration.id}.png`"
                class="max-w-full rounded-md border border-n-weak shadow-sm block dark:hidden bg-n-alpha-3 dark:bg-n-alpha-2"
              />
              <img
                :src="`/dashboard/images/integrations/${integration.id}-dark.png`"
                class="max-w-full rounded-md border border-n-weak shadow-sm hidden dark:block bg-n-alpha-3 dark:bg-n-alpha-2"
              />
            </div>
            <div>
              <h3 class="mb-1 text-heading-1 text-n-slate-12">
                {{ integration.name }}
              </h3>
              <p class="text-n-slate-11 text-body-main">
                {{ integration.description }}
              </p>
              <p v-if="integration.enabled" class="text-n-slate-11 text-sm mt-1">
                Connected account: <strong>{{ connectedIntegration.email }}</strong>
              </p>
            </div>
          </div>
          <div class="flex justify-center items-center mb-0">
            <Button
              v-if="integration.enabled"
              faded
              ruby
              :label="t('INTEGRATION_SETTINGS.WEBHOOK.DELETE.BUTTON_TEXT') || 'Disconnect'"
              @click="handleDisconnect"
            />
            <Button
              v-else
              blue
              faded
              :label="t('INTEGRATION_SETTINGS.CONNECT.BUTTON_TEXT') || 'Connect'"
              @click="handleConnect"
            />
          </div>
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
