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
    <div class="title text-center">
      <span class="text-base font-medium text-n-slate-12">
        {{ plan.name }}
      </span>
      <p class="text-base font-medium text-n-slate-12 mt-1">
        {{ formatCurrency(plan.price) }}
      </p>
      <p class="text-sm text-n-slate-11 mt-1">
        {{ plan.description }}
      </p>
    </div>
    <div class="benefit mt-6">
      <template v-for="benefit in plan.benefits" :key="benefit['id']">
        <BenefitItem class="text-center" :label="benefit['description']" />
      </template>
    </div>
    <div class="mt-3 flex justify-center">
      <slot />
    </div>
  </div>
</template>
