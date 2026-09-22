<script setup>
import { ref, computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useI18n } from 'vue-i18n';
import SalesOrdersAPI from 'dashboard/api/sales/orders';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
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
    useAlert('Lỗi khi tải dữ liệu đơn hàng');
  } finally {
    isLoading.value = false;
  }
};

const isUpdating = ref(false);

const updateOrder = async payload => {
  if (!order.value) return;
  isUpdating.value = true;
  try {
    const response = await SalesOrdersAPI.update(order.value.id, payload);
    order.value = response.data;
    useAlert('Cập nhật đơn hàng thành công');
  } catch (error) {
    useAlert('Lỗi khi cập nhật');
  } finally {
    isUpdating.value = false;
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

      <div
        v-if="order && order.external_source"
        class="flex items-center gap-3"
      >
        <Button
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

    <div v-else class="py-6 max-w-4xl mx-auto w-full flex flex-col gap-8">
      <!-- Top Grid: General & Customer -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Khách hàng -->
        <div class="flex flex-col gap-3">
          <span class="text-sm font-medium text-n-slate-11">Khách hàng</span>
          <div
            class="rounded-xl border border-n-weak bg-n-solid-1 p-4 flex flex-col gap-2 h-full"
          >
            <div class="flex items-center gap-3">
              <div v-if="order.contact?.thumbnail || order.contact?.avatar_url">
                <img
                  :src="order.contact?.thumbnail || order.contact?.avatar_url"
                  :alt="order.customer_name || order.contact?.name"
                  class="w-9 h-9 rounded-md object-cover shrink-0 bg-n-solid-3"
                />
              </div>
              <div
                v-else
                class="w-9 h-9 rounded-md bg-n-brand text-white flex items-center justify-center shrink-0 font-medium text-sm uppercase"
              >
                {{
                  (order.customer_name || order.contact?.name || '?').charAt(0)
                }}
              </div>
              <div class="flex-1 min-w-0">
                <div class="text-sm font-medium text-n-slate-12 truncate">
                  {{
                    order.customer_name ||
                    order.contact?.name ||
                    $t('SALES.DIALOG_ORDER_DETAIL.FALLBACKS.GUEST')
                  }}
                </div>
                <div
                  v-if="order.customer_phone || order.contact?.phone_number"
                  class="text-xs text-n-slate-10 truncate mt-0.5"
                >
                  {{ order.customer_phone || order.contact?.phone_number }}
                </div>
              </div>
            </div>
            <div
              v-if="
                order.shipping_address ||
                order.customer_address ||
                order.customer_note ||
                order.note
              "
              class="flex flex-col gap-1.5 pt-2 mt-1 border-t border-n-weak text-xs text-n-slate-10"
            >
              <div
                v-if="order.shipping_address || order.customer_address"
                class="flex items-start gap-1"
              >
                <i class="i-lucide-map-pin text-xs shrink-0 mt-0.5" />
                <span>{{
                  order.shipping_address || order.customer_address
                }}</span>
              </div>
              <div
                v-if="order.customer_note || order.note"
                class="flex items-start gap-1"
              >
                <i class="i-lucide-file-text text-xs shrink-0 mt-0.5" />
                <span>{{ order.customer_note || order.note }}</span>
              </div>
            </div>
          </div>
        </div>

        <!-- Thông tin chung -->
        <div class="flex flex-col gap-3">
          <span class="text-sm font-medium text-n-slate-11">Thông tin chung</span>
          <div
            class="rounded-xl border border-n-weak bg-n-solid-1 p-4 flex flex-col gap-3 h-full"
          >
            <div class="flex flex-col gap-1.5 mb-2 pb-3 border-b border-n-weak">
              <label class="text-sm font-medium text-n-slate-11">Trạng thái đơn hàng</label>
              <ComboBox
                :model-value="order.status"
                :options="[
                  {
                    label: $t('CONVERSATION.ORDER_PANEL.STATUS.DRAFT'),
                    value: 'draft',
                  },
                  {
                    label: $t('CONVERSATION.ORDER_PANEL.STATUS.CONFIRMED'),
                    value: 'confirmed',
                  },
                  {
                    label: $t('CONVERSATION.ORDER_PANEL.STATUS.PROCESSING'),
                    value: 'processing',
                  },
                  {
                    label: $t('CONVERSATION.ORDER_PANEL.STATUS.SHIPPED'),
                    value: 'shipped',
                  },
                  {
                    label: $t('CONVERSATION.ORDER_PANEL.STATUS.DELIVERED'),
                    value: 'delivered',
                  },
                  {
                    label: $t('CONVERSATION.ORDER_PANEL.STATUS.CANCELLED'),
                    value: 'cancelled',
                  },
                ]"
                @update:model-value="val => updateOrder({ status: val })"
              />
            </div>
            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-xs text-n-slate-11 mb-1">Ngày tạo</label>
                <p class="text-sm font-medium text-n-slate-12 mb-0">
                  {{ formatDate(order.created_at) }}
                </p>
              </div>
              <div>
                <label class="block text-xs text-n-slate-11 mb-1">Nguồn</label>
                <p class="text-sm font-medium text-n-slate-12 mb-0 capitalize">
                  {{ order.external_source || 'Shopiz' }}
                </p>
              </div>
              <div v-if="order.external_source">
                <label class="block text-xs text-n-slate-11 mb-1">Đồng bộ lần cuối</label>
                <p class="text-sm font-medium text-n-slate-12 mb-0">
                  {{ formatDate(order.updated_at) }}
                </p>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Middle Grid: Payment & Shipping -->
      <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
        <!-- Thanh toán -->
        <div class="flex flex-col gap-3">
          <span class="text-sm font-medium text-n-slate-11">Thanh toán</span>
          <div
            class="rounded-xl border border-n-weak bg-n-solid-1 p-4 flex flex-col gap-3 h-full"
          >
            <div class="flex flex-col gap-1.5">
              <label class="text-sm font-medium text-n-slate-11">Phương thức</label>
              <ComboBox
                :model-value="order.payment_method || 'cod'"
                :options="[
                  { label: 'COD', value: 'cod' },
                  { label: 'Chuyển khoản', value: 'bank_transfer' },
                  { label: 'Thẻ / Ví điện tử', value: 'card' },
                ]"
                @update:model-value="
                  val => updateOrder({ payment_method: val })
                "
              />
            </div>
            <div class="flex flex-col gap-1.5 mt-1">
              <label class="text-sm font-medium text-n-slate-11">Trạng thái</label>
              <ComboBox
                :model-value="order.payment_status || 'unpaid'"
                :options="[
                  {
                    label: $t('CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.UNPAID'),
                    value: 'unpaid',
                  },
                  {
                    label: $t('CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.PAID'),
                    value: 'paid',
                  },
                  {
                    label: $t(
                      'CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.PARTIALLY_REFUNDED'
                    ),
                    value: 'partially_refunded',
                  },
                  { label: 'Hoàn tiền', value: 'refunded' },
                ]"
                @update:model-value="
                  val => updateOrder({ payment_status: val })
                "
              />
            </div>
          </div>
        </div>

        <!-- Vận chuyển -->
        <div class="flex flex-col gap-3">
          <span class="text-sm font-medium text-n-slate-11">Vận chuyển</span>
          <div
            class="rounded-xl border border-n-weak bg-n-solid-1 p-4 flex flex-col gap-3 h-full"
          >
            <div class="flex items-center justify-between">
              <span class="text-sm text-n-slate-11">Đơn vị</span>
              <span class="text-sm font-medium text-n-slate-12">{{
                order.shipping_carrier || '--'
              }}</span>
            </div>
            <div
              v-if="order.tracking_code"
              class="flex items-center justify-between"
            >
              <span class="text-sm text-n-slate-11">Mã vận đơn</span>
              <span class="text-sm font-medium text-n-brand">{{
                order.tracking_code
              }}</span>
            </div>
          </div>
        </div>
      </div>

      <!-- Danh sách sản phẩm -->
      <div class="flex flex-col gap-3">
        <span class="text-sm font-medium text-n-slate-11">
          Sản phẩm ({{ orderItems.length }})
        </span>
        <div
          class="rounded-xl border border-n-weak bg-n-solid-1 overflow-hidden"
        >
          <div class="overflow-y-auto divide-y divide-n-weak">
            <div
              v-for="(item, index) in orderItems"
              :key="index"
              class="flex items-center gap-3 px-4 py-3"
            >
              <img
                v-if="item.thumbnail || item.product_thumbnail"
                :src="item.thumbnail || item.product_thumbnail"
                :alt="item.product_name || item.name"
                class="w-8 h-8 rounded object-cover shrink-0 bg-n-solid-3"
              />
              <div
                v-else
                class="w-8 h-8 rounded bg-n-solid-3 flex items-center justify-center shrink-0"
              >
                <i class="i-lucide-package text-n-slate-10 text-xs" />
              </div>
              <div class="flex-1 min-w-0">
                <div class="text-sm text-n-slate-12 truncate">
                  {{
                    item.product_name || item.name || `Sản phẩm ${index + 1}`
                  }}
                </div>
                <div class="text-xs text-n-slate-10 mt-0.5">
                  {{ item.quantity || 1 }} x
                  {{ formatCurrency(item.unit_price || item.price) }}
                </div>
              </div>
              <span class="text-sm font-medium text-n-slate-12 shrink-0">
                {{
                  formatCurrency(
                    (item.quantity || 1) * (item.unit_price || item.price)
                  )
                }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <!-- Summary card -->
      <div
        class="p-5 rounded-xl border border-n-weak bg-n-solid-1 flex flex-col gap-3 w-full"
      >
        <div class="flex justify-between items-center text-sm">
          <span class="text-n-slate-11">Tạm tính</span>
          <span class="text-n-slate-12 font-medium">{{
            formatCurrency(
              Number(order.total_amount || 0) -
                Number(order.shipping_fee || 0) -
                Number(order.tax || 0) +
                Number(order.discount_amount || 0)
            )
          }}</span>
        </div>
        <div class="flex justify-between items-center text-sm">
          <span class="text-n-slate-11">Phí vận chuyển</span>
          <span class="text-n-slate-12">{{
            formatCurrency(order.shipping_fee)
          }}</span>
        </div>
        <div class="flex justify-between items-center text-sm">
          <span class="text-n-slate-11">Giảm giá</span>
          <span class="text-n-red-11">-{{ formatCurrency(order.discount_amount) }}</span>
        </div>
        <div class="flex justify-between items-center text-sm">
          <span class="text-n-slate-11">Thuế</span>
          <span class="text-n-slate-12">{{ formatCurrency(order.tax) }}</span>
        </div>
        <div class="h-px bg-n-weak w-full my-1" />
        <div class="flex justify-between items-center">
          <span class="text-base font-medium text-n-slate-12">Tổng tiền</span>
          <span class="text-lg font-bold text-n-brand">{{
            formatCurrency(order.total_amount)
          }}</span>
        </div>
      </div>
    </div>
  </div>
</template>
