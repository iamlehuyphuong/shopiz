<script setup>
import { ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'submit']);

const { t } = useI18n();

const name = ref('');
const sku = ref('');
const barcode = ref('');
const price = ref('');
const description = ref('');
const isSubmitting = ref(false);

const resetForm = () => {
  name.value = '';
  sku.value = '';
  barcode.value = '';
  price.value = '';
  description.value = '';
};

const onClose = () => {
  resetForm();
  emit('close');
};

const onSubmit = () => {
  if (!name.value.trim()) {
    useAlert(t('SALES.DIALOG_ADD_PRODUCT.ALERTS.NAME_REQUIRED'));
    return;
  }
  isSubmitting.value = true;
  emit('submit', {
    name: name.value,
    sku: sku.value,
    barcode: barcode.value,
    price: Number(price.value) || 0,
    currency: 'VND',
    description: description.value,
  });
  isSubmitting.value = false;
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('SALES.DIALOG_ADD_PRODUCT.TITLE')"
      :header-content="$t('SALES.DIALOG_ADD_PRODUCT.DESC')"
    />
    <form class="flex flex-wrap mx-0" @submit.prevent="onSubmit">
      <woot-input
        v-model="name"
        class="w-full"
        :label="$t('SALES.DIALOG_ADD_PRODUCT.FORM.NAME.LABEL')"
        :placeholder="$t('SALES.DIALOG_ADD_PRODUCT.FORM.NAME.PLACEHOLDER')"
      />
      <div class="flex w-full gap-4">
        <woot-input
          v-model="sku"
          class="flex-1"
          :label="$t('SALES.DIALOG_ADD_PRODUCT.FORM.SKU.LABEL')"
          :placeholder="$t('SALES.DIALOG_ADD_PRODUCT.FORM.SKU.PLACEHOLDER')"
        />
        <woot-input
          v-model="barcode"
          class="flex-1"
          :label="$t('SALES.DIALOG_ADD_PRODUCT.FORM.BARCODE.LABEL')"
          :placeholder="$t('SALES.DIALOG_ADD_PRODUCT.FORM.BARCODE.PLACEHOLDER')"
        />
      </div>
      <woot-input
        v-model="price"
        class="w-full"
        type="number"
        :label="$t('SALES.DIALOG_ADD_PRODUCT.FORM.PRICE.LABEL')"
        :placeholder="$t('SALES.DIALOG_ADD_PRODUCT.FORM.PRICE.PLACEHOLDER')"
      />
      <woot-input
        v-model="description"
        class="w-full"
        :label="$t('SALES.DIALOG_ADD_PRODUCT.FORM.DESCRIPTION.LABEL')"
        :placeholder="
          $t('SALES.DIALOG_ADD_PRODUCT.FORM.DESCRIPTION.PLACEHOLDER')
        "
      />
      <div class="flex items-center justify-end w-full gap-2 px-0 py-2">
        <NextButton
          faded
          slate
          type="reset"
          :label="$t('SALES.DIALOG_ADD_PRODUCT.FORM.CANCEL')"
          @click.prevent="onClose"
        />
        <NextButton
          type="submit"
          :label="$t('SALES.DIALOG_ADD_PRODUCT.FORM.SUBMIT')"
          :disabled="isSubmitting"
          :is-loading="isSubmitting"
        />
      </div>
    </form>
  </div>
</template>
