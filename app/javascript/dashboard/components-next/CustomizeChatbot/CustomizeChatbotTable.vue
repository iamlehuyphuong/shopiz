<script lang="ts">
import { PropType } from 'vue';
import FilterByIcon from '../icon/FilterByIcon.vue';
import { Product } from '../../../shared/model/product.model';
export default {
  components: {
    FilterByIcon,
  },
  props: {
    products: {
      type: Array as PropType<Product[]>,
      default: () => [],
    },
  },
};
</script>

<template>
  <!-- #Show: all products -->

  <div
    class="relative h-full overflow-x-auto sm:rounded-xl border-lightNeutral-strokeBold dark:border-blackNeutral-strokeBold border-[0.75px]"
  >
    <table
      class="w-full text-sm text-left rtl:text-right text-lightNeutral-secondary dark:white"
    >
      <thead
        class="text-xs text-lightNeutral-secondary bg-lightNeutral-s border-b-lightNeutral-strokeBold dark:text-white dark:bg-blackNeutral-s dark:border-blackNeutral-strokeBold "
      >
        <tr>
          <th scope="col" class="px-6 py-3">
            <input type="checkbox" />
          </th>
          <th scope="col" class="px-6 py-3">
            {{ $t('CUSTOMIZE_CHATBOT_PRODUCT.TABLE.PRODUCT_NAME') }}
          </th>
          <th scope="col" class="px-6 py-3">
            <div class="flex items-center gap-1">
              {{ $t('CUSTOMIZE_CHATBOT_PRODUCT.TABLE.CATEGORY') }}
              <FilterByIcon />
            </div>
          </th>
          <th scope="col" class="px-6 py-3">
            <div class="flex items-center gap-1">
              {{ $t('CUSTOMIZE_CHATBOT_PRODUCT.TABLE.SALES') }}

              <FilterByIcon />
            </div>
          </th>
          <th scope="col" class="px-6 py-3">
            <div class="flex items-center gap-1">
              {{ $t('CUSTOMIZE_CHATBOT_PRODUCT.TABLE.UNIT_PRICE') }}
              <FilterByIcon />
            </div>
          </th>
          <th scope="col" class="px-6 py-3">
            <div class="flex items-center gap-1">
              {{ $t('CUSTOMIZE_CHATBOT_PRODUCT.TABLE.QUANTITY') }}
              <FilterByIcon />
            </div>
          </th>
          <th scope="col" class="px-6 py-3">
            <div class="flex items-center gap-1">
              {{ $t('CUSTOMIZE_CHATBOT_PRODUCT.TABLE.STATUS') }}
              <FilterByIcon />
            </div>
          </th>
          <th scope="col" class="px-6 py-3">
            <span class="sr-only" />
          </th>
        </tr>
      </thead>
      <tbody
        class="text-lightNeutral-secondary dark:text-white"
      >
        <tr
          v-for="p in products"
          :key="p.id"
          class="bg-white dark:bg-slate-900 border-t-[0.75px] border-lightNeutral-strokeBold dark:border-blackNeutral-strokeBold"
        >
          <td class="text-center justify-center px-6">
            <input type="checkbox" />
          </td>
          <td
            class="px-6 py-4 font-medium text-gray-900 whitespace-nowrap dark:text-white"
          >
            <div class="grid grid-cols-12 gap-2">
              <div class="col-span-3">
                <img
                  width="60"
                  height="60"
                  src="https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQM-UVievxTe_4NdhLyT6CeiiqfmSamSsw08Q&s"
                  alt="Midnight Sky Blue Jacket"
                />
              </div>
              <div class="col-span-9">
                <p class="text-sm font-medium text-primary-700">
                  {{ p.name }}
                </p>
                <span class="text-xs text-wrap text-ellipsis line-clamp-3">{{
                  p.description
                }}</span>
              </div>
            </div>
          </td>
          <td class="px-6 py-4">{{ p.category }}</td>
          <td class="px-6 py-4">{{ p.sales }}</td>
          <td class="px-6 py-4">{{ p.unitPrice }}</td>
          <td class="px-6 py-4">{{ p.quantity }}</td>
          <td class="px-6 py-4">
            <div class="relative inline-block">
              <select
                class="appearance-none bg-[#D9F2DF] text-[#249557] font-medium pl-6 text-xs pr-8 rounded-full border border-transparent focus:outline-none focus:ring-2 focus:ring-green-500"
              >
                <option value="active">
                  {{ $t('CUSTOMIZE_CHATBOT_PRODUCT.TABLE.ACTIVE') }}
                </option>
                <option value="inactive">
                  {{ $t('CUSTOMIZE_CHATBOT_PRODUCT.TABLE.INACTIVE') }}
                </option>
              </select>

              <span
                class="absolute left-2 top-1/2 transform -translate-y-1/2 w-2 h-2 bg-[#249557] rounded-full"
              />
            </div>
          </td>
          <td />
        </tr>
      </tbody>
    </table>
  </div>
</template>

<style scoped>
.appearance-none {
  appearance: none;
  -webkit-appearance: none;
  -moz-appearance: none;
}

select {
  margin-bottom: 0 !important;
  padding-top: 0 !important;
  padding-bottom: 0 !important;
  height: 1.5rem !important;
}
</style>
