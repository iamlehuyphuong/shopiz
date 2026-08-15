<script setup>
import { computed, onMounted } from 'vue';
import { useLoadWithRetry } from 'dashboard/composables/loadWithRetry';
import BaseBubble from './Base.vue';
import Icon from 'next/icon/Icon.vue';
import { useMessageContext } from '../provider.js';

const { attachments } = useMessageContext();

const attachment = computed(() => {
  return attachments.value[0];
});

const { isLoaded, hasError, loadWithRetry } = useLoadWithRetry();

onMounted(() => {
  if (attachment.value?.dataUrl) {
    loadWithRetry(attachment.value.dataUrl);
  }
});

</script>

<template>
  <BaseBubble
    class="overflow-hidden p-3 bg-transparent!"
    data-bubble-name="sticker"
    :show-background="false"
  >
    <div v-if="hasError" class="flex items-center gap-1 text-center rounded-lg">
      <Icon icon="i-lucide-circle-off" class="text-n-slate-11" />
      <p class="mb-0 text-n-slate-11">
        {{ $t('COMPONENTS.MEDIA.IMAGE_UNAVAILABLE') }}
      </p>
    </div>
    <div v-else-if="isLoaded" class="relative group rounded-lg overflow-hidden">
      <img
        class="skip-context-menu max-w-[130px] max-h-[130px] object-contain"
        :src="attachment.dataUrl"
        :width="attachment.width"
        :height="attachment.height"
      />
    </div>
  </BaseBubble>
</template>
