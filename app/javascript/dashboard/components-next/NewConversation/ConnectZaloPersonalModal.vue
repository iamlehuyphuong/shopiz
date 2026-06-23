<script setup>
import { ref, computed, watch } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { useMessageFormatter } from 'shared/composables/useMessageFormatter';
import NextButton from 'dashboard/components-next/button/Button.vue';
import TextArea from 'next/textarea/TextArea.vue';
import { useRouter } from 'vue-router';

const props = defineProps({
  contactId: { type: [String, Number], required: true },
  phone: { type: String, default: '' },
  selectedInboxId: { type: [String, Number], required: true },
  initialFriendRequestMessage: { type: String, default: '' },
  initialGreetingMessage: { type: String, default: '' },
  zaloProfile: { type: Object, default: () => ({}) },
  show: { type: Boolean, default: false }
});

const emit = defineEmits(['close', 'update:show']);

const store = useStore();
const { t } = useI18n();
const router = useRouter();

const { checkPermissions } = usePolicy();
const maskContactInfo = computed(() => !checkPermissions(['contact_manage']));
const { getPlainText } = useMessageFormatter(maskContactInfo);

const sendFriendRequest = ref(true);
const friendRequestMessage = ref(props.initialFriendRequestMessage);
const greetingMessage = ref(props.initialGreetingMessage);
const isSubmitting = ref(false);

watch(
  () => props.initialFriendRequestMessage,
  (newVal) => { friendRequestMessage.value = newVal; }
);

watch(
  () => props.initialGreetingMessage,
  (newVal) => { greetingMessage.value = newVal; }
);

const closeModal = () => {
  emit('update:show', false);
  emit('close');
};

const handleSubmit = async () => {
  if (!props.selectedInboxId) {
    useAlert(t('CONTACT_PANEL.ZALO_PERSONAL.SELECT_INBOX_REQUIRED'));
    return;
  }

  isSubmitting.value = true;
  try {
    let conversationId = null;

    if (sendFriendRequest.value) {
      const friendResponse = await store.dispatch(
        'contactConversations/requestFriend',
        {
          params: {
            contactId: props.contactId,
            inboxId: props.selectedInboxId,
            sourceId: props.phone,
            message: { content: friendRequestMessage.value },
          },
        }
      );

      if (friendResponse && friendResponse.already_friend) {
        useAlert('Khách hàng này đã là bạn bè trên Zalo');
      }
    }

    if (greetingMessage.value.trim()) {
      const response = await store.dispatch('contactConversations/create', {
        params: {
          inboxId: props.selectedInboxId,
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
      router.push({
        path: `/app/accounts/${store.getters.getCurrentAccountId}/conversations/${conversationId}`,
      });
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
  <teleport to="body">
    <woot-modal :show="show" :on-close="closeModal" :show-close-button="false">
      <div class="flex flex-col h-auto w-full sm:w-[600px] max-w-full relative bg-white dark:bg-slate-800 rounded-xl overflow-hidden">
        <div class="px-6 py-4 flex items-center justify-between border-b border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 sticky top-0 z-20">
          <div class="text-lg font-semibold text-slate-900 dark:text-slate-50">Thông tin tài khoản</div>
          <NextButton
            ghost
            slate
            icon="i-lucide-x"
            class="!m-0 !p-1 -mr-2"
            @click.prevent="closeModal"
          />
        </div>

        <div class="relative bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700 pb-4">
          <div class="h-[140px] w-full">
            <img :src="zaloProfile.cover || 'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=600&h=200&fit=crop'" class="w-full h-full object-cover" />
          </div>
          <div class="flex items-end px-6 -mt-12 relative z-10">
            <div class="w-24 h-24 rounded-full border-4 border-white dark:border-slate-800 overflow-hidden bg-slate-200 dark:bg-slate-700 shrink-0">
              <img :src="zaloProfile.avatar || 'https://i.pravatar.cc/150?img=5'" class="w-full h-full object-cover" />
            </div>
            <div class="ml-4 pb-2">
              <h3 class="text-xl font-semibold text-slate-900 dark:text-slate-50 m-0 flex items-center gap-2">
                {{ zaloProfile.name || 'Người dùng Zalo' }}
              </h3>
            </div>
          </div>
        </div>

        <form class="!p-0 flex flex-col w-full mx-0" @submit.prevent="handleSubmit">
          <div class="px-6 py-4 bg-white dark:bg-slate-800">
            <h4 class="font-semibold text-base mb-4 text-slate-900 dark:text-slate-50">Thông tin cá nhân</h4>
            <div class="grid grid-cols-[100px_1fr] gap-x-2 gap-y-3 text-sm">
              <div class="text-slate-500 dark:text-slate-400">Bio</div>
              <div class="text-slate-900 dark:text-slate-100 whitespace-pre-line">{{ zaloProfile.bio || 'Chưa cập nhật' }}</div>

              <div class="text-slate-500 dark:text-slate-400">Giới tính</div>
              <div class="text-slate-900 dark:text-slate-100">{{ zaloProfile.gender || 'Chưa cập nhật' }}</div>

              <div class="text-slate-500 dark:text-slate-400">Ngày sinh</div>
              <div class="text-slate-900 dark:text-slate-100">{{ zaloProfile.dob || 'Chưa cập nhật' }}</div>
            </div>
          </div>

          <div class="px-6 py-4 border-t border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800">
            <div class="flex items-center w-full gap-2 mb-4">
              <input id="sendFriendRequest" v-model="sendFriendRequest" type="checkbox" />
              <label for="sendFriendRequest" class="mb-0 text-sm font-medium text-slate-900 dark:text-slate-100">
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
          </div>

          <div class="flex items-center justify-end w-full gap-2 px-6 py-4 bg-white dark:bg-slate-800 border-t border-slate-200 dark:border-slate-700">
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
              :disabled="!greetingMessage.trim() && !(sendFriendRequest && friendRequestMessage.trim())"
              :label="$t('CONTACT_PANEL.ZALO_PERSONAL.SUBMIT')"
            />
          </div>
        </form>
      </div>
    </woot-modal>
  </teleport>
</template>
