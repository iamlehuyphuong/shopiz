<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';

const props = defineProps({
  assistant: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit']);

const { t } = useI18n();

const initialState = {
  name: '',
  description: '',
  companyName: '',
  industry: '',
  coreProducts: '',
  features: {
    conversationFaqs: false,
    memories: false,
    citations: false,
    contactAttributes: false,
    orderCreation: false,
  },
};

const state = reactive({ ...initialState });

const validationRules = {
  name: { required, minLength: minLength(1) },
  description: { required, minLength: minLength(1) },
  companyName: { required, minLength: minLength(1) },
  industry: { required, minLength: minLength(1) },
  coreProducts: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(validationRules, state);

const getErrorMessage = field => {
  return v$.value[field].$error ? v$.value[field].$errors[0].$message : '';
};

const formErrors = computed(() => ({
  name: getErrorMessage('name'),
  description: getErrorMessage('description'),
  companyName: getErrorMessage('companyName'),
  industry: getErrorMessage('industry'),
  coreProducts: getErrorMessage('coreProducts'),
}));

const updateStateFromAssistant = assistant => {
  const { config = {} } = assistant;
  state.name = assistant.name;
  state.description = assistant.description;
  state.companyName = config.company_name || '';
  state.industry = config.industry || '';
  state.coreProducts = config.core_products || config.product_name || '';
  state.features = {
    conversationFaqs: config.feature_faq || false,
    memories: config.feature_memory || false,
    citations: config.feature_citation || false,
    contactAttributes: config.feature_contact_attributes || false,
    orderCreation: config.feature_order_creation || false,
  };
};

const handleBasicInfoUpdate = async () => {
  const result = await Promise.all([
    v$.value.name.$validate(),
    v$.value.description.$validate(),
    v$.value.companyName.$validate(),
    v$.value.industry.$validate(),
    v$.value.coreProducts.$validate(),
  ]).then(results => results.every(Boolean));
  if (!result) return;

  const payload = {
    name: state.name,
    description: state.description,
    config: {
      ...props.assistant.config,
      company_name: state.companyName,
      industry: state.industry,
      core_products: state.coreProducts,
      feature_faq: state.features.conversationFaqs,
      feature_memory: state.features.memories,
      feature_citation: state.features.citations,
      feature_contact_attributes: state.features.contactAttributes,
      feature_order_creation: state.features.orderCreation,
    },
  };

  emit('submit', payload);
};

watch(
  () => props.assistant,
  newAssistant => {
    if (newAssistant) updateStateFromAssistant(newAssistant);
  },
  { immediate: true }
);
</script>

<template>
  <div class="flex flex-col gap-6">
    <Input
      v-model="state.name"
      :label="t('CAPTAIN.ASSISTANTS.FORM.NAME.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.NAME.PLACEHOLDER')"
      :message="formErrors.name"
      :message-type="formErrors.name ? 'error' : 'info'"
    />

    <Input
      v-model="state.companyName"
      :label="t('CAPTAIN.ASSISTANTS.FORM.COMPANY_NAME.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.COMPANY_NAME.PLACEHOLDER')"
      :message="formErrors.companyName"
      :message-type="formErrors.companyName ? 'error' : 'info'"
    />

    <Input
      v-model="state.industry"
      :label="t('CAPTAIN.ASSISTANTS.FORM.INDUSTRY.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.INDUSTRY.PLACEHOLDER')"
      :message="formErrors.industry"
      :message-type="formErrors.industry ? 'error' : 'info'"
    />

    <Input
      v-model="state.coreProducts"
      :label="t('CAPTAIN.ASSISTANTS.FORM.CORE_PRODUCTS.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.CORE_PRODUCTS.PLACEHOLDER')"
      :message="formErrors.coreProducts"
      :message-type="formErrors.coreProducts ? 'error' : 'info'"
    />

    <Editor
      v-model="state.description"
      :label="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.PLACEHOLDER')"
      :message="formErrors.description"
      :message-type="formErrors.description ? 'error' : 'info'"
      class="z-0"
    />

    <div class="flex flex-col gap-2">
      <label class="text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.TITLE') }}
      </label>
      <div class="flex flex-col gap-2">
        <label class="flex items-center gap-2">
          <input v-model="state.features.conversationFaqs" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CONVERSATION_FAQS') }}
        </label>
        <label class="flex items-center gap-2">
          <input v-model="state.features.memories" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_MEMORIES') }}
        </label>
        <label class="flex items-center gap-2">
          <input v-model="state.features.citations" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CITATIONS') }}
        </label>
        <label class="flex items-center gap-2">
          <input v-model="state.features.contactAttributes" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CONTACT_ATTRIBUTES') }}
        </label>
        <label class="flex items-center gap-2">
          <input v-model="state.features.orderCreation" type="checkbox" />
          Cho phép tạo đơn hàng
        </label>
      </div>
    </div>

    <div>
      <Button
        :label="t('CAPTAIN.ASSISTANTS.FORM.UPDATE')"
        @click="handleBasicInfoUpdate"
      />
    </div>
  </div>
</template>
