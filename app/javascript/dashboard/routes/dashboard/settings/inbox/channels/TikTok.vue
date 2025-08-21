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
      isCreating: false,
      hasError: false,
      omniauth_token: '',
      access_token: '',
      refresh_token: '',
      expires_in: '',
      shopName: '',
      avatar: '',
      channel: 'tiktok',
      emptyStateMessage: this.$t('INBOX_MGMT.DETAILS.LOADING_TIKTOK'),
      errorStateMessage: '',
      errorStateDescription: '',
      hasLoginStarted: false,
    };
  },
  validations: {
    shopName: {
      required,
    },
  },
  computed: {
    showLoader() {
      return this.shopName === '' || this.isCreating;
    },
    ...mapGetters({
      globalConfig: 'globalConfig/get',
    }),
  },
  created() {
    this.tiktokSessionId = this.$route.query.tiktok_session_id;
    this.shopName = this.$route.query.shop_name;
    if (this.shopName) this.hasLoginStarted = true;
  },
  methods: {
    startLogin() {
      this.hasLoginStarted = true;
      window.location.replace(
        'https://auth.tiktok-shops.com/oauth/authorize?app_key=' +
          window.salesmanConfig.tiktokAppId +
          '&redirect_uri=' +
          window.salesmanConfig.hostURL +
          '/tiktok/callback&state=' +
          encodeURIComponent(this.accountId)
      );
    },
    channelParams() {
      return {
        tiktok_session_id: this.tiktokSessionId,
        shop_name: this.shopName,
      };
    },
    createChannel() {
      this.v$.$touch();
      if (!this.v$.$error) {
        this.emptyStateMessage = this.$t('INBOX_MGMT.DETAILS.CREATING_CHANNEL');
        this.isCreating = true;
        this.$store
          .dispatch('inboxes/createTiktokChannel', this.channelParams())
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
      <a href="#" @click="startLogin()">
        <img
          src="~dashboard/assets/images/channels/tiktok_login.png"
          alt="Tiktok-logo"
        />
      </a>
      <p>
        {{
          useInstallationName(
            $t('INBOX_MGMT.ADD.TIKTOK.HELP'),
            globalConfig.installationName
          )
        }}
      </p>
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
            :header-title="$t('INBOX_MGMT.DETAILS.TITLE')"
            :header-content="
              useInstallationName(
                $t('INBOX_MGMT.DETAILS.DESC_TIKTOK'),
                globalConfig.installationName
              )
            "
          />
        </div>
        <div class="w-[60%]">
          <div class="w-full">
            <label :class="{ error: v$.shopName.$error }">
              {{ $t('INBOX_MGMT.ADD.TIKTOK.INBOX_NAME') }}
              <input
                v-model.trim="shopName"
                type="text"
                :placeholder="$t('INBOX_MGMT.ADD.TIKTOK.PICK_NAME')"
                @input="v$.shopName.$touch"
              />
              <span v-if="v$.shopName.$error" class="message">
                {{ $t('INBOX_MGMT.ADD.TIKTOK.ADD_NAME') }}
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
