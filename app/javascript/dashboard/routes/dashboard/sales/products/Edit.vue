<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useRouter, useRoute } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import useVuelidate from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import Button from 'dashboard/components-next/button/Button.vue';
import SalesProductsAPI from 'dashboard/api/sales/products';

const { t } = useI18n();
const router = useRouter();
const route = useRoute();
const store = useStore();

const currentStep = ref(0);
const product = ref(null);
const isLoading = ref(true);
const isSubmitting = ref(false);

import { computed } from 'vue';

const wizardItems = computed(() => [
  {
    title: t('SALES.PRODUCT_FORM.WIZARD.STEP_0.TITLE'),
    body: t('SALES.PRODUCT_FORM.WIZARD.STEP_0.BODY'),
  },
  {
    title: t('SALES.PRODUCT_FORM.WIZARD.STEP_1.TITLE'),
    body: t('SALES.PRODUCT_FORM.WIZARD.STEP_1.BODY'),
  },
  {
    title: t('SALES.PRODUCT_FORM.WIZARD.STEP_2.TITLE'),
    body: t('SALES.PRODUCT_FORM.WIZARD.STEP_2.BODY'),
  },
  {
    title: t('SALES.PRODUCT_FORM.WIZARD.STEP_3.TITLE'),
    body: t('SALES.PRODUCT_FORM.WIZARD.STEP_3.BODY'),
  },
]);

const form = ref({
  name: '',
  description: '',
  price: '',
  currency: 'VND',
  imageUrl: '',
  productType: 'physical',
  category: '',
  brand: '',
  style: '',
  attributes: '',
  status: 'active',
  variants: [],
});

const rules = {
  form: {
    name: { required },
  },
};

const v$ = useVuelidate(rules, { form });

