<script setup>
import { computed, ref, onMounted } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import Modal from 'dashboard/components/Modal.vue';
import FormInput from 'v3/components/Form/Input.vue';
import FormSelect from 'v3/components/Form/Select.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import NextButton from 'next/button/Button.vue';
import { useStore } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useConfig } from 'dashboard/composables/useConfig';
import { useUISettings } from 'dashboard/composables/useUISettings';

const props = defineProps({
  show: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['completed']);
const store = useStore();
const { currentAccount } = useAccount();
const { t, locale } = useI18n();
const { updateUISettings } = useUISettings();
const { enabledLanguages } = useConfig();

const step = ref(1);
const isUpdating = ref(false);

const currentLanguage = computed({
  get: () => locale.value,
  set: async (val) => {
    locale.value = val;
    await updateUISettings({ locale: val });
  }
});

const languageOptions = computed(() => {
  return (enabledLanguages || []).map(l => ({
    label: l.name,
    value: l.iso_639_1_code
  }));
});

// Form fields
const accountName = ref('');
const industry = ref('other');
const industryOther = ref('');

const primaryGoals = ref([]);

const teamSize = ref('');
const dailyMessages = ref('');

const currentCrm = ref('other');
const currentCrmOther = ref('');

onMounted(() => {
  if (currentAccount.value) {
    accountName.value = currentAccount.value.name || '';
  }
});

// Options
const industryOptions = computed(() => [
  { label: t('REGISTER.ONBOARDING.STEP_1.INDUSTRY_OPTIONS.FASHION'), value: 'fashion_accessories' },
  { label: t('REGISTER.ONBOARDING.STEP_1.INDUSTRY_OPTIONS.BEAUTY'), value: 'beauty_personal_care' },
  { label: t('REGISTER.ONBOARDING.STEP_1.INDUSTRY_OPTIONS.F_B'), value: 'fb' },
  { label: t('REGISTER.ONBOARDING.STEP_1.INDUSTRY_OPTIONS.MOM_BABY'), value: 'mom_baby' },
  { label: t('REGISTER.ONBOARDING.STEP_1.INDUSTRY_OPTIONS.SPA'), value: 'spa_salon' },
  { label: t('REGISTER.ONBOARDING.STEP_1.INDUSTRY_OPTIONS.TECH'), value: 'tech_electronics' },
  { label: t('REGISTER.ONBOARDING.STEP_1.INDUSTRY_OPTIONS.HOME'), value: 'home_lifestyle' },
  { label: t('REGISTER.ONBOARDING.STEP_1.INDUSTRY_OPTIONS.EDU'), value: 'education' },
  { label: t('REGISTER.ONBOARDING.STEP_1.INDUSTRY_OPTIONS.HEALTH'), value: 'health_supplements' },
  { label: t('REGISTER.ONBOARDING.STEP_1.INDUSTRY_OPTIONS.OTHER'), value: 'other' },
]);

const goalsOptions = computed(() => [
  { label: t('REGISTER.ONBOARDING.STEP_2.GOALS_OPTIONS.MANAGE_MESSAGES'), value: 'manage_messages' },
  { label: t('REGISTER.ONBOARDING.STEP_2.GOALS_OPTIONS.PREVENT_MISSED'), value: 'prevent_missed' },
  { label: t('REGISTER.ONBOARDING.STEP_2.GOALS_OPTIONS.TRACK_PERFORMANCE'), value: 'track_performance' },
  { label: t('REGISTER.ONBOARDING.STEP_2.GOALS_OPTIONS.REMARKETING'), value: 'remarketing' },
  { label: t('REGISTER.ONBOARDING.STEP_2.GOALS_OPTIONS.AUTOMATION'), value: 'automation' },
]);

const teamSizeOptions = computed(() => [
  { label: t('REGISTER.ONBOARDING.STEP_3.TEAM_SIZE_OPTIONS.UNDER_5'), value: 'under_5' },
  { label: t('REGISTER.ONBOARDING.STEP_3.TEAM_SIZE_OPTIONS.5_TO_10'), value: '5_to_10' },
  { label: t('REGISTER.ONBOARDING.STEP_3.TEAM_SIZE_OPTIONS.OVER_10'), value: 'over_10' },
]);

const dailyMessagesOptions = computed(() => [
  { label: t('REGISTER.ONBOARDING.STEP_3.DAILY_MESSAGES_OPTIONS.UNDER_100'), value: 'under_100' },
  { label: t('REGISTER.ONBOARDING.STEP_3.DAILY_MESSAGES_OPTIONS.100_TO_500'), value: '100_to_500' },
  { label: t('REGISTER.ONBOARDING.STEP_3.DAILY_MESSAGES_OPTIONS.OVER_500'), value: 'over_500' },
]);

const crmOptions = computed(() => [
  { label: t('REGISTER.ONBOARDING.STEP_4.CRM_OPTIONS.NONE'), value: 'none' },
  { label: t('REGISTER.ONBOARDING.STEP_4.CRM_OPTIONS.ECOMMERCE'), value: 'ecommerce' },
  { label: t('REGISTER.ONBOARDING.STEP_4.CRM_OPTIONS.KIOTVIET'), value: 'kiotviet' },
  { label: t('REGISTER.ONBOARDING.STEP_4.CRM_OPTIONS.SAPO'), value: 'sapo' },
  { label: t('REGISTER.ONBOARDING.STEP_4.CRM_OPTIONS.HARAVAN'), value: 'haravan' },
  { label: t('REGISTER.ONBOARDING.STEP_4.CRM_OPTIONS.NHANHVN'), value: 'nhanhvn' },
  { label: t('REGISTER.ONBOARDING.STEP_4.CRM_OPTIONS.OTHER'), value: 'other' },
]);

// Validations
const rulesStep1 = {
  accountName: { required },
  industry: { required },
  industryOther: {
    required: (val) => (industry.value === 'other' ? !!val : true),
  },
};

const rulesStep2 = {
  primaryGoals: { required, minLength: minLength(1) },
};

const rulesStep3 = {
  teamSize: { required },
  dailyMessages: { required },
};

const rulesStep4 = {
  currentCrm: { required },
  currentCrmOther: {
    required: (val) => (currentCrm.value === 'other' ? !!val : true),
  },
};

const v1$ = useVuelidate(rulesStep1, { accountName, industry, industryOther });
const v2$ = useVuelidate(rulesStep2, { primaryGoals });
const v3$ = useVuelidate(rulesStep3, { teamSize, dailyMessages });
const v4$ = useVuelidate(rulesStep4, { currentCrm, currentCrmOther });

const isNextDisabled = computed(() => {
  if (step.value === 1) return v1$.value.$invalid;
  if (step.value === 2) return v2$.value.$invalid;
  if (step.value === 3) return v3$.value.$invalid;
  if (step.value === 4) return v4$.value.$invalid;
  return false;
});

// Handlers
const toggleGoal = (value) => {
  if (primaryGoals.value.includes(value)) {
    primaryGoals.value = primaryGoals.value.filter((g) => g !== value);
  } else {
    primaryGoals.value.push(value);
  }
  v2$.value.$touch();
};

const currentErrorMessage = computed(() => {
  if (step.value === 1) {
    if (v1$.value.accountName.$error) return t('REGISTER.ONBOARDING.STEP_1.BUSINESS_NAME_ERROR');
    if (v1$.value.industry.$error || v1$.value.industryOther.$error) return t('REGISTER.ONBOARDING.STEP_1.INDUSTRY_ERROR');
  }
  if (step.value === 2) {
    if (v2$.value.primaryGoals.$error) return t('REGISTER.ONBOARDING.STEP_2.GOALS_ERROR');
  }
  if (step.value === 3) {
    if (v3$.value.teamSize.$error) return t('REGISTER.ONBOARDING.STEP_3.TEAM_SIZE_ERROR');
    if (v3$.value.dailyMessages.$error) return t('REGISTER.ONBOARDING.STEP_3.DAILY_MESSAGES_ERROR');
  }
  if (step.value === 4) {
    if (v4$.value.currentCrm.$error || v4$.value.currentCrmOther.$error) return t('REGISTER.ONBOARDING.STEP_4.CRM_ERROR');
  }
  return '';
});

const handleNext = async () => {
  if (step.value === 1) {
    v1$.value.$touch();
    if (!v1$.value.$invalid) step.value = 2;
  } else if (step.value === 2) {
    v2$.value.$touch();
    if (!v2$.value.$invalid) step.value = 3;
  } else if (step.value === 3) {
    v3$.value.$touch();
    if (!v3$.value.$invalid) step.value = 4;
  } else if (step.value === 4) {
    submit();
  }
};

const submit = async () => {
  v4$.value.$touch();
  if (v4$.value.$invalid) return;

  isUpdating.value = true;
  try {
    const finalIndustry = industry.value === 'other' ? industryOther.value : industry.value;
    const finalCrm = currentCrm.value === 'other' ? currentCrmOther.value : currentCrm.value;

    const payload = {
      name: accountName.value,
      industry: finalIndustry,
      primary_goals: primaryGoals.value,
      team_size: teamSize.value,
      daily_messages: dailyMessages.value,
      current_crm: finalCrm,
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
    <form class="flex flex-col w-full h-[520px] overflow-hidden" @submit.prevent="handleNext">
      
      <!-- Fixed Header -->
      <div class="p-2 flex flex-col gap-4">
        <h2 class="text-[22px] font-semibold text-n-slate-12 text-center">
          {{ $t('REGISTER.ONBOARDING.STEP_1.TITLE') }}
        </h2>
        
        <!-- Process steps bar -->
        <div class="flex items-center gap-2">
          <div 
            v-for="i in 4" 
            :key="i"
            class="h-1.5 flex-1 rounded-full transition-colors duration-300"
            :class="i <= step ? 'bg-n-orange' : 'bg-n-alpha-black2'"
          ></div>
        </div>
      </div>

      <!-- Scrollable Body -->
      <div class="flex-1 overflow-y-auto p-2">
        
        <!-- STEP 1 -->
        <div v-if="step === 1" class="space-y-5">
          <div>
            <h3 class="text-[15px] font-semibold text-n-slate-12 mb-2">{{ $t('REGISTER.ONBOARDING.STEP_1.LANGUAGE_LABEL') || 'Chọn ngôn ngữ của bạn:' }}</h3>
            <FormSelect
              v-model="currentLanguage"
              :options="languageOptions"
              name="language"
            />
          </div>

          <div>
            <h3 class="text-[15px] font-semibold text-n-slate-12 mb-2">{{ $t('REGISTER.ONBOARDING.STEP_1.BUSINESS_NAME_LABEL') }}</h3>
            <FormInput
              v-model="accountName"
              type="text"
              name="account_name"
              :class="{ error: v1$.accountName.$error }"
              :placeholder="$t('REGISTER.ONBOARDING.STEP_1.BUSINESS_NAME_PLACEHOLDER')"
              :has-error="v1$.accountName.$error"
              @blur="v1$.accountName.$touch"
            />
          </div>

          <div>
            <h3 class="text-[15px] font-semibold text-n-slate-12 mb-2">{{ $t('REGISTER.ONBOARDING.STEP_1.INDUSTRY_LABEL') }}</h3>
            <FormSelect
              v-model="industry"
              :options="industryOptions"
              name="industry"
              :has-error="v1$.industry.$error || v1$.industryOther.$error"
              @update:model-value="(val) => { if (val !== 'other') industryOther = ''; v1$.industry.$touch(); }"
            />
            <div v-if="industry === 'other'" class="mt-3">
              <FormInput
                v-model="industryOther"
                type="text"
                name="industry_other"
                :class="{ error: v1$.industryOther.$error }"
                :placeholder="$t('REGISTER.ONBOARDING.STEP_1.OTHER_PLACEHOLDER')"
                @blur="v1$.industryOther.$touch"
              />
            </div>
          </div>
        </div>

        <!-- STEP 2 -->
        <div v-if="step === 2" class="space-y-4">
          <div>
            <h3 class="text-[15px] font-semibold text-n-slate-12 mb-3">{{ $t('REGISTER.ONBOARDING.STEP_2.TITLE') }}</h3>
            <div class="flex flex-col gap-2">
            <label
              v-for="option in goalsOptions"
              :key="option.value"
              class="flex items-start gap-3 p-3.5 rounded-lg border cursor-pointer transition-colors"
              :class="[
                primaryGoals.includes(option.value)
                  ? 'bg-n-alpha-orange1 border-n-orange'
                  : 'bg-n-alpha-black2 border-n-strong hover:bg-n-alpha-black3',
              ]"
            >
              <div class="flex items-center h-5">
                <input
                  type="checkbox"
                  class="w-4 h-4 rounded border-n-strong text-n-orange focus:ring-n-orange/50 cursor-pointer"
                  :checked="primaryGoals.includes(option.value)"
                  @change="toggleGoal(option.value)"
                />
              </div>
              <div class="text-sm font-medium text-n-slate-12 leading-5">
                {{ option.label }}
              </div>
            </label>
          </div>
        </div>
        </div>

        <!-- STEP 3 -->
        <div v-if="step === 3" class="space-y-6">
          <div :class="{ 'has-error': v3$.teamSize.$error }">
            <h3 class="text-[15px] font-semibold text-n-slate-12 mb-3">
              {{ $t('REGISTER.ONBOARDING.STEP_3.TEAM_SIZE_LABEL') }}
            </h3>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-3 pt-1">
              <button
                v-for="option in teamSizeOptions"
                :key="option.value"
                type="button"
                class="p-3 rounded-lg border text-[13px] font-medium transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-n-orange/50"
                :class="[
                  teamSize === option.value
                    ? 'bg-n-orange border-n-orange text-white shadow-sm'
                    : 'bg-n-alpha-black2 border-n-strong text-n-slate-11 hover:bg-n-alpha-black3 hover:text-n-slate-12',
                ]"
                @click="
                  teamSize = option.value;
                  v3$.teamSize.$touch();
                "
              >
                {{ option.label }}
              </button>
            </div>
          </div>

          <div :class="{ 'has-error': v3$.dailyMessages.$error }">
            <h3 class="text-[15px] font-semibold text-n-slate-12 mb-3">
              {{ $t('REGISTER.ONBOARDING.STEP_3.DAILY_MESSAGES_LABEL') }}
            </h3>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-3 pt-1">
              <button
                v-for="option in dailyMessagesOptions"
                :key="option.value"
                type="button"
                class="p-3 rounded-lg border text-[13px] font-medium transition-colors focus:outline-none focus-visible:ring-2 focus-visible:ring-n-orange/50"
                :class="[
                  dailyMessages === option.value
                    ? 'bg-n-orange border-n-orange text-white shadow-sm'
                    : 'bg-n-alpha-black2 border-n-strong text-n-slate-11 hover:bg-n-alpha-black3 hover:text-n-slate-12',
                ]"
                @click="
                  dailyMessages = option.value;
                  v3$.dailyMessages.$touch();
                "
              >
                {{ option.label }}
              </button>
            </div>
          </div>
        </div>

        <!-- STEP 4 -->
        <div v-if="step === 4" class="space-y-4">
          <div>
            <h3 class="text-[15px] font-semibold text-n-slate-12 mb-2">{{ $t('REGISTER.ONBOARDING.STEP_4.TITLE') }}</h3>
            <FormSelect
              v-model="currentCrm"
              :options="crmOptions"
              name="current_crm"
              :has-error="v4$.currentCrm.$error || v4$.currentCrmOther.$error"
              @update:model-value="(val) => { if (val !== 'other') currentCrmOther = ''; v4$.currentCrm.$touch(); }"
            />
            <div v-if="currentCrm === 'other'" class="mt-3">
              <FormInput
                v-model="currentCrmOther"
                type="text"
                name="current_crm_other"
                :class="{ error: v4$.currentCrmOther.$error }"
                :placeholder="$t('REGISTER.ONBOARDING.STEP_4.OTHER_PLACEHOLDER')"
                @blur="v4$.currentCrmOther.$touch"
              />
            </div>
          </div>
        </div>
      </div>

      <!-- Fixed Footer -->
      <div class="p-2 mt-auto flex justify-between items-center gap-3">
        <div class="text-[13px] text-n-ruby font-medium pl-1">
          {{ currentErrorMessage }}
        </div>
        <div class="flex gap-3">
          <NextButton
            v-if="step > 1"
            type="button"
            class="font-medium !bg-n-alpha-black2 hover:!bg-n-alpha-black3 !text-n-slate-11 hover:!text-n-slate-12 px-6"
            :label="$t('REGISTER.ONBOARDING.GO_BACK')"
            @click="step--"
          />
          <NextButton
            type="submit"
            class="font-medium px-8"
            :label="step === 4 ? $t('REGISTER.ONBOARDING.STEP_4.FINISH_BUTTON') : $t(`REGISTER.ONBOARDING.STEP_${step}.NEXT_BUTTON`)"
            :disabled="isNextDisabled || isUpdating"
            :is-loading="isUpdating"
          />
        </div>
      </div>

    </form>
  </Modal>
</template>
