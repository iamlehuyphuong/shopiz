<script setup>
import { computed } from 'vue';
import VueApexCharts from 'vue3-apexcharts';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  breakdown: { type: Object, default: () => ({}) },
});

const { t } = useI18n();

const statusConfig = [
  { key: 'draft', color: '#94a3b8' },
  { key: 'confirmed', color: '#60a5fa' },
  { key: 'processing', color: '#fbbf24' },
  { key: 'shipped', color: '#fb923c' },
  { key: 'delivered', color: '#34d399' },
  { key: 'cancelled', color: '#f87171' },
];

const chartData = computed(() => {
  const labels = [];
  const series = [];
  const colors = [];

  statusConfig.forEach(s => {
    const count = props.breakdown[s.key] || 0;
    if (count > 0) {
      labels.push(
        t(`SALES.MODULE_DASHBOARD.STATUS_BREAKDOWN.${s.key.toUpperCase()}`)
      );
      series.push(count);
      colors.push(s.color);
    }
  });

  return { labels, series, colors };
});

const chartOptions = computed(() => ({
  chart: {
    type: 'donut',
    background: 'transparent',
    fontFamily: 'Inter, sans-serif',
  },
  labels: chartData.value.labels,
  colors: chartData.value.colors,
  legend: {
    position: 'bottom',
    fontSize: '12px',
    labels: { colors: 'var(--n-slate-11)' },
    markers: { width: 8, height: 8, radius: 2 },
  },
  plotOptions: {
    pie: {
      donut: {
        size: '60%',
        labels: {
          show: true,
          total: {
            show: true,
            label: t('SALES.MODULE_DASHBOARD.STATUS_BREAKDOWN.TITLE'),
            fontSize: '12px',
            color: 'var(--n-slate-11)',
          },
        },
      },
    },
  },
  dataLabels: { enabled: false },
  stroke: { width: 2, colors: ['var(--n-solid-2)'] },
  tooltip: { theme: 'dark' },
}));

const hasData = computed(() => chartData.value.series.length > 0);
</script>

<template>
  <div
    class="bg-white dark:bg-n-solid-1 rounded-xl border border-n-weak shadow-sm flex flex-col"
  >
    <div class="px-6 pt-5 pb-3">
      <h3 class="text-sm font-medium text-n-slate-12 mb-0">
        {{ $t('SALES.MODULE_DASHBOARD.STATUS_BREAKDOWN.TITLE') }}
      </h3>
    </div>
    <div class="flex-1 flex items-center justify-center px-4 pb-4">
      <VueApexCharts
        v-if="hasData"
        type="donut"
        height="280"
        :options="chartOptions"
        :series="chartData.series"
      />
      <p v-else class="text-sm text-n-slate-10 py-12">
        {{ $t('SALES.MODULE_DASHBOARD.RECENT_ORDERS.NO_ORDERS') }}
      </p>
    </div>
  </div>
</template>
