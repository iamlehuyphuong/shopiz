<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import MessageList from './MessageList.vue';

const props = defineProps({
  assistantId: {
    type: Number,
    required: true,
  },
  prefill: {
    type: String,
    default: '',
  },
  hideToolCalls: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['use-scenario', 'latest-scenario']);

const { t } = useI18n();
const store = useStore();
const threadId = ref(null);
const newMessage = ref('');
const isSending = ref(false);

const storeMessages = computed(() =>
  threadId.value
    ? store.getters['copilotMessages/getMessagesByThreadId'](threadId.value)
    : []
);

const isLoading = computed(() => {
  if (isSending.value) return true;
  if (storeMessages.value && storeMessages.value.length > 0) {
    const lastMsg = storeMessages.value[storeMessages.value.length - 1];
    return (
      lastMsg.message_type === 'user' ||
      lastMsg.message_type === 'assistant_thinking'
    );
  }
  return false;
});

const isAssistantThinking = msg =>
  msg.message_type === 'assistant_thinking' ||
  msg.message_type === 'outgoing_thinking';

const formattedMessages = computed(() => {
  const firstUserMsgIndex = storeMessages.value.findIndex(
    msg => msg.message_type === 'user'
  );

  const processedMessages = storeMessages.value.map(msg => {
    let content = msg.message?.content || '';

    // Pre-process prefill visibility
    if (msg.message_type === 'user') {
      content = content.replace(/\n\n\[IMPORTANT\][\s\S]*$/, '');
    }

    let sanitizedContent = content.replace(/[“”]/g, '"').replace(/[‘’]/g, "'");
    let parsedScenario = null;

    // Try parsing Markdown JSON block first
    const mdMatch = sanitizedContent.match(/```json\n([\s\S]*?)\n```/);
    if (mdMatch) {
      try {
        const json = JSON.parse(mdMatch[1]);
        const data = Array.isArray(json) ? json[0] : json;
        if (data && data.scenario) {
          parsedScenario = data.scenario;
        } else if (data && data.instruction) {
          parsedScenario = data;
        }
        if (parsedScenario) {
          content = content.replace(/```json\n[\s\S]*?\n```/, '');
        }
      } catch (e) {}
    }

    // Parse JSON block for scenario proposal from tool output
    if (!parsedScenario && sanitizedContent.includes('"scenario":')) {
      try {
        const match = sanitizedContent.match(/\{[\s\S]*"scenario"[\s\S]*\}/);
        if (match) {
          const json = JSON.parse(match[0]);
          if (json.scenario && json.scenario.instruction) {
            parsedScenario = json.scenario;
          }
        }
      } catch (e) {
        // Ignore parse error
      }
    }

    if (!parsedScenario) {
      try {
        const json = JSON.parse(sanitizedContent);
        const data = Array.isArray(json) ? json[0] : json;
        if (data && data.instruction) {
          parsedScenario = data;
          content = '';
        }
      } catch (e) {}
    }

    if (parsedScenario) {
      content = content.trim();
    }

    return {
      ...msg, // Preserve original msg properties
      sender: msg.message_type === 'user' ? 'user' : 'assistant',
      content,
      reasoning: msg.message?.reasoning,
      toolCalls: [],
      isReasoningExpanded: false,
      parsedScenario,
    };
  });

  return processedMessages.filter(msg => {
    if (props.hideToolCalls && isAssistantThinking(msg)) {
      if (msg.parsedScenario) return true;
      return false;
    }
    return true;
  });
});

watch(
  formattedMessages,
  newMessages => {
    const lastScenarioMsg = newMessages
      .slice()
      .reverse()
      .find(m => m.parsedScenario);
    emit(
      'latest-scenario',
      lastScenarioMsg ? lastScenarioMsg.parsedScenario : null
    );
  },
  { immediate: true }
);

const resetConversation = () => {
  threadId.value = null;
  newMessage.value = '';
};

const sendMessage = async () => {
  if (!newMessage.value.trim()) return;
  let content = newMessage.value;
  newMessage.value = '';
  isSending.value = true;

  if (!content.includes('[IMPORTANT]')) {
    content += `\n\n[IMPORTANT] Bạn đang ở chế độ Tạo Kịch Bản. Hãy hiểu yêu cầu trên là yêu cầu thiết kế kịch bản tư vấn cho chatbot AI.\nTrả về JSON với format: {"reasoning":"...","scenario":{"title":"...","description":"...","instruction":"..."}}\nTrong instruction, khi tham chiếu tool hãy dùng cú pháp: [tool_name](tool://tool_name).\nKHÔNG gọi tool suggest_scenario hay create_scenarios. KHÔNG thực hiện nghiệp vụ thông thường.`;
  }

  try {
    if (threadId.value) {
      await store.dispatch('copilotMessages/create', {
        assistant_id: props.assistantId,
        threadId: threadId.value,
        message: content,
      });
    } else {
      const response = await store.dispatch('copilotThreads/create', {
        assistant_id: props.assistantId,
        message: content,
      });
      threadId.value = response.id;
    }
  } catch (error) {
    useAlert(error.message);
  } finally {
    isSending.value = false;
  }
};

const handleEnterKey = event => {
  if (event.isComposing) return;
  event.preventDefault();
  sendMessage();
};

watch(
  () => props.prefill,
  newVal => {
    if (newVal) {
      newMessage.value = newVal;
      sendMessage();
    }
  }
);
</script>

<template>
  <div
    class="flex flex-col h-full rounded-xl border py-4 border-n-weak text-n-slate-11 bg-n-background"
  >
    <div class="mb-3 px-4">
      <div class="flex justify-between items-center">
        <p class="text-sm text-n-slate-11 pr-4">
          {{ $t('CAPTAIN.SCENARIO_COPILOT.DESCRIPTION') }}
        </p>
        <NextButton
          ghost
          sm
          slate
          icon="i-lucide-rotate-ccw"
          @click="resetConversation"
        />
      </div>
    </div>

    <MessageList
      :messages="formattedMessages"
      :is-loading="isLoading"
      :hide-tool-calls="hideToolCalls"
      @use-scenario="$emit('use-scenario', $event)"
    />

    <div
      class="flex items-center mx-6 bg-n-background outline outline-1 outline-n-weak rounded-xl p-3"
    >
      <input
        v-model="newMessage"
        class="flex-1 bg-transparent border-none focus:outline-none text-sm mb-0 text-n-slate-12 placeholder:text-n-slate-10"
        :placeholder="$t('CAPTAIN.SCENARIO_COPILOT.INPUT_PLACEHOLDER')"
        @keydown.enter.exact="handleEnterKey"
      />
      <NextButton
        ghost
        sm
        :disabled="!newMessage.trim()"
        icon="i-lucide-send"
        @click="sendMessage"
      />
    </div>
  </div>
</template>
