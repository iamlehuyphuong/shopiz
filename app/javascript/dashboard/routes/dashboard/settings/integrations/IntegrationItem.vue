<script setup>
import { computed } from 'vue';
import { useStoreGetters } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { useBranding } from 'shared/composables/useBranding';

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

const actionURL = computed(() =>
  frontendURL(`accounts/${accountId.value}/settings/integrations/${props.id}`)
);
</script>

<template>
  <div
    class="group flex flex-col p-5 bg-white dark:bg-n-solid-1 border border-n-weak rounded-xl hover:border-n-orange-weak hover:shadow-lg hover:shadow-n-orange/5 active:scale-[0.98] transition-all duration-300 ease-out"
    :class="{ 'opacity-70': !isActive }"
  >
    <div class="flex items-start justify-between mb-4">
      <div
        class="flex h-12 w-12 items-center justify-center rounded-xl bg-white dark:bg-n-solid-2 border border-n-strong/20 shadow-sm overflow-hidden"
      >
        <img
          :src="`/dashboard/images/integrations/${id}.png`"
          class="h-7 w-7 object-contain block dark:hidden"
          :alt="name"
        />
        <img
          :src="`/dashboard/images/integrations/${id}-dark.png`"
          class="h-7 w-7 object-contain hidden dark:block"
          :alt="name"
        />
      </div>
      <div class="flex items-center justify-center h-6 w-6 rounded-full bg-n-slate-5 dark:bg-n-slate-6">
        <span class="i-lucide-check text-white size-3.5" />
      </div>
    </div>
    
    <div class="flex flex-col flex-1">
      <div class="flex items-center justify-between gap-3 mb-2">
        <h3 class="text-base font-medium text-n-slate-12 leading-tight">
          {{ name }}
        </h3>
        <router-link v-if="isActive" :to="actionURL">
          <span
            class="text-sm font-medium text-n-orange hover:text-n-orange-strong transition-colors cursor-pointer"
          >
            {{ $t('INTEGRATION_APPS.CONFIGURE') }}
          </span>
        </router-link>
        <div v-else>
          <span
            class="text-sm font-medium text-n-slate-7 flex items-center gap-1"
          >
            {{ $t('INTEGRATION_APPS.CONFIGURE') }}
            <span class="i-lucide-lock size-3.5" />
          </span>
        </div>
      </div>
      <p class="text-n-slate-11 text-[13px] leading-relaxed line-clamp-3">
        {{ replaceInstallationName(description) }}
      </p>
    </div>
  </div>
</template>
