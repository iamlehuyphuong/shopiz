<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  order: {
    type: Object,
    required: true,
  },
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'sync']);

const { t } = useI18n();

const formatCurrency = price => {
  if (!price && price !== 0) return '--';
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: props.order.currency || 'VND',
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
  switch (props.order.status) {
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
  return colors[props.order.status] || 'bg-n-alpha-2 text-n-slate-11';
});

const orderItems = computed(() => props.order.items || []);
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('SALES.DIALOG_ORDER_DETAIL.TITLE')"
      :header-content="
        $t('SALES.DIALOG_ORDER_DETAIL.DESC', {
          id: order.external_order_id || order.id,
          source:
            order.external_source ||
            $t('SALES.DIALOG_ORDER_DETAIL.FALLBACKS.SHOPIZ'),
        })
      "
    />
    <div class="flex flex-wrap mx-0">
      <!-- Status badge -->
      <div class="w-full mb-5 px-8">
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.STATUS') }}
        </label>
        <span
          class="inline-block px-3 py-1 text-xs font-medium rounded-full"
          :class="statusColor"
        >
          {{ statusLabel }}
        </span>
      </div>

      <!-- Customer info -->
      <div class="w-full mb-5 px-8">
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.CUSTOMER') }}
        </label>
        <p class="text-sm text-n-slate-11 mb-0">
          {{
            order.customer_name ||
            order.contact?.name ||
            $t('SALES.DIALOG_ORDER_DETAIL.FALLBACKS.GUEST')
          }}
        </p>
      </div>

      <div class="flex w-full gap-4 px-8 mb-5">
        <div class="flex-1">
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.PHONE') }}
          </label>
          <p class="text-sm text-n-slate-11 mb-0">
            {{
              order.customer_phone ||
              $t('SALES.DIALOG_ORDER_DETAIL.FALLBACKS.NO_DATA')
            }}
          </p>
        </div>
        <div class="flex-1">
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.SOURCE') }}
          </label>
          <p class="text-sm text-n-slate-11 mb-0 capitalize">
            {{
              order.external_source ||
              $t('SALES.DIALOG_ORDER_DETAIL.FALLBACKS.SHOPIZ')
            }}
          </p>
        </div>
      </div>

      <div class="w-full mb-5 px-8">
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.ADDRESS') }}
        </label>
        <p class="text-sm text-n-slate-11 mb-0">
          {{
            order.shipping_address ||
            $t('SALES.DIALOG_ORDER_DETAIL.FALLBACKS.NO_DATA')
          }}
        </p>
      </div>

      <div class="flex w-full gap-4 px-8 mb-5">
        <div class="flex-1">
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.TOTAL') }}
          </label>
          <p class="text-sm text-n-slate-11 font-medium mb-0">
            {{ formatCurrency(order.total_amount) }}
          </p>
        </div>
        <div class="flex-1">
          <label class="block text-sm font-medium text-n-slate-12 mb-2">
            {{ $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.CREATED_AT') }}
          </label>
          <p class="text-sm text-n-slate-11 mb-0">
            {{ formatDate(order.created_at) }}
          </p>
        </div>
      </div>

      <div v-if="order.external_source" class="w-full mb-5 px-8">
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.LAST_SYNC') }}
        </label>
        <p class="text-sm text-n-slate-11 mb-0">
          {{ formatDate(order.updated_at) }}
        </p>
      </div>

      <div v-if="order.note" class="w-full mb-5 px-8">
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.NOTE') }}
        </label>
        <div class="text-sm text-n-slate-11 p-3 bg-n-alpha-1 rounded-lg">
          {{ order.note }}
        </div>
      </div>

      <!-- Order Items -->
      <div v-if="orderItems.length" class="w-full mb-5 px-8">
        <label class="block text-sm font-medium text-n-slate-12 mb-2">
          {{ $t('SALES.DIALOG_ORDER_DETAIL.FIELDS.ITEMS') }} ({{
            orderItems.length
          }})
        </label>
        <div
          class="flex flex-col gap-1.5 p-5 bg-n-alpha-1 rounded-xl border border-n-weak"
        >
          <div
            v-for="(item, index) in orderItems"
            :key="index"
            class="flex items-center justify-between py-1 border-b border-n-weak last:border-0 last:pb-0"
          >
            <div class="flex flex-col gap-0.5">
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
      </div>

      <!-- Footer -->
      <div class="flex items-center justify-end w-full gap-3 px-8 pb-8 pt-4">
        <NextButton
          v-if="order.external_source"
          faded
          slate
          :label="$t('SALES.DIALOG_ORDER_DETAIL.ACTIONS.SYNC')"
          icon="i-lucide-refresh-cw"
          @click="emit('sync', order.id)"
        />
        <NextButton
          :label="$t('SALES.DIALOG_ORDER_DETAIL.ACTIONS.CLOSE')"
          @click="emit('close')"
        />
      </div>
    </div>
  </div>
</template>
