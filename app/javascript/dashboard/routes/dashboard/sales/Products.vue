<script setup>
import { computed, onBeforeMount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { picoSearch } from '@scmmishra/pico-search';

import SalesLayout from './components/SalesLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import AddProductDialog from './components/AddProductDialog.vue';
import PullProductsDialog from './components/PullProductsDialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import PaginationFooter from 'dashboard/components-next/pagination/PaginationFooter.vue';
import {
  BaseTable,
  BaseTableRow,
  BaseTableCell,
} from 'dashboard/components-next/table';

const { t } = useI18n();
const getters = useStoreGetters();
const store = useStore();

const searchQuery = ref('');
const currentPage = ref(1);
const itemsPerPage = 15;

const showAddDialog = ref(false);
const showPullDialog = ref(false);

const products = computed(() => getters['salesProducts/getProducts'].value);
const uiFlags = computed(() => getters['salesProducts/getUIFlags'].value);

const filteredProducts = computed(() => {
  const query = searchQuery.value.trim();
  if (!query) return products.value;
  return picoSearch(products.value, query, ['name', 'sku']);
});

const paginatedProducts = computed(() => {
  const start = (currentPage.value - 1) * itemsPerPage;
  return filteredProducts.value.slice(start, start + itemsPerPage);
});

const showPagination = computed(
  () => filteredProducts.value.length > itemsPerPage
);

const tableHeaders = computed(() => [
  t('SALES.MODULE_PRODUCTS.TABLE.HEADERS.PRODUCT'),
  t('SALES.MODULE_PRODUCTS.TABLE.HEADERS.STATUS'),
  t('SALES.MODULE_PRODUCTS.TABLE.HEADERS.ACTIONS'),
]);

const formatCurrency = (price, currency = 'VND') => {
  if (!price && price !== 0) return '--';
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: currency || 'VND',
  }).format(price);
};

const formatStatus = status => {
  switch (status) {
    case 'active':
      return t('SALES.MODULE_PRODUCTS.STATUS.ACTIVE');
    case 'archived':
      return t('SALES.MODULE_PRODUCTS.STATUS.ARCHIVED');
    default:
      return t('SALES.MODULE_PRODUCTS.STATUS.DRAFT');
  }
};

const statusColor = status => {
  const colors = {
    active: 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300',
    draft: 'bg-n-alpha-2 text-n-slate-11',
    archived: 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300',
  };
  return colors[status] || 'bg-n-alpha-2 text-n-slate-11';
};

const onAddProduct = productData => {
  store
    .dispatch('salesProducts/create', productData)
    .then(() => {
      useAlert(t('SALES.MODULE_PRODUCTS.ALERTS.ADD_SUCCESS'));
      showAddDialog.value = false;
    })
    .catch(error => {
      useAlert(error.message || t('SALES.MODULE_PRODUCTS.ALERTS.ADD_ERROR'));
    });
};

const onPullProducts = platform => {
  useAlert(t('SALES.MODULE_PRODUCTS.ALERTS.PULL_START', { platform }));
  showPullDialog.value = false;
};

const onPushProduct = product => {
  useAlert(
    t('SALES.MODULE_PRODUCTS.ALERTS.PUSH_START', { name: product.name })
  );
};

const onEditProduct = product => {
  useAlert(t('SALES.MODULE_PRODUCTS.ALERTS.EDIT', { name: product.name }));
};

const onDeleteProduct = productId => {
  if (confirm(t('SALES.MODULE_PRODUCTS.ALERTS.DELETE_CONFIRM'))) {
    store.dispatch('salesProducts/delete', productId).then(() => {
      useAlert(t('SALES.MODULE_PRODUCTS.ALERTS.DELETE_SUCCESS'));
    });
  }
};

const onPageChange = page => {
  currentPage.value = page;
};

onBeforeMount(() => {
  store.dispatch('salesProducts/get');
});
</script>

