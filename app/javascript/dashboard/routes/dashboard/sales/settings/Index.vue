<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

const mainTabs = [
  {
    key: 'tool',
    label: t('SALES.SETTINGS.TABS.TOOL'),
    routeName: 'sales_settings_tool',
  },
  {
    key: 'payment',
    label: t('SALES.SETTINGS.TABS.PAYMENT'),
    routeName: 'sales_settings_payment',
  },
  {
    key: 'assistant',
    label: t('SALES.SETTINGS.TABS.ASSISTANT'),
    routeName: 'sales_settings_assistant',
  },
];

const activeMainTabIndex = computed(() => {
  const index = mainTabs.findIndex(tab => route.name === tab.routeName);
  return index >= 0 ? index : 0;
});

const onMainTabChange = index => {
  const tab = mainTabs[index];
  if (tab && tab.routeName) {
    router.push({ name: tab.routeName });
  }
};
</script>

<template>
  <div class="w-full h-full overflow-auto">
    <div class="max-w-5xl mx-auto px-6 py-6">
      <div class="flex flex-col gap-6">
        <!-- Header -->
        <div class="flex flex-col gap-1">
          <h3 class="text-lg font-semibold text-n-slate-12">
            {{
              t('INBOX_MGMT.ECOMMERCE.TITLE') ||
              t('SALES.SETTINGS.HEADER.TITLE')
            }}
          </h3>
        </div>

        <!-- Tabs -->
        <woot-tabs
          class="[&_ul]:p-0 top-px relative mb-6"
          :index="activeMainTabIndex"
          :border="false"
          @change="onMainTabChange"
        >
          <woot-tabs-item
            v-for="(tab, index) in mainTabs"
            :key="tab.key"
            :index="index"
            :name="tab.label"
            :show-badge="false"
            is-compact
          />
        </woot-tabs>

        <!-- Router View for Tab Content -->
        <router-view />
      </div>
    </div>
  </div>
</template>
