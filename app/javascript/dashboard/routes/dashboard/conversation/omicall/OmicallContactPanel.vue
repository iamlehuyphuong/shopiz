<script setup>
import { useOmicall } from 'dashboard/composables/useOmicall';
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';

const props = defineProps({
  contact: {
    type: Object,
    required: true,
  },
});

const currentUser = useMapGetter('getCurrentUser');
const sipUsername = computed(
  () => currentUser.value?.custom_attributes?.sip_user
);
const sipPassword = computed(
  () => currentUser.value?.custom_attributes?.sip_password
);
const sipDomain = computed(
  () => currentUser.value?.custom_attributes?.sip_domain
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

const initializeOmiCall = () => {
  if (sipUsername.value && sipPassword.value && sipDomain.value) {
    initOmicall(sipUsername.value, sipPassword.value, sipDomain.value);
  } else {
    alert(
      'Vui lòng cấu hình SIP user/password/domain trong Custom Attributes của tài khoản (Profile) trước khi gọi.'
    );
  }
};

const callContact = () => {
  if (!props.contact.phone_number) {
    alert('Liên hệ này chưa có số điện thoại!');
    return;
  }
  makeCall(props.contact.phone_number);
};
</script>

<template>
  <div class="omicall-panel">
    <div v-if="!isInitialized" class="flex flex-col gap-2">
      <woot-button
        size="small"
        icon="call"
        color="success"
        variant="hollow"
        @click="initializeOmiCall"
      >
        Mở Kết nối Tổng đài
      </woot-button>
    </div>
    <div v-else>
      <div v-if="isReady" class="flex flex-col gap-2">
        <p class="text-green-600 font-medium text-xs mb-1">
          <fluent-icon
            icon="checkmark-circle"
            size="14"
            class="inline-block align-middle"
          />
          Đã kết nối tổng đài ({{ sipUsername }})
        </p>
        <div class="flex gap-2">
          <woot-button
            size="small"
            icon="call"
            color="success"
            :disabled="!!currentCall"
            class="flex-1"
            @click="callContact"
          >
            Gọi Contact
          </woot-button>
          <woot-button
            size="small"
            icon="dialpad"
            color="primary"
            variant="hollow"
            title="Mở Bàn phím / Lịch sử"
            @click="toggleDial"
          >
            Numpad
          </woot-button>
        </div>
        <div
          v-if="currentCall"
          class="mt-2 text-xs text-slate-700 dark:text-slate-300"
        >
          Trạng thái gọi: <span class="font-bold">{{ currentCall.state }}</span>
        </div>
      </div>
      <div v-else>
        <p class="text-slate-500 text-xs">
          Trạng thái kết nối: {{ connectionStatus }}...
        </p>
      </div>
    </div>
  </div>
</template>
