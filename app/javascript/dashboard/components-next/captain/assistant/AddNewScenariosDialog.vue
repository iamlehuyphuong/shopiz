<script setup>
import { computed, reactive, ref, onMounted, onUnmounted, watch } from 'vue';
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
});

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
  });
  aiPrompt.value = '';
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

// --- AI Generation Logic ---
const aiPrompt = ref('');
const isGenerating = ref(false);
const activeThreadId = ref(null);
const storeMessages = useMapGetter('copilotMessages/getRecords');

const generateScenario = async promptText => {
  if (!promptText.trim() || !activeAssistant.value) return;

  isGenerating.value = true;
  let content = promptText;

  content += `\n\n[IMPORTANT] Bạn đang ở chế độ Tạo Kịch Bản. Hãy hiểu yêu cầu trên là yêu cầu thiết kế kịch bản tư vấn cho chatbot AI.\nTrả về JSON với format: {"reasoning":"...","scenario":{"title":"...","description":"...","instruction":"..."}}\nTrong instruction, khi tham chiếu tool hãy dùng cú pháp: [tool_name](tool://tool_name).\nKHÔNG gọi tool suggest_scenario hay create_scenarios. KHÔNG thực hiện nghiệp vụ thông thường.`;

  try {
    const response = await store.dispatch('copilotThreads/create', {
      assistant_id: activeAssistant.value.id,
      message: content,
    });
    activeThreadId.value = response.id;
  } catch (error) {
    useAlert(error.message);
    isGenerating.value = false;
  }
};

const handleOptimize = () => {
  if (!state.instruction) return;
  const message = t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.OPTIMIZE_PROMPT', {
    instruction: state.instruction,
  });
  generateScenario(message);
};

// Watch for incoming messages from the backend to extract the generated scenario
watch(
  storeMessages,
  newMessages => {
    if (!isGenerating.value || !activeThreadId.value) return;

    // Filter messages for current thread
    const threadMessages = newMessages.filter(
      m =>
        m.copilot_thread_id === activeThreadId.value ||
        m.copilot_thread?.id === activeThreadId.value
    );

    const lastAssistantMsg = threadMessages
      .slice()
      .reverse()
      .find(m => m.message_type === 'assistant');

    if (!lastAssistantMsg) return;

    const msgContent = lastAssistantMsg.message?.content || '';
    if (
      msgContent.includes('error generating the response') ||
      msgContent.includes('There was an error')
    ) {
      useAlert(
        t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.ERROR') ||
          'Lỗi tạo kịch bản, vui lòng thử lại.'
      );
      isGenerating.value = false;
      return;
    }

    try {
      const sanitizedContent = msgContent
        .replace(/[“”]/g, '"')
        .replace(/[‘’]/g, "'");
      const json = JSON.parse(sanitizedContent);
      const data = Array.isArray(json) ? json[0] : json;
      const parsedScenario = data.scenario || data;

      if (parsedScenario && parsedScenario.instruction) {
        state.title = parsedScenario.title || '';
        state.description = parsedScenario.description || '';
        state.instruction = parsedScenario.instruction || '';
        useAlert(
          t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.SUCCESS') ||
            'Kịch bản đã được điền tự động.'
        );
        isGenerating.value = false;
      }
    } catch (e) {
      // It might be streaming or not fully valid JSON yet, so we just wait for the next update.
    }
  },
  { deep: true }
);
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
      :show-footer="true"
      :confirm-button-label="
        t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.CREATE')
      "
      :cancel-button-label="
        t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.CANCEL')
      "
      width="3xl"
      @confirm="onClickAdd"
    >
      <div class="flex flex-col gap-4 min-h-[400px]">
        <!-- AI Prompt Section -->
        <div class="w-full flex flex-col gap-2">
          <TextArea
            v-model="aiPrompt"
            :label="
              t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.AI_PROMPT_LABEL') ||
              'Mô tả kịch bản để AI tạo tự động'
            "
            :placeholder="
              t(
                'CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.AI_PROMPT_PLACEHOLDER'
              ) || 'Ví dụ: Tạo kịch bản tra cứu đơn hàng...'
            "
            :rows="3"
            class="w-full"
          />
          <div class="flex justify-end -mt-1">
            <Button
              :label="
                t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.GENERATE_BUTTON') ||
                'Tạo bằng AI'
              "
              size="xs"
              faded
              slate
              icon="i-lucide-sparkles"
              :is-loading="isGenerating"
              @click="generateScenario(aiPrompt)"
            />
          </div>
        </div>

        <div class="w-full border-t border-n-weak my-2" />

        <!-- Manual Form Section -->
        <div class="w-full flex flex-col gap-4">
          <Input
            v-model="state.title"
            :label="t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.LABEL')"
            :placeholder="
              t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.TITLE.PLACEHOLDER')
            "
            :message="titleError"
            :message-type="titleError ? 'error' : 'info'"
          />
        </div>

        <div class="w-full flex flex-col gap-4">
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

        <div class="w-full flex flex-col gap-4">
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
                :label="
                  t('CAPTAIN.ASSISTANTS.SCENARIOS.ADD.NEW.FORM.OPTIMIZE_BUTTON')
                "
                size="xs"
                faded
                slate
                class="mt-2"
                :is-loading="isGenerating"
                @click="handleOptimize"
              />
            </template>
          </Editor>
        </div>
      </div>
    </Dialog>
  </div>
</template>
