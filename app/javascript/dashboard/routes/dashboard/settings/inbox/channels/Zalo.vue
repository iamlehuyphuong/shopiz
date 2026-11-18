<script>
/* eslint-env browser */
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import axios from 'axios';
import ZaloChannel from 'dashboard/api/channel/zaloChannel';
import PageHeader from '../../SettingsSubPageHeader.vue';
import router from '../../../../index';
import Button from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    LoadingState,
    PageHeader,
    Button,
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
      isCreating: false,
      hasError: false,
      omniauth_token: '',
      access_token: '',
      refresh_token: '',
      expires_in: '',
      oa_id: '',
      pageName: '',
      avatar: '',
      channel: 'zalo',
      emptyStateMessage: this.$t('INBOX_MGMT.ADD.ZALO_OA.LOADING'),
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
  },
  created() {
    if (this.$route.query.code) this.getAccessToken();
  },
  methods: {
    startLogin() {
      this.hasLoginStarted = true;
      window.location.replace(
        'https://oauth.zaloapp.com/v4/oa/permission?app_id=' +
          window.shopizConfig.zaloAppId +
          '&redirect_uri=' +
          encodeURIComponent(window.shopizConfig.hostURL + '/zalo/callback') +
          '&state=' +
          encodeURIComponent(this.accountId)
      );
    },
    getAccessToken() {
      this.hasLoginStarted = true;
      ZaloChannel.exchangeToken(this.$route.query.code)
        .then(response => {
          // if (!response.data.error) {
          this.access_token = response.data.access_token;
          this.refresh_token = response.data.refresh_token;
          this.expires_in = response.data.expires_in;
          this.fetchOaData(this.access_token);
          // } else {
          //  this.hasError = true;
          //  this.errorStateMessage = response.data.error_name;
          //  this.errorStateDescription = response.data.error_description;
          // }
        })
        .catch(error => {
          this.hasError = true;
          this.errorStateMessage = error.message;
        });
    },
    fetchOaData(access_token) {
      const url = 'https://openapi.zalo.me/v2.0/oa/getoa';
      axios
        .get(url, {
          headers: {
            access_token: access_token,
          },
        })
        .then(response => {
          const data = response.data;
          if (data.error === 0) {
            this.oa_id = data.data.oa_id;
            this.pageName = data.data.name;
            this.avatar = data.data.avatar;
          } else {
            this.hasError = true;
            this.errorStateMessage = data.message;
          }
        })
        .catch(error => {
          this.hasError = true;
          this.errorStateMessage = error.message;
        });
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
          .dispatch('inboxes/createZaloChannel', this.channelParams())
          .then(data => {
            router.replace({
              name: 'settings_inboxes_add_agents',
              params: { page: 'new', inbox_id: data.id },
            });
          })
          .catch(error => {
            this.isCreating = false;
            useAlert(error.message);
          });
      }
    },
  },
};
</script>

<template>
  <div class="h-full p-6 w-full max-w-full flex-shrink-0 flex-grow-0">
    <div
      v-if="!hasLoginStarted"
      class="flex flex-col items-center justify-start mt-20 h-full text-center"
    >
      <h6 class="text-2xl font-medium">
        {{ $t('INBOX_MGMT.ADD.ZALO_OA.CONNECT_ZALO_OA') }}
      </h6>
      <p class="py-6 text-sm text-n-slate-11">
        {{ $t('INBOX_MGMT.ADD.ZALO_OA.HELP') }}
        {{ $t('INBOX_MGMT.ADD.ZALO_OA.HELP_2') }}
      </p>
      <Button
        class="text-white !rounded-full !px-6 bg-gradient-to-r from-[#0068FF] to-[#004BBF]"
        lg
        icon="i-woot-zalo-oa"
        :label="$t('INBOX_MGMT.ADD.ZALO_OA.CONTINUE_WITH_ZALO_OA')"
        @click="startLogin()"
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
        class="mx-0 flex flex-wrap p-5"
        @submit.prevent="createChannel()"
      >
        <div class="w-full">
          <PageHeader
            :header-title="$t('INBOX_MGMT.ADD.ZALO_OA.TITLE')"
            :header-content="$t('INBOX_MGMT.ADD.ZALO_OA.TITLE')"
          />
        </div>
        <div class="w-[60%]">
          <div class="w-full">
            <label :class="{ error: v$.pageName.$error }">
              {{ $t('INBOX_MGMT.ADD.ZALO_OA.INBOX_NAME') }}
              <input
                v-model.trim="pageName"
                type="text"
                :placeholder="$t('INBOX_MGMT.ADD.ZALO_OA.PICK_NAME')"
                @input="v$.pageName.$touch"
              />
              <span v-if="v$.pageName.$error" class="message">
                {{ $t('INBOX_MGMT.ADD.ZALO_OA.ADD_NAME') }}
              </span>
            </label>
          </div>
          <div class="w-full text-right">
            <input
              type="submit"
              :value="$t('INBOX_MGMT.ADD.ZALO_OA.CREATE_INBOX')"
              class="button"
            />
          </div>
        </div>
      </form>
    </div>
  </div>
</template>
