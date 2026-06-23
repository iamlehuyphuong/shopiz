<script>
import { MESSAGE_TYPE } from 'widget/helpers/constants';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import { ATTACHMENT_ICONS } from 'shared/constants/messages';
import { usePolicy } from 'dashboard/composables/usePolicy';

export default {
  name: 'MessagePreview',
  props: {
    message: {
      type: Object,
      required: true,
    },
    conversation: {
      type: Object,
      default: () => ({}),
    },
    showMessageType: {
      type: Boolean,
      default: true,
    },
    defaultEmptyMessage: {
      type: String,
      default: '',
    },
  },
  setup() {
    const { checkPermissions } = usePolicy();
    const maskContactInfo = !checkPermissions(['contact_manage']);
    const { getPlainText } = useMessageFormatter(maskContactInfo);
    return {
      getPlainText,
    };
  },
  computed: {
    shouldShowCallStatus() {
      // Always show call status for voice channels if present
      return (
        this.conversation?.meta?.channel === 'Channel::Voice' &&
        !!this.conversation?.additional_attributes?.call_status
      );
    },
    messageByAgent() {
      const { message_type: messageType } = this.message;
      return messageType === MESSAGE_TYPE.OUTGOING;
    },
    isMessageAnActivity() {
      const { message_type: messageType } = this.message;
      return messageType === MESSAGE_TYPE.ACTIVITY;
    },
    isMessagePrivate() {
      const { private: isPrivate } = this.message;
      return isPrivate;
    },
    // Simple check: Is this a voice channel conversation?
    isVoiceChannel() {
      return this.conversation?.meta?.channel === 'Channel::Voice';
    },
    // Check if this is a voice call message
    isVoiceCall() {
      return this.message?.content_type === 'voice_call';
    },
    // Get call direction for voice calls
    isIncomingCall() {
      if (!this.isVoiceChannel) return false;

      // First check conversation attributes
      const direction =
        this.conversation?.additional_attributes?.call_direction;
      if (direction) {
        return direction === 'inbound';
      }
    },
    // Get normalized call status
    callStatus() {
      if (!this.isVoiceChannel) return null;

      // Get raw status from conversation
      const status = this.conversation?.additional_attributes?.call_status;

      // Map status to normalized values
      if (status === 'in-progress') return 'active';
      if (status === 'completed') return 'ended';
      if (status === 'canceled') return 'ended';
      if (status === 'failed') return 'ended';
      if (status === 'busy') return 'no-answer';
      if (status === 'no-answer')
        return this.isIncomingCall ? 'missed' : 'no-answer';

      // Return explicit status values as-is
      if (status === 'active') return 'active';
      if (status === 'missed') return 'missed';
      if (status === 'ended') return 'ended';
      if (status === 'ringing') return 'ringing';

      // Default status
      return 'active';
    },
    // Voice call icon based on status
    voiceCallIcon() {
      if (!this.isVoiceChannel) return null;

      const status = this.callStatus;
      const isIncoming = this.isIncomingCall;

      if (status === 'missed' || status === 'no-answer') {
        return 'phone-missed-call';
      }

      if (status === 'active') {
        return 'phone-in-talk';
      }

      if (status === 'ended') {
        return isIncoming ? 'phone-incoming' : 'phone-outgoing';
      }

      if (status === 'ringing') {
        return isIncoming ? 'phone-incoming' : 'phone-outgoing';
      }

      // Default based on direction
      return isIncoming ? 'phone-incoming' : 'phone-outgoing';
    },
    parsedLastMessage() {
      // For voice calls, return status text
      if (this.isVoiceChannel) {
        // Get status-based text
        const status = this.callStatus;
        const isIncoming = this.isIncomingCall;

        // Return appropriate status text based on call status and direction
        if (status === 'active') {
          // return last message content if message is not activity and not voice call
          if (!this.isMessageAnActivity && !this.isVoiceCall) {
            return this.getPlainText(this.message.content);
          }
          return this.$t('CONVERSATION.VOICE_CALL.CALL_IN_PROGRESS');
        }

        if (isIncoming) {
          if (status === 'ringing') {
            return this.$t('CONVERSATION.VOICE_CALL.INCOMING_CALL');
          }

          if (status === 'missed') {
            return this.$t('CONVERSATION.VOICE_CALL.MISSED_CALL');
          }

          if (status === 'ended') {
            return this.$t('CONVERSATION.VOICE_CALL.CALL_ENDED');
          }
        } else {
          if (status === 'ringing') {
            return this.$t('CONVERSATION.VOICE_CALL.OUTGOING_CALL');
          }

          if (status === 'no-answer') {
            return this.$t('CONVERSATION.VOICE_CALL.NO_ANSWER');
          }

          if (status === 'ended') {
            return this.$t('CONVERSATION.VOICE_CALL.CALL_ENDED');
          }
        }

        // Default fallback based on direction
        return isIncoming
          ? this.$t('CONVERSATION.VOICE_CALL.INCOMING_CALL')
          : this.$t('CONVERSATION.VOICE_CALL.OUTGOING_CALL');
      }

      // Default behavior for non-voice calls
      const { content_attributes: contentAttributes } = this.message;
      const { email: { subject } = {} } = contentAttributes || {};
      return this.getPlainText(subject || this.message.content);
    },
    lastMessageFileType() {
      const [{ file_type: fileType } = {}] = this.message.attachments;
      return fileType;
    },
    attachmentIcon() {
      return ATTACHMENT_ICONS[this.lastMessageFileType];
    },
    attachmentMessageContent() {
      return `CHAT_LIST.ATTACHMENTS.${this.lastMessageFileType}.CONTENT`;
    },
    isMessageSticker() {
      return this.message && this.message.content_type === 'sticker';
    },
    isMessageDeleted() {
      return (
        this.message?.content_attributes?.deleted ||
        this.message?.content_attributes?.undo
      );
    },
  },
};
</script>

