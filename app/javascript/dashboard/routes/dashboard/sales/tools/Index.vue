<script setup>
import { computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import IntegrationItem from 'dashboard/routes/dashboard/settings/integrations/IntegrationItem.vue';

const { t } = useI18n();
const store = useStore();

const ECOMMERCE_APP_IDS = [
  'shopify',
  'google_calendar',
  'calendly',
  'woocommerce',
  'leadsquared',
  'kiotviet',
  'nhanhvn',
  'haravan',
  'sapo',
  'tiktok_shop',
];

const isLoading = computed(() => {
  return store.getters['integrations/getUIFlags'].isFetching;
});

const ecomIntegrations = computed(() => {
  const allIntegrations =
    store.getters['integrations/getAppIntegrations'] || [];
  const filtered = allIntegrations.filter(app =>
    ECOMMERCE_APP_IDS.includes(app.id)
  );
  return filtered.sort((a, b) => {
    const getStatusWeight = status => {
      if (status === 'published') return 1;
      if (status === 'beta') return 2;
      if (status === 'coming_soon') return 3;
      return 4;
    };

    const weightA = getStatusWeight(a.status);
    const weightB = getStatusWeight(b.status);

    if (weightA !== weightB) {
      return weightA - weightB;
    }

    return ECOMMERCE_APP_IDS.indexOf(a.id) - ECOMMERCE_APP_IDS.indexOf(b.id);
  });
});

onMounted(() => {
  store.dispatch('integrations/get');
});
</script>

<template>
  <div class="w-full">
    <!-- Skeleton Loading -->
    <div v-if="isLoading" class="animate-pulse w-full">
      <div class="flex flex-col gap-6">
        <div class="flex flex-col gap-2">
          <div class="h-6 w-48 rounded bg-n-slate-3" />
          <div class="h-4 w-96 rounded bg-n-slate-3" />
        </div>
        <div
          class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 xl:grid-cols-3 gap-6 mt-4"
        >
          <div
            v-for="i in 6"
            :key="i"
            class="flex flex-col p-5 bg-white dark:bg-n-solid-1 border border-n-weak rounded-xl"
          >
            <div class="flex items-start justify-between mb-4">
              <div class="h-12 w-12 rounded-xl bg-n-slate-3" />
              <div class="h-6 w-6 rounded-full bg-n-slate-3" />
            </div>
            <div class="flex flex-col flex-1">
              <div class="flex items-center justify-between gap-3 mb-2">
                <div class="h-5 w-32 rounded bg-n-slate-3" />
                <div class="h-4 w-16 rounded bg-n-slate-3" />
              </div>
              <div class="space-y-2 mt-2">
                <div class="h-3 w-full rounded bg-n-slate-3" />
                <div class="h-3 w-5/6 rounded bg-n-slate-3" />
                <div class="h-3 w-4/6 rounded bg-n-slate-3" />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    <div v-else class="w-full">
      <div class="flex flex-col gap-6">
        <div class="flex flex-col gap-1">
          <h3 class="text-lg font-semibold text-n-slate-12">
            {{ t('SALES.MODULE_TOOLS.HEADER.TITLE') }}
          </h3>
          <p class="text-sm text-n-slate-11">
            {{ t('SALES.MODULE_TOOLS.HEADER.DESCRIPTION') }}
          </p>
        </div>
        <div
          class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 xl:grid-cols-3 gap-6"
        >
          <IntegrationItem
            v-for="item in ecomIntegrations"
            :id="item.id"
            :key="item.id"
            :logo="item.logo"
            :name="item.name"
            :description="item.description"
            :enabled="item.enabled"
            :is-active="item.is_active"
            :status="item.status"
            :path-prefix="'sales/tools'"
          />
        </div>
      </div>
    </div>
  </div>
</template>
