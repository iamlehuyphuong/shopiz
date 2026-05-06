<script setup>
import { useAccount } from 'dashboard/composables/useAccount';
import { useI18n } from 'vue-i18n';
import { formatDistanceToNow } from 'date-fns';
import { vi } from 'date-fns/locale';

const props = defineProps({
  orders: { type: Array, default: () => [] },
});

const { accountScopedRoute } = useAccount();
const { t, locale } = useI18n();

const formatCurrency = price => {
  if (!price && price !== 0) return '--';
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
    maximumFractionDigits: 0,
  }).format(price);
};

const formatSource = source => {
  if (!source) return '--';
  const map = {
    woocommerce: 'WooCommerce',
    tiktok_shop: 'TikTok Shop',
    shopify: 'Shopify',
    haravan: 'Haravan',
    sapo: 'Sapo',
    kiotviet: 'KiotViet',
    nhanhvn: 'Nhanh.vn',
  };
  return map[source] || source;
};

const formatTime = dateStr => {
  try {
    return formatDistanceToNow(new Date(dateStr), {
      addSuffix: true,
      locale: locale.value === 'vi' ? vi : undefined,
    });
  } catch {
    return dateStr;
  }
};

const statusColors = {
  draft: 'bg-n-slate-3 text-n-slate-11',
  confirmed: 'bg-n-blue-3 text-n-blue-11',
  processing: 'bg-n-amber-3 text-n-amber-11',
  shipped: 'bg-n-orange-3 text-n-orange-11',
  delivered: 'bg-n-teal-3 text-n-teal-11',
  cancelled: 'bg-n-ruby-3 text-n-ruby-11',
};

const statusLabel = status => {
  const key = `SALES.MODULE_DASHBOARD.STATUS_BREAKDOWN.${status.toUpperCase()}`;
  return t(key);
};
</script>

<template>
  <div
    class="bg-white dark:bg-n-solid-1 rounded-xl border border-n-weak shadow-sm flex flex-col"
  >
    <div class="px-6 pt-5 pb-3 flex items-center justify-between">
      <h3 class="text-sm font-medium text-n-slate-12 mb-0">
        {{ $t('SALES.MODULE_DASHBOARD.RECENT_ORDERS.TITLE') }}
      </h3>
      <router-link
        :to="accountScopedRoute('sales_orders_list')"
        class="text-xs font-medium text-n-brand hover:underline"
      >
        {{ $t('SALES.MODULE_DASHBOARD.RECENT_ORDERS.VIEW_ALL') }} →
      </router-link>
    </div>
    <div v-if="orders.length" class="flex-1 overflow-x-auto">
      <table class="w-full text-sm">
        <thead>
          <tr class="border-b border-n-weak">
            <th
              class="px-6 py-2.5 text-left text-xs font-medium text-n-slate-10 uppercase tracking-wider"
            >
              {{ $t('SALES.MODULE_DASHBOARD.RECENT_ORDERS.CUSTOMER') }}
            </th>
            <th
              class="px-4 py-2.5 text-left text-xs font-medium text-n-slate-10 uppercase tracking-wider"
            >
              {{ $t('SALES.MODULE_DASHBOARD.RECENT_ORDERS.SOURCE') }}
            </th>
            <th
              class="px-4 py-2.5 text-right text-xs font-medium text-n-slate-10 uppercase tracking-wider"
            >
              {{ $t('SALES.MODULE_DASHBOARD.RECENT_ORDERS.AMOUNT') }}
            </th>
            <th
              class="px-4 py-2.5 text-left text-xs font-medium text-n-slate-10 uppercase tracking-wider"
            >
              {{ $t('SALES.MODULE_DASHBOARD.RECENT_ORDERS.STATUS') }}
            </th>
            <th
              class="px-6 py-2.5 text-right text-xs font-medium text-n-slate-10 uppercase tracking-wider"
            >
              {{ $t('SALES.MODULE_DASHBOARD.RECENT_ORDERS.TIME') }}
            </th>
          </tr>
        </thead>
        <tbody>
          <tr
            v-for="order in orders"
            :key="order.id"
            class="border-b border-n-weak last:border-0 hover:bg-n-alpha-1 transition-colors"
          >
            <td class="px-6 py-3">
              <div class="flex flex-col">
                <span class="text-sm font-medium text-n-slate-12">
                  {{ order.customer_name }}
                </span>
                <span
                  v-if="order.external_order_id"
                  class="text-xs text-n-slate-10"
                >
                  #{{ order.external_order_id }}
                </span>
              </div>
            </td>
            <td class="px-4 py-3">
              <span
                v-if="order.external_source"
                class="text-xs px-2 py-0.5 rounded-full bg-n-alpha-1 text-n-slate-11 font-medium"
              >
                {{ formatSource(order.external_source) }}
              </span>
              <span v-else class="text-xs text-n-slate-10">--</span>
            </td>
            <td
              class="px-4 py-3 text-right text-sm font-medium text-n-slate-12 tabular-nums"
            >
              {{ formatCurrency(order.total_amount) }}
            </td>
            <td class="px-4 py-3">
              <span
                class="text-xs px-2 py-0.5 rounded-full font-medium"
                :class="statusColors[order.status] || 'bg-n-slate-3 text-n-slate-11'"
              >
                {{ statusLabel(order.status) }}
              </span>
            </td>
            <td class="px-6 py-3 text-right text-xs text-n-slate-10">
              {{ formatTime(order.created_at) }}
            </td>
          </tr>
        </tbody>
      </table>
    </div>
    <div
      v-else
      class="flex-1 flex items-center justify-center py-12 text-sm text-n-slate-10"
    >
      {{ $t('SALES.MODULE_DASHBOARD.RECENT_ORDERS.NO_ORDERS') }}
    </div>
  </div>
</template>
