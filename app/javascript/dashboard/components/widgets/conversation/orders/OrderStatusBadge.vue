<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  status: {
    type: String,
    default: 'draft',
  },
  editable: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['update']);

const { t } = useI18n();

const STATUSES = [
  'draft',
  'pending',
  'confirmed',
  'processing',
  'shipped',
  'delivered',
  'cancelled',
  'returned',
];

const statusIndex = computed(() => STATUSES.indexOf(props.status));

const getStatusColor = status => {
  const colors = {
    draft: 'bg-n-slate-5 text-n-slate-11',
    pending: 'bg-n-orange-5 text-n-orange-11',
    confirmed: 'bg-n-blue-5 text-n-blue-11',
    processing: 'bg-n-amber-5 text-n-amber-11',
    shipped: 'bg-n-violet-5 text-n-violet-11',
    delivered: 'bg-n-teal-5 text-n-teal-11',
    cancelled: 'bg-n-ruby-5 text-n-ruby-11',
    returned: 'bg-n-pink-5 text-n-pink-11',
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
    <select
      v-if="editable"
      :value="status"
      class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium w-full capitalize appearance-none outline-none cursor-pointer border border-n-strong text-n-slate-12 bg-transparent hover:bg-n-alpha-1 m-0"
      style="
        background-image: url('data:image/svg+xml;charset=UTF-8,%3csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22currentColor%22 stroke-width=%222%22%3e%3cpath d=%22m6 9 6 6 6-6%22/%3e%3c/svg%3e');
        background-repeat: no-repeat;
        background-position: right 0.25rem center;
        background-size: 1em;
        padding-right: 1.5rem;
      "
      @change="e => emit('update', e.target.value)"
    >
      <option v-for="s in STATUSES" :key="s" :value="s">
        {{ getStatusLabel(s) }}
      </option>
    </select>
    <span
      v-else
      :class="getStatusColor(status)"
      class="inline-flex items-center px-2 py-0.5 rounded text-xs font-medium w-fit capitalize"
    >
      {{ getStatusLabel(status) }}
    </span>

    <!-- Mini Pipeline (only for non-cancelled) -->
    <div v-if="status !== 'cancelled'" class="flex items-center gap-0.5">
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
