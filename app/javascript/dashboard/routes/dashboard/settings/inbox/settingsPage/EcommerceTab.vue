<script setup>
import { ref, computed, onMounted, reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import OrderTemplateMapping from '../components/OrderTemplateMapping.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['update']);

const ECOMMERCE_APP_IDS = [
  'kiotviet',
  'sapo',
  'haravan',
  'shopify',
  'woocommerce',
  'nhanhvn',
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
};

const PLATFORM_ICONS = {
  kiotviet: 'i-lucide-store',
  sapo: 'i-lucide-shopping-bag',
  haravan: 'i-lucide-shopping-cart',
  shopify: 'i-lucide-package',
  woocommerce: 'i-lucide-globe',
  nhanhvn: 'i-lucide-zap',
  tiktok_shop: 'i-lucide-music',
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

const { t } = useI18n();
const store = useStore();

const selectedIntegrationId = ref(null);
const isSaving = ref(false);

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

const integrations = computed(() => {
  const allIntegrations = store.getters['integrations/getAppIntegrations'];
  return allIntegrations
    .filter(app => ECOMMERCE_APP_IDS.includes(app.id) && app.hooks?.length > 0)
    .map(app => ({
      hookId: app.hooks[0].id,
      appId: app.id,
      label: PLATFORM_LABELS[app.id] || app.id,
      icon: PLATFORM_ICONS[app.id] || 'i-lucide-box',
    }));
});

const isMarketplaceLocked = computed(
  () => props.inbox.marketplace_locked || false
);

const TEMPLATE_MAPPING_CHANNELS = ['Channel::ZaloOa', 'Channel::Whatsapp'];

const supportsOrderTemplateMapping = computed(() =>
  TEMPLATE_MAPPING_CHANNELS.includes(props.inbox.channel_type)
);

const currentIntegration = computed(() =>
  integrations.value.find(i => i.hookId === selectedIntegrationId.value)
);

const hasAnyTemplate = computed(() => {
  return Object.values(salesOrderNotificationTemplates).some(
    v => v && v.trim() !== ''
  );
});

const loadSalesSettings = () => {
  const config = props.inbox.sales_config || {};
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
  const config = props.inbox.sales_config || {};
  if (config.platform === 'shopiz') {
    selectedIntegrationId.value = 'shopiz';
  } else {
    selectedIntegrationId.value = props.inbox.ecommerce_integration?.id || null;
  }
  loadSalesSettings();
});

const handleSave = async () => {
  if (isMarketplaceLocked.value) return;

  isSaving.value = true;
  try {
    const payloadIntegrationId =
      selectedIntegrationId.value === 'shopiz'
        ? null
        : selectedIntegrationId.value;
    const platform = selectedIntegrationId.value === 'shopiz' ? 'shopiz' : null;

    await store.dispatch('inboxes/updateInbox', {
      id: props.inbox.id,
      formData: false,
      ecommerce_integration_id: payloadIntegrationId,
      sales_config: {
        platform: platform,
        ai_allow_create_order: allowAiCreateOrder.value,
        order_notification_templates: salesOrderNotificationTemplates,
      },
    });
    useAlert(t('INBOX_MGMT.ECOMMERCE.SAVE_SUCCESS'));
  } catch (error) {
    useAlert(error.message || t('INBOX_MGMT.ECOMMERCE.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
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
  <div class="max-w-4xl mx-6">
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

      <!-- Marketplace locked banner -->
      <div
        v-if="isMarketplaceLocked"
        class="flex items-center gap-3 rounded-xl border border-n-teal-6 bg-n-teal-2 px-4 py-3"
      >
        <i class="i-lucide-lock text-n-teal-11 text-base" />
        <div class="flex-1">
          <p class="text-sm font-medium text-n-teal-12">
            {{
              t('INBOX_MGMT.ECOMMERCE.AUTO_LINKED', {
                platform:
                  PLATFORM_LABELS[inbox.ecommerce_integration?.app_id] ||
                  'Marketplace',
              })
            }}
          </p>
          <p class="text-xs text-n-teal-11 mt-0.5">
            {{ t('INBOX_MGMT.ECOMMERCE.MARKETPLACE_NOTE') }}
          </p>
        </div>
        <span
          v-if="inbox.ecommerce_integration"
          class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-n-teal-4 text-sm font-medium text-n-teal-12"
        >
          <i
            :class="
              PLATFORM_ICONS[inbox.ecommerce_integration.app_id] ||
              'i-lucide-box'
            "
            class="text-sm"
          />
          {{
            PLATFORM_LABELS[inbox.ecommerce_integration.app_id] ||
            inbox.ecommerce_integration.app_id
          }}
        </span>
      </div>

      <!-- Integration selector -->
      <div v-else class="flex flex-col gap-4">
        <div class="flex flex-col gap-1.5">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('INBOX_MGMT.ECOMMERCE.SELECT_PLATFORM') }}
          </label>

          <div
            v-if="integrations.length === 0"
            class="flex flex-col items-center py-8 px-4"
          >
            <div
              class="w-12 h-12 rounded-xl bg-n-solid-3 flex items-center justify-center mb-3"
            >
              <i class="i-lucide-unplug text-xl text-n-slate-10" />
            </div>
            <p class="text-sm text-n-slate-11 text-center">
              {{ t('INBOX_MGMT.ECOMMERCE.NO_INTEGRATIONS') }}
            </p>
          </div>

          <div v-else class="flex flex-col gap-2">
            <!-- None option -->
            <button
              class="flex items-center gap-3 px-4 py-3 rounded-xl border transition-all"
              :class="
                selectedIntegrationId === null
                  ? 'border-n-brand bg-n-brand/5 ring-1 ring-n-brand/30'
                  : 'border-n-weak bg-n-solid-1 hover:bg-n-alpha-1'
              "
              @click="selectedIntegrationId = null"
            >
              <div
                class="w-8 h-8 rounded-lg flex items-center justify-center"
                :class="
                  selectedIntegrationId === null
                    ? 'bg-n-brand/10'
                    : 'bg-n-solid-3'
                "
              >
                <i
                  class="i-lucide-x text-sm"
                  :class="
                    selectedIntegrationId === null
                      ? 'text-n-brand'
                      : 'text-n-slate-10'
                  "
                />
              </div>
              <span
                class="text-sm"
                :class="
                  selectedIntegrationId === null
                    ? 'text-n-slate-12 font-medium'
                    : 'text-n-slate-11'
                "
              >
                {{ t('INBOX_MGMT.ECOMMERCE.NONE') }}
              </span>
            </button>

            <!-- Shopiz (Native) option -->
            <button
              class="flex items-center gap-3 px-4 py-3 rounded-xl border transition-all"
              :class="
                selectedIntegrationId === 'shopiz'
                  ? 'border-n-brand bg-n-brand/5 ring-1 ring-n-brand/30'
                  : 'border-n-weak bg-n-solid-1 hover:bg-n-alpha-1'
              "
              @click="selectedIntegrationId = 'shopiz'"
            >
              <div
                class="w-8 h-8 rounded-lg flex items-center justify-center"
                :class="
                  selectedIntegrationId === 'shopiz'
                    ? 'bg-n-brand/10'
                    : 'bg-n-solid-3'
                "
              >
                <i
                  class="i-lucide-shopping-bag text-sm"
                  :class="
                    selectedIntegrationId === 'shopiz'
                      ? 'text-n-brand'
                      : 'text-n-slate-10'
                  "
                />
              </div>
              <span
                class="text-sm"
                :class="
                  selectedIntegrationId === 'shopiz'
                    ? 'text-n-slate-12 font-medium'
                    : 'text-n-slate-11'
                "
              >
                Shopiz
              </span>
              <i
                v-if="selectedIntegrationId === 'shopiz'"
                class="i-lucide-check text-n-brand text-sm ml-auto"
              />
            </button>

            <!-- Platform options -->
            <button
              v-for="integration in integrations"
              :key="integration.hookId"
              class="flex items-center gap-3 px-4 py-3 rounded-xl border transition-all"
              :class="
                selectedIntegrationId === integration.hookId
                  ? 'border-n-brand bg-n-brand/5 ring-1 ring-n-brand/30'
                  : 'border-n-weak bg-n-solid-1 hover:bg-n-alpha-1'
              "
              @click="selectedIntegrationId = integration.hookId"
            >
              <div
                class="w-8 h-8 rounded-lg flex items-center justify-center"
                :class="
                  selectedIntegrationId === integration.hookId
                    ? 'bg-n-brand/10'
                    : 'bg-n-solid-3'
                "
              >
                <i :class="integration.icon" class="text-sm" />
              </div>
              <span
                class="text-sm"
                :class="
                  selectedIntegrationId === integration.hookId
                    ? 'text-n-slate-12 font-medium'
                    : 'text-n-slate-11'
                "
              >
                {{ integration.label }}
              </span>
              <i
                v-if="selectedIntegrationId === integration.hookId"
                class="i-lucide-check text-n-brand text-sm ml-auto"
              />
            </button>
          </div>
        </div>
      </div>

      <div class="w-full h-[1px] bg-n-weak my-4" />

      <!-- Sales settings: AI Order + Templates -->
      <div class="flex flex-col gap-6">
        <!-- Trợ lý AI tạo đơn hàng -->
        <div class="flex flex-col gap-4">
          <div class="flex flex-col gap-1">
            <h3 class="text-lg font-semibold text-n-slate-12">
              {{ t('INBOX_MGMT.ECOMMERCE.AI_ORDER_TITLE') }}
            </h3>
            <p class="text-sm text-n-slate-11">
              {{ t('INBOX_MGMT.ECOMMERCE.AI_ORDER_DESCRIPTION') }}
            </p>
          </div>
          <div class="flex items-center gap-3">
            <Switch v-model="allowAiCreateOrder" />
            <span class="text-sm text-n-slate-12">{{
              t('INBOX_MGMT.ECOMMERCE.AI_ORDER_TOGGLE')
            }}</span>
          </div>
        </div>

        <div class="w-full h-[1px] bg-n-weak my-2" />

        <!-- Mẫu thông báo đơn hàng -->
        <div class="flex flex-col gap-4">
          <div class="flex flex-row items-start justify-between gap-4">
            <div class="flex flex-col gap-1">
              <h3 class="text-lg font-semibold text-n-slate-12">
                {{ t('INBOX_MGMT.ECOMMERCE.TEMPLATES_TITLE') }}
              </h3>
              <p class="text-sm text-n-slate-11">
                {{ t('INBOX_MGMT.ECOMMERCE.TEMPLATES_DESCRIPTION') }}
              </p>
            </div>
          </div>

          <!-- Toggle customize templates -->
          <div class="flex items-center gap-3">
            <Switch v-model="customizeTemplates" />
            <span class="text-sm text-n-slate-12">
              {{ t('INBOX_MGMT.ECOMMERCE.CUSTOMIZE_TEMPLATES_TOGGLE') }}
            </span>
          </div>

          <template v-if="customizeTemplates">
            <!-- Variable tags helper -->
            <div class="flex flex-col gap-2">
              <p class="text-xs font-medium text-n-slate-11">
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
                      t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_CONFIRMED')
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
                      t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_PROCESSING')
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
                      t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_DELIVERED')
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
                      t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_CANCELLED')
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
      <div class="flex justify-end pt-2 pb-6">
        <NextButton
          :label="t('INBOX_MGMT.ECOMMERCE.SAVE')"
          sm
          :is-loading="isSaving"
          @click="handleSave"
        />
      </div>

      <!-- Order Template Mapping (ZaloOA / WhatsApp) -->
      <template v-if="supportsOrderTemplateMapping">
        <div class="w-full h-[1px] bg-n-weak my-4" />
        <OrderTemplateMapping :inbox="inbox" />
      </template>
    </div>
  </div>
</template>
