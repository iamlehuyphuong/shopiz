<script setup>
import { useI18n } from 'vue-i18n';
import { format } from 'date-fns';
import OrderStatusBadge from './OrderStatusBadge.vue';

const props = defineProps({
  orders: {
    type: Array,
    default: () => [],
  },
  readonly: {
    type: Boolean,
    default: false,
  },
  allowEdit: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['edit', 'delete', 'push', 'sync']);

const { t } = useI18n();

const formatDate = dateString => {
  if (!dateString) return '';
  return format(new Date(dateString), 'dd/MM/yyyy');
};

const formatCurrency = amount =>
  new Intl.NumberFormat('vi-VN').format(amount || 0);

const PLATFORM_LABELS = {
  kiotviet: 'KiotViet',
  sapo: 'Sapo',
  haravan: 'Haravan',
  woocommerce: 'WooCommerce',
  shopify: 'Shopify',
  nhanhvn: 'Nhanh.vn',
  tiktok_shop: 'TikTok Shop',
};

const PLATFORM_ICONS = {
  kiotviet: 'i-lucide-store',
  sapo: 'i-lucide-shopping-bag',
  haravan: 'i-lucide-shopping-cart',
  woocommerce: 'i-lucide-globe',
  shopify: 'i-lucide-package',
  nhanhvn: 'i-lucide-zap',
  tiktok_shop: 'i-lucide-music',
};

const platformLabel = source => PLATFORM_LABELS[source] || source;
const platformIcon = source => PLATFORM_ICONS[source] || 'i-lucide-box';

const canDeleteOrder = order => {
  // Always allow deleting manual/local orders
  if (!order.external_source) return true;

  // Define which external platforms allow order deletion from Flowify
  const ALLOW_DELETE_SOURCES = ['woocommerce', 'shopify']; // Example: custom website platforms might allow it

  return ALLOW_DELETE_SOURCES.includes(order.external_source);
};
</script>

<template>
  <div class="divide-y divide-n-weak">
    <div
      v-for="order in orders"
      :key="order.id"
      class="py-4 px-4 transition-colors flex flex-col gap-3"
      :class="{ 'hover:bg-n-alpha-1 cursor-pointer group': allowEdit }"
      @click="allowEdit && emit('edit', order)"
    >
      <!-- Header: IDs and Date -->
      <div class="flex items-start justify-between gap-2">
        <div class="flex flex-wrap items-center gap-2">
          <span class="text-sm font-bold text-n-slate-12">#{{ order.id }}</span>
          <span
            v-if="order.external_order_id"
            class="text-xs text-n-slate-10 font-mono bg-n-solid-2 px-1.5 py-0.5 rounded"
          >
            {{ order.external_order_id }}
          </span>
        </div>
        <span class="text-xs text-n-slate-9 shrink-0">
          {{ formatDate(order.created_at) }}
        </span>
      </div>

      <!-- Main Info: Badges & Price -->
      <div class="flex items-center justify-between">
        <div class="flex items-center gap-2">
          <OrderStatusBadge :status="order.status" />
          <span
            v-if="order.external_source"
            class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded border border-n-strong text-xs text-n-slate-11"
          >
            {{ platformLabel(order.external_source) }}
          </span>
        </div>
        <div class="text-right shrink-0">
          <div class="text-sm font-bold text-n-slate-12">
            {{ formatCurrency(order.total_amount) }}đ
          </div>
          <div class="text-xs text-n-slate-10">
            {{ order.items?.length || 0 }}
            {{ t('CONVERSATION.ORDER_PANEL.ITEMS_COUNT') }}
          </div>
        </div>
      </div>

      <!-- Customer Info -->
      <div
        v-if="
          order.customer_name || order.customer_phone || order.customer_address
        "
        class="flex flex-col gap-1 mt-1"
      >
        <div class="flex items-center gap-2 text-sm text-n-slate-12">
          <i class="i-lucide-user text-xs text-n-slate-10" />
          <span class="font-medium">{{ order.customer_name }}</span>
          <span v-if="order.customer_phone"
class="text-n-slate-10 text-xs"
            >· {{ order.customer_phone }}</span>
        </div>
        <div
          v-if="order.customer_address"
          class="flex items-start gap-2 text-xs text-n-slate-10 pl-5"
        >
          <span class="leading-snug line-clamp-2">{{
            order.customer_address
          }}</span>
        </div>
      </div>

      <!-- Products Box -->
      <div
        v-if="order.items?.length"
        class="bg-n-solid-2 border border-n-strong rounded-md p-2.5 flex flex-col gap-1.5 mt-1"
      >
        <div
          v-for="item in order.items.slice(0, 3)"
          :key="item.id"
          class="flex items-start justify-between gap-2 text-xs text-n-slate-11"
        >
          <span class="leading-snug line-clamp-2">{{ item.product_name }}</span>
          <span class="font-medium text-n-slate-12 shrink-0">x{{ item.quantity }}</span>
        </div>
        <div
          v-if="order.items.length > 3"
          class="text-xs text-n-slate-9 italic mt-1"
        >
          + {{ order.items.length - 3 }} sản phẩm khác...
        </div>
      </div>

      <!-- Note -->
      <div
        v-if="order.note"
        class="text-xs text-n-ruby-11 flex items-start gap-1.5 bg-n-ruby-2 p-2 rounded mt-1"
      >
        <i class="i-lucide-alert-circle text-[10px] shrink-0 mt-0.5" />
        <span class="leading-snug italic">{{ order.note }}</span>
      </div>

      <!-- Footer Action buttons -->
      <div
        v-if="!props.readonly"
        class="flex items-center justify-end gap-3 mt-1"
      >
        <button
          v-if="
            allowEdit &&
            order.status === 'draft' &&
            order.external_source !== 'tiktok_shop'
          "
          class="text-xs font-medium text-n-slate-11 hover:text-n-blue-9 flex items-center gap-1 transition-colors"
          @click.stop="emit('push', order)"
        >
          <i class="i-lucide-upload-cloud text-[10px]" />
          {{ t('CONVERSATION.ORDER_PANEL.PUSH') }}
        </button>
        <button
          v-if="order.external_order_id"
          class="text-xs font-medium text-n-slate-11 hover:text-n-emerald-9 flex items-center gap-1 transition-colors"
          @click.stop="emit('sync', order)"
        >
          <i class="i-lucide-refresh-cw text-[10px]" />
          {{ t('CONVERSATION.ORDER_PANEL.SYNC') }}
        </button>
        <button
          v-if="allowEdit && canDeleteOrder(order)"
          class="text-xs font-medium text-n-slate-11 hover:text-n-ruby-9 flex items-center gap-1 transition-colors"
          @click.stop="emit('delete', order)"
        >
          <i class="i-lucide-trash-2 text-[10px]" />
          {{ t('CONVERSATION.ORDER_PANEL.DELETE') }}
        </button>
      </div>
    </div>
  </div>
</template>
