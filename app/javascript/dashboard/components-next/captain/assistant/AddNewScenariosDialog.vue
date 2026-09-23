<script setup>
import { computed, reactive, ref, onMounted, onUnmounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';
import ScenarioCopilotChat from './ScenarioCopilotChat.vue';

defineProps({
  color: { type: String, default: 'blue' },
});

const emit = defineEmits(['add']);

const { t } = useI18n();
const store = useStore();

const addScenarioDialog = ref(null);

const assistants = useMapGetter('captainAssistants/getRecords');
const activeAssistant = computed(() => assistants.value?.[0]);

const state = reactive({

  id: '',
  title: '',
  description: '',
  instruction: '',
  activeTabIndex: 0,
});

const tabs = computed(() => [
  { label: t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.TABS.MANUAL') },
  { label: t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.TABS.AI_ASSISTANT') },
]);

const rules = {
  title: { required, minLength: minLength(1) },
  description: { required },
  instruction: { required },
};

const v$ = useVuelidate(rules, state);

const titleError = computed(() =>
  v$.value.title.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.ERROR')
    : ''
);

const descriptionError = computed(() =>
  v$.value.description.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.ERROR')
    : ''
);

const instructionError = computed(() =>
  v$.value.instruction.$error
    ? t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.ERROR')
    : ''
);

const resetState = () => {
  Object.assign(state, {
    id: '',
    title: '',
    description: '',
    instruction: '',
    activeTabIndex: 0,
  });
};

const handleTabChange = tab => {
  state.activeTabIndex = tabs.value.findIndex(t => t.label === tab.label);
};

const onClickAdd = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  await emit('add', state);
  resetState();
  addScenarioDialog.value.close();
};

const openDialog = () => {
  if (assistants.value?.length === 0) {
    store.dispatch('captainAssistants/get');
  }
  addScenarioDialog.value.open();
};

const copilotPrefill = ref('');

const handleOptimize = () => {
  if (!state.instruction) return;
  
  state.activeTabIndex = 1;
  const message = t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.OPTIMIZE_PROMPT', {
    instruction: state.instruction,
  });
  
  // Pass to prefill which ScenarioCopilotChat watches
  setTimeout(() => {
    copilotPrefill.value = message;
    setTimeout(() => {
      copilotPrefill.value = '';
    }, 500);
  }, 300);
};

// Handle tool call result from Copilot
const handleSuggestScenario = payload => {
  if (payload.success && payload.scenario) {
    state.title = payload.scenario.title || '';
    state.description = payload.scenario.description || '';
    state.instruction = payload.scenario.instruction || '';
    state.activeTabIndex = 0; // Switch back to manual tab
  }
};

onMounted(() => {
  emitter.on('CAPTAIN_SUGGEST_SCENARIO_USE', handleSuggestScenario);
});

onUnmounted(() => {
  emitter.off('CAPTAIN_SUGGEST_SCENARIO_USE', handleSuggestScenario);
});

const systemPrompt = "MỤC TIÊU: Thiết kế kịch bản tư vấn. Bạn MẶC ĐỊNH SỬ DỤNG DUY NHẤT tool 'suggest_scenario'. KHÔNG dùng tool 'create_scenarios'.";
</script>

<template>
  <div class="inline-flex relative">
    <Button
      :label="t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.CREATE')"
      sm
      :color="color"
      class="flex-shrink-0"
      @click="openDialog"
    />

    <Dialog
      ref="addScenarioDialog"
      :title="t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.TITLE')"
      :confirm-button-label="
        t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.CREATE')
      "
      :cancel-button-label="
        t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.CANCEL')
      "
      :show-footer="state.activeTabIndex === 0"
      width="3xl"
      @confirm="onClickAdd"
    >
      <div class="flex flex-col gap-2 min-h-[400px]">
        <div class="flex justify-start mb-2">
          <TabBar
            :tabs="tabs"
            :initial-active-tab="state.activeTabIndex"
            @tab-changed="handleTabChange"
          />
        </div>

        <div v-show="state.activeTabIndex === 0">
          <div class="w-full flex flex-col gap-4">
            <Input
              v-model="state.title"
              :label="
                t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.LABEL')
              "
              :placeholder="
                t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.PLACEHOLDER')
              "
              :message="titleError"
              :message-type="titleError ? 'error' : 'info'"
            />
          </div>

          <div class="w-full flex flex-col gap-4 mt-4">
            <TextArea
              v-model="state.description"
              :label="
                t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.LABEL')
              "
              :placeholder="
                t(
                  'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.DESCRIPTION.PLACEHOLDER'
                )
              "
              :message="descriptionError"
              :message-type="descriptionError ? 'error' : 'info'"
            />
          </div>

          <div class="w-full flex flex-col gap-4 mt-4">
            <Editor
              v-model="state.instruction"
              :label="
                t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.LABEL')
              "
              :placeholder="
                t(
                  'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.INSTRUCTION.PLACEHOLDER'
                )
              "
              :message="instructionError"
              :message-type="instructionError ? 'error' : 'info'"
              :show-character-count="false"
              enable-captain-tools
            >
              <template #actions>
                <Button
                  :label="t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.OPTIMIZE_BUTTON')"
                  size="xs"
                  faded
                  slate
                  @click="handleOptimize"
                  class="mt-2"
                />
              </template>
            </Editor>
          </div>
        </div>

        <div v-show="state.activeTabIndex === 1" class="h-[500px]">
          <ScenarioCopilotChat
            v-if="activeAssistant"
            :assistant-id="activeAssistant.id"
            :prefill="copilotPrefill"
            @use-scenario="handleSuggestScenario"
          />
        </div>
      </div>
    </Dialog>
  </div>
</template>
