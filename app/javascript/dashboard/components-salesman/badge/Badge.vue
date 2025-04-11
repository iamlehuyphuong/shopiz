<script setup>
import { computed, useSlots, useAttrs } from 'vue';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import {
  VARIANT_OPTIONS,
  COLOR_OPTIONS,
  JUSTIFY_OPTIONS,
  SIZE_OPTIONS,
  EXCLUDED_ATTRS,
} from './constants.js';

const props = defineProps({
  label: { type: [String, Number], default: '' },
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
  justify: {
    type: String,
    default: null,
    validator: value => JUSTIFY_OPTIONS.includes(value) || value === null,
  },
  startIcon: { type: [String, Object, Function], default: '' },
  endIcon: { type: [String, Object, Function], default: '' },
  trailingIcon: { type: Boolean, default: false },
  isLoading: { type: Boolean, default: false },
});

const slots = useSlots();
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

const computedVariant = computed(() => {
  if (props.variant) return props.variant;
  // The useAttrs method returns attributes values an empty string (not boolean value as in props).
  if (attrs.solid || attrs.solid === '') return 'solid';
  if (attrs.outline || attrs.outline === '') return 'outline';
  if (attrs.surface || attrs.surface === '') return 'faded';
  return 'solid'; // Default variant
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

const computedJustify = computed(() => {
  if (props.justify) return props.justify;
  if (attrs.start || attrs.start === '') return 'start';
  if (attrs.center || attrs.center === '') return 'center';
  if (attrs.end || attrs.end === '') return 'end';

  return 'center';
});

const STYLE_CONFIG = {
  colors: {
    primary: {
      solid:
        'bg-primary-700 text-white hover:bg-primary-800 disable:bg-primary-300',
      surface: 'bg-primary-100 text-primary-700 hover:text-primary-800 disable:text-primary-300',
      outline: 'outline-primary-700 bg-white text-primary-700 hover:bg-primary-100 disable:text-primary-400 disable:outline-primary-300',
    },
    neutral: {
      solid:
        'bg-light-neutral-primary text-white hover:bg-light-neutral-secondary disbale:text-light-neutral-strokeLight disable:bg-light-neutral-s2',
      surface:
        'bg-light-neutral-s text-light-neutral-secondary hover:bg-light-neutral-secondary hover:text-light-neutral-primary disable:bg-light-neutral-s disable:text-light-neutral-stokeLight',
      outline: 'bg-white outline-light-neutral-s2 text-light-neutral-primary hover:bg-light-Neutral-s hover:outline-light-neutral-stroke-bold',

    },
    success: {
      solid:
        'bg-success-500 text-white hover:bg-success-600 disabled:bg-success-300',
      surface:
        'bg-success-50 text-success-500 hover:bg-success-100 hover:text-success-600 disable:bg-success-50 disable:text-success-300',
      outline:
        'bg-white outline-success-500 text-success-500 hover:bg-success-50 disable:outline-success-300 disable:text-success-400',
    },
    warning: {
      solid:
        'bg-warning-500 text-white hover:bg-warning-600 disable:bg-warning-300',
      surface:
        'bg-warning-50 text-warning-500 hover:bg-warning-100 hover:text-warning-600 disable:bg-warning-50 disable:text-warning-300',
      outline: 'outline-warning-500 text-warning-500 hover:bg-warning-50 disable:bg-warning-300 disable:bg-warning-400',
    },
    danger: {
      solid:
        'bg-destructive-500 text-white hover:bg-destructive-600 disable:bg-destructive-300',
      surface:
        'bg-destructive-50 text-destructive-500 hover:bg-destructive-100 hover:text-destructive-600 disable:bg-destructive-300 disable:text-destructive-50',
      outline: 'bg-white text-destructive-500 outline-destructive-500 hover:bg-destructive-50 disable:outline-destructive-300 disable:bg-destructive-300 disabled:text-destructive-400',
    },
  },
  sizes: {
    sm: 'h-6 w-[6.25rem]',
    md: 'h-7 w-28 px-3 py-1',
    lg: 'h-8 w-[7.5rem] px-4 py-[0.375rem] px-0.5 py-2.5',
  },
  fontSize: {
    sm: 'text-xs',
    md: 'text-sm',
    lg: 'text-sm',
  },
  justify: {
    start: 'justify-start',
    center: 'justify-center',
    end: 'justify-end',
  },
  base: 'rounded-3xl inline-flex items-center min-w-0 gap-2 transition-all duration-200 ease-in-out border-0 outline-1 outline gap-[0.375rem] cursor-pointer',
};

const variantClasses = computed(() => {
  const variantMap = {
    ghost: `${STYLE_CONFIG.colors[computedColor.value].ghost}`,
    link: `${STYLE_CONFIG.colors[computedColor.value].link
      } p-0 font-medium underline-offset-4`,
    outline: STYLE_CONFIG.colors[computedColor.value].outline,
    faded: STYLE_CONFIG.colors[computedColor.value].faded,
    solid: STYLE_CONFIG.colors[computedColor.value].solid,
  };

  return variantMap[computedVariant.value];
});

const isIconOnly = computed(() => !props.label && !slots.default);

const buttonClasses = computed(() => {
  const classes = [
    variantClasses.value,
    STYLE_CONFIG.sizes[computedSize.value],
  ].filter(Boolean);

  return classes.join(' ');
});

</script>

<template>
  <button v-bind="filteredAttrs" :class="{
    [STYLE_CONFIG.base]: true,
    [buttonClasses]: true,
    [STYLE_CONFIG.fontSize[computedSize]]: true,
    [STYLE_CONFIG.justify[computedJustify]]: true,
    'flex-row-reverse': trailingIcon && !isIconOnly,
  }">
    <slot v-if="startIcon && !isLoading" name="icon">
      <Icon :icon="startIcon" class="flex-shrink-0" />
    </slot>

    <slot v-if="label || $slots.default" name="default">
      <span v-if="label" class="min-w-0 truncate">{{ label }}</span>
    </slot>


    <slot v-if="endIcon && !isLoading" name="icon">
      <Icon :icon="endIcon" class="flex-shrink-0" />
    </slot>
  </button>
</template>
