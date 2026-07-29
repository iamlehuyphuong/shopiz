<script setup>
import { computed, onBeforeMount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import SalesOrdersAPI from 'dashboard/api/sales/orders';
import SalesLayout from '../components/SalesLayout.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import PullOrdersDialog from '../components/PullOrdersDialog.vue';
import { OnClickOutside } from '@vueuse/components';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

const { t } = useI18n();
const store = useStore();
const getters = useStoreGetters();
const globalConfig = computed(() => getters['globalConfig/get'].value);

const isLoading = ref(true);
const isSyncing = ref(false);
const showPullDialog = ref(false);
const orders = ref([]);
const searchQuery = ref('');
const currentPage = ref(1);
const itemsPerPage = 15;
const sourceFilter = ref('all');

const sources = [
  { label: 'Tất cả nền tảng', value: 'all' },
  { label: 'Shopiz', value: 'shopiz' },
  { label: 'KiotViet', value: 'kiotviet' },
  { label: 'Sapo', value: 'sapo' },
  { label: 'Haravan', value: 'haravan' },
  { label: 'Shopify', value: 'shopify' },
  { label: 'WooCommerce', value: 'woocommerce' },
  { label: 'Nhanh.vn', value: 'nhanhvn' },
];

const showSourceDropdown = ref(false);
const activeSourceName = computed(
  () => sources.find(s => s.value === sourceFilter.value)?.label
);

const appIntegrations = computed(
  () => getters['integrations/getAppIntegrations'].value
);

const isSourceConnected = sourceValue => {
  if (sourceValue === 'all' || sourceValue === 'shopiz') return true;
  const integration = appIntegrations.value?.find(i => i.id === sourceValue);
  return integration && integration.hooks && integration.hooks.length > 0;
};

const sortedSources = computed(() => {
  return [...sources].sort((a, b) => {
    const getWeight = s => {
      if (s.value === 'all') return 0;
      if (s.value === 'shopiz') return 1;
      return isSourceConnected(s.value) ? 2 : 3;
    };
    return getWeight(a) - getWeight(b);
  });
});

const filteredOrders = computed(() => {
  let filtered = orders.value;

  if (sourceFilter.value !== 'all') {
    filtered = filtered.filter(order => {
      const source = order.external_source || 'shopiz';
      return source === sourceFilter.value;
    });
  }

  const query = searchQuery.value.trim();
  if (!query) return filtered;

  return filtered.filter(order => {
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
  const sourceMap = {
    kiotviet: 'KiotViet',
    sapo: 'Sapo',
    haravan: 'Haravan',
    shopify: 'Shopify',
    woocommerce: 'WooCommerce',
    nhanhvn: 'Nhanh.vn',
    tiktok_shop: 'TikTok Shop',
  };
  return sourceMap[source] || source;
};

const sourceLogo = source => {
  if (!source) return null;
  return `/dashboard/images/integrations/${source}.png`;
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

const onPullOrders = async platform => {
  showPullDialog.value = false;
  isSyncing.value = true;
  try {
    await SalesOrdersAPI.sync(platform);
    useAlert(t('SALES.DIALOG_PULL_ORDERS.ALERTS.SYNC_SUCCESS'));
    await fetchOrders();
  } catch (error) {
    useAlert(
      error.response?.data?.error ||
        t('SALES.DIALOG_PULL_ORDERS.ALERTS.SYNC_ERROR')
    );
  } finally {
    isSyncing.value = false;
  }
};

onBeforeMount(() => {
  store.dispatch('integrations/get');
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
      <div class="flex flex-col items-start w-full mb-4">
        <div
          class="flex items-center justify-between w-full gap-4 min-h-8 mb-2"
        >
          <div class="flex items-center gap-2">
            <span class="text-heading-1 text-n-slate-12">
              {{ activeSourceName }}
            </span>
            <div class="relative group z-20">
              <OnClickOutside @trigger="showSourceDropdown = false">
                <Button
                  icon="i-lucide-chevron-down"
                  :variant="showSourceDropdown ? 'faded' : 'ghost'"
                  color="slate"
                  size="xs"
                  class="rounded-md group-hover:bg-n-slate-3 hover:bg-n-slate-3 [&>span]:size-4"
                  @click="showSourceDropdown = !showSourceDropdown"
                />

                <div
                  v-if="showSourceDropdown"
                  class="py-3 bg-n-alpha-3 backdrop-blur-[100px] outline outline-n-container outline-1 z-50 absolute ltr:left-0 rtl:right-0 top-9 min-w-[20rem] max-w-[24rem] rounded-xl shadow-lg flex flex-col gap-2 mt-1"
                >
                  <div
                    class="flex items-center justify-between gap-4 px-4 pb-3 border-b border-n-alpha-2 mx-2"
                  >
                    <div class="flex flex-col gap-0.5">
                      <h2 class="text-sm font-semibold text-n-slate-12">
                        Nền tảng
                      </h2>
                      <p class="text-xs text-n-slate-11">
                        Chuyển đổi giữa các nền tảng bán hàng
                      </p>
                    </div>
                  </div>
                  <div
                    class="flex flex-col gap-0.5 px-2 max-h-[60vh] overflow-y-auto"
                  >
                    <Button
                      v-for="s in sortedSources"
                      :key="s.value"
                      variant="ghost"
                      color="slate"
                      class="!justify-between !px-3 !py-2 hover:!bg-n-alpha-2 h-10 w-full"
                      :disabled="!isSourceConnected(s.value)"
                      @click="
                        () => {
                          sourceFilter = s.value;
                          showSourceDropdown = false;
                        }
                      "
                    >
                      <div class="flex items-center gap-2.5 min-w-0">
                        <img
                          v-if="s.value !== 'all' && s.value !== 'shopiz'"
                          :src="sourceLogo(s.value)"
                          class="w-5 h-5 rounded-full object-cover flex-shrink-0"
                        />
                        <img
                          v-else-if="s.value === 'shopiz'"
                          :src="globalConfig.logoThumbnail"
                          class="w-5 h-5 object-contain flex-shrink-0"
                        />
                        <span
                          class="text-sm font-medium truncate text-n-slate-12"
                          >{{ s.label }}</span>
                      </div>
                      <Icon
                        v-if="sourceFilter === s.value"
                        icon="i-lucide-check"
                        class="w-4 h-4 text-n-teal-10 flex-shrink-0"
                      />
                    </Button>
                  </div>
                </div>
              </OnClickOutside>
            </div>

            <div class="w-0.5 h-4 rounded-2xl bg-n-weak ml-2 mr-2" />
            <span class="text-heading-1 text-n-slate-11">
              {{ $t('SALES.MODULE_ORDERS.HEADER.TITLE') }}
            </span>
          </div>
        </div>

        <div class="flex flex-col w-full gap-1.5 text-n-slate-11">
          <p class="mb-0 max-w-3xl text-body-main">
            {{ $t('SALES.MODULE_ORDERS.HEADER.DESCRIPTION') }}
          </p>
        </div>
      </div>

      <div class="gap-3 flex justify-between sm:mt-4 min-w-0 mb-4">
        <div class="flex items-center gap-3">
          <Input
            v-model="searchQuery"
            :placeholder="$t('SALES.MODULE_ORDERS.HEADER.SEARCH')"
            class="group w-56 min-w-0 hidden sm:flex [&_input]:ltr:!pl-10 [&_input]:rtl:!pr-10 [&_input]:!rounded-[0.625rem]"
            size="sm"
            type="search"
          >
            <template #prefix>
              <Icon
                icon="i-lucide-search"
                class="absolute top-1/2 -translate-y-1/2 text-n-slate-11 group-focus-within:text-n-orange size-3.5 ltr:left-2.5 rtl:right-2.5"
              />
            </template>
          </Input>
        </div>
        <div
          class="flex items-center gap-3 min-w-0 flex-row-reverse sm:flex-row"
        >
          <Button
            :label="$t('SALES.MODULE_ORDERS.ACTIONS.SYNC')"
            slate
            sm
            ghost
            :is-loading="isSyncing"
            @click="showPullDialog = true"
          />
          <Button
            :label="$t('SALES.MODULE_ORDERS.ACTIONS.ADD')"
            size="sm"
            @click="router.push({ name: 'sales_orders_new' })"
          />
        </div>
      </div>
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
              <BaseTableCell class="w-40 min-w-[140px]">
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

    <!-- Dialogs -->
    <woot-modal
      v-model:show="showPullDialog"
      :on-close="() => (showPullDialog = false)"
    >
      <PullOrdersDialog @close="showPullDialog = false" @sync="onPullOrders" />
    </woot-modal>
  </SalesLayout>
</template>
