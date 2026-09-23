<script>
import { useAlert } from 'dashboard/composables';
import inboxMixin from 'shared/mixins/inboxMixin';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import SettingsAccordion from 'dashboard/components-next/Settings/SettingsAccordion.vue';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import NextButton from 'dashboard/components-next/button/Button.vue';
import TextArea from 'next/textarea/TextArea.vue';
import WhatsappReauthorize from '../channels/whatsapp/Reauthorize.vue';
import { sanitizeAllowedDomains } from 'dashboard/helper/URLHelper';
import MultiSelect from 'dashboard/components-next/filter/inputs/MultiSelect.vue';

export default {
  components: {
    SettingsFieldSection,
    SettingsToggleSection,
    SettingsAccordion,
    NextButton,
    TextArea,
    WhatsappReauthorize,
    MultiSelect,
  },
  mixins: [inboxMixin],
  props: {
    inbox: {
      type: Object,
      default: () => ({}),
    },
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      hmacMandatory: false,
      allowMobileWebview: false,
      whatsAppInboxAPIKey: '',
      isRequestingReauthorization: false,
      allowedDomains: '',
      isUpdatingAllowedDomains: false,
      isSettingDefaults: false,
      zaloAutoMessageEnabled: false,
      zaloAutoMessageInboxes: [],
    };
  },
  validations: {
    whatsAppInboxAPIKey: { required },
  },
  computed: {
    isEmbeddedSignupWhatsApp() {
      return this.inbox.provider_config?.source === 'embedded_signup';
    },
    whatsappAppId() {
      return window.shopizConfig?.whatsappAppId;
    },
    allInboxes() {
      return this.$store.getters['inboxes/getInboxes'];
    },
    zaloPersonalInboxes() {
      return this.allInboxes
        .filter(i => i.channel_type === 'Channel::ZaloPersonal')
        .map(i => ({ id: i.id, name: i.name }));
    },
  },
  watch: {
    inbox() {
      this.setDefaults();
    },
    allowMobileWebview() {
      if (!this.isSettingDefaults) this.handleMobileWebviewFlag();
    },
    hmacMandatory() {
      if (!this.isSettingDefaults && this.isAWebWidgetInbox)
        this.handleHmacFlag();
    },
    zaloAutoMessageEnabled() {
      if (!this.isSettingDefaults && !this.isAZaloPersonalChannel)
        this.handleZaloAutoMessageConfig();
    },
    zaloAutoMessageInboxes() {
      if (!this.isSettingDefaults && !this.isAZaloPersonalChannel)
        this.handleZaloAutoMessageConfig();
    },
  },
  mounted() {
    this.setDefaults();
  },
  methods: {
    setDefaults() {
      this.isSettingDefaults = true;
      this.hmacMandatory = this.inbox.hmac_mandatory || false;
      this.allowMobileWebview = (
        this.inbox.selected_feature_flags || []
      ).includes('allow_mobile_webview');
      this.allowedDomains = this.inbox.allowed_domains || '';

      const zaloConfig = this.inbox.zalo_auto_message_config || {};
      this.zaloAutoMessageEnabled =
        zaloConfig.zalo_auto_message_enabled || false;
      const zaloIds = zaloConfig.zalo_auto_message_inbox_ids || [];
      const newZaloInboxes = this.zaloPersonalInboxes.filter(i =>
        zaloIds.includes(i.id)
      );
      const currentIds = this.zaloAutoMessageInboxes
        .map(i => i.id)
        .sort()
        .join(',');
      const nextIds = newZaloInboxes
        .map(i => i.id)
        .sort()
        .join(',');
      if (currentIds !== nextIds) {
        this.zaloAutoMessageInboxes = newZaloInboxes;
      }

      this.$nextTick(() => {
        this.isSettingDefaults = false;
      });
    },
    handleHmacFlag() {
      this.updateInbox();
    },
    async updateInbox() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            hmac_mandatory: this.hmacMandatory,
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    async handleMobileWebviewFlag() {
      try {
        const currentFlags = this.inbox.selected_feature_flags || [];
        const selectedFlags = this.allowMobileWebview
          ? [...currentFlags, 'allow_mobile_webview']
          : currentFlags.filter(f => f !== 'allow_mobile_webview');

        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            selected_feature_flags: selectedFlags,
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    async updateAllowedDomains() {
      this.isUpdatingAllowedDomains = true;
      const sanitizedAllowedDomains = sanitizeAllowedDomains(
        this.allowedDomains
      );
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {
            allowed_domains: sanitizedAllowedDomains,
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        this.allowedDomains = sanitizedAllowedDomains;
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      } finally {
        this.isUpdatingAllowedDomains = false;
      }
    },
    async updateWhatsAppInboxAPIKey() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          channel: {},
        };

        payload.channel.provider_config = {
          ...this.inbox.provider_config,
          api_key: this.whatsAppInboxAPIKey,
        };

        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    async handleReconfigure() {
      if (this.$refs.whatsappReauth) {
        await this.$refs.whatsappReauth.requestAuthorization();
      }
    },
    async handleZaloAutoMessageConfig() {
      try {
        const payload = {
          id: this.inbox.id,
          formData: false,
          zalo_auto_message_config: {
            zalo_auto_message_enabled: this.zaloAutoMessageEnabled,
            zalo_auto_message_inbox_ids: this.zaloAutoMessageInboxes.map(
              i => i.id
            ),
          },
        };
        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<template>
  <div v-if="isATwilioChannel">
    <SettingsFieldSection
      :label="$t('INBOX_MGMT.ADD.TWILIO.API_CALLBACK.TITLE')"
      :help-text="$t('INBOX_MGMT.ADD.TWILIO.API_CALLBACK.SUBTITLE')"
    >
      <woot-code :script="inbox.callback_webhook_url" lang="html" />
    </SettingsFieldSection>
  </div>
  <div v-else-if="isAVoiceChannel">
    <SettingsFieldSection
      :label="$t('INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_VOICE_URL_TITLE')"
      :help-text="
        $t('INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_VOICE_URL_SUBTITLE')
      "
    >
      <woot-code :script="inbox.voice_call_webhook_url" lang="html" />
    </SettingsFieldSection>
    <SettingsFieldSection
      :label="$t('INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_STATUS_URL_TITLE')"
      :help-text="
        $t('INBOX_MGMT.ADD.VOICE.CONFIGURATION.TWILIO_STATUS_URL_SUBTITLE')
      "
    >
      <woot-code :script="inbox.voice_status_webhook_url" lang="html" />
    </SettingsFieldSection>
  </div>

  <div v-else-if="isALineChannel">
    <SettingsFieldSection
      :label="$t('INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.TITLE')"
      :help-text="$t('INBOX_MGMT.ADD.LINE_CHANNEL.API_CALLBACK.SUBTITLE')"
    >
      <woot-code :script="inbox.callback_webhook_url" lang="html" />
    </SettingsFieldSection>
  </div>
  <div v-else-if="isAZaloPersonalChannel">
    <SettingsFieldSection
      :label="$t('INBOX_MGMT.SETTINGS_POPUP.PROXY_CONFIGURATION.TITLE')"
      :help-text="$t('INBOX_MGMT.SETTINGS_POPUP.PROXY_CONFIGURATION.SUBTITLE')"
    >
      <woot-code
        :script="
          inbox.provider_config?.proxy_used ||
          $t('INBOX_MGMT.SETTINGS_POPUP.PROXY_CONFIGURATION.NO_PROXY')
        "
        lang="text"
      />
      <p class="mt-2 text-sm text-n-slate-11">
        {{ $t('INBOX_MGMT.SETTINGS_POPUP.PROXY_CONFIGURATION.HELP') }}
      </p>
    </SettingsFieldSection>
  </div>
  <div v-else-if="isAWebWidgetInbox">
    <div class="space-y-4">
      <SettingsToggleSection
        :header="$t('INBOX_MGMT.SETTINGS_POPUP.ALLOWED_DOMAINS.TITLE')"
        :description="
          $t('INBOX_MGMT.SETTINGS_POPUP.ALLOWED_DOMAINS.DESCRIPTION')
        "
        hide-toggle
      >
        <template #editor>
          <TextArea
            v-model="allowedDomains"
            :placeholder="
              $t('INBOX_MGMT.SETTINGS_POPUP.ALLOWED_DOMAINS.PLACEHOLDER')
            "
            auto-height
            resize
            class="w-full [&>div]:!bg-transparent [&>div]:!border-none [&>div]:!border-0 [&>div]:px-0 [&>div]:pb-0 [&>div]:pt-0"
          />
          <div class="mt-3 flex justify-end">
            <NextButton
              :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
              :is-loading="isUpdatingAllowedDomains"
              @click="updateAllowedDomains"
            />
          </div>
        </template>
      </SettingsToggleSection>
      <SettingsToggleSection
        v-model="allowMobileWebview"
        :header="$t('INBOX_MGMT.SETTINGS_POPUP.ALLOW_MOBILE_WEBVIEW.LABEL')"
        :description="
          $t('INBOX_MGMT.SETTINGS_POPUP.ALLOW_MOBILE_WEBVIEW.SUBTITLE')
        "
      />
    </div>

    <SettingsAccordion
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.TITLE')"
      class="mt-6"
    >
      <SettingsToggleSection
        :header="$t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.TITLE')"
        :description="
          $t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.DESCRIPTION')
        "
        hide-toggle
      >
        <template #editor>
          <p class="mb-1 text-sm font-medium text-n-slate-12">
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.SECRET_KEY') }}
          </p>
          <woot-code :script="inbox.hmac_token" />
          <p class="mt-1.5 text-label-small text-n-slate-11">
            {{ $t('INBOX_MGMT.SETTINGS_POPUP.HMAC_DESCRIPTION') }}
            <a
              target="_blank"
              rel="noopener noreferrer"
              href="https://www.shopiz.pro/docs/product/channels/live-chat/sdk/identity-validation/"
              class="text-n-orange-11 hover:underline text-label-small"
            >
              {{
                $t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.VIEW_DOCS')
              }}
            </a>
          </p>
        </template>
      </SettingsToggleSection>

      <SettingsToggleSection
        v-model="hmacMandatory"
        :header="
          $t('INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.REQUIRE_LABEL')
        "
        :description="
          $t(
            'INBOX_MGMT.SETTINGS_POPUP.IDENTITY_VALIDATION.REQUIRE_DESCRIPTION'
          )
        "
      />
    </SettingsAccordion>
  </div>
  <div v-else-if="isAPIInbox">
    <SettingsFieldSection
      :label="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_IDENTIFIER')"
      :help-text="$t('INBOX_MGMT.SETTINGS_POPUP.INBOX_IDENTIFIER_SUB_TEXT')"
    >
      <woot-code :script="inbox.inbox_identifier" />
    </SettingsFieldSection>

    <SettingsFieldSection
      :label="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_VERIFICATION')"
      :help-text="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_DESCRIPTION')"
    >
      <woot-code :script="inbox.hmac_token" />
    </SettingsFieldSection>
    <SettingsFieldSection
      :label="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_VERIFICATION')"
      :help-text="$t('INBOX_MGMT.SETTINGS_POPUP.HMAC_MANDATORY_DESCRIPTION')"
    >
      <div class="flex gap-2 items-center">
        <input
          id="hmacMandatory"
          v-model="hmacMandatory"
          type="checkbox"
          @change="handleHmacFlag"
        />
        <label for="hmacMandatory" class="text-body-main text-n-slate-12">
          {{ $t('INBOX_MGMT.EDIT.ENABLE_HMAC.LABEL') }}
        </label>
      </div>
    </SettingsFieldSection>
  </div>
  <div v-else-if="isAWhatsAppChannel && !isATwilioChannel">
    <div v-if="inbox.provider_config">
      <!-- Embedded Signup Section -->
      <template v-if="isEmbeddedSignupWhatsApp">
        <SettingsFieldSection
          v-if="whatsappAppId"
          :label="
            $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_EMBEDDED_SIGNUP_TITLE')
          "
          :help-text="`${$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_EMBEDDED_SIGNUP_SUBHEADER')} ${$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_EMBEDDED_SIGNUP_DESCRIPTION')}`"
        >
          <div class="flex flex-col gap-1 items-start">
            <NextButton @click="handleReconfigure">
              {{ $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_RECONFIGURE_BUTTON') }}
            </NextButton>
          </div>
        </SettingsFieldSection>
      </template>

      <!-- Manual Setup Section -->
      <template v-else>
        <SettingsFieldSection
          :label="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEBHOOK_TITLE')"
          :help-text="
            $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_WEBHOOK_SUBHEADER')
          "
        >
          <woot-code :script="inbox.provider_config.webhook_verify_token" />
        </SettingsFieldSection>
        <SettingsFieldSection
          :label="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_TITLE')"
          :help-text="
            $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_SUBHEADER')
          "
        >
          <woot-code :script="inbox.provider_config.api_key" />
        </SettingsFieldSection>
        <SettingsFieldSection
          :label="$t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_TITLE')"
          :help-text="
            $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_SUBHEADER')
          "
        >
          <div
            class="flex flex-1 justify-between items-center whatsapp-settings--content"
          >
            <woot-input
              v-model="whatsAppInboxAPIKey"
              type="text"
              class="flex-1 mr-2 [&_input]:!mb-0"
              :placeholder="
                $t(
                  'INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_PLACEHOLDER'
                )
              "
            />
            <NextButton
              :disabled="v$.whatsAppInboxAPIKey.$invalid"
              @click="updateWhatsAppInboxAPIKey"
            >
              {{
                $t('INBOX_MGMT.SETTINGS_POPUP.WHATSAPP_SECTION_UPDATE_BUTTON')
              }}
            </NextButton>
          </div>
        </SettingsFieldSection>
      </template>
    </div>
    <WhatsappReauthorize
      v-if="isEmbeddedSignupWhatsApp"
      ref="whatsappReauth"
      :inbox="inbox"
      class="hidden"
    />
  </div>

  <div v-if="!isAZaloPersonalChannel" class="mt-4">
    <SettingsAccordion
      :title="$t('INBOX_MGMT.SETTINGS_POPUP.ZALO_AUTO_MESSAGE.TITLE')"
      class="mt-6"
    >
      <div class="space-y-4">
        <SettingsToggleSection
          v-model="zaloAutoMessageEnabled"
          :header="$t('INBOX_MGMT.SETTINGS_POPUP.ZALO_AUTO_MESSAGE.ENABLE')"
          :description="
            $t('INBOX_MGMT.SETTINGS_POPUP.ZALO_AUTO_MESSAGE.ENABLE_DESC')
          "
          :disabled="zaloPersonalInboxes.length === 0"
        />

        <SettingsToggleSection
          :header="
            $t('INBOX_MGMT.SETTINGS_POPUP.ZALO_AUTO_MESSAGE.SELECT_INBOX')
          "
          :description="
            $t('INBOX_MGMT.SETTINGS_POPUP.ZALO_AUTO_MESSAGE.SELECT_INBOX_DESC')
          "
          hide-toggle
        >
          <template #editor>
            <MultiSelect
              v-model="zaloAutoMessageInboxes"
              :options="zaloPersonalInboxes"
              :max-chips="10"
              class="w-full mt-2"
              :disabled="zaloPersonalInboxes.length === 0"
            />
          </template>
        </SettingsToggleSection>
      </div>
    </SettingsAccordion>
  </div>
</template>

<style lang="scss" scoped>
.whatsapp-settings--content {
  ::v-deep input {
    margin-bottom: 0;
  }
}
</style>
