<template>
  <div class="mt-4">
    <div class="flex items-center justify-between mb-4">
      <Input
        v-model="searchQuery"
        :placeholder="$t('INBOX_MGMT.LABEL_SYNC.SEARCH_PLACEHOLDER')"
        class="group w-64 min-w-0 flex [&_input]:ltr:!pl-10 [&_input]:rtl:!pr-10 [&_input]:!rounded-[0.625rem]"
        size="sm"
        type="search"
      >
        <template #prefix>
          <Icon
            icon="i-lucide-search"
            class="absolute top-1/2 -translate-y-1/2 text-n-slate-11 group-focus-within:text-n-orange size-3.5 ltr:left-2.5 rtl:right-2.5"
          />
        </template>
      </Input>
      <div class="flex items-center">
        <span class="text-sm text-n-slate-11 mr-4">{{ $t('INBOX_MGMT.LABEL_SYNC.LABELS_COUNT', { count: filteredLabels.length }) }}</span>
        <woot-button
          v-if="!hasFetched"
          icon="arrow-download"
          :is-loading="isLoading"
          class="!bg-[#f17032] hover:!bg-[#e05f24] !border-none !text-white !text-[13px] !py-1 !px-3 !min-h-0 !rounded-md !cursor-pointer"
          @click="fetchNativeLabels(true)"
        >
          {{ $t('INBOX_MGMT.LABEL_SYNC.FETCH_BUTTON') }}
        </woot-button>
        <woot-button
          v-if="hasFetched"
          icon="arrow-sync"
          :is-loading="isSyncing"
          class="!bg-[#f17032] hover:!bg-[#e05f24] !border-none !text-white !text-[13px] !py-1 !px-3 !min-h-0 !rounded-md !cursor-pointer"
          @click="syncLabels"
        >
          {{ $t('INBOX_MGMT.LABEL_SYNC.SYNC_BUTTON') }}
        </woot-button>
      </div>
    </div>

    <div v-if="isLoading" class="flex items-center justify-center p-8">
      <spinner />
    </div>
    
    <div v-else class="w-full">
      <table class="w-full text-left">
        <thead class="border-y border-n-strong dark:border-n-strong/50">
          <tr>
            <th class="px-4 py-3 text-sm font-medium text-n-slate-12">
              {{ $t('INBOX_MGMT.LABEL_SYNC.COLUMNS.CHANNEL_LABEL_ID') }}
            </th>
            <th class="px-4 py-3 text-sm font-medium text-n-slate-12">
              {{ $t('INBOX_MGMT.LABEL_SYNC.COLUMNS.CHANNEL_LABEL_NAME') }}
            </th>
            <th class="px-4 py-3 text-sm font-medium text-n-slate-12">
              {{ $t('INBOX_MGMT.LABEL_SYNC.COLUMNS.COLOR') }}
            </th>
            <th class="px-4 py-3 text-sm font-medium text-n-slate-12 w-64">
              {{ $t('INBOX_MGMT.LABEL_SYNC.COLUMNS.SHOPIZ_LABEL') }}
            </th>
            <th class="px-4 py-3 text-sm font-medium text-n-slate-12 w-40">
              {{ $t('INBOX_MGMT.LABEL_SYNC.COLUMNS.STATUS') }}
            </th>
          </tr>
        </thead>
        <tbody class="divide-y divide-n-strong dark:divide-n-strong/50">
          <tr v-if="filteredLabels.length === 0">
            <td colspan="5" class="px-4 py-8 text-center text-n-slate-11">
              {{ !hasFetched && !searchQuery ? $t('INBOX_MGMT.LABEL_SYNC.NOT_FETCHED') : (searchQuery ? $t('INBOX_MGMT.LABEL_SYNC.NO_RESULTS') : $t('INBOX_MGMT.LABEL_SYNC.NO_LABELS')) }}
            </td>
          </tr>
          <tr v-for="label in filteredLabels" :key="label.id">
            <td class="px-4 py-3 text-sm text-n-slate-12">
              {{ label.id }}
            </td>
            <td class="px-4 py-3 text-sm text-n-slate-12">
              {{ label.text }}
            </td>
            <td class="px-4 py-3 text-sm text-n-slate-11">
              <div class="flex items-center gap-2">
                <span class="w-4 h-4 rounded border border-n-strong dark:border-n-strong/50" :style="{ backgroundColor: label.color || '#cccccc' }" />
                {{ label.color || '#cccccc' }}
              </div>
            </td>
            <td class="px-4 py-3 text-sm">
              <Select
                v-model="label.selected_label_id"
                :options="mappedAppLabels"
                class="w-full [&_select]:w-full"
              />
            </td>
            <td class="px-4 py-3 text-sm">
              <span v-if="label.mapped_label_id" class="text-green-600 dark:text-green-500 font-medium">
                {{ $t('INBOX_MGMT.LABEL_SYNC.SYNCED') }}
              </span>
              <span v-else class="text-n-slate-10">
                {{ $t('INBOX_MGMT.LABEL_SYNC.NOT_SYNCED') }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script>
import { useAlert } from 'dashboard/composables';
import Spinner from 'shared/components/Spinner.vue';
import InboxAPI from 'dashboard/api/inboxes';
import Input from 'dashboard/components-next/input/Input.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Select from 'dashboard/components-next/select/Select.vue';

export default {
  components: {
    Spinner,
    Input,
    Icon,
    Select,
  },
  props: {
    inbox: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      isSyncing: false,
      hasFetched: false,
      nativeLabels: [],
      searchQuery: '',
    };
  },
  computed: {
    appLabels() {
      return this.$store.getters['labels/getLabels'];
    },
    mappedAppLabels() {
      return [
        { value: null, label: this.$t('INBOX_MGMT.LABEL_SYNC.CREATE_NEW') },
        ...this.appLabels.map(label => ({
          value: label.id,
          label: label.title,
        })),
      ];
    },
    filteredLabels() {
      if (!this.searchQuery) return this.nativeLabels;
      const query = this.searchQuery.toLowerCase();
      return this.nativeLabels.filter(label => (label.text || '').toLowerCase().includes(query));
    },
  },
  mounted() {
    this.$store.dispatch('labels/get');
    this.fetchNativeLabels(false);
  },
  methods: {
    async fetchNativeLabels(fetchFromZalo = true) {
      this.isLoading = true;
      try {
        const response = await InboxAPI.getNativeLabels(this.inbox.id, fetchFromZalo);
        this.nativeLabels = (response.data.data || []).map(label => ({
          ...label,
          selected_label_id: label.mapped_label_id || null,
        }));
      } catch (error) {
        useAlert(error.response?.data?.error || this.$t('INBOX_MGMT.LABEL_SYNC.FETCH_ERROR'));
      } finally {
        this.isLoading = false;
        if (fetchFromZalo === true) {
          this.hasFetched = true;
        }
      }
    },
    async syncLabels() {
      this.isSyncing = true;
      try {
        const mappings = this.nativeLabels.map(label => ({
          native_label_id: label.id,
          native_label_name: label.text,
          label_id: label.selected_label_id,
          color: label.color,
        }));
        
        const response = await InboxAPI.updateLabelMappings(this.inbox.id, { mappings });
        useAlert(response.data.message || this.$t('INBOX_MGMT.LABEL_SYNC.SYNC_SUCCESS'));
        
        // Refresh to get updated mapping status
        await this.fetchNativeLabels(false);
        this.$store.dispatch('labels/get'); // In case new labels were created
      } catch (error) {
        useAlert(error.response?.data?.error || this.$t('INBOX_MGMT.LABEL_SYNC.SYNC_ERROR'));
      } finally {
        this.isSyncing = false;
      }
    },
  },
};
</script>
