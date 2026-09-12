<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { OnClickOutside } from '@vueuse/components';
import IntegrationItem from 'dashboard/routes/dashboard/settings/integrations/IntegrationItem.vue';

const { t } = useI18n();
const store = useStore();
const { currentAccount } = useAccount();

const ECOMMERCE_APP_IDS = [
  'shopify',
  'woocommerce',
  'calendly',
  'leadsquared',
  'kiotviet',
  'nhanhvn',
  'haravan',
  'sapo',
  'tiktok_shop',
];

const PLATFORM_LABELS = {
  kiotviet: 'KiotViet',
  sapo: 'Sapo',
  haravan: 'Haravan',
  shopify: 'Shopify',
  woocommerce: 'WooCommerce',
  nhanhvn: 'Nhanh.vn',
  tiktok_shop: 'TikTok Shop',
  calendly: 'Calendly',
  leadsquared: 'LeadSquared',
};

const PLATFORM_ICONS = {
  kiotviet: 'i-lucide-store',
  sapo: 'i-lucide-shopping-bag',
  haravan: 'i-lucide-shopping-cart',
  shopify: 'i-lucide-package',
  woocommerce: 'i-lucide-globe',
  nhanhvn: 'i-lucide-zap',
  tiktok_shop: 'i-lucide-music',
  calendly: 'i-lucide-calendar',
  leadsquared: 'i-lucide-users',
};

const SHOPIZ_LOGO_PATH = '/brand-assets/logo_thumbnail.svg';

const selectedIntegrationId = ref(null);
const showPlatformDropdown = ref(false);

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

const integrations = computed(() => {
  return ecomIntegrations.value
    .filter(app => app.hooks?.length > 0)
    .map(app => ({
      hookId: app.id,
      appId: app.id,
      label: PLATFORM_LABELS[app.id] || app.id,
      icon: PLATFORM_ICONS[app.id] || 'i-lucide-box',
    }));
});

const activePlatformLabel = computed(() => {
  if (selectedIntegrationId.value === 'shopiz') return 'Shopiz';
  const found = integrations.value.find(
    item => item.hookId === selectedIntegrationId.value
  );
  return found ? found.label : selectedIntegrationId.value;
});

const activePlatformLogo = computed(() => {
  if (selectedIntegrationId.value === 'shopiz') return SHOPIZ_LOGO_PATH;
  return `/dashboard/images/integrations/${selectedIntegrationId.value}.png`;
});

watch(
  currentAccount,
  () => {
    const config = currentAccount.value?.settings || {};
    selectedIntegrationId.value = config.active_ecommerce_platform || 'shopiz';
  },
  { deep: true, immediate: true }
);

onMounted(() => {
  store.dispatch('integrations/get');
});

const selectIntegration = async id => {
  selectedIntegrationId.value = id;
  try {
    await store.dispatch('accounts/update', {
      active_ecommerce_platform: id,
    });
    useAlert(
      t('INBOX_MGMT.ECOMMERCE.SAVE_SUCCESS') ||
        'Đã lưu phần mềm bán hàng mặc định'
    );
  } catch (error) {
    useAlert(error.message || t('INBOX_MGMT.ECOMMERCE.SAVE_ERROR'));
  }
};
</script>

