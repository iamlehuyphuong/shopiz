<script setup>
import { useOmicall } from 'dashboard/composables/useOmicall';
import { computed, ref } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

const props = defineProps({
  contact: {
    type: Object,
    required: true,
  },
  isExpanded: {
    type: Boolean,
    default: false,
  },
});

const currentUser = useMapGetter('getCurrentUser');
const sipUsername = computed(
  () =>
    currentUser.value?.omicall_sip_info?.sip_user ||
    currentUser.value?.custom_attributes?.sip_user
);
const sipPassword = computed(
  () =>
    currentUser.value?.omicall_sip_info?.sip_password ||
    currentUser.value?.custom_attributes?.sip_password
);
const sipDomain = computed(
  () =>
    currentUser.value?.omicall_sip_info?.sip_domain ||
    currentUser.value?.custom_attributes?.sip_domain
);

const {
  isInitialized,
  isReady,
  connectionStatus,
  currentCall,
  initOmicall,
  makeCall,
  toggleDial,
} = useOmicall();

const showAlertModal = ref(false);
const alertMessage = ref('');

import { useI18n } from 'vue-i18n';
const { t } = useI18n();

const initializeOmiCall = () => {
  if (sipUsername.value && sipPassword.value && sipDomain.value) {
    initOmicall(sipUsername.value, sipPassword.value, sipDomain.value);
  } else {
    alertMessage.value = t('CONTACT_PANEL.OMICALL.MISSING_SIP_CONFIG');
    showAlertModal.value = true;
  }
};

const callContact = () => {
  if (!props.contact.phone_number) {
    alertMessage.value = t('CONTACT_PANEL.OMICALL.MISSING_PHONE');
    showAlertModal.value = true;
    return;
  }
  makeCall(props.contact.phone_number);
};

const closeAlertModal = () => {
  showAlertModal.value = false;
  alertMessage.value = '';
};

import omicallAPI from 'dashboard/api/integrations/omicall';
import { onMounted, watch } from 'vue';

const callHistory = ref([]);
const isLoadingHistory = ref(false);
const historyError = ref('');
const hasFetchedForCurrentPhone = ref(false);

const fetchCallHistory = async () => {
  if (!props.contact.phone_number) {
    callHistory.value = [];
    hasFetchedForCurrentPhone.value = true;
    return;
  }

  isLoadingHistory.value = true;
  historyError.value = '';

  try {
    const response = await omicallAPI.getCallHistory({
      phoneNumber: props.contact.phone_number,
    });
    if (response.data && response.data.items) {
      callHistory.value = response.data.items;
    } else {
      callHistory.value = [];
    }
  } catch (error) {
    historyError.value = t('CONTACT_PANEL.OMICALL.LOAD_FAILED');
    callHistory.value = [];
    console.error(error);
  } finally {
    isLoadingHistory.value = false;
    hasFetchedForCurrentPhone.value = true;
  }
};

const formatDate = timestamp => {
  if (!timestamp) return '';
  const date = new Date(timestamp);
  return date.toLocaleString('vi-VN');
};

const formatDuration = seconds => {
  if (!seconds) return '0s';
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return m > 0 ? `${m}m ${s}s` : `${s}s`;
};

onMounted(() => {
  if (props.isExpanded) {
    fetchCallHistory();
  }
});

watch(
  () => props.contact.phone_number,
  () => {
    callHistory.value = [];
    hasFetchedForCurrentPhone.value = false;
    if (props.isExpanded) {
      fetchCallHistory();
    }
  }
);

watch(
  () => props.isExpanded,
  expanded => {
    if (expanded && !hasFetchedForCurrentPhone.value) {
      fetchCallHistory();
    }
  }
);
</script>

