<script setup>
import BaseCell from 'dashboard/components/table/BaseCell.vue';
import Avatar from 'next/avatar/Avatar.vue';
import { useMapGetter } from 'dashboard/composables/store';

defineProps({
  row: {
    type: Object,
    required: true,
  },
});

const isRTL = useMapGetter('accounts/isRTL');
</script>

<template>
  <BaseCell>
    <div
      class="items-center flex text-left"
      :class="{ 'flex-row-reverse': isRTL }"
    >
      <Avatar :name="row.original.name" :size="32" branded />
      <div class="items-start flex flex-col min-w-0 my-0 mx-2">
        <h6
          class="overflow-hidden text-sm m-0 leading-[1.2] text-n-slate-12 whitespace-nowrap text-ellipsis"
        >
          {{ row.original.name }}
        </h6>
      </div>
    </div>
  </BaseCell>
</template>
