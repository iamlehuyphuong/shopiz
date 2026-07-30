<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter } from 'dashboard/composables/store';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import captainTasksAPI from 'dashboard/api/captain/tasks';
import { useAlert } from 'dashboard/composables';
import { ref } from 'vue';

const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: value => ['edit', 'create'].includes(value),
  },
  assistant: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();

const formState = {
  uiFlags: useMapGetter('captainAssistants/getUIFlags'),
};

const initialState = {
  name: '',
  description: '',
  productName: '',
  featureFaq: false,
  featureMemory: false,
  featureCitation: false,
};

const state = reactive({ ...initialState });

const validationRules = {
  name: { required, minLength: minLength(1) },
  description: { required, minLength: minLength(1) },
  productName: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(validationRules, state);

const isLoading = computed(() => formState.uiFlags.value.creatingItem);

const getErrorMessage = (field, errorKey) => {
  return v$.value[field].$error
    ? t(`CAPTAIN.ASSISTANTS.FORM.${errorKey}.ERROR`)
    : '';
};

const formErrors = computed(() => ({
  name: getErrorMessage('name', 'NAME'),
  description: getErrorMessage('description', 'DESCRIPTION'),
  productName: getErrorMessage('productName', 'PRODUCT_NAME'),
}));

const handleCancel = () => emit('cancel');

const prepareAssistantDetails = () => ({
  name: state.name,
  description: state.description,
  config: {
    product_name: state.productName,
    feature_faq: state.featureFaq,
    feature_memory: state.featureMemory,
    feature_citation: state.featureCitation,
  },
});

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) {
    return;
  }

  emit('submit', prepareAssistantDetails());
};

const updateStateFromAssistant = assistant => {
  if (!assistant) return;

  const { name, description, config } = assistant;

  Object.assign(state, {
    name,
    description,
    productName: config.product_name,
    featureFaq: config.feature_faq || false,
    featureMemory: config.feature_memory || false,
    featureCitation: config.feature_citation || false,
  });
};

watch(
  () => props.assistant,
  newAssistant => {
    if (props.mode === 'edit' && newAssistant) {
      updateStateFromAssistant(newAssistant);
    }
  },
  { immediate: true }
);

const applyTemplate = templateKey => {
  const templateText = t(
    `CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.TEMPLATES.${templateKey}_TEXT`
  );
  if (!state.description) {
    state.description = templateText;
  } else {
    state.description += `\n${templateText}`;
  }
};

const isImproving = ref(false);

const improveWithAI = async () => {
  if (!state.description) return;
  isImproving.value = true;
  try {
    const response = await captainTasksAPI.rewrite({
      operation: 'improve_assistant_description',
      content: state.description,
      context: {
        assistant_name: state.name,
        core_products: state.productName,
      }
    });
    if (response.data && response.data.message) {
      state.description = response.data.message;
    }
  } catch (error) {
    useAlert(t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.IMPROVE_AI_ERROR') || 'Error');
  } finally {
    isImproving.value = false;
  }
};
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <Input
      v-model="state.name"
      :label="t('CAPTAIN.ASSISTANTS.FORM.NAME.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.NAME.PLACEHOLDER')"
      :message="formErrors.name"
      :message-type="formErrors.name ? 'error' : 'info'"
    />

    <div class="flex flex-col gap-1.5">
      <Editor
        v-model="state.description"
        :label="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.LABEL')"
        :placeholder="t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.PLACEHOLDER')"
        :message="formErrors.description"
        :message-type="formErrors.description ? 'error' : 'info'"
        :max-length="1000"
      />
      <div class="flex items-center mt-3 mb-4">
        <button
          type="button"
          class="flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium transition-colors border rounded-md text-n-slate-11 border-n-strong bg-white hover:bg-n-alpha-1 hover:text-n-slate-12 shadow-sm"
          @click="improveWithAI"
          :disabled="isImproving || !state.description"
          :class="{ 'opacity-50 cursor-not-allowed': isImproving || !state.description }"
        >
          <Icon v-if="!isImproving" icon="i-lucide-wand-sparkles" class="w-4 h-4" />
          <Icon v-else icon="i-lucide-loader-2" class="w-4 h-4 animate-spin" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.IMPROVE_AI') || 'Cải thiện bằng AI' }}
        </button>
      </div>
      <div class="flex flex-wrap items-center gap-2">
        <span class="text-xs text-n-slate-11">
          {{ t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.TEMPLATES.TITLE') }}
        </span>
        <button
          v-for="i in 5"
          :key="i"
          type="button"
          class="px-2 py-1 text-xs font-medium transition-colors border rounded-md text-n-slate-11 border-n-weak bg-n-alpha-1 hover:bg-n-alpha-2 hover:text-n-slate-12"
          @click="applyTemplate(`TEMPLATE_${i}`)"
        >
          {{ t(`CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.TEMPLATES.TEMPLATE_${i}_LABEL`) }}
        </button>
      </div>
    </div>

    <Input
      v-model="state.productName"
      :label="t('CAPTAIN.ASSISTANTS.FORM.PRODUCT_NAME.LABEL')"
      :placeholder="t('CAPTAIN.ASSISTANTS.FORM.PRODUCT_NAME.PLACEHOLDER')"
      :message="formErrors.productName"
      :message-type="formErrors.productName ? 'error' : 'info'"
    />

    <fieldset class="flex flex-col gap-2.5">
      <legend class="mb-3 text-sm font-medium text-n-slate-12">
        {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.TITLE') }}
      </legend>

      <label class="flex items-center gap-2">
        <input v-model="state.featureFaq" type="checkbox" />
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CONVERSATION_FAQS') }}
        </span>
      </label>

      <label class="flex items-center gap-2">
        <input v-model="state.featureMemory" type="checkbox" />
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_MEMORIES') }}
        </span>
      </label>

      <label class="flex items-center gap-2">
        <input v-model="state.featureCitation" type="checkbox" />
        <span class="text-sm font-medium text-n-slate-12">
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CITATIONS') }}
        </span>
      </label>
    </fieldset>

    <div class="flex items-center justify-between w-full gap-3">
      <Button
        type="button"
        variant="faded"
        color="slate"
        :label="t('CAPTAIN.FORM.CANCEL')"
        class="w-full bg-n-alpha-2 text-n-orange-11 hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        type="submit"
        :label="t(`CAPTAIN.FORM.${mode.toUpperCase()}`)"
        class="w-full"
        :is-loading="isLoading"
        :disabled="isLoading"
      />
    </div>
  </form>
</template>
