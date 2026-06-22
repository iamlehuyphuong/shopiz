<script setup>
import { computed, ref, onMounted } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required } from '@vuelidate/validators';
import Modal from 'dashboard/components/Modal.vue';
import FormInput from 'v3/components/Form/Input.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextButton from 'next/button/Button.vue';
import { useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['completed']);
const store = useStore();
const { currentAccount } = useAccount();
const { t } = useI18n();

const accountName = ref('');
const industry = ref('');
const companySize = ref('');
const source = ref('');
const isUpdating = ref(false);

const rules = {
  accountName: { required },
  industry: { required },
  companySize: { required },
  source: { required },
};

const v$ = useVuelidate(rules, { accountName, industry, companySize, source });

onMounted(() => {
  if (currentAccount.value) {
    accountName.value = currentAccount.value.name || '';
  }
});

const industryOptions = computed(() => [
  {
    label: t('REGISTER.ONBOARDING.INDUSTRY.OPTIONS.FASHION'),
    value: 'fashion_accessories',
  },
  {
    label: t('REGISTER.ONBOARDING.INDUSTRY.OPTIONS.HEALTH_BEAUTY'),
    value: 'health_beauty',
  },
  { label: t('REGISTER.ONBOARDING.INDUSTRY.OPTIONS.F_B'), value: 'f_b' },
  {
    label: t('REGISTER.ONBOARDING.INDUSTRY.OPTIONS.TECH'),
    value: 'technology',
  },
  { label: t('REGISTER.ONBOARDING.INDUSTRY.OPTIONS.OTHER'), value: 'other' },
]);

const companySizeOptions = computed(() => [
  {
    label: t('REGISTER.ONBOARDING.COMPANY_SIZE.OPTIONS.SIZE_1_5'),
    value: '1_5',
  },
  {
    label: t('REGISTER.ONBOARDING.COMPANY_SIZE.OPTIONS.SIZE_6_20'),
    value: '6_20',
  },
  {
    label: t('REGISTER.ONBOARDING.COMPANY_SIZE.OPTIONS.SIZE_21_50'),
    value: '21_50',
  },
  {
    label: t('REGISTER.ONBOARDING.COMPANY_SIZE.OPTIONS.SIZE_50_PLUS'),
    value: '50_plus',
  },
]);

const sourceOptions = computed(() => [
  {
    label: t('REGISTER.ONBOARDING.SOURCE.OPTIONS.FACEBOOK'),
    value: 'facebook',
  },
  { label: t('REGISTER.ONBOARDING.SOURCE.OPTIONS.TIKTOK'), value: 'tiktok' },
  { label: t('REGISTER.ONBOARDING.SOURCE.OPTIONS.GOOGLE'), value: 'google' },
  {
    label: t('REGISTER.ONBOARDING.SOURCE.OPTIONS.REFERRAL'),
    value: 'referral',
  },
  { label: t('REGISTER.ONBOARDING.SOURCE.OPTIONS.OTHER'), value: 'other' },
]);

const submit = async () => {
  v$.value.$touch();
  if (v$.value.$invalid) return;

  isUpdating.value = true;
  try {
    const payload = {
      name: accountName.value,
      industry: industry.value,
      company_size: companySize.value,
      source: source.value,
      onboarding_completed: true,
    };
    await store.dispatch('accounts/update', payload);
    useAlert(t('GENERAL_SETTINGS.UPDATE.SUCCESS'));
    emit('completed');
  } catch (error) {
    useAlert(error.message || t('GENERAL_SETTINGS.UPDATE.ERROR'));
  } finally {
    isUpdating.value = false;
  }
};
</script>

