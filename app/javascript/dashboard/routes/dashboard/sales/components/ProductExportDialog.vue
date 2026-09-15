<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { useMapGetter } from 'dashboard/composables/store';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['export', 'close']);
const { t } = useI18n();

const uiFlags = useMapGetter('salesProducts/getUIFlags');
const isExportingProduct = computed(() => uiFlags.value.isExporting || false);

const dialogRef = ref(null);

const confirmExport = () => {
  emit('export');
};

const closeDialog = () => {
  emit('close');
};

watch(
  () => props.show,
  newVal => {
    if (newVal) {
      dialogRef.value?.open();
    } else {
      dialogRef.value?.close();
    }
  }
);

onMounted(() => {
  if (props.show) {
    dialogRef.value?.open();
  }
});

defineExpose({ dialogRef });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="$t('SALES.MODULE_PRODUCTS.ACTIONS.EXPORT_PRODUCT.TITLE')"
    :confirm-button-label="
      $t('SALES.MODULE_PRODUCTS.ACTIONS.EXPORT_PRODUCT.EXPORT')
    "
    :is-loading="isExportingProduct"
    :disable-confirm-button="isExportingProduct"
    @confirm="confirmExport"
    @cancel="closeDialog"
  >
    <template #description>
      <p class="mb-0 text-sm text-n-slate-11">
        {{ $t('SALES.MODULE_PRODUCTS.ACTIONS.EXPORT_PRODUCT.DESCRIPTION') }}
      </p>
    </template>
  </Dialog>
</template>
