<script>
import { computed } from 'vue';
import { mapGetters } from 'vuex';
import { format, parseISO, isValid } from 'date-fns';
import { useAlert } from 'dashboard/composables';
import { dynamicTime } from 'shared/helpers/timeHelper';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { usePolicy } from 'dashboard/composables/usePolicy';
import MessageFormatter from 'shared/helpers/MessageFormatter';
import ContactInfoRow from './ContactInfoRow.vue';
import Avatar from 'next/avatar/Avatar.vue';
import SocialIcons from './SocialIcons.vue';
import EditContact from './EditContact.vue';
import ContactMergeModal from 'dashboard/modules/contact/ContactMergeModal.vue';
import ConnectZaloPersonalModal from 'dashboard/components-next/NewConversation/ConnectZaloPersonalModal.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import NextButton from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import zalopersonalChannel from 'dashboard/api/channel/zalopersonalChannel';
import inboxMixin, { INBOX_FEATURES } from 'shared/mixins/inboxMixin';
import { useOmicall } from 'dashboard/composables/useOmicall';

import {
  isAConversationRoute,
  isAInboxViewRoute,
  getConversationDashboardRoute,
} from '../../../../helper/routeHelpers';
import { emitter } from 'shared/helpers/mitt';
import { frontendURL, conversationUrl } from 'dashboard/helper/URLHelper';

