<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import AccordionItem from 'dashboard/components/Accordion/AccordionItem.vue';
import ProductSearch from './ProductSearch.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  contact: {
    type: Object,
    default: () => ({}),
  },
  order: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['close', 'saved']);

const { t } = useI18n();
const store = useStore();

const isEditing = computed(() => !!props.order);

const currentConversation = useMapGetter('getSelectedChat');

// Auto-detect ecommerce platform from inbox integration
const inboxEcommerceAppId = computed(() => {
  const inbox = currentConversation.value?.inbox;
  if (!inbox) return '';
  return inbox.ecommerce_integration?.app_id || '';
});

const isSourceLocked = computed(
  () => inboxEcommerceAppId.value !== '' || isEditing.value
);

const form = ref({
  status: 'draft',
  external_source: '',
  customer_name: '',
  customer_phone: '',
  customer_address: '',
  customer_note: '',
  items: [],
});

const STATUS_OPTIONS = [
  'draft',
  'confirmed',
  'processing',
  'shipped',
  'delivered',
  'cancelled',
];

const PLATFORM_OPTIONS = [
  { value: '', label: '—' },
  { value: 'kiotviet', label: 'KiotViet' },
  { value: 'sapo', label: 'Sapo' },
  { value: 'haravan', label: 'Haravan' },
  { value: 'shopify', label: 'Shopify' },
  { value: 'woocommerce', label: 'WooCommerce' },
  { value: 'nhanhvn', label: 'Nhanh.vn' },
  { value: 'tiktok_shop', label: 'TikTok Shop' },
];

onMounted(() => {
  if (isEditing.value) {
    form.value = {
      status: props.order.status,
      external_source: props.order.external_source || '',
      customer_name: props.order.customer_name || '',
      customer_phone: props.order.customer_phone || '',
      customer_address: props.order.customer_address || '',
      customer_note: props.order.customer_note || '',
      items: (props.order.items || []).map(item => ({ ...item })),
    };
  } else {
    form.value.customer_name = props.contact?.name || '';
    form.value.customer_phone = props.contact?.phone_number || '';
    form.value.customer_address =
      props.contact?.additional_attributes?.address || '';
    // Auto-fill from inbox ecommerce integration
    if (inboxEcommerceAppId.value) {
      form.value.external_source = inboxEcommerceAppId.value;
    }
  }
});

const totalAmount = computed(() =>
  form.value.items.reduce(
    (sum, item) => sum + (item.quantity || 0) * (item.unit_price || 0),
    0
  )
);

const formatCurrency = amount => new Intl.NumberFormat('vi-VN').format(amount);

const addProduct = product => {
  const existingIndex = form.value.items.findIndex(
    item =>
      item.product_id === product.id && item.product_source === product.source
  );
  if (existingIndex >= 0) {
    form.value.items[existingIndex].quantity += 1;
    return;
  }
  form.value.items.push({
    product_name: product.name,
    product_id: product.id,
    product_source: product.source,
    quantity: 1,
    unit_price: product.price || 0,
    product_thumbnail: product.thumbnail,
  });
};

const addManualItem = () => {
  form.value.items.push({
    product_name: '',
    product_id: null,
    product_source: 'manual',
    quantity: 1,
    unit_price: 0,
    product_thumbnail: null,
  });
};

const removeItem = index => {
  form.value.items.splice(index, 1);
};

const isSaving = computed(
  () =>
    store.getters['conversationOrders/getUIFlags'].isCreating ||
    store.getters['conversationOrders/getUIFlags'].isUpdating
);

const canSave = computed(
  () =>
    form.value.items.length > 0 && form.value.items.every(i => i.product_name)
);

const handleSave = async () => {
  const orderData = {
    status: form.value.status,
    external_source: form.value.external_source || undefined,
    customer_name: form.value.customer_name,
    customer_phone: form.value.customer_phone,
    customer_address: form.value.customer_address,
    customer_note: form.value.customer_note,
    items_attributes: form.value.items.map(item => ({
      id: item.id || undefined,
      product_name: item.product_name,
      product_id: item.product_id,
      product_source: item.product_source,
      quantity: item.quantity,
      unit_price: item.unit_price,
      product_thumbnail: item.product_thumbnail,
      _destroy: item._destroy || false,
    })),
  };

  try {
    if (isEditing.value) {
      await store.dispatch('conversationOrders/update', {
        conversationId: props.conversationId,
        orderId: props.order.id,
        orderData,
      });
    } else {
      await store.dispatch('conversationOrders/create', {
        conversationId: props.conversationId,
        orderData,
      });
    }
    emit('saved');
  } catch {
    // error handled by store
  }
};

const isSectionOpen = ref({
  status: true,
  products: true,
  customer: true,
});

