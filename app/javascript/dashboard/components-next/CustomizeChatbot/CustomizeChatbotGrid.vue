<script lang="ts">
import { PropType } from 'vue';
import { Product } from '../../../shared/model/product.model';

export default {
  props: {
    products: {
      type: Array as PropType<Product[]>,
      default: () => [],
    },
  },
};
</script>

<template>
  <div class="w-full">
    <div class="flex flex-wrap gap-3">
      <a href="#" v-for="product in products" v-bind:key="product.id"
        class="w-[14rem] h-[17.375rem] flex flex-col bg-white border border-n-gray-8 rounded-xl shadow-sm hover:bg-n-gray-1 dark:bg-slate-900 dark:border-~slate-800/50 dark:hover:bg-n-gray-7">
        <header
          class="border-b-[0.5px]  border-light-neutral-stroke-bold dark:border-black-neutral-stroke-bold w-full justify-center items-center flex h-[7.625rem]">
          <img class="h-full w-full object-contain"
            src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQM-UVievxTe_4NdhLyT6CeiiqfmSamSsw08Q&s"
            alt="Midnight Sky Blue Jacket" />
        </header>
        <main class="flex flex-col gap-2 py-3 px-2">
          <span class="font-inter text-xs font-normal">
            {{ product.category }}
          </span>
          <span class="text-primary-700 font-inter text-sm font-medium line-clamp-1">{{ product.name }}</span>
          <span class="font-inter text-xs font-normal line-clamp-2 h-8">{{
            product.description
          }}</span>
          <div class="h-10">
            <b class="text-light-neutral-primary dark:text-black-neutral-primary font-inter text-base font-semibold">${{
              product.unitPrice }}</b><br />
            <span class="font-inter text-xs font-normal">Products: {{ product.quantity }}</span>
          </div>
        </main>
      </a>
    </div>
  </div>
</template>