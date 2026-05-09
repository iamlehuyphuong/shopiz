<script setup>
import { computed, onMounted, reactive, ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useAccount } from 'dashboard/composables/useAccount';
import BaseSettingsHeader from '../../settings/components/BaseSettingsHeader.vue';
import SectionLayout from '../../settings/account/components/SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextInput from 'next/input/Input.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const { t } = useI18n();
const store = useStore();
const { accountId } = useAccount();

const isLoading = ref(false);
const isUpdating = ref(false);

const salesOrderNotificationTemplates = reactive({
  draft: '',
  confirmed: '',
  processing: '',
  shipped: '',
  delivered: '',
  cancelled: '',
});

const defaultOrderDestination = ref('');

const destinations = [
  { label: 'Shopiz Native', value: 'shopiz' },
  { label: 'WooCommerce', value: 'woocommerce' },
  { label: 'KiotViet', value: 'kiotviet' },
  { label: 'Haravan', value: 'haravan' },
  { label: 'Nhanh.vn', value: 'nhanhvn' },
  { label: 'Sapo', value: 'sapo' },
  { label: 'Shopify', value: 'shopify' },
];

const account = computed(() => store.getters['accounts/getAccount'](accountId.value) || {});

const loadSettings = () => {
  const settings = account.value.settings || {};
  
  if (settings.sales_order_notification_templates) {
    Object.keys(salesOrderNotificationTemplates).forEach(key => {
      salesOrderNotificationTemplates[key] = settings.sales_order_notification_templates[key] || '';
    });
  }
  
  defaultOrderDestination.value = settings.sales_default_order_destination || 'shopiz';
};

const saveSettings = async () => {
  isUpdating.value = true;
  try {
    await store.dispatch('accounts/update', {
      settings: {
        ...account.value.settings,
        sales_order_notification_templates: salesOrderNotificationTemplates,
        sales_default_order_destination: defaultOrderDestination.value,
      },
    });
    useAlert(t('GENERAL_SETTINGS.UPDATE.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.UPDATE.ERROR'));
  } finally {
    isUpdating.value = false;
  }
};

onMounted(() => {
  loadSettings();
});
</script>

<template>
  <div class="flex flex-col w-full max-w-full ltr:mr-auto rtl:ml-auto">
    <BaseSettingsHeader
      title="Cài đặt Bán hàng"
      description="Quản lý cấu hình chung cho tính năng đơn hàng và thông báo."
    />
    <div class="flex-grow flex-shrink min-w-0 mt-3 pb-12">
      <!-- Mẫu thông báo đơn hàng -->
      <SectionLayout
        title="Mẫu thông báo đơn hàng"
        description="Định cấu hình các mẫu tin nhắn được gửi tự động khi đơn hàng thay đổi trạng thái. Bạn có thể sử dụng các biến: %{customer_name}, %{fanpage_name}, %{order_id}, %{status_label}, %{total_amount}"
      >
        <form class="grid gap-4" @submit.prevent="saveSettings">
          <WithLabel name="template-draft" label="Đơn nháp (Draft)">
            <textarea
              v-model="salesOrderNotificationTemplates.draft"
              class="w-full min-h-[80px] rounded-lg border border-n-weak bg-n-alpha-black2 p-3 text-sm focus:border-n-brand focus:ring-1 focus:ring-n-brand"
              placeholder="Ví dụ: Chào %{customer_name}, đơn nháp #%{order_id} của bạn..."
            />
          </WithLabel>
          <WithLabel name="template-confirmed" label="Đã xác nhận (Confirmed)">
            <textarea
              v-model="salesOrderNotificationTemplates.confirmed"
              class="w-full min-h-[80px] rounded-lg border border-n-weak bg-n-alpha-black2 p-3 text-sm focus:border-n-brand focus:ring-1 focus:ring-n-brand"
            />
          </WithLabel>
          <WithLabel name="template-processing" label="Đang xử lý (Processing)">
            <textarea
              v-model="salesOrderNotificationTemplates.processing"
              class="w-full min-h-[80px] rounded-lg border border-n-weak bg-n-alpha-black2 p-3 text-sm focus:border-n-brand focus:ring-1 focus:ring-n-brand"
            />
          </WithLabel>
          <WithLabel name="template-shipped" label="Đang giao (Shipped)">
            <textarea
              v-model="salesOrderNotificationTemplates.shipped"
              class="w-full min-h-[80px] rounded-lg border border-n-weak bg-n-alpha-black2 p-3 text-sm focus:border-n-brand focus:ring-1 focus:ring-n-brand"
            />
          </WithLabel>
          <WithLabel name="template-delivered" label="Đã giao (Delivered)">
            <textarea
              v-model="salesOrderNotificationTemplates.delivered"
              class="w-full min-h-[80px] rounded-lg border border-n-weak bg-n-alpha-black2 p-3 text-sm focus:border-n-brand focus:ring-1 focus:ring-n-brand"
            />
          </WithLabel>
          <WithLabel name="template-cancelled" label="Đã hủy (Cancelled)">
            <textarea
              v-model="salesOrderNotificationTemplates.cancelled"
              class="w-full min-h-[80px] rounded-lg border border-n-weak bg-n-alpha-black2 p-3 text-sm focus:border-n-brand focus:ring-1 focus:ring-n-brand"
            />
          </WithLabel>
          
          <div>
            <NextButton blue :is-loading="isUpdating" type="submit">
              Lưu thay đổi
            </NextButton>
          </div>
        </form>
      </SectionLayout>

      <!-- Đích đến khi tạo đơn bằng AI -->
      <SectionLayout
        title="Đích đến mặc định của AI"
        description="Khi trợ lý AI thực hiện tạo đơn hàng, hệ thống này sẽ được chọn làm đích đến mặc định để đồng bộ đơn hàng về."
        class="mt-8"
      >
        <form class="grid gap-4" @submit.prevent="saveSettings">
          <WithLabel name="ai-order-dest" label="Hệ thống tạo đơn">
            <select
              v-model="defaultOrderDestination"
              class="w-full rounded-lg border border-n-weak bg-n-alpha-black2 p-3 text-sm focus:border-n-brand focus:ring-1 focus:ring-n-brand h-10"
            >
              <option v-for="dest in destinations" :key="dest.value" :value="dest.value">
                {{ dest.label }}
              </option>
            </select>
          </WithLabel>
          
          <div>
            <NextButton blue :is-loading="isUpdating" type="submit">
              Lưu thay đổi
            </NextButton>
          </div>
        </form>
      </SectionLayout>
    </div>
  </div>
</template>
