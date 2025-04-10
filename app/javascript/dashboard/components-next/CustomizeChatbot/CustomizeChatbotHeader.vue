<script setup lang="ts">
import Alert from '../../components-salesman/alert/Alert.vue';
import Badge from '../../components-salesman/badge/Badge.vue';
import Button from '../../components-salesman/button/Button.vue';
import Radio from '../../components-salesman/radio/Radio.vue';
import Switcher from '../../components-salesman/switcher/Switcher.vue'
import ConversationIcon from '../../components/layout/sidebarComponents/icons/ConversationsIcon.vue'
import { defineEmits } from 'vue';
const props = defineProps({
  title:{
    type: String, 
    default: ''
  },
  buttonText: {
      type: String,
      default: '',
    },
})
const emit = defineEmits(['buttonClick'])
</script>

<template>
  <div
    class="h-[4.5rem] flex gap-2 border-b-[0.5px] pt-4 pr-6 pb-4 pl-6 border-lightNeutral-strokeBold dark:border-blackNeutral-strokeBold"
  >
    <h1 class="text-2xl font-bold">{{ title }}</h1>
    <Button
      v-if="buttonText"
      @click="$emit('buttonClick')"
      color="primary"
      variant="solid"
      size="lg"
      icon="i-lucide-chevron-up"
      >
      {{ buttonText }}
    </Button>
    <Switcher  />
    <Radio />
    <Badge size="lg" label="Badge"></Badge>
  </div>
  <div class="w-[56rem]">
    <Alert 
    :icon="ConversationIcon " 
    color="success"
    header="Alert line which displays the main function or reason of the alert."
    >
    <template #description>
      Become a legendary UX/UI designer through real world and practical courses.
    </template>
    
    <template #footer>
      footer
    </template>
    
    </Alert>
  </div>
</template>