<template>
  <div class="flex flex-col gap-6">
    <!-- Integration selector -->
    <div class="flex flex-col gap-4">
      <div class="flex flex-col gap-1">
        <h3 class="text-base font-semibold text-n-slate-12">
          {{ t('SALES.SETTINGS.TOOL.HEADER_TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11 leading-relaxed">
          {{ t('SALES.SETTINGS.TOOL.HEADER_DESC') }}
        </p>
      </div>

      <div
        v-if="integrations.length === 0"
        class="flex items-center gap-2 text-xs text-n-slate-10 py-2.5"
      >
        <i class="i-lucide-unplug text-sm" />
        <span>{{ t('INBOX_MGMT.ECOMMERCE.NO_INTEGRATIONS') }}</span>
      </div>

      <div v-else class="flex items-center gap-3">
        <span class="text-sm font-medium text-n-slate-12">{{
          t('SALES.SETTINGS.TOOL.DEFAULT_PLATFORM')
        }}</span>
        <OnClickOutside @trigger="showPlatformDropdown = false">
          <div class="relative">
            <button
              type="button"
              class="flex items-center gap-2 px-3 py-1.5 rounded-lg border-0 outline outline-1 -outline-offset-1 outline-n-weak hover:outline-n-slate-6 bg-n-surface-1 transition-all duration-200 min-w-[240px] justify-between cursor-pointer select-none text-left"
              @click="showPlatformDropdown = !showPlatformDropdown"
            >
              <div class="flex items-center gap-2.5 min-w-0">
                <div
                  class="w-6 h-6 rounded flex items-center justify-center flex-shrink-0 bg-white dark:bg-n-solid-2 border border-n-weak"
                >
                  <img
                    :src="activePlatformLogo"
                    class="w-4 h-4 object-contain"
                    alt="logo"
                  />
                </div>
                <span class="text-sm font-medium text-n-slate-12 truncate">
                  {{ activePlatformLabel }}
                </span>
              </div>
              <i
                class="i-lucide-chevron-down text-n-slate-10 text-sm flex-shrink-0"
              />
            </button>

            <div
              v-if="showPlatformDropdown"
              class="py-2 bg-n-alpha-3 backdrop-blur-[100px] outline outline-n-container outline-1 z-50 absolute ltr:right-0 rtl:left-0 top-12 min-w-[240px] rounded-xl shadow-lg flex flex-col gap-1 mt-1"
            >
              <!-- Shopiz Option -->
              <button
                type="button"
                class="flex items-center justify-between px-3 py-2 mx-1 rounded-lg transition-all hover:bg-n-alpha-2 cursor-pointer text-left w-[calc(100%-8px)]"
                :class="
                  selectedIntegrationId === 'shopiz'
                    ? 'bg-n-brand/10 hover:bg-n-brand/15'
                    : ''
                "
                @click="
                  () => {
                    selectIntegration('shopiz');
                    showPlatformDropdown = false;
                  }
                "
              >
                <div class="flex items-center gap-2.5 min-w-0">
                  <div
                    class="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0 bg-n-alpha-2 border border-n-weak"
                  >
                    <img
                      :src="SHOPIZ_LOGO_PATH"
                      class="w-5 h-5 object-contain"
                      alt="Shopiz"
                    />
                  </div>
                  <span class="text-sm font-medium text-n-slate-12 truncate">{{
                    t('SALES.SETTINGS.TOOL.SHOPIZ')
                  }}</span>
                </div>
                <i
                  v-if="selectedIntegrationId === 'shopiz'"
                  class="i-lucide-check text-n-brand text-sm flex-shrink-0"
                />
              </button>

              <!-- Connected Integration Options -->
              <button
                v-for="integration in integrations"
                :key="integration.hookId"
                type="button"
                class="flex items-center justify-between px-3 py-2 mx-1 rounded-lg transition-all hover:bg-n-alpha-2 cursor-pointer text-left w-[calc(100%-8px)]"
                :class="
                  selectedIntegrationId === integration.hookId
                    ? 'bg-n-brand/10 hover:bg-n-brand/15'
                    : ''
                "
                @click="
                  () => {
                    selectIntegration(integration.hookId);
                    showPlatformDropdown = false;
                  }
                "
              >
                <div class="flex items-center gap-2.5 min-w-0">
                  <div
                    class="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0 bg-n-alpha-2 border border-n-weak"
                  >
                    <img
                      :src="`/dashboard/images/integrations/${integration.appId}.png`"
                      class="w-5 h-5 object-contain"
                      alt="logo"
                    />
                  </div>
                  <span class="text-sm font-medium text-n-slate-12 truncate">{{
                    integration.label
                  }}</span>
                </div>
                <i
                  v-if="selectedIntegrationId === integration.hookId"
                  class="i-lucide-check text-n-brand text-sm flex-shrink-0"
                />
              </button>
            </div>
          </div>
        </OnClickOutside>
      </div>
    </div>

    <div class="h-px bg-n-weak w-full" />

    <!-- Danh sách các phần mềm bán hàng -->
    <div class="flex flex-col gap-4">
      <h3 class="text-base font-semibold text-n-slate-12">
        {{ t('SALES.SETTINGS.TOOL.LIST_TITLE') }}
      </h3>
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        <IntegrationItem
          v-for="app in ecomIntegrations"
          :id="app.id"
          :key="app.id"
          :name="app.name"
          :description="app.description"
          :status="app.status"
          :enabled="app.hooks && app.hooks.length > 0"
          path-prefix="sales/settings/tool"
        />
      </div>
    </div>
  </div>
</template>
