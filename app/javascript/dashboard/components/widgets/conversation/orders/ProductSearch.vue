<script setup>
import { computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import ConversationOrdersAPI from 'dashboard/api/conversationOrders';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const emit = defineEmits(['select-product']);

const { t } = useI18n();
const searchQuery = ref('');
const results = ref([]);
const isSearching = ref(false);
const searchTimeout = ref(null);

const groupedResults = computed(() => {
  const groups = {};
  results.value.forEach(product => {
    const source = product.source || 'other';
    if (!groups[source]) {
      groups[source] = [];
    }
    groups[source].push(product);
  });
  return groups;
});

const sourceLabel = source => {
  const labels = {
    shopify: 'Shopify',
    kiotviet: 'KiotViet',
    haravan: 'Haravan',
    sapo: 'Sapo',
    woocommerce: 'WooCommerce',
    nhanhvn: 'NhanhVN',
    shopiz: 'Shopiz',
    other: 'Other',
  };
  return labels[source] || source;
};

const performSearch = async () => {
  if (searchQuery.value.length < 2) {
    results.value = [];
    return;
  }
  isSearching.value = true;
  try {
    const { data } = await ConversationOrdersAPI.searchProducts(
      searchQuery.value,
      props.conversationId
    );
    results.value = data.products || [];
  } catch {
    results.value = [];
  } finally {
    isSearching.value = false;
  }
};

const debouncedSearch = () => {
  clearTimeout(searchTimeout.value);
  searchTimeout.value = setTimeout(performSearch, 400);
};

watch(searchQuery, debouncedSearch);

const selectProduct = product => {
  emit('select-product', product);
  searchQuery.value = '';
  results.value = [];
};

const formatPrice = price => {
  if (!price) return '';
  return new Intl.NumberFormat('vi-VN').format(price);
};
</script>

<template>
  <div class="flex flex-col gap-2">
    <div
      class="flex items-center w-full h-[38px] px-3 rounded-lg border border-n-weak bg-white dark:bg-n-solid-1 focus-within:border-n-brand focus-within:ring-1 focus-within:ring-n-brand/30 transition-all"
    >
      <i class="i-lucide-search text-n-slate-10 text-base shrink-0" />
      <input
        v-model="searchQuery"
        type="text"
        :placeholder="t('CONVERSATION.ORDER_PANEL.PRODUCT_SEARCH')"
        class="flex-1 w-full h-full !px-3 !py-0 text-sm !bg-transparent !border-none !outline-none !shadow-none !ring-0 text-n-slate-12 placeholder:text-n-slate-9 !m-0 !leading-normal"
      />
      <div class="flex items-center shrink-0">
        <i
          v-if="isSearching"
          class="i-lucide-loader-2 text-n-slate-10 animate-spin text-base"
        />
        <button
          v-else-if="searchQuery.length > 0"
          class="p-1 rounded hover:bg-n-alpha-2 text-n-slate-10 hover:text-n-slate-12 transition-colors flex items-center justify-center"
          @click="
            searchQuery = '';
            results = [];
          "
        >
          <i class="i-lucide-x text-sm" />
        </button>
      </div>
    </div>

    <!-- Results -->
    <div
      v-if="results.length > 0"
      class="max-h-64 overflow-y-auto rounded-lg border border-n-weak bg-white dark:bg-slate-900 shadow-md"
    >
      <template v-for="(products, source) in groupedResults" :key="source">
        <div
          class="px-4 py-2 bg-n-solid-2 text-xs font-medium text-n-slate-10 uppercase tracking-wider"
        >
          {{ sourceLabel(source) }}
        </div>
        <div class="p-1.5 space-y-0.5">
          <button
            v-for="product in products"
            :key="product.id"
            class="w-full flex items-center gap-3 px-2.5 py-2 rounded-md hover:bg-n-alpha-1 transition-colors text-left"
            @click="selectProduct(product)"
          >
            <img
              v-if="product.thumbnail"
              :src="product.thumbnail"
              :alt="product.name"
              class="w-8 h-8 rounded object-cover shrink-0 bg-n-solid-3"
            />
            <div
              v-else
              class="w-8 h-8 rounded bg-n-solid-3 flex items-center justify-center shrink-0"
            >
              <i class="i-lucide-package text-n-slate-10 text-xs" />
            </div>
            <div class="flex-1 min-w-0">
              <div class="text-sm text-n-slate-12 truncate">
                {{ product.name }}
              </div>
              <div v-if="product.price" class="text-xs text-n-slate-10 mt-0.5">
                {{ formatPrice(product.price) }}đ
              </div>
            </div>
          </button>
        </div>
      </template>
    </div>

    <div
      v-else-if="
        searchQuery.length >= 2 && !isSearching && results.length === 0
      "
      class="text-center py-3 text-sm text-n-slate-10"
    >
      {{ t('CONVERSATION.ORDER_PANEL.NO_PRODUCTS') }}
    </div>
  </div>
</template>
