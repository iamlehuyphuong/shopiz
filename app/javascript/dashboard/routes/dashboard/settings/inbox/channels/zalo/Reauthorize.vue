<script>
/* eslint-env browser */
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { mapGetters } from 'vuex';
import axios from 'axios';

export default {
  components: {
    LoadingState,
  },
  setup() {
    const { accountId } = useAccount();
    return {
      accountId,
      v$: useVuelidate(),
    };
  },
  data() {
    return {
      socket: null,
      countdownInterval: null,
      qrCode: "",
      isCreating: false,
      hasError: false,
      omniauth_token: '',
      access_token: '',
      refresh_token: '',
      expires_in: '',
      oa_id: '',
      pageName: '',
      avatar: '',
      channel: 'zalopersonal',
      emptyStateMessage: this.$t('INBOX_MGMT.ADD.ZALO_OA.LOADING'),
      errorStateMessage: '',
      errorStateDescription: '',
      successStateDescription: this.$t('LOGIN.API.SUCCESS_MESSAGE'),
      hasLoginStarted: false,
    };
  },
  validations: {
    pageName: {
      required,
    },
  },
  computed: {
    showLoader() {
      return this.oa_id === '' || this.isCreating;
    },
    ...mapGetters({
      // currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
    }),
  },
  created() {
    //if (this.$route.query.code) this.getAccessToken();
    this.generateQR();
  },
  methods: {
    startLogin() {
      this.generateQR();
    },
    generateQR() {
      this.qrCode = `${window.shopizConfig?.zaloApiUrl}/api/zalo-login?proxy`;
      this.connectWebSocket();
      this.hasLoginStarted = false;
    },
    connectWebSocket() {
      // Đóng kết nối WebSocket cũ nếu có
      if (this.socket) {
        this.socket.close();
      }
      // Xác định URL WebSocket dựa trên URL hiện tại
      //const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
      const wsUrl = `${window.shopizConfig?.zaloApiUrl.replace('http', 'ws')}/ws`;
      console.log('Đang kết nối đến WebSocket tại:', wsUrl);
      try {
          this.socket = new WebSocket(wsUrl);
          this.socket.onopen = function() {
              console.log('WebSocket đã kết nối');
              this.hasError = false;
              this.emptyStateMessage = 'Kết nối WebSocket thành công. Vui lòng quét mã QR để đăng nhập.';
          }.bind(this);
          this.socket.onmessage = function(event) {
            console.log('Nhận tin nhắn WebSocket:', event.data);
            if (event.data.indexOf('login_success:') === 0) {
                console.log('Đăng nhập thành công qua WebSocket',event);
                this.emptyStateMessage = 'Đăng nhập thành công. Đang tải danh sách hội thoại';
                this.hasLoginStarted = true;
                this.hasError = false;
                this.oa_id = event.data.split(':')[1];
                this.access_token = this.oa_id;
                this.refresh_token = this.oa_id;
                this.expires_in = 90000;
                console.log('oa_id:', this.oa_id);
            }
          }.bind(this);

          this.socket.onerror = function(error) {
              console.error('Lỗi WebSocket:', error);
              this.hasError = true;
              this.errorStateMessage = 'Lỗi kết nối WebSocket.Thử kết nối lại.';
          }.bind(this);

          this.socket.onclose = function() {
              console.log('WebSocket đã đóng kết nối');
              this.hasError = true;
              this.errorStateMessage = 'Kết nối WebSocket đã đóng.';
          }.bind(this);
      } catch (err) {
          console.error('Lỗi khi tạo WebSocket:', err);
          this.hasError = true;
          this.errorStateMessage = 'Không thể tạo kết nối WebSocket.';
      }
    },
  },
};
</script>

<template>
  <div class="wizard-body w-full flex-shrink-0 flex-grow-0">
    <div v-if="!hasLoginStarted" class="flex flex-col login-init items-center justify-center pt-10">
      <div class="text-center w-[300px]">
        <p class="font-bold mb-0 text-lg">{{ $t('INBOX_MGMT.ADD.ZALO_PERSONAL.DESC') }}<span class="text-n-blue-text">Zalo</span></p>
        <p class="font-bold text-lg">{{ $t('INBOX_MGMT.ADD.ZALO_PERSONAL.DESC_2') }} <span class="text-n-blue-text">Shopiz</span></p>
      </div>
      <img
        v-if="qrCode"
        :src="qrCode"
        alt="Zalo-Login-QR"
        class="text-center w-[300px] h-[300px]"
      />
      <p class="pt-6 mb-0 text-center">{{ $t('INBOX_MGMT.ADD.ZALO_PERSONAL.HELP') }}</p>
      <p class="text-center">{{ $t('INBOX_MGMT.ADD.ZALO_PERSONAL.HELP_2') }}</p>
    </div>
    <div v-else class="pt-10">
      <div v-if="hasError" class="max-w-lg mx-auto text-center">
        <h5>{{ errorStateMessage }}</h5>
        <p
          v-if="errorStateDescription"
          v-dompurify-html="errorStateDescription"
        />
      </div>
      <LoadingState v-else-if="showLoader" :message="emptyStateMessage" />
      <p
        v-else
        v-dompurify-html="successStateDescription"
      ></p>

    </div>
  </div>
</template>
