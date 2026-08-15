<script setup>
import { computed, ref, watch, onMounted } from 'vue';
import { useMessageContext } from '../provider.js';
import BaseBubble from './Base.vue';
import { copyTextToClipboard } from 'shared/helpers/clipboard';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

const { contentAttributes } = useMessageContext();
const { t } = useI18n();

const contentData = computed(() => {
  return contentAttributes.value?.data || {};
});

const bankName = computed(() => contentData.value.bankName);
const accountNumber = computed(() => contentData.value.accountNumber);
const accountHolder = computed(() => contentData.value.accountHolder);
const vietQrString = computed(() => contentData.value.vietQr);
const title = computed(() => contentData.value.title || '[Tài khoản ngân hàng]');

const onCopyAccountNumber = async () => {
  if (!accountNumber.value) return;
  await copyTextToClipboard(accountNumber.value);
  useAlert(t('COMPONENTS.CODE.COPY_SUCCESSFUL'));
};

</script>

<template>
  <BaseBubble class="overflow-hidden p-3" data-bubble-name="bank-card">
    <div class="grid gap-3 min-w-[240px] max-w-sm">
      <div class="flex items-center gap-3 border-b border-n-container pb-3 mb-1">
        <div class="size-10 rounded-full flex items-center justify-center bg-[#3B82F6] shrink-0">
          <div class="text-white size-5 i-lucide-credit-card" />
        </div>
        <div class="flex-1 overflow-hidden">
          <div class="truncate font-medium text-sm text-n-slate-12">
            {{ title }}
          </div>
          <div v-if="bankName" class="truncate text-xs text-n-slate-11 mt-0.5">
            {{ bankName }}
          </div>
        </div>
      </div>
      
      <div v-if="accountNumber || accountHolder" class="space-y-3">
        <div v-if="accountNumber" class="flex flex-col items-start">
          <span class="text-xs text-n-slate-11 mb-0.5">{{ $t('COMPONENTS.BANK_CARD_BUBBLE.ACCOUNT_NUMBER') }}</span>
          <button 
            class="flex items-center gap-1.5 text-left hover:bg-slate-50 dark:hover:bg-slate-800 -ml-1.5 p-1.5 rounded-md transition-colors group" 
            @click="onCopyAccountNumber"
            :title="$t('COMPONENTS.CODE.BUTTON_TEXT')"
          >
            <span class="font-medium text-sm text-n-slate-12 break-all">{{ accountNumber }}</span>
            <span class="i-lucide-copy size-3.5 text-n-slate-10 opacity-0 group-hover:opacity-100 transition-opacity shrink-0" />
          </button>
        </div>
        
        <div v-if="accountHolder" class="flex flex-col">
          <span class="text-xs text-n-slate-11 mb-0.5">{{ $t('COMPONENTS.BANK_CARD_BUBBLE.ACCOUNT_HOLDER') }}</span>
          <span class="font-medium text-sm text-n-slate-12 uppercase break-words">{{ accountHolder }}</span>
        </div>
      </div>
      <div v-else class="text-sm text-n-slate-11 italic">
        {{ $t('COMPONENTS.BANK_CARD_BUBBLE.FALLBACK_TEXT') }}
      </div>

    </div>
  </BaseBubble>
</template>
