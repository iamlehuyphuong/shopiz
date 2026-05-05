<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import ReportHeader from './components/ReportHeader.vue';
import ReportFilters from './components/ReportFilters.vue';
import AccountAPI from 'dashboard/api/account';

const { t } = useI18n();
const store = useStore();

const loading = ref(false);
const analyticsData = ref(null);
const dateRange = ref({ from: null, to: null });

const accountId = computed(() => store.getters.getCurrentAccountId);

const platformLabels = {
  kiotviet: 'KiotViet',
  sapo: 'Sapo',
  haravan: 'Haravan',
  woocommerce: 'WooCommerce',
  shopify: 'Shopify',
  nhanhvn: 'Nhanh.vn',
  tiktok_shop: 'TikTok Shop',
};

const statusLabels = {
  draft: { label: 'Nháp', color: 'bg-n-slate-3' },
  confirmed: { label: 'Xác nhận', color: 'bg-n-blue-3' },
  processing: { label: 'Đang xử lý', color: 'bg-n-amber-3' },
  shipped: { label: 'Đang giao', color: 'bg-n-violet-3' },
  delivered: { label: 'Hoàn thành', color: 'bg-n-teal-3' },
  cancelled: { label: 'Đã hủy', color: 'bg-n-ruby-3' },
};

const formatCurrency = (value, currency = 'VND') => {
  return new Intl.NumberFormat('vi-VN', {
    style: 'currency',
    currency,
    maximumFractionDigits: 0,
  }).format(value);
};

const fetchAnalytics = async () => {
  loading.value = true;
  try {
    const params = {};
    if (dateRange.value.from)
      params.since = new Date(dateRange.value.from * 1000).toISOString();
    if (dateRange.value.to)
      params.until = new Date(dateRange.value.to * 1000).toISOString();
    params.group_by = 'day';

    const response = await AccountAPI.getOrderAnalytics(
      accountId.value,
      params
    );
    analyticsData.value = response.data;
  } catch {
    analyticsData.value = null;
  } finally {
    loading.value = false;
  }
};

const onFilterChange = ({ from, to }) => {
  dateRange.value = { from, to };
  fetchAnalytics();
};

onMounted(() => {
  fetchAnalytics();
});
</script>

<template>
  <div>
    <ReportHeader :header-title="t('ORDER_ANALYTICS.HEADER')" />
    <div class="flex flex-col">
      <ReportFilters
        :show-entity-filter="false"
        @filter-change="onFilterChange"
      />

      <div v-if="loading" class="flex items-center justify-center py-12">
        <span class="text-n-slate-11">{{ t('ORDER_ANALYTICS.LOADING') }}</span>
      </div>

      <div v-else-if="analyticsData" class="flex flex-col gap-6 p-4">
        <!-- Summary Cards -->
        <div class="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <div class="rounded-xl border border-n-weak bg-n-background p-4">
            <p class="text-sm text-n-slate-11">
              {{ t('ORDER_ANALYTICS.TOTAL_ORDERS') }}
            </p>
            <p class="mt-1 text-2xl font-semibold text-n-slate-12">
              {{ analyticsData.summary.total_orders }}
            </p>
          </div>
          <div class="rounded-xl border border-n-weak bg-n-background p-4">
            <p class="text-sm text-n-slate-11">
              {{ t('ORDER_ANALYTICS.TOTAL_REVENUE') }}
            </p>
            <p class="mt-1 text-2xl font-semibold text-n-slate-12">
              {{ formatCurrency(analyticsData.summary.total_revenue) }}
            </p>
          </div>
          <div class="rounded-xl border border-n-weak bg-n-background p-4">
            <p class="text-sm text-n-slate-11">
              {{ t('ORDER_ANALYTICS.AVG_ORDER_VALUE') }}
            </p>
            <p class="mt-1 text-2xl font-semibold text-n-slate-12">
              {{ formatCurrency(analyticsData.summary.avg_order_value) }}
            </p>
          </div>
        </div>

        <!-- Platform Breakdown -->
        <div class="rounded-xl border border-n-weak bg-n-background p-4">
          <h3 class="mb-3 text-sm font-medium text-n-slate-12">
            {{ t('ORDER_ANALYTICS.BY_PLATFORM') }}
          </h3>
          <div v-if="analyticsData.by_platform.length > 0" class="space-y-2">
            <div
              v-for="item in analyticsData.by_platform"
              :key="item.platform"
              class="flex items-center justify-between rounded-lg bg-n-alpha-2 px-3 py-2"
            >
              <span class="text-sm font-medium text-n-slate-12">
                {{ platformLabels[item.platform] || item.platform }}
              </span>
              <div class="flex items-center gap-4">
                <span class="text-xs text-n-slate-11">
                  {{ item.order_count }} {{ t('ORDER_ANALYTICS.ORDERS') }}
                </span>
                <span class="text-sm font-semibold text-n-slate-12">
                  {{ formatCurrency(item.revenue) }}
                </span>
              </div>
            </div>
          </div>
          <p v-else class="text-sm text-n-slate-10">
            {{ t('ORDER_ANALYTICS.NO_DATA') }}
          </p>
        </div>

        <!-- Status Breakdown -->
        <div class="rounded-xl border border-n-weak bg-n-background p-4">
          <h3 class="mb-3 text-sm font-medium text-n-slate-12">
            {{ t('ORDER_ANALYTICS.BY_STATUS') }}
          </h3>
          <div class="flex flex-wrap gap-3">
            <div
              v-for="(count, status) in analyticsData.by_status"
              :key="status"
              class="flex items-center gap-2 rounded-lg bg-n-alpha-2 px-3 py-2"
            >
              <span
                class="size-2 rounded-full"
                :class="statusLabels[status]?.color || 'bg-n-slate-6'"
              />
              <span class="text-sm text-n-slate-11">
                {{ statusLabels[status]?.label || status }}
              </span>
              <span class="text-sm font-semibold text-n-slate-12">
                {{ count }}
              </span>
            </div>
          </div>
        </div>
      </div>

      <div v-else class="flex items-center justify-center py-12">
        <p class="text-sm text-n-slate-10">
          {{ t('ORDER_ANALYTICS.NO_DATA') }}
        </p>
      </div>
    </div>
  </div>
</template>
