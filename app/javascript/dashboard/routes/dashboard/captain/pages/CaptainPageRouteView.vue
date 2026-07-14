<script setup>
import { watch, watchEffect, ref } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useLimitation } from 'dashboard/composables/useLimitation';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import ConfirmationModal from 'dashboard/components/widgets/modal/ConfirmationModal.vue';

const route = useRoute();
const router = useRouter();
const store = useStore();
const { uiSettings, updateUISettings } = useUISettings();
const { usageData, getUsage } = useLimitation();

const appIntegrations = useMapGetter('integrations/getAppIntegrations');
const confirmationModal = ref(null);
const hasCheckedOpenAI = ref(false);

watch(
  () => route.params.assistantId,
  newAssistantId => {
    if (
      newAssistantId &&
      newAssistantId !== String(uiSettings.value.last_active_assistant_id)
    ) {
      updateUISettings({
        last_active_assistant_id: Number(newAssistantId),
      });
    }
  }
);

watchEffect(async () => {
  if (Object.keys(usageData.value).length === 0) return;
  if (hasCheckedOpenAI.value) return;

  const usage = getUsage('captain_assistants');
  if (usage.isReached) {
    hasCheckedOpenAI.value = true;
    if (!appIntegrations.value.length) {
      await store.dispatch('integrations/get');
    }
    const aiIntegration = appIntegrations.value.find(
      integration => integration.id === 'openai' && !!integration.hooks.length
    );
    if (!aiIntegration) {
      const confirmed = await confirmationModal.value?.showConfirmation();
      if (confirmed) {
        router.push({
          name: 'settings_applications_integration',
          params: { integration_id: 'openai' },
        });
      }
    }
  }
});
</script>

<template>
  <div class="flex w-full h-full min-h-0">
    <section class="flex flex-1 h-full px-0 overflow-hidden bg-n-surface-1">
      <router-view />
    </section>
    <ConfirmationModal
      ref="confirmationModal"
      :title="$t('CAPTAIN.ASSISTANTS.LIMIT_REACHED.TITLE')"
      :description="$t('CAPTAIN.ASSISTANTS.LIMIT_REACHED.DESCRIPTION')"
      :confirm-label="$t('CAPTAIN.ASSISTANTS.LIMIT_REACHED.CONFIRM')"
      :cancel-label="$t('CAPTAIN.ASSISTANTS.LIMIT_REACHED.CANCEL')"
    />
  </div>
</template>
