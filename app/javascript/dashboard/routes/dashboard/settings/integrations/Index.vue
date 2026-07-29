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

const HIDDEN_IDS = [
  'dialogflow',
  'shopify',
  'woocommerce',
  'kiotviet',
  'haravan',
  'sapo',
  'nhanhvn',
  'calendly',
  'google_calendar',
  'leadsquared',
];

const filteredIntegrationList = computed(() => {
  const visible = integrationList.value.filter(
    item =>
      !HIDDEN_IDS.includes(item.id) &&
      !['draft', 'deprecated'].includes(item.status)
  );

  const STATUS_ORDER = { published: 1, beta: 2, coming_soon: 3 };

  const sortedVisible = visible.sort((a, b) => {
    // Ưu tiên OMICall lên đầu
    if (a.id === 'omicall' && b.id !== 'omicall') return -1;
    if (b.id === 'omicall' && a.id !== 'omicall') return 1;

    // Sắp xếp theo status: Published > Beta > Coming Soon
    const statusA = STATUS_ORDER[a.status] || 99;
    const statusB = STATUS_ORDER[b.status] || 99;
    return statusA - statusB;
  });

  const query = searchQuery.value.trim();
  if (!query) return sortedVisible;
  return picoSearch(sortedVisible, query, ['name', 'description']);
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
            v-if="!filteredIntegrationList.length"
            class="flex-1 flex items-center justify-center py-20 text-center text-body-main !text-base text-n-slate-11"
          >
            {{ $t('INTEGRATION_SETTINGS.NO_RESULTS') }}
          </div>
          <div
            v-else
            class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 xl:grid-cols-3 gap-6 animate-in fade-in slide-in-from-bottom-4 duration-700"
          >
            <IntegrationItem
              v-for="item in filteredIntegrationList"
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
      </div>
    </template>
  </SettingsLayout>
</template>
