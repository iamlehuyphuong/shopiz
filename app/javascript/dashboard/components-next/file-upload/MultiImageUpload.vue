<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { uploadFile } from 'dashboard/helper/uploadHelper';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  modelValue: {
    type: Array,
    default: () => [],
  },
  maxImages: {
    type: Number,
    default: 4,
  },
  placeholder: {
    type: String,
    default: 'https://example.com/image.jpg',
  },
});

const emit = defineEmits(['update:modelValue']);

const { t } = useI18n();

const linkInput = ref('');
const isUploading = ref(false);
const fileInput = ref(null);

const canAddMore = computed(() => props.modelValue.length < props.maxImages);

const handleAddLink = () => {
  if (!linkInput.value.trim() || !canAddMore.value) return;
  const newImages = [...props.modelValue, linkInput.value.trim()];
  emit('update:modelValue', newImages);
  linkInput.value = '';
};

const handleRemove = index => {
  const newImages = [...props.modelValue];
  newImages.splice(index, 1);
  emit('update:modelValue', newImages);
};

const triggerUpload = () => {
  if (canAddMore.value) {
    fileInput.value?.click();
  }
};

const onFileSelect = async event => {
  const file = event.target.files?.[0];
  if (!file) return;

  const validTypes = ['image/png', 'image/jpeg', 'image/jpg', 'image/webp'];
  if (!validTypes.includes(file.type)) {
    useAlert('Định dạng ảnh không được hỗ trợ (chỉ cho phép png, jpg, webp)');
    if (fileInput.value) fileInput.value.value = '';
    return;
  }

  if (file.size > 8 * 1024 * 1024) {
    // 8MB limit
    useAlert('Dung lượng ảnh vượt quá 8MB');
    return;
  }

  isUploading.value = true;
  try {
    const { fileUrl } = await uploadFile(file);
    if (fileUrl) {
      emit('update:modelValue', [...props.modelValue, fileUrl]);
    }
  } catch (error) {
    useAlert(error.message || 'Tải ảnh lên thất bại');
  } finally {
    isUploading.value = false;
    if (fileInput.value) {
      fileInput.value.value = '';
    }
  }
};
</script>

<template>
  <div class="flex flex-col gap-3 w-full">
    <!-- Image Grid -->
    <div
      v-if="modelValue.length > 0"
      class="grid grid-cols-2 md:grid-cols-4 gap-3"
    >
      <div
        v-for="(url, index) in modelValue"
        :key="index"
        class="relative group aspect-square rounded-lg border border-n-weak overflow-hidden bg-n-surface-2 flex items-center justify-center"
      >
        <img :src="url" class="w-full h-full object-cover" />
        <button
          class="absolute top-2 right-2 h-7 px-2 rounded-md bg-white shadow-sm border border-n-weak flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all text-n-red-11 hover:bg-n-red-2"
          @click.prevent="handleRemove(index)"
        >
          <Icon icon="i-lucide-x" class="size-4" />
        </button>
      </div>
    </div>

    <!-- Add New -->
    <div v-if="canAddMore" class="flex flex-col sm:flex-row items-center gap-2">
      <Input
        v-model="linkInput"
        class="w-full sm:flex-1"
        custom-input-class="!bg-n-surface-1"
        :placeholder="placeholder"
        @enter="handleAddLink"
      />
      <div class="flex items-center gap-2 w-full sm:w-auto shrink-0">
        <Button
          :label="isUploading ? '' : 'Thêm'"
          icon="i-lucide-plus"
          :is-loading="isUploading"
          :disabled="!linkInput.trim() || isUploading"
          class="flex-1 sm:flex-none"
          @click.prevent="handleAddLink"
        />
        <span class="text-n-slate-10 text-sm hidden sm:block">hoặc</span>
        <Button
          :label="isUploading ? 'Đang tải...' : 'Tải lên'"
          icon="i-lucide-upload"
          slate
          outline
          :is-loading="isUploading"
          :disabled="isUploading"
          class="flex-1 sm:flex-none"
          @click.prevent="triggerUpload"
        />
        <input
          ref="fileInput"
          type="file"
          accept="image/png, image/jpeg, image/jpg, image/webp"
          class="hidden"
          @change="onFileSelect"
        />
      </div>
    </div>

    <p v-if="!canAddMore" class="text-xs text-n-slate-11">
      Đã đạt giới hạn tối đa {{ maxImages }} ảnh.
    </p>
  </div>
</template>