<template>
  <div class="overflow-hidden text-ellipsis whitespace-nowrap">
    <template v-if="showMessageType">
      <fluent-icon
        v-if="isMessagePrivate"
        size="16"
        class="-mt-0.5 align-middle text-n-slate-11 inline-block"
        icon="lock-closed"
      />
      <fluent-icon
        v-else-if="messageByAgent"
        size="16"
        class="-mt-0.5 align-middle text-n-slate-11 inline-block"
        icon="arrow-reply"
      />
      <fluent-icon
        v-else-if="isMessageAnActivity"
        size="16"
        class="-mt-0.5 align-middle text-n-slate-11 inline-block"
        icon="info"
      />
    </template>
    <span
      v-if="message.content && isMessageSticker"
      :class="{ 'line-through opacity-60': isMessageDeleted }"
    >
      <fluent-icon
        size="16"
        class="-mt-0.5 align-middle inline-block text-n-slate-11"
        icon="image"
      />
      {{ $t('CHAT_LIST.ATTACHMENTS.image.CONTENT') }}
    </span>
    <span
      v-else-if="message.content"
      :class="{ 'line-through opacity-60': isMessageDeleted }"
    >
      {{ parsedLastMessage }}
    </span>
    <span
      v-else-if="message.attachments"
      :class="{ 'line-through opacity-60': isMessageDeleted }"
    >
      <fluent-icon
        v-if="attachmentIcon && showMessageType"
        size="16"
        class="-mt-0.5 align-middle inline-block text-n-slate-11"
        :icon="attachmentIcon"
      />
      {{ $t(`${attachmentMessageContent}`) }}
    </span>
    <span v-else :class="{ 'line-through opacity-60': isMessageDeleted }">
      {{ defaultEmptyMessage || $t('CHAT_LIST.NO_CONTENT') }}
    </span>
  </div>
</template>
