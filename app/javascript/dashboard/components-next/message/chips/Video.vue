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

const showGallery = ref(false);

const { filteredCurrentChatAttachments } = useMessageContext();
</script>

<template>
  <div
    class="overflow-hidden contain-content rounded-xl cursor-pointer relative group w-full"
    :class="{
      'max-h-[350px]': props.totalCount <= 3,
      'h-[200px]': props.totalCount > 3,
      'aspect-square': props.totalCount !== 1 && props.totalCount <= 3,
    }"
    @click="showGallery = true"
  >
    <video
      :src="attachment.dataUrl || attachment.data_url"
      class="w-full h-full"
      :class="props.totalCount === 1 ? 'object-contain' : 'object-cover'"
      muted
      playsInline
    />
    <div
      class="absolute w-full h-full inset-0 p-1 flex items-center justify-center"
    >
      <div
        class="size-7 bg-n-slate-1/60 backdrop-blur-sm rounded-full overflow-hidden shadow-[0_5px_15px_rgba(0,0,0,0.4)]"
      >
        <Icon
          icon="i-teenyicons-play-small-solid"
          class="size-7 text-n-slate-12/80 backdrop-blur"
        />
      </div>
    </div>
    <div
      v-if="props.remainingCount > 0"
      class="absolute inset-0 bg-black/50 flex items-center justify-center text-white text-2xl font-medium"
    >
      +{{ props.remainingCount }}
    </div>
  </div>
  <GalleryView
    v-if="showGallery"
    v-model:show="showGallery"
    :attachment="useSnakeCase(attachment)"
    :all-attachments="filteredCurrentChatAttachments"
    @error="onError"
    @close="() => (showGallery = false)"
  />
</template>
