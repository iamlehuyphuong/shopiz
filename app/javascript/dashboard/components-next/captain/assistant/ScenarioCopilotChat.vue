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
});

const emit = defineEmits(['use-scenario']);

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
    return lastMsg.message_type === 'user' || lastMsg.message_type === 'assistant_thinking';
  }
  return false;
});

const formattedMessages = computed(() => {
  return storeMessages.value.map(msg => {
    let content = msg.message?.content || '';
    let parsedScenario = null;
    
    // Parse JSON block for scenario proposal
    if (content.includes('"scenario":')) {
      try {
        const match = content.match(/\{[\s\S]*"scenario"[\s\S]*\}/);
        if (match) {
          const json = JSON.parse(match[0]);
          if (json.success && json.scenario) {
            parsedScenario = json.scenario;
            content = `**Kịch bản đề xuất:**\n- Tiêu đề: ${parsedScenario.title}\n- Mô tả: ${parsedScenario.description}`;
          }
        }
      } catch (e) {
        // Ignore parse error
      }
    }
    
    return {
      sender: msg.message_type === 'user' ? 'user' : 'assistant',
      content,
      reasoning: msg.message?.reasoning,
      toolCalls: msg.message?.function_name ? [{ name: msg.message.function_name }] : [],
      isReasoningExpanded: false,
      parsedScenario,
    };
  });
});

const resetConversation = () => {
  threadId.value = null;
  newMessage.value = '';
};

const sendMessage = async () => {
  if (!newMessage.value.trim()) return;
  const content = newMessage.value;
  newMessage.value = '';
  isSending.value = true;

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
  <div class="flex flex-col h-full rounded-xl border py-6 border-n-weak text-n-slate-11">
    <div class="mb-8 px-6">
      <div class="flex justify-between items-center mb-1">
        <h3 class="text-lg font-medium">ShopizAI Assistant</h3>
        <NextButton ghost sm slate icon="i-lucide-rotate-ccw" @click="resetConversation" />
      </div>
      <p class="text-sm text-n-slate-11">
        Mô tả kịch bản bạn muốn tạo hoặc tối ưu, AI sẽ hỗ trợ bạn.
      </p>
    </div>

    <MessageList :messages="formattedMessages" :is-loading="isLoading" @use-scenario="$emit('use-scenario', $event)" />

    <div class="flex items-center mx-6 bg-n-background outline outline-1 outline-n-weak rounded-xl p-3">
      <input
        v-model="newMessage"
        class="flex-1 bg-transparent border-none focus:outline-none text-sm mb-0 text-n-slate-12 placeholder:text-n-slate-10"
        placeholder="Nhập yêu cầu của bạn..."
        @keydown.enter.exact="handleEnterKey"
      />
      <NextButton ghost sm :disabled="!newMessage.trim()" icon="i-lucide-send" @click="sendMessage" />
    </div>
  </div>
</template>
