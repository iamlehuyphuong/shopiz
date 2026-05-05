<script setup>
import { ref, onMounted } from 'vue';
import SalesReportsAPI from 'dashboard/api/sales/reports';
import SalesLayout from './components/SalesLayout.vue';
import BaseSettingsHeader from 'dashboard/routes/dashboard/settings/components/BaseSettingsHeader.vue';

const isLoading = ref(true);
const reportData = ref(null);

const fetchReports = async () => {
  isLoading.value = true;
  try {
    const response = await SalesReportsAPI.get();
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
  }).format(price);
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
      <div v-if="reportData" class="flex flex-col gap-6">
        <!-- Metrics -->
        <div
          class="bg-white dark:bg-n-solid-1 rounded-xl border border-n-weak shadow-sm"
        >
          <div class="px-6 py-4 flex items-center gap-2">
            <h3 class="text-base font-medium text-n-slate-12 mb-0">
              {{ $t('SALES.MODULE_DASHBOARD.METRICS.OVERVIEW') }}
            </h3>
            <span
              class="px-1.5 py-0.5 bg-n-brand/10 text-n-brand text-xs font-medium rounded"
            >
              {{ $t('SALES.MODULE_DASHBOARD.METRICS.LIVE') }}
            </span>
          </div>
          <div class="px-6 pb-6 flex items-center gap-12">
            <div class="flex flex-col gap-2">
              <p class="text-sm text-n-slate-11 mb-0">
                {{ $t('SALES.MODULE_DASHBOARD.METRICS.TOTAL_REVENUE') }}
              </p>
              <p class="text-3xl font-normal text-n-slate-12 mb-0">
                {{ formatCurrency(reportData.metrics.total_revenue) }}
              </p>
            </div>
            <div class="flex flex-col gap-2">
              <p class="text-sm text-n-slate-11 mb-0">
                {{ $t('SALES.MODULE_DASHBOARD.METRICS.TOTAL_ORDERS') }}
              </p>
              <p class="text-3xl font-normal text-n-slate-12 mb-0">
                {{ reportData.metrics.total_orders }}
              </p>
            </div>
            <div class="flex flex-col gap-2">
              <p class="text-sm text-n-slate-11 mb-0">
                {{ $t('SALES.MODULE_DASHBOARD.METRICS.AOV') }}
              </p>
              <p class="text-3xl font-normal text-n-slate-12 mb-0">
                {{ formatCurrency(reportData.metrics.average_order_value) }}
              </p>
            </div>
          </div>
        </div>

        <!-- Chart area placeholder -->
        <div
          class="bg-white dark:bg-n-solid-1 p-8 rounded-xl border border-n-weak shadow-sm h-80 flex flex-col items-center justify-center gap-4"
        >
          <div
            class="h-16 w-16 bg-n-alpha-1 rounded-full flex items-center justify-center"
          >
            <span class="i-lucide-bar-chart-3 text-3xl text-n-slate-10" />
          </div>
          <p class="text-n-slate-11 font-medium">
            {{ $t('SALES.MODULE_DASHBOARD.CHART.PLACEHOLDER') }}
          </p>
        </div>
      </div>
    </template>
  </SalesLayout>
</template>
