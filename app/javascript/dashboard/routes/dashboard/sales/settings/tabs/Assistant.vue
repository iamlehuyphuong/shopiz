<script setup>
import { ref, reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';
import TabBar from 'dashboard/components-next/tabbar/TabBar.vue';

const { t } = useI18n();
const store = useStore();
const { currentAccount } = useAccount();

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

const templateVariables = {
  customer_name: '%{customer_name}',
  order_id: '%{order_id}',
  total_amount: '%{total_amount}',
  inbox_name: '%{inbox_name}',
  status_label: '%{status_label}',
  fanpage_name: '%{fanpage_name}',
};

const TEMPLATE_TABS = [
  { key: 'confirmed', labelKey: 'SALES.MODULE_ORDERS.STATUS.CONFIRMED' },
  { key: 'processing', labelKey: 'SALES.MODULE_ORDERS.STATUS.PROCESSING' },
  { key: 'shipped', labelKey: 'SALES.MODULE_ORDERS.STATUS.SHIPPED' },
  { key: 'delivered', labelKey: 'SALES.MODULE_ORDERS.STATUS.DELIVERED' },
  { key: 'cancelled', labelKey: 'SALES.MODULE_ORDERS.STATUS.CANCELLED' },
];

const isSaving = ref(false);
const customizeTemplates = ref(false);
const allowAiCreateOrder = ref(false);
const activeTabIndex = ref(0);
const activeTextareaRef = ref(null);

const salesOrderNotificationTemplates = reactive({
  confirmed: '',
  processing: '',
  shipped: '',
  delivered: '',
  cancelled: '',
});

const activeTab = computed(() => TEMPLATE_TABS[activeTabIndex.value].key);

const tabsForTabBar = computed(() =>
  // eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys
  TEMPLATE_TABS.map(tab => ({ label: t(tab.labelKey), key: tab.key }))
);

const onClickTabChange = tab => {
  activeTabIndex.value = TEMPLATE_TABS.findIndex(item => item.key === tab.key);
};

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

  if (hasAnyTemplate.value) {
    customizeTemplates.value = true;
  }
};

watch(
  currentAccount,
  () => {
    loadSalesSettings();
  },
  { deep: true, immediate: true }
);

const handleSave = async () => {
  isSaving.value = true;
  try {
    await store.dispatch('accounts/update', {
      ai_allow_create_order: allowAiCreateOrder.value,
      order_notification_templates: salesOrderNotificationTemplates,
    });
    useAlert(
      t('INBOX_MGMT.ECOMMERCE.SAVE_SUCCESS') || 'Đã lưu cấu hình trợ lý AI'
    );
  } catch (error) {
    useAlert(error.message || t('INBOX_MGMT.ECOMMERCE.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};

const fillDefaultTemplates = () => {
  salesOrderNotificationTemplates.confirmed = t(
    'INBOX_MGMT.ECOMMERCE.TEMPLATES_DEFAULT_CONFIRMED',
    templateVariables
  );
  salesOrderNotificationTemplates.processing = t(
    'INBOX_MGMT.ECOMMERCE.TEMPLATES_DEFAULT_PROCESSING',
    templateVariables
  );
  salesOrderNotificationTemplates.shipped = t(
    'INBOX_MGMT.ECOMMERCE.TEMPLATES_DEFAULT_SHIPPED',
    templateVariables
  );
  salesOrderNotificationTemplates.delivered = t(
    'INBOX_MGMT.ECOMMERCE.TEMPLATES_DEFAULT_DELIVERED',
    templateVariables
  );
  salesOrderNotificationTemplates.cancelled = t(
    'INBOX_MGMT.ECOMMERCE.TEMPLATES_DEFAULT_CANCELLED',
    templateVariables
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

  const name = textarea.closest('[data-template-key]')?.dataset.templateKey;
  if (name && name in salesOrderNotificationTemplates) {
    salesOrderNotificationTemplates[name] = newValue;
  }

  const newCursorPos = start + variableKey.length;
  requestAnimationFrame(() => {
    textarea.focus();
    textarea.setSelectionRange(newCursorPos, newCursorPos);
  });
};
</script>

<template>
  <div class="flex flex-col gap-8">
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

    <div class="h-px bg-n-weak w-full" />

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
        <Switch v-model="customizeTemplates" class="flex-shrink-0 mt-0.5" />
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
              <!-- eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys -->
              {{ t(variable.labelKey) }}
            </button>
          </div>
        </div>

        <div class="flex flex-col gap-4">
          <!-- Tab Headers and Actions -->
          <div class="flex items-center justify-between gap-4 flex-wrap">
            <TabBar
              :tabs="tabsForTabBar"
              :initial-active-tab="activeTabIndex"
              @tab-changed="onClickTabChange"
            />
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

          <!-- Tab Content -->
          <div class="mt-2">
            <div :data-template-key="activeTab" class="w-full">
              <!-- eslint-disable-next-line @intlify/vue-i18n/no-dynamic-keys -->
              <textarea
                v-model="salesOrderNotificationTemplates[activeTab]"
                class="w-full min-h-[120px] rounded-xl bg-n-alpha-black2 p-4 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none transition-all shadow-sm"
                :placeholder="
                  t(
                    `INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_${activeTab.toUpperCase()}`,
                    templateVariables
                  )
                "
                @focus="onTextareaFocus"
              />
            </div>
          </div>
        </div>
      </template>
    </div>

    <div class="flex justify-end pt-2">
      <NextButton
        :label="t('INBOX_MGMT.ECOMMERCE.SAVE') || 'Cập nhật cấu hình'"
        sm
        :is-loading="isSaving"
        @click="handleSave"
      />
    </div>
  </div>
</template>
