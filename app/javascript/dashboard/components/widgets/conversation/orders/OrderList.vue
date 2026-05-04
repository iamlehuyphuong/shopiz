<script setup>
import { useI18n } from 'vue-i18n';
import { format } from 'date-fns';
import OrderStatusBadge from './OrderStatusBadge.vue';

const props = defineProps({
  orders: {
    type: Array,
    default: () => [],
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
</script>

<template>
  <div class="divide-y divide-n-weak">
    <div
      v-for="order in orders"
      :key="order.id"
      class="py-3 px-4 hover:bg-n-alpha-1 transition-colors cursor-pointer group"
      @click="emit('edit', order)"
    >
      <div class="flex items-start justify-between gap-2 mb-1.5">
        <div class="flex-1 min-w-0">
          <div class="flex items-center gap-2 mb-1">
            <span class="text-sm font-medium text-n-slate-12">
              #{{ order.id }}
            </span>
            <span
              v-if="order.external_source"
              class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-n-solid-3 text-xs text-n-slate-11"
            >
              <i :class="platformIcon(order.external_source)" class="text-xs" />
              {{ platformLabel(order.external_source) }}
            </span>
            <span class="text-xs text-n-slate-10">
              {{ formatDate(order.created_at) }}
            </span>
          </div>
          <OrderStatusBadge :status="order.status" />
        </div>
        <div class="text-right shrink-0">
          <div class="text-sm font-semibold text-n-slate-12">
            {{ formatCurrency(order.total_amount) }}đ
          </div>
          <div class="text-xs text-n-slate-10">
            {{ order.items?.length || 0 }}
            {{ t('CONVERSATION.ORDER_PANEL.ITEMS_COUNT') }}
          </div>
        </div>
      </div>

      <!-- Customer info -->
      <div
        v-if="
          order.customer_name || order.customer_phone || order.customer_address
        "
        class="flex flex-col gap-1 text-xs text-n-slate-10 mt-1.5"
      >
        <div class="flex items-center gap-3">
          <span v-if="order.customer_name" class="flex items-center gap-1">
            <i class="i-lucide-user text-xs" />
            {{ order.customer_name }}
          </span>
          <span v-if="order.customer_phone" class="flex items-center gap-1">
            <i class="i-lucide-phone text-xs" />
            {{ order.customer_phone }}
          </span>
        </div>
        <div v-if="order.customer_address" class="flex items-center gap-1">
          <i class="i-lucide-map-pin text-xs" />
          {{ order.customer_address }}
        </div>
      </div>

      <!-- Products preview -->
      <div v-if="order.items?.length" class="mt-2 flex flex-wrap gap-1">
        <span
          v-for="item in order.items.slice(0, 3)"
          :key="item.id"
          class="inline-flex items-center gap-1 px-1.5 py-0.5 rounded bg-n-solid-3 text-xs text-n-slate-11"
        >
          {{ item.product_name }}
          <span class="text-n-slate-9">×{{ item.quantity }}</span>
        </span>
        <span
          v-if="order.items.length > 3"
          class="inline-flex items-center px-1.5 py-0.5 rounded bg-n-solid-3 text-xs text-n-slate-10"
        >
          +{{ order.items.length - 3 }}
        </span>
      </div>

      <!-- Action buttons (visible on hover) -->
      <div
        class="flex items-center gap-3 mt-2 opacity-0 group-hover:opacity-100 transition-opacity"
      >
        <button
          v-if="
            order.status === 'draft' && order.external_source !== 'tiktok_shop'
          "
          class="text-xs text-n-slate-10 hover:text-n-blue-9 flex items-center gap-1 transition-colors"
          @click.stop="emit('push', order)"
        >
          <i class="i-lucide-upload-cloud text-xs" />
          {{ t('CONVERSATION.ORDER_PANEL.PUSH') }}
        </button>
        <button
          v-if="order.external_order_id"
          class="text-xs text-n-slate-10 hover:text-n-emerald-9 flex items-center gap-1 transition-colors"
          @click.stop="emit('sync', order)"
        >
          <i class="i-lucide-refresh-cw text-xs" />
          {{ t('CONVERSATION.ORDER_PANEL.SYNC') }}
        </button>
        <button
          class="text-xs text-n-slate-10 hover:text-n-ruby-9 flex items-center gap-1 transition-colors"
          @click.stop="emit('delete', order)"
        >
          <i class="i-lucide-trash-2 text-xs" />
          {{ t('CONVERSATION.ORDER_PANEL.DELETE') }}
        </button>
      </div>
    </div>
  </div>
</template>
