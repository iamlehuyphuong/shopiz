<script setup>
import { ref, computed, onMounted, watch } from 'vue';
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
const hidePhoneComments = ref(false);
const hideEmailComments = ref(false);
const autoReplyToComments = ref(false);
const autoPublicReplyToComments = ref(false);
const autoReplyUseAi = ref(false);
const autoReplyMessage = ref('');
const autoReplyAiPrompt = ref('');
const isUpdating = ref(false);

const providerConfig = computed(() => props.inbox.provider_config || {});
const isTiktokChannel = computed(
  () => props.inbox.channel_type === 'Channel::Tiktok'
);
const supportsCommentModeration = computed(() => !isTiktokChannel.value);

// When "hide all" is toggled on, force-off the granular rules
watch(hideComments, newVal => {
  if (newVal) {
    hidePhoneComments.value = false;
    hideEmailComments.value = false;
  }
});

onMounted(() => {
  syncSettings();
});

function syncSettings() {
  const config = providerConfig.value;
  hideComments.value = toBool(config.hide_comments);
  hidePhoneComments.value = toBool(config.hide_phone_comments);
  hideEmailComments.value = toBool(config.hide_email_comments);
  autoReplyToComments.value = toBool(config.auto_reply_to_comments);
  autoPublicReplyToComments.value = toBool(config.auto_public_reply_to_comments);
  autoReplyUseAi.value = toBool(config.auto_reply_use_ai);
  autoReplyMessage.value = config.auto_reply_message || '';
  autoReplyAiPrompt.value = config.auto_reply_ai_prompt || '';
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
          ...(supportsCommentModeration.value
            ? {
                hide_comments: hideComments.value,
                hide_phone_comments: hidePhoneComments.value,
                hide_email_comments: hideEmailComments.value,
              }
            : {}),
          auto_reply_to_comments: autoReplyToComments.value,
          auto_public_reply_to_comments: autoPublicReplyToComments.value,
          auto_reply_use_ai: autoReplyUseAi.value,
          auto_reply_message: autoReplyMessage.value,
          auto_reply_ai_prompt: autoReplyAiPrompt.value,
        },
      },
    });
    useAlert(t('INBOX_MGMT.POSTS_AND_COMMENTS.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(
      error.message || t('INBOX_MGMT.POSTS_AND_COMMENTS.API.ERROR_MESSAGE')
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

    <!-- Comment Moderation Section (not available for TikTok) -->
    <SettingsAccordion
      v-if="supportsCommentModeration"
      :title="$t('INBOX_MGMT.POSTS_AND_COMMENTS.COMMENT_MODERATION.TITLE')"
    >
      <p class="text-sm text-n-slate-11 mb-4">
        {{ $t('INBOX_MGMT.POSTS_AND_COMMENTS.COMMENT_MODERATION.DESCRIPTION') }}
      </p>

      <SettingsToggleSection
        v-model="hideComments"
        :header="
          $t('INBOX_MGMT.POSTS_AND_COMMENTS.COMMENT_MODERATION.HIDE_ALL')
        "
        :description="
          $t('INBOX_MGMT.POSTS_AND_COMMENTS.COMMENT_MODERATION.HIDE_ALL_HELP')
        "
      />

      <div :class="{ 'opacity-50 pointer-events-none': hideComments }">
        <SettingsToggleSection
          v-model="hidePhoneComments"
          :header="
            $t('INBOX_MGMT.POSTS_AND_COMMENTS.COMMENT_MODERATION.HIDE_PHONE')
          "
          :description="
            $t(
              'INBOX_MGMT.POSTS_AND_COMMENTS.COMMENT_MODERATION.HIDE_PHONE_HELP'
            )
          "
        />
      </div>

      <div :class="{ 'opacity-50 pointer-events-none': hideComments }">
        <SettingsToggleSection
          v-model="hideEmailComments"
          :header="
            $t('INBOX_MGMT.POSTS_AND_COMMENTS.COMMENT_MODERATION.HIDE_EMAIL')
          "
          :description="
            $t(
              'INBOX_MGMT.POSTS_AND_COMMENTS.COMMENT_MODERATION.HIDE_EMAIL_HELP'
            )
          "
        />
      </div>
    </SettingsAccordion>

    <!-- Auto Reply Section -->
    <SettingsAccordion
      :title="$t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.TITLE')"
    >
      <p class="text-sm text-n-slate-11 mb-4">
        {{ $t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.DESCRIPTION') }}
      </p>

      <SettingsToggleSection
        v-model="autoReplyToComments"
        :header="$t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.ENABLE_PRIVATE')"
        :description="
          $t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.ENABLE_PRIVATE_HELP')
        "
      />

      <SettingsToggleSection
        v-model="autoPublicReplyToComments"
        :header="$t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.ENABLE_PUBLIC')"
        :description="
          $t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.ENABLE_PUBLIC_HELP')
        "
      />

      <template v-if="autoReplyToComments || autoPublicReplyToComments">
        <SettingsToggleSection
          v-model="autoReplyUseAi"
          :header="$t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.USE_AI')"
          :description="
            $t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.USE_AI_HELP')
          "
        />

        <SettingsFieldSection
          v-if="autoReplyUseAi"
          :label="
            $t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.AI_PROMPT_LABEL')
          "
        >
          <textarea
            v-model="autoReplyAiPrompt"
            class="w-full min-h-[100px] rounded-lg border border-n-weak p-3 text-sm text-n-slate-12 bg-n-alpha-white placeholder:text-n-slate-9 focus:outline-none focus:ring-0 focus-visible:ring-2 focus-visible:ring-n-orange-9 resize-y"
            :placeholder="
              $t(
                'INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.AI_PROMPT_PLACEHOLDER'
              )
            "
            rows="4"
          />
        </SettingsFieldSection>

        <SettingsFieldSection
          v-else
          :label="$t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.MESSAGE_LABEL')"
        >
          <textarea
            v-model="autoReplyMessage"
            class="w-full min-h-[100px] rounded-lg border border-n-weak p-3 text-sm text-n-slate-12 bg-n-alpha-white placeholder:text-n-slate-9 focus:outline-none focus:ring-0 focus-visible:ring-2 focus-visible:ring-n-orange-9 resize-y"
            :placeholder="
              $t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.MESSAGE_PLACEHOLDER')
            "
            rows="4"
          />
        </SettingsFieldSection>

        <p class="text-xs text-n-slate-10 mt-2 italic">
          {{ $t('INBOX_MGMT.POSTS_AND_COMMENTS.AUTO_REPLY.NOTE') }}
        </p>
      </template>
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
