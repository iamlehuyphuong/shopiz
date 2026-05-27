<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, email } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { DEFAULT_REDIRECT_URL } from 'dashboard/constants/globals';
import VueHcaptcha from '@hcaptcha/vue3-hcaptcha';
import FormInput from 'v3/components/Form/Input.vue';
import NextButton from 'next/button/Button.vue';
import PasswordRequirements from './PasswordRequirements.vue';
import { isValidPassword } from 'shared/helpers/Validators';
import GoogleOAuthButton from 'v3/components/GoogleOauth/Button.vue';
import Icon from 'next/icon/Icon.vue';
import SimpleDivider from 'v3/components/Divider/SimpleDivider.vue';
import { register } from 'v3/api/auth';

const MIN_PASSWORD_LENGTH = 6;
const SPECIAL_CHAR_REGEX = /[!@#$%^&*()_+\-=[\]{}|'"/\\.,`<>:;?~]/;

export default {
  components: {
    FormInput,
    GoogleOAuthButton,
    NextButton,
    SimpleDivider,
    Icon,
    VueHcaptcha,
    PasswordRequirements,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      credentials: {
        accountName: '',
        fullName: '',
        email: '',
        password: '',
        hCaptchaClientResponse: '',
      },
      didCaptchaReset: false,
      isSignupInProgress: false,
      isPasswordFocused: false,
      error: '',
    };
  },
  validations() {
    return {
      credentials: {
        email: {
          required,
          email,
        },
        password: {
          required,
          isValidPassword,
          minLength: minLength(MIN_PASSWORD_LENGTH),
        },
      },
    };
  },
  computed: {
    ...mapGetters({ globalConfig: 'globalConfig/get' }),
    termsLink() {
      return this.$t('REGISTER.TERMS_ACCEPT')
        .replace('https://www.flowify.vn/terms', this.globalConfig.termsURL)
        .replace(
          'https://www.flowify.vn/privacy-policy',
          this.globalConfig.privacyURL
        );
    },
    hasAValidCaptcha() {
      if (this.globalConfig.hCaptchaSiteKey) {
        return !!this.credentials.hCaptchaClientResponse;
      }
      return true;
    },
    allowedLoginMethods() {
      return window.flowifyConfig.allowedLoginMethods || ['email'];
    },
    showGoogleOAuth() {
      return (
        this.allowedLoginMethods.includes('google_oauth') &&
        Boolean(window.flowifyConfig.googleOAuthClientId)
      );
    },
    isFormValid() {
      return !this.v$.$invalid;
    },
    passwordRequirements() {
      const password = this.credentials.password || '';
      return {
        length: password.length >= MIN_PASSWORD_LENGTH,
        uppercase: /[A-Z]/.test(password),
        lowercase: /[a-z]/.test(password),
        number: /[0-9]/.test(password),
        special: SPECIAL_CHAR_REGEX.test(password),
      };
    },
    passwordRequirementItems() {
      const reqs = this.passwordRequirements;
      return [
        {
          id: 'length',
          met: reqs.length,
          label: this.$t('REGISTER.PASSWORD.REQUIREMENTS_LENGTH', {
            min: MIN_PASSWORD_LENGTH,
          }),
        },
        {
          id: 'uppercase',
          met: reqs.uppercase,
          label: this.$t('REGISTER.PASSWORD.REQUIREMENTS_UPPERCASE'),
        },
        {
          id: 'lowercase',
          met: reqs.lowercase,
          label: this.$t('REGISTER.PASSWORD.REQUIREMENTS_LOWERCASE'),
        },
        {
          id: 'number',
          met: reqs.number,
          label: this.$t('REGISTER.PASSWORD.REQUIREMENTS_NUMBER'),
        },
        {
          id: 'special',
          met: reqs.special,
          label: this.$t('REGISTER.PASSWORD.REQUIREMENTS_SPECIAL'),
        },
      ];
    },
    passwordRequirementsMet() {
      return Object.values(this.passwordRequirements).every(Boolean);
    },
  },
  methods: {
    async submit() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        this.resetCaptcha();
        return;
      }

      if (
        this.globalConfig.hCaptchaSiteKey &&
        !this.credentials.hCaptchaClientResponse
      ) {
        this.$refs.hCaptcha.execute();
        return;
      }

      this.isSignupInProgress = true;
      try {
        await register(this.credentials);
        window.location = DEFAULT_REDIRECT_URL;
      } catch (error) {
        let errorMessage =
          error?.message || this.$t('REGISTER.API.ERROR_MESSAGE');
        this.resetCaptcha();
        useAlert(errorMessage);
      } finally {
        this.isSignupInProgress = false;
      }
    },
    onRecaptchaVerified(token) {
      this.credentials.hCaptchaClientResponse = token;
      this.didCaptchaReset = false;
      this.v$.$touch();
      if (!this.v$.$invalid) {
        this.submit();
      }
    },
    resetCaptcha() {
      if (!this.globalConfig.hCaptchaSiteKey) return;
      this.$refs.hCaptcha.reset();
      this.credentials.hCaptchaClientResponse = '';
      this.didCaptchaReset = true;
    },
  },
};
</script>

