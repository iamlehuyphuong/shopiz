<script setup>
import { ref, computed, onMounted, watch } from 'vue';
import SalesReportsAPI from 'dashboard/api/sales/reports';
import SalesLayout from './components/SalesLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';
import OverviewMetricCard from './components/OverviewMetricCard.vue';
import RevenueChart from './components/RevenueChart.vue';
import OrdersByInboxTable from './components/OrdersByInboxTable.vue';
import OrderHeatmap from './components/OrderHeatmap.vue';
import WootDatePicker from 'dashboard/components/ui/DatePicker/DatePicker.vue';
import { DATE_RANGE_TYPES } from 'dashboard/components/ui/DatePicker/helpers/DatePickerHelper';
import { getUnixStartOfDay, getUnixEndOfDay } from 'helpers/DateHelper';
import subDays from 'date-fns/subDays';
import differenceInCalendarDays from 'date-fns/differenceInCalendarDays';
import { useI18n } from 'vue-i18n';

const { t } = useI18n();

const isLoading = ref(true);
const reportData = ref(null);

const customDateRange = ref([subDays(new Date(), 6), new Date()]);
const selectedDateRange = ref(DATE_RANGE_TYPES.LAST_7_DAYS);

const fromTimestamp = computed(() =>
  getUnixStartOfDay(customDateRange.value[0])
);
const toTimestamp = computed(() => getUnixEndOfDay(customDateRange.value[1]));
const numberOfDays = computed(
  () =>
    differenceInCalendarDays(
      customDateRange.value[1],
      customDateRange.value[0]
    ) + 1
);

const fetchReports = async () => {
  isLoading.value = true;
  try {
    const response = await SalesReportsAPI.getReports({
      from: fromTimestamp.value,
      to: toTimestamp.value,
    });
    reportData.value = response.data;
  } catch (error) {
    console.error('Failed to fetch sales reports', error);
  } finally {
    isLoading.value = false;
  }
};

const formatCurrency = price => {
  if (!price && price !== 0) return '--';
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency: 'VND',
    maximumFractionDigits: 0,
  }).format(price);
};

const formatNumber = num => {
  if (!num && num !== 0) return '--';
  return new Intl.NumberFormat('vi-VN').format(num);
};

const calcChange = (current, previous) => {
  if (!previous || previous === 0) return null;
  return ((current - previous) / previous) * 100;
};

const metrics = computed(() => {
  if (!reportData.value?.metrics) return [];
  const m = reportData.value.metrics;
  const prev = m.previous || {};

  return [
    {
      label: t('SALES.MODULE_DASHBOARD.METRICS.TOTAL_REVENUE'),
      value: formatCurrency(m.total_revenue),
      change: calcChange(m.total_revenue, prev.total_revenue),
    },
    {
      label: t('SALES.MODULE_DASHBOARD.METRICS.TOTAL_ORDERS'),
      value: formatNumber(m.total_orders),
      change: calcChange(m.total_orders, prev.total_orders),
    },
    {
      label: t('SALES.MODULE_DASHBOARD.METRICS.AOV'),
      value: formatCurrency(m.average_order_value),
      change: calcChange(m.average_order_value, prev.average_order_value),
    },
  ];
});

const onDateRangeChange = value => {
  const [startDate, endDate, rangeType] = value;
  customDateRange.value = [startDate, endDate];
  selectedDateRange.value = rangeType || DATE_RANGE_TYPES.CUSTOM_RANGE;
  fetchReports();
};

onMounted(() => {
  fetchReports();
});
</script>

<template>
  <SalesLayout :is-loading="isLoading">
    <template #header>
      <BaseSettingsHeader
        :title="$t('SALES.MODULE_DASHBOARD.HEADER.TITLE')"
        :description="$t('SALES.MODULE_DASHBOARD.HEADER.DESCRIPTION')"
        feature-name="salesDashboard"
      />
    </template>
    <template #body>
      <div class="flex flex-col gap-5">
        <!-- Date Range Picker -->
        <div class="flex items-center">
          <WootDatePicker
            v-model:date-range="customDateRange"
            v-model:range-type="selectedDateRange"
            @date-range-changed="onDateRangeChange"
          />
        </div>

        <div v-if="reportData" class="flex flex-col gap-5">
          <!-- KPI Cards -->
          <div class="grid grid-cols-2 lg:grid-cols-3 gap-4">
            <OverviewMetricCard
              v-for="metric in metrics"
              :key="metric.label"
              :label="metric.label"
              :value="metric.value"
              :change-percent="metric.change"
            />
          </div>

          <!-- Revenue Chart -->
          <RevenueChart
            :chart-data="reportData.chart_data || []"
            :date-range="customDateRange"
          />

          <!-- Orders By Inbox -->
          <OrdersByInboxTable :data="reportData.orders_by_inbox || []" />

          <!-- Order Heatmap -->
          <OrderHeatmap :date-range="customDateRange" />
        </div>

        <div
          v-else-if="!isLoading"
          class="flex flex-col items-center justify-center p-12 bg-n-alpha-1 border border-n-weak rounded-xl"
        >
          <div class="text-n-slate-11 text-center">
            <span class="i-lucide-alert-circle text-4xl mb-3 block mx-auto" />
            <p class="font-medium text-n-slate-12 text-base m-0 mb-1">
              Không thể tải dữ liệu
            </p>
            <p class="text-sm m-0 max-w-md mx-auto">
              Có lỗi xảy ra khi tải báo cáo. Vui lòng thử lại hoặc kiểm tra xem
              trình duyệt có đang chặn request (AdBlocker) không.
            </p>
            <button
              class="mt-4 px-4 py-2 bg-n-brand text-white rounded-lg text-sm hover:bg-n-brand-dark transition-colors"
              @click="fetchReports"
            >
              Thử lại
            </button>
          </div>
        </div>
      </div>
    </template>
  </SalesLayout>
</template>
