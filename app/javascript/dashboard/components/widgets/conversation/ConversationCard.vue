<script setup>
import { computed, ref, watch } from 'vue';
import { useRouter } from 'vue-router';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { getLastMessage } from 'dashboard/helper/conversationHelper';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';
import Avatar from 'next/avatar/Avatar.vue';
import MessagePreview from './MessagePreview.vue';
import InboxName from '../InboxName.vue';
import ConversationContextMenu from './contextMenu/Index.vue';
import TimeAgo from 'dashboard/components/ui/TimeAgo.vue';
import CardLabels from './conversationCardComponents/CardLabels.vue';
import PriorityMark from './PriorityMark.vue';
import SLACardLabel from './components/SLACardLabel.vue';
import ContextMenu from 'dashboard/components/ui/ContextMenu.vue';

const props = defineProps({
  activeLabel: { type: String, default: '' },
  chat: { type: Object, default: () => ({}) },
  hideInboxName: { type: Boolean, default: false },
  hideThumbnail: { type: Boolean, default: false },
  teamId: { type: [String, Number], default: 0 },
  foldersId: { type: [String, Number], default: 0 },
  showAssignee: { type: Boolean, default: false },
  conversationType: { type: String, default: '' },
  selected: { type: Boolean, default: false },
  compact: { type: Boolean, default: false },
  enableContextMenu: { type: Boolean, default: false },
  allowedContextMenuOptions: { type: Array, default: () => [] },
});

const emit = defineEmits([
  'contextMenuToggle',
  'assignAgent',
  'assignLabel',
  'removeLabel',
  'assignTeam',
  'markAsUnread',
  'markAsRead',
  'assignPriority',
  'updateConversationStatus',
  'deleteConversation',
  'selectConversation',
  'deSelectConversation',
]);

const router = useRouter();
const store = useStore();

const hovered = ref(false);
const showContextMenu = ref(false);
const contextMenu = ref({ x: null, y: null });

// Reset UI state when conversation changes at same index (no :key, instance reused on reorder)
// This prevents context menu/hover state from leaking to a different conversation
// Emit contextMenuToggle(false) to sync parent state if menu was open during recycling
const resetState = () => {
  if (showContextMenu.value) {
    emit('contextMenuToggle', false);
  }
  hovered.value = false;
  showContextMenu.value = false;
  contextMenu.value = { x: null, y: null };
};

watch(() => props.chat.id, resetState);

const currentChat = useMapGetter('getSelectedChat');
const inboxesList = useMapGetter('inboxes/getInboxes');
const activeInbox = useMapGetter('getSelectedInbox');
const accountId = useMapGetter('getCurrentAccountId');

const chatMetadata = computed(() => props.chat.meta || {});

const assignee = computed(() => chatMetadata.value.assignee || {});

const senderId = computed(() => chatMetadata.value.sender?.id);

const currentContact = computed(() => {
  return senderId.value
    ? store.getters['contacts/getContact'](senderId.value)
    : {};
});

const isActiveChat = computed(() => {
  return currentChat.value.id === props.chat.id;
});

const unreadCount = computed(() => props.chat.unread_count);

const hasUnread = computed(() => unreadCount.value > 0);

const isInboxNameVisible = computed(() => !activeInbox.value);

const lastMessageInChat = computed(() => getLastMessage(props.chat));

const inboxId = computed(() => props.chat.inbox_id);

const inbox = computed(() => {
  return inboxId.value ? store.getters['inboxes/getInbox'](inboxId.value) : {};
});

const showInboxName = computed(() => {
  return (
    !props.hideInboxName &&
    isInboxNameVisible.value &&
    inboxesList.value.length > 1
  );
});

const showMetaSection = computed(() => {
  return (
    showInboxName.value ||
    (props.showAssignee && assignee.value.name) ||
    props.chat.priority
  );
});

const hasSlaPolicyId = computed(() => props.chat?.sla_policy_id);

const showLabelsSection = computed(() => {
  return props.chat.labels?.length > 0 || hasSlaPolicyId.value;
});

