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
import VoiceCallButton from 'dashboard/components-next/Contacts/VoiceCallButton.vue';
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
    VoiceCallButton,
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
    const { makeCall: makeOmicallCall, isReady: isOmicallReady, isOmicallConfigured } = useOmicall();

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
      isCallLoading: false,
      activeCallConversation: null,
      isHoveringCallButton: false,
      showZaloDropdown: false,
      showZaloConnectModal: false,
      isFetchingZaloUser: false,
      zaloProfileData: {},
      selectedZaloInboxId: null,
      initialZaloFriendMessage: '',
      initialZaloGreetingMessage: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'contacts/getUIFlags',
      storeActiveCall: 'calls/getActiveCall',
      storeHasActiveCall: 'calls/hasActiveCall',
    }),
    // Check if there's an active call either in store or local component
    hasActiveCall() {
      return this.storeHasActiveCall || !!this.activeCallConversation;
    },
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
        false,
        false,
        true,
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
    async initiateVoiceCall() {
      if (!this.contact || !this.contact.id) return;

      this.isCallLoading = true;
      try {
        const response = await VoiceAPI.initiateCall(this.contact.id);
        const conversation = response.data;

        // First set local state for immediate UI update
        this.activeCallConversation = conversation;
        console.log('Call initiated, conversation data:', conversation);

        // Always create a call SID even if it's not in the response
        let callSid = conversation?.call_sid;

        // If not directly available, try to find it in messages
        if (!callSid) {
          const messages = conversation?.messages || [];
          const callMessage = messages.find(
            message =>
              message.message_type === 10 &&
              message.additional_attributes &&
              message.additional_attributes.call_sid
          );

          callSid = callMessage?.additional_attributes?.call_sid;
        }

        // If still not found, check conversation.additional_attributes
        if (!callSid && conversation?.additional_attributes) {
          callSid = conversation.additional_attributes.call_sid;
        }

        // If we don't have a call SID, log the error but continue
        // This will allow the UI to show something while we wait for the real call SID
        if (!callSid) {
          console.log(
            'No call SID found in response, waiting for server to assign one'
          );

          // We'll rely on WebSocket updates to get the real call SID when available
          // For now just set a placeholder for UI purposes
          callSid = 'pending';
        }

        // Log for debugging
        console.log('Voice call response:', conversation);
        console.log('Using call SID:', callSid);

        // Always set the global call state for the floating widget
        const inbox = conversation.inbox_id
          ? this.$store.getters['inboxes/getInbox'](conversation.inbox_id)
          : null;

        this.$store.dispatch('calls/setActiveCall', {
          callSid,
          inboxName: inbox?.name || 'Primary',
          conversationId: conversation.id,
          contactId: this.contact.id,
          inboxId: conversation.inbox_id,
        });

        // Set App's showCallWidget to true
        if (window.app && window.app.$data) {
          window.app.$data.showCallWidget = true;
        }

        // IMPORTANT: Redirect to the conversation view
        if (conversation.id) {
          const accountId = this.$route.params.accountId;
          const path = frontendURL(
            conversationUrl({
              accountId,
              id: conversation.id,
            })
          );
          console.log(`Redirecting to conversation path: ${path}`);
          this.$router.push({ path });
        }

        // After a brief delay, force update UI
        setTimeout(() => {
          this.$forceUpdate();
        }, 100);

        useAlert('Voice call initiated successfully');
      } catch (error) {
        // Error handled with useAlert
        useAlert('Failed to initiate voice call');
      } finally {
        this.isCallLoading = false;
      }
    },

    handleCallEnded() {
      // Immediately reset local state
      this.activeCallConversation = null;
      this.isCallLoading = false;

      // Clear global call state
      this.$store.dispatch('calls/clearActiveCall');

      // Force re-render the component to ensure button state updates
      this.$forceUpdate();
    },

    // Simplified emergency end call function
    forceEndActiveCall() {
      console.log('FORCE END ACTIVE CALL triggered from ContactInfo');

      // Important: Save a reference to the conversation before resetting it
      const savedConversation = this.activeCallConversation;

      // 1. Immediately update local state for immediate UI feedback
      this.activeCallConversation = null;
      this.isHoveringCallButton = false;
      this.$forceUpdate();

      // 2. Reset App global state
      if (window.app) {
        window.app.$data.showCallWidget = false;
      }

      // 3. Reset store state
      this.$store.dispatch('calls/clearActiveCall');

      // 4. Get the call SID from the saved conversation
      if (savedConversation) {
        // Try to find the call SID
        let callSid = null;

        // Check all possible locations
        if (savedConversation.call_sid) {
          callSid = savedConversation.call_sid;
        } else if (savedConversation.additional_attributes?.call_sid) {
          callSid = savedConversation.additional_attributes.call_sid;
        } else if (
          savedConversation.messages &&
          savedConversation.messages.length > 0
        ) {
          // Look in messages
          const callMessage = savedConversation.messages.find(
            message =>
              message.message_type === 10 &&
              message.additional_attributes?.call_sid
          );

          if (callMessage) {
            callSid = callMessage.additional_attributes.call_sid;
          }
        }

        console.log('ContactInfo: Found call SID for API call:', callSid);

        // 5. Make direct API call to end the call if we have a valid call SID
        if (callSid && callSid !== 'pending') {
          // Check if it's a valid Twilio call SID
          const isValidTwilioSid =
            callSid.startsWith('CA') || callSid.startsWith('TJ');

          if (isValidTwilioSid) {
            console.log(
              'ContactInfo: Making direct API call to end call with SID:',
              callSid
            );

            // Make API call with conversation ID
            VoiceAPI.endCall(callSid, savedConversation.id)
              .then(response => {
                console.log(
                  'ContactInfo: Call ended successfully via API:',
                  response
                );
              })
              .catch(error => {
                console.error('ContactInfo: Error ending call via API:', error);
              });
          } else {
            console.log(
              'ContactInfo: Invalid Twilio call SID format:',
              callSid
            );
          }
        } else if (callSid === 'pending') {
          console.log(
            'ContactInfo: Call was still in pending state, no API call needed'
          );
        } else {
          console.log('ContactInfo: No call SID available for API call');
        }
      }

      // 6. User feedback
      useAlert({ message: 'Call ended successfully', type: 'success' });
    },

    // Original more careful implementation
    async endActiveCall() {
      console.log('End active call triggered from ContactInfo component');

      // First, immediately update the UI for responsive feedback
      const savedActiveCall = this.activeCallConversation;
      this.activeCallConversation = null;
      this.$forceUpdate();

      // Reset app-level state
      if (window.app && window.app.$data) {
        window.app.$data.showCallWidget = false;
      }

      // Clear global state
      this.$store.dispatch('calls/clearActiveCall');

      // Always give user success feedback
      useAlert({ message: 'Call ended successfully', type: 'success' });

      // Then try the API call (after UI is updated)
      try {
        if (savedActiveCall) {
          // Try to find the call SID
          let callSid = null;

          // Check all possible locations
          if (savedActiveCall.call_sid) {
            callSid = savedActiveCall.call_sid;
          } else if (savedActiveCall.additional_attributes?.call_sid) {
            callSid = savedActiveCall.additional_attributes.call_sid;
          } else {
            // Look in messages
            const messages = savedActiveCall.messages || [];
            const callMessage = messages.find(
              message =>
                message.message_type === 10 &&
                message.additional_attributes?.call_sid
            );

            if (callMessage) {
              callSid = callMessage.additional_attributes.call_sid;
            }
          }

          console.log('Found call SID for API call:', callSid);

          // Make the API call if we have a valid call SID
          if (callSid && callSid !== 'pending') {
            // Check if it's a valid Twilio call SID
            const isValidTwilioSid =
              callSid.startsWith('CA') || callSid.startsWith('TJ');

            if (isValidTwilioSid) {
              try {
                console.log('Making API call to end call with SID:', callSid);
                await VoiceAPI.endCall(callSid, savedActiveCall.id);
                console.log('API call to end call succeeded');
              } catch (apiError) {
                console.error('API call to end call failed:', apiError);
                // We've already updated UI, so don't show error to user
              }
            } else {
              console.log('Invalid Twilio call SID format:', callSid);
            }
          } else if (callSid === 'pending') {
            console.log('Call was still in pending state, no API call needed');
          } else {
            console.log('No call SID available for API call');
          }
        }
      } catch (error) {
        console.error('Error in endActiveCall:', error);
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
    onCallButtonClick() {
      // If there's an active call in the store, just show widget
      if (this.storeHasActiveCall) {
        useAlert('Call already active, showing call widget', 'info');
        if (window.app && window.app.$data) {
          window.app.$data.showCallWidget = true;
        }
        return;
      }

      // Check if we have a stale local state
      if (this.activeCallConversation) {
        // Reset our local state
        this.activeCallConversation = null;
        this.$forceUpdate();

        // If store is clear, initiate a new call after state reset
        if (!this.storeHasActiveCall) {
          this.$nextTick(() => {
            this.initiateVoiceCall();
          });
        }
      } else {
        // No active call, proceed with initiating a new one
        this.initiateVoiceCall();
      }
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
      <!-- Call Manager Component - Shows only when a call is active -->
      <CallManager
        v-if="activeCallConversation && contact && contact.id"
        :contact="contact"
        :conversation="activeCallConversation"
        @call-ended="handleCallEnded"
      />

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
          rounded-full
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

        <p v-if="additionalAttributes.description" class="break-words mb-0.5">
          {{ additionalAttributes.description }}
        </p>
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
                zaloGroupInfo &&
                (zaloGroupInfo.desc || zaloGroupInfo.description)
              "
              :value="zaloGroupInfo.desc || zaloGroupInfo.description"
              icon="document"
              title="Mô tả"
              multiline
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
        <VoiceCallButton
          :phone="contact.phone_number"
          :contact-id="contact.id"
          icon="i-ri-phone-fill"
          size="sm"
          :tooltip-label="$t('CONTACT_PANEL.CALL')"
          slate
          faded
        />
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
