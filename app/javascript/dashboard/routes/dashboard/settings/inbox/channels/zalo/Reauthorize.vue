<script>
/* eslint-env browser */
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
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
      qrCode: '',
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
      proxyUrl: '',
      proxyUsed: '',
      isGeneratingQR: false,
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
    // if (this.$route.query.code) this.getAccessToken();
  },
  methods: {
    startLogin() {
      this.generateQR();
    },
    async generateQR() {
      try {
        this.isGeneratingQR = true;
        this.qrCode = ''; // Clear old QR code
        if (this.socket) {
          this.socket.close();
        }
        
        const payload = {};
        if (this.proxyUrl) {
          payload.proxy = this.proxyUrl;
        }
        
        const response = await axios.post(`${window.shopizConfig?.zaloApiUrl}/api/zalo-login`, payload);
        
        if (response.data.success) {
          this.qrCode = response.data.qrCodeImage;
          this.proxyUsed = response.data.proxyUsed;
          this.connectWebSocket();
          this.hasLoginStarted = false;
          this.hasError = false;
        } else {
          useAlert(this.$t('INBOX_MGMT.ADD.ZALO_PERSONAL.QR_ERROR'));
        }
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.ADD.ZALO_PERSONAL.QR_NETWORK_ERROR'));
      } finally {
        this.isGeneratingQR = false;
      }
    },
    connectWebSocket() {
      // Đóng kết nối WebSocket cũ nếu có
      if (this.socket) {
        this.socket.close();
      }
      // Xác định URL WebSocket dựa trên URL hiện tại
      // const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
      const wsUrl = `${window.shopizConfig?.zaloApiUrl.replace('http', 'ws')}/ws`;
      console.log('Đang kết nối đến WebSocket tại:', wsUrl);
      try {
        this.socket = new WebSocket(wsUrl);
        this.socket.onopen = function () {
          console.log('WebSocket đã kết nối');
          this.hasError = false;
          this.emptyStateMessage =
            'Kết nối WebSocket thành công. Vui lòng quét mã QR để đăng nhập.';
        }.bind(this);
        this.socket.onmessage = function (event) {
          console.log('Nhận tin nhắn WebSocket:', event.data);
          if (event.data.indexOf('login_success:') === 0) {
            console.log('Đăng nhập thành công qua WebSocket', event);
            this.emptyStateMessage =
              'Đăng nhập thành công. Đang tải danh sách hội thoại';
            this.hasLoginStarted = true;
            this.hasError = false;
            this.oa_id = event.data.split(':')[1];
            this.access_token = this.oa_id;
            this.refresh_token = this.oa_id;
            this.expires_in = 90000;
            console.log('oa_id:', this.oa_id);
          }
        }.bind(this);

        this.socket.onerror = function (error) {
          console.error('Lỗi WebSocket:', error);
          this.hasError = true;
          this.errorStateMessage = 'Lỗi kết nối WebSocket.Thử kết nối lại.';
        }.bind(this);

        this.socket.onclose = function () {
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
    reloadPage() {
      window.location.reload();
    },
  },
};
</script>

<template>
  <div class="wizard-body w-full flex-shrink-0 flex-grow-0">
    <div
      v-if="!hasLoginStarted"
      class="flex flex-col login-init items-center justify-center pt-6"
    >
      <div class="w-full text-center">
        <p class="font-bold mb-0 text-lg">
          {{ $t('INBOX_MGMT.ADD.ZALO_PERSONAL.DESC') }}
          <span class="text-n-orange">Zalo</span>
        </p>
        <p class="font-bold text-lg">
          {{ $t('INBOX_MGMT.ADD.ZALO_PERSONAL.DESC_2') }}
          <span class="text-n-orange">Shopiz</span>
        </p>
      </div>
      <div class="w-[300px] h-[300px] mt-4 border border-n-weak rounded-md shadow-sm flex items-center justify-center bg-n-alpha-1 overflow-hidden">
        <img
          v-if="qrCode && !isGeneratingQR"
          :src="qrCode"
          alt="Zalo-Login-QR"
          class="w-full h-full object-contain"
        />
        <div v-else-if="isGeneratingQR" class="flex flex-col items-center gap-2 text-n-slate-11">
          <span class="i-lucide-loader-2 animate-spin text-2xl" />
          <span class="text-sm">{{ $t('INBOX_MGMT.ADD.ZALO_PERSONAL.GENERATING_QR') }}</span>
        </div>
        <div v-else class="flex flex-col items-center gap-2 text-n-slate-11 px-4">
          <span class="i-lucide-qr-code text-4xl opacity-30" />
          <span class="text-sm text-center">{{ $t('INBOX_MGMT.ADD.ZALO_PERSONAL.QR_PLACEHOLDER') }}</span>
        </div>
      </div>

      <div class="mt-4 flex flex-col items-center w-full max-w-xs">
        <label class="w-full">
          <span class="text-sm font-medium text-n-slate-12">{{ $t('INBOX_MGMT.ADD.ZALO_PERSONAL.CUSTOM_PROXY') }}</span>
          <input
            v-model="proxyUrl"
            type="text"
            :placeholder="$t('INBOX_MGMT.ADD.ZALO_PERSONAL.CUSTOM_PROXY_PLACEHOLDER')"
            class="w-full mt-1"
            @keyup.enter="generateQR"
          />
        </label>
        <button class="button w-full mt-2 py-3 bg-n-orange hover:bg-n-orange/90 text-white" :disabled="isGeneratingQR" @click="generateQR">
          {{ isGeneratingQR ? $t('INBOX_MGMT.ADD.ZALO_PERSONAL.GENERATING_QR') : $t('INBOX_MGMT.ADD.ZALO_PERSONAL.GENERATE_QR') }}
        </button>
        <p v-if="proxyUsed" class="text-xs text-n-slate-11 mt-2 text-center">
          {{ $t('INBOX_MGMT.ADD.ZALO_PERSONAL.PROXY_USED') }} <span class="font-medium text-n-slate-12">{{ proxyUsed }}</span>
        </p>
      </div>
      <div class="mt-6 text-n-slate-11 text-center">
        <p class="mb-1">{{ $t('INBOX_MGMT.ADD.ZALO_PERSONAL.HELP') }}</p>
        <p class="mb-0">{{ $t('INBOX_MGMT.ADD.ZALO_PERSONAL.HELP_2') }}</p>
      </div>
    </div>
    <div v-else class="pt-6">
      <div v-if="hasError" class="max-w-lg">
        <h5>{{ errorStateMessage }}</h5>
        <p
          v-if="errorStateDescription"
          v-dompurify-html="errorStateDescription"
        />
      </div>
      <LoadingState v-else-if="showLoader" :message="emptyStateMessage" />
      <div v-else class="text-center">
        <p v-dompurify-html="successStateDescription" />
        <button class="button mt-4" @click="reloadPage">
          {{ $t('INBOX_MGMT.GO_TO_CONFIGURATION') }}
        </button>
      </div>
    </div>
  </div>
</template>
