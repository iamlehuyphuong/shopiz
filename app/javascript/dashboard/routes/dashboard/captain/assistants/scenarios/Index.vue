<script setup>
import { computed, h, ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { picoSearch } from '@scmmishra/pico-search';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import Button from 'dashboard/components-next/button/Button.vue';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import SuggestedScenarios from 'dashboard/components-next/captain/assistant/SuggestedRules.vue';
import ScenariosCard from 'dashboard/components-next/captain/assistant/ScenariosCard.vue';
import BulkSelectBar from 'dashboard/components-next/captain/assistant/BulkSelectBar.vue';
import AddNewScenariosDialog from 'dashboard/components-next/captain/assistant/AddNewScenariosDialog.vue';

const { t, tm } = useI18n();
const route = useRoute();
const store = useStore();
const { formatMessage } = useMessageFormatter();
const assistantId = computed(() => Number(route.params.assistantId));

const activeTabIndex = ref(0);

const uiFlags = useMapGetter('captainScenarios/getUIFlags');
const isFetching = computed(() => uiFlags.value.fetchingList);
const scenarios = useMapGetter('captainScenarios/getRecords');

const tabs = computed(() => [
  {
    key: 'scenarios',
    label: t('CAPTAIN.ASSISTANTS.SCENARIOS.TITLE'),
    count: scenarios.value.length,
  },
  {
    key: 'templates',
    label: t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.SUGGESTED.TITLE'),
  },
]);

const onTabChange = tab => {
  activeTabIndex.value = tabs.value.findIndex(item => item.key === tab.key);
};

const searchQuery = ref('');

const LINK_INSTRUCTION_CLASS =
  '[&_a[href^="tool://"]]:text-n-iris-11 [&_a:not([href^="tool://"])]:text-n-slate-12 [&_a]:pointer-events-none [&_a]:cursor-default';

const renderInstruction = instruction => () =>
  h('span', {
    class: `text-sm text-n-slate-12 py-4 prose prose-sm min-w-0 break-words ${LINK_INSTRUCTION_CLASS}`,
    innerHTML: instruction,
  });

// Suggested example scenarios for quick add
const caseStudies = computed(() => {
  const cases = tm('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.SUGGESTED.CASE_STUDIES');
  return Array.isArray(cases) ? cases : [];
});

const filteredScenarios = computed(() => {
  const query = searchQuery.value.trim();
  const source = scenarios.value;
  if (!query) return source;
  return picoSearch(source, query, ['title', 'description', 'instruction']);
});

const closeSuggestedRules = () => {
  activeTabIndex.value = 0;
};

// Bulk selection & hover state
const bulkSelectedIds = ref(new Set());
const hoveredCard = ref(null);

const handleRuleSelect = id => {
  const selected = new Set(bulkSelectedIds.value);
  selected[selected.has(id) ? 'delete' : 'add'](id);
  bulkSelectedIds.value = selected;
};

const buildSelectedCountLabel = computed(() => {
  const count = scenarios.value.length || 0;
  const isAllSelected = bulkSelectedIds.value.size === count && count > 0;
  return isAllSelected
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.BULK_ACTION.UNSELECT_ALL', { count })
    : t('CAPTAIN.ASSISTANTS.SCENARIOS.BULK_ACTION.SELECT_ALL', { count });
});

const selectedCountLabel = computed(() => {
  return t('CAPTAIN.ASSISTANTS.SCENARIOS.BULK_ACTION.SELECTED', {
    count: bulkSelectedIds.value.size,
  });
});

const handleRuleHover = (isHovered, id) => {
  hoveredCard.value = isHovered ? id : null;
};

const getToolsFromInstruction = instruction => [
  ...new Set(
    [...(instruction?.matchAll(/\(tool:\/\/([^)]+)\)/g) ?? [])].map(m => m[1])
  ),
];

const updateScenario = async scenario => {
  try {
    await store.dispatch('captainScenarios/update', {
      id: scenario.id,
      assistantId: assistantId.value,
      ...scenario,
      tools: getToolsFromInstruction(scenario.instruction),
    });
    useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.UPDATE.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAPTAIN.ASSISTANTS.SCENARIOS.API.UPDATE.ERROR');
    useAlert(errorMessage);
  }
};

const deleteScenario = async id => {
  try {
    await store.dispatch('captainScenarios/delete', {
      id,
      assistantId: assistantId.value,
    });
    useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.DELETE.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAPTAIN.ASSISTANTS.SCENARIOS.API.DELETE.ERROR');
    useAlert(errorMessage);
  }
};

