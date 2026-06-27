<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import ProductSearch from './ProductSearch.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import MultiselectDropdown from 'shared/components/ui/MultiselectDropdown.vue';
import SalesOrdersAPI from 'dashboard/api/sales/orders';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: false,
  },
  contact: {
    type: Object,
    default: () => ({}),
  },
  order: {
    type: Object,
    default: null,
  },
  initialProduct: {
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
const currentInbox = computed(() => {
  const inboxId = currentConversation.value?.inbox_id;
  if (!inboxId) return {};
  return store.getters['inboxes/getInbox'](inboxId);
});

const inboxEcommerceAppId = computed(() => {
  if (currentInbox.value?.sales_config?.platform === 'shopiz') {
    return 'shopiz';
  }
  return currentInbox.value?.ecommerce_integration?.app_id || '';
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
  shipping_fee: 0,
  tax: 0,
  discount_amount: 0,
  payment_method: 'cod',
  payment_status: 'unpaid',
  contact_id: null,
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

const statusOptionsList = computed(() => {
  return STATUS_OPTIONS.map(s => ({
    id: s,
    name: t(`CONVERSATION.ORDER_PANEL.STATUS.${s.toUpperCase()}`)
  }));
});

const selectedStatus = computed(() => {
  return statusOptionsList.value.find(s => s.id === form.value.status) || statusOptionsList.value[0];
});

const paymentMethodOptionsList = computed(() => [
  { id: 'cod', name: 'COD' },
  { id: 'bank_transfer', name: 'Chuyển khoản' },
  { id: 'card', name: 'Thẻ / Ví điện tử' },
]);

const selectedPaymentMethod = computed(() => {
  return paymentMethodOptionsList.value.find(s => s.id === form.value.payment_method) || paymentMethodOptionsList.value[0];
});

const paymentStatusOptionsList = computed(() => [
  { id: 'unpaid', name: t('CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.UNPAID') },
  { id: 'paid', name: t('CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.PAID') },
  { id: 'partially_refunded', name: t('CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.PARTIALLY_REFUNDED') },
]);

const selectedPaymentStatus = computed(() => {
  return paymentStatusOptionsList.value.find(s => s.id === form.value.payment_status) || paymentStatusOptionsList.value[0];
});

const PLATFORM_OPTIONS = [
  { value: '', label: '—' },
  { value: 'kiotviet', label: 'KiotViet' },
  { value: 'sapo', label: 'Sapo' },
  { value: 'haravan', label: 'Haravan' },
  { value: 'shopify', label: 'Shopify' },
  { value: 'woocommerce', label: 'WooCommerce' },
  { value: 'nhanhvn', label: 'Nhanh.vn' },
  { value: 'tiktok_shop', label: 'TikTok Shop' },
  { value: 'shopiz', label: 'Shopiz' },
];

watch(
  () => props.contact,
  newContact => {
    if (!isEditing.value) {
      if (!form.value.customer_name)
        form.value.customer_name = newContact?.name || '';
      if (!form.value.customer_phone)
        form.value.customer_phone = newContact?.phone_number || '';
      if (!form.value.customer_address) {
        const attrs = newContact?.additional_attributes || {};
        form.value.customer_address =
          attrs.address ||
          [attrs.city, attrs.country].filter(Boolean).join(', ') ||
          '';
      }
      if (!form.value.contact_id && newContact?.id) {
        form.value.contact_id = newContact.id;
      }
      // Auto-fill from inbox ecommerce integration
      if (inboxEcommerceAppId.value && !form.value.external_source) {
        form.value.external_source = inboxEcommerceAppId.value;
      }
    }
  },
  { immediate: true, deep: true }
);

const addProduct = product => {
  const existingIndex = form.value.items.findIndex(
    item =>
      String(item.product_id) === String(product.id) &&
      String(item.product_source) === String(product.source)
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
    tax_rate: product.tax_rate || 0,
    product_thumbnail: product.thumbnail,
  });
};

const formatCurrencyValue = val => {
  if (val === null || val === undefined || val === '') return '';
  return new Intl.NumberFormat('vi-VN').format(val);
};

const parseCurrencyValue = val => {
  if (!val) return 0;
  const num = parseInt(val.toString().replace(/\D/g, ''), 10);
  return isNaN(num) ? 0 : num;
};

watch(
  () => props.order,
  newOrder => {
    if (newOrder && isEditing.value) {
      form.value = {
        status: newOrder.status,
        external_source: newOrder.external_source || '',
        customer_name: newOrder.customer_name || '',
        customer_phone: newOrder.customer_phone || '',
        customer_address: newOrder.customer_address || '',
        customer_note: newOrder.customer_note || '',
        shipping_fee: newOrder.shipping_fee || 0,
        tax: newOrder.tax || 0,
        discount_amount: newOrder.discount_amount || 0,
        payment_method: newOrder.payment_method || 'cod',
        payment_status: newOrder.payment_status || 'unpaid',
        items: (newOrder.items || []).map(item => ({ 
          ...item, 
          tax_rate: (item.product_metadata && item.product_metadata.tax_rate) || 0 
        })),
      };
    }
  },
  { immediate: true }
);

watch(
  () => form.value.items,
  newItems => {
    form.value.tax = newItems.reduce((sum, item) => {
      const itemTax = ((item.quantity || 0) * (item.unit_price || 0) * (item.tax_rate || 0)) / 100;
      return sum + itemTax;
    }, 0);
  },
  { deep: true }
);

watch(
  () => props.initialProduct,
  newProduct => {
    if (newProduct) {
      addProduct(newProduct);
    }
  },
  { immediate: true }
);

const totalAmount = computed(() => {
  const subtotal = form.value.items.reduce(
    (sum, item) => sum + (item.quantity || 0) * (item.unit_price || 0),
    0
  );
  return (
    subtotal +
    (form.value.shipping_fee || 0) +
    (form.value.tax || 0) -
    (form.value.discount_amount || 0)
  );
});

const formatCurrency = amount => new Intl.NumberFormat('vi-VN').format(amount);

const addManualItem = () => {
  form.value.items.push({
    product_name: '',
    product_id: null,
    product_source: 'manual',
    quantity: 1,
    unit_price: 0,
    tax_rate: 0,
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

const canSave = computed(() => {
  const hasItems =
    form.value.items.length > 0 && form.value.items.every(i => i.product_name);
  if (!props.conversationId && !form.value.contact_id) {
    return false; // Require contact when creating standalone order
  }
  return hasItems;
});

const handleSave = async () => {
  const orderData = {
    status: form.value.status,
    external_source: form.value.external_source || undefined,
    customer_name: form.value.customer_name,
    customer_phone: form.value.customer_phone,
    customer_address: form.value.customer_address,
    customer_note: form.value.customer_note,
    contact_id: form.value.contact_id || undefined,
    shipping_fee: form.value.shipping_fee,
    tax: form.value.tax,
    discount_amount: form.value.discount_amount,
    payment_method: form.value.payment_method,
    payment_status: form.value.payment_status,
    items_attributes: form.value.items.map(item => ({
      id: item.id || undefined,
      product_name: item.product_name,
      product_id: item.product_id,
      product_source: item.product_source,
      variant_id: item.variant_id,
      quantity: item.quantity,
      unit_price: item.unit_price,
      product_metadata: {
        ...(item.product_metadata || {}),
        tax_rate: item.tax_rate || 0,
      },
      product_thumbnail: item.product_thumbnail,
      _destroy: item._destroy || false,
    })),
  };

  try {
    if (isEditing.value) {
      if (props.conversationId) {
        await store.dispatch('conversationOrders/update', {
          conversationId: props.conversationId,
          orderId: props.order.id,
          orderData,
        });
      } else {
        await SalesOrdersAPI.update(props.order.id, orderData);
      }
    } else if (props.conversationId) {
      await store.dispatch('conversationOrders/create', {
        conversationId: props.conversationId,
        orderData,
      });
    } else {
      await SalesOrdersAPI.create(orderData);
    }
    emit('saved');
  } catch (error) {
    console.error('Save order failed', error);
  }
};
</script>

<template>
  <div class="flex flex-col w-full">
    <!-- Form Body -->
    <div class="flex-1 overflow-y-auto px-3 pb-8 pt-2">
      <div class="flex flex-col gap-5">
        <!-- Status & Source -->
        <div class="space-y-2">
          <h4 class="text-sm font-semibold text-n-slate-12 mb-1">
            {{ t('CONVERSATION.ORDER_PANEL.STATUS_LABEL') }}
          </h4>
          <div class="flex flex-col gap-2">
            <MultiselectDropdown
              :options="statusOptionsList"
              :selected-item="selectedStatus"
              :has-thumbnail="false"
              :multiselector-title="t('CONVERSATION.ORDER_PANEL.STATUS_LABEL')"
              :multiselector-placeholder="t('CONVERSATION.ORDER_PANEL.STATUS_LABEL')"
              :input-placeholder="t('CONVERSATION.ORDER_PANEL.STATUS_LABEL')"
              @select="item => form.status = item.id"
            />
            <select
              v-if="!isSourceLocked"
              v-model="form.external_source"
              class="w-full px-3 py-1 h-8 text-sm rounded-md border-0 outline outline-1 outline-n-strong bg-transparent hover:bg-n-slate-9/10 transition-colors text-n-slate-12 focus:!outline-n-brand !shadow-none m-0 appearance-none cursor-pointer"
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
        </div>
        <!-- Products -->
        <div class="space-y-2">
          <h4 class="text-sm font-semibold text-n-slate-12 mb-1">
            {{ t('CONVERSATION.ORDER_PANEL.PRODUCTS') }}
          </h4>
          <ProductSearch
            :conversation-id="conversationId"
            @select-product="addProduct"
          />

          <!-- Items List -->
          <div v-if="form.items.length" class="mt-3">
            <div
              v-for="(item, index) in form.items"
              :key="index"
              class="flex gap-3 py-3 border-b border-n-weak last:border-b-0"
            >
              <!-- Left: Thumbnail -->
              <div class="w-16 h-16 shrink-0 rounded-md bg-n-solid-2 border border-n-weak overflow-hidden flex items-center justify-center">
                <img
                  v-if="item.product_thumbnail"
                  :src="item.product_thumbnail"
                  class="w-full h-full object-cover"
                />
                <i v-else class="i-lucide-image text-n-slate-9 text-xl" />
              </div>

              <!-- Right: Info -->
              <div class="flex-1 min-w-0 flex flex-col gap-2">
                <!-- Row 1: Tên sản phẩm & Nút xoá -->
                <div class="flex items-start justify-between gap-2">
                  <div class="flex-1 min-w-0 mt-0.5">
                    <input
                      v-if="item.product_source === 'manual'"
                      v-model="item.product_name"
                      type="text"
                      :placeholder="t('CONVERSATION.ORDER_PANEL.PRODUCT_NAME')"
                      class="w-full text-sm text-n-slate-12 border border-transparent bg-n-alpha-1 hover:bg-n-alpha-2 focus:bg-n-solid-1 rounded-md px-2 py-1 outline-none font-medium placeholder:text-n-slate-9 focus:!border-n-brand !shadow-none m-0 transition-all"
                    />
                    <div
                      v-else
                      class="text-sm font-medium text-n-slate-12 leading-relaxed break-words"
                    >
                      {{ item.product_name }}
                    </div>
                  </div>
                  <button
                    class="shrink-0 p-1 rounded-md hover:bg-n-ruby-3 text-n-slate-10 hover:text-n-ruby-11 transition-colors"
                    @click="removeItem(index)"
                  >
                    <i class="i-lucide-trash-2 text-sm" />
                  </button>
                </div>

                <!-- Row 2: Đơn giá -->
                <div class="flex items-center gap-2 mt-0.5">
                  <label class="text-xs font-medium text-n-slate-11 w-16 shrink-0">Đơn giá</label>
                  <input
                    type="text"
                    :value="formatCurrencyValue(item.unit_price)"
                    @input="e => item.unit_price = parseCurrencyValue(e.target.value)"
                    class="flex-1 w-full text-sm rounded-md border border-transparent bg-n-alpha-1 hover:bg-n-alpha-2 focus:bg-n-solid-1 transition-colors text-n-slate-12 py-1 px-2 outline-none focus:!border-n-brand !shadow-none m-0 transition-shadow"
                  />
                </div>

                <!-- Row 3: Thuế -->
                <div class="flex items-center gap-2 mt-0.5">
                  <label class="text-xs font-medium text-n-slate-11 w-16 shrink-0">Thuế %</label>
                  <input
                    v-model.number="item.tax_rate"
                    type="number"
                    min="0"
                    max="100"
                    class="flex-1 w-full text-sm rounded-md border border-transparent bg-n-alpha-1 hover:bg-n-alpha-2 focus:bg-n-solid-1 transition-colors text-n-slate-12 py-1 px-2 outline-none focus:!border-n-brand !shadow-none m-0 transition-shadow"
                  />
                </div>

                <!-- Row 4: Số lượng (+/-) -->
                <div class="flex items-center justify-between mt-0.5">
                  <div class="flex items-center gap-2">
                    <label class="text-xs font-medium text-n-slate-11 w-16 shrink-0">Số lượng</label>
                    <div class="flex items-center gap-1">
                      <button
                        class="p-1.5 rounded-md hover:bg-n-alpha-2 text-n-slate-10 hover:text-n-slate-12 transition-colors cursor-pointer"
                        @click="item.quantity > 1 ? item.quantity-- : null"
                      >
                        <i class="i-lucide-minus text-sm" />
                      </button>
                      <input
                        v-model.number="item.quantity"
                        type="number"
                        min="1"
                        class="!w-12 text-sm text-center rounded-md border border-transparent bg-n-alpha-1 hover:bg-n-alpha-2 focus:bg-n-solid-1 transition-colors text-n-slate-12 py-1 px-1 outline-none focus:!border-n-brand !shadow-none m-0 [appearance:textfield] [&::-webkit-outer-spin-button]:appearance-none [&::-webkit-inner-spin-button]:appearance-none"
                      />
                      <button
                        class="p-1.5 rounded-md hover:bg-n-alpha-2 text-n-slate-10 hover:text-n-slate-12 transition-colors cursor-pointer"
                        @click="item.quantity++"
                      >
                        <i class="i-lucide-plus text-sm" />
                      </button>
                    </div>
                  </div>
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


        </div>
        <!-- Financial & Payment -->
        <div class="space-y-3">
          <h4 class="text-sm font-semibold text-n-slate-12 mb-1">
            {{ t('CONVERSATION.ORDER_PANEL.FINANCIAL') }}
          </h4>

          <div class="flex flex-col gap-2.5">
            <div>
              <label class="block text-xs font-medium text-n-slate-11 mb-1">{{
                t('CONVERSATION.ORDER_PANEL.SHIPPING_FEE')
              }}</label>
              <input
                type="text"
                :value="formatCurrencyValue(form.shipping_fee)"
                @input="e => form.shipping_fee = parseCurrencyValue(e.target.value)"
                class="w-full px-3 py-1 text-sm rounded-lg border border-transparent bg-n-alpha-1 hover:bg-n-alpha-2 focus:bg-n-solid-1 transition-colors text-n-slate-12 outline-none focus:!border-n-brand !shadow-none m-0"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-n-slate-11 mb-1">{{
                t('CONVERSATION.ORDER_PANEL.DISCOUNT')
              }}</label>
              <input
                type="text"
                :value="formatCurrencyValue(form.discount_amount)"
                @input="e => form.discount_amount = parseCurrencyValue(e.target.value)"
                class="w-full px-3 py-1 text-sm rounded-lg border border-transparent bg-n-alpha-1 hover:bg-n-alpha-2 focus:bg-n-solid-1 transition-colors text-n-slate-12 outline-none focus:!border-n-brand !shadow-none m-0"
              />
            </div>

            <div>
              <label class="block text-xs font-medium text-n-slate-11 mb-1">{{
                t('CONVERSATION.ORDER_PANEL.PAYMENT_METHOD')
              }}</label>
              <MultiselectDropdown
                :options="paymentMethodOptionsList"
                :selected-item="selectedPaymentMethod"
                :has-thumbnail="false"
                :multiselector-title="t('CONVERSATION.ORDER_PANEL.PAYMENT_METHOD')"
                :multiselector-placeholder="t('CONVERSATION.ORDER_PANEL.PAYMENT_METHOD')"
                :input-placeholder="t('CONVERSATION.ORDER_PANEL.PAYMENT_METHOD')"
                @select="item => form.payment_method = item.id"
              />
            </div>
            <div>
              <label class="block text-xs font-medium text-n-slate-11 mb-1">{{
                t('CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.LABEL')
              }}</label>
              <MultiselectDropdown
                :options="paymentStatusOptionsList"
                :selected-item="selectedPaymentStatus"
                :has-thumbnail="false"
                :multiselector-title="t('CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.LABEL')"
                :multiselector-placeholder="t('CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.LABEL')"
                :input-placeholder="t('CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.LABEL')"
                @select="item => form.payment_status = item.id"
              />
            </div>
          </div>

          <!-- Total -->
          <div
            v-if="form.items.length"
            class="flex justify-between items-center py-2.5 px-3 rounded-lg bg-n-solid-3 border border-n-weak"
          >
            <span class="text-sm font-medium text-n-slate-11">
              {{ t('CONVERSATION.ORDER_PANEL.TOTAL') }}
            </span>
            <span class="text-sm font-bold text-n-slate-12">
              {{ formatCurrency(totalAmount) }}đ
            </span>
          </div>
        </div>
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
