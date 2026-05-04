<script setup>
import { useI18n } from 'vue-i18n';

defineProps({
  product: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const PLATFORM_LABELS = {
  kiotviet: 'KiotViet',
  sapo: 'Sapo',
  haravan: 'Haravan',
  shopify: 'Shopify',
  woocommerce: 'WooCommerce',
  nhanhvn: 'Nhanh.vn',
  tiktok_shop: 'TikTok Shop',
};

const formatCurrency = amount =>
  new Intl.NumberFormat('vi-VN').format(amount || 0);
</script>

<template>
  <div
    class="group flex gap-3 p-2.5 rounded-xl border border-n-weak bg-n-solid-1 hover:bg-n-alpha-1 transition-colors cursor-pointer"
  >
    <!-- Thumbnail -->
    <div
      class="w-12 h-12 rounded-lg bg-n-solid-3 flex items-center justify-center shrink-0 overflow-hidden"
    >
      <img
        v-if="product.thumbnail"
        :src="product.thumbnail"
        :alt="product.name"
        class="w-full h-full object-cover"
      />
      <i v-else class="i-lucide-package text-base text-n-slate-10" />
    </div>

    <!-- Info -->
    <div class="flex-1 min-w-0">
      <p
        class="text-sm font-medium text-n-slate-12 truncate leading-snug"
        :title="product.name"
      >
        {{ product.name }}
      </p>
      <div class="flex items-center gap-2 mt-0.5">
        <span class="text-sm font-semibold text-n-brand">
          <!-- eslint-disable-next-line vue/no-bare-strings-in-template -->
          {{ formatCurrency(product.price) }}đ
        </span>
        <span
          v-if="product.in_stock !== undefined"
          class="text-xs"
          :class="product.in_stock ? 'text-n-emerald-11' : 'text-n-ruby-11'"
        >
          {{
            product.in_stock
              ? t('CONVERSATION.PRODUCT_PANEL.IN_STOCK')
              : t('CONVERSATION.PRODUCT_PANEL.OUT_OF_STOCK')
          }}
        </span>
      </div>
      <span
        v-if="product.source"
        class="inline-flex mt-1 px-1.5 py-0.5 rounded bg-n-solid-3 text-[10px] text-n-slate-10"
      >
        {{ PLATFORM_LABELS[product.source] || product.source }}
      </span>
    </div>
  </div>
</template>
