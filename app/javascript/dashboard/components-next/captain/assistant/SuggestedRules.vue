<script setup>
import { useI18n } from 'vue-i18n';
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  title: {
    type: String,
    default: '',
  },
  items: {
    type: Array,
    default: () => [],
  },
});

const emit = defineEmits(['add', 'close']);

const { t } = useI18n();
import { ref } from 'vue';

const isExpanded = ref(false);

const toggleExpand = () => {
  isExpanded.value = !isExpanded.value;
};

const onAddClick = () => {
  emit('add');
};

const onClickClose = () => {
  emit('close');
};
</script>

<template>
  <div
    class="flex flex-col items-start self-stretch rounded-xl w-full overflow-hidden border border-dashed border-n-strong"
  >
    <div class="flex items-center justify-between w-full gap-3 px-4 pb-4 pt-4 cursor-pointer select-none hover:bg-n-alpha-1" @click="toggleExpand">
      <div class="flex items-center gap-3">
        <span
          class="text-n-slate-11 transition-transform duration-200"
          :class="[isExpanded ? 'i-lucide-chevron-down' : 'i-lucide-chevron-right']"
        />
        <h5 class="text-sm font-medium text-n-slate-11">{{ title }}</h5>
        <span class="h-3 w-px bg-n-weak" />
        <Button
          :label="t('CAPTAIN.ASSISTANTS.GUARDRAILS.ADD.SUGGESTED.ADD')"
          ghost
          xs
          slate
          class="!text-sm !text-n-slate-11 flex-shrink-0"
          @click.stop="onAddClick"
        />
      </div>
      <Button
        ghost
        xs
        slate
        icon="i-lucide-x"
        class="!text-sm !text-n-slate-11 flex-shrink-0"
        @click.stop="onClickClose"
      />
    </div>
    <div
      v-show="isExpanded"
      class="flex flex-col items-start divide-y divide-n-strong divide-dashed w-full border-t border-dashed border-n-strong"
    >
      <div v-for="item in items" :key="item.content" class="w-full px-4 py-4">
        <slot :item="item" />
      </div>
    </div>
  </div>
</template>