export default {
  components: {
    NextButton,
    ContactInfoRow,
    EditContact,
    Avatar,
    ConnectZaloPersonalModal,
    ComposeConversation,
    SocialIcons,
    ContactMergeModal,
    DropdownMenu,
  },
  mixins: [inboxMixin],
  props: {
    contact: {
      type: Object,
      default: () => ({}),
    },
    showAvatar: {
      type: Boolean,
      default: true,
    },
  },
  emits: ['panelClose'],
  setup() {
    const { isAdmin } = useAdmin();
    const { checkPermissions } = usePolicy();
    const maskContactInfo = computed(
      () => !checkPermissions(['contact_manage'])
    );
    const {
      makeCall: makeOmicallCall,
      isReady: isOmicallReady,
      isOmicallConfigured,
    } = useOmicall();

    return {
      isAdmin,
      maskContactInfo,
      makeOmicallCall,
      isOmicallReady,
      isOmicallConfigured,
    };
  },
  data() {
    return {
      showEditModal: false,
      showDeleteModal: false,
      showZaloDropdown: false,
      showZaloConnectModal: false,
      isFetchingZaloUser: false,
      zaloProfileData: {},
      selectedZaloInboxId: null,
      initialZaloFriendMessage: '',
      initialZaloGreetingMessage: '',
      isDescriptionExpanded: false,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
    }),
    contactProfileLink() {
      return `/app/accounts/${this.$route.params.accountId}/contacts/${this.contact.id}`;
    },
    formattedBirthday() {
      const birthday = this.contact.birthday;
      if (!birthday) return '';

      const date = parseISO(birthday);
      return isValid(date) ? format(date, 'dd-MM-yyyy') : '';
    },
    additionalAttributes() {
      return this.contact.additional_attributes || {};
    },
    location() {
      const {
        country = '',
        city = '',
        country_code: countryCode,
      } = this.additionalAttributes;
      const cityAndCountry = [city, country].filter(item => !!item).join(', ');

      if (!cityAndCountry) {
        return '';
      }
      return this.findCountryFlag(countryCode, cityAndCountry);
    },
    socialProfiles() {
      const {
        social_profiles: socialProfiles,
        screen_name: twitterScreenName,
        social_telegram_user_name: telegramUsername,
      } = this.additionalAttributes;

      const telegram = socialProfiles?.telegram || telegramUsername || '';
      const twitter = socialProfiles?.twitter || twitterScreenName || '';

      return {
        ...(socialProfiles || {}),
        twitter,
        telegram,
      };
    },
    // Delete Modal
    confirmDeleteMessage() {
      return ` ${this.contact.name}?`;
    },
    currentConversation() {
      return this.$store.getters.getSelectedChat;
    },
    isCurrentConversationZaloPersonal() {
      if (!this.currentConversation) return false;
      const inbox = this.$store.getters['inboxes/getInbox'](
        this.currentConversation.inbox_id
      );
      return inbox?.channel_type === 'Channel::ZaloPersonal';
    },
    isZaloGroupConversation() {
      if (!this.isCurrentConversationZaloPersonal) return false;
      const type = this.currentConversation.additional_attributes?.type;
      return (
        type === 1 || !!this.currentConversation.additional_attributes?.group
      );
    },
    zaloGroupInfo() {
      if (!this.isZaloGroupConversation) return null;
      return this.currentConversation.additional_attributes?.group || null;
    },
    zaloFriendshipStatus() {
      if (!this.currentConversation) return false;

      const friendInboxIds =
        this.contact.additional_attributes?.zalo_friend_inbox_ids || [];
      return friendInboxIds.includes(this.currentConversation.inbox_id);
    },
    hasZaloPersonalInboxes() {
      return this.$store.getters['inboxes/getInboxes'].some(
        inbox => inbox.channel_type === 'Channel::ZaloPersonal'
      );
    },
    zaloPersonalInboxes() {
      return this.$store.getters['inboxes/getInboxes'].filter(
        inbox => inbox.channel_type === 'Channel::ZaloPersonal'
      );
    },
    zaloDropdownItems() {
      return this.zaloPersonalInboxes.map(inbox => ({
        label: inbox.name,
        value: inbox.id,
        action: 'select_zalo_inbox',
      }));
    },
    omicallLogoUrl() {
      return '/dashboard/images/integrations/omicall.png';
    },
    omicallLogoDarkUrl() {
      return '/dashboard/images/integrations/omicall-dark.png';
    },
  },
  watch: {
    'contact.id': {
      handler(id) {
        this.$store.dispatch('contacts/fetchContactableInbox', id);
      },
      immediate: true,
    },
  },
  methods: {
    getPlainText(text) {
      if (!text) return '';
      const formatter = new MessageFormatter(
        text,
        false, // isAPrivateNote
        true, // linkify
        this.maskContactInfo
      );
      return formatter.plainText;
    },
    dynamicTime,
    toggleEditModal() {
      this.showEditModal = !this.showEditModal;
    },
    openComposeConversationModal() {
      this.showZaloConnectModal = true;
      // Flag to prevent triggering drag n drop,
      // When compose modal is active
      emitter.emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, true);
    },
    closeComposeConversationModal() {
      this.showZaloConnectModal = false;
      // Flag to enable drag n drop,
      // When compose modal is closed
      emitter.emit(BUS_EVENTS.NEW_CONVERSATION_MODAL, false);
    },
    async handleOmicallButtonClick() {
      if (!this.isOmicallConfigured) {
        const isConfirmed =
          await this.$refs.confirmConnectPbxDialog.showConfirmation();
        if (isConfirmed) {
          window.open(
            `/app/accounts/${this.$route.params.accountId}/settings/integrations/omicall`,
            '_blank'
          );
        }
        return;
      }
      const isConfirmed = await this.$refs.confirmCallDialog.showConfirmation();
      if (isConfirmed) {
        this.makeOmicallCall(this.contact.phone_number);
      }
    },
    handleZaloButtonClick() {
      if (this.zaloPersonalInboxes.length === 1) {
        this.handleZaloDropdownAction({
          action: 'select_zalo_inbox',
          value: this.zaloPersonalInboxes[0].id,
        });
      } else if (this.zaloPersonalInboxes.length > 1) {
        this.showZaloDropdown = !this.showZaloDropdown;
      }
    },
    async handleZaloDropdownAction(item) {
      this.showZaloDropdown = false;
      if (item.action === 'select_zalo_inbox') {
        const inboxId = item.value;
        this.selectedZaloInboxId = inboxId;

        const inbox = this.zaloPersonalInboxes.find(i => i.id === inboxId);
        if (inbox) {
          this.initialZaloFriendMessage =
            inbox.provider_config?.default_friend_request_message || '';
          this.initialZaloGreetingMessage =
            inbox.provider_config?.default_greeting_message || '';
        }

        try {
          this.isFetchingZaloUser = true;
          const response = await zalopersonalChannel.findUser({
            phone: this.contact.phone_number,
            inboxId: inboxId,
          });
          const data = response.data?.data || response.data;

          if (data && data.name) {
            this.zaloProfileData = {
              name: data.name,
              avatar: data.avatar,
              cover: data.cover,
              bio: data.bio,
              gender: data.gender,
              dob: data.dob,
            };
            this.openComposeConversationModal();
          } else {
            useAlert('Số điện thoại chưa đăng ký hoặc không cho phép tìm kiếm');
          }
        } catch (error) {
          useAlert('Số điện thoại chưa đăng ký hoặc không cho phép tìm kiếm');
        } finally {
          this.isFetchingZaloUser = false;
        }
      }
    },
    toggleDeleteModal() {
      this.showDeleteModal = !this.showDeleteModal;
    },
    confirmDeletion() {
      this.deleteContact(this.contact);
      this.closeDelete();
    },
    closeDelete() {
      this.showDeleteModal = false;
      this.showEditModal = false;
    },
    findCountryFlag(countryCode, cityAndCountry) {
      try {
        if (!countryCode) {
          return `${cityAndCountry} 🌎`;
        }

        const code = countryCode?.toLowerCase();
        return `${cityAndCountry} <span class="fi fi-${code} size-3.5"></span>`;
      } catch (error) {
        return '';
      }
    },
    async deleteContact({ id }) {
      try {
        await this.$store.dispatch('contacts/delete', id);
        this.$emit('panelClose');
        useAlert(this.$t('DELETE_CONTACT.API.SUCCESS_MESSAGE'));

        if (isAConversationRoute(this.$route.name)) {
          this.$router.push({
            name: getConversationDashboardRoute(this.$route.name),
          });
        } else if (isAInboxViewRoute(this.$route.name)) {
          this.$router.push({
            name: 'inbox_view',
          });
        } else if (this.$route.name !== 'contacts_dashboard') {
          this.$router.push({
            name: 'contacts_dashboard',
          });
        }
      } catch (error) {
        useAlert(
          error.message
            ? error.message
            : this.$t('DELETE_CONTACT.API.ERROR_MESSAGE')
        );
      }
    },
    openMergeModal() {
      this.$refs.mergeModal?.open();
    },
    async handleDuplicatePhoneMerge(existingContactId) {
      this.toggleEditModal();
      try {
        await this.$store.dispatch('contacts/merge', {
          childId: this.contact.id,
          parentId: existingContactId,
        });
        useAlert(this.$t('MERGE_CONTACTS.FORM.SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(this.$t('MERGE_CONTACTS.FORM.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<template>
  <div class="relative items-center w-full p-4">
    <div class="flex flex-col w-full gap-2 text-left rtl:text-right">
      <div class="flex flex-row justify-between">
        <Avatar
          v-if="showAvatar"
          :src="
            contact.thumbnail ||
            (zaloGroupInfo && (zaloGroupInfo.avatar || zaloGroupInfo.avt)) ||
            ''
          "
          :name="contact.name"
          :status="contact.availability_status"
          :size="48"
          hide-offline-status
          branded
        />
      </div>

      <div class="flex flex-col items-start gap-1.5 min-w-0 w-full">
        <div v-if="showAvatar" class="flex items-center w-full min-w-0 gap-3">
          <h3
            class="flex-shrink max-w-full min-w-0 my-0 text-base capitalize break-words text-n-slate-12"
          >
            {{ contact.name }}
          </h3>
          <div class="flex flex-row items-center gap-2">
            <span
              v-if="contact.created_at"
              v-tooltip.left="
                `${$t('CONTACT_PANEL.CREATED_AT_LABEL')} ${dynamicTime(
                  contact.created_at
                )}`
              "
              class="i-lucide-info text-sm text-n-slate-10"
            />
            <a
              :href="contactProfileLink"
              target="_blank"
              rel="noopener nofollow noreferrer"
              class="leading-3"
            >
              <span class="i-lucide-external-link text-sm text-n-slate-10" />
            </a>
          </div>
        </div>

        <div v-if="additionalAttributes.description" class="w-full">
          <p
            class="break-words mb-0.5"
            :class="{ 'line-clamp-2': !isDescriptionExpanded }"
          >
            {{ additionalAttributes.description }}
          </p>
          <button
            v-if="additionalAttributes.description.length > 100"
            class="text-xs font-medium text-brand-500 hover:underline mt-0.5"
            @click="isDescriptionExpanded = !isDescriptionExpanded"
          >
            {{ isDescriptionExpanded ? 'Thu gọn' : 'Xem thêm' }}
          </button>
        </div>
        <div class="flex flex-col items-start w-full gap-2">
          <template v-if="!isZaloGroupConversation">
            <ContactInfoRow
              :href="
                !maskContactInfo && contact.email
                  ? `mailto:${contact.email}`
                  : ''
              "
              :value="contact.email ? getPlainText(contact.email) : ''"
              icon="mail"
              emoji="✉️"
              :title="$t('CONTACT_PANEL.EMAIL_ADDRESS')"
              :not-available-text="$t('CONTACT_PANEL.NOT_AVAILABLE_EMAIL')"
              show-copy
            />
            <ContactInfoRow
              :href="
                !maskContactInfo && contact.phone_number
                  ? `tel:${contact.phone_number}`
                  : ''
              "
              :value="
                contact.phone_number ? getPlainText(contact.phone_number) : ''
              "
              icon="call"
              emoji="📞"
              :title="$t('CONTACT_PANEL.PHONE_NUMBER')"
              :not-available-text="$t('CONTACT_PANEL.NOT_AVAILABLE_PHONE')"
              show-copy
              value-class="!text-[13px]"
            />
            <ContactInfoRow
              :value="formattedBirthday"
              icon="calendar"
              :title="$t('CONTACT_PANEL.BIRTHDAY')"
              :not-available-text="$t('CONTACT_PANEL.NOT_AVAILABLE_BIRTHDAY')"
            />
            <ContactInfoRow
              :value="
                contact.gender_id
                  ? $t(`CONTACT_PANEL.GENDERS.${contact.gender_id}`)
                  : ''
              "
              icon="person"
              :title="$t('CONTACT_PANEL.GENDER')"
              :not-available-text="$t('CONTACT_PANEL.NOT_AVAILABLE_GENDER')"
            />
            <ContactInfoRow
              v-if="contact.identifier"
              :value="contact.identifier"
              icon="contact-identify"
              emoji="🪪"
              :title="$t('CONTACT_PANEL.IDENTIFIER')"
            />
            <ContactInfoRow
              :value="additionalAttributes.address"
              icon="location"
              emoji="📍"
              :title="$t('CONTACT_PANEL.ADDRESS')"
              :not-available-text="$t('CONTACT_PANEL.NOT_AVAILABLE_ADDRESS')"
            />
            <ContactInfoRow
              v-if="location || additionalAttributes.location"
              :value="location || additionalAttributes.location"
              icon="map"
              emoji="🌍"
              :title="$t('CONTACT_PANEL.LOCATION')"
            />
            <SocialIcons :social-profiles="socialProfiles" />
          </template>
          <template v-else>
            <ContactInfoRow
              v-if="zaloGroupInfo && zaloGroupInfo.group_id"
              :value="zaloGroupInfo.group_id"
              icon="people"
              title="ID Nhóm"
              show-copy
            />
            <ContactInfoRow
              v-if="
                zaloGroupInfo && (zaloGroupInfo.link || zaloGroupInfo.groupLink)
              "
              :value="zaloGroupInfo.link || zaloGroupInfo.groupLink"
              :href="zaloGroupInfo.link || zaloGroupInfo.groupLink"
              icon="link"
              title="Link nhóm"
              show-copy
            />
          </template>
        </div>
      </div>
      <div class="flex items-center w-full mt-0.5 gap-2">
        <!-- Zalo Personal Integration -->
        <template v-if="contact.phone_number">
          <template v-if="!isCurrentConversationZaloPersonal">
            <div class="relative inline-block">
              <NextButton
                v-tooltip.top-end="
                  $t('CONTACT_PANEL.ZALO_PERSONAL.CONNECT_TOOLTIP')
                "
                icon="i-woot-zalo-personal"
                slate
                faded
                sm
                :is-loading="isFetchingZaloUser"
                :disabled="!hasZaloPersonalInboxes"
                @click="handleZaloButtonClick"
              />
              <DropdownMenu
                v-if="showZaloDropdown"
                :menu-items="zaloDropdownItems"
                class="bottom-full left-0 mb-2 whitespace-nowrap !min-w-[150px]"
                @action="handleZaloDropdownAction"
              />
            </div>

            <ConnectZaloPersonalModal
              v-if="showZaloConnectModal"
              v-model:show="showZaloConnectModal"
              :contact-id="String(contact.id)"
              :phone="contact.phone_number"
              :selected-inbox-id="selectedZaloInboxId"
              :zalo-profile="zaloProfileData"
              :is-friend="zaloFriendshipStatus"
              :initial-friend-request-message="initialZaloFriendMessage"
              :initial-greeting-message="initialZaloGreetingMessage"
              @close="closeComposeConversationModal"
            />
          </template>

          <!-- Friendship Status (Zalo conversation) -->
          <div
            v-else-if="zaloFriendshipStatus && !isZaloGroupConversation"
            class="flex items-center gap-1 px-2 py-1 bg-slate-50 dark:bg-slate-800 rounded-md text-xs"
          >
            <span class="w-2 h-2 rounded-full bg-green-500" />
            <span class="text-slate-600 dark:text-slate-300 font-medium">
              Đã là bạn bè
            </span>
          </div>
        </template>
        <NextButton
          v-tooltip.top-end="
            !contact.phone_number
              ? $t('CONTACT_PANEL.OMICALL.TOOLTIP_NO_PHONE')
              : $t('CONTACT_PANEL.OMICALL.TOOLTIP_CALL')
          "
          slate
          faded
          sm
          :disabled="!contact.phone_number"
          @click="handleOmicallButtonClick"
        >
          <template #icon>
            <img
              :src="omicallLogoUrl"
              class="w-4 h-4 dark:hidden"
              alt="OMICall"
            />
            <img
              :src="omicallLogoDarkUrl"
              class="w-4 h-4 hidden dark:block"
              alt="OMICall"
            />
          </template>
        </NextButton>
        <NextButton
          v-tooltip.top-end="$t('EDIT_CONTACT.BUTTON_LABEL')"
          icon="i-ph-pencil-simple"
          slate
          faded
          sm
          @click="toggleEditModal"
        />
        <NextButton
          v-tooltip.top-end="$t('CONTACT_PANEL.MERGE_CONTACT')"
          icon="i-ph-arrows-merge"
          slate
          faded
          sm
          :disabled="uiFlags.isMerging"
          @click="openMergeModal"
        />
        <NextButton
          v-if="isAdmin"
          v-tooltip.top-end="$t('DELETE_CONTACT.BUTTON_LABEL')"
          icon="i-ph-trash"
          slate
          faded
          sm
          ruby
          :disabled="uiFlags.isDeleting"
          @click="toggleDeleteModal"
        />
      </div>
      <EditContact
        v-if="showEditModal"
        :show="showEditModal"
        :contact="contact"
        @cancel="toggleEditModal"
        @duplicate-phone-merge="handleDuplicatePhoneMerge"
      />
      <ContactMergeModal ref="mergeModal" :primary-contact="contact" />
    </div>
    <woot-delete-modal
      v-if="showDeleteModal"
      v-model:show="showDeleteModal"
      :on-close="closeDelete"
      :on-confirm="confirmDeletion"
      :title="$t('DELETE_CONTACT.CONFIRM.TITLE')"
      :message="$t('DELETE_CONTACT.CONFIRM.MESSAGE')"
      :message-value="confirmDeleteMessage"
      :confirm-text="$t('DELETE_CONTACT.CONFIRM.YES')"
      :reject-text="$t('DELETE_CONTACT.CONFIRM.NO')"
    />
    <woot-confirm-modal
      ref="confirmCallDialog"
      :title="$t('CONTACT_PANEL.OMICALL.CONFIRM_CALL.TITLE')"
      :description="
        $t('CONTACT_PANEL.OMICALL.CONFIRM_CALL.DESCRIPTION', {
          phoneNumber: contact.phone_number
            ? getPlainText(contact.phone_number)
            : '',
        })
      "
      :confirm-label="$t('CONTACT_PANEL.OMICALL.CONFIRM_CALL.CONFIRM')"
      :cancel-label="$t('CONTACT_PANEL.OMICALL.CONFIRM_CALL.CANCEL')"
    />
    <woot-confirm-modal
      ref="confirmConnectPbxDialog"
      :title="$t('CONTACT_PANEL.OMICALL.CONNECT_PBX_CONFIRM.TITLE')"
      :description="$t('CONTACT_PANEL.OMICALL.CONNECT_PBX_CONFIRM.DESCRIPTION')"
      :confirm-label="$t('CONTACT_PANEL.OMICALL.CONNECT_PBX_CONFIRM.CONFIRM')"
      :cancel-label="$t('CONTACT_PANEL.OMICALL.CONNECT_PBX_CONFIRM.CANCEL')"
    />
  </div>
</template>
