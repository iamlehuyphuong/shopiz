<script setup>
import { ref, computed, onMounted, reactive } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import NextButton from 'dashboard/components-next/button/Button.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

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

const { t } = useI18n();
const store = useStore();
const { accountId } = useAccount();

const selectedIntegrationId = ref(null);
const isSaving = ref(false);

const isUpdatingSalesSettings = ref(false);
const salesOrderNotificationTemplates = reactive({
  draft: '',
  confirmed: '',
  processing: '',
  shipped: '',
  delivered: '',
  cancelled: '',
});
const allowAiCreateOrder = ref(false);

const account = computed(
  () => store.getters['accounts/getAccount'](accountId.value) || {}
);

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

const currentIntegration = computed(() =>
  integrations.value.find(i => i.hookId === selectedIntegrationId.value)
);

const loadSalesSettings = () => {
  const settings = account.value.settings || {};

  if (settings.sales_order_notification_templates) {
    Object.keys(salesOrderNotificationTemplates).forEach(key => {
      salesOrderNotificationTemplates[key] =
        settings.sales_order_notification_templates[key] || '';
    });
  }

  allowAiCreateOrder.value = settings.sales_ai_allow_create_order ?? false;
};

onMounted(() => {
  store.dispatch('integrations/get');
  selectedIntegrationId.value = props.inbox.ecommerce_integration?.id || null;
  loadSalesSettings();
});

const handleSave = async () => {
  if (isMarketplaceLocked.value) return;

  isSaving.value = true;
  try {
    await store.dispatch('inboxes/updateInbox', {
      id: props.inbox.id,
      formData: false,
      ecommerce_integration_id: selectedIntegrationId.value,
    });
    useAlert(t('INBOX_MGMT.ECOMMERCE.SAVE_SUCCESS'));
  } catch (error) {
    useAlert(error.message || t('INBOX_MGMT.ECOMMERCE.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const saveSalesSettings = async () => {
  isUpdatingSalesSettings.value = true;
  try {
    await store.dispatch('accounts/update', {
      settings: {
        ...account.value.settings,
        sales_order_notification_templates: salesOrderNotificationTemplates,
        sales_ai_allow_create_order: allowAiCreateOrder.value,
      },
    });
    useAlert(t('GENERAL_SETTINGS.UPDATE.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.UPDATE.ERROR'));
  } finally {
    isUpdatingSalesSettings.value = false;
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

        <!-- Save button -->
        <div class="flex justify-end pt-2">
          <NextButton
            :label="t('INBOX_MGMT.ECOMMERCE.SAVE')"
            sm
            :is-loading="isSaving"
            @click="handleSave"
          />
        </div>
      </div>

      <div class="w-full h-[1px] bg-n-weak my-4" />

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
        <form class="flex flex-col gap-6" @submit.prevent="saveSalesSettings">
          <div class="grid gap-4">
            <WithLabel
              name="template-draft"
              :label="$t('SALES.MODULE_ORDERS.STATUS.DRAFT')"
            >
              <textarea
                v-model="salesOrderNotificationTemplates.draft"
                class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                :placeholder="
                  t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_DRAFT')
                "
              />
            </WithLabel>
            <WithLabel
              name="template-confirmed"
              :label="$t('SALES.MODULE_ORDERS.STATUS.CONFIRMED')"
            >
              <textarea
                v-model="salesOrderNotificationTemplates.confirmed"
                class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                :placeholder="
                  t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_CONFIRMED')
                "
              />
            </WithLabel>
            <WithLabel
              name="template-processing"
              :label="$t('SALES.MODULE_ORDERS.STATUS.PROCESSING')"
            >
              <textarea
                v-model="salesOrderNotificationTemplates.processing"
                class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                :placeholder="
                  t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_PROCESSING')
                "
              />
            </WithLabel>
            <WithLabel
              name="template-shipped"
              :label="$t('SALES.MODULE_ORDERS.STATUS.SHIPPED')"
            >
              <textarea
                v-model="salesOrderNotificationTemplates.shipped"
                class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                :placeholder="
                  t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_SHIPPED')
                "
              />
            </WithLabel>
            <WithLabel
              name="template-delivered"
              :label="$t('SALES.MODULE_ORDERS.STATUS.DELIVERED')"
            >
              <textarea
                v-model="salesOrderNotificationTemplates.delivered"
                class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                :placeholder="
                  t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_DELIVERED')
                "
              />
            </WithLabel>
            <WithLabel
              name="template-cancelled"
              :label="$t('SALES.MODULE_ORDERS.STATUS.CANCELLED')"
            >
              <textarea
                v-model="salesOrderNotificationTemplates.cancelled"
                class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                :placeholder="
                  t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_CANCELLED')
                "
              />
            </WithLabel>
          </div>

          <div class="w-full h-[1px] bg-n-weak my-2" />

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

          <div class="flex justify-end pt-2 pb-6">
            <NextButton :is-loading="isUpdatingSalesSettings" sm type="submit">
              {{ t('INBOX_MGMT.ECOMMERCE.SAVE_SALES_SETTINGS') }}
            </NextButton>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>
