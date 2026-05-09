<script setup>
import { computed, onBeforeMount, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useDebounceFn } from '@vueuse/core';
import { useToggle } from '@vueuse/core';

import SalesLayout from '../components/SalesLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import PullProductsDialog from '../components/PullProductsDialog.vue';
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

const showPullDialog = ref(false);
const [showDeleteModal, toggleDeleteModal] = useToggle(false);
const deleteProduct = ref(null);

const selectedProducts = ref([]);
const toggleSelectAll = event => {
  if (event.target.checked) {
    selectedProducts.value = products.value.map(p => p.id);
  } else {
    selectedProducts.value = [];
  }
};

const products = computed(() => getters['salesProducts/getProducts'].value);
const meta = computed(() => getters['salesProducts/getMeta'].value);
const uiFlags = computed(() => getters['salesProducts/getUIFlags'].value);

const showPagination = computed(() => meta.value.total_count > itemsPerPage);

const fetchProducts = () => {
  store.dispatch('salesProducts/get', {
    page: currentPage.value,
    search: searchQuery.value,
  });
};

const debouncedSearch = useDebounceFn(() => {
  currentPage.value = 1;
  fetchProducts();
}, 500);

import { watch } from 'vue';
watch(searchQuery, () => {
  debouncedSearch();
});

const tableHeaders = computed(() => {
  let productHeader = t('SALES.MODULE_PRODUCTS.TABLE.HEADERS.PRODUCT');
  if (selectedProducts.value.length > 0) {
    productHeader = `${productHeader} (${selectedProducts.value.length} đã chọn)`;
  }
  return [
    '', // Checkbox
    productHeader,
    t('SALES.MODULE_PRODUCTS.TABLE.HEADERS.STATUS'),
    t('SALES.MODULE_PRODUCTS.TABLE.HEADERS.ACTIONS'),
  ];
});

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

const formatSource = source => {
  const sources = {
    kiotviet: 'KiotViet',
    sapo: 'Sapo',
    haravan: 'Haravan',
    shopify: 'Shopify',
    woocommerce: 'WooCommerce',
    nhanhvn: 'Nhanh.vn',
    tiktok_shop: 'TikTok Shop',
  };
  return sources[source] || 'Shopiz';
};

const sourceLogo = source => {
  if (!source) return null;
  return `/dashboard/images/integrations/${source}.png`;
};

const onPullProducts = async platform => {
  useAlert(t('SALES.MODULE_PRODUCTS.ALERTS.PULL_START', { platform }));
  showPullDialog.value = false;
  try {
    await store.dispatch('salesProducts/syncPlatform', platform);
    useAlert(t('SALES.DIALOG_PULL_PRODUCTS.ALERTS.SYNC_SUCCESS'));
  } catch (error) {
    useAlert(t('SALES.DIALOG_PULL_PRODUCTS.ALERTS.SYNC_ERROR'));
  }
};

const onPushProduct = product => {
  useAlert(
    t('SALES.MODULE_PRODUCTS.ALERTS.PUSH_START', { name: product.name })
  );
};

import { useRouter } from 'vue-router';
const router = useRouter();

const onEditProduct = product => {
  router.push({ name: 'sales_products_edit', params: { id: product.id } });
};

const onDeleteProduct = product => {
  deleteProduct.value = product;
  toggleDeleteModal(true);
};

const confirmDeleteProduct = () => {
  store.dispatch('salesProducts/delete', deleteProduct.value.id).then(() => {
    useAlert(t('SALES.MODULE_PRODUCTS.ALERTS.DELETE_SUCCESS'));
  }).catch(() => {
    useAlert(t('SALES.MODULE_PRODUCTS.ALERTS.DELETE_ERROR'));
  }).finally(() => {
    toggleDeleteModal(false);
    deleteProduct.value = null;
  });
};

const onPageChange = page => {
  currentPage.value = page;
  fetchProducts();
};

