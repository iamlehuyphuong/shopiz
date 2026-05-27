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
    flowify: 'Flowify',
    helpcenter: 'Help Center',
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
    <div class="relative">
      <input
        v-model="searchQuery"
        type="text"
        :placeholder="t('CONVERSATION.ORDER_PANEL.PRODUCT_SEARCH')"
        class="w-full px-3 pr-8 py-1.5 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12 placeholder:text-n-slate-9 outline-none focus:border-n-brand focus:ring-1 focus:ring-n-brand/30 transition-all"
      />
      <fluent-icon
        v-if="isSearching"
        icon="spinner"
        size="16"
        class="absolute right-3 top-1/2 -translate-y-1/2 text-n-slate-10 animate-spin"
      />
      <button
        v-else-if="searchQuery.length > 0"
        class="absolute right-2 top-1/2 -translate-y-1/2 p-0.5 rounded hover:bg-n-alpha-2 text-n-slate-10 hover:text-n-slate-12 transition-colors"
        @click="
          searchQuery = '';
          results = [];
        "
      >
        <fluent-icon icon="dismiss" size="12" />
      </button>
    </div>

    <!-- Results -->
    <div
      v-if="results.length > 0"
      class="max-h-48 overflow-y-auto rounded-lg border border-n-weak bg-n-solid-1 divide-y divide-n-weak"
    >
      <template v-for="(products, source) in groupedResults" :key="source">
        <div
          class="px-3 py-1.5 bg-n-solid-2 text-xs font-medium text-n-slate-10 uppercase tracking-wider"
        >
          {{ sourceLabel(source) }}
        </div>
        <button
          v-for="product in products"
          :key="product.id"
          class="w-full flex items-center gap-2.5 px-3 py-2 hover:bg-n-alpha-1 transition-colors text-left"
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
            <div v-if="product.price" class="text-xs text-n-slate-10">
              {{ formatPrice(product.price) }}đ
            </div>
          </div>
          <i class="i-lucide-plus text-n-slate-10 text-sm shrink-0" />
        </button>
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