// TODO: Add bulk delete endpoint
const bulkDeleteScenarios = async ids => {
  const idsArray = ids || Array.from(bulkSelectedIds.value);
  await Promise.all(
    idsArray.map(id =>
      store.dispatch('captainScenarios/delete', {
        id,
        assistantId: assistantId.value,
      })
    )
  );
  bulkSelectedIds.value = new Set();
  useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.DELETE.SUCCESS'));
};

const addScenario = async scenario => {
  try {
    await store.dispatch('captainScenarios/create', {
      assistantId: assistantId.value,
      ...scenario,
      tools: getToolsFromInstruction(scenario.instruction),
    });
    useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.ADD.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAPTAIN.ASSISTANTS.SCENARIOS.API.ADD.ERROR');
    useAlert(errorMessage);
  }
};

const addAllExampleScenarios = async scenarios => {
  try {
    scenarios.forEach(async scenario => {
      await store.dispatch('captainScenarios/create', {
        assistantId: assistantId.value,
        ...scenario,
      });
    });
    useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.ADD.SUCCESS'));
  } catch (error) {
    const errorMessage =
      error?.response?.message ||
      t('CAPTAIN.ASSISTANTS.SCENARIOS.API.ADD.ERROR');
    useAlert(errorMessage);
  }
};

const importInput = ref(null);

const triggerImport = () => {
  importInput.value.click();
};

const onFileChange = async event => {
  const file = event.target.files[0];
  if (!file) return;

  const reader = new FileReader();
  reader.onload = async e => {
    try {
      const data = JSON.parse(e.target.result);
      if (!Array.isArray(data)) {
        throw new Error('Invalid format');
      }

      const validItems = data.filter(
        item => item.title && item.description && item.instruction
      );

      if (validItems.length > 0) {
        await Promise.all(validItems.map(item => addScenario(item)));
        useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.IMPORT.SUCCESS'));
      } else {
        useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.IMPORT.ERROR'));
      }
    } catch (error) {
      useAlert(t('CAPTAIN.ASSISTANTS.SCENARIOS.API.IMPORT.ERROR'));
    }
  };
  reader.readAsText(file);
  event.target.value = '';
};

const exportScenarios = scenario => {
  let scenariosToExport = [];
  if (scenario) {
    scenariosToExport = [scenario];
  } else if (bulkSelectedIds.value.size > 0) {
    scenariosToExport = scenarios.value.filter(s =>
      bulkSelectedIds.value.has(s.id)
    );
  } else {
    scenariosToExport = filteredScenarios.value;
  }

  const exportData = scenariosToExport.map(s => ({
    title: s.title,
    description: s.description,
    instruction: s.instruction,
  }));

  const dataStr = JSON.stringify(exportData, null, 2);
  const dataUri =
    'data:application/json;charset=utf-8,' + encodeURIComponent(dataStr);

  const exportFileDefaultName = `scenarios-${
    assistantId.value
  }-${new Date().getTime()}.json`;

  const linkElement = document.createElement('a');
  linkElement.setAttribute('href', dataUri);
  linkElement.setAttribute('download', exportFileDefaultName);
  linkElement.click();
};

