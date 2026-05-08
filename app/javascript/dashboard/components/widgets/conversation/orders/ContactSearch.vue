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
    <div class="relative">
      <input
        v-model="searchQuery"
        type="text"
        :placeholder="
          $t('SALES.ORDER_FORM.PLACEHOLDERS.SEARCH_CONTACT') ||
          'Tìm kiếm khách hàng theo tên, SĐT...'
        "
        class="w-full px-3 pr-8 py-1.5 text-sm rounded-lg border border-n-weak bg-n-solid-1 text-n-slate-12 placeholder:text-n-slate-9 outline-none focus:border-n-brand focus:ring-1 focus:ring-n-brand/30 transition-all"
      />
      <fluent-icon
        v-if="isSearching"
        icon="spinner"
        size="16"
        class="absolute right-3 top-1/2 -translate-y-1/2 text-n-slate-10 animate-spin"
      />
      <button
        v-else-if="searchQuery.length > 0"
        class="absolute right-2 top-1/2 -translate-y-1/2 p-0.5 rounded hover:bg-n-alpha-2 text-n-slate-10 hover:text-n-slate-12 transition-colors"
        @click="
          searchQuery = '';
          results = [];
        "
      >
        <fluent-icon icon="dismiss" size="12" />
      </button>
    </div>

    <!-- Results -->
    <div
      v-if="results.length > 0"
      class="max-h-48 overflow-y-auto rounded-lg border border-n-weak bg-n-solid-1 divide-y divide-n-weak"
    >
      <button
        v-for="contact in results"
        :key="contact.id"
        class="w-full flex items-center gap-2.5 px-3 py-2 hover:bg-n-alpha-1 transition-colors text-left"
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
          {{ contact.name.charAt(0) }}
        </div>
        <div class="flex-1 min-w-0">
          <div class="text-sm font-medium text-n-slate-12 truncate">
            {{ contact.name }}
          </div>
          <div
            v-if="contact.phone_number || contact.email"
            class="text-xs text-n-slate-10 truncate"
          >
            {{ contact.phone_number }}
            {{ contact.phone_number && contact.email ? '•' : '' }}
            {{ contact.email }}
          </div>
        </div>
      </button>
    </div>
  </div>
</template>
