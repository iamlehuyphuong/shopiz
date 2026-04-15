<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { useStore } from 'dashboard/composables/store';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import SettingsAccordion from 'dashboard/components-next/Settings/SettingsAccordion.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const hideComments = ref(false);
const hideNoPhoneComments = ref(false);
const hideNoEmailComments = ref(false);
const autoReplyToComments = ref(false);
const autoReplyMessage = ref('');
const isUpdating = ref(false);

const providerConfig = computed(
  () => props.inbox.provider_config || {}
);

onMounted(() => {
  syncSettings();
});

function syncSettings() {
  const config = providerConfig.value;
  hideComments.value = toBool(config.hide_comments);
  hideNoPhoneComments.value = toBool(config.hide_no_phone_comments);
  hideNoEmailComments.value = toBool(config.hide_no_email_comments);
  autoReplyToComments.value = toBool(config.auto_reply_to_comments);
  autoReplyMessage.value = config.auto_reply_message || '';
}

function toBool(val) {
  if (typeof val === 'boolean') return val;
  if (typeof val === 'string') return val === 'true';
  return false;
}

async function updateSettings() {
  isUpdating.value = true;
  try {
    await store.dispatch('inboxes/updateInbox', {
      id: props.inbox.id,
      formData: false,
      channel: {
        provider_config: {
          hide_comments: hideComments.value,
          hide_no_phone_comments: hideNoPhoneComments.value,
          hide_no_email_comments: hideNoEmailComments.value,
          auto_reply_to_comments: autoReplyToComments.value,
          auto_reply_message: autoReplyMessage.value,
        },
      },
    });
    useAlert(t('INBOX_MGMT.POSTS_AND_COMMENTS.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(
      error.message ||
        t('INBOX_MGMT.POSTS_AND_COMMENTS.API.ERROR_MESSAGE')
    );
  } finally {
    isUpdating.value = false;
  }
}
</script>

<template>
  <div class="max-w-4xl mx-6">
    <div class="flex flex-col gap-1 mb-6">
      <h3 class="text-heading-2 text-n-slate-12">
        {{ $t('INBOX_MGMT.POSTS_AND_COMMENTS.TITLE') }}
      </h3>
      <p class="text-sm text-n-slate-11">
        {{ $t('INBOX_MGMT.POSTS_AND_COMMENTS.DESCRIPTION') }}
      </p>
    </div>

    <!-- Comment Moderation Section -->
    <SettingsAccordion
      :title="$t('INBOX_MGMT.POSTS_AND_COMMENTS.COMMENT_MODERATION.TITLE')"
      class="mb-4"
    >
      <p class="text-sm text-n-slate-11 mb-4">
        {{
          $t(
            'INBOX_MGMT.POSTS_AND_COMMENTS.COMMENT_MODERATION.DESCRIPTION'
          )
        }}
      </p>

      <SettingsToggleSection
        v-model="hideComments"
        :header="
          $t('INBOX_MGMT.POSTS_AND_COMMENTS.COMMENT_MODERATION.HIDE_ALL')
        "
        :description="
          $t(
            'INBOX_MGMT.POSTS_AND_COMMENTS.COMMENT_MODERATION.HIDE_ALL_HELP'
          )
        "
      />

      <SettingsToggleSection
        v-model="hideNoPhoneComments"
        :disabled="hideComments"
        :header="
          $t(
            'INBOX_MGMT.POSTS_AND_COMMENTS.COMMENT_MODERATION.HIDE_NO_PHONE'
          )
        "
        :description="
          $t(
            'INBOX_MGMT.POSTS_AND_COMMENTS.COMMENT_MODERATION.HIDE_NO_PHONE_HELP'
          )
        "
      />

      <SettingsToggleSection
        v-model="hideNoEmailComments"
        :disabled="hideComments"
        :header="
          $t(
            'INBOX_MGMT.POSTS_AND_COMMENTS.COMMENT_MODERATION.HIDE_NO_EMAIL'
          )
        "
        :description="
          $t(
            'INBOX_MGMT.POSTS_AND_COMMENTS.COMMENT_MODERATION.HIDE_NO_EMAIL_HELP'
          )
        "
      />
    </SettingsAccordion>

    <!-- Auto Reply Section -->
    <SettingsAccordion
      :title="$t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.TITLE')"
      class="mb-4"
    >
      <p class="text-sm text-n-slate-11 mb-4">
        {{ $t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.DESCRIPTION') }}
      </p>

      <SettingsToggleSection
        v-model="autoReplyToComments"
        :header="
          $t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.ENABLE')
        "
        :description="
          $t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.ENABLE_HELP')
        "
      />

      <SettingsFieldSection
        v-if="autoReplyToComments"
        :label="
          $t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.MESSAGE_LABEL')
        "
        class="[&>div]:!items-start [&>div>label]:mt-1 mt-4"
      >
        <textarea
          v-model="autoReplyMessage"
          class="w-full min-h-[100px] rounded-lg border border-n-weak p-3 text-sm text-n-slate-12 bg-n-alpha-white placeholder:text-n-slate-9 focus:outline-none focus:ring-2 focus:ring-n-blue-9"
          :placeholder="
            $t(
              'INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.MESSAGE_PLACEHOLDER'
            )
          "
          rows="4"
        />
      </SettingsFieldSection>

      <p
        v-if="autoReplyToComments"
        class="text-xs text-n-slate-10 mt-2"
      >
        {{ $t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.NOTE') }}
      </p>
    </SettingsAccordion>

    <!-- Save Button -->
    <div class="w-full flex justify-end items-center py-4 mt-2">
      <NextButton
        type="submit"
        :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
        :is-loading="isUpdating"
        @click="updateSettings"
      />
    </div>
  </div>
</template>
