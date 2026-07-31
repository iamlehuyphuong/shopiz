<!-- eslint-disable vue/v-slot-style -->
<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useIntegrationHook } from 'dashboard/composables/useIntegrationHook';
import { FormKit } from '@formkit/vue';
import { useBranding } from 'shared/composables/useBranding';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    FormKit,
    NextButton,
  },
  props: {
    integrationId: {
      type: String,
      required: true,
    },
    hook: {
      type: Object,
      default: null,
    },
    inline: {
      type: Boolean,
      default: false,
    },
  },
  emits: ['close'],
  setup(props) {
    const { integration, isHookTypeInbox } = useIntegrationHook(
      props.integrationId
    );
    const { replaceInstallationName } = useBranding();

    return { integration, isHookTypeInbox, replaceInstallationName };
  },
  data() {
    return {
      endPoint: '',
      alertMessage: '',
      values: this.hook ? { ...this.hook.settings } : {},
      showPassword: {},
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'integrations/getUIFlags',
      dialogFlowEnabledInboxes: 'inboxes/dialogFlowEnabledInboxes',
    }),
    inboxes() {
      return this.dialogFlowEnabledInboxes
        .filter(inbox => {
          if (!this.isIntegrationDialogflow) {
            return true;
          }
          return !this.connectedDialogflowInboxIds.includes(inbox.id);
        })
        .map(inbox => ({ label: inbox.name, value: inbox.id }));
    },

    connectedDialogflowInboxIds() {
      if (!this.isIntegrationDialogflow) {
        return [];
      }
      return this.integration.hooks.map(item => item.inbox?.id);
    },
    formItems() {
      return this.integration.settings_form_schema.map(item => {
        let localizedItem = { ...item };
        const i18nPrefix = `INTEGRATION_APPS.${this.integration.id.toUpperCase()}.FORM.${item.name.toUpperCase()}`;

        if (this.$te(`${i18nPrefix}.LABEL`)) {
          localizedItem.label = this.$t(`${i18nPrefix}.LABEL`);
        }
        if (this.$te(`${i18nPrefix}.PLACEHOLDER`)) {
          localizedItem.placeholder = this.$t(`${i18nPrefix}.PLACEHOLDER`);
        }
        if (this.$te(`${i18nPrefix}.HELP`)) {
          localizedItem.help = this.$t(`${i18nPrefix}.HELP`);
        }

        if (localizedItem.type === 'password') {
          const isVisible = !!this.showPassword[localizedItem.name];
          return {
            ...localizedItem,
            type: isVisible ? 'text' : 'password',
            'suffix-icon': isVisible ? 'eyeClosed' : 'eye',
            'outer-class': 'password-input-wrapper',
            onSuffixIconClick: () => {
              this.showPassword[localizedItem.name] = !isVisible;
            },
          };
        }
        return localizedItem;
      });
    },
    isIntegrationDialogflow() {
      return this.integration.id === 'dialogflow';
    },
    isUpdating() {
      return !!this.hook;
    },
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    buildHookPayload() {
      const hookPayload = {
        app_id: this.integration.id,
        settings: {},
      };

      hookPayload.settings = Object.keys(this.values).reduce((acc, key) => {
        if (key !== 'inbox') {
          acc[key] = this.values[key];
        }
        return acc;
      }, {});

      this.formItems.forEach(item => {
        if (item.validation?.includes('JSON') && typeof hookPayload.settings[item.name] === 'string') {
          try {
            hookPayload.settings[item.name] = JSON.parse(
              hookPayload.settings[item.name]
            );
          } catch (e) {
            // ignore
          }
        }
      });

      if (this.isHookTypeInbox && this.values.inbox) {
        hookPayload.inbox_id = this.values.inbox;
      }

      return hookPayload;
    },
    async submitForm() {
      try {
        if (this.isUpdating) {
          await this.$store.dispatch('integrations/updateHook', {
            hookId: this.hook.id,
            hookData: this.buildHookPayload(),
          });
          this.alertMessage = this.$t('INTEGRATION_APPS.UPDATE.API.SUCCESS_MESSAGE', 'Cập nhật cấu hình thành công!');
        } else {
          await this.$store.dispatch(
            'integrations/createHook',
            this.buildHookPayload()
          );
          this.alertMessage = this.$t('INTEGRATION_APPS.ADD.API.SUCCESS_MESSAGE');
        }
        this.onClose();
      } catch (error) {
        const errorMessage = error?.response?.data?.message;
        this.alertMessage =
          errorMessage || this.$t('INTEGRATION_APPS.ADD.API.ERROR_MESSAGE');
      } finally {
        useAlert(this.alertMessage);
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto integration-hooks" :class="{ 'mt-4': inline }">
    <woot-modal-header
      v-if="!inline"
      :header-title="integration.name"
      :header-content="replaceInstallationName(integration.short_description)"
    />
    <FormKit
      v-model="values"
      type="form"
      form-class="w-full grid gap-4"
      :submit-attrs="{
        inputClass: 'hidden',
        wrapperClass: 'hidden',
      }"
      :incomplete-message="false"
      @submit="submitForm"
    >
      <FormKit v-for="item in formItems" :key="item.name" v-bind="item" />
      <FormKit
        v-if="isHookTypeInbox"
        :options="inboxes"
        type="select"
        name="inbox"
        input-class="reset-base"
        :placeholder="$t('INTEGRATION_APPS.ADD.FORM.INBOX.LABEL')"
        :label="$t('INTEGRATION_APPS.ADD.FORM.INBOX.PLACEHOLDER')"
        validation="required"
        validation-name="Inbox"
      />
      <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
        <NextButton
          v-if="!inline"
          faded
          slate
          type="reset"
          :label="$t('INTEGRATION_APPS.ADD.FORM.CANCEL')"
          @click.prevent="onClose"
        />
        <NextButton
          type="submit"
          :label="isUpdating ? $t('INTEGRATION_APPS.UPDATE.BUTTON_TEXT', 'Cập nhật') : $t('INTEGRATION_APPS.ADD.FORM.SUBMIT')"
          :is-loading="uiFlags.isCreatingHook || uiFlags.isUpdating"
        />
      </div>
    </FormKit>
  </div>
</template>

<style lang="css">
.formkit-outer {
  @apply mt-2;
}

.formkit-form > .formkit-wrapper > ul.formkit-messages {
  @apply hidden;
}

.formkit-form .formkit-help {
  @apply text-n-slate-10 text-sm font-normal mt-2 w-full;
}

/* equivalent of .reset-base */
.formkit-input {
  margin-bottom: 0px !important;
}

[data-invalid] .formkit-message {
  @apply text-n-ruby-9 block text-xs font-normal my-1 w-full;
}

.formkit-outer[data-type='checkbox'] .formkit-wrapper {
  @apply flex items-center gap-2 px-0.5;
}

.formkit-messages {
  @apply list-none m-0 p-0;
}

.formkit-actions {
  @apply hidden;
}

.password-input-wrapper .formkit-inner {
  @apply relative flex items-center w-full;
}

.password-input-wrapper .formkit-input {
  @apply w-full;
  padding-right: 2.5rem !important;
}

.password-input-wrapper .formkit-icon,
.password-input-wrapper .formkit-suffix-icon {
  @apply absolute right-2 w-5 h-5 flex items-center justify-center cursor-pointer text-slate-500;
}

.password-input-wrapper .formkit-icon svg,
.password-input-wrapper .formkit-suffix-icon svg {
  @apply w-full h-full;
}
</style>
