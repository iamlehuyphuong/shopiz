<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import SalesLayout from './components/SalesLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';

const { t } = useI18n();

const onImageError = e => {
  e.target.style.display = 'none';
};

const tools = computed(() => [
  {
    id: 'shopify',
    name: 'Shopify',
    logo: 'shopify',
    description: t('SALES.MODULE_TOOLS.DESCRIPTIONS.SHOPIFY'),
    enabled: true,
  },
  {
    id: 'kiotviet',
    name: 'KiotViet',
    logo: 'kiotviet',
    description: t('SALES.MODULE_TOOLS.DESCRIPTIONS.KIOTVIET'),
    enabled: true,
  },
  {
    id: 'haravan',
    name: 'Haravan',
    logo: 'haravan',
    description: t('SALES.MODULE_TOOLS.DESCRIPTIONS.HARAVAN'),
    enabled: true,
  },
  {
    id: 'woocommerce',
    name: 'WooCommerce',
    logo: 'woocommerce',
    description: t('SALES.MODULE_TOOLS.DESCRIPTIONS.WOOCOMMERCE'),
    enabled: true,
  },
  {
    id: 'sapo',
    name: 'Sapo',
    logo: 'sapo',
    description: t('SALES.MODULE_TOOLS.DESCRIPTIONS.SAPO'),
    enabled: true,
  },
  {
    id: 'nhanhvn',
    name: 'Nhanh.vn',
    logo: 'nhanhvn',
    description: t('SALES.MODULE_TOOLS.DESCRIPTIONS.NHANHVN'),
    enabled: true,
  },
  {
    id: 'tiktokshop',
    name: 'TikTok Shop',
    logo: 'tiktok_shop',
    description: t('SALES.MODULE_TOOLS.DESCRIPTIONS.TIKTOK_SHOP'),
    enabled: false,
  },
]);
</script>

<template>
  <SalesLayout>
    <template #header>
      <BaseSettingsHeader
        :title="$t('SALES.MODULE_TOOLS.HEADER.TITLE')"
        :description="$t('SALES.MODULE_TOOLS.HEADER.DESCRIPTION')"
        feature-name="salesTools"
      />
    </template>
    <template #body>
      <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
        <div
          v-for="tool in tools"
          :key="tool.id"
          class="group flex flex-col p-5 bg-white dark:bg-n-solid-1 border border-n-weak rounded-xl hover:border-n-orange-weak hover:shadow-lg hover:shadow-n-orange/5 transition-all duration-300 ease-out"
          :class="{ 'opacity-70': !tool.enabled }"
        >
          <div class="flex items-start justify-between mb-4">
            <div
              class="flex h-12 w-12 items-center justify-center rounded-xl bg-white dark:bg-n-solid-2 border border-n-strong/20 shadow-sm overflow-hidden"
            >
              <img
                :src="`/dashboard/images/integrations/${tool.logo}.png`"
                class="h-7 w-7 object-contain block dark:hidden"
                :alt="tool.name"
                @error="onImageError"
              />
              <img
                :src="`/dashboard/images/integrations/${tool.logo}-dark.png`"
                class="h-7 w-7 object-contain hidden dark:block"
                :alt="tool.name"
                @error="onImageError"
              />
            </div>
            <div
              class="flex items-center justify-center h-6 w-6 rounded-full bg-n-slate-5 dark:bg-n-slate-6"
            >
              <span class="i-lucide-check text-white size-3.5" />
            </div>
          </div>

          <div class="flex flex-col flex-1">
            <div class="flex items-center justify-between gap-3 mb-2">
              <h3 class="text-base font-medium text-n-slate-12 leading-tight">
                {{ tool.name }}
              </h3>
              <div>
                <span
                  v-if="tool.enabled"
                  class="text-sm font-medium text-n-orange hover:text-n-orange-strong transition-colors cursor-pointer"
                >
                  {{ $t('SALES.MODULE_TOOLS.ACTIONS.CONFIGURE') }}
                </span>
                <span
                  v-else
                  class="text-sm font-medium text-n-slate-7 flex items-center gap-1"
                >
                  {{ $t('SALES.MODULE_TOOLS.ACTIONS.COMING_SOON') }}
                  <span class="i-lucide-lock size-3.5" />
                </span>
              </div>
            </div>
            <p class="text-n-slate-11 text-[13px] leading-relaxed line-clamp-3">
              {{ tool.description }}
            </p>
          </div>
        </div>
      </div>
    </template>
  </SalesLayout>
</template>