const toggleSection = key => {
  isSectionOpen.value[key] = !isSectionOpen.value[key];
};
</script>

<template>
  <div class="flex flex-col h-full w-full">
    <!-- Header - matches contact panel style -->
    <div
      class="flex items-center gap-2 px-4 py-3 border-b border-n-weak shrink-0"
    >
      <button
        class="p-1 rounded-md hover:bg-n-alpha-2 text-n-slate-10 hover:text-n-slate-12 transition-colors"
        @click="emit('close')"
      >
        <i class="i-lucide-arrow-left text-sm" />
      </button>
      <h3 class="text-sm font-medium text-n-slate-12">
        {{
          isEditing
            ? t('CONVERSATION.ORDER_PANEL.EDIT_ORDER')
            : t('CONVERSATION.ORDER_PANEL.NEW_ORDER')
        }}
      </h3>
    </div>

    <!-- Form Body - matches contact panel's accordion layout -->
    <div class="flex-1 overflow-y-auto px-2 pb-8 pt-3">
      <div class="flex flex-col gap-3">
        <!-- Status Accordion -->
        <AccordionItem
          :title="t('CONVERSATION.ORDER_PANEL.STATUS_LABEL')"
          :is-open="isSectionOpen.status"
          compact
          @toggle="toggleSection('status')"
        >
          <div class="px-3 py-3 space-y-2.5">
            <select
              v-model="form.status"
              class="w-full px-3 py-1.5 text-sm rounded-lg border border-n-weak bg-n-alpha-1 hover:bg-n-alpha-2 transition-colors text-n-slate-12 outline-none focus:border-n-brand focus:bg-n-solid-1 focus:ring-1 focus:ring-n-brand/30 cursor-pointer appearance-none"
              style="
                background-image: url('data:image/svg+xml;charset=UTF-8,%3csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%2394a3b8%22 stroke-width=%222%22%3e%3cpath d=%22m6 9 6 6 6-6%22/%3e%3c/svg%3e');
                background-repeat: no-repeat;
                background-position: right 0.5rem center;
                background-size: 1.25rem;
              "
            >
              <option v-for="s in STATUS_OPTIONS" :key="s" :value="s">
                {{ t(`CONVERSATION.ORDER_PANEL.STATUS.${s.toUpperCase()}`) }}
              </option>
            </select>
            <select
              v-if="!isSourceLocked"
              v-model="form.external_source"
              class="w-full px-3 py-1.5 text-sm rounded-lg border border-n-weak bg-n-alpha-1 hover:bg-n-alpha-2 transition-colors text-n-slate-12 outline-none focus:border-n-brand focus:bg-n-solid-1 focus:ring-1 focus:ring-n-brand/30 appearance-none cursor-pointer"
              style="
                background-image: url('data:image/svg+xml;charset=UTF-8,%3csvg xmlns=%22http://www.w3.org/2000/svg%22 viewBox=%220 0 24 24%22 fill=%22none%22 stroke=%22%2394a3b8%22 stroke-width=%222%22%3e%3cpath d=%22m6 9 6 6 6-6%22/%3e%3c/svg%3e');
                background-repeat: no-repeat;
                background-position: right 0.5rem center;
                background-size: 1.25rem;
              "
            >
              <option
                v-for="platform in PLATFORM_OPTIONS"
                :key="platform.value"
                :value="platform.value"
              >
                {{ platform.label }}
              </option>
            </select>
          </div>
        </AccordionItem>

        <!-- Products Accordion -->
        <AccordionItem
          :title="t('CONVERSATION.ORDER_PANEL.PRODUCTS')"
          :is-open="isSectionOpen.products"
          compact
          @toggle="toggleSection('products')"
        >
          <div class="px-3 py-3">
            <ProductSearch
              :conversation-id="conversationId"
              @select-product="addProduct"
            />

            <!-- Items List -->
            <div v-if="form.items.length" class="mt-3 space-y-2">
              <div
                v-for="(item, index) in form.items"
                :key="index"
                class="flex flex-col gap-2 p-2.5 rounded-lg bg-n-solid-2 border border-n-weak"
              >
                <!-- Row 1: Tên sản phẩm & Nút xoá -->
                <div class="flex items-start gap-2">
                  <input
                    v-model="item.product_name"
                    type="text"
                    :placeholder="t('CONVERSATION.ORDER_PANEL.PRODUCT_NAME')"
                    class="flex-1 w-full text-sm text-n-slate-12 bg-n-solid-1 border border-n-weak rounded-md px-2.5 py-1.5 outline-none font-medium placeholder:text-n-slate-9 focus:border-n-brand focus:ring-1 focus:ring-n-brand/30 transition-shadow"
                  />
                  <button
                    class="shrink-0 p-1.5 rounded-md hover:bg-n-ruby-3 text-n-slate-10 hover:text-n-ruby-11 transition-colors"
                    @click="removeItem(index)"
                  >
                    <i class="i-lucide-trash-2 text-sm" />
                  </button>
                </div>
                
                <!-- Row 2: Số lượng & Giá -->
                <div class="flex items-center gap-3">
                  <div class="flex items-center gap-2 w-1/3">
                    <label class="text-xs text-n-slate-10 shrink-0">{{ t('CONVERSATION.ORDER_PANEL.QUANTITY') }}:</label>
                    <input
                      v-model.number="item.quantity"
                      type="number"
                      min="1"
                      class="w-full text-xs text-center rounded-md border border-n-weak bg-n-solid-1 text-n-slate-12 py-1 px-2 outline-none focus:border-n-brand focus:ring-1 focus:ring-n-brand/30 transition-shadow"
                    />
                  </div>
                  <div class="flex items-center gap-2 flex-1">
                    <label class="text-xs text-n-slate-10 shrink-0">{{ t('CONVERSATION.ORDER_PANEL.PRICE') }}:</label>
                    <input
                      v-model.number="item.unit_price"
                      type="number"
                      min="0"
                      class="w-full text-xs rounded-md border border-n-weak bg-n-solid-1 text-n-slate-12 py-1 px-2 outline-none focus:border-n-brand focus:ring-1 focus:ring-n-brand/30 transition-shadow"
                    />
                  </div>
                </div>
              </div>
            </div>

            <button
              class="mt-2.5 flex items-center gap-1.5 text-xs font-medium text-n-brand hover:text-n-brand/80 transition-colors py-1"
              @click="addManualItem"
            >
              <i class="i-lucide-plus text-xs" />
              {{ t('CONVERSATION.ORDER_PANEL.ADD_MANUAL') }}
            </button>

            <!-- Total -->
            <div
              v-if="form.items.length"
              class="flex justify-between items-center py-2.5 px-3 mt-2 rounded-lg bg-n-solid-3 border border-n-weak"
            >
              <span class="text-sm font-medium text-n-slate-11">
                {{ t('CONVERSATION.ORDER_PANEL.TOTAL') }}
              </span>
              <span class="text-sm font-bold text-n-slate-12">
                {{ formatCurrency(totalAmount) }}đ
              </span>
            </div>
          </div>
        </AccordionItem>

        <!-- Customer Info Accordion -->
        <AccordionItem
          :title="t('CONVERSATION.ORDER_PANEL.CUSTOMER_INFO')"
          :is-open="isSectionOpen.customer"
          compact
          @toggle="toggleSection('customer')"
        >
          <div class="px-3 py-3 space-y-2.5">
            <input
              v-model="form.customer_name"
              type="text"
              :placeholder="t('CONVERSATION.ORDER_PANEL.CUSTOMER_NAME')"
              class="w-full px-3 py-1.5 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12 placeholder:text-n-slate-9 outline-none focus:border-n-brand focus:ring-1 focus:ring-n-brand/30"
            />
            <input
              v-model="form.customer_phone"
              type="tel"
              :placeholder="t('CONVERSATION.ORDER_PANEL.PHONE')"
              class="w-full px-3 py-1.5 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12 placeholder:text-n-slate-9 outline-none focus:border-n-brand focus:ring-1 focus:ring-n-brand/30"
            />
            <textarea
              v-model="form.customer_address"
              :placeholder="t('CONVERSATION.ORDER_PANEL.ADDRESS')"
              rows="2"
              class="w-full px-3 py-1.5 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12 placeholder:text-n-slate-9 outline-none focus:border-n-brand focus:ring-1 focus:ring-n-brand/30 resize-none leading-relaxed"
            ></textarea>
            <textarea
              v-model="form.customer_note"
              :placeholder="t('CONVERSATION.ORDER_PANEL.NOTE')"
              rows="2"
              class="w-full px-3 py-1.5 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12 placeholder:text-n-slate-9 outline-none focus:border-n-brand focus:ring-1 focus:ring-n-brand/30 resize-none leading-relaxed"
            ></textarea>
          </div>
        </AccordionItem>
      </div>
    </div>

    <!-- Footer -->
    <div
      class="flex items-center justify-end gap-2 px-4 py-3 border-t border-n-weak shrink-0"
    >
      <Button
        :label="t('CONVERSATION.ORDER_PANEL.CANCEL')"
        ghost
        sm
        slate
        @click="emit('close')"
      />
      <Button
        :label="
          isEditing
            ? t('CONVERSATION.ORDER_PANEL.UPDATE')
            : t('CONVERSATION.ORDER_PANEL.SAVE')
        "
        sm
        :disabled="!canSave || isSaving"
        :is-loading="isSaving"
        @click="handleSave"
      />
    </div>
  </div>
</template>
