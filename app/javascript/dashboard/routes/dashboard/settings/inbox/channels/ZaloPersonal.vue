<script>
/* eslint-env browser */
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { mapGetters } from 'vuex';
import axios from 'axios';
import PageHeader from '../../SettingsSubPageHeader.vue';
import router from '../../../../index';
import globalConfigMixin from 'shared/mixins/globalConfigMixin';

// import accountMixin from '../../../../../mixins/account';
export default {
  components: {
    LoadingState,
    PageHeader,
  },
  mixins: [globalConfigMixin],
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
      emptyStateMessage: this.$t('INBOX_MGMT.ADD.ZALO.LOADING'),
      errorStateMessage: '',
      errorStateDescription: '',
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
    channelParams() {
      return {
        oa_id: this.oa_id,
        access_token: this.access_token,
        refresh_token: this.refresh_token,
        expires_in: this.expires_in,
        inbox_name: this.pageName,
        avatar_url: this.avatar,
      };
    },
    createChannel() {
      this.v$.$touch();
      if (!this.v$.$error) {
        this.emptyStateMessage = this.$t('INBOX_MGMT.DETAILS.CREATING_CHANNEL');
        this.isCreating = true;
        this.$store
          .dispatch('inboxes/createZaloPersonalChannel', this.channelParams())
          .then(data => {
            router.replace({
              name: 'settings_inboxes_add_agents',
              params: { page: 'new', inbox_id: data.id },
            });
          })
          .catch(() => {
            this.isCreating = false;
          });
      }
    },
  },
};
</script>

<template>
  <div class="wizard-body w-[75%] flex-shrink-0 flex-grow-0 max-w-[75%]">
    <div v-if="!hasLoginStarted" class="login-init h-full">
      <img
        v-if="qrCode"
        :src="qrCode"
        alt="Zalo-Login-QR"
      />
    </div>
    <div v-else>
      <div v-if="hasError" class="max-w-lg mx-auto text-center">
        <h5>{{ errorStateMessage }}</h5>
        <p
          v-if="errorStateDescription"
          v-dompurify-html="errorStateDescription"
        />
      </div>
      <LoadingState v-else-if="showLoader" :message="emptyStateMessage" />
      <form
        v-else
        class="mx-0 flex flex-wrap"
        @submit.prevent="createChannel()"
      >
        <div class="w-full">
          <PageHeader
            :header-title="$t('INBOX_MGMT.ADD.ZALO.TITLE')"
            :header-content="
              useInstallationName(
                $t('INBOX_MGMT.ADD.ZALO.TITLE'),
                globalConfig.installationName
              )
            "
          />
        </div>
        <div class="w-[60%]">
          <div class="w-full">
            <label :class="{ error: v$.pageName.$error }">
              {{ $t('INBOX_MGMT.ADD.ZALO.INBOX_NAME') }}
              <input
                v-model.trim="pageName"
                type="text"
                :placeholder="$t('INBOX_MGMT.ADD.ZALO.PICK_NAME')"
                @input="v$.pageName.$touch"
              />
              <span v-if="v$.pageName.$error" class="message">
                {{ $t('INBOX_MGMT.ADD.ZALO.ADD_NAME') }}
              </span>
            </label>
          </div>
          <div class="w-full text-right">
            <input type="submit" value="Create Inbox" class="button" />
          </div>
        </div>
      </form>
    </div>
  </div>
</template>