const isAutoFollowUpActive = computed(() => {
  const autoFollowUpConfig = inbox.value?.auto_follow_up_config;
  if (!autoFollowUpConfig?.enabled) return false;

  const isCancelled = [true, 'true'].includes(
    props.chat.custom_attributes?.auto_follow_up_cancelled
  );
  if (isCancelled) return false;

  const isBotPending =
    props.chat.status === 'pending' &&
    props.chat.meta?.assignee_type === 'AgentBot';
  if (!['open', 'snoozed'].includes(props.chat.status) && !isBotPending)
    return false;

  const lastMsg = props.chat.last_non_activity_message;
  // 1 is OUTGOING
  if (!lastMsg || lastMsg.message_type !== 1) return false;

  const maxAttempts = autoFollowUpConfig.max_attempts || 1;
  const currentCount = props.chat.custom_attributes?.auto_follow_up_count || 0;

  return currentCount < maxAttempts;
});

const canRestoreAutoFollowUp = computed(() => {
  const autoFollowUpConfig = inbox.value?.auto_follow_up_config;
  if (!autoFollowUpConfig?.enabled) return false;

  const isCancelled = [true, 'true'].includes(
    props.chat.custom_attributes?.auto_follow_up_cancelled
  );
  return isCancelled;
});

const autoFollowUpTextParams = computed(() => {
  const currentCount = props.chat.custom_attributes?.auto_follow_up_count || 0;
  const maxAttempts = inbox.value?.auto_follow_up_config?.max_attempts || 1;
  return { currentCount, maxAttempts };
});

const messagePreviewClass = computed(() => {
  return [
    hasUnread.value ? 'font-medium text-n-slate-12' : 'text-n-slate-11',
    !props.compact && hasUnread.value ? 'ltr:pr-4 rtl:pl-4' : '',
    props.compact && hasUnread.value ? 'ltr:pr-6 rtl:pl-6' : '',
  ];
});

const conversationPath = computed(() => {
  return frontendURL(
    conversationUrl({
      accountId: accountId.value,
      activeInbox: activeInbox.value,
      id: props.chat.id,
      label: props.activeLabel,
      teamId: props.teamId,
      conversationType: props.conversationType,
      foldersId: props.foldersId,
    })
  );
});

const onCardClick = e => {
  const path = conversationPath.value;
  if (!path) return;

  // Handle Ctrl/Cmd + Click for new tab
  if (e.metaKey || e.ctrlKey) {
    e.preventDefault();
    window.open(
      `${window.shopizConfig.hostURL}${path}`,
      '_blank',
      'noopener,noreferrer'
    );
    return;
  }

  // Skip if already active
  if (isActiveChat.value) return;

  router.push({ path });
};

const onThumbnailHover = () => {
  hovered.value = !props.hideThumbnail;
};

const onThumbnailLeave = () => {
  hovered.value = false;
};

const onSelectConversation = checked => {
  if (checked) {
    emit('selectConversation', props.chat.id, inbox.value.id);
  } else {
    emit('deSelectConversation', props.chat.id, inbox.value.id);
  }
};

const openContextMenu = e => {
  if (!props.enableContextMenu) return;
  e.preventDefault();
  emit('contextMenuToggle', true);
  contextMenu.value.x = e.pageX || e.clientX;
  contextMenu.value.y = e.pageY || e.clientY;
  showContextMenu.value = true;
};

const closeContextMenu = () => {
  emit('contextMenuToggle', false);
  showContextMenu.value = false;
  contextMenu.value.x = null;
  contextMenu.value.y = null;
};

const cancelAutoFollowUp = async () => {
  closeContextMenu();
  try {
    await store.dispatch('conversations/updateCustomAttributes', {
      conversationId: props.chat.id,
      customAttributes: {
        ...props.chat.custom_attributes,
        auto_follow_up_cancelled: true,
      },
    });
  } catch (error) {
    // Ignore error
  }
};

const restoreAutoFollowUp = async () => {
  closeContextMenu();
  try {
    await store.dispatch('conversations/updateCustomAttributes', {
      conversationId: props.chat.id,
      customAttributes: {
        ...props.chat.custom_attributes,
        auto_follow_up_cancelled: false,
      },
    });
  } catch (error) {
    // Ignore error
  }
};

const onUpdateConversation = (status, snoozedUntil) => {
  closeContextMenu();
  emit('updateConversationStatus', props.chat.id, status, snoozedUntil);
};

const onAssignAgent = agent => {
  emit('assignAgent', agent, [props.chat.id]);
  closeContextMenu();
};

const onAssignLabel = label => {
  emit('assignLabel', [label.title], [props.chat.id]);
};

