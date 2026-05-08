<script setup>
import { computed, onBeforeMount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { picoSearch } from '@scmmishra/pico-search';

import SalesOrdersAPI from 'dashboard/api/sales/orders';
import SalesLayout from '../components/SalesLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

const { t } = useI18n();
const isLoading = ref(true);
const orders = ref([]);
const searchQuery = ref('');
const currentPage = ref(1);
const itemsPerPage = 15;

const filteredOrders = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return orders.value;
  return orders.value.filter(order => {
    const searchableString = [
      order.id,
      order.customer_name,
      order.customer_phone,
      order.customer_address,
      order.external_order_id,
      order.external_source,
      order.contact?.name,
      order.contact?.phone_number,
    ]
      .filter(Boolean)
      .join(' ')
      .toLowerCase();

    return searchableString.includes(query.toLowerCase());
  });
});

const paginatedOrders = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage;
  return filteredOrders.value.slice(start, start + itemsPerPage);
});

const showPagination = computed(() => filteredOrders.value.length > 0);

const tableHeaders = computed(() => [
  t('SALES.MODULE_ORDERS.TABLE.HEADERS.ORDER'),
  t('SALES.MODULE_ORDERS.TABLE.HEADERS.STATUS'),
  t('SALES.MODULE_ORDERS.TABLE.HEADERS.ACTIONS'),
]);

const fetchOrders = async () => {
  isLoading.value = true;
  try {
    const response = await SalesOrdersAPI.get();
    orders.value = response.data;
  } catch (error) {
    console.error('Failed to fetch sales orders', error);
  } finally {
    isLoading.value = false;
  }
};

const formatCurrency = (amount, currency = 'VND') => {
  if (!amount && amount !== 0) return '--';
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: currency || 'VND',
  }).format(amount);
};

const formatDate = dateString => {
  if (!dateString) return '--';
  const date = new Date(dateString);
  return date.toLocaleDateString('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  });
};

const statusColor = status => {
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
  return colors[status] || 'bg-n-alpha-2 text-n-slate-11';
};

const formatStatus = status => {
  switch (status) {
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
};

const formatSource = source => {
  if (!source) return t('SALES.DIALOG_ORDER_DETAIL.FALLBACKS.SHOPIZ');
  const sources = {
    kiotviet: 'KiotViet',
    sapo: 'Sapo',
    haravan: 'Haravan',
    shopify: 'Shopify',
    woocommerce: 'WooCommerce',
    nhanhvn: 'Nhanh.vn',
    tiktok_shop: 'TikTok Shop',
  };
  return sources[source] || source;
};

const onPageChange = page => {
  currentPage.value = page;
};

import { useRouter } from 'vue-router';
const router = useRouter();

const openDetail = order => {
  router.push({ name: 'sales_orders_show', params: { id: order.id } });
};

const onSyncOrder = order => {
  useAlert(
    window.i18n.t('SALES.MODULE_ORDERS.MESSAGES.SYNC', {
      id: order.external_order_id || order.id,
    })
  );
};

onBeforeMount(() => {
  fetchOrders();
});
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
  <SalesLayout
    :is-loading="isLoading"
    :no-records-found="!orders.length"
    :no-records-message="$t('SALES.MODULE_ORDERS.TABLE.EMPTY_STATE')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('SALES.MODULE_ORDERS.HEADER.TITLE')"
        :description="$t('SALES.MODULE_ORDERS.HEADER.DESCRIPTION')"
        :search-placeholder="$t('SALES.MODULE_ORDERS.HEADER.SEARCH')"
        feature-name="salesOrders"
      >
        <template #actions>
          <Button
            :label="$t('SALES.MODULE_ORDERS.ACTIONS.REFRESH')"
            slate
            sm
            ghost
            icon="i-lucide-refresh-cw"
            @click="fetchOrders"
          />
          <Button
            :label="$t('SALES.MODULE_ORDERS.ACTIONS.ADD')"
            size="sm"
            @click="router.push({ name: 'sales_orders_new' })"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <BaseTable
        :headers="tableHeaders"
        :items="paginatedOrders"
        :no-data-message="
          searchQuery
            ? $t('SALES.MODULE_ORDERS.TABLE.EMPTY_SEARCH')
            : $t('SALES.MODULE_ORDERS.TABLE.EMPTY_STATE')
        "
      >
        <template #row="{ items }">
          <BaseTableRow
            v-for="(order, index) in items"
            :key="order.id"
            :item="order"
          >
            <template #default>
              <!-- Column 1: Order info -->
              <BaseTableCell class="max-w-0 w-full">
                <div class="flex flex-col gap-1">
                  <div
                    class="flex items-center gap-2 text-body-main text-n-slate-12"
                  >
                    <span class="font-medium">
                      #{{ order.external_order_id || order.id }}
                    </span>
                    <span class="font-medium">
                      {{
                        order.customer_name ||
                        order.contact?.name ||
                        $t('SALES.DIALOG_ORDER_DETAIL.FALLBACKS.GUEST')
                      }}
                    </span>
                    <span v-if="order.customer_phone" class="text-n-slate-11">
                      · {{ order.customer_phone }}
                    </span>
                    <span
                      v-if="order.customer_address"
                      class="text-n-slate-11 truncate max-w-[200px]"
                      :title="order.customer_address"
                    >
                      · {{ order.customer_address }}
                    </span>
                  </div>
                  <div
                    class="flex items-center gap-2 text-body-main text-n-slate-11"
                  >
                    <span class="px-2 py-0.5 bg-n-alpha-2 rounded text-xs">
                      {{ formatSource(order.external_source) }}
                    </span>
                    <span>·</span>
                    <span>{{ formatCurrency(order.total_amount) }}</span>
                    <span>·</span>
                    <span>{{ formatDate(order.created_at) }}</span>
                  </div>
                </div>
              </BaseTableCell>

              <!-- Column 2: Status -->
              <BaseTableCell>
                <span
                  class="px-2.5 py-1 text-xs font-medium rounded-full whitespace-nowrap"
                  :class="statusColor(order.status)"
                >
                  {{ formatStatus(order.status) }}
                </span>
              </BaseTableCell>

              <!-- Column 3: Actions -->
              <BaseTableCell align="end">
                <div class="flex gap-3 justify-end flex-shrink-0">
                  <Button
                    v-tooltip.top="$t('SALES.MODULE_ORDERS.TABLE.ACTIONS.SYNC')"
                    icon="i-woot-settings"
                    slate
                    sm
                    ghost
                    @click="onSyncOrder(order)"
                  />
                  <Button
                    v-tooltip.top="$t('SALES.MODULE_ORDERS.TABLE.ACTIONS.VIEW')"
                    icon="i-lucide-eye"
                    slate
                    sm
                    ghost
                    @click="openDetail(order)"
                  />
                </div>
              </BaseTableCell>
            </template>
          </BaseTableRow>
        </template>
      </BaseTable>
    </template>
    <template v-if="showPagination" #footer>
      <PaginationFooter
        :current-page="currentPage"
        :total-items="filteredOrders.length"
        :items-per-page="itemsPerPage"
        @update:current-page="onPageChange"
      />
    </template>
  </SalesLayout>
</template>
