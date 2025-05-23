<script>
import CustomizeChatbotGrid from '../../../../components-next/CustomizeChatbot/CustomizeChatbotGrid.vue';
import CustomizeChatbotHeader from '../../../../components-next/CustomizeChatbot/CustomizeChatbotHeader.vue';
import CustomizeChatbotPagination from '../../../../components-next/CustomizeChatbot/CustomizeChatbotPagination.vue';
import CustomizeChatbotPageSize from '../../../../components-next/CustomizeChatbot/CustomizeChatbotPageSize.vue';

import CustomizeChatbotTable from '../../../../components-next/CustomizeChatbot/CustomizeChatbotTable.vue';
import ToggleViewStyle from '../../../../components-next/CustomizeChatbot/ToggleViewStyle.vue';

import DataEmpty from '../../../../components/ui/DataEmpty.vue';
import ComboBox from '../../../../components-next/combobox/ComboBox.vue';
import Input from '../../../../components-next/input/Input.vue';
import Drawer from '../../../../components-next/drawer/Drawer.vue';

export default {
  components: {
    CustomizeChatbotHeader,
    CustomizeChatbotTable,
    CustomizeChatbotPagination,
    CustomizeChatbotPageSize,
    CustomizeChatbotGrid,
    ToggleViewStyle,
    DataEmpty,
    ComboBox,
    Input,
    Drawer
  },
  data() {
    return {
      companyName: 'Effi AI',
      description: 'Description',
      gridOrTable: true, // true = grid, false = table
      products: [
        {
          id: 1,
          selected: false,
          name: 'Midnight Sky Blue Jacket',
          category: 'Jacket',
          sales: 500,
          unitPrice: 20,
          quantity: 50,
          status: 'active',
          description: 'Speed up your UX/UI design career growth with our diverse,',
        },
        {
          id: 2,
          selected: false,
          name: 'Midnight Sky Blue Jacket',
          category: 'Jacket',
          sales: 500,
          unitPrice: 20,
          quantity: 50,
          status: 'active',
          description: 'Speed up your UX/UI design career growth with our diverse,',
        },
        {
          id: 3,
          selected: false,
          name: 'Midnight Sky Blue Jacket',
          category: 'Jacket',
          sales: 500,
          unitPrice: 20,
          quantity: 50,
          status: 'active',
          description: 'Speed up your UX/UI design career growth with our diverse,',
        },
        {
          id: 4,
          selected: false,
          name: 'Midnight Sky Blue Jacket',
          category: 'Jacket',
          sales: 500,
          unitPrice: 20,
          quantity: 50,
          status: 'active',
          description: 'Speed up your UX/UI design career growth with our diverse,',
        },
        {
          id: 5,
          selected: false,
          name: 'Midnight Sky Blue Jacket',
          category: 'Jacket',
          sales: 500,
          unitPrice: 20,
          quantity: 50,
          status: 'active',
          description: 'Speed up your UX/UI design career growth with our diverse,',
        },
      ],
      options: [
        {
          value: 'option1',
          label: 'active',
        },
        {
          value: 'option2',
          label: 'inactive',
        },
      ],
    };
  },
  methods: {
    updateSettings() {},
    toggleViewStyle(value) {
      this.gridOrTable = value;
    },
  },
};
</script>

<template>
  <!-- #Header -->
  <div class="flex flex-col min-h-screen bg-white  dark:bg-slate-900 dark:border-~slate-800/50 ">
    <CustomizeChatbotHeader
      :title="$t('CUSTOMIZE_CHATBOT_PRODUCT.TITLE')"
      :button-text="$t('CUSTOMIZE_CHATBOT_PRODUCT.BUTTON')"
      @buttonClick="updateSettings"
    />
    <!-- #Content -->
    <div class="flex-grow p-6 gap-4">
      <!-- #Toolbar -->
      <div class="flex flex-col md:flex-row justify-between mb-4 gap-3">
        <!-- #Filter/Sort -->
        <div class="flex flex-row gap-4">

          <!-- Filter -->
            <ComboBox
              :searchAble="false"
              :options="[]"
              placeholder="Show: All Products"
              class="w-20"
            />
            <!-- Sort -->
            <ComboBox
              :searchAble="false"
              :options="[]"
              placeholder="Sort by: Default"
            />
        </div>
        <!-- #Search/ViewStyle -->
        <div class="flex flex-row gap-3">
          <!-- Search -->
          <Input :placeholder="$t('CUSTOMIZE_CHATBOT_PRODUCT.SEARCH')">
            <template #prefix>
              <span class="absolute i-lucide-search top-2.5 size-5 left-3" />
            </template>
          </Input>
          <!-- Toggle view style -->
          <ToggleViewStyle :gridOrTable="gridOrTable" @toggleViewStyle="toggleViewStyle"/>
        </div>
      </div>
      <!-- #Dataview -->
      <div class="w-full" v-if="products && products.length > 0">
        <!-- Grid Card -->
        <CustomizeChatbotGrid v-if="gridOrTable" :products="products" />
        <!-- Table -->
        <CustomizeChatbotTable v-else :products="products" />
      </div>
      <!-- If: Data empty -->
      <DataEmpty v-else />
    </div>
    <!-- #Footer -->
    <div class="p-6 mt-auto">
      <br />
      <div class="flex flex-row justify-between">
        <!-- Pagination -->
        <CustomizeChatbotPagination />
        <!-- Page size -->
        <CustomizeChatbotPageSize />
      </div>
    </div>
  </div>
  <!-- <Drawer/> -->

</template>