const onRemoveLabel = label => {
  emit('removeLabel', [label.title], [props.chat.id]);
};

const onAssignTeam = team => {
  emit('assignTeam', team, props.chat.id);
  closeContextMenu();
};

const markAsUnread = () => {
  emit('markAsUnread', props.chat.id);
  closeContextMenu();
};

const markAsRead = () => {
  emit('markAsRead', props.chat.id);
  closeContextMenu();
};

const assignPriority = priority => {
  emit('assignPriority', priority, props.chat.id);
  closeContextMenu();
};

const deleteConversation = () => {
  emit('deleteConversation', props.chat.id);
  closeContextMenu();
};
</script>

<template>
  <div
    class="relative flex items-start flex-grow-0 flex-shrink-0 w-auto max-w-full py-0 border-t-0 border-b-0 border-l-0 border-r-0 border-transparent border-solid cursor-pointer conversation hover:bg-n-alpha-1 dark:hover:bg-n-alpha-3 group"
    :class="{
      'active animate-card-select bg-n-background border-n-weak': isActiveChat,
      'bg-n-slate-2': selected,
      'px-0': compact,
      'px-3': !compact,
    }"
    @click="onCardClick"
    @contextmenu="openContextMenu($event)"
  >
    <div
      class="relative"
      @mouseenter="onThumbnailHover"
      @mouseleave="onThumbnailLeave"
    >
      <Avatar
        v-if="!hideThumbnail"
        :name="chat?.additional_attributes?.group?.name ?? currentContact.name"
        :src="
          chat?.additional_attributes?.group?.avt ?? currentContact.thumbnail
        "
        :size="32"
        :status="currentContact.availability_status"
        :class="!showInboxName ? 'mt-4' : 'mt-8'"
        hide-offline-status
        branded
      >
        <template #overlay="{ size }">
          <label
            v-if="hovered || selected"
            class="flex items-center justify-center rounded-full cursor-pointer absolute inset-0 z-10 backdrop-blur-[2px]"
            :style="{ width: `${size}px`, height: `${size}px` }"
            @click.stop
          >
            <input
              :value="selected"
              :checked="selected"
              class="!m-0 cursor-pointer"
              type="checkbox"
              @change="onSelectConversation($event.target.checked)"
            />
          </label>
        </template>
      </Avatar>
    </div>
    <div
      class="px-0 py-3 border-b group-hover:border-transparent flex-1 border-n-slate-3 min-w-0"
    >
      <div
        v-if="showMetaSection"
        class="flex items-center min-w-0 gap-1"
        :class="{
          'ltr:ml-2 rtl:mr-2': !compact,
          'mx-2': compact,
        }"
      >
        <InboxName v-if="showInboxName" :inbox="inbox" class="flex-1 min-w-0" />
        <div
          class="flex items-center gap-2 flex-shrink-0"
          :class="{
            'flex-1 justify-between': !showInboxName,
          }"
        >
          <span
            v-if="showAssignee && assignee.name"
            class="text-n-slate-11 text-xs font-medium leading-3 py-0.5 px-0 inline-flex items-center truncate"
          >
            <fluent-icon icon="person" size="12" class="text-n-slate-11" />
            {{ assignee.name }}
          </span>
          <PriorityMark :priority="chat.priority" class="flex-shrink-0" />
        </div>
      </div>
      <div class="flex gap-2 ltr:ml-2 rtl:mr-2 mt-1 items-center">
        <span
          class="conversation--status text-white text-xxs font-medium leading-4 py-1 px-2 rounded-full border border-solid border-n-strong text-n-slate-10 bg-n-slate-1 text-ellipsis overflow-hidden whitespace-nowrap"
          :class="chat.status"
        >
          {{
            $t(`CHAT_LIST.CHAT_STATUS_FILTER_ITEMS.${props.chat.status}.TEXT`)
          }}
        </span>
        <span
          v-if="isAutoFollowUpActive"
          class="text-xxs font-medium leading-4 py-1 px-2 rounded-full border border-solid border-n-orange text-n-orange-11 bg-n-orange-2 text-ellipsis overflow-hidden whitespace-nowrap"
        >
          {{ $t('CHAT_LIST.AUTO_FOLLOW_UP_BADGE', autoFollowUpTextParams) }}
        </span>
        <div
          v-if="currentContact.phone_number"
          class="inline-flex items-center justify-center size-6 bg-n-orange rounded-full"
        >
          <span class="i-lucide-phone text-white size-3" />
        </div>
        <div
          v-if="currentContact.email"
          class="inline-flex items-center justify-center size-6 bg-n-orange rounded-full"
        >
          <span class="i-lucide-mail text-white size-3" />
        </div>
      </div>
      <div class="flex items-center gap-2">
        <h4
          class="conversation--title my-0 mx-2 capitalize pt-0.5 max-w-[96%] text-ellipsis overflow-hidden whitespace-nowrap min-w-0 text-n-slate-12"
          :class="hasUnread ? 'font-semibold' : 'font-medium'"
        >
          {{ chat?.additional_attributes?.group?.name || currentContact.name }}
        </h4>
      </div>
      <MessagePreview
        v-if="lastMessageInChat"
        key="message-preview"
        :message="lastMessageInChat"
        class="my-0 mx-2 leading-6 h-6 flex-1 min-w-0 text-sm"
        :class="messagePreviewClass"
      />
      <p
        v-else
        key="no-messages"
        class="text-n-slate-11 text-sm my-0 mx-2 leading-6 h-6 flex-1 min-w-0 overflow-hidden text-ellipsis whitespace-nowrap"
        :class="messagePreviewClass"
      >
        <fluent-icon
          size="16"
          class="-mt-0.5 align-middle inline-block text-n-slate-10"
          icon="info"
        />
        <span class="mx-0.5">
          {{ $t(`CHAT_LIST.NO_MESSAGES`) }}
        </span>
      </p>
      <div
        class="absolute flex flex-col ltr:right-3 rtl:left-3"
        :class="showMetaSection ? 'top-8' : 'top-4'"
      >
        <span class="ml-auto font-normal leading-4 text-xxs">
          <TimeAgo
            :last-activity-timestamp="chat.timestamp"
            :created-at-timestamp="chat.created_at"
            :conversation-id="chat.id"
          />
        </span>
        <span
          class="shadow-lg rounded-full text-xxs font-semibold h-4 leading-4 ltr:ml-auto rtl:mr-auto mt-1 min-w-[1rem] px-1 py-0 text-center text-white bg-n-teal-9"
          :class="hasUnread ? 'block' : 'hidden'"
        >
          {{ unreadCount > 9 ? '9+' : unreadCount }}
        </span>
      </div>
      <CardLabels
        v-if="showLabelsSection"
        :conversation-labels="chat.labels"
        class="mt-0.5 mx-2 mb-0"
      >
        <template v-if="hasSlaPolicyId" #before>
          <SLACardLabel :chat="chat" class="ltr:mr-1 rtl:ml-1" />
        </template>
      </CardLabels>
    </div>
    <ContextMenu
      v-if="showContextMenu"
      :x="contextMenu.x"
      :y="contextMenu.y"
      @close="closeContextMenu"
    >
      <ConversationContextMenu
        :status="chat.status"
        :inbox-id="inbox.id"
        :priority="chat.priority"
        :chat-id="chat.id"
        :has-unread-messages="hasUnread"
        :conversation-labels="chat.labels"
        :conversation-url="conversationPath"
        :allowed-options="allowedContextMenuOptions"
        :is-followup-active="isAutoFollowUpActive"
        :is-followup-cancelled="canRestoreAutoFollowUp"
        @update-conversation="onUpdateConversation"
        @assign-agent="onAssignAgent"
        @assign-label="onAssignLabel"
        @remove-label="onRemoveLabel"
        @assign-team="onAssignTeam"
        @mark-as-unread="markAsUnread"
        @mark-as-read="markAsRead"
        @assign-priority="assignPriority"
        @delete-conversation="deleteConversation"
        @cancel-followup="cancelAutoFollowUp"
        @restore-followup="restoreAutoFollowUp"
        @close="closeContextMenu"
      />
    </ContextMenu>
  </div>
</template>

<style lang="scss" scoped>
.conversation--status {
  &.bot {
    background-color: #e06720;
  }
  &.open {
    @apply bg-n-teal-10;
  }
  &.pending {
    @apply bg-n-slate-10;
  }
  &.resolved {
    @apply bg-[#5b5bd6];
  }
  &.snoozed {
    @apply bg-n-ruby-10;
  }
}
</style>