<template>
  <div class="omicall-panel">
    <div v-if="!isInitialized" class="px-4 py-3">
      <div class="text-[12px] text-n-slate-11 mb-2">
        {{ $t('CONTACT_PANEL.OMICALL.NOT_CONNECTED') }}
      </div>
      <button
        class="flex items-center text-[12px] text-n-orange-11 hover:underline"
        @click="initializeOmiCall"
      >
        <fluent-icon icon="arrow-right" class="mr-1" size="12" />
        {{ $t('CONTACT_PANEL.OMICALL.CONNECT_OMICALL') }}
      </button>
    </div>
    <div v-else>
      <div v-if="isReady" class="flex flex-col gap-2">
        <div
          v-if="currentCall"
          class="mt-2 text-xs text-slate-700 dark:text-slate-300"
        >
          {{ $t('CONTACT_PANEL.OMICALL.CALL_STATUS') }}:
          <span class="font-bold">{{ currentCall.state }}</span>
        </div>
      </div>
    </div>

    <!-- Always show call history regardless of PBX connection status -->
    <div>
      <div
        v-if="isLoadingHistory && !callHistory.length"
        class="text-center py-4"
      >
        <woot-spinner size="small" />
      </div>

      <div v-else-if="historyError" class="text-xs text-red-500 py-2">
        {{ historyError }}
      </div>

      <div
        v-else-if="callHistory.length === 0"
        class="px-4 py-3 mb-4 text-n-slate-11"
      >
        {{ $t('CONTACT_PANEL.OMICALL.NO_HISTORY') }}
      </div>

      <div v-else class="flex flex-col max-h-64 overflow-y-auto pr-1">
        <div
          v-for="call in callHistory"
          :key="call.transaction_id"
          class="py-3 first:pt-0 border-b border-slate-100 dark:border-slate-800 last:border-b-0 text-xs"
        >
          <div class="flex justify-between items-start mb-1">
            <span class="font-semibold text-slate-700 dark:text-slate-200">
              <span
                class="inline-block align-middle mr-1"
                :class="[
                  call.direction === 'outbound'
                    ? 'i-lucide-phone-outgoing text-n-orange-11'
                    : 'i-lucide-phone-incoming text-green-500',
                ]"
              />
              {{
                call.direction === 'outbound'
                  ? $t('CONTACT_PANEL.OMICALL.DIRECTION.OUTGOING')
                  : $t('CONTACT_PANEL.OMICALL.DIRECTION.INCOMING')
              }}
            </span>
            <span class="text-slate-400">{{
              formatDate(call.created_date)
            }}</span>
          </div>
          <div class="flex justify-between items-center">
            <span
              class="font-medium"
              :class="
                call.disposition === 'answered'
                  ? 'text-green-600 dark:text-green-400'
                  : 'text-red-500 dark:text-red-400'
              "
            >
              {{
                call.disposition === 'answered'
                  ? $t('CONTACT_PANEL.OMICALL.DISPOSITION.ANSWERED')
                  : $t('CONTACT_PANEL.OMICALL.DISPOSITION.MISSED')
              }}
            </span>
            <span v-if="call.duration > 0">
              <fluent-icon
                icon="clock"
                size="12"
                class="inline-block align-middle mr-1"
              />
              {{ formatDuration(call.duration) }}
            </span>
          </div>
          <div v-if="call.recording_file_url" class="mt-2">
            <audio controls class="w-full h-8">
              <source :src="call.recording_file_url" type="audio/mpeg" />
              Your browser does not support the audio element.
            </audio>
          </div>
        </div>
      </div>

      <div class="flex justify-end mt-2">
        <button
          class="flex items-center text-[12px] text-n-orange-11 hover:underline disabled:opacity-50"
          :disabled="isLoadingHistory"
          @click="fetchCallHistory"
        >
          <fluent-icon
            v-if="!isLoadingHistory"
            icon="arrow-right"
            class="mr-1"
            size="12"
          />
          <woot-spinner v-else size="small" class="mr-1" />
          {{ $t('CONTACT_PANEL.OMICALL.GET_HISTORY') }}
        </button>
      </div>
    </div>

    <woot-modal v-model:show="showAlertModal" :on-close="closeAlertModal">
      <div class="h-auto overflow-auto flex flex-col">
        <woot-modal-header
          :header-title="$t('CONTACT_PANEL.OMICALL.ALERT_TITLE')"
          :header-content="alertMessage"
        />
        <div class="flex flex-row justify-end gap-2 py-4 px-6 w-full">
          <woot-button @click="closeAlertModal">
            {{ $t('CONTACT_PANEL.OMICALL.ALERT_UNDERSTOOD') }}
          </woot-button>
        </div>
      </div>
    </woot-modal>
  </div>
</template>
