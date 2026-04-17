<script>
import Spinner from 'shared/components/Spinner.vue';

export default {
  components: {
    Spinner,
  },
  props: {
    disabled: {
      type: Boolean,
      default: false,
    },
    loading: {
      type: Boolean,
      default: false,
    },
    buttonText: {
      type: String,
      default: '',
    },
    buttonClass: {
      type: String,
      default: '',
    },
    iconClass: {
      type: String,
      default: '',
    },
    spinnerClass: {
      type: String,
      default: '',
    },
    type: {
      type: String,
      default: 'submit',
    },
  },
  computed: {
    computedClass() {
      return `button nice gap-2 ${this.buttonClass || ' '}`;
    },
  },
};
</script>

<template>
  <button
    :type="type"
    data-testid="submit_button"
    :disabled="disabled"
    :class="computedClass"
  >
    <fluent-icon v-if="!!iconClass" :icon="iconClass" class="icon" />
    <span>{{ buttonText }}</span>
    <Spinner v-if="loading" class="ml-2" :color-scheme="spinnerClass" />
  </button>
</template>

<style lang="scss" scoped>
button:disabled {
  background-color: rgba(224, 103, 32, 0.1);
  opacity: 1;
  html.dark & {
    background-color: rgba(224, 103, 32, 0.25);
    color: #64748b; /* slate-500 */
  }
  &:hover {
    background-color: rgba(224, 103, 32, 0.1);
    html.dark & {
      background-color: rgba(224, 103, 32, 0.25);
    }
  }
}
</style>
