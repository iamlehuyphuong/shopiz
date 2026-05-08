<script setup>
import { computed, h } from 'vue';
import {
  useVueTable,
  createColumnHelper,
  getCoreRowModel,
  getPaginationRowModel,
} from '@tanstack/vue-table';
import { useI18n } from 'vue-i18n';
import Table from 'dashboard/components/table/Table.vue';
import Pagination from 'dashboard/components/table/Pagination.vue';
import EmptyState from 'dashboard/components/widgets/EmptyState.vue';
import InboxCell from './InboxCell.vue';

const props = defineProps({
  data: {
    type: Array,
    default: () => [],
  },
  isLoading: {
    type: Boolean,
    default: false,
  },
});

const { t } = useI18n();

const defaultSpanRender = cellProps =>
  h(
    'span',
    {
      class: 'text-n-slate-12',
    },
    cellProps.getValue() !== undefined ? cellProps.getValue() : '---'
  );

const columnHelper = createColumnHelper();
const columns = [
  columnHelper.accessor('name', {
    header: t('SALES.MODULE_DASHBOARD.ORDERS_BY_INBOX.INBOX', 'Inbox'),
    cell: cellProps => h(InboxCell, cellProps),
    size: 250,
  }),
  columnHelper.accessor('count', {
    header: t('SALES.MODULE_DASHBOARD.ORDERS_BY_INBOX.ORDER_COUNT', 'Orders'),
    cell: defaultSpanRender,
    size: 100,
  }),
];

const table = useVueTable({
  get data() {
    return props.data;
  },
  columns,
  enableSorting: false,
  getCoreRowModel: getCoreRowModel(),
  getPaginationRowModel: getPaginationRowModel(),
  initialState: {
    pagination: {
      pageSize: 10,
    },
  },
});
</script>

<template>
  <div
    class="bg-white dark:bg-n-solid-1 rounded-xl border border-n-weak shadow-sm flex flex-col"
  >
    <div class="px-6 py-4">
      <h3 class="text-sm font-medium text-n-slate-12 mb-0">
        {{
          t('SALES.MODULE_DASHBOARD.ORDERS_BY_INBOX.TITLE', 'Orders by inbox')
        }}
      </h3>
    </div>
    <div class="flex flex-col flex-1 px-6 pb-6 pt-2">
      <Table
        v-if="data.length"
        :table="table"
        class="max-h-[calc(100vh-21.875rem)]"
      />
      <Pagination
        v-if="data.length"
        class="mt-2"
        :table="table"
        show-page-size-selector
        :default-page-size="10"
      />
      <EmptyState
        v-if="!isLoading && !data.length"
        :title="
          t(
            'SALES.MODULE_DASHBOARD.ORDERS_BY_INBOX.NO_DATA',
            'No data available'
          )
        "
      />
    </div>
  </div>
</template>
