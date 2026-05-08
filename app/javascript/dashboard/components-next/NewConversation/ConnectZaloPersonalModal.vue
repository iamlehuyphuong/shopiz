<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import TextArea from 'next/textarea/TextArea.vue';

const props = defineProps({
  contactId: { type: [String, Number], required: true },
});

const emit = defineEmits(['close']);

const store = useStore();
const { t } = useI18n();

const showModal = ref(false);
const selectedInboxId = ref('');
const sendFriendRequest = ref(true);
const friendRequestMessage = ref('');
const greetingMessage = ref('');
const isSubmitting = ref(false);

const contact = computed(() => {
  return store.getters['contacts/getContact'](props.contactId);
});

const zaloPersonalInboxes = computed(() => {
  return store.getters['inboxes/getInboxes'].filter(
    inbox => inbox.channel_type === 'Channel::ZaloPersonal'
  );
});

const selectedInbox = computed(() => {
  return zaloPersonalInboxes.value.find(
    inbox => inbox.id === selectedInboxId.value
  );
});

watch(selectedInbox, newInbox => {
  if (newInbox) {
    friendRequestMessage.value =
      newInbox.provider_config?.default_friend_request_message || '';
    greetingMessage.value =
      newInbox.provider_config?.default_greeting_message || '';
  } else {
    friendRequestMessage.value = '';
    greetingMessage.value = '';
  }
});

const openModal = () => {
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
  emit('close');
};

const handleSubmit = async () => {
  if (!selectedInbox.value) {
    useAlert(t('CONTACT_PANEL.ZALO_PERSONAL.SELECT_INBOX_REQUIRED'));
    return;
  }

  isSubmitting.value = true;
  try {
    let conversationId = null;

    // 1. Send friend request if checked
    if (sendFriendRequest.value) {
      await store.dispatch('contactConversations/requestFriend', {
        params: {
          contactId: props.contactId,
          inboxId: selectedInbox.value.id,
          sourceId: props.phone,
          message: { content: friendRequestMessage.value },
        },
      });
    }

    // 2. Send greeting message (creates conversation or adds to existing)
    if (greetingMessage.value.trim()) {
      const messagePayload = {
        inbox_id: selectedInbox.value.id,
        contact_id: props.contactId,
        message: {
          content: greetingMessage.value,
        },
      };

      const response = await store.dispatch(
        'contactConversations/create',
        messagePayload
      );
      conversationId = response.id || response.conversation_id;
    }

    useAlert(t('CONTACT_PANEL.ZALO_PERSONAL.CONNECT_SUCCESS'));
    closeModal();

    if (conversationId) {
      window.location = `/app/accounts/${store.getters.getCurrentAccountId}/conversations/${conversationId}`;
    }
  } catch (error) {
    useAlert(t('CONTACT_PANEL.ZALO_PERSONAL.CONNECT_ERROR'));
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <div class="inline-block">
    <slot name="trigger" :toggle="openModal" />
    <woot-modal v-model:show="showModal" :on-close="closeModal">
      <div
        class="flex flex-col bg-white dark:bg-slate-900 rounded-xl overflow-hidden max-h-[90vh]"
      >
        <woot-modal-header
          :header-title="$t('CONTACT_PANEL.ZALO_PERSONAL.CONNECT_TITLE')"
          :header-content="$t('CONTACT_PANEL.ZALO_PERSONAL.CONNECT_SUBTITLE')"
        />
        <div class="flex-1 p-6 overflow-y-auto space-y-6">
          <!-- Inbox Selection -->
          <div class="space-y-2">
            <label
              class="text-sm font-medium text-slate-800 dark:text-slate-100"
            >
              {{ $t('CONTACT_PANEL.ZALO_PERSONAL.SELECT_INBOX') }}
            </label>
            <select
              v-model="selectedInboxId"
              class="w-full px-3 py-2 border rounded-md dark:bg-slate-800 dark:border-slate-700 dark:text-slate-200"
            >
              <option value="" disabled>
                {{ $t('CONTACT_PANEL.ZALO_PERSONAL.SELECT_INBOX_PLACEHOLDER') }}
              </option>
              <option
                v-for="inbox in zaloPersonalInboxes"
                :key="inbox.id"
                :value="inbox.id"
              >
                {{ inbox.name }}
              </option>
            </select>
          </div>

          <!-- Toggle Friend Request -->
          <div class="flex items-center space-x-2">
            <input
              id="sendFriendRequest"
              v-model="sendFriendRequest"
              type="checkbox"
              class="w-4 h-4 text-brand-500 border-slate-300 rounded focus:ring-brand-500"
            />
            <label
              for="sendFriendRequest"
              class="text-sm font-medium text-slate-800 dark:text-slate-100"
            >
              {{ $t('CONTACT_PANEL.ZALO_PERSONAL.SEND_FRIEND_REQUEST') }}
            </label>
          </div>

          <!-- Friend Request Message -->
          <div v-if="sendFriendRequest" class="space-y-2">
            <label
              class="text-sm font-medium text-slate-800 dark:text-slate-100"
            >
              {{ $t('CONTACT_PANEL.ZALO_PERSONAL.FRIEND_REQUEST_MESSAGE') }}
            </label>
            <TextArea
              v-model="friendRequestMessage"
              auto-height
              class="w-full"
            />
          </div>

          <!-- Greeting Message -->
          <div class="space-y-2">
            <label
              class="text-sm font-medium text-slate-800 dark:text-slate-100"
            >
              {{ $t('CONTACT_PANEL.ZALO_PERSONAL.GREETING_MESSAGE') }}
            </label>
            <TextArea v-model="greetingMessage" auto-height class="w-full" />
          </div>
        </div>

        <div
          class="p-6 border-t border-slate-100 dark:border-slate-800 flex justify-end gap-3"
        >
          <NextButton color="slate" variant="ghost" @click="closeModal">
            {{ $t('CONTACT_PANEL.ZALO_PERSONAL.CANCEL') }}
          </NextButton>
          <NextButton
            color="brand"
            :is-loading="isSubmitting"
            :disabled="
              !selectedInboxId ||
              (!greetingMessage.trim() &&
                !(sendFriendRequest && friendRequestMessage.trim()))
            "
            @click="handleSubmit"
          >
            {{ $t('CONTACT_PANEL.ZALO_PERSONAL.SUBMIT') }}
          </NextButton>
        </div>
      </div>
    </woot-modal>
  </div>
</template>