<template>
  <SalesLayout
    :is-loading="uiFlags.isFetching"
    :no-records-found="!products.length"
    :no-records-message="$t('SALES.MODULE_PRODUCTS.TABLE.EMPTY_STATE')"
  >
    <template #header>
      <BaseSettingsHeader
        v-model:search-query="searchQuery"
        :title="$t('SALES.MODULE_PRODUCTS.HEADER.TITLE')"
        :description="$t('SALES.MODULE_PRODUCTS.HEADER.DESCRIPTION')"
        :search-placeholder="$t('SALES.MODULE_PRODUCTS.HEADER.SEARCH')"
        feature-name="salesProducts"
      >
        <template v-if="products?.length" #count>
          <span class="text-body-main text-n-slate-11">
            {{ products.length }} {{ $t('SALES.MODULE_PRODUCTS.HEADER.COUNT') }}
          </span>
        </template>
        <template #actions>
          <Button
            :label="$t('SALES.MODULE_PRODUCTS.ACTIONS.PULL')"
            slate
            sm
            ghost
            @click="showPullDialog = true"
          />
          <Button
            :label="$t('SALES.MODULE_PRODUCTS.ACTIONS.PUSH')"
            slate
            sm
            ghost
            @click="useAlert($t('SALES.MODULE_PRODUCTS.ALERTS.SELECT_TO_PUSH'))"
          />
          <Button
            :label="$t('SALES.MODULE_PRODUCTS.ACTIONS.ADD')"
            size="sm"
            @click="showAddDialog = true"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <BaseTable
        :headers="tableHeaders"
        :items="paginatedProducts"
        :no-data-message="
          searchQuery
            ? $t('SALES.MODULE_PRODUCTS.TABLE.EMPTY_SEARCH')
            : $t('SALES.MODULE_PRODUCTS.TABLE.EMPTY_STATE')
        "
      >
        <template #row="{ items }">
          <BaseTableRow
            v-for="(product, index) in items"
            :key="product.id"
            :item="product"
          >
            <template #default>
              <!-- Column 1: Product info -->
              <BaseTableCell class="max-w-0 w-full">
                <div class="flex flex-col gap-1">
                  <div
                    class="flex items-center gap-2 text-body-main text-n-slate-12"
                  >
                    <span class="font-medium">
                      #{{ (currentPage - 1) * itemsPerPage + index + 1 }}
                    </span>
                    <span class="font-medium">
                      {{ product.name }}
                    </span>
                  </div>
                  <div
                    class="flex items-center gap-2 text-body-main text-n-slate-11"
                  >
                    <span v-if="product.sku">SKU: {{ product.sku }}</span>
                    <span v-if="product.sku">·</span>
                    <span>
                      {{ formatCurrency(product.price, product.currency) }}
                    </span>
                    <span v-if="product.barcode">·</span>
                    <span v-if="product.barcode">
                      {{ product.barcode }}
                    </span>
                  </div>
                </div>
              </BaseTableCell>

              <!-- Column 2: Status -->
              <BaseTableCell>
                <span
                  class="px-2.5 py-1 text-xs font-medium rounded-full whitespace-nowrap"
                  :class="statusColor(product.status)"
                >
                  {{ formatStatus(product.status) }}
                </span>
              </BaseTableCell>

              <!-- Column 3: Actions -->
              <BaseTableCell align="end">
                <div class="flex gap-3 justify-end flex-shrink-0">
                  <Button
                    v-tooltip.top="
                      $t('SALES.MODULE_PRODUCTS.TABLE.ACTIONS.PUSH')
                    "
                    icon="i-lucide-upload"
                    slate
                    sm
                    ghost
                    @click="onPushProduct(product)"
                  />
                  <Button
                    v-tooltip.top="
                      $t('SALES.MODULE_PRODUCTS.TABLE.ACTIONS.EDIT')
                    "
                    icon="i-woot-settings"
                    slate
                    sm
                    ghost
                    @click="onEditProduct(product)"
                  />
                  <Button
                    v-tooltip.top="
                      $t('SALES.MODULE_PRODUCTS.TABLE.ACTIONS.DELETE')
                    "
                    icon="i-woot-bin"
                    slate
                    sm
                    ghost
                    class="hover:enabled:text-n-ruby-11 hover:enabled:bg-n-ruby-2"
                    @click="onDeleteProduct(product.id)"
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
        :total-items="filteredProducts.length"
        :items-per-page="itemsPerPage"
        @update:current-page="onPageChange"
      />
    </template>

    <!-- Dialogs -->
    <woot-modal
      v-model:show="showAddDialog"
      :on-close="() => (showAddDialog = false)"
    >
      <AddProductDialog @close="showAddDialog = false" @submit="onAddProduct" />
    </woot-modal>
    <woot-modal
      v-model:show="showPullDialog"
      :on-close="() => (showPullDialog = false)"
    >
      <PullProductsDialog
        @close="showPullDialog = false"
        @sync="onPullProducts"
      />
    </woot-modal>
  </SalesLayout>
</template>
