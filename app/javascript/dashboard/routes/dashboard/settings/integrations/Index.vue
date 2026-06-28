<script setup>
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { computed, onMounted, ref } from 'vue';
import { useBranding } from 'shared/composables/useBranding';
import { picoSearch } from '@scmmishra/pico-search';
import IntegrationItem from './IntegrationItem.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

const store = useStore();
const getters = useStoreGetters();
const { replaceInstallationName } = useBranding();

const searchQuery = ref('');
const uiFlags = getters['integrations/getUIFlags'];

const integrationList = computed(
  () => getters['integrations/getAppIntegrations'].value
);

const CATEGORIES = [
  {
    key: 'AI_AUTOMATION',
    ids: ['openai', 'dialogflow', 'webhook', 'google_translate'],
  },
  {
    key: 'WORKSPACE_SYNC',
    ids: ['linear', 'notion', 'slack', 'omicall'],
  },
  {
    key: 'CUSTOM_EXTENSIONS',
    ids: ['dashboard_apps', 'dyte'],
  },
];

const HIDDEN_IDS = [
  'dialogflow',
  'shopify',
  'woocommerce',
  'kiotviet',
  'haravan',
  'sapo',
  'nhanhvn',
  'calendly',
  'leadsquared',
];

const filteredIntegrationList = computed(() => {
  const visible = integrationList.value.filter(
    item => !HIDDEN_IDS.includes(item.id) && !['draft', 'deprecated'].includes(item.status)
  );
  const query = searchQuery.value.trim();
  if (!query) return visible;
  return picoSearch(visible, query, ['name', 'description']);
});

const categorizedIntegrations = computed(() => {
  const usedIds = new Set();
  const categories = CATEGORIES.map(category => {
    const items = filteredIntegrationList.value.filter(item =>
      category.ids.includes(item.id)
    );
    items.forEach(item => usedIds.add(item.id));
    return {
      ...category,
      items,
    };
  });

  const otherItems = filteredIntegrationList.value.filter(
    item => !usedIds.has(item.id)
  );

  if (otherItems.length) {
    categories.push({
      key: 'MORE_INTEGRATIONS',
      items: otherItems,
    });
  }

  return categories.filter(category => category.items.length > 0);
});

onMounted(() => {
  store.dispatch('integrations/get');
});
</script>

<template>
  <SettingsLayout
    :is-loading="uiFlags.isFetching"
    :loading-message="$t('INTEGRATION_SETTINGS.LOADING')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('INTEGRATION_SETTINGS.HEADER')"
        :description="
          replaceInstallationName($t('INTEGRATION_SETTINGS.DESCRIPTION'))
        "
        :link-text="$t('INTEGRATION_SETTINGS.LEARN_MORE')"
        :search-placeholder="$t('INTEGRATION_SETTINGS.SEARCH_PLACEHOLDER')"
        feature-name="integrations"
      />
    </template>
    <template #body>
      <div class="w-full flex-grow flex-shrink overflow-auto mt-6">
        <div class="max-w-7xl flex flex-col gap-10">
          <div
            v-if="!categorizedIntegrations.length"
            class="flex-1 flex items-center justify-center py-20 text-center text-body-main !text-base text-n-slate-11"
          >
            {{ $t('INTEGRATION_SETTINGS.NO_RESULTS') }}
          </div>
          <template v-else>
            <div
              v-for="category in categorizedIntegrations"
              :key="category.key"
              class="flex flex-col gap-4 animate-in fade-in slide-in-from-bottom-4 duration-700"
            >
              <h2
                class="text-xs font-bold uppercase tracking-widest text-n-slate-11"
              >
                {{ $t(`INTEGRATION_SETTINGS.SECTION.${category.key}`) }}
              </h2>
              <div
                class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 xl:grid-cols-3 gap-6"
              >
                <IntegrationItem
                  v-for="item in category.items"
                  :id="item.id"
                  :key="item.id"
                  :logo="item.logo"
                  :name="item.name"
                  :description="item.description"
                  :enabled="item.enabled"
                  :is-active="item.is_active"
                  :status="item.status"
                />
              </div>
            </div>
          </template>
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
