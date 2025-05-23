<script setup>
defineProps({
  label: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div class="px-5">
    <span class="i-lucide-bolt size-4 text-n-slate-11 mr-2" />
    <span class="text-n-slate-11 text-xs">
      {{ label }}
    </span>
  </div>
</template>
