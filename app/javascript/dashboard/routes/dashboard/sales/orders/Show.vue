<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import SalesOrdersAPI from 'dashboard/api/sales/orders';
import Button from 'dashboard/components-next/button/Button.vue';
import { useAlert } from 'dashboard/composables';

const route = useRoute();
const { t } = useI18n();

const order = ref(null);
const isLoading = ref(true);

const fetchOrderDetails = async () => {
  isLoading.value = true;
  try {
    const response = await SalesOrdersAPI.show(route.params.id);
    order.value = response.data;
  } catch (error) {
    useAlert(
      t('SALES.MODULE_ORDERS.ALERTS.FETCH_ERROR') ||
        'Lỗi khi tải dữ liệu đơn hàng'
    );
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  if (route.params.id) {
    fetchOrderDetails();
  }
});

const onSyncOrder = () => {
  useAlert(
    t('SALES.MODULE_ORDERS.MESSAGES.SYNC', {
      id: order.value?.external_order_id || order.value?.id,
    }) || 'Đang đồng bộ đơn hàng...'
  );
};

const formatCurrency = price => {
  if (!price && price !== 0) return '--';
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: order.value?.currency || 'VND',
  }).format(price);
};

const formatDate = dateStr => {
  if (!dateStr) return '--';
  const d = new Date(dateStr);
  return d.toLocaleDateString('vi-VN', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
};

const statusLabel = computed(() => {
  if (!order.value) return '';
  switch (order.value.status) {
    case 'confirmed':
      return t('SALES.MODULE_ORDERS.STATUS.CONFIRMED');
    case 'processing':
      return t('SALES.MODULE_ORDERS.STATUS.PROCESSING');
    case 'shipped':
      return t('SALES.MODULE_ORDERS.STATUS.SHIPPED');
    case 'delivered':
      return t('SALES.MODULE_ORDERS.STATUS.DELIVERED');
    case 'cancelled':
      return t('SALES.MODULE_ORDERS.STATUS.CANCELLED');
    default:
      return t('SALES.MODULE_ORDERS.STATUS.DRAFT');
  }
});

const statusColor = computed(() => {
  if (!order.value) return '';
  const colors = {
    draft: 'bg-n-alpha-2 text-n-slate-11',
    confirmed: 'bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300',
    processing:
      'bg-yellow-100 text-yellow-700 dark:bg-yellow-900 dark:text-yellow-300',
    shipped:
      'bg-purple-100 text-purple-700 dark:bg-purple-900 dark:text-purple-300',
    delivered:
      'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300',
    cancelled: 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300',
  };
  return colors[order.value.status] || 'bg-n-alpha-2 text-n-slate-11';
});

const orderItems = computed(() => order.value?.items || []);
</script>

<!--
  Tailwind Safelist for dynamic status colors:
  bg-blue-100 text-blue-700 dark:bg-blue-900 dark:text-blue-300
  bg-yellow-100 text-yellow-700 dark:bg-yellow-900 dark:text-yellow-300
  bg-purple-100 text-purple-700 dark:bg-purple-900 dark:text-purple-300
  bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300
  bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300
-->

<template>
  <div class="flex flex-col h-full bg-n-surface-1 w-full overflow-y-auto">
    <div
      class="flex justify-between items-center h-20 min-h-[3.5rem] px-6 py-2 bg-n-surface-1 max-w-5xl mx-auto w-full flex-shrink-0"
    >
      <h1 class="flex items-center mb-0 text-n-slate-12">
        <router-link
          :to="{ name: 'sales_orders_list' }"
          class="flex items-center font-normal cursor-pointer text-n-slate-11 text-base ltr:mr-4 rtl:ml-4 hover:text-n-slate-12 transition-colors"
        >
          <i class="i-lucide-chevron-left -ml-1 text-lg mr-1" />
          Back
        </router-link>
        <span class="text-heading-1 text-n-slate-12 flex items-center">
          {{ $t('SALES.DIALOG_ORDER_DETAIL.TITLE') }}
          <span
            v-if="order"
            class="text-n-slate-11 font-normal ml-2 text-base mt-0.5"
          >
            #{{ order.external_order_id || order.id }}
          </span>
        </span>
      </h1>

      <div v-if="order" class="flex items-center gap-3">
        <span
          class="px-2.5 py-1 text-xs font-medium rounded-full whitespace-nowrap"
          :class="statusColor"
        >
          {{ statusLabel }}
        </span>
        <Button
          v-if="order.external_source"
          faded
          slate
          :label="$t('SALES.DIALOG_ORDER_DETAIL.ACTIONS.SYNC')"
          icon="i-lucide-refresh-cw"
          @click="onSyncOrder"
        />
      </div>
    </div>

    <div v-if="isLoading" class="p-8 flex items-center justify-center">
      <span class="icon-spin text-2xl text-n-slate-11 animate-spin" />
    </div>

    <div v-else-if="!order" class="p-8 text-center text-n-slate-11">
      <p>Không tìm thấy đơn hàng</p>
    </div>

    <div v-else class="p-8 max-w-5xl mx-auto w-full flex flex-col gap-6">
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Customer info -->
        <div
          class="bg-n-alpha-1 rounded-xl p-5 border border-n-weak flex flex-col gap-4"
        >
          <h3 class="text-base font-semibold text-n-slate-12 m-0">
            {{ $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.CUSTOMER') }}
          </h3>
          <div class="flex flex-col gap-2">
            <p class="text-sm text-n-slate-12 font-medium mb-0">
              {{
                order.customer_name ||
                order.contact?.name ||
                $t('SALES.DIALOG_ORDER_DETAIL.FALLBACKS.GUEST')
              }}
            </p>
            <p class="text-sm text-n-slate-11 mb-0 flex items-center gap-2">
              <span class="icon-call text-n-slate-9" />
              {{
                order.customer_phone ||
                $t('SALES.DIALOG_ORDER_DETAIL.FALLBACKS.NO_DATA')
              }}
            </p>
            <p class="text-sm text-n-slate-11 mb-0 flex items-start gap-2">
              <span class="icon-location text-n-slate-9 mt-0.5" />
              {{
                order.shipping_address ||
                order.customer_address ||
                $t('SALES.DIALOG_ORDER_DETAIL.FALLBACKS.NO_DATA')
              }}
            </p>
          </div>
        </div>

        <!-- Order details -->
        <div
          class="bg-n-alpha-1 rounded-xl p-5 border border-n-weak flex flex-col gap-4"
        >
          <h3 class="text-base font-semibold text-n-slate-12 m-0">
            {{ $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.GENERAL_INFO') }}
          </h3>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-xs text-n-slate-11 mb-1">{{
                $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.CREATED_AT')
              }}</label>
              <p class="text-sm font-medium text-n-slate-12 mb-0">
                {{ formatDate(order.created_at) }}
              </p>
            </div>
            <div>
              <label class="block text-xs text-n-slate-11 mb-1">{{
                $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.SOURCE')
              }}</label>
              <p class="text-sm font-medium text-n-slate-12 mb-0 capitalize">
                {{
                  order.external_source ||
                  $t('SALES.DIALOG_ORDER_DETAIL.FALLBACKS.FLOWIFY')
                }}
              </p>
            </div>
            <div v-if="order.external_source" class="col-span-2">
              <label class="block text-xs text-n-slate-11 mb-1">{{
                $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.LAST_SYNC')
              }}</label>
              <p class="text-sm font-medium text-n-slate-12 mb-0">
                {{ formatDate(order.updated_at) }}
              </p>
            </div>
          </div>
        </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Payment -->
        <div
          class="bg-n-alpha-1 rounded-xl p-5 border border-n-weak flex flex-col gap-4"
        >
          <h3 class="text-base font-semibold text-n-slate-12 m-0">
            {{ $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.PAYMENT_METHOD') }}
          </h3>
          <div class="flex items-center gap-3">
            <p class="text-sm font-medium text-n-slate-12 uppercase mb-0">
              {{ order.payment_method || '--' }}
            </p>
            <span
              class="inline-block px-2 py-0.5 text-xs font-medium rounded capitalize"
              :class="
                order.payment_status === 'paid'
                  ? 'bg-green-100 text-green-700'
                  : 'bg-yellow-100 text-yellow-700'
              "
            >
              {{ order.payment_status || 'unpaid' }}
            </span>
          </div>
        </div>

        <!-- Shipping -->
        <div
          class="bg-n-alpha-1 rounded-xl p-5 border border-n-weak flex flex-col gap-4"
        >
          <h3 class="text-base font-semibold text-n-slate-12 m-0">
            {{ $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.SHIPPING') }}
          </h3>
          <div class="flex flex-col gap-1">
            <p class="text-sm font-medium text-n-slate-12 mb-0">
              {{ order.shipping_carrier || '--' }}
            </p>
            <p v-if="order.tracking_code" class="text-sm text-n-brand mb-0">
              {{ order.tracking_code }}
            </p>
          </div>
        </div>
      </div>

      <!-- Note -->
      <div
        v-if="order.note"
        class="bg-n-alpha-1 rounded-xl p-5 border border-n-weak flex flex-col gap-3"
      >
        <h3 class="text-base font-semibold text-n-slate-12 m-0">
          {{ $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.NOTE') }}
        </h3>
        <p class="text-sm text-n-slate-11 mb-0">{{ order.note }}</p>
      </div>

      <!-- Order Items -->
      <div
        v-if="orderItems.length"
        class="bg-white dark:bg-slate-900 rounded-xl border border-n-weak overflow-hidden"
      >
        <div class="px-5 py-4 border-b border-n-weak bg-n-alpha-1">
          <h3 class="text-base font-semibold text-n-slate-12 m-0">
            {{ $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.ITEMS') }} ({{
              orderItems.length
            }})
          </h3>
        </div>
        <div class="flex flex-col px-5">
          <div
            v-for="(item, index) in orderItems"
            :key="index"
            class="flex items-center justify-between py-4 border-b border-n-weak last:border-0"
          >
            <div class="flex flex-col gap-1">
              <span class="text-sm font-medium text-n-slate-12">
                {{
                  item.product_name ||
                  item.name ||
                  $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.PRODUCT', {
                    index: index + 1,
                  })
                }}
              </span>
              <span class="text-xs text-n-slate-11">
                {{ formatCurrency(item.unit_price || item.price) }} x
                {{ item.quantity || 1 }}
              </span>
            </div>
            <span class="text-sm font-medium text-n-slate-12">
              {{
                formatCurrency(
                  (item.unit_price || item.price) * (item.quantity || 1)
                )
              }}
            </span>
          </div>
        </div>

        <!-- Financial Breakdown -->
        <div
          class="px-5 py-4 bg-n-alpha-1 border-t border-n-weak flex flex-col items-end"
        >
          <div class="w-full sm:w-1/2 flex flex-col gap-2">
            <div class="flex justify-between text-sm text-n-slate-11">
              <span>{{
                  $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.SUBTOTAL') || 'Tạm tính'
                }}:</span>
              <span>{{
                formatCurrency(
                  Number(order.total_amount || 0) -
                    Number(order.shipping_fee || 0) -
                    Number(order.tax || 0) +
                    Number(order.discount_amount || 0)
                )
              }}</span>
            </div>
            <div
              v-if="order.shipping_fee > 0"
              class="flex justify-between text-sm text-n-slate-11"
            >
              <span>{{
                  $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.SHIPPING_FEE') ||
                  'Phí vận chuyển'
                }}:</span>
              <span>{{ formatCurrency(order.shipping_fee) }}</span>
            </div>
            <div
              v-if="order.tax > 0"
              class="flex justify-between text-sm text-n-slate-11"
            >
              <span>{{
                  $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.TAX') || 'Thuế'
                }}:</span>
              <span>{{ formatCurrency(order.tax) }}</span>
            </div>
            <div
              v-if="order.discount_amount > 0"
              class="flex justify-between text-sm text-green-600"
            >
              <span>{{
                  $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.DISCOUNT') || 'Giảm giá'
                }}:</span>
              <span>-{{ formatCurrency(order.discount_amount) }}</span>
            </div>
            <div
              class="flex justify-between text-base font-bold text-n-slate-12 pt-3 mt-1 border-t border-n-strong"
            >
              <span>{{ $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.TOTAL') }}:</span>
              <span>{{ formatCurrency(order.total_amount) }}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
