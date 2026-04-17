<script setup>
import { computed } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { useBranding } from 'shared/composables/useBranding';

import Label from 'dashboard/components-next/label/Label.vue';

const props = defineProps({
  id: {
    type: [String, Number],
    required: true,
  },
  name: {
    type: String,
    default: '',
  },
  description: {
    type: String,
    default: '',
  },
  enabled: {
    type: Boolean,
    default: false,
  },
  isActive: {
    type: Boolean,
    default: true,
  },
});

const getters = useStoreGetters();
const accountId = getters.getCurrentAccountId;

const { t } = useI18n();
const { replaceInstallationName } = useBranding();

const integrationStatus = computed(() =>
  props.enabled
    ? t('INTEGRATION_APPS.STATUS.ENABLED')
    : t('INTEGRATION_APPS.STATUS.DISABLED')
);

const integrationStatusColor = computed(() =>
  props.enabled ? 'teal' : 'slate'
);

const actionURL = computed(() =>
  frontendURL(`accounts/${accountId.value}/settings/integrations/${props.id}`)
);
</script>

<template>
  <div
    class="group flex flex-col p-5 bg-n-alpha-1 border border-n-weak rounded-2xl hover:border-n-orange-weak hover:shadow-xl hover:shadow-n-orange/5 active:scale-[0.98] transition-all duration-300 ease-out"
    :class="{ 'opacity-70': !isActive }"
  >
    <div class="flex items-start justify-between mb-4">
      <div
        class="flex h-14 w-14 items-center justify-center rounded-2xl bg-white dark:bg-n-solid-2 border border-n-weak shadow-sm group-hover:shadow-md transition-shadow duration-300 overflow-hidden"
      >
        <img
          :src="`/dashboard/images/integrations/${id}.png`"
          class="h-10 w-10 object-contain block dark:hidden"
          :alt="name"
        />
        <img
          :src="`/dashboard/images/integrations/${id}-dark.png`"
          class="h-10 w-10 object-contain hidden dark:block"
          :alt="name"
        />
      </div>
      <div class="flex flex-col items-end gap-2">
        <Label
          :label="integrationStatus"
          :color="integrationStatusColor"
          compact
          class="text-[10px] uppercase tracking-wider font-bold h-5"
        />
      </div>
    </div>
    <div class="flex flex-col flex-1">
      <div class="flex items-start justify-between gap-3 mb-2">
        <h3 class="text-lg font-semibold text-n-slate-12 leading-tight">
          {{ name }}
        </h3>
      </div>
      <p class="text-n-slate-11 text-sm leading-relaxed line-clamp-3">
        {{ replaceInstallationName(description) }}
      </p>
    </div>
    <div class="mt-4 pt-4 border-t border-n-weak/50 flex justify-end">
      <router-link v-if="isActive" :to="actionURL">
        <span
          class="text-xs font-medium text-n-orange hover:text-n-orange-strong transition-colors cursor-pointer flex items-center gap-1"
        >
          {{ $t('INTEGRATION_APPS.CONFIGURE') }}
          <span class="i-lucide-chevron-right size-3" />
        </span>
      </router-link>
      <div v-else>
        <span
          class="text-xs font-medium text-n-slate-7 flex items-center gap-1"
        >
          {{ $t('INTEGRATION_APPS.CONFIGURE') }}
          <span class="i-lucide-lock size-3" />
        </span>
      </div>
    </div>
  </div>
</template>
