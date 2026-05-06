<script setup>
defineProps({
  label: { type: String, required: true },
  value: { type: String, required: true },
  changePercent: { type: Number, default: null },
});
</script>

<template>
  <div
    class="flex flex-col gap-2 p-5 rounded-xl bg-white dark:bg-n-solid-1 border border-n-weak shadow-sm min-w-0 flex-1"
  >
    <span class="text-xs font-medium text-n-slate-11 uppercase tracking-wide">
      {{ label }}
    </span>
    <p class="text-2xl font-semibold text-n-slate-12 mb-0 tabular-nums">
      {{ value }}
    </p>
    <div v-if="changePercent !== null" class="flex items-center gap-1">
      <span
        class="text-xs font-medium"
        :class="
          changePercent >= 0
            ? 'text-n-teal-11'
            : 'text-n-ruby-11'
        "
      >
        <span v-if="changePercent >= 0">↑</span>
        <span v-else>↓</span>
        {{ Math.abs(changePercent).toFixed(1) }}%
      </span>
      <span class="text-[10px] text-n-slate-10">
        {{ $t('SALES.MODULE_DASHBOARD.METRICS.VS_PREVIOUS') }}
      </span>
    </div>
  </div>
</template>
