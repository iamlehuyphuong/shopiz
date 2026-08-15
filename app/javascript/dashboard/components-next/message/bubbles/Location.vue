<script setup>
import { computed } from 'vue';
import BaseBubble from './Base.vue';
import { useI18n } from 'vue-i18n';
import { useMessageContext } from '../provider.js';

const { attachments } = useMessageContext();
const { t } = useI18n();

const attachment = computed(() => {
  return attachments.value[0];
});

const lat = computed(() => {
  return attachment.value.coordinatesLat;
});
const long = computed(() => {
  return attachment.value.coordinatesLong;
});

const title = computed(() => {
  return attachment.value.fallbackTitle ?? attachment.value.fallback_title;
});

const mapUrl = computed(
  () => `https://maps.google.com/?q=${lat.value},${long.value}`
);

const embedUrl = computed(
  () =>
    `https://maps.google.com/maps?q=${lat.value},${long.value}&z=15&output=embed`
);
</script>

<template>
  <BaseBubble class="overflow-hidden p-3" data-bubble-name="location">
    <div class="grid gap-3 min-w-64">
      <div class="w-full h-40 bg-slate-100 rounded-lg overflow-hidden">
        <iframe
          class="w-full h-full border-0"
          frameborder="0"
          :src="embedUrl"
          allowfullscreen
        />
      </div>
      <div class="space-y-1 overflow-hidden">
        <div v-if="title" class="truncate text-sm text-n-slate-12">
          {{ title }}
        </div>
        <div class="text-xs text-n-slate-11">{{ lat }}, {{ long }}</div>
      </div>
      <div class="mb-2">
        <a
          :href="mapUrl"
          target="_blank"
          rel="noopener noreferrer"
          class="w-full block bg-n-solid-3 px-4 py-2 rounded-lg text-sm text-center border border-n-container"
        >
          {{ t('COMPONENTS.LOCATION_BUBBLE.SEE_ON_MAP') }}
        </a>
      </div>
    </div>
  </BaseBubble>
</template>
