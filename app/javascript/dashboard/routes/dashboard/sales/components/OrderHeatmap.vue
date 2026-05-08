<script setup>
import { ref, watch, onMounted } from 'vue';
import BaseHeatmap from 'dashboard/routes/dashboard/settings/reports/components/heatmaps/BaseHeatmap.vue';
import HeatmapDateRangeSelector from 'dashboard/routes/dashboard/settings/reports/components/heatmaps/HeatmapDateRangeSelector.vue';
import { useI18n } from 'vue-i18n';
import SalesReportsAPI from 'dashboard/api/sales/reports';
import getUnixTime from 'date-fns/getUnixTime';

const { t } = useI18n();

const heatmapData = ref([]);
const isLoading = ref(false);

const fromDate = ref(null);
const MathToDate = ref(null); // Will be bound to 'to'
const daysNum = ref(0);

const fetchHeatmapData = async () => {
  if (isLoading.value || !fromDate.value || !MathToDate.value) return;
  isLoading.value = true;
  try {
    const response = await SalesReportsAPI.getHeatmap({
      from: getUnixTime(fromDate.value),
      to: getUnixTime(MathToDate.value),
    });
    heatmapData.value = response.data;
  } catch (error) {
    console.error('Failed to fetch order heatmap', error);
    heatmapData.value = [];
  } finally {
    isLoading.value = false;
  }
};

watch(
  () => [fromDate.value, MathToDate.value],
  () => fetchHeatmapData()
);

onMounted(fetchHeatmapData);
</script>

<template>
  <div
    class="bg-white dark:bg-n-solid-1 rounded-xl border border-n-weak shadow-sm"
  >
    <div class="px-6 py-4 flex justify-between items-center">
      <h3 class="text-sm font-medium text-n-slate-12 mb-0">
        {{ t('SALES.MODULE_DASHBOARD.HEATMAP.TITLE') }}
      </h3>
      <HeatmapDateRangeSelector
        v-model:from="fromDate"
        v-model:to="MathToDate"
        v-model:days-num="daysNum"
      />
    </div>
    <div class="p-6">
      <BaseHeatmap
        :heatmap-data="heatmapData"
        :number-of-rows="daysNum + 1"
        :is-loading="isLoading"
        color-scheme="brand"
        :tooltip-messages="{
          noData: 'SALES.MODULE_DASHBOARD.HEATMAP.NO_ORDERS',
          singular: 'SALES.MODULE_DASHBOARD.HEATMAP.ORDER',
          plural: 'SALES.MODULE_DASHBOARD.HEATMAP.ORDERS',
        }"
      />
    </div>
  </div>
</template>
