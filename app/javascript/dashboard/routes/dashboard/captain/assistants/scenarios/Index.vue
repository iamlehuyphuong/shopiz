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

const { t } = useI18n();
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
const scenariosExample = [
  {
    id: 1,
    title: t('Prospective Buyer'),
    description: t(
      'Handle customers who are showing interest in purchasing a license'
    ),
    instruction: t(
      'If someone is interested in purchasing a license, ask them for following:\n\n1. How many licenses are they willing to purchase?\n2. Are they migrating from another platform?\n. Once these details are collected, do the following steps\n1. add a private note to with the information you collected using [Add Private Note](tool://add_private_note)\n2. Add label "sales" to the contact using [Add Label to Conversation](tool://add_label_to_conversation)\n3. Reply saying "one of us will reach out soon" and provide an estimated timeline for the response and [Handoff to Human](tool://handoff)'
    ),
    tools: ['add_private_note', 'add_label_to_conversation', 'handoff'],
  },
  {
    id: 2,
    title: t('Technical Issue'),
    description: t(
      'Assist customers who report a technical problem or bug with the product'
    ),
    instruction: t(
      'If a customer reports a technical issue, follow these steps:\n\n1. Ask for a detailed description of the problem and any error messages.\n2. Request screenshots or screen recordings if possible.\n3. Add a private note summarizing the issue using [Add Private Note](tool://add_private_note).\n4. Assign the conversation to the "technical support" team using [Add Label to Conversation](tool://add_label_to_conversation).\n5. Inform the customer that the issue has been escalated and provide an estimated response time.'
    ),
    tools: ['add_private_note', 'add_label_to_conversation'],
  },
  {
    id: 3,
    title: t('Feature Request'),
    description: t('Handle customers who suggest new features or improvements'),
    instruction: t(
      'When a customer requests a new feature, do the following:\n\n1. Thank them for their suggestion.\n2. Add a private note with the feature details using [Add Private Note](tool://add_private_note).\n3. Tag the conversation with "feature-request" using [Add Label to Conversation](tool://add_label_to_conversation).\n4. Let the customer know their feedback has been shared with the product team.'
    ),
    tools: ['add_private_note', 'add_label_to_conversation'],
  },
];

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

const addAllExampleScenarios = async () => {
  try {
    scenariosExample.forEach(async scenario => {
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
          <AddNewScenariosDialog color="blue" @add="addScenario" />
        </template>
      </BaseSettingsHeader>

      <div v-if="activeTabIndex === 0" class="flex mt-7 flex-col gap-4">
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
          />
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
            @hover="isHovered => handleRuleHover(isHovered, scenario.id)"
          />
        </div>
      </div>
      <div v-else class="flex mt-7 flex-col gap-4">
        <SuggestedScenarios
          :title="$t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.SUGGESTED.TITLE')"
          :items="scenariosExample"
          @close="closeSuggestedRules"
          @add="addAllExampleScenarios"
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
