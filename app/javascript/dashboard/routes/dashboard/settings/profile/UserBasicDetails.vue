<script>
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength, email } from '@vuelidate/validators';
export default {
  components: {
    NextButton,
  },
  props: {
    name: {
      type: String,
      default: '',
    },
    email: {
      type: String,
      default: '',
    },
    displayName: {
      type: String,
      default: '',
    },
    emailEnabled: {
      type: Boolean,
      default: false,
    },
    address: {
      type: String,
      default: '',
    },
    typeId: {
      type: String,
      default: null,
    },
    companyName: {
      type: String,
      default: '',
    },
    companyAddress: {
      type: String,
      default: '',
    },
    companyEmail: {
      type: String,
      default: '',
    },
    companyTaxId: {
      type: String,
      default: '',
    },
  },
  emits: ['updateUser'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      userName: this.name,
      userDisplayName: this.displayName,
      userEmail: this.email,
      userAddress: this.address,
      userTypeId: this.typeId,
      modelCompanyName: this.companyName,
      modelCompanyAddress: this.companyAddress,
      modelCompanyEmail: this.companyEmail,
      modelCompanyTaxId: this.companyTaxId,
      inputStyles: {
        borderRadius: '0.75rem',
        padding: '0.375rem 0.75rem',
        fontSize: '0.875rem',
        marginBottom: '0.125rem',
      },
    };
  },
  validations: {
    userName: {
      required,
      minLength: minLength(1),
    },
    userDisplayName: {},
    userEmail: {
      required,
      email,
    },
    userAddress: {},
    modelCompanyName: {},
    modelCompanyAddress: {},
    modelCompanyEmail: {
      email,
    },
    modelCompanyTaxId: {},
  },
  watch: {
    name: {
      handler(value) {
        this.userName = value;
      },
      immediate: true,
    },
    displayName: {
      handler(value) {
        this.userDisplayName = value;
      },
      immediate: true,
    },
    email: {
      handler(value) {
        this.userEmail = value;
      },
      immediate: true,
    },
    address: {
      handler(value) {
        this.userAddress = value;
      },
      immediate: true,
    },
    companyName: {
      handler(value) {
        this.modelCompanyName = value;
      },
      immediate: true,
    },
    companyAddress: {
      handler(value) {
        this.modelCompanyAddress = value;
      },
      immediate: true,
    },
    companyEmail: {
      handler(value) {
        this.modelCompanyEmail = value;
      },
      immediate: true,
    },
    companyTaxId: {
      handler(value) {
        this.modelCompanyTaxId = value;
      },
      immediate: true,
    },
    typeId: {
      handler(value) {
        if (value === 'personal' || value === 'company') {
          this.userTypeId = value
        }
      },
      immediate: true
    }
  },
  methods: {
    async updateUser() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        useAlert(this.$t('PROFILE_SETTINGS.FORM.ERROR'));
        return;
      }
      this.$emit('updateUser', {
        name: this.userName,
        displayName: this.userDisplayName,
        email: this.userEmail,
        address: this.userAddress,
        typeId: this.userTypeId,
        companyName: this.modelCompanyName,
        companyAddress: this.modelCompanyAddress,
        companyEmail: this.modelCompanyEmail,
        companyTaxId: this.modelCompanyTaxId,
      });
    },
  },
};
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="updateUser('profile')">
    <woot-input
      v-model="userDisplayName"
      :styles="inputStyles"
      :class="{ error: v$.userDisplayName.$error }"
      :label="$t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.PLACEHOLDER')"
      :error="`${
        v$.userDisplayName.$error
          ? $t('PROFILE_SETTINGS.FORM.DISPLAY_NAME.ERROR')
          : ''
      }`"
      @input="v$.userDisplayName.$touch"
      @blur="v$.userDisplayName.$touch"
    />
    <div class="flex gap-2">
      <div class="flex items-center gap-2">
        <input
          id="personal"
          v-model="userTypeId"
          type="radio"
          name="userTypeId"
          value="personal"
        />
        <label for="personal">{{
          $t('PROFILE_SETTINGS.FORM.TYPE_IDS.PERSONAL')
        }}</label>
      </div>
      <div class="flex items-center gap-2">
        <input
          id="company"
          v-model="userTypeId"
          type="radio"
          name="userTypeId"
          value="company"
        />
        <label for="company">{{
          $t('PROFILE_SETTINGS.FORM.TYPE_IDS.COMPANY')
        }}</label>
      </div>
    </div>
    <woot-input
      v-if="userTypeId === 'personal'"
      v-model="userName"
      :styles="inputStyles"
      :class="{ error: v$.userName.$error }"
      :label="$t('PROFILE_SETTINGS.FORM.NAME.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.NAME.PLACEHOLDER')"
      :error="`${
        v$.userName.$error ? $t('PROFILE_SETTINGS.FORM.NAME.ERROR') : ''
      }`"
      @input="v$.userName.$touch"
      @blur="v$.userName.$touch"
    />
    <woot-input
      v-if="userTypeId === 'personal'"
      v-model="userAddress"
      :styles="inputStyles"
      :label="$t('PROFILE_SETTINGS.FORM.ADDRESS.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.ADDRESS.PLACEHOLDER')"
      @input="v$.userAddress.$touch"
      @blur="v$.userAddress.$touch"
    />
    <woot-input
      v-if="userTypeId === 'personal' && emailEnabled"
      v-model="userEmail"
      :styles="inputStyles"
      :class="{ error: v$.userEmail.$error }"
      :label="$t('PROFILE_SETTINGS.FORM.EMAIL.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.EMAIL.PLACEHOLDER')"
      :error="`${
        v$.userEmail.$error ? $t('PROFILE_SETTINGS.FORM.EMAIL.ERROR') : ''
      }`"
      @input="v$.userEmail.$touch"
      @blur="v$.userEmail.$touch"
    />

    <woot-input
      v-if="userTypeId === 'company'"
      v-model="modelCompanyName"
      :styles="inputStyles"
      :label="$t('PROFILE_SETTINGS.FORM.COMPANY_NAME.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.COMPANY_NAME.PLACEHOLDER')"
      @input="v$.modelCompanyName.$touch"
      @blur="v$.modelCompanyName.$touch"
    />
    <woot-input
      v-if="userTypeId === 'company'"
      v-model="modelCompanyTaxId"
      :styles="inputStyles"
      :label="$t('PROFILE_SETTINGS.FORM.COMPANY_TAX.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.COMPANY_TAX.PLACEHOLDER')"
      @input="v$.modelCompanyTaxId.$touch"
      @blur="v$.modelCompanyTaxId.$touch"
    />
    <woot-input
      v-if="userTypeId === 'company'"
      v-model="modelCompanyAddress"
      :styles="inputStyles"
      :label="$t('PROFILE_SETTINGS.FORM.COMPANY_ADDRESS.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.COMPANY_ADDRESS.PLACEHOLDER')"
      @input="v$.modelCompanyAddress.$touch"
      @blur="v$.modelCompanyAddress.$touch"
    />
    <woot-input
      v-if="userTypeId === 'company'"
      v-model="modelCompanyEmail"
      :class="{ error: v$.modelCompanyEmail.$error }"
      :styles="inputStyles"
      :label="$t('PROFILE_SETTINGS.FORM.COMPANY_EMAIL.LABEL')"
      :placeholder="$t('PROFILE_SETTINGS.FORM.COMPANY_EMAIL.PLACEHOLDER')"
      :error="`${
        v$.modelCompanyEmail.$error ? $t('PROFILE_SETTINGS.FORM.COMPANY_EMAIL.ERROR') : ''
      }`"
      @input="v$.modelCompanyEmail.$touch"
      @blur="v$.modelCompanyEmail.$touch"
    />
    <div>
      <NextButton type="submit" :label="$t('PROFILE_SETTINGS.BTN_TEXT')" />
    </div>
  </form>
</template>
