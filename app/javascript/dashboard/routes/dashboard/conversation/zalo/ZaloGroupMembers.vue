<template>
  <div class="zalo-group-members">
    <div v-if="isLoading" class="p-3 text-center">
      <spinner />
    </div>
    <div v-else-if="members.length === 0" class="p-3 text-center text-slate-500">
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
            <span class="font-medium text-sm text-slate-900 dark:text-slate-100 truncate">{{ member.name }}</span>
            <span v-if="member.is_creator" class="px-1.5 py-0.5 text-[10px] font-semibold bg-n-orange-3 text-n-orange-11 rounded">Trưởng nhóm</span>
            <span v-else-if="member.is_admin" class="px-1.5 py-0.5 text-[10px] font-semibold bg-n-slate-3 text-n-slate-11 rounded">Phó nhóm</span>
          </div>
          <div class="text-xs text-slate-500 flex gap-2 mt-0.5">
            <span v-if="member.phone_number">{{ maskPhone(member.phone_number) }}</span>
            <span v-if="member.is_friend" class="text-green-600 flex items-center gap-0.5">
              <fluent-icon icon="checkmark-circle" size="12" /> Đã kết bạn
            </span>
            <span v-else class="flex items-center gap-0.5">
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
    />
  </div>
</template>

<script>
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Spinner from 'shared/components/Spinner.vue';
import ConnectZaloPersonalModal from 'dashboard/components-next/NewConversation/ConnectZaloPersonalModal.vue';

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
  data() {
    return {
      members: [],
      isLoading: false,
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
        const response = await window.axios.get(`/api/v1/accounts/${accountId}/conversations/${this.conversationId}/zalo_group_members`);
        this.members = response.data || [];
      } catch (error) {
        // ignore
      } finally {
        this.isLoading = false;
      }
    },
    maskPhone(phone) {
      if (!phone || phone.length < 8) return phone;
      const start = phone.substring(0, phone.length - 4);
      const end = phone.substring(phone.length - 2);
      return `${start}**${end}`;
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

<style scoped>
.zalo-group-members {
  max-height: 400px;
  overflow-y: auto;
}
</style>
