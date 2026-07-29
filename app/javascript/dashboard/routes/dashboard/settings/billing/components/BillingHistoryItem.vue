<script setup>
defineProps({
  item: {
    type: Object,
    required: true,
  },
});
</script>

<template>
  <div
    class="flex items-center justify-between rounded-xl shadow-sm border border-n-weak bg-n-solid-2 p-2"
  >
    <div class="flex items-center gap-10">
      <span class="pl-2 text-sm text-n-slate-11 w-28">{{
        item.created_date_formatted
      }}</span>
      <span class="text-sm text-n-slate-11 w-28 text-right">{{
        item.amount_formatted
      }}</span>
      <span class="text-sm text-n-slate-11">{{ item.content }}</span>
    </div>

    <div class="flex items-center gap-2">
      <a
        v-if="item.einvoice_url"
        :href="item.einvoice_url"
        target="_blank"
        rel="noopener noreferrer"
        class="px-4 py-2 rounded-lg text-sm font-medium text-n-blue-11 hover:bg-n-blue-3 transition-colors flex items-center gap-1"
      >
        <span class="i-woot-document-download text-lg" />
        {{ $t('BILLING_SETTINGS.INVOICE') || 'Hóa đơn' }}
      </a>
      <button class="px-4 py-2 rounded-lg text-sm text-n-slate-11">
        {{ item.status_text }}
      </button>
    </div>
  </div>
</template>
