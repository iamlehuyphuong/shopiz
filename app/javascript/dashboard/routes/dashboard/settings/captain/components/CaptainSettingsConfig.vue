<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { storeToRefs } from 'pinia';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useConfig } from 'dashboard/composables/useConfig';
import { useCaptainConfigStore } from 'dashboard/store/captain/preferences';

import SectionLayout from '../../account/components/SectionLayout.vue';
import ModelSelector from './ModelSelector.vue';
import FeatureToggle from './FeatureToggle.vue';

const { t } = useI18n();
const { captainEnabled } = useCaptain();
const { isEnterprise, enterprisePlanName } = useConfig();
const { isOnChatwootCloud } = useAccount();

const captainConfigStore = useCaptainConfigStore();
const { uiFlags } = storeToRefs(captainConfigStore);

const modelFeatures = computed(() => [
  {
    key: 'editor',
    title: t('CAPTAIN_SETTINGS.MODEL_CONFIG.EDITOR.TITLE'),
    description: t('CAPTAIN_SETTINGS.MODEL_CONFIG.EDITOR.DESCRIPTION'),
  },
  {
    key: 'assistant',
    title: t('CAPTAIN_SETTINGS.MODEL_CONFIG.ASSISTANT.TITLE'),
    description: t('CAPTAIN_SETTINGS.MODEL_CONFIG.ASSISTANT.DESCRIPTION'),
    enterprise: true,
  },
  {
    key: 'copilot',
    title: t('CAPTAIN_SETTINGS.MODEL_CONFIG.COPILOT.TITLE'),
    description: t('CAPTAIN_SETTINGS.MODEL_CONFIG.COPILOT.DESCRIPTION'),
    enterprise: true,
  },
]);

const featureToggles = computed(() => [
  {
    key: 'label_suggestion',
  },

  {
    key: 'audio_transcription',
    enterprise: true,
  },
]);

const shouldShowFeature = feature => {
  if (isOnChatwootCloud.value && captainEnabled) {
    return true;
  }
  if (feature.enterprise) {
    return isEnterprise;
  }
  return true;
};

const isFeatureAccessible = feature => {
  if (isOnChatwootCloud.value && captainEnabled) {
    return true;
  }
  if (feature.enterprise) {
    return isEnterprise && enterprisePlanName === 'enterprise';
  }
  return true;
};

async function handleFeatureToggle({ feature, enabled }) {
  try {
    await captainConfigStore.updatePreferences({
      captain_features: { [feature]: enabled },
    });
    useAlert(t('CAPTAIN_SETTINGS.API.SUCCESS'));
  } catch (error) {
    useAlert(t('CAPTAIN_SETTINGS.API.ERROR'));
    captainConfigStore.fetch();
  }
}

async function handleModelChange({ feature, model }) {
  try {
    await captainConfigStore.updatePreferences({
      captain_models: { [feature]: model },
    });
    useAlert(t('CAPTAIN_SETTINGS.API.SUCCESS'));
  } catch (error) {
    useAlert(t('CAPTAIN_SETTINGS.API.ERROR'));
    captainConfigStore.fetch();
  }
}

onMounted(() => {
  captainConfigStore.fetch();
});
</script>

<template>
  <div
    v-if="captainEnabled"
    class="flex flex-col gap-1 text-slate-900 dark:text-slate-100 mt-8"
  >
    <!-- Model Configuration Section -->
    <SectionLayout
      :title="t('CAPTAIN_SETTINGS.MODEL_CONFIG.TITLE')"
      :description="t('CAPTAIN_SETTINGS.MODEL_CONFIG.DESCRIPTION')"
    >
      <div class="grid gap-4">
        <ModelSelector
          v-for="feature in modelFeatures"
          v-show="shouldShowFeature(feature)"
          :key="feature.key"
          :is-allowed="isFeatureAccessible(feature)"
          :feature-key="feature.key"
          :title="feature.title"
          :description="feature.description"
          @change="handleModelChange"
        />
      </div>
    </SectionLayout>

    <!-- Features Section -->
    <SectionLayout
      :title="t('CAPTAIN_SETTINGS.FEATURES.TITLE')"
      :description="t('CAPTAIN_SETTINGS.FEATURES.DESCRIPTION')"
      with-border
    >
      <div class="grid gap-4">
        <FeatureToggle
          v-for="feature in featureToggles"
          v-show="shouldShowFeature(feature)"
          :key="feature.key"
          :is-allowed="isFeatureAccessible(feature)"
          :feature-key="feature.key"
          @change="handleFeatureToggle"
          @model-change="handleModelChange"
        />
      </div>
    </SectionLayout>
  </div>
</template>
