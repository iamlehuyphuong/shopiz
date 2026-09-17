<script setup>
import { ref, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';

import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  isImporting: { type: Boolean, default: false },
});

const emit = defineEmits(['import', 'close']);
const { t } = useI18n();

const dialogRef = ref(null);
const fileInput = ref(null);

const hasSelectedFile = ref(null);
const selectedFileName = ref('');

onMounted(() => {
  if (dialogRef.value) {
    dialogRef.value.open();
  }
});

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

defineExpose({ dialogRef, handleRemoveFile });
</script>

<template>
  <Dialog
    ref="dialogRef"
    :title="t('CANNED_MGMT.IMPORT.TITLE')"
    :confirm-button-label="t('CANNED_MGMT.IMPORT.CONFIRM')"
    :is-loading="isImporting"
    :disable-confirm-button="isImporting"
    @confirm="uploadFile"
    @close="$emit('close')"
  >
    <template #description>
      <p class="mb-0 text-sm text-n-slate-11">
        {{ t('CANNED_MGMT.IMPORT.DESCRIPTION') }}
      </p>
    </template>

    <div class="flex flex-col gap-2">
      <div class="flex items-center gap-2">
        <label class="text-sm text-n-slate-12 whitespace-nowrap">
          {{ t('CANNED_MGMT.IMPORT.LABEL') }}
        </label>
        <div class="flex items-center justify-between w-full gap-2">
          <span v-if="hasSelectedFile" class="text-sm text-n-slate-12">
            {{ selectedFileName }}
          </span>
          <Button
            v-if="!hasSelectedFile"
            :label="t('CANNED_MGMT.IMPORT.CHOOSE_FILE')"
            icon="i-lucide-upload"
            color="slate"
            variant="ghost"
            size="sm"
            class="!w-fit"
            @click="handleFileClick"
          />
          <div v-else class="flex items-center gap-1">
            <Button
              :label="t('CANNED_MGMT.IMPORT.CHANGE')"
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
      accept="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, .xlsx"
      class="hidden"
      @change="handleFileChange"
    />
  </Dialog>
</template>
