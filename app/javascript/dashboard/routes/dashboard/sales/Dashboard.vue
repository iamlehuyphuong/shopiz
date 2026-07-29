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
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { OnClickOutside } from '@vueuse/components';

const { t } = useI18n();
const store = useStore();
const getters = useStoreGetters();
const globalConfig = computed(() => getters['globalConfig/get'].value);

const isLoading = ref(true);
const reportData = ref(null);

const sourceFilter = ref('all');
const sources = [
  { label: 'Tất cả nền tảng', value: 'all' },
  { label: 'Shopiz', value: 'shopiz' },
  { label: 'KiotViet', value: 'kiotviet' },
  { label: 'Sapo', value: 'sapo' },
  { label: 'Haravan', value: 'haravan' },
  { label: 'Shopify', value: 'shopify' },
  { label: 'WooCommerce', value: 'woocommerce' },
  { label: 'Nhanh.vn', value: 'nhanhvn' },
];

const showSourceDropdown = ref(false);
const activeSourceName = computed(
  () => sources.find(s => s.value === sourceFilter.value)?.label
);

const appIntegrations = computed(
  () => getters['integrations/getAppIntegrations'].value
);

const isSourceConnected = sourceValue => {
  if (sourceValue === 'all' || sourceValue === 'shopiz') return true;
  const integration = appIntegrations.value?.find(i => i.id === sourceValue);
  return integration && integration.hooks && integration.hooks.length > 0;
};

const sortedSources = computed(() => {
  return [...sources].sort((a, b) => {
    const getWeight = s => {
      if (s.value === 'all') return 0;
      if (s.value === 'shopiz') return 1;
      return isSourceConnected(s.value) ? 2 : 3;
    };
    return getWeight(a) - getWeight(b);
  });
});

const sourceLogo = source => {
  if (!source) return null;
  return `/dashboard/images/integrations/${source}.png`;
};

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
      source: sourceFilter.value === 'all' ? undefined : sourceFilter.value,
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

watch(sourceFilter, () => {
  fetchReports();
});

onMounted(() => {
  store.dispatch('integrations/get');
  fetchReports();
});
</script>

<template>
  <SalesLayout :is-loading="isLoading">
    <template #header>
      <div class="flex flex-col items-start w-full mb-4">
        <div
          class="flex items-center justify-between w-full gap-4 min-h-8 mb-2"
        >
          <div class="flex items-center gap-2">
            <span class="text-heading-1 text-n-slate-12">
              {{ activeSourceName }}
            </span>
            <div class="relative group z-20">
              <OnClickOutside @trigger="showSourceDropdown = false">
                <Button
                  icon="i-lucide-chevron-down"
                  :variant="showSourceDropdown ? 'faded' : 'ghost'"
                  color="slate"
                  size="xs"
                  class="rounded-md group-hover:bg-n-slate-3 hover:bg-n-slate-3 [&>span]:size-4"
                  @click="showSourceDropdown = !showSourceDropdown"
                />

                <div
                  v-if="showSourceDropdown"
                  class="py-3 bg-n-alpha-3 backdrop-blur-[100px] outline outline-n-container outline-1 z-50 absolute ltr:left-0 rtl:right-0 top-9 min-w-[20rem] max-w-[24rem] rounded-xl shadow-lg flex flex-col gap-2 mt-1"
                >
                  <div
                    class="flex items-center justify-between gap-4 px-4 pb-3 border-b border-n-alpha-2 mx-2"
                  >
                    <div class="flex flex-col gap-0.5">
                      <h2 class="text-sm font-semibold text-n-slate-12">
                        Nền tảng
                      </h2>
                      <p class="text-xs text-n-slate-11">
                        Chuyển đổi giữa các nền tảng bán hàng
                      </p>
                    </div>
                  </div>
                  <div
                    class="flex flex-col gap-0.5 px-2 max-h-[60vh] overflow-y-auto"
                  >
                    <Button
                      v-for="s in sortedSources"
                      :key="s.value"
                      variant="ghost"
                      color="slate"
                      class="!justify-between !px-3 !py-2 hover:!bg-n-alpha-2 h-10 w-full"
                      :disabled="!isSourceConnected(s.value)"
                      @click="
                        () => {
                          sourceFilter = s.value;
                          showSourceDropdown = false;
                        }
                      "
                    >
                      <div class="flex items-center gap-2.5 min-w-0">
                        <img
                          v-if="s.value !== 'all' && s.value !== 'shopiz'"
                          :src="sourceLogo(s.value)"
                          class="w-5 h-5 rounded-full object-cover flex-shrink-0"
                        />
                        <img
                          v-else-if="s.value === 'shopiz'"
                          :src="globalConfig.logoThumbnail"
                          class="w-5 h-5 object-contain flex-shrink-0"
                        />
                        <span
                          class="text-sm font-medium truncate text-n-slate-12"
                          >{{ s.label }}</span>
                      </div>
                      <Icon
                        v-if="sourceFilter === s.value"
                        icon="i-lucide-check"
                        class="w-4 h-4 text-n-teal-10 flex-shrink-0"
                      />
                    </Button>
                  </div>
                </div>
              </OnClickOutside>
            </div>

            <div class="w-0.5 h-4 rounded-2xl bg-n-weak ml-2 mr-2" />
            <span class="text-heading-1 text-n-slate-11">
              {{ $t('SALES.MODULE_DASHBOARD.HEADER.TITLE') }}
            </span>
          </div>
        </div>

        <div class="flex flex-col w-full gap-1.5 text-n-slate-11">
          <p class="mb-0 max-w-3xl text-body-main">
            {{ $t('SALES.MODULE_DASHBOARD.HEADER.DESCRIPTION') }}
          </p>
        </div>
      </div>
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
          <OrderHeatmap :date-range="customDateRange" :source="sourceFilter" />
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
