<script setup>
import { useI18n } from 'vue-i18n';
import CardLayout from 'dashboard/components-next/CardLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  template: {
    type: Object,
    required: true,
  },
  typeLabels: {
    type: Object,
    default: () => ({}),
  },
  statusColors: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['edit', 'delete']);

const { t } = useI18n();

const statusClass = props.statusColors[props.template.status] || '';
const typeLabel = props.typeLabels[props.template.template_type]
  ? t(props.typeLabels[props.template.template_type])
  : props.template.template_type;

const previewContent = (() => {
  const elements = props.template.template_content?.elements || [];
  const textEl = elements.find(e => e.type === 'text');
  return textEl?.content || '—';
})();
</script>

<template>
  <CardLayout layout="row">
    <div class="flex flex-col items-start justify-between flex-1 min-w-0 gap-2">
      <div class="flex items-center gap-3 w-full">
        <span class="text-base font-medium text-n-slate-12 truncate">
          {{ template.template_name }}
        </span>
        <span
          class="text-xs font-medium px-2 py-0.5 rounded-md whitespace-nowrap"
          :class="statusClass"
        >
          {{ template.status }}
        </span>
        <span
          class="text-xs font-medium px-2 py-0.5 rounded-md bg-n-orange-3 text-n-orange-11 whitespace-nowrap"
        >
          {{ typeLabel }}
        </span>
      </div>
      <p class="text-sm text-n-slate-11 line-clamp-1">
        {{ previewContent }}
      </p>
    </div>
    <div class="flex items-center gap-2">
      <Button
        variant="faded"
        size="sm"
        color="slate"
        icon="i-lucide-sliders-vertical"
        @click="emit('edit', template)"
      />
      <Button
        variant="faded"
        color="ruby"
        size="sm"
        icon="i-lucide-trash"
        @click="emit('delete', template)"
      />
    </div>
  </CardLayout>
</template>