<template>
  <Modal
    :show="show"
    :close-on-backdrop-click="false"
    :show-close-button="false"
  >
    <div class="px-2 pb-2 pt-6 flex flex-col gap-6">
      <div class="text-center">
        <h2 class="text-2xl font-semibold text-n-slate-12 mb-2">
          {{ $t('REGISTER.ONBOARDING.WELCOME_TITLE') }}
        </h2>
        <p class="text-n-slate-11">
          {{ $t('REGISTER.ONBOARDING.WELCOME_DESCRIPTION') }}
        </p>
      </div>

      <form class="space-y-4" @submit.prevent="submit">
        <FormInput
          v-model="accountName"
          type="text"
          name="account_name"
          :class="{ error: v$.accountName.$error }"
          :label="$t('REGISTER.ONBOARDING.BUSINESS_NAME.LABEL')"
          :placeholder="$t('REGISTER.ONBOARDING.BUSINESS_NAME.PLACEHOLDER')"
          :has-error="v$.accountName.$error"
          :error-message="$t('REGISTER.ONBOARDING.BUSINESS_NAME.ERROR')"
          @blur="v$.accountName.$touch"
        />
        <WithLabel
          :label="$t('REGISTER.ONBOARDING.INDUSTRY.LABEL')"
          name="industry"
          :has-error="v$.industry.$error"
          :error-message="$t('REGISTER.ONBOARDING.INDUSTRY.ERROR')"
        >
          <div class="flex flex-wrap gap-2 pt-1">
            <button
              v-for="option in industryOptions"
              :key="option.value"
              type="button"
              class="px-3.5 py-1.5 rounded-full text-[13px] font-medium border transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-n-orange/50"
              :class="[
                industry === option.value
                  ? 'bg-n-orange border-n-orange text-white shadow-sm'
                  : 'bg-n-alpha-black2 border-n-strong text-n-slate-11 hover:bg-n-alpha-black3 hover:text-n-slate-12',
              ]"
              @click="
                industry = option.value;
                v$.industry.$touch();
              "
            >
              {{ option.label }}
            </button>
          </div>
        </WithLabel>

        <WithLabel
          :label="$t('REGISTER.ONBOARDING.COMPANY_SIZE.LABEL')"
          name="company_size"
          :has-error="v$.companySize.$error"
          :error-message="$t('REGISTER.ONBOARDING.COMPANY_SIZE.ERROR')"
        >
          <div class="flex flex-wrap gap-2 pt-1">
            <button
              v-for="option in companySizeOptions"
              :key="option.value"
              type="button"
              class="px-3.5 py-1.5 rounded-full text-[13px] font-medium border transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-n-orange/50"
              :class="[
                companySize === option.value
                  ? 'bg-n-orange border-n-orange text-white shadow-sm'
                  : 'bg-n-alpha-black2 border-n-strong text-n-slate-11 hover:bg-n-alpha-black3 hover:text-n-slate-12',
              ]"
              @click="
                companySize = option.value;
                v$.companySize.$touch();
              "
            >
              {{ option.label }}
            </button>
          </div>
        </WithLabel>

        <WithLabel
          :label="$t('REGISTER.ONBOARDING.SOURCE.LABEL')"
          name="source"
          :has-error="v$.source.$error"
          :error-message="$t('REGISTER.ONBOARDING.SOURCE.ERROR')"
        >
          <div class="flex flex-wrap gap-2 pt-1">
            <button
              v-for="option in sourceOptions"
              :key="option.value"
              type="button"
              class="px-3.5 py-1.5 rounded-full text-[13px] font-medium border transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-n-orange/50"
              :class="[
                source === option.value
                  ? 'bg-n-orange border-n-orange text-white shadow-sm'
                  : 'bg-n-alpha-black2 border-n-strong text-n-slate-11 hover:bg-n-alpha-black3 hover:text-n-slate-12',
              ]"
              @click="
                source = option.value;
                v$.source.$touch();
              "
            >
              {{ option.label }}
            </button>
          </div>
        </WithLabel>

        <div class="pt-4">
          <NextButton
            lg
            type="submit"
            class="w-full font-medium"
            :label="$t('REGISTER.ONBOARDING.NEXT_STEP')"
            :disabled="isUpdating || v$.$invalid"
            :is-loading="isUpdating"
          />
        </div>
      </form>
    </div>
  </Modal>
</template>
