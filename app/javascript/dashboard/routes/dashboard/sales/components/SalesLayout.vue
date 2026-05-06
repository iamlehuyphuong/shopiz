<script setup>
defineProps({
  isLoading: {
    type: Boolean,
    default: false,
  },
  noRecordsFound: {
    type: Boolean,
    default: false,
  },
  loadingMessage: {
    type: String,
    default: '',
  },
  noRecordsMessage: {
    type: String,
    default: '',
  },
});
</script>

<template>
  <div class="flex flex-col w-full h-full m-0 bg-n-surface-1 overflow-hidden">
    <main class="flex-1 overflow-y-auto p-6 sm:py-8 lg:px-16">
      <div class="flex flex-col w-full gap-4 font-inter max-w-5xl mx-auto min-h-full">
        <slot name="header" />
        <slot name="preBody" />
        <slot v-if="isLoading" name="loading">
          <woot-loading-state :message="loadingMessage" />
        </slot>
        <p
          v-else-if="noRecordsFound"
          class="flex-1 py-20 text-n-slate-12 flex items-center justify-center text-base"
        >
          {{ noRecordsMessage }}
        </p>
        <slot v-else name="body" />
        <slot />
      </div>
    </main>
    <footer v-if="$slots.footer" class="w-full bg-n-surface-1 py-2 z-10">
      <div class="w-full max-w-5xl mx-auto px-6 lg:px-16 sm:px-8">
        <slot name="footer" />
      </div>
    </footer>
  </div>
</template>
