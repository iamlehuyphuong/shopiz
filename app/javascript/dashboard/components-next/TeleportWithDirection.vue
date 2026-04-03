<!--
 * Preserves RTL/LTR context when teleporting content
 * Ensures direction-specific classes (ltr:tailwind-class, rtl:tailwind-class) work correctly
 * when content is teleported outside the app's container with [dir] attribute
-->
<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

defineProps({
  to: {
    type: String,
    default: 'body',
  },
  disabled: {
    type: Boolean,
    default: false,
  },
});

const isRTL = useMapGetter('accounts/isRTL');

const contentDirection = computed(() => (isRTL.value ? 'rtl' : 'ltr'));
</script>

<template>
  <Teleport :to="to" :disabled="disabled">
    <div :dir="contentDirection" class="contents">
      <slot />
    </div>
  </Teleport>
</template>
