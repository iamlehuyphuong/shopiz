<script setup>
defineProps({
  label: {
    type: String,
    required: true,
  },
});
</script>

<template>
  <div>
    <span class="text-n-slate-11 text-xs">
      {{ label }}
    </span>
  </div>
</template>
