<script setup>
import GridViewIcon from '../icon/GridViewIcon.vue';
import ListViewIcon from '../icon/ListViewIcon.vue';

const props = defineProps({
  gridOrTable: {
    type: Boolean,
    default: true,
  },
});
const emit = defineEmits(['toggleViewStyle']);
</script>
<template>
  <div
    class="flex flex-row h-10 p-1 justify-center items-center gap-2.5 border-[1px] border-lightNeutral-strokeBold dark:border-blackNeutral-strokeBold rounded-lg bg-transparent"
  >
    <div
      class="p-2 rounded-[0.5rem]"
      :class="gridOrTable ? 'bg-primary-100' : 'bg-transparent'"
      @click="emit('toggleViewStyle', true)"
    >
      <GridViewIcon :color="gridOrTable ? '#386BB7' : '#575757'" />
    </div>
    <div
      class="p-2 rounded-[0.5rem]"
      :class="!gridOrTable ? 'bg-primary-100' : 'bg-transparent'"
      @click="emit('toggleViewStyle', false)"

    >
      <ListViewIcon :color="!gridOrTable ? '#386BB7' : '#575757'" />
    </div>
  </div>
</template>