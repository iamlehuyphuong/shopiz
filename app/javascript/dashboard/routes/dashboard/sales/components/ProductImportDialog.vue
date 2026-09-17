<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['import', 'close']);
const { t } = useI18n();

const uiFlags = useMapGetter('salesProducts/getUIFlags');
const isImportingProduct = computed(() => uiFlags.value.isImporting || false);

const dialogRef = ref(null);
const fileInput = ref(null);

const hasSelectedFile = ref(null);
const selectedFileName = ref('');

const xlsxUrl = '/downloads/import-products-sample.xlsx';

const handleFileClick = () => fileInput.value?.click();

const processFileName = fileName => {
  const lastDotIndex = fileName.lastIndexOf('.');
  const extension = fileName.slice(lastDotIndex);
  const baseName = fileName.slice(0, lastDotIndex);

  return baseName.length > 20
    ? `${baseName.slice(0, 20)}...${extension}`
    : fileName;
};

const handleFileChange = () => {
  const file = fileInput.value?.files[0];
  hasSelectedFile.value = file;
  selectedFileName.value = file ? processFileName(file.name) : '';
};

const handleRemoveFile = () => {
  hasSelectedFile.value = null;
  if (fileInput.value) {
    fileInput.value.value = null;
  }
  selectedFileName.value = '';
};

const uploadFile = async () => {
  if (!hasSelectedFile.value) return;
  emit('import', hasSelectedFile.value);
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
    :title="$t('SALES.MODULE_PRODUCTS.ACTIONS.IMPORT_PRODUCT.TITLE')"
    :confirm-button-label="
      $t('SALES.MODULE_PRODUCTS.ACTIONS.IMPORT_PRODUCT.IMPORT')
    "
    :is-loading="isImportingProduct"
    :disable-confirm-button="isImportingProduct || !hasSelectedFile"
    @confirm="uploadFile"
    @cancel="closeDialog"
  >
    <template #description>
      <p class="mb-0 text-sm text-n-slate-11">
        {{ $t('SALES.MODULE_PRODUCTS.ACTIONS.IMPORT_PRODUCT.DESCRIPTION') }}
        <a
          :href="xlsxUrl"
          target="_blank"
          rel="noopener noreferrer"
          download="import-products-sample.xlsx"
          class="text-n-orange-11"
        >
          {{
            $t('SALES.MODULE_PRODUCTS.ACTIONS.IMPORT_PRODUCT.DOWNLOAD_LABEL')
          }}
        </a>
      </p>
    </template>

    <div class="flex flex-col gap-2 mt-4">
      <div class="flex items-center gap-2">
        <label class="text-sm text-n-slate-12 whitespace-nowrap">
          {{ $t('SALES.MODULE_PRODUCTS.ACTIONS.IMPORT_PRODUCT.LABEL') }}
        </label>
        <div class="flex items-center justify-between w-full gap-2">
          <span v-if="hasSelectedFile" class="text-sm text-n-slate-12">
            {{ selectedFileName }}
          </span>
          <Button
            v-if="!hasSelectedFile"
            :label="
              $t('SALES.MODULE_PRODUCTS.ACTIONS.IMPORT_PRODUCT.CHOOSE_FILE')
            "
            icon="i-lucide-upload"
            color="slate"
            variant="ghost"
            size="sm"
            class="!w-fit"
            @click="handleFileClick"
          />
          <div v-else class="flex items-center gap-1">
            <Button
              :label="$t('SALES.MODULE_PRODUCTS.ACTIONS.IMPORT_PRODUCT.CHANGE')"
              color="slate"
              variant="ghost"
              size="sm"
              @click="handleFileClick"
            />
            <div class="w-px h-3 bg-n-strong" />
            <Button
              icon="i-lucide-trash"
              color="slate"
              variant="ghost"
              size="sm"
              @click="handleRemoveFile"
            />
          </div>
        </div>
      </div>
    </div>
    <input
      ref="fileInput"
      type="file"
      accept=".xlsx"
      class="hidden"
      @change="handleFileChange"
    />
  </Dialog>
</template>
