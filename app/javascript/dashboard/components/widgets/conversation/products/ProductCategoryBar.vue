<script setup>
import { useI18n } from 'vue-i18n';

defineProps({
  categories: {
    type: Array,
    default: () => [],
  },
  selectedId: {
    type: [String, Number, null],
    default: null,
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select']);
const { t } = useI18n();
</script>

<template>
  <div class="px-3 pb-2">
    <div class="flex gap-1.5 overflow-x-auto scrollbar-hide py-0.5">
      <!-- All chip -->
      <button
        class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium whitespace-nowrap transition-all shrink-0"
        :class="
          selectedId === null
            ? 'bg-n-brand text-white'
            : 'bg-n-solid-3 text-n-slate-11 hover:bg-n-alpha-2'
        "
        @click="emit('select', null)"
      >
        {{ t('CONVERSATION.PRODUCT_PANEL.ALL_CATEGORIES') }}
      </button>

      <!-- Category chips -->
      <button
        v-for="cat in categories"
        :key="cat.id"
        class="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-medium whitespace-nowrap transition-all shrink-0"
        :class="
          selectedId === cat.id
            ? 'bg-n-brand text-white'
            : 'bg-n-solid-3 text-n-slate-11 hover:bg-n-alpha-2'
        "
        @click="emit('select', cat.id)"
      >
        {{ cat.name }}
      </button>

      <!-- Loading -->
      <div v-if="isLoading" class="flex items-center px-2">
        <i class="i-lucide-loader-2 text-xs text-n-slate-10 animate-spin" />
      </div>
    </div>
  </div>
</template>
