<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  channelKey: {
    type: String,
    required: true,
  },
  channelName: {
    type: String,
    required: true,
  },
  channelIcon: {
    type: String,
    required: true,
  },
  iconColor: {
    type: String,
    default: 'text-n-slate-11',
  },
  inboxCount: {
    type: Number,
    default: 0,
  },
  templates: {
    type: Array,
    default: () => [],
  },
  statusGroups: {
    type: Array,
    default: () => [],
  },
  isActive: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['select']);

const { t } = useI18n();

const totalTemplates = computed(() => props.templates.length);

const inboxLabel = computed(() => {
  if (props.inboxCount === 0)
    return t('SETTINGS.TEMPLATES.CHANNEL_OVERVIEW.NO_INBOXES');
  return `${props.inboxCount} ${props.inboxCount === 1 ? 'inbox' : 'inboxes'}`;
});

const maxCount = computed(() => {
  if (totalTemplates.value === 0) return 1;
  return totalTemplates.value;
});

const handleSelect = () => {
  emit('select', props.channelKey);
};
</script>

<template>
  <button
    type="button"
    class="flex flex-col gap-4 p-5 rounded-xl border transition-all duration-200 text-left w-full min-w-0"
    :class="[
      isActive
        ? 'border-n-orange-7 bg-n-orange-2 ring-1 ring-n-orange-7 shadow-sm'
        : 'border-n-weak bg-n-solid-2 hover:bg-n-solid-3 hover:border-n-strong',
    ]"
    @click="handleSelect"
  >
    <!-- Header -->
    <div class="flex items-center justify-between w-full">
      <div class="flex items-center gap-3 min-w-0">
        <div
          class="flex items-center justify-center w-9 h-9 rounded-lg"
          :class="isActive ? 'bg-n-orange-3' : 'bg-n-solid-3'"
        >
          <span :class="[channelIcon, iconColor]" class="size-5" />
        </div>
        <div class="min-w-0">
          <h3 class="text-sm font-semibold text-n-slate-12 truncate">
            {{ channelName }}
          </h3>
          <p class="text-xs text-n-slate-10 mt-0.5">
            {{ inboxLabel }}
          </p>
        </div>
      </div>
      <div
        class="flex items-center justify-center px-2.5 py-1 rounded-full text-xs font-bold"
        :class="
          isActive
            ? 'bg-n-orange-4 text-n-orange-11'
            : 'bg-n-solid-3 text-n-slate-11'
        "
      >
        {{ totalTemplates }}
      </div>
    </div>

    <!-- Status Bars -->
    <div v-if="statusGroups.length > 0" class="flex flex-col gap-2 w-full">
      <div
        v-for="group in statusGroups"
        :key="group.key"
        class="flex items-center gap-2.5"
      >
        <div class="flex-1 h-1.5 rounded-full bg-n-solid-3 overflow-hidden">
          <div
            class="h-full rounded-full transition-all duration-500"
            :class="group.barColor"
            :style="{
              width: `${Math.max((group.count / maxCount) * 100, group.count > 0 ? 8 : 0)}%`,
            }"
          />
        </div>
        <span class="text-xs text-n-slate-10 whitespace-nowrap min-w-[80px]">
          <span class="font-medium" :class="group.textColor">
            {{ group.count }}
          </span>
          {{ group.label }}
        </span>
      </div>
    </div>

    <!-- Empty State -->
    <div v-else class="flex items-center gap-2 py-1">
      <Icon icon="i-lucide-file-text" class="size-3.5 text-n-slate-9" />
      <span class="text-xs text-n-slate-10">
        {{ t('SETTINGS.TEMPLATES.CHANNEL_OVERVIEW.NO_TEMPLATES') }}
      </span>
    </div>
  </button>
</template>
