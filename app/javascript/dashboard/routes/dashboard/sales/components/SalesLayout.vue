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
  <div
    class="flex flex-col w-full h-full m-0 p-6 sm:py-8 lg:px-16 overflow-auto bg-n-background"
  >
    <div class="flex-1 flex items-start w-full max-w-5xl mx-auto">
      <div class="flex flex-col w-full h-full gap-4 font-inter">
        <slot name="header" />
        <main>
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
        </main>
      </div>
    </div>
    <footer v-if="$slots.footer" class="sticky bottom-0 z-0">
      <slot name="footer" />
    </footer>
  </div>
</template>
