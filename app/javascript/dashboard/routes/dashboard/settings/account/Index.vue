<script>
import { useVuelidate } from '@vuelidate/core';
import { required, email } from '@vuelidate/validators';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useConfig } from 'dashboard/composables/useConfig';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { FEATURE_FLAGS } from '../../../../featureFlags';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextInput from 'next/input/Input.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import AccountId from './components/AccountId.vue';
import BuildInfo from './components/BuildInfo.vue';
import AccountDelete from './components/AccountDelete.vue';
import AudioTranscription from './components/AudioTranscription.vue';
import SectionLayout from './components/SectionLayout.vue';
import NextSwitch from 'dashboard/components-next/switch/Switch.vue';
import SmtpSettings from './components/SmtpSettings.vue';

export default {
  components: {
    BaseSettingsHeader,
    NextButton,
    AccountId,
    BuildInfo,
    AccountDelete,
    AudioTranscription,
    SectionLayout,
    WithLabel,
    NextInput,
    NextSwitch,
    SmtpSettings,
  },
  setup() {
    const { updateUISettings, uiSettings } = useUISettings();
    const { enabledLanguages } = useConfig();
    const { accountId } = useAccount();
    const { isAdmin } = useAdmin();
    const v$ = useVuelidate();

    return {
      updateUISettings,
      uiSettings,
      v$,
      enabledLanguages,
      accountId,
      isAdmin,
    };
  },
  data() {
    return {
      id: '',
      name: '',
      locale: window.navigator?.language?.startsWith('vi') ? 'vi' : 'en',
      domain: '',
      supportEmail: '',
      features: {},
      customEmailConfig: {},
      typeId: 'personal',
      idNumber: '',
      address: '',
      companyName: '',
      companyAddress: '',
      companyEmail: '',
      companyTaxId: '',
    };
  },
  validations: {
    name: {
      required,
    },
    locale: {
      required,
    },
    companyEmail: {
      email,
    },
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      uiFlags: 'accounts/getUIFlags',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
      isOnChatwootCloud: 'globalConfig/isOnChatwootCloud',
    }),
    showAudioTranscriptionConfig() {
      return this.isFeatureEnabledonAccount(
        this.accountId,
        FEATURE_FLAGS.CAPTAIN
      );
    },
    languagesSortedByCode() {
      const enabledLanguages = [...this.enabledLanguages];
      return enabledLanguages.sort((l1, l2) =>
        l1.iso_639_1_code.localeCompare(l2.iso_639_1_code)
      );
    },
    isUpdating() {
      return this.uiFlags.isUpdating;
    },
    featureInboundEmailEnabled() {
      return !!this.features?.inbound_emails;
    },
    featureCustomReplyDomainEnabled() {
      return (
        this.featureInboundEmailEnabled && !!this.features.custom_reply_domain
      );
    },
    featureCustomReplyEmailEnabled() {
      return (
        this.featureInboundEmailEnabled && !!this.features.custom_reply_email
      );
    },
    currentAccount() {
      return this.getAccount(this.accountId) || {};
    },
    isVietnamese: {
      get() {
        return this.locale === 'vi';
      },
      set(value) {
        this.locale = value ? 'vi' : 'en';
      },
    },
    isCompany: {
      get() {
        return this.typeId === 'company';
      },
      set(value) {
        this.typeId = value ? 'company' : 'personal';
      },
    },
  },
  mounted() {
    this.initializeAccount();
  },
  methods: {
    async initializeAccount() {
      try {
        const {
          name,
          locale,
          id,
          domain,
          support_email,
          features,
          settings,
          type_id,
          id_number,
          address,
          company_name,
          company_address,
          company_email,
          company_tax_id,
        } = this.getAccount(this.accountId);

        this.$root.$i18n.locale = this.uiSettings?.locale || locale;
        this.name = name;
        this.locale = locale;
        this.id = id;
        this.domain = domain;
        this.supportEmail = support_email;
        this.features = features;
        this.customEmailConfig = settings?.custom_email_config || {};
        this.typeId = type_id || 'personal';
        this.idNumber = id_number || '';
        this.address = address || '';
        this.companyName = company_name || '';
        this.companyAddress = company_address || '';
        this.companyEmail = company_email || '';
        this.companyTaxId = company_tax_id || '';
      } catch (error) {
        // Ignore error
      }
    },

    async updateAccount() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        useAlert(this.$t('GENERAL_SETTINGS.FORM.ERROR'));
        return;
      }
      try {
        await this.$store.dispatch('accounts/update', {
          locale: this.locale,
          name: this.name,
          domain: this.domain,
          support_email: this.supportEmail,
          type_id: this.typeId,
          id_number: this.idNumber,
          address: this.address,
          company_name: this.companyName,
          company_address: this.companyAddress,
          company_email: this.companyEmail,
          company_tax_id: this.companyTaxId,
        });
        // If user locale is set, update the locale with user locale
        if (this.uiSettings?.locale) {
          this.$root.$i18n.locale = this.uiSettings?.locale;
        } else {
          // If user locale is not set, update the locale with account locale
          this.$root.$i18n.locale = this.locale;
        }
        this.getAccount(this.id).locale = this.locale;
        useAlert(this.$t('GENERAL_SETTINGS.UPDATE.SUCCESS'));
      } catch (error) {
        useAlert(this.$t('GENERAL_SETTINGS.UPDATE.ERROR'));
      }
    },
    async updateSmtpConfig(payload) {
      try {
        await this.$store.dispatch('accounts/update', {
          custom_email_config: payload,
        });
        useAlert(this.$t('GENERAL_SETTINGS.UPDATE.SUCCESS'));
      } catch (error) {
        useAlert(this.$t('GENERAL_SETTINGS.UPDATE.ERROR'));
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col w-full max-w-full ltr:mr-auto rtl:ml-auto">
    <BaseSettingsHeader :title="$t('GENERAL_SETTINGS.TITLE')" />
    <div class="flex-grow flex-shrink min-w-0 mt-3">
      <SectionLayout
        :title="$t('GENERAL_SETTINGS.FORM.GENERAL_SECTION.TITLE')"
        :description="$t('GENERAL_SETTINGS.FORM.GENERAL_SECTION.NOTE')"
        class="!pt-0"
      >
        <form
          v-if="!uiFlags.isFetchingItem"
          class="grid gap-4"
          @submit.prevent="updateAccount"
        >
          <WithLabel
            name="account-name"
            :has-error="v$.name.$error"
            :label="$t('GENERAL_SETTINGS.FORM.NAME.LABEL')"
            :error-message="$t('GENERAL_SETTINGS.FORM.NAME.ERROR')"
          >
            <NextInput
              v-model="name"
              type="text"
              class="w-full"
              :placeholder="$t('GENERAL_SETTINGS.FORM.NAME.PLACEHOLDER')"
              @blur="v$.name.$touch"
            />
          </WithLabel>
          <WithLabel
            v-if="false"
            name="site-language"
            :has-error="v$.locale.$error"
            :label="$t('GENERAL_SETTINGS.FORM.LANGUAGE.LABEL')"
            :error-message="$t('GENERAL_SETTINGS.FORM.LANGUAGE.ERROR')"
          >
            <div
              class="flex items-center gap-3 h-10 w-full rounded-lg bg-n-alpha-black2 px-3 border border-n-weak outline-n-weak"
            >
              <span
                class="text-sm font-medium"
                :class="!isVietnamese ? 'text-n-slate-12' : 'text-n-slate-10'"
              >
                {{ 'English' }}
              </span>
              <NextSwitch v-model="isVietnamese" />
              <span
                class="text-sm font-medium"
                :class="isVietnamese ? 'text-n-slate-12' : 'text-n-slate-10'"
              >
                {{ 'Tiếng Việt' }}
              </span>
            </div>
          </WithLabel>
          <WithLabel
            v-if="featureCustomReplyDomainEnabled"
            name="custom-domain"
            :label="$t('GENERAL_SETTINGS.FORM.DOMAIN.LABEL')"
          >
            <NextInput
              v-model="domain"
              type="text"
              class="w-full"
              :placeholder="$t('GENERAL_SETTINGS.FORM.DOMAIN.PLACEHOLDER')"
            />
            <template #help>
              {{
                featureInboundEmailEnabled &&
                $t('GENERAL_SETTINGS.FORM.FEATURES.INBOUND_EMAIL_ENABLED')
              }}

              {{
                featureCustomReplyDomainEnabled &&
                $t('GENERAL_SETTINGS.FORM.FEATURES.CUSTOM_EMAIL_DOMAIN_ENABLED')
              }}
            </template>
          </WithLabel>
          <WithLabel
            v-if="featureCustomReplyEmailEnabled"
            name="support-email"
            :label="$t('GENERAL_SETTINGS.FORM.SUPPORT_EMAIL.LABEL')"
          >
            <NextInput
              v-model="supportEmail"
              type="text"
              class="w-full"
              :placeholder="
                $t('GENERAL_SETTINGS.FORM.SUPPORT_EMAIL.PLACEHOLDER')
              "
            />
          </WithLabel>
          <div>
            <NextButton blue :is-loading="isUpdating" type="submit">
              {{ $t('GENERAL_SETTINGS.SUBMIT') }}
            </NextButton>
          </div>
        </form>
      </SectionLayout>

      <woot-loading-state v-if="uiFlags.isFetchingItem" />
    </div>

    <div
      v-if="!uiFlags.isFetchingItem && isAdmin"
      class="flex-grow flex-shrink min-w-0 mt-3"
    >
      <SectionLayout
        :title="$t('GENERAL_SETTINGS.FORM.INVOICE_SECTION.TITLE')"
        :description="$t('GENERAL_SETTINGS.FORM.INVOICE_SECTION.NOTE')"
        with-border
      >
        <template #headerActions>
          <div class="flex justify-end">
            <NextSwitch v-model="isCompany" />
          </div>
        </template>
        <form class="grid gap-4 mt-2" @submit.prevent="updateAccount">
          <template v-if="!isCompany">
            <WithLabel
              name="id-number"
              :label="
                $t('GENERAL_SETTINGS.FORM.INVOICE_SECTION.ID_NUMBER.LABEL')
              "
            >
              <NextInput
                v-model="idNumber"
                type="text"
                class="w-full"
                :placeholder="
                  $t(
                    'GENERAL_SETTINGS.FORM.INVOICE_SECTION.ID_NUMBER.PLACEHOLDER'
                  )
                "
              />
            </WithLabel>
            <WithLabel
              name="address"
              :label="$t('GENERAL_SETTINGS.FORM.INVOICE_SECTION.ADDRESS.LABEL')"
            >
              <NextInput
                v-model="address"
                type="text"
                class="w-full"
                :placeholder="
                  $t(
                    'GENERAL_SETTINGS.FORM.INVOICE_SECTION.ADDRESS.PLACEHOLDER'
                  )
                "
              />
            </WithLabel>
          </template>

          <template v-else>
            <WithLabel
              name="company-name"
              :label="
                $t('GENERAL_SETTINGS.FORM.INVOICE_SECTION.COMPANY_NAME.LABEL')
              "
            >
              <NextInput
                v-model="companyName"
                type="text"
                class="w-full"
                :placeholder="
                  $t(
                    'GENERAL_SETTINGS.FORM.INVOICE_SECTION.COMPANY_NAME.PLACEHOLDER'
                  )
                "
              />
            </WithLabel>
            <WithLabel
              name="company-tax"
              :label="
                $t('GENERAL_SETTINGS.FORM.INVOICE_SECTION.COMPANY_TAX.LABEL')
              "
            >
              <NextInput
                v-model="companyTaxId"
                type="text"
                class="w-full"
                :placeholder="
                  $t(
                    'GENERAL_SETTINGS.FORM.INVOICE_SECTION.COMPANY_TAX.PLACEHOLDER'
                  )
                "
              />
            </WithLabel>
            <WithLabel
              name="company-address"
              :label="
                $t(
                  'GENERAL_SETTINGS.FORM.INVOICE_SECTION.COMPANY_ADDRESS.LABEL'
                )
              "
            >
              <NextInput
                v-model="companyAddress"
                type="text"
                class="w-full"
                :placeholder="
                  $t(
                    'GENERAL_SETTINGS.FORM.INVOICE_SECTION.COMPANY_ADDRESS.PLACEHOLDER'
                  )
                "
              />
            </WithLabel>
            <WithLabel
              name="company-email"
              :label="
                $t('GENERAL_SETTINGS.FORM.INVOICE_SECTION.COMPANY_EMAIL.LABEL')
              "
              :has-error="v$.companyEmail.$error"
              :error-message="
                $t('GENERAL_SETTINGS.FORM.INVOICE_SECTION.COMPANY_EMAIL.ERROR')
              "
            >
              <NextInput
                v-model="companyEmail"
                type="text"
                class="w-full"
                :placeholder="
                  $t(
                    'GENERAL_SETTINGS.FORM.INVOICE_SECTION.COMPANY_EMAIL.PLACEHOLDER'
                  )
                "
                @blur="v$.companyEmail.$touch"
              />
            </WithLabel>
          </template>
          <div>
            <NextButton blue :is-loading="isUpdating" type="submit">
              {{ $t('GENERAL_SETTINGS.SUBMIT') }}
            </NextButton>
          </div>
        </form>
      </SectionLayout>
    </div>

    <div
      v-if="!uiFlags.isFetchingItem && isAdmin"
      class="flex-grow flex-shrink min-w-0 mt-3"
    >
      <SmtpSettings
        :config="customEmailConfig"
        :is-updating="isUpdating"
        @submit="updateSmtpConfig"
      />
    </div>

    <AudioTranscription v-if="showAudioTranscriptionConfig" />
    <AccountId />
    <div v-if="!uiFlags.isFetchingItem && isOnChatwootCloud">
      <AccountDelete />
    </div>
    <BuildInfo />
  </div>
</template>
