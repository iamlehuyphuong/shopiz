<script>
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Spinner from 'shared/components/Spinner.vue';
import ConnectZaloPersonalModal from 'dashboard/components-next/NewConversation/ConnectZaloPersonalModal.vue';
import { usePolicy } from 'dashboard/composables/usePolicy';
import { computed } from 'vue';

export default {
  name: 'ZaloGroupMembers',
  components: {
    Avatar,
    Spinner,
    ConnectZaloPersonalModal,
  },
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
    conversationInboxId: {
      type: [Number, String],
      required: true,
    },
  },
  setup() {
    const { checkPermissions } = usePolicy();
    const canManageContacts = computed(() =>
      checkPermissions(['contact_manage'])
    );
    return { canManageContacts };
  },
  data() {
    return {
      members: [],
      isLoading: false,
      isSyncing: false,
      showConnectModal: false,
      selectedMember: null,
    };
  },
  watch: {
    conversationId: {
      handler() {
        this.fetchMembers();
      },
    },
  },
  mounted() {
    this.fetchMembers();
  },
  methods: {
    async fetchMembers() {
      this.isLoading = true;
      try {
        const accountId = this.$route.params.accountId;
        const response = await window.axios.get(
          `/api/v1/accounts/${accountId}/conversations/${this.conversationId}/zalo_group_members`
        );
        this.members = this.processMembers(response.data);
      } catch (error) {
        // ignore
      } finally {
        this.isLoading = false;
      }
    },
    async syncMembers() {
      this.isSyncing = true;
      try {
        const accountId = this.$route.params.accountId;
        const response = await window.axios.post(
          `/api/v1/accounts/${accountId}/conversations/${this.conversationId}/zalo_group_members/sync`
        );
        this.members = this.processMembers(response.data);
      } catch (error) {
        // ignore
      } finally {
        this.isSyncing = false;
      }
    },
    processMembers(data) {
      if (!data) return [];
      return data.sort((a, b) => {
        if (a.is_you !== b.is_you) return a.is_you ? -1 : 1;
        if (a.is_creator !== b.is_creator) return a.is_creator ? -1 : 1;
        if (a.is_admin !== b.is_admin) return a.is_admin ? -1 : 1;
        const nameA = a.name || '';
        const nameB = b.name || '';
        return nameA.localeCompare(nameB);
      });
    },
    maskPhone(phone) {
      if (this.canManageContacts) return phone;
      if (!phone || phone.length < 8) return phone;
      const start = phone.substring(0, phone.length - 6);
      const end = phone.substring(phone.length - 2);
      return `${start}****${end}`;
    },
    openConnectModal(member) {
      this.selectedMember = member;
      this.showConnectModal = true;
    },
    formattedZaloProfile(member) {
      return {
        userId: member.uid,
        name: member.name,
        avatar: member.avatar,
        bio: member.bio,
        gender: member.gender,
        dob: member.dob,
        cover: member.cover,
      };
    },
  },
};
</script>

<template>
  <div class="zalo-group-members relative flex flex-col h-full">
    <div
      class="sticky top-0 bg-white dark:bg-slate-900 z-10 px-3 py-2 border-b border-slate-50 dark:border-slate-800 flex justify-between items-center"
    >
      <div class="text-sm font-medium text-slate-800 dark:text-slate-100">
        Danh sách thành viên ({{ members.length }})
      </div>
      <button
        class="flex items-center gap-1 text-xs px-2 py-1 bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-200 rounded transition-colors"
        :disabled="isSyncing || isLoading"
        @click="syncMembers"
      >
        <Spinner v-if="isSyncing" size="small" />
        <fluent-icon v-else icon="arrow-clockwise" size="14" />
        Đồng bộ
      </button>
    </div>
    <div v-if="isLoading" class="p-3 text-center">
      <Spinner />
    </div>
    <div
      v-else-if="members.length === 0"
      class="p-3 text-center text-slate-500"
    >
      Không có thành viên nào
    </div>
    <div v-else class="members-list">
      <div
        v-for="member in members"
        :key="member.uid"
        class="member-item flex items-center p-3 border-b border-slate-50 dark:border-slate-800 cursor-pointer hover:bg-slate-50 dark:hover:bg-slate-800"
        @click="openConnectModal(member)"
      >
        <Avatar
          :src="member.avatar"
          :name="member.name"
          :size="32"
          class="mr-2"
        />
        <div class="member-info flex-1 min-w-0">
          <div class="flex items-center gap-1">
            <span
              class="font-medium text-sm text-slate-900 dark:text-slate-100 truncate"
              >{{ member.name }}</span
            >
            <span
              v-if="member.is_you"
              class="px-1.5 py-0.5 text-[10px] font-semibold bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400 rounded whitespace-nowrap"
              >Bạn</span
            >
            <span
              v-if="member.is_creator"
              class="px-1.5 py-0.5 text-[10px] font-semibold bg-n-orange-3 text-n-orange-11 rounded whitespace-nowrap"
              >Trưởng nhóm</span
            >
            <span
              v-else-if="member.is_admin"
              class="px-1.5 py-0.5 text-[10px] font-semibold bg-n-slate-3 text-n-slate-11 rounded whitespace-nowrap"
              >Phó nhóm</span
            >
          </div>
          <div class="text-xs text-slate-500 flex gap-2 mt-0.5">
            <span v-if="member.phone_number">{{
              maskPhone(member.phone_number)
            }}</span>
            <span
              v-if="member.is_friend"
              class="text-green-600 flex items-center gap-0.5"
            >
              <fluent-icon icon="checkmark-circle" size="12" /> Đã kết bạn
            </span>
            <span v-else-if="!member.is_you" class="flex items-center gap-0.5">
              Chưa kết bạn
            </span>
          </div>
        </div>
      </div>
    </div>

    <ConnectZaloPersonalModal
      v-if="showConnectModal"
      v-model:show="showConnectModal"
      :contact-id="String(selectedMember.contact_id || '')"
      :phone="selectedMember.phone_number"
      :selected-inbox-id="conversationInboxId"
      :zalo-profile="formattedZaloProfile(selectedMember)"
      :is-friend="selectedMember.is_friend"
      :is-you="selectedMember.is_you"
    />
  </div>
</template>

<style scoped>
.zalo-group-members {
  max-height: 400px;
  overflow-y: auto;
}
</style>
