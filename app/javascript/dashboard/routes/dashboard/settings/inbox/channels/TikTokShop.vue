<script>
/* eslint-env browser */
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';
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
    return {
      v$: useVuelidate(),
    };
  },
  data() {
    return {
      isCreating: false,
      hasError: false,
      omniauth_token: '',
      access_token: '',
      initial_account_id: '',
      refresh_token: '',
      expires_in: '',
      shopName: '',
      avatar: '',
      channel: 'tiktok_shop',
      emptyStateMessage: this.$t('INBOX_MGMT.DETAILS.LOADING_TIKTOK_SHOP'),
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
      return this.isCreating;
    },
  },
  created() {
    this.tiktokSessionId = this.$route.query.tiktok_session_id;
    this.shopName = this.$route.query.shop_name;
    this.initial_account_id = this.$route.params.accountId;
    if (this.shopName) this.hasLoginStarted = true;
  },
  methods: {
    startLogin() {
      this.hasLoginStarted = true;
      window.location.replace(
        'https://services.tiktokshop.com/open/authorize?service_id=' +
          window.flowifyConfig.tiktokShopAppId +
          '&state=' +
          encodeURIComponent(this.initial_account_id)
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
          .dispatch('inboxes/createTiktokShopChannel', this.channelParams())
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
  <div class="h-full p-6 w-full max-w-full flex-shrink-0 flex-grow-0">
    <div
      v-if="!hasLoginStarted"
      class="flex flex-col items-center justify-start mt-20 h-full text-center"
    >
      <h6 class="text-2xl font-medium">
        {{ $t('INBOX_MGMT.ADD.TIKTOK_SHOP.CONNECT_TIKTOK_SHOP') }}
      </h6>
      <p class="py-6 text-sm text-n-slate-11">
        {{ $t('INBOX_MGMT.ADD.TIKTOK_SHOP.HELP') }}
      </p>
      <Button
        class="text-white !rounded-full !px-6 bg-gradient-to-r from-[#00f2ea] via-[#ff0050] to-[#000000]"
        lg
        icon="i-woot-tiktok-shop"
        :label="$t('INBOX_MGMT.ADD.TIKTOK_SHOP.CONTINUE_WITH_TIKTOK_SHOP')"
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
      <LoadingState v-if="showLoader" :message="emptyStateMessage" />
      <form
        v-else
        class="mx-0 flex flex-wrap p-5"
        @submit.prevent="createChannel()"
      >
        <div class="w-full">
          <PageHeader
            :header-title="$t('INBOX_MGMT.DETAILS.TITLE')"
            :header-content="$t('INBOX_MGMT.DETAILS.DESC_TIKTOK_SHOP')"
          />
        </div>
        <div class="w-[60%]">
          <div class="w-full">
            <label :class="{ error: v$.shopName.$error }">
              {{ $t('INBOX_MGMT.ADD.TIKTOK_SHOP.INBOX_NAME') }}
              <input
                v-model.trim="shopName"
                type="text"
                :placeholder="$t('INBOX_MGMT.ADD.TIKTOK_SHOP.PICK_NAME')"
                @input="v$.shopName.$touch"
              />
              <span v-if="v$.shopName.$error" class="message">
                {{ $t('INBOX_MGMT.ADD.TIKTOK_SHOP.ADD_NAME') }}
              </span>
            </label>
          </div>
          <div class="w-full text-right">
            <input
              type="submit"
              :value="$t('INBOX_MGMT.ADD.TIKTOK_SHOP.CREATE_INBOX')"
              class="button"
            />
          </div>
        </div>
      </form>
    </div>
  </div>
</template>
