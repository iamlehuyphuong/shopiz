<script setup>
import { computed, useSlots, useAttrs } from 'vue';

import {
  COLOR_OPTIONS,
  SIZE_OPTIONS,
  EXCLUDED_ATTRS,
} from './constants.js';

const props = defineProps({
  label: { type: [String, Number], default: '' },
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
    primary: {
       outside: 'border-primary-700 peer-checked:border-primary-700',
       inside: 'bg-primary-700'
      },
    secondary: 'bg-destructive-500 text-white hover:bg-destructive-600 active:bg-destructive-600 active:text-destructive-200 disable:bg-destructive-300',
  },
  sizes: {
    outside:{
      md: 'w-5 h-5',
    },
    inside:{
      md: 'w-2.5 h-2.5',
    }
  },
  base: {
    outside: 'relative flex items-center cursor-pointer rounded-full border-2 justify-center transition-colors ',
    inside: 'rounded-full scale-0 transform peer-checked:scale-100'
  }
};

const outSideColorClasses = computed(() => {
  return `${STYLE_CONFIG.colors[computedColor.value].outside}`;
});


const radioBoxClasses = computed(() => {
  const classes = [
  outSideColorClasses.value,
      STYLE_CONFIG.sizes.outside[computedSize.value],
  ].filter(Boolean);

  return classes.join(' ');
});

const radioInsideClasses = computed(() => {
  const classes = [
  `${STYLE_CONFIG.colors[computedColor.value].inside}`,
      STYLE_CONFIG.sizes.inside[computedSize.value],
  ].filter(Boolean);

  return classes.join(' ');
});
</script>

<template>
<label :class="{
    [STYLE_CONFIG.base.outside]: true,
    [radioBoxClasses]:true
    }" 
    >
  <input
    v-bind="filteredAttrs"
    type="radio"
    class="peer sr-only"
  />
    <div
    :class="{
    [STYLE_CONFIG.base.inside]: true,
    [radioInsideClasses]: true
    }" 
    ></div>
</label>

</template>
