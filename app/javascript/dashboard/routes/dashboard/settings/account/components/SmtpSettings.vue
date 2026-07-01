<script>
import { useVuelidate } from '@vuelidate/core';
import { required, email, requiredIf } from '@vuelidate/validators';
import SectionLayout from './SectionLayout.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextInput from 'next/input/Input.vue';
import NextSwitch from 'dashboard/components-next/switch/Switch.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import AccountAPI from 'dashboard/api/account';
import { useAlert } from 'dashboard/composables';

export default {
  components: {
    SectionLayout,
    WithLabel,
    NextInput,
    NextSwitch,
    NextButton,
  },
  props: {
    config: {
      type: Object,
      default: () => ({}),
    },
    isUpdating: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['submit'],
  setup() {
    const v$ = useVuelidate();
    return { v$ };
  },
  data() {
    return {
      enabled: false,
      senderEmail: '',
      smtpPassword: '',
      isTesting: false,
    };
  },
  validations: {
    senderEmail: {
      email,
      required: requiredIf(function () {
        return this.enabled;
      }),
    },
    smtpPassword: {
      required: requiredIf(function () {
        return this.enabled;
      }),
    },
    smtpPassword: {
      required: requiredIf(function () {
        return this.enabled;
      }),
    },
  },
  watch: {
    config: {
      handler(newConfig) {
        if (newConfig && Object.keys(newConfig).length > 0) {
          this.enabled = !!newConfig.smtp_address;
          this.senderEmail = newConfig.sender_email || '';
          this.smtpPassword = newConfig.smtp_password || '';
        }
      },
      immediate: true,
      deep: true,
    },
  },
  methods: {
    async testEmail() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }
      this.isTesting = true;
      try {
        await AccountAPI.testEmail(this.senderEmail);
        useAlert(this.$t('GENERAL_SETTINGS.FORM.CUSTOM_EMAIL.TEST_EMAIL_SUCCESS'));
      } catch (error) {
        useAlert(this.$t('GENERAL_SETTINGS.FORM.CUSTOM_EMAIL.TEST_EMAIL_ERROR'));
      } finally {
        this.isTesting = false;
      }
    },
    onSubmit() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      let payload = null;
      if (this.enabled) {
        payload = {
          sender_email: this.senderEmail,
          smtp_address: 'smtp.gmail.com',
          smtp_port: 587,
          smtp_username: this.senderEmail,
          smtp_password: this.smtpPassword,
          smtp_domain: 'gmail.com',
          smtp_authentication: 'login',
          smtp_enable_starttls_auto: true,
          smtp_openssl_verify_mode: 'peer',
        };
      } else {
        // Clear SMTP config when disabled
        payload = {
          sender_email: '',
          smtp_address: '',
          smtp_port: null,
          smtp_username: '',
          smtp_password: '',
          smtp_domain: '',
          smtp_authentication: 'login',
          smtp_enable_starttls_auto: true,
          smtp_openssl_verify_mode: 'peer',
        };
      }
      this.$emit('submit', payload);
    },
  },
};
</script>

<template>
  <SectionLayout
    :title="$t('GENERAL_SETTINGS.FORM.CUSTOM_EMAIL.TITLE')"
    with-border
  >
    <template #headerActions>
      <div class="flex justify-end">
        <NextSwitch v-model="enabled" />
      </div>
    </template>
    <template #description>
      <span v-html="$t('GENERAL_SETTINGS.FORM.CUSTOM_EMAIL.NOTE')" />
    </template>
    <form class="grid gap-4 mt-2" @submit.prevent="onSubmit">
      <div v-if="enabled" class="grid gap-4 bg-n-alpha-black2 p-4 rounded-lg">
        <WithLabel
          name="sender-email"
          :has-error="v$.senderEmail.$error"
          :label="$t('GENERAL_SETTINGS.FORM.CUSTOM_EMAIL.SENDER_EMAIL.LABEL')"
          :error-message="
            $t('GENERAL_SETTINGS.FORM.CUSTOM_EMAIL.SENDER_EMAIL.ERROR')
          "
        >
          <NextInput
            v-model="senderEmail"
            type="text"
            class="w-full"
            :placeholder="
              $t('GENERAL_SETTINGS.FORM.CUSTOM_EMAIL.SENDER_EMAIL.PLACEHOLDER')
            "
            @blur="v$.senderEmail.$touch"
          />
        </WithLabel>

        <div class="grid grid-cols-1 gap-4">
          <WithLabel
            name="smtp-password"
            :has-error="v$.smtpPassword.$error"
            :label="
              $t('GENERAL_SETTINGS.FORM.CUSTOM_EMAIL.SMTP_PASSWORD.LABEL')
            "
            :error-message="
              $t('GENERAL_SETTINGS.FORM.CUSTOM_EMAIL.SMTP_PASSWORD.ERROR')
            "
          >
            <NextInput
              v-model="smtpPassword"
              type="password"
              class="w-full"
              :placeholder="
                $t(
                  'GENERAL_SETTINGS.FORM.CUSTOM_EMAIL.SMTP_PASSWORD.PLACEHOLDER'
                )
              "
              @blur="v$.smtpPassword.$touch"
            />
          </WithLabel>
        </div>
      </div>

      <div class="flex gap-2">
        <NextButton blue :is-loading="isUpdating" type="submit">
          {{ $t('GENERAL_SETTINGS.FORM.CUSTOM_EMAIL.SUBMIT') }}
        </NextButton>
        <NextButton
          v-if="enabled"
          :is-loading="isTesting"
          @click.prevent="testEmail"
        >
          {{ $t('GENERAL_SETTINGS.FORM.CUSTOM_EMAIL.TEST_EMAIL_SUBMIT') }}
        </NextButton>
      </div>
    </form>
  </SectionLayout>
</template>
