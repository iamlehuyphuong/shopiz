<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRoute } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import SalesProductsAPI from 'dashboard/api/sales/products';

const { t } = useI18n();
const route = useRoute();

const product = ref(null);
const isLoading = ref(true);

const fetchProductDetails = async () => {
  isLoading.value = true;
  try {
    const response = await SalesProductsAPI.show(route.params.id);
    product.value = response.data;
  } catch (error) {
    useAlert(
      t('SALES.MODULE_PRODUCTS.ALERTS.FETCH_ERROR') ||
        'Lỗi khi tải dữ liệu sản phẩm'
    );
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  if (route.params.id) {
    fetchProductDetails();
  }
});

const formatCurrency = price => {
  if (!price && price !== 0) return '--';
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: product.value?.currency || 'VND',
  }).format(price);
};

const formatStatus = status => {
  switch (status) {
    case 'active':
      return t('SALES.MODULE_PRODUCTS.STATUS.ACTIVE') || 'Đang bán';
    case 'archived':
      return t('SALES.MODULE_PRODUCTS.STATUS.ARCHIVED') || 'Lưu trữ';
    default:
      return t('SALES.MODULE_PRODUCTS.STATUS.DRAFT') || 'Bản nháp';
  }
};

const statusColor = computed(() => {
  if (!product.value) return '';
  const colors = {
    active: 'bg-green-100 text-green-700 dark:bg-green-900 dark:text-green-300',
    draft: 'bg-n-alpha-2 text-n-slate-11',
    archived: 'bg-red-100 text-red-700 dark:bg-red-900 dark:text-red-300',
  };
  return colors[product.value.status] || 'bg-n-alpha-2 text-n-slate-11';
});

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
</script>

<template>
  <div
    class="flex flex-col h-full bg-white dark:bg-slate-900 overflow-y-auto w-full"
  >
    <div
      class="flex items-center gap-3 px-8 py-5 border-b border-n-weak sticky top-0 bg-white dark:bg-slate-900 z-10 flex-shrink-0"
    >
      <router-link
        :to="{ name: 'sales_products_list' }"
        class="p-2 -ml-2 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-1 rounded-lg transition-colors"
      >
        <span class="icon-arrow-left text-xl" />
      </router-link>
      <h2 class="text-xl font-semibold text-n-slate-12 mb-0">
        Chi tiết sản phẩm
      </h2>
      <div v-if="product" class="ml-auto flex items-center gap-3">
        <span
          class="px-2.5 py-1 text-xs font-medium rounded-full whitespace-nowrap"
          :class="statusColor"
        >
          {{ formatStatus(product.status) }}
        </span>
        <Button
          :label="$t('SALES.MODULE_PRODUCTS.TABLE.ACTIONS.EDIT') || 'Chỉnh sửa'"
          icon="i-woot-settings"
          @click="
            $router.push({
              name: 'sales_products_edit',
              params: { id: product.id },
            })
          "
        />
      </div>
    </div>

    <div v-if="isLoading" class="p-8 flex items-center justify-center">
      <span class="icon-spin text-2xl text-n-slate-11 animate-spin" />
    </div>

    <div v-else-if="!product" class="p-8 text-center text-n-slate-11">
      <p>Không tìm thấy sản phẩm</p>
    </div>

    <div
      v-else
      class="p-8 max-w-5xl mx-auto w-full grid grid-cols-1 lg:grid-cols-3 gap-8"
    >
      <!-- Main Content Column -->
      <div class="lg:col-span-2 flex flex-col gap-6">
        <!-- Basic Info -->
        <div
          class="bg-n-alpha-1 rounded-xl p-6 border border-n-weak flex flex-col gap-5"
        >
          <h3 class="text-base font-semibold text-n-slate-12 m-0">
            Thông tin cơ bản
          </h3>

          <div>
            <label class="block text-xs text-n-slate-11 mb-1">{{
              $t('SALES.DIALOG_ADD_PRODUCT.FORM.NAME.LABEL') || 'Tên sản phẩm'
            }}</label>
            <p class="text-lg font-medium text-n-slate-12 mb-0">
              {{ product.name }}
            </p>
          </div>

          <div>
            <label class="block text-xs text-n-slate-11 mb-1">{{
              $t('SALES.DIALOG_ADD_PRODUCT.FORM.DESCRIPTION.LABEL') ||
              'Mô tả sản phẩm'
            }}</label>
            <div
              class="text-sm text-n-slate-12 p-3 bg-white dark:bg-slate-900 rounded-lg border border-n-weak min-h-[120px] whitespace-pre-wrap"
            >
              {{ product.description || 'Không có mô tả' }}
            </div>
          </div>
        </div>

        <!-- Pricing & Inventory -->
        <div
          class="bg-n-alpha-1 rounded-xl p-6 border border-n-weak flex flex-col gap-5"
        >
          <h3 class="text-base font-semibold text-n-slate-12 m-0">
            Giá bán & Phân loại
          </h3>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-xs text-n-slate-11 mb-1">{{
                $t('SALES.DIALOG_ADD_PRODUCT.FORM.PRICE.LABEL') || 'Giá bán'
              }}</label>
              <p class="text-lg font-medium text-n-slate-12 mb-0">
                {{ formatCurrency(product.price) }}
              </p>
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4 border-t border-n-weak pt-4">
            <div>
              <label class="block text-xs text-n-slate-11 mb-1">{{
                $t('SALES.DIALOG_ADD_PRODUCT.FORM.SKU.LABEL') || 'Mã SKU'
              }}</label>
              <p class="text-sm font-medium text-n-slate-12 mb-0">
                {{ product.sku || '--' }}
              </p>
            </div>

            <div>
              <label class="block text-xs text-n-slate-11 mb-1">{{
                $t('SALES.DIALOG_ADD_PRODUCT.FORM.BARCODE.LABEL') ||
                'Mã vạch (Barcode)'
              }}</label>
              <p class="text-sm font-medium text-n-slate-12 mb-0">
                {{ product.barcode || '--' }}
              </p>
            </div>
          </div>
        </div>
      </div>

      <!-- Side Column -->
      <div class="flex flex-col gap-6">
        <!-- System info -->
        <div
          class="bg-n-alpha-1 rounded-xl p-6 border border-n-weak flex flex-col gap-5"
        >
          <h3 class="text-base font-semibold text-n-slate-12 m-0">Hệ thống</h3>

          <div>
            <label class="block text-xs text-n-slate-11 mb-1">Ngày tạo</label>
            <p class="text-sm text-n-slate-12 mb-0">
              {{ formatDate(product.created_at) }}
            </p>
          </div>

          <div>
            <label class="block text-xs text-n-slate-11 mb-1"
              >Cập nhật lần cuối</label
            >
            <p class="text-sm text-n-slate-12 mb-0">
              {{ formatDate(product.updated_at) }}
            </p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
