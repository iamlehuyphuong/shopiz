<script setup>
defineProps({
  title: {
    type: String,
    required: true,
  },
  price: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div class="grid grid-cols-[1fr_auto] gap-5">
    <div>
      <span class="text-base font-medium text-n-slate-12">
        {{ title }}
      </span>
      <p class="text-base font-medium text-n-slate-12">
        {{ price }}
      </p>
      <p class="text-sm mt-1 text-n-slate-11">
        {{ description }}
      </p>
      <slot />
    </div>
  </div>
</template>
