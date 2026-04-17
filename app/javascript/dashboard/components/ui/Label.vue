<script>
import { getContrastingTextColor } from '@chatwoot/utils';

export default {
  props: {
    title: {
      type: String,
      required: true,
    },
    description: {
      type: String,
      default: '',
    },
    href: {
      type: String,
      default: '',
    },
    bgColor: {
      type: String,
      default: '',
    },
    small: {
      type: Boolean,
      default: false,
    },
    showClose: {
      type: Boolean,
      default: false,
    },
    icon: {
      type: String,
      default: '',
    },
    color: {
      type: String,
      default: '',
    },
    colorScheme: {
      type: String,
      default: '',
    },
    variant: {
      type: String,
      default: '',
    },
  },
  emits: ['remove'],
  computed: {
    textColor() {
      if (this.variant === 'smooth') return '';
      if (this.variant === 'dashed') return '';
      return this.color || getContrastingTextColor(this.bgColor);
    },
    labelClass() {
      return `label ${this.colorScheme} ${this.variant} ${
        this.small ? 'small' : ''
      }`;
    },
    labelStyle() {
      if (this.bgColor) {
        return {
          background: this.bgColor,
          color: this.textColor,
          border: `1px solid ${this.bgColor}`,
        };
      }
      return {};
    },
    anchorStyle() {
      if (this.bgColor) {
        return { color: this.textColor };
      }
      return {};
    },
  },
  methods: {
    onClick() {
      this.$emit('remove', this.title);
    },
  },
};
</script>

<template>
  <div
    class="inline-flex ltr:mr-1 rtl:ml-1 mb-1"
    :class="labelClass"
    :style="labelStyle"
    :title="description"
  >
    <span v-if="icon" class="label-action--button">
      <fluent-icon :icon="icon" size="12" class="label--icon cursor-pointer" />
    </span>
    <span
      v-if="['smooth', 'dashed'].includes(variant) && title && !icon"
      :style="{ background: color }"
      class="label-color-dot flex-shrink-0"
    />
    <span v-if="!href" class="whitespace-nowrap text-ellipsis overflow-hidden">
      {{ title }}
    </span>
    <a v-else :href="href" :style="anchorStyle">{{ title }}</a>
    <button
      v-if="showClose"
      class="label-close--button p-0"
      :style="{ color: textColor }"
      @click="onClick"
    >
      <fluent-icon icon="dismiss" size="12" class="close--icon" />
    </button>
  </div>
</template>

<style scoped lang="scss">
.label {
  @apply items-center font-medium text-xs rounded-[4px] gap-1 p-1 bg-n-slate-3 text-n-slate-12 border border-solid border-n-strong h-6;

  &.small {
    @apply text-xs py-0.5 px-1 leading-tight h-5;
  }

  &.small .label--icon,
  &.small .close--icon {
    @apply text-[0.5rem];
  }

  a {
    @apply text-xs;
    &:hover {
      @apply underline;
    }
  }

  /* Color Schemes */
  &.primary {
    background-color: rgb(var(--orange-5));
    color: rgb(var(--orange-12));
    border-color: rgb(var(--orange-7));

    a {
      color: rgb(var(--orange-12));
    }
    .label-color-dot {
      background-color: rgb(var(--orange-9));
    }
  }
  &.secondary {
    background-color: rgb(var(--slate-5));
    color: rgb(var(--slate-12));
    border-color: rgb(var(--slate-7));

    a {
      color: rgb(var(--slate-12));
    }
    .label-color-dot {
      background-color: rgb(var(--slate-9));
    }
  }
  &.success {
    background-color: rgb(var(--teal-5));
    color: rgb(var(--teal-12));
    border-color: rgb(var(--teal-7));

    a {
      color: rgb(var(--teal-12));
    }
    .label-color-dot {
      background-color: rgb(var(--teal-9));
    }
  }
  &.alert {
    background-color: rgb(var(--ruby-5));
    color: rgb(var(--ruby-12));
    border-color: rgb(var(--ruby-7));

    a {
      color: rgb(var(--ruby-12));
    }
    .label-color-dot {
      background-color: rgb(var(--ruby-9));
    }
  }
  &.warning {
    background-color: rgb(var(--amber-5));
    color: rgb(var(--amber-12));
    border-color: rgb(var(--amber-7));

    a {
      color: rgb(var(--amber-12));
    }
    .label-color-dot {
      background-color: rgb(var(--amber-9));
    }
  }

  &.smooth {
    @apply bg-transparent text-n-slate-11 dark:text-n-slate-12 border border-solid border-n-strong;
  }

  &.dashed {
    @apply bg-transparent text-n-slate-11 dark:text-n-slate-12 border border-dashed border-n-strong;
  }
}

.label-close--button {
  @apply text-n-slate-11 -mb-0.5 rounded-sm cursor-pointer flex items-center justify-center hover:bg-n-slate-3;

  svg {
    @apply text-n-slate-11;
  }
}

.label-action--button {
  @apply flex mr-1;
}

.label-color-dot {
  @apply inline-block w-3 h-3 rounded-sm shadow-sm;
}
.label.small .label-color-dot {
  @apply w-2 h-2 rounded-sm shadow-sm;
}
</style>
