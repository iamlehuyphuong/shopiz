<script setup>
import { computed, watch } from 'vue';
import VueApexCharts from 'vue3-apexcharts';

const props = defineProps({
  chartData: { type: Array, default: () => [] },
});

const series = computed(() => [
  {
    name: 'Revenue',
    data: props.chartData.map(d => ({
      x: d.date,
      y: d.revenue,
    })),
  },
]);

const chartOptions = computed(() => ({
  chart: {
    type: 'area',
    height: 280,
    toolbar: { show: false },
    zoom: { enabled: false },
    fontFamily: 'Inter, sans-serif',
    background: 'transparent',
  },
  colors: ['#6366f1'],
  fill: {
    type: 'gradient',
    gradient: {
      shadeIntensity: 1,
      opacityFrom: 0.4,
      opacityTo: 0.05,
      stops: [0, 90, 100],
    },
  },
  stroke: {
    curve: 'smooth',
    width: 2.5,
  },
  dataLabels: { enabled: false },
  grid: {
    borderColor: 'var(--n-alpha-1)',
    strokeDashArray: 4,
    xaxis: { lines: { show: false } },
    yaxis: { lines: { show: true } },
    padding: { left: 8, right: 8 },
  },
  xaxis: {
    type: 'datetime',
    labels: {
      style: { colors: 'var(--n-slate-11)', fontSize: '11px' },
      datetimeFormatter: { day: 'dd/MM' },
    },
    axisBorder: { show: false },
    axisTicks: { show: false },
  },
  yaxis: {
    labels: {
      style: { colors: 'var(--n-slate-11)', fontSize: '11px' },
      formatter: val => {
        if (val >= 1_000_000) return `${(val / 1_000_000).toFixed(1)}M`;
        if (val >= 1_000) return `${(val / 1_000).toFixed(0)}K`;
        return val;
      },
    },
  },
  tooltip: {
    theme: 'dark',
    x: { format: 'dd/MM/yyyy' },
    y: {
      formatter: val =>
        new Intl.NumberFormat('vi-VN', {
          style: 'currency',
          currency: 'VND',
          maximumFractionDigits: 0,
        }).format(val),
    },
  },
}));
</script>

<template>
  <div
    class="bg-white dark:bg-n-solid-1 rounded-xl border border-n-weak shadow-sm"
  >
    <div class="px-6 pt-5 pb-2">
      <h3 class="text-sm font-medium text-n-slate-12 mb-0">
        {{ $t('SALES.MODULE_DASHBOARD.REVENUE_CHART.TITLE') }}
      </h3>
    </div>
    <div class="px-4 pb-4">
      <VueApexCharts
        v-if="chartData.length"
        type="area"
        height="280"
        :options="chartOptions"
        :series="series"
      />
      <div
        v-else
        class="h-[280px] flex items-center justify-center text-n-slate-10 text-sm"
      >
        {{ $t('SALES.MODULE_DASHBOARD.RECENT_ORDERS.NO_ORDERS') }}
      </div>
    </div>
  </div>
</template>
