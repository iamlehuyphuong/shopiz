<script setup>
import { reactive, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';

import Input from 'dashboard/components-next/input/Input.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import captainTasksAPI from 'dashboard/api/captain/tasks';
import { useAlert } from 'dashboard/composables';
import { ref } from 'vue';

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
  features: {
    conversationFaqs: false,
    memories: false,
    contactAttributes: false,
    orderCreation: false,
  },
};

const state = reactive({ ...initialState });

const validationRules = {
  name: { required, minLength: minLength(1) },
  description: { required, minLength: minLength(1) },
};

const v$ = useVuelidate(validationRules, state);

const getErrorMessage = field => {
  return v$.value[field].$error ? v$.value[field].$errors[0].$message : '';
};

const formErrors = computed(() => ({
  name: getErrorMessage('name'),
  description: getErrorMessage('description'),
}));

const updateStateFromAssistant = assistant => {
  const { config = {} } = assistant;
  state.name = assistant.name;
  state.description = assistant.description;
  state.features = {
    conversationFaqs: config.feature_faq || false,
    memories: config.feature_memory || false,
    contactAttributes: config.feature_contact_attributes || false,
    orderCreation: config.feature_order_creation || false,
  };
};

const handleBasicInfoUpdate = async () => {
  const result = await Promise.all([
    v$.value.name.$validate(),
    v$.value.description.$validate(),
  ]).then(results => results.every(Boolean));
  if (!result) return;

  const payload = {
    name: state.name,
    description: state.description,
    config: {
      ...props.assistant.config,
      feature_faq: state.features.conversationFaqs,
      feature_memory: state.features.memories,
      feature_contact_attributes: state.features.contactAttributes,
      feature_order_creation: state.features.orderCreation,
    },
  };

  emit('submit', payload);
};

const applyTemplate = templateKey => {
  state.description = t(
    `CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.TEMPLATES.${templateKey}_TEXT`
  );
};

watch(
  () => props.assistant,
  newAssistant => {
    if (newAssistant) updateStateFromAssistant(newAssistant);
  },
  { immediate: true }
);

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
      },
    });
    if (response.data && response.data.message) {
      state.description = response.data.message;
    }
  } catch (error) {
    useAlert(
      t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.IMPROVE_AI_ERROR') || 'Error'
    );
  } finally {
    isImproving.value = false;
  }
};
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

    <div class="flex flex-col gap-1.5 z-0">
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
          :disabled="isImproving || !state.description"
          :class="{
            'opacity-50 cursor-not-allowed': isImproving || !state.description,
          }"
          @click="improveWithAI"
        >
          <Icon
            v-if="!isImproving"
            icon="i-lucide-wand-sparkles"
            class="w-4 h-4"
          />
          <Icon v-else icon="i-lucide-loader-2" class="w-4 h-4 animate-spin" />
          {{
            t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.IMPROVE_AI') ||
            'Cải thiện bằng AI'
          }}
        </button>
      </div>

      <div class="flex flex-wrap items-center gap-2">
        <span class="text-xs text-n-slate-11">
          {{ t('CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.TEMPLATES.TITLE') }}
        </span>
        <button
          v-for="i in 6"
          :key="i"
          type="button"
          class="px-2 py-1 text-xs font-medium transition-colors border rounded-md text-n-slate-11 border-n-weak bg-n-alpha-1 hover:bg-n-alpha-2 hover:text-n-slate-12"
          @click="applyTemplate(`TEMPLATE_${i}`)"
        >
          {{
            t(
              `CAPTAIN.ASSISTANTS.FORM.DESCRIPTION.TEMPLATES.TEMPLATE_${i}_LABEL`
            )
          }}
        </button>
      </div>
    </div>

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
          <input v-model="state.features.contactAttributes" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_CONTACT_ATTRIBUTES') }}
        </label>
        <label class="flex items-center gap-2">
          <input v-model="state.features.orderCreation" type="checkbox" />
          {{ t('CAPTAIN.ASSISTANTS.FORM.FEATURES.ALLOW_ORDER_CREATION') }}
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
