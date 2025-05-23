export const VARIANT_OPTIONS = ['solid','surface' ,'outline' ];
export const COLOR_OPTIONS = ['primary', 'secondary'];
export const SIZE_OPTIONS = ['sm', 'md', 'lg'];
export const JUSTIFY_OPTIONS = ['start', 'center', 'end'];

export const EXCLUDED_ATTRS = [
  'variant',
  'color',
  'size',
  'icon',
  'trailingIcon',
  'leftIcon',
  'rightIcon',
  'isLoading',
  'disable',
  ...VARIANT_OPTIONS,
  ...COLOR_OPTIONS,
  ...SIZE_OPTIONS,
  ...JUSTIFY_OPTIONS,
];
