<script setup>
import { computed, useAttrs } from 'vue';

import {
  COLOR_OPTIONS,
  SIZE_OPTIONS,
  EXCLUDED_ATTRS,
} from './constants.js';

const props = defineProps({

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

});

const attrs = useAttrs();

defineOptions({
  inheritAttrs: false,
});

const filteredAttrs = computed(() => {
  const standardAttrs = {};

  Object.entries(attrs)
    .filter(([key]) => !EXCLUDED_ATTRS.includes(key))
    .forEach(([key, value]) => {
      standardAttrs[key] = value;
    });

  return standardAttrs;
});


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
    primary: 'peer-focus:ring-primary-100 dark:peer-focus:ring-primary-800 peer-checked:bg-primary-700 dark:peer-checked:bg-primary-700',
  },
  sizes: {
    md: 'w-10 h-6 after:h-5 after:w-5',
  },
  base: "relative bg-light-neutral-s2 rounded-full peer peer-focus:ring-2 peer-checked:after:translate-x-full rtl:peer-checked:after:-translate-x-full dark:bg-n-slate-7 peer-checked:after:border-white after:content-[''] after:absolute after:top-0.5 after:start-[-1px] after:bg-white after:border-n-gray-3 after:border after:rounded-full after:transition-all dark:border-n-gray-6",
};

const colorClass = computed(() => {
  return `${STYLE_CONFIG.colors[computedColor.value]}`;
});


const switcherClasses = computed(() => {
  const classes = [
    colorClass.value,
    STYLE_CONFIG.sizes[computedSize.value],
  ].filter(Boolean);

  return classes.join(' ');
});

</script>

<template>
  <label class="inline-flex items-center cursor-pointer">
    <input v-bind="filteredAttrs" type="checkbox" value="" class="sr-only peer" checked />
    <div :class="{
      [STYLE_CONFIG.base]: true,
      [switcherClasses]: true,
    }"></div>
  </label>



</template>
