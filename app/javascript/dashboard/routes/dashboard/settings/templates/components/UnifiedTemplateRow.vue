<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  template: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['delete', 'navigate']);

const { t } = useI18n();

const channelIcon = computed(() => {
  if (props.template.source === 'whatsapp') return 'i-ri-whatsapp-fill';
  if (props.template.source === 'zalo') return 'i-ri-zalo-oa-fill';
  return 'i-lucide-message-square';
});

const channelIconColor = computed(() => {
  if (props.template.source === 'whatsapp') return 'text-green-500';
  if (props.template.source === 'zalo') return 'text-orange-500';
  return 'text-n-slate-11';
});

const channelLabel = computed(() => {
  if (props.template.source === 'whatsapp') return 'WhatsApp';
  if (props.template.source === 'zalo') return 'Zalo OA';
  return 'Unknown';
});

const statusConfig = computed(() => {
  const status = props.template.normalizedStatus;
  const configs = {
    approved: {
      label: t('SETTINGS.TEMPLATES.UNIFIED_STATUS.APPROVED'),
      classes: 'bg-n-teal-3 text-n-teal-11',
      dotClass: 'bg-n-teal-9',
    },
    active: {
      label: t('SETTINGS.TEMPLATES.UNIFIED_STATUS.ACTIVE'),
      classes: 'bg-n-teal-3 text-n-teal-11',
      dotClass: 'bg-n-teal-9',
    },
    pending: {
      label: t('SETTINGS.TEMPLATES.UNIFIED_STATUS.PENDING'),
      classes: 'bg-n-amber-3 text-n-amber-11',
      dotClass: 'bg-n-amber-9',
    },
    draft: {
      label: t('SETTINGS.TEMPLATES.UNIFIED_STATUS.DRAFT'),
      classes: 'bg-n-slate-3 text-n-slate-11',
      dotClass: 'bg-n-slate-9',
    },
    rejected: {
      label: t('SETTINGS.TEMPLATES.UNIFIED_STATUS.REJECTED'),
      classes: 'bg-n-ruby-3 text-n-ruby-11',
      dotClass: 'bg-n-ruby-9',
    },
    disabled: {
      label: t('SETTINGS.TEMPLATES.UNIFIED_STATUS.DISABLED'),
      classes: 'bg-n-ruby-3 text-n-ruby-11',
      dotClass: 'bg-n-ruby-9',
    },
  };
  return configs[status] || configs.draft;
});

const categoryLabel = computed(() => {
  const cat = props.template.category || '';
  return cat.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase());
});

const categoryIcon = computed(() => {
  const cat = props.template.category || '';
  const icons = {
    marketing: 'i-lucide-megaphone',
    utility: 'i-lucide-settings',
    authentication: 'i-lucide-shield-check',
    transaction_order: 'i-lucide-shopping-cart',
    transaction_payment: 'i-lucide-credit-card',
    transaction_shipping: 'i-lucide-truck',
    transaction_otp: 'i-lucide-key-round',
    transaction_reward: 'i-lucide-gift',
    promotion: 'i-lucide-megaphone',
  };
  return icons[cat] || 'i-lucide-message-square';
});
</script>

<template>
  <div
    class="group flex items-center gap-4 px-4 py-3.5 border border-n-weak rounded-xl bg-n-solid-2 hover:bg-n-solid-3 transition-all duration-150"
  >
    <!-- Channel Icon -->
    <div
      class="flex items-center justify-center w-9 h-9 rounded-lg bg-n-solid-3 flex-shrink-0"
    >
      <span :class="[channelIcon, channelIconColor]" class="size-4.5" />
    </div>

    <!-- Template Info -->
    <div class="flex-1 min-w-0">
      <div class="flex items-center gap-2.5 mb-1">
        <h3
          class="text-sm font-medium text-n-slate-12 truncate max-w-[200px]"
          :title="template.name"
        >
          {{ template.name }}
        </h3>
        <!-- Status Badge -->
        <span
          class="inline-flex items-center gap-1.5 px-2 py-0.5 rounded-full text-xs font-medium"
          :class="statusConfig.classes"
        >
          <span
            class="w-1.5 h-1.5 rounded-full"
            :class="statusConfig.dotClass"
          />
          {{ statusConfig.label }}
        </span>
      </div>
      <div class="flex items-center gap-3 text-xs text-n-slate-10">
        <!-- Channel -->
        <span class="flex items-center gap-1">
          <span :class="[channelIcon, channelIconColor]" class="size-3" />
          {{ channelLabel }}
        </span>
        <!-- Inbox -->
        <span
          v-if="template.inboxName"
          class="flex items-center gap-1 truncate max-w-[140px]"
          :title="template.inboxName"
        >
          <span class="i-lucide-inbox size-3" />
          {{ template.inboxName }}
        </span>
        <!-- Category -->
        <span class="flex items-center gap-1">
          <span :class="categoryIcon" class="size-3" />
          {{ categoryLabel }}
        </span>
        <!-- Language -->
        <span class="flex items-center gap-1">
          <span class="i-lucide-globe size-3" />
          {{ template.language?.toUpperCase() }}
        </span>
      </div>
    </div>

    <!-- Actions -->
    <div
      class="flex items-center gap-1 opacity-0 group-hover:opacity-100 transition-opacity flex-shrink-0"
    >
      <Button
        v-tooltip.top="$t('SETTINGS.TEMPLATES.ACTIONS.VIEW_IN_INBOX')"
        icon="i-lucide-external-link"
        xs
        faded
        slate
        @click.stop="emit('navigate', template)"
      />
      <Button
        v-tooltip.top="$t('SETTINGS.TEMPLATES.ACTIONS.DELETE')"
        icon="i-lucide-trash-2"
        xs
        faded
        ruby
        @click.stop="emit('delete', template)"
      />
    </div>
  </div>
</template>
