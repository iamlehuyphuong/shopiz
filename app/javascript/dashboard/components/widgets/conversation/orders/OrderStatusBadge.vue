<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  status: {
    type: String,
    default: 'draft',
  },
});

const { t } = useI18n();

const STATUSES = [
  'draft',
  'confirmed',
  'processing',
  'shipped',
  'delivered',
  'cancelled',
];

const statusIndex = computed(() => STATUSES.indexOf(props.status));

const getStatusColor = status => {
  const colors = {
    draft: 'bg-n-slate-5 text-n-slate-11',
    confirmed: 'bg-n-blue-5 text-n-blue-11',
    processing: 'bg-n-amber-5 text-n-amber-11',
    shipped: 'bg-n-violet-5 text-n-violet-11',
    delivered: 'bg-n-teal-5 text-n-teal-11',
    cancelled: 'bg-n-ruby-5 text-n-ruby-11',
  };
  return colors[status] || colors.draft;
};

const getPipelineColor = (index, currentIndex, status) => {
  if (status === 'cancelled') return 'bg-n-ruby-5';
  if (index <= currentIndex) return 'bg-n-teal-9';
  return 'bg-n-slate-4';
};

const getStatusLabel = status => {
  return t(`CONVERSATION.ORDER_PANEL.STATUS.${status.toUpperCase()}`);
};

const pipelineStatuses = computed(() =>
  STATUSES.filter(s => s !== 'cancelled')
);
</script>

<template>
  <div class="flex flex-col gap-1.5">
    <!-- Status Badge -->
    <span
      :class="getStatusColor(status)"
      class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium w-fit capitalize"
    >
      {{ getStatusLabel(status) }}
    </span>

    <!-- Mini Pipeline (only for non-cancelled) -->
    <div
      v-if="status !== 'cancelled'"
      class="flex items-center gap-0.5"
    >
      <div
        v-for="(pStatus, index) in pipelineStatuses"
        :key="pStatus"
        v-tooltip="getStatusLabel(pStatus)"
        class="h-1 flex-1 rounded-full transition-colors duration-300"
        :class="getPipelineColor(index, statusIndex, status)"
      />
    </div>
  </div>
</template>
