<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';
import TextArea from 'next/textarea/TextArea.vue';

const props = defineProps({
  contactId: { type: [String, Number], required: true },
  phone: { type: String, default: '' },
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
      const response = await store.dispatch('contactConversations/create', {
        params: {
          inboxId: selectedInbox.value.id,
          contactId: props.contactId,
          sourceId: props.phone,
          message: {
            content: greetingMessage.value,
          },
        },
      });
      conversationId = response.id || response.conversation_id;
    }

    useAlert(t('CONTACT_PANEL.ZALO_PERSONAL.CONNECT_SUCCESS'));
    closeModal();

    if (conversationId) {
      window.location = `/app/accounts/${store.getters.getCurrentAccountId}/conversations/${conversationId}`;
    }
  } catch (error) {
    const errorMessage =
      error?.response?.data?.message ||
      error?.response?.data?.error ||
      'Số điện thoại đã thuộc liên hệ khác';
    useAlert(errorMessage);
  } finally {
    isSubmitting.value = false;
  }
};
</script>

<template>
  <div class="inline-block">
    <slot name="trigger" :toggle="openModal" />
    <woot-modal v-model:show="showModal" :on-close="closeModal">
      <div class="flex flex-col h-auto overflow-auto">
        <woot-modal-header
          :header-title="$t('CONTACT_PANEL.ZALO_PERSONAL.CONNECT_TITLE')"
          :header-content="$t('CONTACT_PANEL.ZALO_PERSONAL.CONNECT_SUBTITLE')"
        />
        <form class="flex flex-wrap mx-0" @submit.prevent="handleSubmit">
          <div class="w-full mb-4">
            <label>
              {{ $t('CONTACT_PANEL.ZALO_PERSONAL.SELECT_INBOX') }}
              <select v-model="selectedInboxId">
                <option value="" disabled>
                  {{
                    $t('CONTACT_PANEL.ZALO_PERSONAL.SELECT_INBOX_PLACEHOLDER')
                  }}
                </option>
                <option
                  v-for="inbox in zaloPersonalInboxes"
                  :key="inbox.id"
                  :value="inbox.id"
                >
                  {{ inbox.name }}
                </option>
              </select>
            </label>
          </div>

          <div class="flex items-center w-full gap-2 mb-4">
            <input
              id="sendFriendRequest"
              v-model="sendFriendRequest"
              type="checkbox"
            />
            <label for="sendFriendRequest" class="mb-0">
              {{ $t('CONTACT_PANEL.ZALO_PERSONAL.SEND_FRIEND_REQUEST') }}
            </label>
          </div>

          <div v-if="sendFriendRequest" class="w-full mb-4">
            <TextArea
              v-model="friendRequestMessage"
              :label="$t('CONTACT_PANEL.ZALO_PERSONAL.FRIEND_REQUEST_MESSAGE')"
              auto-height
            />
          </div>

          <div class="w-full mb-4">
            <TextArea
              v-model="greetingMessage"
              :label="$t('CONTACT_PANEL.ZALO_PERSONAL.GREETING_MESSAGE')"
              auto-height
            />
          </div>

          <div class="flex items-center justify-end w-full gap-2 px-0 py-2">
            <NextButton
              faded
              slate
              type="reset"
              :label="$t('CONTACT_PANEL.ZALO_PERSONAL.CANCEL')"
              @click.prevent="closeModal"
            />
            <NextButton
              type="submit"
              :is-loading="isSubmitting"
              :disabled="
                !selectedInboxId ||
                (!greetingMessage.trim() &&
                  !(sendFriendRequest && friendRequestMessage.trim()))
              "
              :label="$t('CONTACT_PANEL.ZALO_PERSONAL.SUBMIT')"
            />
          </div>
        </form>
      </div>
    </woot-modal>
  </div>
</template>
