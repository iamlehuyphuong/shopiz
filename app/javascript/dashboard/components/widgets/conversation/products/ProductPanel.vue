<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import { useRouter } from 'vue-router';
import ProductCard from './ProductCard.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const PLATFORM_LABELS = {
  shopiz: 'Shopiz',
  kiotviet: 'KiotViet',
  sapo: 'Sapo',
  haravan: 'Haravan',
  shopify: 'Shopify',
  woocommerce: 'WooCommerce',
  nhanhvn: 'Nhanh.vn',
  tiktok_shop: 'TikTok Shop',
};

const { t } = useI18n();
const store = useStore();
const router = useRouter();

const searchQuery = ref('');
const currentPage = ref(0);
let searchTimer = null;

const account = computed(() =>
  store.getters['accounts/getAccount'](store.getters.getCurrentAccountId)
);

const sourceFilter = computed(
  () => account.value?.settings?.active_ecommerce_platform || 'shopiz'
);

const activeSourceName = computed(
  () => PLATFORM_LABELS[sourceFilter.value] || sourceFilter.value
);

const products = computed(
  () => store.getters['conversationProducts/getProducts']
);
const uiFlags = computed(
  () => store.getters['conversationProducts/getUIFlags']
);

const fetchProducts = (page = 0) => {
  currentPage.value = page;
  store.dispatch('conversationProducts/fetchProducts', {
    conversationId: props.conversationId,
    query: searchQuery.value,
    page,
    source: sourceFilter.value,
  });
};

const handleSearch = () => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => fetchProducts(0), 400);
};

const handleLoadMore = () => {
  fetchProducts(currentPage.value + 1);
};

onMounted(() => {
  fetchProducts(0);
});

watch(
  () => props.conversationId,
  () => {
    searchQuery.value = '';
    fetchProducts(0);
  }
);

watch(sourceFilter, () => {
  searchQuery.value = '';
  fetchProducts(0);
});

const formatProductText = product => {
  const price = new Intl.NumberFormat('vi-VN').format(product.price || 0);
  let text = `${product.name}\nGiá: ${price}đ`;
  if (product.thumbnail) {
    text += `\n${product.thumbnail}`;
  }
  return text;
};

const handleSendToChat = product => {
  const text = formatProductText(product);
  emitter.emit(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, text);
  useAlert(t('CONVERSATION.PRODUCT_PANEL.PRODUCT_INSERTED'));
};

const goToProductList = () => {
  router.push({ name: 'sales_products_list' });
};

const handleAddToOrder = product => {
  emitter.emit(BUS_EVENTS.ADD_PRODUCT_TO_ORDER, product);
  useAlert(t('CONVERSATION.PRODUCT_PANEL.ADDED_TO_ORDER'));
};
</script>

<template>
  <div class="flex flex-col w-full h-full">
    <!-- Search -->
    <div class="px-3 pt-3 pb-2 flex flex-col gap-2">
      <span class="text-sm font-medium text-n-slate-12">
        {{ $t('CONVERSATION.PRODUCT_PANEL.TITLE') }} ({{ activeSourceName }})
      </span>
      <div
        class="flex items-center gap-2 px-3 py-2 rounded-lg border border-n-weak bg-n-solid-1 focus-within:border-n-brand/50 transition-colors"
      >
        <i class="i-lucide-search text-sm text-n-slate-10 shrink-0" />
        <input
          v-model="searchQuery"
          class="flex-1 text-sm bg-transparent outline-none text-n-slate-12 placeholder:text-n-slate-9"
          :placeholder="t('CONVERSATION.PRODUCT_PANEL.SEARCH')"
          @input="handleSearch"
        />
        <i
          v-if="searchQuery"
          class="i-lucide-x text-sm text-n-slate-10 cursor-pointer hover:text-n-slate-12 transition-colors"
          @click="
            searchQuery = '';
            fetchProducts(0);
          "
        />
      </div>
    </div>

    <!-- Products list -->
    <div class="flex-1 overflow-y-auto px-3 pb-6">
      <!-- Loading -->
      <div
        v-if="uiFlags.isFetching && currentPage === 0"
        class="flex items-center justify-center py-8"
      >
        <i class="i-lucide-loader-2 text-n-slate-10 animate-spin text-lg" />
      </div>

      <!-- Products -->
      <div v-else-if="products && products.length" class="flex flex-col gap-2">
        <ProductCard
          v-for="product in products"
          :key="`${product.source}-${product.id}`"
          :product="product"
          @send-to-chat="handleSendToChat"
          @add-to-order="handleAddToOrder"
        />

        <!-- Load more -->
        <div
          v-if="products && products.length >= 20"
          class="flex justify-center pt-2"
        >
          <Button
            :label="t('CONVERSATION.PRODUCT_PANEL.LOAD_MORE')"
            xs
            faded
            :is-loading="uiFlags.isFetching && currentPage > 0"
            @click="handleLoadMore"
          />
        </div>
      </div>

      <!-- Empty (Unsynced or No products) -->
      <div v-else class="flex flex-col items-center py-8 px-4">
        <template v-if="uiFlags.hasSyncedData === false">
          <div
            class="w-10 h-10 rounded-xl bg-n-brand/10 flex items-center justify-center mb-3"
          >
            <i class="i-lucide-refresh-cw text-base text-n-brand" />
          </div>
          <p class="text-sm font-medium text-n-slate-12 mb-1 text-center">
            Chưa đồng bộ sản phẩm
          </p>
          <p class="text-xs text-n-slate-10 text-center mb-4 leading-relaxed">
            Sản phẩm từ {{ activeSourceName }} chưa được đồng bộ vào hệ thống. Vui lòng đồng bộ để có thể gửi cho khách hàng.
          </p>
          <Button
            label="Đồng bộ ngay"
            icon="i-lucide-arrow-right"
            icon-position="right"
            size="sm"
            @click="goToProductList"
          />
        </template>
        <template v-else>
          <div
            class="w-10 h-10 rounded-xl bg-n-solid-3 flex items-center justify-center mb-2.5"
          >
            <i class="i-lucide-package-search text-base text-n-slate-10" />
          </div>
          <p class="text-xs text-n-slate-10 text-center">
            {{ t('CONVERSATION.PRODUCT_PANEL.NO_PRODUCTS') }}
          </p>
        </template>
      </div>
    </div>
  </div>
</template>
