<script>
import CustomizeChatbotHeader from '../../../../components-next/CustomizeChatbot/CustomizeChatbotHeader.vue';
import CustomizeChatbotPagination from '../../../../components-next/CustomizeChatbot/CustomizeChatbotPagination.vue';
import CustomizeChatbotTable from '../../../../components-next/CustomizeChatbot/CustomizeChatbotTable.vue';

export default {
  components: {
    CustomizeChatbotHeader,
    CustomizeChatbotTable,
    CustomizeChatbotPagination,
  },
  data() {
    return {
      companyName: 'Effi AI',
      description: 'Description',
    };
  },
  methods: {
    updateSettings() {},
  },
};
</script>

<template>
  <div class="flex flex-col min-h-screen bg-white">
    <CustomizeChatbotHeader
      :title="$t('CUSTOMIZE_CHATBOT_PRODUCT.TITLE')"
      button-text="$t('CUSTOMIZE_CHATBOT_PRODUCT.BUTTON')"
      @button-click="updateSettings"
    />
    <!-- Content -->
    <div class="flex-grow p-6 gap-4">
      <!-- Tool bar -->
      <div class="flex justify-between">
        <!-- Filter/Sort -->
        <div class="flex flex-row gap-4">
          <div class="relative inline-block">
            <select
              class="w-full rounded-md border border-gray-300 bg-white font-sans text-black text-sm p-2 appearance-none pr-8"
            >
              <option value="all" disabled hidden>
                {{ $t('CUSTOMIZE_CHATBOT_PRODUCT.SHOW_PRODUCT') }}
              </option>
            </select>
          </div>

          <div class="relative inline-block">
            <select
              class="w-full rounded-md border border-gray-300 bg-white font-sans text-black text-sm p-2 appearance-none pr-8"
            >
              <option value="all" disabled hidden>
                {{ $t('CUSTOMIZE_CHATBOT_PRODUCT.SOFT_BY') }}
              </option>
            </select>
          </div>
        </div>
        <!-- Search/ViewType -->
        <div class="flex gap-4">
          <div
            class="flex h-10 px-4 py-2 items-center gap-2 flex-shrink-0 rounded-lg border-[1px] border-solid border-[#D1D1D1]"
          >
            <svg
              xmlns="http://www.w3.org/2000/svg"
              width="24"
              height="24"
              viewBox="0 0 24 24"
              fill="none"
            >
              <path
                d="M17.5 17.5L22 22"
                stroke="#575757"
                stroke-width="1.5"
                stroke-linecap="round"
                stroke-linejoin="round"
              />
              <path
                d="M20 11C20 6.02944 15.9706 2 11 2C6.02944 2 2 6.02944 2 11C2 15.9706 6.02944 20 11 20C15.9706 20 20 15.9706 20 11Z"
                stroke="#575757"
                stroke-width="1.5"
                stroke-linejoin="round"
              />
            </svg>
            <input class="search-input" type="text" />
          </div>
        </div>
      </div>
      <!-- Table -->
      <CustomizeChatbotTable />
    </div>
    <!-- Footer -->
    <div class="p-6 mt-auto">
      <br />
      <div class="flex flex-row justify-between">
        <!-- #pagination -->
        <CustomizeChatbotPagination />
        <span class="text-base flex flex-row gap-1 items-center justify-center">
          {{ $t('CUSTOMIZE_CHATBOT_PAGINATION.ITEM_PER_PAGE') }}

          <div class="border-solid border-[#D1D1D1] p-1 rounded border-[1px]">
            <input
              value="20"
              type="text"
              class="text-center justify-center items-center pagination-input"
            />
          </div>
          {{ $t('CUSTOMIZE_CHATBOT_PAGINATION.ITEM_PER_PAGE', '1-20', '500') }}
        </span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.appearance-none {
  appearance: none !important;
  -webkit-appearance: none !important;
  -moz-appearance: none !important;
}
input {
  margin-bottom: 0 !important;
  border: none !important;
}
pagination-input {
  width: 2.5rem !important;
  height: 1.25rem !important;
}
search-input {
  padding: 0 !important;
  height: auto !important;
}
</style>
