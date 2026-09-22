<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import ContactAPI from 'dashboard/api/contacts';

const emit = defineEmits(['select-contact']);

const { t } = useI18n();
const searchQuery = ref('');
const results = ref([]);
const isSearching = ref(false);
const searchTimeout = ref(null);

const performSearch = async () => {
  if (searchQuery.value.length < 2) {
    results.value = [];
    return;
  }
  isSearching.value = true;
  try {
    const { data } = await ContactAPI.search(searchQuery.value, 1, 'name', '');
    results.value = data.payload || [];
  } catch {
    results.value = [];
  } finally {
    isSearching.value = false;
  }
};

const debouncedSearch = () => {
  clearTimeout(searchTimeout.value);
  searchTimeout.value = setTimeout(performSearch, 400);
};

watch(searchQuery, debouncedSearch);

const selectContact = contact => {
  emit('select-contact', contact);
  searchQuery.value = '';
  results.value = [];
};
</script>

<template>
  <div class="flex flex-col gap-2">
    <div
      class="flex items-center w-full h-[38px] px-3 rounded-lg border border-n-weak bg-white dark:bg-n-solid-1 focus-within:border-n-brand focus-within:ring-1 focus-within:ring-n-brand/30 transition-all"
    >
      <i class="i-lucide-search text-n-slate-10 text-base shrink-0" />
      <input
        v-model="searchQuery"
        type="text"
        :placeholder="
          $t('SALES.ORDER_FORM.PLACEHOLDERS.SEARCH_CONTACT') ||
          'Tìm kiếm khách hàng bằng tên, email hoặc số điện thoại'
        "
        class="reset-base flex-1 w-full h-full !px-3 !py-0 text-sm !bg-transparent !border-none !outline-none !shadow-none !ring-0 text-n-slate-12 placeholder:text-n-slate-9 !m-0 !leading-normal !mb-0"
      />
      <div class="flex items-center shrink-0">
        <i
          v-if="isSearching"
          class="i-lucide-loader-2 text-n-slate-10 animate-spin text-base"
        />
        <button
          v-else-if="searchQuery.length > 0"
          class="p-1 rounded hover:bg-n-alpha-2 text-n-slate-10 hover:text-n-slate-12 transition-colors flex items-center justify-center"
          @click="
            searchQuery = '';
            results = [];
          "
        >
          <i class="i-lucide-x text-sm" />
        </button>
      </div>
    </div>

    <!-- Results -->
    <div
      v-if="results.length > 0"
      class="max-h-64 overflow-y-auto rounded-lg border border-n-weak bg-white dark:bg-slate-900 shadow-md"
    >
      <div class="p-1.5 space-y-0.5">
        <button
          v-for="contact in results"
          :key="contact.id"
          class="w-full flex items-center gap-3 px-2.5 py-2 rounded-md hover:bg-n-alpha-1 transition-colors text-left"
          @click="selectContact(contact)"
        >
          <img
            v-if="contact.thumbnail"
            :src="contact.thumbnail"
            :alt="contact.name"
            class="w-8 h-8 rounded-full object-cover shrink-0 bg-n-solid-3"
          />
          <div
            v-else
            class="w-8 h-8 rounded-full bg-n-brand text-white flex items-center justify-center shrink-0 font-medium text-xs uppercase"
          >
            {{ contact.name ? contact.name.charAt(0) : '?' }}
          </div>
          <div class="flex-1 min-w-0">
            <div class="text-sm font-medium text-n-slate-12 truncate">
              {{ contact.name }}
            </div>
            <div
              v-if="contact.phone_number || contact.email"
              class="text-xs text-n-slate-10 truncate mt-0.5"
            >
              {{ contact.phone_number }}
              {{ contact.phone_number && contact.email ? '•' : '' }}
              {{ contact.email }}
            </div>
          </div>
        </button>
      </div>
    </div>

    <div
      v-else-if="
        searchQuery.length >= 2 && !isSearching && results.length === 0
      "
      class="text-center py-3 text-sm text-n-slate-10"
    >
      Không tìm thấy khách hàng
    </div>
  </div>
</template>
