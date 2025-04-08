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
        'bg-linear-secondary-x-l text-white hover:bg-primary-800 disable:bg-primary-300',
      surface: 'bg-primary-100 text-primary-700 hover:text-primary-800 disable:text-primary-300',
      outline: 'outline-primary-700 bg-white text-primary-700 hover:bg-primary-100 disable:text-primary-400 disable:outline-primary-300',
    },
    secondary: {
      solid:
        'bg-destructive-500 text-white hover:bg-destructive-600 disable:bg-destructive-300',
      surface:
        'bg-destructive-50 text-destructive-500 hover:bg-destructive-100 hover:text-destructive-600 disable:bg-destructive-300 disable:text-destructive-50',
      outline: 'bg-white text-destructive-500 outline-destructive-500 hover:bg-destructive-50 disable:outline-destructive-300 disable:bg-destructive-300 disabled:text-destructive-400',
    },
  },
  sizes: {
    regular: {
      sm: 'h-8 w-[8.375rem] px-3 py-[0.375rem]',
      md: 'h-10 w-40 px-3 py-1',
      lg: 'h-12 w-48 px-6 py-3',
    },

  },
  fontSize: {
    sm: 'text-xs',
    md: 'text-sm',
    lg: 'text-base',
  },
  justify: {
    start: 'justify-start',
    center: 'justify-center',
    end: 'justify-end',
  },
  base: 'rounded-lg inline-flex items-center min-w-0 gap-2 transition-all duration-200 ease-in-out border-0 rounded-lg outline-1 outline gap-[0.375rem] cursor-pointer',
};

const variantClasses = computed(() => {
  const variantMap = {
    ghost: `${STYLE_CONFIG.colors[computedColor.value].ghost}`,
    link: `${
      STYLE_CONFIG.colors[computedColor.value].link
    } p-0 font-medium underline-offset-4`,
    outline: STYLE_CONFIG.colors[computedColor.value].outline,
    faded: STYLE_CONFIG.colors[computedColor.value].faded,
    solid: STYLE_CONFIG.colors[computedColor.value].solid,
  };

  return variantMap[computedVariant.value];
});

const isIconOnly = computed(() => !props.label && !slots.default);
const isLink = computed(() => computedVariant.value === 'link');

const buttonClasses = computed(() => {
  const sizeConfig = isIconOnly.value ? 'iconOnly' : 'regular';
  const classes = [
    variantClasses.value,
    computedVariant.value !== 'link' &&
      STYLE_CONFIG.sizes[sizeConfig][computedSize.value],
  ].filter(Boolean);

  return classes.join(' ');
});

const linkButtonClasses = computed(() => {
  const classes = [
    variantClasses.value,
    STYLE_CONFIG.sizes.link[computedSize.value],
  ].filter(Boolean);

  return classes.join(' ');
});
</script>

<template>
  <button
    v-bind="filteredAttrs"
    :class="{
      [STYLE_CONFIG.base]: true,
      [isLink ? linkButtonClasses : buttonClasses]: true,
      [STYLE_CONFIG.fontSize[computedSize]]: true,
      [STYLE_CONFIG.justify[computedJustify]]: true,
      'flex-row-reverse': trailingIcon && !isIconOnly,
    }"
  >
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
