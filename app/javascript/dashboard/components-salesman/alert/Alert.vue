<script setup>
import { computed, ref, useAttrs } from 'vue';

import {
  VARIANT_OPTIONS,
  COLOR_OPTIONS,
  SIZE_OPTIONS,
} from './constants.js';

const props = defineProps({
  variant: {
    type: String,
    default: null,
    validator: value => VARIANT_OPTIONS.includes(value) || value === null,
  },
  color: {
    type: String,
    default: null,
    validator: value => COLOR_OPTIONS.includes(value) || value === null,
  },
  size: {
    type: String,
    default: null,
    validator: value => SIZE_OPTIONS.includes(value) || value === null,
  },
  icon: { type: [String, Object, Function], default: '' },
  isLoading: { type: Boolean, default: false },
  closeButton: { type: Boolean, default: true },
  customClass: { type: [String], default: '' },
  header: { type: [String], default: '' },
  description: { type: [String], default: '' },
  footer: { type: [String], default: '' },

});

const attrs = useAttrs();

defineOptions({
  inheritAttrs: false,
});

const isClose = ref(false);

const computedColor = computed(() => {
  if (props.color) return props.color;
  if (attrs.primary || attrs.primary === '') return 'primary';
  if (attrs.neutral || attrs.neutral === '') return 'neutral';
  if (attrs.success || attrs.success === '') return 'success';
  if (attrs.warning || attrs.warning === '') return 'warning';
  if (attrs.danger || attrs.danger === '') return 'danger';
  return 'primary'; // Default color
});

const computedSize = computed(() => {
  if (props.size) return props.size;
  if (attrs.sm || attrs.sm === '') return 'sm';
  if (attrs.md || attrs.md === '') return 'md';
  if (attrs.lg || attrs.lg === '') return 'lg';
  return 'md';
});


const STYLE_CONFIG = {
  colors: {
    neutral:
      'bg-light-neutral-s border-light-neutral-stoke-bold',
    primary:
      'bg-primary-100 border-primary-400',
    success:
      'bg-success-100 border-success-400',
    warning:
      'bg-warning-100 border-warning-400',
    danger:
      'bg-destructive-100 border-destructive-400',
  },
  sizes: {
    md: 'min-w-[56rem] px-[1.5rem] gap-3',
  },
  fontSize: {
    sm: 'text-xs',
    md: 'text-sm',
    lg: 'text-sm',
  },
  textColor: {
    primary: {
      other: 'text-primary-800',
      description: 'text-primary-700',
      closeIcon: '#386BB7'
    },
    neutral: {
      other: 'text-light-neutral-primary',
      description: 'text-light-neutral-secondary',
      closeIcon: '#878787'

    },
    success: {
      other: 'text-success-900',
      description: 'text-success-800',
      closeIcon: '#22C55E'

    },
    warning: {
      other: 'text-warning-900',
      description: 'text-warning-800',
      closeIcon: '#F59E0B'

    },
    danger: {
      other: 'text-destructive-900',
      description: 'text-destructive-800',
      closeIcon: '#EF4444'

    },

  },
  base: 'px-[1.5rem] flex relative p-4 items-start border rounded-md',
};


</script>

<template>
  <div :class="{
    [STYLE_CONFIG.base]: true,
    [STYLE_CONFIG.sizes[computedSize]]: true,
    [STYLE_CONFIG.colors[computedColor]]: true,
    [STYLE_CONFIG.fontSize[computedSize]]: true,
    [STYLE_CONFIG.textColor[computedColor].other]: true,
    [customClass]: true
  }" v-if="!isClose">
    <span class="inline-flex items-center w-4 h-4 flex-shrink-0">
      <slot v-if="icon" name="icon">
        <component :is="icon" />
      </slot>
    </span>
    <div class="flex flex-col flex-1 ">

      <header class="mb-3">
        <slot v-if="header === ''" name="header" />
        <h1 v-else class="text-inherit">

          {{ header }}
        </h1>
      </header>

      <main class="flex-grow mb-3.5" :class="{
        [STYLE_CONFIG.textColor[computedColor].description]: true
      }">
        <slot name="description" />
      </main>


      <footer class="mt-auto">
        <slot name="footer" />
      </footer>
    </div>
    <span v-if="closeButton">
      <button v-on:click="isClose = true">
        <svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14" fill="none">
          <path d="M12.8346 1.16663L1.16797 12.8333M1.16797 1.16663L12.8346 12.8333"
            :stroke="STYLE_CONFIG.textColor[computedColor].closeIcon" stroke-width="1.5" stroke-linecap="round"
            stroke-linejoin="round" />
        </svg>
      </button>
    </span>
  </div>

</template>
<style lang="css" scoped></style>