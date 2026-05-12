<script setup>
import { ref, nextTick, onMounted, watch } from 'vue';

const props = defineProps({
  prefill: {
    type: String,
    default: '',
  },
});

const emit = defineEmits(['send']);
const message = ref('');
const textareaRef = ref(null);

const adjustHeight = () => {
  if (!textareaRef.value) return;

  // Reset height to auto to get the correct scrollHeight
  textareaRef.value.style.height = 'auto';
  // Set the height to the scrollHeight
  textareaRef.value.style.height = `${textareaRef.value.scrollHeight}px`;
};

const sendMessage = () => {
  if (message.value.trim()) {
    emit('send', message.value);
    message.value = '';
    // Reset textarea height after sending
    nextTick(() => {
      adjustHeight();
    });
  }
};

const handleInput = () => {
  nextTick(adjustHeight);
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
      message.value = newVal;
      nextTick(() => {
        adjustHeight();
        textareaRef.value?.focus();
        textareaRef.value?.setSelectionRange(0, 0); // Focus at the beginning
      });
    }
  }
);

onMounted(() => {
  nextTick(adjustHeight);
});
</script>

<template>
  <form class="relative" @submit.prevent="sendMessage">
    <textarea
      ref="textareaRef"
      v-model="message"
      :placeholder="$t('CAPTAIN.COPILOT.SEND_MESSAGE')"
      class="w-full reset-base bg-n-alpha-3 ltr:pl-4 ltr:pr-12 rtl:pl-12 rtl:pr-4 py-3 text-sm border border-n-weak rounded-lg focus:outline-none focus:ring-0 focus-visible:ring-2 focus-visible:ring-n-orange-11 focus-visible:border-n-orange-11 resize-none overflow-hidden max-h-[200px] mb-0 text-n-slate-12"
      rows="1"
      @input="handleInput"
      @keydown.enter.exact="handleEnterKey"
    />
    <button
      class="absolute ltr:right-1 rtl:left-1 top-1/2 -translate-y-1/2 h-9 w-10 flex items-center justify-center text-n-slate-11 hover:text-n-orange-11"
      type="submit"
    >
      <i class="i-ph-arrow-up" />
    </button>
  </form>
</template>
