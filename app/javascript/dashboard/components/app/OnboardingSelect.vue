<script setup>
import { ref, computed } from 'vue';
import { onClickOutside, useElementBounding } from '@vueuse/core';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  options: { type: Array, default: () => [] },
  modelValue: { type: [String, Number], default: '' },
  hasError: { type: Boolean, default: false },
  placeholder: { type: String, default: 'Vui lòng chọn...' }
});

const emit = defineEmits(['update:modelValue']);
const isOpen = ref(false);

const selectedOption = computed(() => {
  return props.options.find(opt => opt.value === props.modelValue);
});

const triggerRef = ref(null);
const dropdownRef = ref(null);

const { bottom, left, width } = useElementBounding(triggerRef);

const toggle = () => { 
  isOpen.value = !isOpen.value; 
};

const close = () => { 
  isOpen.value = false; 
};

const select = (value) => {
  emit('update:modelValue', value);
  close();
};

onClickOutside(dropdownRef, (event) => {
  if (triggerRef.value && triggerRef.value.contains(event.target)) {
    return;
  }
  close();
}, { ignore: [triggerRef] });

</script>

<template>
  <div class="relative w-full">
    <!-- Trigger -->
    <button
      ref="triggerRef"
      type="button"
      class="relative flex items-center justify-between w-full text-left mb-0 border-none rounded-md shadow-sm bg-n-alpha-black2 appearance-none outline outline-1 focus:outline focus:outline-1 sm:text-sm sm:leading-6 px-3 py-3 transition-colors"
      :class="[
        hasError ? 'outline-n-ruby-8 hover:outline-n-ruby-9' : 'outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange',
        modelValue ? 'text-n-slate-12' : 'text-n-slate-10'
      ]"
      @click="toggle"
    >
      <span class="truncate pr-6">{{ selectedOption ? selectedOption.label : placeholder }}</span>
      <Icon icon="i-lucide-chevron-down" class="absolute right-3 size-4 text-n-slate-11 pointer-events-none" />
    </button>

    <!-- Dropdown Menu -->
    <Teleport to="body">
      <div
        v-if="isOpen"
        ref="dropdownRef"
        class="fixed z-[10000] flex flex-col p-1.5 max-h-[300px] overflow-y-auto shadow-lg rounded-xl border-0 outline outline-1 outline-n-container bg-n-alpha-3 backdrop-blur-[100px]"
        :style="{ top: `${bottom + 4}px`, left: `${left}px`, width: `${width}px` }"
      >
        <button
          v-for="option in options"
          :key="option.value"
          type="button"
          class="inline-flex items-center justify-start w-full h-8 min-w-0 gap-2 px-2 py-1.5 transition-all duration-200 ease-in-out border-0 rounded-lg hover:bg-n-alpha-1 dark:hover:bg-n-alpha-2"
          :class="[
            option.value === modelValue ? 'bg-n-alpha-1 dark:bg-n-solid-active' : ''
          ]"
          @click="select(option.value)"
        >
          <span class="w-4 h-4 flex-shrink-0 flex items-center justify-center">
            <Icon v-if="option.value === modelValue" icon="i-lucide-check" class="size-3.5 text-n-slate-12" />
          </span>
          <span class="min-w-0 text-sm truncate text-n-slate-12">{{ option.label }}</span>
        </button>
      </div>
    </Teleport>
  </div>
</template>
