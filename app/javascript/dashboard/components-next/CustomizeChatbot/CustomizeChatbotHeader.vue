<script>
export default {
  name: 'HeaderComponent',
  props: {
    title: {
      type: String,
      default: '',
    },
    buttonText: {
      type: String,
      default: '',
    },
  },
  emits: ['buttonClick'],
};
</script>

<template>
  <div
    class="h-[4.5rem] flex justify-between border-b-[0.5px] pt-4 pr-6 pb-4 pl-6 border-[#D1D1D1]"
  >
    <h1 class="text-2xl font-bold">{{ title }}</h1>
    <button
      v-if="buttonText"
      class="h-[2.5rem] p-2 px-4 gap-2 rounded-lg bg-[#386BB7] text-white"
      @click="$emit('buttonClick')"
    >
      {{ buttonText }}
    </button>
  </div>
</template>
