<script setup>
import { isVNode, computed } from 'vue';
import Icon from 'next/icon/Icon.vue';

const props = defineProps({
  label: { type: String, required: true },
  to: { type: [String, Object], required: true },
  icon: { type: [String, Object], default: null },
  active: { type: Boolean, default: false },
  component: { type: Function, default: null },
  isLocked: { type: Boolean, default: false },
  featureFlag: { type: String, default: '' },
});

const emit = defineEmits(['toggleLocked']);

const shouldRenderComponent = computed(() => {
  return typeof props.component === 'function' || isVNode(props.component);
});

// A locked item should not navigate, it opens the paywall modal instead
const renderAsLink = computed(() => Boolean(props.to) && !props.isLocked);
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <li
    class="py-0.5 ltr:pl-2 rtl:pr-2 rtl:mr-3 ltr:ml-3 relative text-n-slate-11 child-item before:bg-n-slate-4 after:bg-transparent after:border-n-slate-4 before:left-0 rtl:before:right-0 min-w-0 transition-opacity duration-200"
    :class="{ 'opacity-50': isLocked }"
  >
    <component
      :is="renderAsLink ? 'router-link' : 'div'"
      :to="renderAsLink ? to : undefined"
      :title="label"
      class="flex h-8 items-center gap-2 px-2 py-1 rounded-lg w-full hover:bg-gradient-to-r from-transparent via-n-slate-3/70 to-n-slate-3/70 group relative"
      :class="{
        'text-n-slate-12 bg-n-alpha-2 active': active,
      }"
      @click="isLocked ? emit('toggleLocked', featureFlag) : undefined"
    >
      <component
        :is="component"
        v-if="shouldRenderComponent"
        :label="label"
        :icon="icon"
        :active="active"
      />
      <template v-else>
        <span v-if="icon" class="size-4 grid place-content-center rounded-full">
          <Icon :icon="icon" class="size-4 inline-block" />
        </span>
        <div class="flex-1 truncate min-w-0 text-sm">{{ label }}</div>
        <Icon
          v-if="isLocked"
          icon="i-lucide-lock-keyhole"
          class="size-3 text-n-slate-11 shrink-0"
        />
      </template>
    </component>
  </li>
</template>
