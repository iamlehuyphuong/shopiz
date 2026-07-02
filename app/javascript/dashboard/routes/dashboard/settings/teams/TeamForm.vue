<script>
import validations from './helpers/validations';
import FormInput from 'v3/components/Form/Input.vue';
import { reactive } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { ref } from 'vue';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
    FormInput,
  },
  props: {
    onSubmit: {
      type: Function,
      default: () => {},
    },
    submitInProgress: {
      type: Boolean,
      default: false,
    },
    formData: {
      type: Object,
      default: () => {},
    },
    submitButtonText: {
      type: String,
      default: '',
    },
  },
  setup(props) {
    const formData = props.formData || {};
    const {
      description = '',
      name: title = '',
      allow_auto_assign: allowAutoAssign = true,
    } = formData;

    const state = reactive({
      description,
      title,
      allowAutoAssign,
    });

    const rules = validations;
    const v$ = useVuelidate(rules, state);

    const { processEvent } = useCaptain();
    const isImproving = ref(false);

    const improveDescription = async () => {
      if (!state.description) return;
      isImproving.value = true;
      try {
        const { message } = await processEvent(
          'improve_team_description',
          state.description
        );
        if (message) {
          state.description = message;
        }
      } catch (error) {
        // Error is handled inside processEvent
      } finally {
        isImproving.value = false;
      }
    };

    return { state, v$, isImproving, improveDescription };
  },
  methods: {
    handleSubmit() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }
      this.onSubmit({
        description: this.state.description,
        name: this.state.title,
        allow_auto_assign: this.state.allowAutoAssign,
      });
    },
  },
};
</script>

<template>
  <div class="flex-shrink-0 w-full">
    <form class="mx-0 grid gap-4" @submit.prevent="handleSubmit">
      <FormInput
        v-model="state.title"
        name="title"
        spacing="compact"
        :label="$t('TEAMS_SETTINGS.FORM.NAME.LABEL')"
        :placeholder="$t('TEAMS_SETTINGS.FORM.NAME.PLACEHOLDER')"
        :has-error="v$.title.$error"
        :error-message="v$.title.$error ? v$.title.$errors[0].$message : ''"
        @blur="v$.title.$touch"
      />
      <div class="flex flex-col w-full gap-2">
        <FormInput
          v-model="state.description"
          name="description"
          spacing="compact"
          :label="$t('TEAMS_SETTINGS.FORM.DESCRIPTION.LABEL')"
          :placeholder="$t('TEAMS_SETTINGS.FORM.DESCRIPTION.PLACEHOLDER')"
          :has-error="v$.description.$error"
          :error-message="
            v$.description.$error ? v$.description.$errors[0].$message : ''
          "
          class="!mb-0"
          @blur="v$.description.$touch"
        />
        <div class="flex justify-start">
          <NextButton
            icon="i-lucide-wand-2"
            size="xs"
            color="slate"
            :label="$t('TEAMS_SETTINGS.FORM.IMPROVE_BY_AI', 'Improve by AI')"
            :is-loading="isImproving"
            @click.prevent="improveDescription"
          />
        </div>
      </div>
      <div class="w-full flex items-center gap-2">
        <input v-model="state.allowAutoAssign" type="checkbox" :value="true" />
        <label for="conversation_creation">
          {{ $t('TEAMS_SETTINGS.FORM.AUTO_ASSIGN.LABEL') }}
        </label>
      </div>
      <div class="flex flex-row justify-end gap-2 py-2 px-0 w-full">
        <div class="w-full">
          <NextButton
            type="submit"
            :label="submitButtonText"
            :disabled="v$.title.$invalid || submitInProgress"
            :is-loading="submitInProgress"
          />
        </div>
      </div>
    </form>
  </div>
</template>
