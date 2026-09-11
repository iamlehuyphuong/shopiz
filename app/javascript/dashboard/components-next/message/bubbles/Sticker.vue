<script setup>
import { computed, onMounted, watch } from 'vue';
import { useLoadWithRetry } from 'dashboard/composables/loadWithRetry';
import BaseBubble from './Base.vue';
import Icon from 'next/icon/Icon.vue';
import Spinner from 'shared/components/Spinner.vue';
import { useMessageContext } from '../provider.js';

const { attachments } = useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
});

const { isLoaded, hasError, loadWithRetry } = useLoadWithRetry();

const attemptLoad = () => {
  if (attachment.value?.dataUrl) {
    loadWithRetry(attachment.value.dataUrl);
  } else {
    hasError.value = true;
  }
};

onMounted(() => {
  attemptLoad();
});

watch(
  () => attachment.value?.dataUrl,
  (newUrl, oldUrl) => {
    if (newUrl && newUrl !== oldUrl && (!isLoaded.value || hasError.value)) {
      attemptLoad();
    }
  }
);
</script>

<template>
  <BaseBubble
    class="overflow-hidden p-3 bg-transparent!"
    data-bubble-name="sticker"
    :show-background="false"
  >
    <div
      v-if="hasError"
      class="flex flex-col items-center justify-center p-4 bg-slate-50 dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700"
    >
      <Icon icon="i-lucide-sticker" class="text-n-slate-11 w-8 h-8 mb-2" />
      <p class="mb-0 text-n-slate-11 text-sm font-medium">[Sticker]</p>
    </div>
    <div v-else-if="isLoaded" class="relative group rounded-lg overflow-hidden">
      <img
        class="skip-context-menu max-w-[130px] max-h-[130px] object-contain"
        :src="attachment.dataUrl"
        :width="attachment.width"
        :height="attachment.height"
      />
    </div>
    <div
      v-else
      class="flex flex-col items-center justify-center p-4 bg-slate-50 dark:bg-slate-800 rounded-lg border border-slate-200 dark:border-slate-700 min-w-[130px] min-h-[130px]"
    >
      <Spinner />
    </div>
  </BaseBubble>
</template>