const fetchProductDetails = async () => {
  isLoading.value = true;
  try {
    const response = await SalesProductsAPI.show(route.params.id);
    product.value = response.data;

    // Fill form
    const data = product.value;
    const meta = data.meta || {};

    form.value.name = data.name || '';
    form.value.description = data.description || '';
    form.value.price = data.price || '';
    form.value.currency = data.currency || 'VND';
    form.value.imageUrl =
      data.images && data.images.length > 0 ? data.images[0] : '';
    form.value.productType = meta.product_type || 'physical';
    form.value.category = meta.category || '';
    form.value.brand = meta.brand || '';
    form.value.style = meta.style || '';
    form.value.attributes = meta.attributes || '';
    form.value.status = data.status || 'draft';

    if (data.variants && data.variants.length > 0) {
      form.value.variants = data.variants.map(v => {
        const vMeta = v.meta || {};
        return {
          id: v.id,
          name: v.name || '',
          sku: v.sku || '',
          barcode: v.barcode || '',
          price: v.price || '',
          weight: v.weight || 0,
          meta: {
            color: vMeta.color || '',
            size: vMeta.size || '',
            length: vMeta.length || 0,
            width: vMeta.width || 0,
            height: vMeta.height || 0,
          },
        };
      });
    }
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

const nextStep = () => {
  if (currentStep.value === 0) {
    v$.value.form.$touch();
    if (v$.value.form.$error) {
      useAlert(t('SALES.PRODUCT_FORM.ALERTS.NAME_REQUIRED'));
      return;
    }
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

const addVariant = () => {
  form.value.variants.push({
    name: '',
    sku: '',
    barcode: '',
    price: '',
    weight: 0,
    meta: { color: '', size: '', length: 0, width: 0, height: 0 },
  });
};

const duplicateVariant = index => {
  const variant = form.value.variants[index];
  form.value.variants.push({
    name: variant.name ? `${variant.name} (Copy)` : '',
    sku: variant.sku ? `${variant.sku}-COPY` : '',
    barcode: variant.barcode,
    price: variant.price,
    weight: variant.weight,
    meta: { ...variant.meta },
  });
};

const removeVariant = index => {
  form.value.variants.splice(index, 1);
};

const onSubmit = async () => {
  isSubmitting.value = true;

  try {
    const cleanedVariants = form.value.variants.map(v => {
      const cleanMeta = { ...v.meta };
      if (!cleanMeta.color) delete cleanMeta.color;
      if (!cleanMeta.size) delete cleanMeta.size;
      return {
        ...v,
        price: v.price ? Number(v.price) : undefined,
        weight: Number(v.weight) || 0,
        meta: cleanMeta,
      };
    });

    const finalVariants = cleanedVariants.filter(
      v => v.name || v.meta.color || v.meta.size
    );

    const payload = {
      id: route.params.id,
      name: form.value.name,
      description: form.value.description,
      price: Number(form.value.price) || 0,
      currency: form.value.currency,
      status: form.value.status,
      images: form.value.imageUrl ? [form.value.imageUrl] : [],
      meta: {
        product_type: form.value.productType,
        category: form.value.category,
        brand: form.value.brand,
        style: form.value.style,
        attributes: form.value.attributes,
      },
    };

    // Luôn gửi mảng variants (kể cả rỗng) để backend cập nhật (xoá/thêm/sửa)
    payload.product_variants_attributes = finalVariants;

    const { id: productId, ...productData } = payload;
    await store.dispatch('salesProducts/update', {
      id: productId,
      product: productData,
    });

    useAlert(t('SALES.PRODUCT_FORM.ALERTS.UPDATE_SUCCESS'));
    router.push({ name: 'sales_products_list' });
  } catch (error) {
    useAlert(error.message || t('SALES.PRODUCT_FORM.ALERTS.SAVE_ERROR'));
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
          :to="{ name: 'sales_products_list' }"
          class="flex items-center font-normal cursor-pointer text-n-slate-11 text-base ltr:mr-4 rtl:ml-4 hover:text-n-slate-12 transition-colors"
        >
          <i class="i-lucide-chevron-left -ml-1 text-lg mr-1" />
          {{ $t('SALES.PRODUCT_FORM.BACK') }}
        </router-link>
        <span class="text-heading-1 text-n-slate-12">
          {{ $t('SALES.PRODUCT_FORM.TITLE_EDIT') }}
        </span>
      </h1>
    </div>

    <div
      class="flex flex-col mb-8 mt-8 max-w-5xl mx-auto w-full px-6 flex-1 overflow-hidden"
    >
      <div
        class="grid grid-cols-1 lg:grid-cols-8 lg:divide-x lg:divide-n-weak rounded-xl border border-n-weak h-full w-full bg-white dark:bg-slate-900 overflow-hidden"
      >
        <!-- Sidebar Wizard -->
        <div
          class="hidden lg:flex flex-col col-span-2 py-8 px-6 overflow-y-auto"
        >
          <div
            v-for="(item, index) in wizardItems"
            :key="index"
            class="cursor-pointer flex items-start gap-6 relative after:content-[''] after:absolute after:w-0.5 after:h-full after:top-5 ltr:after:left-4 rtl:after:right-4 before:content-[''] before:absolute before:w-0.5 before:h-4 before:top-0 before:left-4 rtl:before:right-4 last:after:hidden first:before:hidden after:bg-n-slate-3 before:bg-n-slate-3"
            @click="currentStep = index"
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
          class="col-span-1 lg:col-span-6 p-8 flex flex-col gap-8 overflow-y-auto"
        >
          <div v-if="isLoading" class="py-8 flex items-center justify-center">
            <span class="icon-spin text-2xl text-n-slate-11 animate-spin" />
          </div>

          <div v-else-if="!product" class="py-8 text-center text-n-slate-11">
            <p>Không tìm thấy sản phẩm</p>
          </div>

          <div v-else class="w-full">
            <!-- STEP 0: Thông tin cơ bản -->
            <div v-show="currentStep === 0" class="flex flex-col gap-6 w-full">
              <div class="flex flex-col gap-1 mb-2">
                <h2 class="text-lg text-n-slate-12 font-medium m-0">
                  {{ $t('SALES.PRODUCT_FORM.STEP_0.HEADING_EDIT') }}
                </h2>
                <p class="text-sm text-n-slate-11 m-0">
                  {{ $t('SALES.PRODUCT_FORM.STEP_0.SUBHEADING_EDIT') }}
                </p>
              </div>

              <div class="w-full">
                <woot-input
                  v-model="form.name"
                  class="w-full mb-0"
                  :class="{ error: v$.form.name.$error }"
                  :label="$t('SALES.PRODUCT_FORM.FIELDS.NAME.LABEL')"
                  :placeholder="
                    $t('SALES.PRODUCT_FORM.FIELDS.NAME.PLACEHOLDER')
                  "
                  @blur="v$.form.name.$touch"
                />
                <span
                  v-if="v$.form.name.$error"
                  class="message text-n-red-11 text-xs mt-1 block"
                >
                  {{ $t('SALES.PRODUCT_FORM.FIELDS.NAME.ERROR') }}
                </span>
              </div>

              <div class="w-full">
                <woot-input
                  v-model="form.imageUrl"
                  class="w-full mb-0"
                  :label="$t('SALES.PRODUCT_FORM.FIELDS.IMAGE.LABEL')"
                  :placeholder="
                    $t('SALES.PRODUCT_FORM.FIELDS.IMAGE.PLACEHOLDER')
                  "
                />
              </div>

              <div class="w-full grid grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm font-medium text-n-slate-12 mb-1">
                    {{ $t('SALES.PRODUCT_FORM.FIELDS.TYPE.LABEL') }}
                  </label>
                  <select
                    v-model="form.productType"
                    class="w-full p-2.5 rounded-lg border border-n-weak bg-white dark:bg-slate-900 focus:outline-none focus:ring-1 focus:ring-n-brand text-sm text-n-slate-12"
                  >
                    <option value="physical">
                      {{
                        $t('SALES.PRODUCT_FORM.FIELDS.TYPE.OPTIONS.PHYSICAL')
                      }}
                    </option>
                    <option value="digital">
                      {{ $t('SALES.PRODUCT_FORM.FIELDS.TYPE.OPTIONS.DIGITAL') }}
                    </option>
                    <option value="service">
                      {{ $t('SALES.PRODUCT_FORM.FIELDS.TYPE.OPTIONS.SERVICE') }}
                    </option>
                  </select>
                </div>
                <woot-input
                  v-model="form.category"
                  class="w-full mb-0"
                  :label="$t('SALES.PRODUCT_FORM.FIELDS.CATEGORY.LABEL')"
                  :placeholder="
                    $t('SALES.PRODUCT_FORM.FIELDS.CATEGORY.PLACEHOLDER')
                  "
                />
              </div>

              <div class="w-full">
                <label class="block text-sm font-medium text-n-slate-12 mb-1">
                  {{ $t('SALES.PRODUCT_FORM.FIELDS.DESCRIPTION.LABEL') }}
                </label>
                <textarea
                  v-model="form.description"
                  class="w-full p-3 rounded-lg border border-n-weak bg-white dark:bg-slate-900 focus:outline-none focus:ring-1 focus:ring-n-brand focus:border-n-brand text-sm transition-shadow min-h-[120px]"
                  :placeholder="
                    $t('SALES.PRODUCT_FORM.FIELDS.DESCRIPTION.PLACEHOLDER')
                  "
                />
              </div>

              <div class="w-full grid grid-cols-2 gap-4">
                <woot-input
                  v-model="form.price"
                  class="w-full mb-0"
                  type="number"
                  :label="$t('SALES.PRODUCT_FORM.FIELDS.PRICE.LABEL')"
                  :placeholder="
                    $t('SALES.PRODUCT_FORM.FIELDS.PRICE.PLACEHOLDER')
                  "
                />
                <woot-input
                  v-model="form.currency"
                  class="w-full mb-0"
                  :label="$t('SALES.PRODUCT_FORM.FIELDS.CURRENCY.LABEL')"
                  :placeholder="
                    $t('SALES.PRODUCT_FORM.FIELDS.CURRENCY.PLACEHOLDER')
                  "
                />
              </div>

              <div class="mt-4 flex justify-end">
                <Button
                  :label="$t('SALES.PRODUCT_FORM.BUTTONS.NEXT')"
                  icon="i-lucide-arrow-right"
                  icon-position="right"
                  @click="nextStep"
                />
              </div>
            </div>

            <!-- STEP 1: Thuộc tính -->
            <div v-show="currentStep === 1" class="flex flex-col gap-6 w-full">
              <div class="flex flex-col gap-1 mb-2">
                <h2 class="text-lg text-n-slate-12 font-medium m-0">
                  {{ $t('SALES.PRODUCT_FORM.STEP_1.HEADING_EDIT') }}
                </h2>
                <p class="text-sm text-n-slate-11 m-0">
                  {{ $t('SALES.PRODUCT_FORM.STEP_1.SUBHEADING_EDIT') }}
                </p>
              </div>

              <div class="w-full">
                <woot-input
                  v-model="form.brand"
                  class="w-full mb-0"
                  :label="$t('SALES.PRODUCT_FORM.FIELDS.BRAND.LABEL')"
                  :placeholder="
                    $t('SALES.PRODUCT_FORM.FIELDS.BRAND.PLACEHOLDER')
                  "
                />
              </div>

              <div class="w-full">
                <woot-input
                  v-model="form.style"
                  class="w-full mb-0"
                  :label="$t('SALES.PRODUCT_FORM.FIELDS.STYLE.LABEL')"
                  :placeholder="
                    $t('SALES.PRODUCT_FORM.FIELDS.STYLE.PLACEHOLDER')
                  "
                />
              </div>

              <div class="w-full">
                <label class="block text-sm font-medium text-n-slate-12 mb-1">
                  {{ $t('SALES.PRODUCT_FORM.FIELDS.ATTRIBUTES.LABEL') }}
                </label>
                <textarea
                  v-model="form.attributes"
                  class="w-full p-3 rounded-lg border border-n-weak bg-white dark:bg-slate-900 focus:outline-none focus:ring-1 focus:ring-n-brand focus:border-n-brand text-sm transition-shadow min-h-[80px]"
                  :placeholder="
                    $t('SALES.PRODUCT_FORM.FIELDS.ATTRIBUTES.PLACEHOLDER')
                  "
                />
              </div>

              <div class="mt-4 flex justify-between">
                <Button
                  slate
                  ghost
                  :label="$t('SALES.PRODUCT_FORM.BUTTONS.BACK')"
                  icon="i-lucide-arrow-left"
                  @click="prevStep"
                />
                <Button
                  :label="$t('SALES.PRODUCT_FORM.BUTTONS.NEXT')"
                  icon="i-lucide-arrow-right"
                  icon-position="right"
                  @click="nextStep"
                />
              </div>
            </div>

            <!-- STEP 2: Biến thể -->
            <div v-show="currentStep === 2" class="flex flex-col gap-6 w-full">
              <div class="flex flex-col gap-1 mb-2">
                <h2 class="text-lg text-n-slate-12 font-medium m-0">
                  {{ $t('SALES.PRODUCT_FORM.STEP_2.HEADING_EDIT') }}
                </h2>
                <p class="text-sm text-n-slate-11 m-0">
                  {{ $t('SALES.PRODUCT_FORM.STEP_2.SUBHEADING_EDIT') }}
                </p>
              </div>

              <!-- List of variants -->
              <div
                v-for="(variant, index) in form.variants"
                :key="index"
                class="bg-n-alpha-1 border border-n-weak rounded-xl p-6 relative flex flex-col gap-4"
              >
                <div class="absolute top-4 right-4 flex items-center gap-2">
                  <button
                    class="text-n-slate-11 hover:text-n-brand transition-colors"
                    :title="$t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.DUPLICATE')"
                    @click.prevent="duplicateVariant(index)"
                  >
                    <span class="i-lucide-copy text-base" />
                  </button>
                  <button
                    class="text-n-slate-11 hover:text-n-red-11 transition-colors"
                    :title="$t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.REMOVE')"
                    @click.prevent="removeVariant(index)"
                  >
                    <span class="i-lucide-trash-2 text-base" />
                  </button>
                </div>

                <h3 class="font-medium text-n-slate-12 m-0 text-base">
                  {{
                    $t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.TITLE', {
                      index: index + 1,
                    })
                  }}
                </h3>

                <div class="grid grid-cols-2 gap-4">
                  <woot-input
                    v-model="variant.name"
                    class="w-full mb-0"
                    :label="$t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.NAME.LABEL')"
                    :placeholder="
                      $t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.NAME.PLACEHOLDER')
                    "
                  />
                  <woot-input
                    v-model="variant.price"
                    type="number"
                    class="w-full mb-0"
                    :label="
                      $t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.PRICE.LABEL')
                    "
                    :placeholder="
                      $t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.PRICE.PLACEHOLDER')
                    "
                  />
                </div>

                <div class="grid grid-cols-2 gap-4">
                  <woot-input
                    v-model="variant.sku"
                    class="w-full mb-0"
                    :label="$t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.SKU.LABEL')"
                    :placeholder="
                      $t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.SKU.PLACEHOLDER')
                    "
                  />
                  <woot-input
                    v-model="variant.barcode"
                    class="w-full mb-0"
                    :label="
                      $t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.BARCODE.LABEL')
                    "
                    :placeholder="
                      $t(
                        'SALES.PRODUCT_FORM.FIELDS.VARIANTS.BARCODE.PLACEHOLDER'
                      )
                    "
                  />
                </div>

                <!-- Meta info: Color, Size -->
                <div class="grid grid-cols-2 gap-4">
                  <woot-input
                    v-model="variant.meta.color"
                    class="w-full mb-0"
                    :label="
                      $t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.COLOR.LABEL')
                    "
                    :placeholder="
                      $t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.COLOR.PLACEHOLDER')
                    "
                  />
                  <woot-input
                    v-model="variant.meta.size"
                    class="w-full mb-0"
                    :label="$t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.SIZE.LABEL')"
                    :placeholder="
                      $t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.SIZE.PLACEHOLDER')
                    "
                  />
                </div>

                <!-- Shipping info: Weight, Dimensions -->
                <div class="grid grid-cols-4 gap-4 mt-2">
                  <woot-input
                    v-model="variant.weight"
                    type="number"
                    class="w-full mb-0"
                    :label="
                      $t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.WEIGHT.LABEL')
                    "
                    :placeholder="
                      $t(
                        'SALES.PRODUCT_FORM.FIELDS.VARIANTS.WEIGHT.PLACEHOLDER'
                      )
                    "
                  />
                  <woot-input
                    v-model="variant.meta.length"
                    type="number"
                    class="w-full mb-0"
                    :label="
                      $t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.LENGTH.LABEL')
                    "
                    :placeholder="
                      $t(
                        'SALES.PRODUCT_FORM.FIELDS.VARIANTS.WEIGHT.PLACEHOLDER'
                      )
                    "
                  />
                  <woot-input
                    v-model="variant.meta.width"
                    type="number"
                    class="w-full mb-0"
                    :label="
                      $t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.WIDTH.LABEL')
                    "
                    :placeholder="
                      $t(
                        'SALES.PRODUCT_FORM.FIELDS.VARIANTS.WEIGHT.PLACEHOLDER'
                      )
                    "
                  />
                  <woot-input
                    v-model="variant.meta.height"
                    type="number"
                    class="w-full mb-0"
                    :label="
                      $t('SALES.PRODUCT_FORM.FIELDS.VARIANTS.HEIGHT.LABEL')
                    "
                    :placeholder="
                      $t(
                        'SALES.PRODUCT_FORM.FIELDS.VARIANTS.WEIGHT.PLACEHOLDER'
                      )
                    "
                  />
                </div>
              </div>

              <Button
                slate
                ghost
                icon="i-lucide-plus"
                :label="$t('SALES.PRODUCT_FORM.BUTTONS.ADD_VARIANT')"
                class="w-fit"
                @click="addVariant"
              />

              <div class="mt-4 flex justify-between">
                <Button
                  slate
                  ghost
                  :label="$t('SALES.PRODUCT_FORM.BUTTONS.BACK')"
                  icon="i-lucide-arrow-left"
                  @click="prevStep"
                />
                <Button
                  :label="$t('SALES.PRODUCT_FORM.BUTTONS.NEXT')"
                  icon="i-lucide-arrow-right"
                  icon-position="right"
                  @click="nextStep"
                />
              </div>
            </div>

            <!-- STEP 3: Hoàn tất -->
            <div v-show="currentStep === 3" class="flex flex-col gap-6 w-full">
              <div class="flex flex-col gap-1 mb-2">
                <h2 class="text-lg text-n-slate-12 font-medium m-0">
                  {{ $t('SALES.PRODUCT_FORM.STEP_3.HEADING_EDIT') }}
                </h2>
                <p class="text-sm text-n-slate-11 m-0">
                  {{ $t('SALES.PRODUCT_FORM.STEP_3.SUBHEADING_EDIT') }}
                </p>
              </div>

              <div
                class="bg-n-alpha-1 border border-n-weak rounded-xl p-6 flex flex-col gap-4"
              >
                <h3 class="font-medium text-n-slate-12 m-0 text-base">
                  {{ $t('SALES.PRODUCT_FORM.STEP_3.OVERVIEW') }}
                </h3>

                <div class="flex flex-col gap-2 text-sm">
                  <div class="flex gap-2">
                    <span class="text-n-slate-11 w-32">{{
                      $t('SALES.PRODUCT_FORM.STEP_3.NAME')
                    }}</span>
                    <span class="text-n-slate-12 font-medium">{{
                      form.name || $t('SALES.PRODUCT_FORM.STEP_3.NOT_ENTERED')
                    }}</span>
                  </div>
                  <div class="flex gap-2">
                    <span class="text-n-slate-11 w-32">{{
                      $t('SALES.PRODUCT_FORM.STEP_3.BASE_PRICE')
                    }}</span>
                    <span class="text-n-slate-12 font-medium"
                      >{{ form.price || 0 }} {{ form.currency }}</span
                    >
                  </div>
                  <div class="flex gap-2">
                    <span class="text-n-slate-11 w-32">{{
                      $t('SALES.PRODUCT_FORM.STEP_3.VARIANT_COUNT')
                    }}</span>
                    <span class="text-n-slate-12 font-medium">{{
                      form.variants.length
                    }}</span>
                  </div>
                </div>
              </div>

              <div class="w-full">
                <label class="block text-sm font-medium text-n-slate-12 mb-2">
                  {{ $t('SALES.PRODUCT_FORM.FIELDS.STATUS.LABEL') }}
                </label>
                <select
                  v-model="form.status"
                  class="w-full p-2.5 rounded-lg border border-n-weak bg-white dark:bg-slate-900 focus:outline-none focus:ring-1 focus:ring-n-brand text-sm text-n-slate-12"
                >
                  <option value="active">
                    {{ $t('SALES.PRODUCT_FORM.FIELDS.STATUS.OPTIONS.ACTIVE') }}
                  </option>
                  <option value="draft">
                    {{ $t('SALES.PRODUCT_FORM.FIELDS.STATUS.OPTIONS.DRAFT') }}
                  </option>
                  <option value="archived">Lưu trữ</option>
                </select>
              </div>

              <div class="mt-6 flex justify-between">
                <Button
                  slate
                  ghost
                  :label="$t('SALES.PRODUCT_FORM.BUTTONS.BACK')"
                  icon="i-lucide-arrow-left"
                  @click="prevStep"
                />
                <Button
                  :label="$t('SALES.PRODUCT_FORM.BUTTONS.UPDATE')"
                  icon="i-lucide-check"
                  icon-position="right"
                  :is-loading="isSubmitting"
                  :disabled="isSubmitting"
                  @click="onSubmit"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
