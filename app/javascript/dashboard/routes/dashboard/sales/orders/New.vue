<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import ProductSearch from 'dashboard/components/widgets/conversation/orders/ProductSearch.vue';
import ContactSearch from 'dashboard/components/widgets/conversation/orders/ContactSearch.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import SalesOrdersAPI from 'dashboard/api/sales/orders';

const { t } = useI18n();
const router = useRouter();

const currentStep = ref(0);
const isSubmitting = ref(false);

const wizardItems = computed(() => [
  {
    title: t('SALES.ORDER_FORM.WIZARD.STEP_0.TITLE'),
    body: t('SALES.ORDER_FORM.WIZARD.STEP_0.BODY'),
  },
  {
    title: 'Thanh toán',
    body: t('SALES.ORDER_FORM.WIZARD.STEP_1.BODY'),
  },
  {
    title: t('SALES.ORDER_FORM.WIZARD.STEP_2.TITLE'),
    body: t('SALES.ORDER_FORM.WIZARD.STEP_2.BODY'),
  },
  {
    title: t('SALES.ORDER_FORM.WIZARD.STEP_3.TITLE'),
    body: t('SALES.ORDER_FORM.WIZARD.STEP_3.BODY'),
  },
]);

const form = ref({
  status: 'draft',
  external_source: '',
  customer_name: '',
  customer_phone: '',
  customer_address: '',
  customer_note: '',
  contact_id: null,
  shipping_fee: 0,
  tax: 0,
  tax_rate: 0,
  discount_amount: 0,
  payment_method: 'cod',
  payment_status: 'unpaid',
  items: [],
});

// Step validation
const canProceedToNextStep = computed(() => {
  if (currentStep.value === 0) {
    return (
      form.value.items.length > 0 && form.value.items.every(i => i.product_name)
    );
  }
  if (currentStep.value === 2) {
    // Require contact selection for standalone orders
    return !!form.value.contact_id;
  }
  return true;
});

const nextStep = () => {
  if (!canProceedToNextStep.value) {
    if (currentStep.value === 0)
      useAlert(t('CONVERSATION.ORDER_PANEL.NO_PRODUCTS'));
    if (currentStep.value === 2)
      useAlert(t('CONVERSATION.ORDER_PANEL.CUSTOMER_NAME')); // Provide better translation if available
    return;
  }
  if (currentStep.value < wizardItems.value.length - 1) {
    currentStep.value++;
  }
};

const prevStep = () => {
  if (currentStep.value > 0) {
    currentStep.value--;
  }
};

// Actions
const addProduct = product => {
  const existingItemIndex = form.value.items.findIndex(
    i =>
      i.product_id === product.id &&
      i.variant_id === product.variant_id &&
      !i._destroy
  );

  if (existingItemIndex > -1) {
    form.value.items[existingItemIndex].quantity += 1;
  } else {
    form.value.items.push({
      product_name: product.name,
      product_id: product.id,
      product_source: product.source || 'shopiz',
      variant_id: product.variant_id,
      quantity: 1,
      unit_price: product.price,
      product_thumbnail: product.thumbnail,
    });
  }
};

const removeProduct = index => {
  form.value.items.splice(index, 1);
};

const updateQuantity = (index, delta) => {
  const newQuantity = form.value.items[index].quantity + delta;
  if (newQuantity > 0) {
    form.value.items[index].quantity = newQuantity;
  } else {
    removeProduct(index);
  }
};

const selectedContact = ref(null);

const handleContactSelect = contact => {
  selectedContact.value = contact;
  form.value.contact_id = contact.id;
  form.value.customer_name = contact.name;
  form.value.customer_phone = contact.phone_number || '';
  const attrs = contact.additional_attributes || {};
  form.value.customer_address =
    attrs.address ||
    [attrs.city, attrs.country].filter(Boolean).join(', ') ||
    '';
};

const clearContact = () => {
  selectedContact.value = null;
  form.value.contact_id = null;
  form.value.customer_name = '';
  form.value.customer_phone = '';
  form.value.customer_address = '';
};

