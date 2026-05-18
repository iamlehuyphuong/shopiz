<script setup>
import { ref, computed, onMounted, reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import IntegrationItem from 'dashboard/routes/dashboard/settings/integrations/IntegrationItem.vue';
import { OnClickOutside } from '@vueuse/components';

const { t } = useI18n();
const store = useStore();
const { currentAccount } = useAccount();

const ECOMMERCE_APP_IDS = [
  'shopify',
  'woocommerce',
  'calendly',
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
};

const TEMPLATE_VARIABLES = [
  {
    key: '%{customer_name}',
    labelKey: 'INBOX_MGMT.ECOMMERCE.VAR_CUSTOMER_NAME',
  },
  { key: '%{inbox_name}', labelKey: 'INBOX_MGMT.ECOMMERCE.VAR_INBOX_NAME' },
  { key: '%{order_id}', labelKey: 'INBOX_MGMT.ECOMMERCE.VAR_ORDER_ID' },
  { key: '%{status_label}', labelKey: 'INBOX_MGMT.ECOMMERCE.VAR_STATUS_LABEL' },
  { key: '%{total_amount}', labelKey: 'INBOX_MGMT.ECOMMERCE.VAR_TOTAL_AMOUNT' },
];

const SHOPIZ_LOGO_PATH = '/brand-assets/logo_thumbnail.svg';

const selectedIntegrationId = ref(null);
const isSaving = ref(false);
const showPlatformDropdown = ref(false);

const customizeTemplates = ref(false);
const salesOrderNotificationTemplates = reactive({
  draft: '',
  confirmed: '',
  processing: '',
  shipped: '',
  delivered: '',
  cancelled: '',
});
const allowAiCreateOrder = ref(false);

// Track which textarea is currently focused
const activeTextareaRef = ref(null);

const ecomIntegrations = computed(() => {
  const allIntegrations =
    store.getters['integrations/getAppIntegrations'] || [];
  const filtered = allIntegrations.filter(app =>
    ECOMMERCE_APP_IDS.includes(app.id)
  );
  return filtered.sort((a, b) => {
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

const hasAnyTemplate = computed(() => {
  return Object.values(salesOrderNotificationTemplates).some(
    v => v && v.trim() !== ''
  );
});

const loadSalesSettings = () => {
  const config = currentAccount.value?.settings || {};
  const templates = config.order_notification_templates || {};

  Object.keys(salesOrderNotificationTemplates).forEach(key => {
    salesOrderNotificationTemplates[key] = templates[key] || '';
  });

  allowAiCreateOrder.value = config.ai_allow_create_order ?? false;

  // Auto-enable customize toggle if any template already has content
  if (hasAnyTemplate.value) {
    customizeTemplates.value = true;
  }
};

onMounted(() => {
  store.dispatch('integrations/get');
});

watch(
  currentAccount,
  () => {
    const config = currentAccount.value?.settings || {};
    selectedIntegrationId.value = config.active_ecommerce_platform || 'shopiz';
    loadSalesSettings();
  },
  { deep: true, immediate: true }
);

const handleSave = async () => {
  isSaving.value = true;
  try {
    const platform = selectedIntegrationId.value;

    await store.dispatch('accounts/update', {
      active_ecommerce_platform: platform,
      ai_allow_create_order: allowAiCreateOrder.value,
      order_notification_templates: salesOrderNotificationTemplates,
    });
    useAlert(t('INBOX_MGMT.ECOMMERCE.SAVE_SUCCESS'));
  } catch (error) {
    useAlert(error.message || t('INBOX_MGMT.ECOMMERCE.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const selectIntegration = async id => {
  selectedIntegrationId.value = id;
  await handleSave();
};

const fillDefaultTemplates = () => {
  salesOrderNotificationTemplates.draft = t(
    'INBOX_MGMT.ECOMMERCE.TEMPLATES_DEFAULT_DRAFT'
  );
  salesOrderNotificationTemplates.confirmed = t(
    'INBOX_MGMT.ECOMMERCE.TEMPLATES_DEFAULT_CONFIRMED'
  );
  salesOrderNotificationTemplates.processing = t(
    'INBOX_MGMT.ECOMMERCE.TEMPLATES_DEFAULT_PROCESSING'
  );
  salesOrderNotificationTemplates.shipped = t(
    'INBOX_MGMT.ECOMMERCE.TEMPLATES_DEFAULT_SHIPPED'
  );
  salesOrderNotificationTemplates.delivered = t(
    'INBOX_MGMT.ECOMMERCE.TEMPLATES_DEFAULT_DELIVERED'
  );
  salesOrderNotificationTemplates.cancelled = t(
    'INBOX_MGMT.ECOMMERCE.TEMPLATES_DEFAULT_CANCELLED'
  );
};

const onTextareaFocus = event => {
  activeTextareaRef.value = event.target;
};

const insertVariable = variableKey => {
  const textarea = activeTextareaRef.value;
  if (!textarea) return;

  const start = textarea.selectionStart;
  const end = textarea.selectionEnd;
  const currentValue = textarea.value;

  const newValue =
    currentValue.substring(0, start) +
    variableKey +
    currentValue.substring(end);

  // Find which model key this textarea belongs to via its name attribute
  const name = textarea.closest('[data-template-key]')?.dataset.templateKey;
  if (name && name in salesOrderNotificationTemplates) {
    salesOrderNotificationTemplates[name] = newValue;
  }

  // Restore cursor position after the inserted text
  const newCursorPos = start + variableKey.length;
  requestAnimationFrame(() => {
    textarea.focus();
    textarea.setSelectionRange(newCursorPos, newCursorPos);
  });
};
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <!-- eslint-disable @intlify/vue-i18n/no-raw-text -->
  <div class="w-full h-full overflow-auto">
    <div class="max-w-5xl mx-auto px-6 py-6">
      <div class="flex flex-col gap-6">
        <!-- Header -->
        <div class="flex flex-col gap-1">
          <h3 class="text-lg font-semibold text-n-slate-12">
            {{ t('INBOX_MGMT.ECOMMERCE.TITLE') }}
          </h3>
          <p class="text-sm text-n-slate-11">
            {{ t('INBOX_MGMT.ECOMMERCE.DESCRIPTION') }}
          </p>
        </div>

        <!-- Integration selector -->
        <div class="flex items-start justify-between gap-4">
          <div class="flex flex-col gap-1">
            <h3 class="text-base font-semibold text-n-slate-12">
              {{ t('INBOX_MGMT.ECOMMERCE.INTEGRATIONS_TITLE') }}
            </h3>
            <p class="text-sm text-n-slate-11 leading-relaxed">
              {{ t('INBOX_MGMT.ECOMMERCE.INTEGRATIONS_DESCRIPTION') }}
            </p>
          </div>

          <div
            v-if="integrations.length === 0"
            class="flex items-center gap-2 text-xs text-n-slate-10 py-2.5"
          >
            <i class="i-lucide-unplug text-sm" />
            <span>{{ t('INBOX_MGMT.ECOMMERCE.NO_INTEGRATIONS') }}</span>
          </div>

          <OnClickOutside v-else @trigger="showPlatformDropdown = false">
            <div class="relative">
              <button
                type="button"
                class="flex items-center gap-3 px-4 py-2.5 rounded-xl border border-n-weak hover:border-n-brand bg-n-solid-1 hover:bg-n-solid-2 active:scale-[0.98] transition-all min-w-[240px] justify-between cursor-pointer select-none text-left"
                @click="showPlatformDropdown = !showPlatformDropdown"
              >
                <div class="flex items-center gap-2.5 min-w-0">
                  <div
                    class="w-7 h-7 rounded-lg flex items-center justify-center flex-shrink-0 bg-n-alpha-2 border border-n-weak"
                  >
                    <img
                      :src="activePlatformLogo"
                      class="w-5 h-5 object-contain"
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
                    <span class="text-sm font-medium text-n-slate-12 truncate">
                      Shopiz
                    </span>
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
                    <span class="text-sm font-medium text-n-slate-12 truncate">
                      {{ integration.label }}
                    </span>
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

        <!-- Sales settings: AI Order + Templates -->
        <div class="flex flex-col gap-6">
          <!-- Trợ lý AI tạo đơn hàng -->
          <div class="flex items-start justify-between gap-4">
            <div class="flex flex-col gap-1">
              <h3 class="text-base font-semibold text-n-slate-12">
                {{ t('INBOX_MGMT.ECOMMERCE.AI_ORDER_TITLE') }}
              </h3>
              <p class="text-sm text-n-slate-11 leading-relaxed">
                {{ t('INBOX_MGMT.ECOMMERCE.AI_ORDER_DESCRIPTION') }}
              </p>
            </div>
            <Switch
              v-model="allowAiCreateOrder"
              class="flex-shrink-0 mt-0.5"
              @update:model-value="handleSave"
            />
          </div>

          <!-- Mẫu thông báo đơn hàng -->
          <div class="flex flex-col gap-4">
            <div class="flex items-start justify-between gap-4">
              <div class="flex flex-col gap-1">
                <h3 class="text-base font-semibold text-n-slate-12">
                  {{ t('INBOX_MGMT.ECOMMERCE.TEMPLATES_TITLE') }}
                </h3>
                <p class="text-sm text-n-slate-11 leading-relaxed">
                  {{ t('INBOX_MGMT.ECOMMERCE.TEMPLATES_DESCRIPTION') }}
                </p>
              </div>
              <Switch
                v-model="customizeTemplates"
                class="flex-shrink-0 mt-0.5"
              />
            </div>

            <template v-if="customizeTemplates">
              <!-- Variable tags helper -->
              <div class="flex flex-col gap-2">
                <p class="text-sm font-medium text-n-slate-11">
                  {{ t('INBOX_MGMT.ECOMMERCE.VARIABLE_TAGS_LABEL') }}
                </p>
                <div class="flex flex-wrap gap-1.5">
                  <button
                    v-for="variable in TEMPLATE_VARIABLES"
                    :key="variable.key"
                    type="button"
                    class="inline-flex items-center gap-1 px-2 py-1 rounded-md bg-n-alpha-2 border border-n-weak text-xs font-mono text-n-slate-11 hover:bg-n-alpha-3 hover:text-n-slate-12 hover:border-n-slate-6 transition-all cursor-pointer select-none"
                    :title="
                      t('INBOX_MGMT.ECOMMERCE.VARIABLE_TAG_TOOLTIP', {
                        variable: variable.key,
                      })
                    "
                    @click="insertVariable(variable.key)"
                  >
                    <i class="i-lucide-code text-[10px] opacity-60" />
                    {{ t(variable.labelKey) }}
                  </button>
                </div>
              </div>

              <div class="flex justify-end">
                <NextButton
                  sm
                  outline
                  slate
                  icon="i-lucide-wand-2"
                  class="flex-shrink-0"
                  @click="fillDefaultTemplates"
                >
                  {{ t('INBOX_MGMT.ECOMMERCE.FILL_DEFAULT_TEMPLATES') }}
                </NextButton>
              </div>

              <div class="grid gap-4">
                <WithLabel
                  name="template-draft"
                  :label="$t('SALES.MODULE_ORDERS.STATUS.DRAFT')"
                >
                  <div data-template-key="draft" class="w-full">
                    <textarea
                      v-model="salesOrderNotificationTemplates.draft"
                      class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                      :placeholder="
                        t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_DRAFT')
                      "
                      @focus="onTextareaFocus"
                    />
                  </div>
                </WithLabel>
                <WithLabel
                  name="template-confirmed"
                  :label="$t('SALES.MODULE_ORDERS.STATUS.CONFIRMED')"
                >
                  <div data-template-key="confirmed" class="w-full">
                    <textarea
                      v-model="salesOrderNotificationTemplates.confirmed"
                      class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                      :placeholder="
                        t(
                          'INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_CONFIRMED'
                        )
                      "
                      @focus="onTextareaFocus"
                    />
                  </div>
                </WithLabel>
                <WithLabel
                  name="template-processing"
                  :label="$t('SALES.MODULE_ORDERS.STATUS.PROCESSING')"
                >
                  <div data-template-key="processing" class="w-full">
                    <textarea
                      v-model="salesOrderNotificationTemplates.processing"
                      class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                      :placeholder="
                        t(
                          'INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_PROCESSING'
                        )
                      "
                      @focus="onTextareaFocus"
                    />
                  </div>
                </WithLabel>
                <WithLabel
                  name="template-shipped"
                  :label="$t('SALES.MODULE_ORDERS.STATUS.SHIPPED')"
                >
                  <div data-template-key="shipped" class="w-full">
                    <textarea
                      v-model="salesOrderNotificationTemplates.shipped"
                      class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                      :placeholder="
                        t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_SHIPPED')
                      "
                      @focus="onTextareaFocus"
                    />
                  </div>
                </WithLabel>
                <WithLabel
                  name="template-delivered"
                  :label="$t('SALES.MODULE_ORDERS.STATUS.DELIVERED')"
                >
                  <div data-template-key="delivered" class="w-full">
                    <textarea
                      v-model="salesOrderNotificationTemplates.delivered"
                      class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                      :placeholder="
                        t(
                          'INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_DELIVERED'
                        )
                      "
                      @focus="onTextareaFocus"
                    />
                  </div>
                </WithLabel>
                <WithLabel
                  name="template-cancelled"
                  :label="$t('SALES.MODULE_ORDERS.STATUS.CANCELLED')"
                >
                  <div data-template-key="cancelled" class="w-full">
                    <textarea
                      v-model="salesOrderNotificationTemplates.cancelled"
                      class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                      :placeholder="
                        t(
                          'INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_CANCELLED'
                        )
                      "
                      @focus="onTextareaFocus"
                    />
                  </div>
                </WithLabel>
              </div>
            </template>
          </div>
        </div>

        <!-- Save button (unified: integration + sales settings) -->
        <div class="flex justify-end pt-2">
          <NextButton
            :label="t('INBOX_MGMT.ECOMMERCE.SAVE')"
            sm
            :is-loading="isSaving"
            @click="handleSave"
          />
        </div>

        <!-- Ecom Integrations -->
        <div class="flex flex-col gap-4">
          <div class="flex flex-col gap-1">
            <h3 class="text-lg font-semibold text-n-slate-12">
              {{ t('INBOX_MGMT.ECOMMERCE.INTEGRATIONS_TITLE') }}
            </h3>
            <p class="text-sm text-n-slate-11">
              {{ t('INBOX_MGMT.ECOMMERCE.INTEGRATIONS_DESCRIPTION') }}
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
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
