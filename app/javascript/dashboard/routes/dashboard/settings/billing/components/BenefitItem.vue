<script setup>
defineProps({
  label: {
    type: String,
    required: true,
  },
  count: {
    type: [Number, String],
    default: null,
  },
  included: {
    type: Boolean,
    default: true,
  },
  status: {
    type: String,
    default: null,
  },
});
</script>

<template>
  <div class="flex items-center justify-start my-1.5">
    <svg
      v-if="included"
      xmlns="http://www.w3.org/2000/svg"
      class="w-[17px] h-[17px] text-green-500 mr-2.5 shrink-0"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2.5"
      stroke-linecap="round"
      stroke-linejoin="round"
    >
      <circle cx="12" cy="12" r="10" />
      <path d="m9 12 2 2 4-4" />
    </svg>
    <svg
      v-else
      xmlns="http://www.w3.org/2000/svg"
      class="w-[17px] h-[17px] text-red-500 mr-2.5 shrink-0"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      stroke-width="2.5"
      stroke-linecap="round"
      stroke-linejoin="round"
    >
      <circle cx="12" cy="12" r="10" />
      <path d="m15 9-6 6" />
      <path d="m9 9 6 6" />
    </svg>
    <span
      class="text-[13px] font-medium flex items-center gap-1.5"
      :class="included ? 'text-n-slate-12' : 'text-n-slate-8'"
    >
      {{
        count !== null && count !== undefined
          ? $t(label, { count: count })
          : $t(label)
      }}
      <span
        v-if="status === 'beta'"
        class="text-[9px] uppercase font-bold px-1.5 py-0.5 rounded-md bg-n-blue-3 text-n-blue-11 leading-none border border-n-blue-5"
      >
        BETA
      </span>
    </span>
  </div>
</template>
