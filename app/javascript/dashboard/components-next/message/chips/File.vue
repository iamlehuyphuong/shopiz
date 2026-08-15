<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { getFileInfo } from '@chatwoot/utils';
import { formatBytes } from 'shared/helpers/FileHelper';

import FileIcon from 'next/icon/FileIcon.vue';
import Icon from 'next/icon/Icon.vue';

const { attachment } = defineProps({
  attachment: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const fileDetails = computed(() => {
  const fallback = attachment?.fallback_title || attachment?.fallbackTitle;
  if (fallback) {
    return getFileInfo(fallback);
  }
  return getFileInfo(attachment?.dataUrl || attachment?.data_url || '');
});

const displayFileName = computed(() => {
  const { base, type } = fileDetails.value;
  const truncatedName = (str, maxLength, hasExt) =>
    str.length > maxLength
      ? `${str.substring(0, maxLength).trimEnd()}${hasExt ? '..' : '...'}`
      : str;

  return type
    ? `${truncatedName(base, 12, true)}.${type}`
    : truncatedName(base, 14, false);
});

const textColorClass = computed(() => {
  const colorMap = {
    '7z': 'dark:text-[#EDEEF0] text-[#2F265F]',
    csv: 'text-n-amber-12',
    doc: 'dark:text-[#D6E1FF] text-[#1F2D5C]', // indigo-12
    docx: 'dark:text-[#D6E1FF] text-[#1F2D5C]', // indigo-12
    json: 'text-n-slate-12',
    odt: 'dark:text-[#D6E1FF] text-[#1F2D5C]', // indigo-12
    pdf: 'text-n-slate-12',
    ppt: 'dark:text-[#FFE0C2] text-[#582D1D]',
    pptx: 'dark:text-[#FFE0C2] text-[#582D1D]',
    rar: 'dark:text-[#EDEEF0] text-[#2F265F]',
    rtf: 'dark:text-[#D6E1FF] text-[#1F2D5C]', // indigo-12
    tar: 'dark:text-[#EDEEF0] text-[#2F265F]',
    txt: 'text-n-slate-12',
    xls: 'text-n-teal-12',
    xlsx: 'text-n-teal-12',
    zip: 'dark:text-[#EDEEF0] text-[#2F265F]',
  };

  return colorMap[fileDetails.value.type] || 'text-n-slate-12';
});

const fileSize = computed(() => {
  const size = attachment?.file_size || attachment?.fileSize;
  return size ? formatBytes(size, 1) : '';
});
</script>

<template>
  <div
    class="min-h-[36px] py-1.5 bg-n-alpha-white gap-2 overflow-hidden items-center flex px-2 rounded-lg border border-n-container"
  >
    <FileIcon class="flex-shrink-0" :file-type="fileDetails.type" />
    <div class="flex-1 min-w-0 flex flex-col justify-center">
      <span
        class="truncate text-sm max-w-36"
        :title="fileDetails.name"
        :class="textColorClass"
      >
        {{ displayFileName }}
      </span>
      <span v-if="fileSize" class="text-[11px] font-medium text-n-slate-11">
        {{ fileSize }}
      </span>
    </div>
    <a
      v-tooltip="t('CONVERSATION.DOWNLOAD')"
      class="flex-shrink-0 size-9 grid place-content-center cursor-pointer text-n-slate-11 hover:text-n-slate-12 transition-colors"
      :href="attachment?.dataUrl || attachment?.data_url"
      rel="noreferrer noopener nofollow"
      target="_blank"
    >
      <Icon icon="i-lucide-download" />
    </a>
  </div>
</template>
