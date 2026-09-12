<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { OnClickOutside } from '@vueuse/components';
import IntegrationItem from 'dashboard/routes/dashboard/settings/integrations/IntegrationItem.vue';

const { t } = useI18n();
const store = useStore();
const { currentAccount } = useAccount();

const isLoading = computed(() => {
  return store.getters['accounts/getUIFlags'].isFetchingItem;
});

const defaultProvider = ref('');
const showPlatformDropdown = ref(false);

const loadConfig = () => {
  const config = currentAccount.value?.settings?.sales_payment_config || {};
  defaultProvider.value = config.default_provider || '';
};

watch(
  currentAccount,
  () => {
    if (currentAccount.value) {
      loadConfig();
    }
  },
  { deep: true, immediate: true }
);

const handleDefaultProviderChange = async provider => {
  if (defaultProvider.value === provider) return;

  defaultProvider.value = provider;
  try {
    const existingConfig =
      currentAccount.value?.settings?.sales_payment_config || {};
    const payload = {
      sales_payment_config: {
        ...existingConfig,
        default_provider: provider,
      },
    };
    await store.dispatch('accounts/update', payload);
    useAlert(
      t('GENERAL_SETTINGS.UPDATE.SUCCESS') || 'Updated default provider'
    );
  } catch (error) {
    useAlert(
      error.message ||
        t('GENERAL_SETTINGS.UPDATE.ERROR') ||
        'Error updating settings'
    );
  }
  showPlatformDropdown.value = false;
};

// Define integration items for payments
const paymentIntegrations = computed(() => {
  const config = currentAccount.value?.settings?.sales_payment_config || {};

  return [
    {
      id: 'sepay',
      name: 'SePay',
      description: t('SALES.SETTINGS.PAYMENT.SEPAY_DESC'),
      status: 'published',
      enabled: !!config.sepay?.active,
    },
    {
      id: 'payos',
      name: 'PayOS',
      description: t('SALES.SETTINGS.PAYMENT.PAYOS_DESC'),
      status: 'published',
      enabled: !!config.payos?.active,
    },
    {
      id: 'tingee',
      name: 'Tingee',
      description: t('SALES.SETTINGS.PAYMENT.TINGEE_DESC'),
      status: 'published',
      enabled: !!config.tingee?.active,
    },
  ];
});

const activePlatformLabel = computed(() => {
  const active = paymentIntegrations.value.find(
    p => p.id === defaultProvider.value
  );
  return active
    ? active.name
    : t('INBOX_MGMT.ECOMMERCE.SELECT_PLATFORM') ||
        t('SALES.SETTINGS.PAYMENT.SELECT_PLATFORM');
});

const activePlatformLogo = computed(() => {
  return `/dashboard/images/integrations/${defaultProvider.value || 'default'}.png`;
});
</script>

<template>
  <div :class="{ 'w-full h-full overflow-auto': !embedded }">
    <!-- Skeleton Loading -->
    <div
      v-if="isLoading"
      :class="
        embedded ? 'animate-pulse' : 'max-w-5xl mx-auto px-6 py-6 animate-pulse'
      "
    >
      <div class="h-6 w-48 rounded bg-n-slate-3 mb-6" />
      <div class="h-40 w-full rounded-xl bg-n-slate-3 mb-6" />
      <div class="h-40 w-full rounded-xl bg-n-slate-3 mb-6" />
      <div class="h-40 w-full rounded-xl bg-n-slate-3" />
    </div>

    <div
      v-else
      :class="
        embedded
          ? 'flex flex-col gap-6'
          : 'max-w-5xl mx-auto px-6 py-6 flex flex-col gap-6'
      "
    >
      <div class="flex flex-col gap-1">
        <h3 class="text-base font-semibold text-n-slate-12">
          {{ t('SALES.SETTINGS.PAYMENT.HEADER_TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11 leading-relaxed">
          {{ t('SALES.SETTINGS.PAYMENT.HEADER_DESC') }}
        </p>
      </div>

      <div class="flex flex-col gap-4">
        <div class="flex items-center gap-3">
          <span class="text-sm font-medium text-n-slate-12">{{
            t('SALES.SETTINGS.PAYMENT.DEFAULT_PLATFORM')
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
                    v-if="defaultProvider"
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
                <!-- Clear Option -->
                <button
                  type="button"
                  class="flex items-center justify-between px-3 py-2 mx-1 rounded-lg transition-all hover:bg-n-alpha-2 cursor-pointer text-left w-[calc(100%-8px)]"
                  :class="
                    !defaultProvider ? 'bg-n-brand/10 hover:bg-n-brand/15' : ''
                  "
                  @click="handleDefaultProviderChange('')"
                >
                  <div class="flex items-center gap-3 min-w-0">
                    <span class="text-sm font-medium text-n-slate-12 truncate">
                      {{
                        t('INBOX_MGMT.ECOMMERCE.SELECT_PLATFORM') || 'Không có'
                      }}
                    </span>
                  </div>
                  <i
                    v-if="!defaultProvider"
                    class="i-lucide-check text-n-brand text-sm flex-shrink-0"
                  />
                </button>
                <div class="h-px bg-n-weak w-full my-1" />
                <!-- Options -->
                <button
                  v-for="platform in paymentIntegrations.filter(
                    p => p.status !== 'coming_soon'
                  )"
                  :key="platform.id"
                  type="button"
                  class="flex items-center justify-between px-3 py-2 mx-1 rounded-lg transition-all hover:bg-n-alpha-2 cursor-pointer text-left w-[calc(100%-8px)]"
                  :class="
                    defaultProvider === platform.id
                      ? 'bg-n-brand/10 hover:bg-n-brand/15'
                      : ''
                  "
                  @click="handleDefaultProviderChange(platform.id)"
                >
                  <div class="flex items-center gap-3 min-w-0">
                    <div
                      class="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0 bg-n-alpha-2 border border-n-weak"
                    >
                      <img
                        :src="`/dashboard/images/integrations/${platform.id}.png`"
                        class="w-5 h-5 object-contain"
                        alt="logo"
                      />
                    </div>
                    <span class="text-sm font-medium text-n-slate-12 truncate">
                      {{ platform.name }}
                    </span>
                  </div>
                  <i
                    v-if="defaultProvider === platform.id"
                    class="i-lucide-check text-n-brand text-sm flex-shrink-0"
                  />
                </button>
              </div>
            </div>
          </OnClickOutside>
        </div>
      </div>

      <div class="h-px bg-n-weak w-full" />

      <!-- Danh sách kênh thanh toán -->
      <div class="flex flex-col gap-4">
        <h3 class="text-base font-semibold text-n-slate-12">
          {{ t('SALES.SETTINGS.PAYMENT.LIST_TITLE') }}
        </h3>
        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
          <IntegrationItem
            v-for="app in paymentIntegrations"
            :id="app.id"
            :key="app.id"
            :name="app.name"
            :description="app.description"
            :status="app.status"
            :enabled="app.enabled"
            path-prefix="sales/settings"
          />
        </div>
      </div>
    </div>
  </div>
</template>