onMounted(() => {
  store.dispatch('captainScenarios/get', {
    assistantId: assistantId.value,
  });
  store.dispatch('captainTools/getTools');
});
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.ASSISTANTS.SCENARIOS.TITLE')"
    :is-fetching="isFetching"
    :show-know-more="false"
    :show-pagination-footer="false"
  >
    <template #body>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('CAPTAIN.ASSISTANTS.SCENARIOS.TITLE')"
        :description="$t('CAPTAIN.ASSISTANTS.SCENARIOS.DESCRIPTION')"
        :search-placeholder="
          activeTabIndex === 0
            ? t('CAPTAIN.ASSISTANTS.SCENARIOS.LIST.SEARCH_PLACEHOLDER')
            : ''
        "
      >
        <template v-if="scenarios.length" #count>
          <span class="text-body-main text-n-slate-11 truncate min-w-0">
            {{
              $t('CAPTAIN.ASSISTANTS.SCENARIOS.LIST.COUNT', {
                count: scenarios.length,
              })
            }}
          </span>
        </template>
        <template #tabs>
          <TabBar
            :tabs="tabs"
            :initial-active-tab="activeTabIndex"
            @tab-changed="onTabChange"
          />
        </template>
        <template #actions>
          <div class="flex items-center gap-2">
            <input
              ref="importInput"
              type="file"
              accept=".json"
              class="hidden"
              @change="onFileChange"
            />
            <Button
              :label="
                t('CAPTAIN.ASSISTANTS.SCENARIOS.IMPORT_EXPORT.IMPORT_BUTTON')
              "
              sm
              slate
              faded
              icon="i-lucide-upload"
              @click="triggerImport"
            />
            <AddNewScenariosDialog color="blue" @add="addScenario" />
          </div>
        </template>
      </BaseSettingsHeader>

      <div v-if="activeTabIndex === 0" class="flex mt-7 flex-col gap-4 pb-16">
        <div class="flex justify-between items-center">
          <BulkSelectBar
            v-model="bulkSelectedIds"
            :all-items="scenarios"
            :select-all-label="buildSelectedCountLabel"
            :selected-count-label="selectedCountLabel"
            :delete-label="
              $t('CAPTAIN.ASSISTANTS.SCENARIOS.BULK_ACTION.BULK_DELETE_BUTTON')
            "
            @bulk-delete="bulkDeleteScenarios"
          >
            <template #actions>
              <Button
                :label="
                  $t(
                    'CAPTAIN.ASSISTANTS.SCENARIOS.BULK_ACTION.BULK_EXPORT_BUTTON'
                  )
                "
                sm
                slate
                ghost
                class="!px-1.5"
                icon="i-lucide-download"
                @click="exportScenarios()"
              />
              <span class="w-px h-4 bg-n-weak" />
              <Button
                :label="
                  $t(
                    'CAPTAIN.ASSISTANTS.SCENARIOS.BULK_ACTION.BULK_DELETE_BUTTON'
                  )
                "
                sm
                ruby
                ghost
                class="!px-1.5"
                icon="i-lucide-trash"
                @click="bulkDeleteScenarios(null)"
              />
            </template>
          </BulkSelectBar>
        </div>
        <div v-if="scenarios.length === 0" class="mt-1 mb-2">
          <span class="text-n-slate-11 text-sm">
            {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.EMPTY_MESSAGE') }}
          </span>
        </div>
        <div v-else-if="filteredScenarios.length === 0" class="mt-1 mb-2">
          <span class="text-n-slate-11 text-sm">
            {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.SEARCH_EMPTY_MESSAGE') }}
          </span>
        </div>
        <div v-else class="flex flex-col gap-2">
          <ScenariosCard
            v-for="scenario in filteredScenarios"
            :id="scenario.id"
            :key="scenario.id"
            :title="scenario.title"
            :description="scenario.description"
            :instruction="scenario.instruction"
            :tools="scenario.tools"
            :is-selected="bulkSelectedIds.has(scenario.id)"
            :selectable="
              hoveredCard === scenario.id || bulkSelectedIds.size > 0
            "
            @select="handleRuleSelect"
            @delete="deleteScenario(scenario.id)"
            @update="updateScenario"
            @export="exportScenarios(scenario)"
            @hover="isHovered => handleRuleHover(isHovered, scenario.id)"
          />
        </div>
      </div>
      <div v-else class="flex mt-7 flex-col gap-4 pb-16">
        <SuggestedScenarios
          v-for="pack in caseStudies"
          :key="pack.id"
          :title="pack.name"
          :items="pack.scenarios"
          @close="closeSuggestedRules"
          @add="addAllExampleScenarios(pack.scenarios)"
        >
          <template #default="{ item }">
            <div class="flex items-center gap-3 justify-between">
              <span class="text-sm text-n-slate-12">
                {{ item.title }}
              </span>
              <Button
                :label="
                  $t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.SUGGESTED.ADD_SINGLE')
                "
                ghost
                xs
                slate
                class="!text-sm !text-n-slate-11 flex-shrink-0"
                @click="addScenario(item)"
              />
            </div>
            <div class="flex flex-col">
              <span class="text-sm text-n-slate-11 mt-2">
                {{ item.description }}
              </span>
              <component
                :is="renderInstruction(formatMessage(item.instruction, false))"
              />
              <span class="text-sm text-n-slate-11 font-medium mb-1">
                {{ t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.SUGGESTED.TOOLS_USED') }}
                {{ item.tools?.map(tool => `@${tool}`).join(', ') }}
              </span>
            </div>
          </template>
        </SuggestedScenarios>
      </div>
    </template>
  </PageLayout>
</template>