const itemsTotal = computed(() => {
  return form.value.items
    .filter(i => !i._destroy)
    .reduce((sum, item) => sum + item.quantity * item.unit_price, 0);
});

const formattedDiscount = computed({
  get: () => new Intl.NumberFormat('vi-VN').format(form.value.discount_amount || 0),
  set: (val) => {
    form.value.discount_amount = Number(String(val).replace(/\D/g, '')) || 0;
  }
});

const formattedShippingFee = computed({
  get: () => new Intl.NumberFormat('vi-VN').format(form.value.shipping_fee || 0),
  set: (val) => {
    form.value.shipping_fee = Number(String(val).replace(/\D/g, '')) || 0;
  }
});

const calculatedTax = computed(() => {
  if (form.value.tax_rate) {
    return (itemsTotal.value * Number(form.value.tax_rate)) / 100;
  }
  return Number(form.value.tax || 0);
});

const orderTotal = computed(() => {
  return (
    itemsTotal.value +
    Number(form.value.shipping_fee || 0) +
    calculatedTax.value -
    Number(form.value.discount_amount || 0)
  );
});

const formatCurrency = (value) => {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(value || 0);
};

const handleSave = async () => {
  if (!canProceedToNextStep.value) return;
  isSubmitting.value = true;
  const orderData = {
    status: form.value.status,
    external_source: form.value.external_source || undefined,
    customer_name: form.value.customer_name,
    customer_phone: form.value.customer_phone,
    customer_address: form.value.customer_address,
    customer_note: form.value.customer_note,
    contact_id: form.value.contact_id || undefined,
    shipping_fee: form.value.shipping_fee,
    tax: calculatedTax.value,
    discount_amount: form.value.discount_amount,
    payment_method: form.value.payment_method,
    payment_status: form.value.payment_status,
    items_attributes: form.value.items.map(item => ({
      product_name: item.product_name,
      product_id: item.product_id,
      product_source: item.product_source,
      variant_id: item.variant_id,
      quantity: item.quantity,
      unit_price: item.unit_price,
      product_thumbnail: item.product_thumbnail,
    })),
  };

  try {
    await SalesOrdersAPI.create(orderData);
    useAlert(t('CONVERSATION.ORDER_PANEL.SAVE_SUCCESS'));
    router.push({ name: 'sales_orders_list' });
  } catch (error) {
    console.error('Save order failed', error);
    useAlert(error.message || 'Error');
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col h-full bg-white w-full overflow-hidden relative">
    <div
      class="flex justify-between items-center h-16 px-6 py-2 bg-white max-w-5xl mx-auto w-full flex-shrink-0"
    >
      <h1 class="flex items-center mb-0 text-n-slate-12">
        <router-link
          :to="{ name: 'sales_orders_list' }"
          class="flex items-center font-normal cursor-pointer text-n-slate-11 text-base ltr:mr-4 rtl:ml-4 hover:text-n-slate-12 transition-colors"
        >
          <i class="i-lucide-chevron-left -ml-1 text-lg mr-1" />
          Back
        </router-link>
        <span class="text-heading-1 text-n-slate-12 flex items-center">
          {{ $t('SALES.MODULE_ORDERS.ACTIONS.CREATE') }}
        </span>
      </h1>
    </div>

    <div
      class="flex flex-col mb-8 mt-4 max-w-5xl mx-auto w-full px-6 flex-1 overflow-hidden"
    >
      <div
        class="grid grid-cols-1 lg:grid-cols-8 lg:divide-x lg:divide-n-weak rounded-xl border border-n-weak h-full w-full bg-white overflow-hidden shadow-sm"
      >
        <!-- Sidebar Wizard -->
        <div
          class="hidden lg:flex flex-col col-span-2 py-8 px-6 overflow-y-auto"
        >
          <div
            v-for="(item, index) in wizardItems"
            :key="index"
            class="cursor-pointer flex items-start gap-6 relative after:content-[''] after:absolute after:w-0.5 after:h-full after:top-5 ltr:after:left-4 rtl:after:right-4 before:content-[''] before:absolute before:w-0.5 before:h-4 before:top-0 before:left-4 rtl:before:right-4 last:after:hidden first:before:hidden after:bg-n-slate-3 before:bg-n-slate-3"
            @click="canProceedToNextStep && (currentStep = index)"
          >
            <!-- Circle -->
            <div
              class="rounded-2xl flex-shrink-0 size-8 border-2 border-n-slate-3 flex items-center justify-center left-2 leading-4 z-10 top-5 transition-all duration-300 ease-in-out"
              :class="{
                'bg-n-slate-3': currentStep >= index,
                'bg-n-background': currentStep < index,
              }"
            >
              <span
                v-if="currentStep <= index"
                class="text-xs font-bold transition-colors duration-300"
                :class="
                  currentStep === index ? 'text-n-orange-11' : 'text-n-slate-11'
                "
              >
                {{ index + 1 }}
              </span>
              <span v-else class="i-lucide-check text-n-slate-11 size-4" />
            </div>

            <!-- Content -->
            <div class="flex flex-col items-start gap-1.5 pb-10 pt-1">
              <h3
                class="text-sm font-medium overflow-hidden whitespace-nowrap mt-0.5 text-ellipsis leading-tight m-0 transition-colors"
                :class="
                  currentStep === index ? 'text-n-orange-11' : 'text-n-slate-12'
                "
              >
                {{ item.title }}
              </h3>
              <p class="m-0 mt-1.5 text-sm text-n-slate-11">
                {{ item.body }}
              </p>
            </div>
          </div>
        </div>

        <div
          class="flex flex-col col-span-1 lg:col-span-6 overflow-hidden h-full"
        >
          <div class="flex-1 overflow-y-auto p-8">
            <!-- Step 0: Products -->
            <div v-show="currentStep === 0" class="flex flex-col gap-6">
              <h2 class="text-lg font-medium text-n-slate-12 mb-2">
                {{ $t('CONVERSATION.ORDER_PANEL.PRODUCTS') }}
              </h2>
              <ProductSearch @select-product="addProduct" />

              <div v-if="form.items.length > 0" class="mt-8 flex flex-col gap-4">
                <h3 class="text-sm font-semibold text-n-slate-12">
                  Danh sách sản phẩm
                </h3>
                <div class="space-y-3">
                  <div
                    v-for="(item, index) in form.items"
                    :key="index"
                    class="flex items-center gap-3 p-3 rounded-lg border border-n-weak bg-white dark:bg-n-surface-1"
                  >
                    <img
                      v-if="item.product_thumbnail"
                      :src="item.product_thumbnail"
                      class="w-12 h-12 rounded object-cover"
                    />
                    <div
                      v-else
                      class="w-12 h-12 rounded bg-n-slate-2 flex items-center justify-center text-n-slate-11"
                    >
                      <i class="i-lucide-image" />
                    </div>

                    <div class="flex-1 min-w-0 pr-4">
                      <p
                        class="text-sm font-medium text-n-slate-12 truncate mb-1"
                      >
                        {{ item.product_name }}
                      </p>
                      <p class="text-xs text-n-slate-11">
                        {{
                          new Intl.NumberFormat('vi-VN', {
                            style: 'currency',
                            currency: 'VND',
                          }).format(item.unit_price)
                        }}
                      </p>
                    </div>

                    <div class="flex items-center gap-1.5 shrink-0">
                      <button
                        class="w-8 h-8 flex items-center justify-center rounded-md bg-n-solid-2 hover:bg-n-solid-3 text-n-slate-12 transition-colors"
                        @click="updateQuantity(index, -1)"
                      >
                        <fluent-icon icon="subtract" size="20" />
                      </button>
                      <span
                        class="text-sm text-n-slate-12 font-medium w-8 text-center"
                      >
                        {{ item.quantity }}
                      </span>
                      <button
                        class="w-8 h-8 flex items-center justify-center rounded-md bg-n-solid-2 hover:bg-n-solid-3 text-n-slate-12 transition-colors"
                        @click="updateQuantity(index, 1)"
                      >
                        <fluent-icon icon="add" size="20" />
                      </button>
                    </div>

                    <button
                      class="w-8 h-8 flex items-center justify-center rounded-md bg-transparent text-n-slate-10 hover:bg-n-red-2 hover:text-n-red-11 transition-colors ml-2 shrink-0"
                      @click="removeProduct(index)"
                    >
                      <fluent-icon icon="delete" size="20" />
                    </button>
                  </div>
                </div>

                <div class="flex justify-between items-center py-4 border-t border-n-weak mt-2">
                  <span class="text-sm font-medium text-n-slate-11">Tổng tạm tính</span>
                  <span class="text-base font-semibold text-n-slate-12">
                    {{
                      new Intl.NumberFormat('vi-VN', {
                        style: 'currency',
                        currency: 'VND',
                      }).format(form.items.reduce((sum, item) => sum + (item.quantity * item.unit_price), 0))
                    }}
                  </span>
                </div>
              </div>
            </div>

            <!-- Step 1: Financials -->
            <div v-show="currentStep === 1" class="flex flex-col gap-6">
              <h2 class="text-lg font-medium text-n-slate-12 mb-2">
                Thông tin thanh toán
              </h2>

              <!-- Payment options grid moved to top -->
              <div class="grid grid-cols-2 gap-4">
                <div class="flex flex-col gap-1.5">
                  <label class="text-sm font-medium text-n-slate-11">{{ t('CONVERSATION.ORDER_PANEL.PAYMENT_METHOD') }}</label>
                  <ComboBox
                    v-model="form.payment_method"
                    :options="[
                      { label: 'COD', value: 'cod' },
                      { label: 'Chuyển khoản', value: 'bank_transfer' },
                      { label: 'Thẻ / Ví điện tử', value: 'card' }
                    ]"
                  />
                </div>
                <div class="flex flex-col gap-1.5">
                  <label class="text-sm font-medium text-n-slate-11">{{ t('CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.LABEL') }}</label>
                  <ComboBox
                    v-model="form.payment_status"
                    :options="[
                      { label: t('CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.UNPAID'), value: 'unpaid' },
                      { label: t('CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.PAID'), value: 'paid' },
                      { label: t('CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.PARTIALLY_REFUNDED'), value: 'partially_refunded' },
                      { label: 'Hoàn tiền', value: 'refunded' }
                    ]"
                  />
                </div>
              </div>

              <!-- Financial Summary Grid -->
              <div class="flex flex-col gap-4 mt-6">
                <!-- Tổng tiền -->
                <div class="flex flex-col gap-1.5">
                  <span class="text-sm font-medium text-n-slate-11">Tổng tiền (Tạm tính)</span>
                  <span class="text-base font-semibold text-n-slate-12 mt-1">
                    {{ formatCurrency(itemsTotal) }}
                  </span>
                </div>
                
                <!-- Thuế -->
                <div class="flex flex-col gap-1.5">
                  <span class="text-sm font-medium text-n-slate-11">Thuế (%)</span>
                  <div class="grid grid-cols-2 gap-4 items-center">
                    <div class="flex items-center w-full h-[38px] rounded-lg border border-n-weak bg-white dark:bg-n-solid-1 focus-within:border-n-brand transition-all overflow-hidden">
                      <input
                        v-model.number="form.tax_rate"
                        type="number"
                        min="0"
                        class="reset-base flex-1 w-full px-3 h-full text-sm text-n-slate-12 bg-transparent border-none outline-none m-0 p-0 !mb-0"
                      />
                      <span class="pr-3 text-sm text-n-slate-11 shrink-0">%</span>
                    </div>
                    <div class="flex h-[38px] items-center px-2">
                      <span class="text-sm font-medium text-n-slate-11">
                        {{ formatCurrency(calculatedTax) }}
                      </span>
                    </div>
                  </div>
                </div>

                <!-- Giảm giá -->
                <div class="flex flex-col gap-1.5">
                  <span class="text-sm font-medium text-n-slate-11">Giảm giá</span>
                  <div class="flex items-center w-full h-[38px] rounded-lg border border-n-weak bg-white dark:bg-n-solid-1 focus-within:border-n-brand transition-all overflow-hidden">
                    <input
                      v-model="formattedDiscount"
                      type="text"
                      class="reset-base flex-1 w-full px-3 h-full text-sm text-n-slate-12 bg-transparent border-none outline-none m-0 p-0 !mb-0"
                    />
                  </div>
                </div>

                <!-- Phí vận chuyển -->
                <div class="flex flex-col gap-1.5">
                  <span class="text-sm font-medium text-n-slate-11">Phí vận chuyển</span>
                  <div class="flex items-center w-full h-[38px] rounded-lg border border-n-weak bg-white dark:bg-n-solid-1 focus-within:border-n-brand transition-all overflow-hidden">
                    <input
                      v-model="formattedShippingFee"
                      type="text"
                      class="reset-base flex-1 w-full px-3 h-full text-sm text-n-slate-12 bg-transparent border-none outline-none m-0 p-0 !mb-0"
                    />
                  </div>
                </div>

                <!-- Tổng cộng -->
                <div class="flex flex-col gap-1.5 col-span-2 pt-4 border-t border-n-weak">
                  <span class="text-sm font-medium text-n-slate-11">Tổng cộng</span>
                  <span class="text-2xl font-bold text-n-orange-11">
                    {{ formatCurrency(orderTotal) }}
                  </span>
                </div>
              </div>
            </div>

            <!-- Step 2: Customer -->
            <div v-show="currentStep === 2" class="flex flex-col gap-6">
              <h2 class="text-lg font-medium text-n-slate-12 mb-2">
                {{ $t('CONVERSATION.ORDER_PANEL.CUSTOMER_INFO') }}
              </h2>

              <ContactSearch @select-contact="handleContactSelect" />

              <div class="flex flex-col gap-4 mt-2">
                <div class="flex flex-col gap-1.5">
                  <span class="text-sm font-medium text-n-slate-11">Khách hàng</span>
                  <div v-if="selectedContact" class="flex items-center gap-3 w-full h-[42px] px-3 rounded-lg border border-n-weak bg-white dark:bg-n-solid-1">
                    <img
                      v-if="selectedContact.thumbnail"
                      :src="selectedContact.thumbnail"
                      :alt="selectedContact.name"
                      class="w-7 h-7 rounded-md object-cover shrink-0 bg-n-solid-3"
                    />
                    <div
                      v-else
                      class="w-7 h-7 rounded-md bg-n-brand text-white flex items-center justify-center shrink-0 font-medium text-xs uppercase"
                    >
                      {{ selectedContact.name ? selectedContact.name.charAt(0) : '?' }}
                    </div>
                    <span class="flex-1 text-sm font-medium text-n-slate-12 truncate">{{ selectedContact.name }}</span>
                    <button
                      class="p-1 rounded hover:bg-n-alpha-2 text-n-slate-10 hover:text-n-slate-12 transition-colors flex items-center justify-center"
                      @click="clearContact"
                    >
                      <i class="i-lucide-x text-sm" />
                    </button>
                  </div>
                  <div v-else class="flex items-center w-full h-[38px] rounded-lg border border-n-weak bg-white dark:bg-n-solid-1 focus-within:border-n-brand transition-all overflow-hidden">
                    <input
                      v-model="form.customer_name"
                      type="text"
                      placeholder="Nhập tên khách hàng"
                      class="reset-base flex-1 w-full px-3 h-full text-sm text-n-slate-12 placeholder:text-n-slate-9 bg-transparent border-none outline-none m-0 p-0 !mb-0"
                    />
                  </div>
                </div>
                <div class="flex flex-col gap-1.5">
                  <span class="text-sm font-medium text-n-slate-11">{{ t('CONVERSATION.ORDER_PANEL.PHONE') }}</span>
                  <div class="flex items-center w-full h-[38px] rounded-lg border border-n-weak bg-white dark:bg-n-solid-1 focus-within:border-n-brand transition-all overflow-hidden">
                    <input
                      v-model="form.customer_phone"
                      type="tel"
                      class="reset-base flex-1 w-full px-3 h-full text-sm text-n-slate-12 placeholder:text-n-slate-9 bg-transparent border-none outline-none m-0 p-0 !mb-0"
                    />
                  </div>
                </div>
                <div class="flex flex-col gap-1.5">
                  <span class="text-sm font-medium text-n-slate-11">{{ t('CONVERSATION.ORDER_PANEL.ADDRESS') }}</span>
                  <div class="w-full rounded-lg border border-n-weak bg-white dark:bg-n-solid-1 focus-within:border-n-brand transition-all overflow-hidden">
                    <textarea
                      v-model="form.customer_address"
                      rows="3"
                      class="reset-base w-full px-3 py-2 text-sm text-n-slate-12 placeholder:text-n-slate-9 bg-transparent border-none outline-none resize-none m-0 !mb-0"
                    />
                  </div>
                </div>
                <div class="flex flex-col gap-1.5">
                  <span class="text-sm font-medium text-n-slate-11">{{ t('CONVERSATION.ORDER_PANEL.NOTE') }}</span>
                  <div class="w-full rounded-lg border border-n-weak bg-white dark:bg-n-solid-1 focus-within:border-n-brand transition-all overflow-hidden">
                    <textarea
                      v-model="form.customer_note"
                      rows="2"
                      class="reset-base w-full px-3 py-2 text-sm text-n-slate-12 placeholder:text-n-slate-9 bg-transparent border-none outline-none resize-none m-0 !mb-0"
                    />
                  </div>
                </div>
              </div>
            </div>

            <!-- Step 3: Completion -->
            <div v-show="currentStep === 3" class="flex flex-col gap-6">
              <h2 class="text-lg font-medium text-n-slate-12 mb-2">
                Tạo đơn hàng
              </h2>

              <!-- Trạng thái đơn hàng -->
              <div class="flex flex-col gap-1.5">
                <label class="text-sm font-medium text-n-slate-11">Trạng thái</label>
                <ComboBox
                  v-model="form.status"
                  :options="[
                    { label: t('CONVERSATION.ORDER_PANEL.STATUS.DRAFT'), value: 'draft' },
                    { label: t('CONVERSATION.ORDER_PANEL.STATUS.CONFIRMED'), value: 'confirmed' },
                    { label: t('CONVERSATION.ORDER_PANEL.STATUS.PROCESSING'), value: 'processing' },
                    { label: t('CONVERSATION.ORDER_PANEL.STATUS.SHIPPED'), value: 'shipped' },
                    { label: t('CONVERSATION.ORDER_PANEL.STATUS.DELIVERED'), value: 'delivered' },
                    { label: t('CONVERSATION.ORDER_PANEL.STATUS.CANCELLED'), value: 'cancelled' }
                  ]"
                />
              </div>

              <!-- Thông tin khách hàng -->
              <div class="flex flex-col gap-3">
                <span class="text-sm font-medium text-n-slate-11">Khách hàng</span>
                <div class="rounded-xl border border-n-weak bg-n-solid-1 p-4 flex flex-col gap-2">
                  <div v-if="form.customer_name" class="flex items-center gap-3">
                    <div v-if="selectedContact && selectedContact.thumbnail">
                      <img
                        :src="selectedContact.thumbnail"
                        :alt="form.customer_name"
                        class="w-9 h-9 rounded-md object-cover shrink-0 bg-n-solid-3"
                      />
                    </div>
                    <div
                      v-else
                      class="w-9 h-9 rounded-md bg-n-brand text-white flex items-center justify-center shrink-0 font-medium text-sm uppercase"
                    >
                      {{ form.customer_name.charAt(0) }}
                    </div>
                    <div class="flex-1 min-w-0">
                      <div class="text-sm font-medium text-n-slate-12 truncate">
                        {{ form.customer_name }}
                      </div>
                      <div
                        v-if="form.customer_phone"
                        class="text-xs text-n-slate-10 truncate mt-0.5"
                      >
                        {{ form.customer_phone }}
                      </div>
                    </div>
                  </div>
                  <div v-else class="text-sm text-n-slate-10 italic">
                    Chưa có thông tin khách hàng
                  </div>
                  <div
                    v-if="form.customer_address"
                    class="text-xs text-n-slate-10 pt-2 border-t border-n-weak"
                  >
                    <i class="i-lucide-map-pin text-xs mr-1" />{{ form.customer_address }}
                  </div>
                </div>
              </div>

              <!-- Danh sách sản phẩm -->
              <div class="flex flex-col gap-3">
                <span class="text-sm font-medium text-n-slate-11">
                  Sản phẩm ({{ form.items.filter(i => !i._destroy).length }})
                </span>
                <div class="rounded-xl border border-n-weak bg-n-solid-1 overflow-hidden">
                  <div class="max-h-[160px] overflow-y-auto divide-y divide-n-weak">
                    <div
                      v-for="item in form.items.filter(i => !i._destroy)"
                      :key="item.product_id"
                      class="flex items-center gap-3 px-4 py-3"
                    >
                      <img
                        v-if="item.thumbnail"
                        :src="item.thumbnail"
                        :alt="item.product_name"
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
                          {{ item.product_name }}
                        </div>
                        <div class="text-xs text-n-slate-10 mt-0.5">
                          {{ item.quantity }} x {{ formatCurrency(item.unit_price) }}
                        </div>
                      </div>
                      <span class="text-sm font-medium text-n-slate-12 shrink-0">
                        {{ formatCurrency(item.quantity * item.unit_price) }}
                      </span>
                    </div>
                  </div>
                </div>
              </div>

              <!-- Summary card -->
              <div
                class="p-5 rounded-xl border border-n-weak bg-n-solid-1 flex flex-col gap-3"
              >
                <div class="flex justify-between items-center text-sm">
                  <span class="text-n-slate-11">Tạm tính</span>
                  <span class="text-n-slate-12 font-medium">{{ formatCurrency(itemsTotal) }}</span>
                </div>
                <div class="flex justify-between items-center text-sm">
                  <span class="text-n-slate-11">Phí vận chuyển</span>
                  <span class="text-n-slate-12">{{ formatCurrency(form.shipping_fee) }}</span>
                </div>
                <div class="flex justify-between items-center text-sm">
                  <span class="text-n-slate-11">Giảm giá</span>
                  <span class="text-n-red-11">-{{ formatCurrency(form.discount_amount) }}</span>
                </div>
                <div class="flex justify-between items-center text-sm">
                  <span class="text-n-slate-11">Thuế</span>
                  <span class="text-n-slate-12">{{ formatCurrency(calculatedTax) }}</span>
                </div>
                <div class="h-px bg-n-weak w-full my-1" />
                <div class="flex justify-between items-center">
                  <span class="text-base font-medium text-n-slate-12">Tổng thanh toán</span>
                  <span class="text-lg font-bold text-n-brand">{{ formatCurrency(orderTotal) }}</span>
                </div>
              </div>

            </div>
          </div>

          <!-- Footer Actions -->
          <div
            class="flex items-center justify-between px-8 py-5 bg-transparent shrink-0"
          >
            <Button
              v-if="currentStep > 0"
              :label="$t('SALES.PRODUCT_FORM.BUTTONS.BACK')"
              ghost
              slate
              icon="i-lucide-arrow-left"
              @click="prevStep"
            />
            <div v-else />

            <Button
              v-if="currentStep < wizardItems.length - 1"
              :label="$t('SALES.PRODUCT_FORM.BUTTONS.NEXT')"
              icon="i-lucide-arrow-right"
              trailing-icon
              @click="nextStep"
            />
            <Button
              v-else
              label="Hoàn thành"
              icon="i-lucide-check"
              color="brand"
              :is-loading="isSubmitting"
              @click="handleSave"
            />
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
