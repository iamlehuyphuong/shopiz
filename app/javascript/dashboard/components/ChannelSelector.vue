<script setup>
import Icon from 'next/icon/Icon.vue';

defineProps({
  title: {
    type: String,
    required: true,
  },
  description: {
    type: String,
    default: '',
  },
  icon: {
    type: String,
    required: true,
  },
  status: {
    type: String,
    default: 'published',
  },
});
</script>

<template>
  <button
    class="relative bg-n-solid-1 gap-6 cursor-pointer rounded-2xl flex flex-col justify-start transition-all duration-200 ease-in -m-px py-6 px-5 items-start border border-solid border-n-weak"
    :class="{
      'hover:enabled:border-n-orange-9 hover:enabled:shadow-md disabled:opacity-60 disabled:cursor-not-allowed':
        status !== 'coming_soon',
      'cursor-not-allowed disabled:opacity-80': status === 'coming_soon',
    }"
  >
    <div
      class="flex size-10 items-center justify-center rounded-full bg-n-alpha-2"
    >
      <Icon :icon="icon" class="text-n-slate-10 size-6" />
    </div>

    <div class="flex flex-col items-start gap-1.5">
      <h3 class="text-n-slate-12 text-sm text-start font-medium capitalize">
        {{ title }}
      </h3>
      <p class="text-n-slate-11 text-start text-sm">
        {{ description }}
      </p>
    </div>

    <div
      v-if="status === 'beta'"
      class="absolute top-4 right-4 bg-n-blue-9 text-white text-[11px] font-bold px-2 py-0.5 rounded-md tracking-wide uppercase shadow-sm"
    >
      Beta
    </div>

    <div
      v-if="status === 'coming_soon'"
      class="absolute inset-0 flex items-center justify-center backdrop-blur-[1px] rounded-2xl bg-gradient-to-br from-n-surface-1/50 via-n-surface-1/40 to-n-surface-1/60 cursor-not-allowed"
    >
      <span class="text-n-slate-12 font-medium text-sm">
        {{ $t('CHANNEL_SELECTOR.COMING_SOON') }} 🚀
      </span>
    </div>
  </button>
</template>
