<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import ProductCategoryBar from './ProductCategoryBar.vue';
import ProductCard from './ProductCard.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const searchQuery = ref('');
const selectedCategoryId = ref(null);
const currentPage = ref(0);
let searchTimer = null;

const currentConversation = useMapGetter('getSelectedChat');

const currentInbox = computed(() => {
  const inboxId = currentConversation.value?.inbox_id;
  if (!inboxId) return {};
  return store.getters['inboxes/getInbox'](inboxId);
});

const hasEcommerceIntegration = computed(() => {
  return !!currentInbox.value?.ecommerce_integration;
});

const products = computed(
  () => store.getters['conversationProducts/getProducts']
);
const categories = computed(
  () => store.getters['conversationProducts/getCategories']
);
const uiFlags = computed(
  () => store.getters['conversationProducts/getUIFlags']
);

const fetchCategories = () => {
  store.dispatch('conversationProducts/fetchCategories', {
    conversationId: props.conversationId,
  });
};

const fetchProducts = (page = 0) => {
  currentPage.value = page;
  store.dispatch('conversationProducts/fetchProducts', {
    conversationId: props.conversationId,
    query: searchQuery.value,
    categoryId: selectedCategoryId.value,
    page,
  });
};

const handleCategoryChange = categoryId => {
  selectedCategoryId.value = categoryId;
  fetchProducts(0);
};

const handleSearch = () => {
  clearTimeout(searchTimer);
  searchTimer = setTimeout(() => fetchProducts(0), 400);
};

const handleLoadMore = () => {
  fetchProducts(currentPage.value + 1);
};

onMounted(() => {
  if (hasEcommerceIntegration.value) {
    fetchCategories();
    fetchProducts(0);
  }
});

watch(
  () => props.conversationId,
  () => {
    if (hasEcommerceIntegration.value) {
      searchQuery.value = '';
      selectedCategoryId.value = null;
      fetchCategories();
      fetchProducts(0);
    }
  }
);

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

const handleAddToOrder = product => {
  emitter.emit(BUS_EVENTS.ADD_PRODUCT_TO_ORDER, product);
  useAlert(t('CONVERSATION.PRODUCT_PANEL.ADDED_TO_ORDER'));
};
</script>

<template>
  <div class="flex flex-col w-full h-full">
    <!-- No integration state -->
    <div
      v-if="!hasEcommerceIntegration"
      class="flex flex-col items-center justify-center py-12 px-6"
    >
      <div
        class="w-12 h-12 rounded-xl bg-n-solid-3 flex items-center justify-center mb-3"
      >
        <i class="i-lucide-unplug text-xl text-n-slate-10" />
      </div>
      <p
        class="text-xs text-n-slate-10 text-center leading-relaxed max-w-[200px]"
      >
        {{ t('CONVERSATION.PRODUCT_PANEL.NO_INTEGRATION') }}
      </p>
    </div>

    <!-- Products view -->
    <template v-else>
      <!-- Search -->
      <div class="px-3 pt-3 pb-2">
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

      <!-- Categories -->
      <ProductCategoryBar
        v-if="categories && categories.length"
        :categories="categories"
        :selected-id="selectedCategoryId"
        :is-loading="uiFlags.isFetchingCategories"
        @select="handleCategoryChange"
      />

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
          <div v-if="products && products.length >= 20" class="flex justify-center pt-2">
            <Button
              :label="t('CONVERSATION.PRODUCT_PANEL.LOAD_MORE')"
              xs
              faded
              :is-loading="uiFlags.isFetching && currentPage > 0"
              @click="handleLoadMore"
            />
          </div>
        </div>

        <!-- Empty -->
        <div v-else class="flex flex-col items-center py-8 px-4">
          <div
            class="w-10 h-10 rounded-xl bg-n-solid-3 flex items-center justify-center mb-2.5"
          >
            <i class="i-lucide-package-search text-base text-n-slate-10" />
          </div>
          <p class="text-xs text-n-slate-10 text-center">
            {{ t('CONVERSATION.PRODUCT_PANEL.NO_PRODUCTS') }}
          </p>
        </div>
      </div>
    </template>
  </div>
</template>
