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

    <button class="px-4 py-2 rounded-lg text-sm text-n-slate-11">
      {{ item.status_text }}
    </button>
  </div>
</template>
