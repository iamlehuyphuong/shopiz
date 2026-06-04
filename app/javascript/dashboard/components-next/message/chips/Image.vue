<script setup>
import { ref } from 'vue';
import Icon from 'next/icon/Icon.vue';
import { useSnakeCase } from 'dashboard/composables/useTransformKeys';
import { useMessageContext } from '../provider.js';

import GalleryView from 'dashboard/components/widgets/conversation/components/GalleryView.vue';

const props = defineProps({
  attachment: {
    type: Object,
    required: true,
  },
  totalCount: {
    type: Number,
    default: 1,
  },
  remainingCount: {
    type: Number,
    default: 0,
  },
});
const hasError = ref(false);
const showGallery = ref(false);

const { filteredCurrentChatAttachments } = useMessageContext();

const handleError = () => {
  hasError.value = true;
};
</script>

<template>
  <div
    class="relative overflow-hidden contain-content rounded-xl cursor-pointer w-full"
    :class="{
      'max-h-[350px]': props.totalCount <= 3,
      'h-[200px]': props.totalCount > 3,
      'aspect-square': props.totalCount !== 1 && props.totalCount <= 3,
    }"
    @click="showGallery = true"
  >
    <div
      v-if="hasError"
      class="flex flex-col items-center justify-center gap-1 text-xs text-center rounded-lg size-full bg-n-alpha-1 text-n-slate-11"
    >
      <Icon icon="i-lucide-circle-off" class="text-n-slate-11" />
      {{ $t('COMPONENTS.MEDIA.LOADING_FAILED') }}
    </div>
    <template v-else>
      <img
        class="w-full h-full skip-context-menu"
        :class="props.totalCount === 1 ? 'object-contain' : 'object-cover'"
        :src="attachment.dataUrl || attachment.data_url"
        @error="handleError"
      />
      <div
        v-if="props.remainingCount > 0"
        class="absolute inset-0 bg-black/50 flex items-center justify-center text-white text-2xl font-medium"
      >
        +{{ props.remainingCount }}
      </div>
    </template>
  </div>
  <GalleryView
    v-if="showGallery"
    v-model:show="showGallery"
    :attachment="useSnakeCase(attachment)"
    :all-attachments="filteredCurrentChatAttachments"
    @error="handleError"
    @close="() => (showGallery = false)"
  />
</template>
