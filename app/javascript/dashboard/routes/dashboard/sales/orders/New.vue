<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import ProductSearch from 'dashboard/components/widgets/conversation/orders/ProductSearch.vue';
import ContactSearch from 'dashboard/components/widgets/conversation/orders/ContactSearch.vue';
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
    title: t('SALES.ORDER_FORM.WIZARD.STEP_1.TITLE'),
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
      product_source: 'shopiz',
      variant_id: product.variant_id,
      quantity: 1,
      unit_price: product.price,
      product_thumbnail: product.image_url,
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

const handleContactSelect = selectedContact => {
  form.value.contact_id = selectedContact.id;
  form.value.customer_name = selectedContact.name;
  form.value.customer_phone = selectedContact.phone_number || '';
  const attrs = selectedContact.additional_attributes || {};
  form.value.customer_address =
    attrs.address ||
    [attrs.city, attrs.country].filter(Boolean).join(', ') ||
    '';
};

const orderTotal = computed(() => {
  const itemsTotal = form.value.items
    .filter(i => !i._destroy)
    .reduce((sum, item) => sum + item.quantity * item.unit_price, 0);
  return (
    itemsTotal +
    Number(form.value.shipping_fee || 0) +
    Number(form.value.tax || 0) -
    Number(form.value.discount_amount || 0)
  );
});

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
    tax: form.value.tax,
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
  <div class="flex flex-col h-full bg-n-surface-1 w-full overflow-hidden">
    <div
      class="flex justify-between items-center h-20 min-h-[3.5rem] px-6 py-2 bg-n-surface-1 max-w-5xl mx-auto w-full flex-shrink-0"
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
        class="grid grid-cols-1 lg:grid-cols-8 lg:divide-x lg:divide-n-weak rounded-xl border border-n-weak h-full w-full bg-transparent overflow-hidden"
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

              <div class="space-y-3 mt-4">
                <div
                  v-for="(item, index) in form.items"
                  :key="index"
                  class="flex items-center gap-3 p-3 rounded-lg border border-n-weak bg-n-alpha-1 relative group"
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

                  <div class="flex-1 min-w-0">
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

                  <div class="flex items-center gap-2">
                    <button
                      class="p-1 rounded bg-n-solid-2 hover:bg-n-solid-3 text-n-slate-11 transition-colors"
                      @click="updateQuantity(index, -1)"
                    >
                      <i class="i-lucide-minus text-xs" />
                    </button>
                    <span
                      class="text-sm text-n-slate-12 font-medium w-6 text-center"
                    >
                      {{ item.quantity }}
                    </span>
                    <button
                      class="p-1 rounded bg-n-solid-2 hover:bg-n-solid-3 text-n-slate-11 transition-colors"
                      @click="updateQuantity(index, 1)"
                    >
                      <i class="i-lucide-plus text-xs" />
                    </button>
                  </div>

                  <button
                    class="absolute -top-2 -right-2 p-1 rounded-full bg-n-slate-2 border border-n-weak text-n-slate-11 hover:text-n-red-11 hover:border-n-red-11 opacity-0 group-hover:opacity-100 transition-all cursor-pointer shadow-sm"
                    @click="removeProduct(index)"
                  >
                    <i class="i-lucide-x text-xs" />
                  </button>
                </div>
              </div>
            </div>

            <!-- Step 1: Financials -->
            <div v-show="currentStep === 1" class="flex flex-col gap-6">
              <h2 class="text-lg font-medium text-n-slate-12 mb-2">
                {{ $t('CONVERSATION.ORDER_PANEL.FINANCIAL') }}
              </h2>

              <div class="grid grid-cols-2 gap-4">
                <div class="flex flex-col gap-1.5">
                  <label class="text-sm font-medium text-n-slate-11">{{
                    t('CONVERSATION.ORDER_PANEL.SHIPPING_FEE')
                  }}</label>
                  <input
                    v-model.number="form.shipping_fee"
                    type="number"
                    min="0"
                    class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 outline-none focus:border-n-brand focus:ring-1 focus:ring-n-brand/30"
                  />
                </div>
                <div class="flex flex-col gap-1.5">
                  <label class="text-sm font-medium text-n-slate-11">{{
                    t('CONVERSATION.ORDER_PANEL.DISCOUNT')
                  }}</label>
                  <input
                    v-model.number="form.discount_amount"
                    type="number"
                    min="0"
                    class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 outline-none focus:border-n-brand focus:ring-1 focus:ring-n-brand/30"
                  />
                </div>
                <div class="flex flex-col gap-1.5">
                  <label class="text-sm font-medium text-n-slate-11">{{
                    t('CONVERSATION.ORDER_PANEL.TAX')
                  }}</label>
                  <input
                    v-model.number="form.tax"
                    type="number"
                    min="0"
                    class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 outline-none focus:border-n-brand focus:ring-1 focus:ring-n-brand/30"
                  />
                </div>
              </div>

              <div class="grid grid-cols-2 gap-4">
                <div class="flex flex-col gap-1.5">
                  <label class="text-sm font-medium text-n-slate-11">{{
                    t('CONVERSATION.ORDER_PANEL.PAYMENT_METHOD')
                  }}</label>
                  <div class="relative">
                    <select
                      v-model="form.payment_method"
                      class="w-full px-3 py-2 pr-10 text-sm rounded-lg border border-n-weak bg-n-alpha-1 bg-none text-n-slate-12 outline-none focus:ring-1 focus:ring-n-brand focus:border-n-brand appearance-none cursor-pointer"
                    >
                      <option value="cod">COD</option>
                      <option value="bank_transfer">Chuyển khoản</option>
                      <option value="card">Thẻ / Ví điện tử</option>
                    </select>
                    <i
                      class="i-lucide-chevron-down absolute right-3 top-1/2 -translate-y-1/2 text-n-slate-11 pointer-events-none text-base"
                    />
                  </div>
                </div>
                <div class="flex flex-col gap-1.5">
                  <label class="text-sm font-medium text-n-slate-11">{{
                    t('CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.LABEL')
                  }}</label>
                  <select
                    v-model="form.payment_status"
                    class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 outline-none focus:border-n-brand cursor-pointer"
                  >
                    <option value="unpaid">
                      {{ t('CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.UNPAID') }}
                    </option>
                    <option value="paid">
                      {{ t('CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.PAID') }}
                    </option>
                    <option value="partially_refunded">
                      {{
                        t(
                          'CONVERSATION.ORDER_PANEL.PAYMENT_STATUS.PARTIALLY_REFUNDED'
                        )
                      }}
                    </option>
                  </select>
                </div>
              </div>
            </div>

            <!-- Step 2: Customer -->
            <div v-show="currentStep === 2" class="flex flex-col gap-6">
              <h2 class="text-lg font-medium text-n-slate-12 mb-2">
                {{ $t('CONVERSATION.ORDER_PANEL.CUSTOMER_INFO') }}
              </h2>

              <ContactSearch @select-contact="handleContactSelect" />

              <div class="grid grid-cols-2 gap-4 mt-2">
                <div class="flex flex-col gap-1.5 col-span-2">
                  <input
                    v-model="form.customer_name"
                    type="text"
                    :placeholder="t('CONVERSATION.ORDER_PANEL.CUSTOMER_NAME')"
                    class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder:text-n-slate-9 outline-none focus:border-n-brand focus:ring-1 focus:ring-n-brand/30"
                  />
                </div>
                <div class="flex flex-col gap-1.5 col-span-2">
                  <input
                    v-model="form.customer_phone"
                    type="tel"
                    :placeholder="t('CONVERSATION.ORDER_PANEL.PHONE')"
                    class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder:text-n-slate-9 outline-none focus:border-n-brand focus:ring-1 focus:ring-n-brand/30"
                  />
                </div>
                <div class="flex flex-col gap-1.5 col-span-2">
                  <textarea
                    v-model="form.customer_address"
                    :placeholder="t('CONVERSATION.ORDER_PANEL.ADDRESS')"
                    rows="3"
                    class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder:text-n-slate-9 outline-none focus:border-n-brand resize-none"
                  />
                </div>
                <div class="flex flex-col gap-1.5 col-span-2">
                  <textarea
                    v-model="form.customer_note"
                    :placeholder="t('CONVERSATION.ORDER_PANEL.NOTE')"
                    rows="2"
                    class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 placeholder:text-n-slate-9 outline-none focus:border-n-brand resize-none"
                  />
                </div>
              </div>
            </div>

            <!-- Step 3: Completion -->
            <div v-show="currentStep === 3" class="flex flex-col gap-6">
              <h2 class="text-lg font-medium text-n-slate-12 mb-2">
                Hoàn thành Đơn hàng
              </h2>

              <div class="flex flex-col gap-1.5">
                <label class="text-sm font-medium text-n-slate-11">{{
                  t('CONVERSATION.ORDER_PANEL.STATUS_LABEL')
                }}</label>
                <select
                  v-model="form.status"
                  class="w-full px-3 py-2 text-sm rounded-lg border border-n-weak bg-n-alpha-1 text-n-slate-12 outline-none focus:border-n-brand cursor-pointer"
                >
                  <option value="draft">
                    {{ t('CONVERSATION.ORDER_PANEL.STATUS.DRAFT') }}
                  </option>
                  <option value="confirmed">
                    {{ t('CONVERSATION.ORDER_PANEL.STATUS.CONFIRMED') }}
                  </option>
                  <option value="processing">
                    {{ t('CONVERSATION.ORDER_PANEL.STATUS.PROCESSING') }}
                  </option>
                  <option value="shipped">
                    {{ t('CONVERSATION.ORDER_PANEL.STATUS.SHIPPED') }}
                  </option>
                  <option value="delivered">
                    {{ t('CONVERSATION.ORDER_PANEL.STATUS.DELIVERED') }}
                  </option>
                  <option value="cancelled">
                    {{ t('CONVERSATION.ORDER_PANEL.STATUS.CANCELLED') }}
                  </option>
                </select>
              </div>

              <!-- Summary card -->
              <div
                class="mt-4 p-5 rounded-xl border border-n-weak bg-n-solid-1 flex flex-col gap-4"
              >
                <div class="flex justify-between items-center text-sm">
                  <span class="text-n-slate-11">Sản phẩm ({{ form.items.length }})</span>
                  <span class="text-n-slate-12 font-medium">{{
                    new Intl.NumberFormat('vi-VN', {
                      style: 'currency',
                      currency: 'VND',
                    }).format(
                      form.items.reduce(
                        (sum, item) => sum + item.quantity * item.unit_price,
                        0
                      )
                    )
                  }}</span>
                </div>
                <div class="flex justify-between items-center text-sm">
                  <span class="text-n-slate-11">Phí vận chuyển</span>
                  <span class="text-n-slate-12">{{
                    new Intl.NumberFormat('vi-VN', {
                      style: 'currency',
                      currency: 'VND',
                    }).format(form.shipping_fee)
                  }}</span>
                </div>
                <div class="flex justify-between items-center text-sm">
                  <span class="text-n-slate-11">Giảm giá</span>
                  <span class="text-n-red-11">-{{
                      new Intl.NumberFormat('vi-VN', {
                        style: 'currency',
                        currency: 'VND',
                      }).format(form.discount_amount)
                    }}</span>
                </div>
                <div class="flex justify-between items-center text-sm">
                  <span class="text-n-slate-11">Thuế</span>
                  <span class="text-n-slate-12">{{
                    new Intl.NumberFormat('vi-VN', {
                      style: 'currency',
                      currency: 'VND',
                    }).format(form.tax)
                  }}</span>
                </div>
                <div class="h-px bg-n-weak w-full my-1" />
                <div class="flex justify-between items-center">
                  <span class="text-base font-medium text-n-slate-12">Tổng thanh toán</span>
                  <span class="text-lg font-bold text-n-brand">{{
                    new Intl.NumberFormat('vi-VN', {
                      style: 'currency',
                      currency: 'VND',
                    }).format(orderTotal)
                  }}</span>
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
              :label="$t('SALES.PRODUCT_FORM.BUTTONS.SUBMIT')"
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