onBeforeMount(() => {
  fetchProducts();
});
</script>

<!--
  Tailwind Safelist for dynamic status colors:
  bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300
  bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300
-->

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
            @click="router.push({ name: 'sales_products_new' })"
          />
        </template>
      </BaseSettingsHeader>
    </template>
    <template #body>
      <BaseTable
        :headers="tableHeaders"
        :items="products"
        :no-data-message="
          searchQuery
            ? $t('SALES.MODULE_PRODUCTS.TABLE.EMPTY_SEARCH')
            : $t('SALES.MODULE_PRODUCTS.TABLE.EMPTY_STATE')
        "
      >
        <template #header-0>
          <div class="flex items-center">
            <input
              type="checkbox"
              class="w-4 h-4 rounded border-n-weak dark:border-slate-700 bg-transparent text-woot-500 focus:ring-woot-500 transition-opacity"
              :class="
                selectedProducts.length > 0
                  ? 'opacity-100'
                  : 'opacity-0 group-hover:opacity-100'
              "
              :checked="
                selectedProducts.length === products.length &&
                products.length > 0
              "
              :indeterminate="
                selectedProducts.length > 0 &&
                selectedProducts.length < products.length
              "
              @change="toggleSelectAll"
            />
          </div>
        </template>
        <template #row="{ items }">
          <BaseTableRow
            v-for="(product, index) in items"
            :key="product.id"
            :item="product"
            class="group hover:bg-n-solid-2"
          >
            <template #default>
              <!-- Column 0: Checkbox -->
              <BaseTableCell class="w-12">
                <input
                  v-model="selectedProducts"
                  type="checkbox"
                  class="w-4 h-4 rounded border-n-weak dark:border-slate-700 bg-transparent text-woot-500 focus:ring-woot-500 transition-opacity"
                  :class="
                    selectedProducts.includes(product.id)
                      ? 'opacity-100'
                      : 'opacity-0 group-hover:opacity-100'
                  "
                  :value="product.id"
                />
              </BaseTableCell>

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
                    <span class="px-2 py-0.5 bg-n-alpha-2 rounded text-xs">
                      {{ formatSource(product.meta?.source) }}
                    </span>
                    <span v-if="product.sku || product.price || product.barcode">·</span>
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

              <!-- Column 4: Actions -->
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
                    @click="onDeleteProduct(product)"
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
        :current-page="meta.current_page"
        :total-items="meta.total_count"
        :items-per-page="itemsPerPage"
        @update:current-page="onPageChange"
      />
    </template>

    <!-- Dialogs -->
    <woot-modal
      v-model:show="showPullDialog"
      :on-close="() => (showPullDialog = false)"
    >
      <PullProductsDialog
        @close="showPullDialog = false"
        @sync="onPullProducts"
      />
    </woot-modal>

    <woot-confirm-delete-modal
      v-if="showDeleteModal"
      v-model:show="showDeleteModal"
      :title="$t('SALES.MODULE_PRODUCTS.ALERTS.DELETE_CONFIRM_TITLE')"
      :message="$t('SALES.MODULE_PRODUCTS.ALERTS.DELETE_CONFIRM', { name: deleteProduct?.name })"
      :confirm-text="$t('SALES.MODULE_PRODUCTS.ALERTS.DELETE_CONFIRM_YES', { name: deleteProduct?.name })"
      :reject-text="$t('SALES.MODULE_PRODUCTS.ALERTS.CANCEL', { name: deleteProduct?.name })"
      :confirm-value="deleteProduct?.name"
      :confirm-place-holder-text="$t('SALES.MODULE_PRODUCTS.ALERTS.DELETE_CONFIRM_PLACEHOLDER', { name: deleteProduct?.name })"
      @on-confirm="confirmDeleteProduct"
      @on-close="toggleDeleteModal(false)"
    />
  </SalesLayout>
</template>
