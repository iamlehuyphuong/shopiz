<script setup>
import { ref, watch, onMounted, computed } from 'vue';
import BaseHeatmap from 'dashboard/routes/dashboard/settings/reports/components/heatmaps/BaseHeatmap.vue';
import { useI18n } from 'vue-i18n';
import SalesReportsAPI from 'dashboard/api/sales/reports';
import getUnixTime from 'date-fns/getUnixTime';
import differenceInCalendarDays from 'date-fns/differenceInCalendarDays';

const props = defineProps({
  dateRange: {
    type: Array,
    required: true,
  },
});

const { t } = useI18n();

const heatmapData = ref([]);
const isLoading = ref(false);

const fromDate = computed(() => props.dateRange?.[0]);
const toDate = computed(() => props.dateRange?.[1]);

const numberOfRows = computed(() => {
  if (!fromDate.value || !toDate.value) return 7;
  return differenceInCalendarDays(toDate.value, fromDate.value) + 1;
});

const fetchHeatmapData = async () => {
  if (isLoading.value || !fromDate.value || !toDate.value) return;
  isLoading.value = true;
  try {
    const response = await SalesReportsAPI.getHeatmap({
      from: getUnixTime(fromDate.value),
      to: getUnixTime(toDate.value),
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
  () => props.dateRange,
  () => fetchHeatmapData(),
  { deep: true }
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
    </div>
    <div class="p-6">
      <BaseHeatmap
        :heatmap-data="heatmapData"
        :number-of-rows="numberOfRows"
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