<template>
  <div class="flex-1">
    <form class="space-y-3" @submit.prevent="submit">
      <FormInput
        v-model="credentials.email"
        type="email"
        name="email_address"
        :class="{ error: v$.credentials.email.$error }"
        :label="$t('REGISTER.EMAIL.LABEL')"
        :placeholder="$t('REGISTER.EMAIL.PLACEHOLDER')"
        :has-error="v$.credentials.email.$error"
        :error-message="$t('REGISTER.EMAIL.ERROR')"
        @blur="v$.credentials.email.$touch"
      />
      <div class="relative">
        <FormInput
          v-model="credentials.password"
          type="password"
          name="password"
          :class="{ error: v$.credentials.password.$error }"
          :label="$t('LOGIN.PASSWORD.LABEL')"
          :placeholder="$t('SET_NEW_PASSWORD.PASSWORD.PLACEHOLDER')"
          :has-error="v$.credentials.password.$error"
          @focus="isPasswordFocused = true"
          @blur="
            isPasswordFocused = false;
            v$.credentials.password.$touch();
          "
        />
        <Transition
          enter-active-class="transition duration-200 ease-out origin-left"
          enter-from-class="opacity-0 scale-90 translate-x-1"
          enter-to-class="opacity-100 scale-100 translate-x-0"
          leave-active-class="transition duration-150 ease-in origin-left"
          leave-from-class="opacity-100 scale-100 translate-x-0"
          leave-to-class="opacity-0 scale-90 translate-x-1"
        >
          <PasswordRequirements
            v-if="isPasswordFocused"
            :password="credentials.password"
          />
        </Transition>
      </div>
      <VueHcaptcha
        v-if="globalConfig.hCaptchaSiteKey"
        ref="hCaptcha"
        size="invisible"
        :sitekey="globalConfig.hCaptchaSiteKey"
        @verify="onRecaptchaVerified"
        @error="onCaptchaError"
        @expired="onCaptchaError"
        @challenge-expired="onCaptchaError"
        @closed="onCaptchaError"
      />
      <NextButton
        lg
        type="submit"
        data-testid="submit_button"
        class="w-full font-medium"
        :label="$t('REGISTER.SUBMIT')"
        :disabled="isSignupInProgress || !isFormValid"
        :is-loading="isSignupInProgress"
      />
    </form>
    <GoogleOAuthButton v-if="showGoogleOAuth" class="mt-3">
      {{ $t('REGISTER.OAUTH.GOOGLE_SIGNUP') }}
    </GoogleOAuthButton>
    <p
      class="text-sm mt-5 mb-0 text-n-slate-11 [&>a]:text-n-orange-10 [&>a]:font-medium [&>a]:hover:text-n-orange-11"
      v-html="termsLink"
    />
  </div>
</template>
