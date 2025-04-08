<script>
import Badge from '../../components-salesman/badge/Badge.vue';
import Button from '../../components-salesman/button/Button.vue';

export default {
  name: 'HeaderComponent',
  components: {
    Badge,
    Button
  },
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
    class="h-[4.5rem] flex justify-between border-b-[0.5px] pt-4 pr-6 pb-4 pl-6 border-lightNeutral-strokeBold dark:border-blackNeutral-strokeBold"
  >
    <h1 class="text-2xl font-bold">{{ title }}</h1>
    <Button
      v-if="buttonText"
      @click="$emit('buttonClick')"
      color="primary"
      variant="solid"
      size="lg"
      >
      {{ buttonText }}
    </Button>
  </div>
</template>
