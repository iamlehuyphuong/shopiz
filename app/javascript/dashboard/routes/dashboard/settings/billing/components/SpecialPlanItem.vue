<script setup>
import BenefitItem from './BenefitItem.vue';
import { formatCurrency } from 'dashboard/helper/commons';

defineProps({
  plan: {
    type: Object,
    required: true,
  },
});

</script>

<template>
  <div class="trial-item rounded-xl shadow-sm border border-n-weak bg-n-solid-2 py-8 px-8">
    <div class="grid grid-cols-2 gap-8">
      <div class="title">
        <span class="text-base font-medium text-n-slate-12">
          {{ plan.name }}
        </span>
        <p class="text-base font-medium text-n-slate-12">
          {{ formatCurrency(plan.price) }}
        </p>
        <p class="text-sm text-n-slate-11 mt-5">
          {{ plan.description }}
        </p>
      </div>
      <div class="benefit">
        <template v-for="benefit in plan.benefits" :key="benefit['id']">
          <BenefitItem :label="benefit['description']" />
        </template>
      </div>
    </div>
    <div class="button-group mt-5">
      <slot />
    </div>
  </div>
</template>
