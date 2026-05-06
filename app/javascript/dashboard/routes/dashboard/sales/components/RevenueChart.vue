<script setup>
import { computed } from 'vue';
import VueApexCharts from 'vue3-apexcharts';
import { useI18n } from 'vue-i18n';
import eachDayOfInterval from 'date-fns/eachDayOfInterval';
import format from 'date-fns/format';

const props = defineProps({
  chartData: { type: Array, default: () => [] },
  dateRange: { type: Array, default: () => [] },
});

const { t } = useI18n();

const paddedData = computed(() => {
  if (!props.dateRange || props.dateRange.length !== 2) return props.chartData;
  const [start, end] = props.dateRange;
  
  const days = eachDayOfInterval({ start, end });
  return days.map(day => {
    const dateStr = format(day, 'yyyy-MM-dd');
    const existing = props.chartData.find(d => d.date === dateStr);
    return {
      date: dateStr,
      revenue: existing ? existing.revenue : 0,
      orders: existing ? existing.orders : 0,
    };
  });
});

const hasAnyData = computed(() => {
  return paddedData.value.some(d => d.revenue > 0 || d.orders > 0);
});

const series = computed(() => [
  {
    name: t('SALES.MODULE_DASHBOARD.REVENUE_CHART.REVENUE'),
    type: 'area',
    data: paddedData.value.map(d => ({
      x: d.date,
      y: d.revenue,
    })),
  },
  {
    name: t('SALES.MODULE_DASHBOARD.REVENUE_CHART.ORDERS'),
    type: 'line',
    data: paddedData.value.map(d => ({
      x: d.date,
      y: d.orders,
    })),
  }
]);

const chartOptions = computed(() => ({
  chart: {
    height: 280,
    toolbar: { show: false },
    zoom: { enabled: false },
    fontFamily: 'Inter, sans-serif',
    background: 'transparent',
  },
  colors: ['#f97316', '#92400e'],
  fill: {
    type: ['gradient', 'solid'],
    gradient: {
      shadeIntensity: 1,
      opacityFrom: 0.4,
      opacityTo: 0.05,
      stops: [0, 90, 100],
    },
  },
  stroke: {
    curve: 'smooth',
    width: 1.5,
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
  yaxis: [
    {
      seriesName: t('SALES.MODULE_DASHBOARD.REVENUE_CHART.REVENUE'),
      labels: {
        style: { colors: 'var(--n-slate-11)', fontSize: '11px' },
        formatter: val => {
          if (val >= 1_000_000) return `${(val / 1_000_000).toFixed(1)}M`;
          if (val >= 1_000) return `${(val / 1_000).toFixed(0)}K`;
          return val;
        },
      },
    },
    {
      seriesName: t('SALES.MODULE_DASHBOARD.REVENUE_CHART.ORDERS'),
      opposite: true,
      labels: {
        style: { colors: 'var(--n-slate-11)', fontSize: '11px' },
        formatter: val => Math.round(val),
      },
    }
  ],
  tooltip: {
    theme: 'dark',
    x: { format: 'dd/MM/yyyy' },
    y: [
      {
        formatter: val =>
          new Intl.NumberFormat('vi-VN', {
            style: 'currency',
            currency: 'VND',
            maximumFractionDigits: 0,
          }).format(val),
      },
      {
        formatter: val => val,
      }
    ],
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
        v-if="hasAnyData"
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
