<script>
import { mapGetters } from 'vuex';
import LoadingState from './components/widgets/LoadingState.vue';
import NetworkNotification from './components/NetworkNotification.vue';
import UpdateBanner from './components/app/UpdateBanner.vue';
import PaymentPendingBanner from './components/app/PaymentPendingBanner.vue';
import PendingEmailVerificationBanner from './components/app/PendingEmailVerificationBanner.vue';
import FloatingCallWidget from './components/widgets/FloatingCallWidget.vue';
import vueActionCable from './helper/actionCable';
import { useRouter } from 'vue-router';
import { useStore } from 'dashboard/composables/store';
import WootSnackbarBox from './components/SnackbarContainer.vue';
import { setColorTheme } from './helper/themeHelper';
import { isOnOnboardingView } from 'v3/helpers/RouteHelper';
import { useAccount } from 'dashboard/composables/useAccount';
import { useFontSize } from 'dashboard/composables/useFontSize';
import { useAlert } from 'dashboard/composables';
import VoiceAPI from 'dashboard/api/channels/voice';
import {
  registerSubscription,
  verifyServiceWorkerExistence,
} from './helper/pushHelper';
import ReconnectService from 'dashboard/helper/ReconnectService';
import { useUISettings } from 'dashboard/composables/useUISettings';
import ContextMenu from 'dashboard/components/ui/ContextMenu.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import CreateNewContactDialog from 'dashboard/components-next/Contacts/ContactsForm/CreateNewContactDialog.vue';
import LimitationModal from './components/widgets/modal/LimitationModal.vue';

export default {
  name: 'App',

  components: {
    FloatingCallWidget,
    LoadingState,
    NetworkNotification,
    UpdateBanner,
    PaymentPendingBanner,
    WootSnackbarBox,
    PendingEmailVerificationBanner,
    ContextMenu,
    DropdownMenu,
    CreateNewContactDialog,
    LimitationModal,
  },
  setup() {
    const router = useRouter();
    const store = useStore();
    const { accountId } = useAccount();
    // Use the font size composable (it automatically sets up the watcher)
    const { currentFontSize } = useFontSize();
    const { uiSettings } = useUISettings();

    return {
      router,
      store,
      currentAccountId: accountId,
      currentFontSize,
      uiSettings,
    };
  },
  data() {
    return {
      latestChatwootVersion: null,
      reconnectService: null,
      showCallWidget: false, // Will be set to true when calls are active
      contactMenuConfig: {
        show: false,
        x: 0,
        y: 0,
        type: '',
        value: '',
      },
    };
  },
  computed: {
    ...mapGetters({
      getAccount: 'accounts/getAccount',
      isRTL: 'accounts/isRTL',
      currentUser: 'getCurrentUser',
      authUIFlags: 'getAuthUIFlags',
      accountUIFlags: 'accounts/getUIFlags',
      activeCall: 'calls/getActiveCall',
      hasActiveCall: 'calls/hasActiveCall',
      incomingCall: 'calls/getIncomingCall',
      hasIncomingCall: 'calls/hasIncomingCall',
      selectedChat: 'getSelectedChat',
    }),
    hideOnOnboardingView() {
      return !isOnOnboardingView(this.$route);
    },
    contactMenuItems() {
      const { type } = this.contactMenuConfig;
      if (type === 'email') {
        return [
          {
            label: this.$t('CONTACT_PANEL.SAVE_CONTACT'),
            action: 'save',
            value: 'save',
            icon: 'i-lucide-user-plus',
          },
          {
            label: this.$t('CONTACT_PANEL.COPY_EMAIL'),
            action: 'copy',
            value: 'copy',
            icon: 'i-lucide-copy',
          },
          {
            label: this.$t('CONTACT_PANEL.SEND_EMAIL'),
            action: 'email',
            value: 'email',
            icon: 'i-lucide-mail',
          },
        ];
      }
      if (type === 'phone') {
        return [
          {
            label: this.$t('CONTACT_PANEL.SAVE_CONTACT'),
            action: 'save',
            value: 'save',
            icon: 'i-lucide-user-plus',
          },
          {
            label: this.$t('CONTACT_PANEL.COPY_PHONE'),
            action: 'copy',
            value: 'copy',
            icon: 'i-lucide-copy',
          },
          {
            label: this.$t('CONTACT_PANEL.CALL'),
            action: 'call',
            value: 'call',
            icon: 'i-lucide-phone',
          },
          {
            label: this.$t('CONTACT_PANEL.LOOKUP_ZALO'),
            action: 'zalo',
            value: 'zalo',
            icon: 'i-lucide-search',
          },
        ];
      }
      return [];
    },
  },

  watch: {
    currentAccountId: {
      immediate: true,
      handler() {
        if (this.currentAccountId) {
          this.initializeAccount();
        }
      },
    },
    hasIncomingCall: {
      immediate: true,
      handler(newVal) {
        console.log('App.vue detected change in hasIncomingCall to', newVal);
        if (newVal) {
          console.log('Incoming call data:', this.incomingCall);
          this.showCallWidget = true;
        } else {
          this.showCallWidget = false;
        }
      },
    },
    hasActiveCall: {
      immediate: true,
      handler(newVal) {
        console.log('App.vue detected change in hasActiveCall to', newVal);
        if (newVal) {
          console.log('Active call data:', this.activeCall);
          this.showCallWidget = true;
        } else {
          this.showCallWidget = false;
        }
      },
    },
  },
  mounted() {
    this.initializeColorTheme();
    this.listenToThemeChanges();
    // If user locale is set, use it; otherwise use account locale
    this.setLocale(
      this.uiSettings?.locale || window.shopizConfig.selectedLocale
    );
    document.addEventListener('click', this.handleGlobalClick);
  },
  unmounted() {
    if (this.reconnectService) {
      this.reconnectService.disconnect();
    }
    document.removeEventListener('click', this.handleGlobalClick);
  },
  methods: {
    initializeColorTheme() {
      setColorTheme(window.matchMedia('(prefers-color-scheme: dark)').matches);
    },
    listenToThemeChanges() {
      const mql = window.matchMedia('(prefers-color-scheme: dark)');
      mql.onchange = e => setColorTheme(e.matches);
    },
    setLocale(locale) {
      this.$root.$i18n.locale = locale;
    },
    handleCallEnded() {
      this.showCallWidget = false;
      this.$store.dispatch('calls/clearActiveCall');
      this.$store.dispatch('calls/clearIncomingCall');

      // Clear the activeCallConversation state in all ContactInfo components
      this.$nextTick(() => {
        const clearContactInfoCallState = components => {
          if (!components) return;

          components.forEach(component => {
            if (
              component.$options &&
              component.$options.name === 'ContactInfo'
            ) {
              if (component.activeCallConversation) {
                component.activeCallConversation = null;
                component.$forceUpdate();
              }
            }
            if (component.$children && component.$children.length) {
              clearContactInfoCallState(component.$children);
            }
          });
        };

        clearContactInfoCallState(this.$children);
      });
    },
    handleCallJoined() {
      this.showCallWidget = true;
    },
    handleCallRejected() {
      this.showCallWidget = false;
      this.$store.dispatch('calls/clearIncomingCall');
    },
    forceEndCall() {
      this.showCallWidget = false;
      if (window.forceEndCallHandlers) {
        window.forceEndCallHandlers.forEach(handler => {
          try {
            handler();
          } catch (e) {
            // Optionally log error in production
          }
        });
      }
      if (this.activeCall && this.activeCall.callSid) {
        const { callSid, conversationId } = this.activeCall;
        const savedCallSid = callSid;
        const savedConversationId = conversationId;
        this.$store.dispatch('calls/clearActiveCall');
        if (savedConversationId) {
          VoiceAPI.endCall(savedCallSid, savedConversationId)
            .then(response => {
              useAlert({ message: 'Call ended successfully', type: 'success' });
            })
            .catch(error => {
              setTimeout(() => {
                VoiceAPI.endCall(savedCallSid, savedConversationId)
                  .then(retryResponse => {})
                  .catch(retryError => {});
              }, 1000);
              useAlert({ message: 'Call UI has been reset', type: 'info' });
            });
        } else {
          useAlert({ message: 'Call ended', type: 'success' });
        }
      } else {
        this.$store.dispatch('calls/clearActiveCall');
      }
    },
    async initializeAccount() {
      await this.$store.dispatch('accounts/get');
      this.$store.dispatch('setActiveAccount', {
        accountId: this.currentAccountId,
      });
      const { locale, latest_chatwoot_version: latestChatwootVersion } =
        this.getAccount(this.currentAccountId);
      const { pubsub_token: pubsubToken } = this.currentUser || {};
      // If user locale is set, use it; otherwise use account locale
      this.setLocale(this.uiSettings?.locale || locale);
      this.latestChatwootVersion = latestChatwootVersion;
      vueActionCable.init(this.store, pubsubToken);
      this.reconnectService = new ReconnectService(this.store, this.router);
      window.reconnectService = this.reconnectService;

      verifyServiceWorkerExistence(registration =>
        registration.pushManager.getSubscription().then(subscription => {
          if (subscription) {
            registerSubscription();
          }
        })
      );
    },
    handleGlobalClick(event) {
      const target = event.target.closest('.highlight-link');
      const isInsideMenu = event.target.closest('.js-contact-context-menu');

      if (target) {
        event.preventDefault();
        event.stopPropagation();
        const type = target.getAttribute('data-type');
        const value = target.getAttribute('data-value');

        this.contactMenuConfig = {
          show: true,
          x: event.clientX,
          y: event.clientY,
          type,
          value,
        };
      } else if (this.contactMenuConfig.show && !isInsideMenu) {
        this.closeContactMenu();
      }
    },
    closeContactMenu() {
      this.contactMenuConfig.show = false;
    },
    async handleContactMenuAction({ action }) {
      const { value, type } = this.contactMenuConfig;
      if (action === 'save') {
        const contact = this.selectedChat?.meta?.sender;
        if (!contact?.id) {
          useAlert(this.$t('CONTACT_PANEL.NO_CONTACT_FOUND'));
        } else {
          try {
            const updatePayload = { id: contact.id };
            if (type === 'email') {
              updatePayload.email = value;
            } else if (type === 'phone') {
              // Normalize to international format (+84 for Vietnam)
              const digits = value.replace(/\D/g, '');
              if (digits.startsWith('0')) {
                updatePayload.phoneNumber = `+84${digits.slice(1)}`;
              } else if (digits.startsWith('84')) {
                updatePayload.phoneNumber = `+${digits}`;
              } else {
                updatePayload.phoneNumber = `+${digits}`;
              }
            }
            await this.$store.dispatch('contacts/update', updatePayload);
            useAlert(this.$t('CONTACT_PANEL.SAVE_CONTACT_SUCCESS'));
          } catch {
            useAlert(this.$t('CONTACT_PANEL.SAVE_CONTACT_ERROR'));
          }
        }
      } else if (action === 'copy') {
        navigator.clipboard.writeText(value).then(() => {
          useAlert(this.$t('CONTACT_PANEL.COPY_SUCCESSFUL'));
        });
      } else if (action === 'email') {
        window.location.href = `mailto:${value}`;
      } else if (action === 'call') {
        window.location.href = `tel:${value}`;
      } else if (action === 'zalo') {
        const cleanPhone = value.replace(/\D/g, '').replace(/^84/, '0');
        window.open(`https://zalo.me/${cleanPhone}`, '_blank');
      }
      this.closeContactMenu();
    },
    async onCreateContact(contact) {
      try {
        await this.$store.dispatch('contacts/create', contact);
        this.$refs.createNewContactDialog.onSuccess();
        useAlert(
          this.$t(
            'CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION.SUCCESS_MESSAGE'
          )
        );
      } catch (error) {
        const i18nPrefix = 'CONTACTS_LAYOUT.HEADER.ACTIONS.CONTACT_CREATION';
        if (error.response?.data?.message?.includes('email')) {
          useAlert(this.$t(`${i18nPrefix}.EMAIL_ADDRESS_DUPLICATE`));
        } else if (error.response?.data?.message?.includes('phone_number')) {
          useAlert(this.$t(`${i18nPrefix}.PHONE_NUMBER_DUPLICATE`));
        } else {
          useAlert(this.$t(`${i18nPrefix}.ERROR_MESSAGE`));
        }
      }
    },
  },
};
</script>

<template>
  <div
    v-if="!authUIFlags.isFetching && !accountUIFlags.isFetchingItem"
    id="app"
    class="flex flex-col w-full h-screen min-h-0 bg-n-background"
    :dir="isRTL ? 'rtl' : 'ltr'"
  >
    <UpdateBanner :latest-chatwoot-version="latestChatwootVersion" />
    <template v-if="currentAccountId">
      <PendingEmailVerificationBanner v-if="hideOnOnboardingView" />
      <PaymentPendingBanner v-if="hideOnOnboardingView" />
    </template>
    <router-view v-slot="{ Component }">
      <transition name="fade" mode="out-in">
        <component :is="Component" />
      </transition>
    </router-view>
    <WootSnackbarBox />
    <NetworkNotification />
    <!-- Floating call widget that appears during active calls -->
    <FloatingCallWidget
      v-if="showCallWidget || hasActiveCall || hasIncomingCall"
      :key="
        activeCall
          ? activeCall.callSid
          : incomingCall
            ? incomingCall.callSid
            : 'no-call'
      "
      :call-sid="
        activeCall
          ? activeCall.callSid
          : incomingCall
            ? incomingCall.callSid
            : ''
      "
      :inbox-name="
        activeCall
          ? activeCall.inboxName || 'Primary'
          : incomingCall
            ? incomingCall.inboxName
            : 'Primary'
      "
      :conversation-id="
        activeCall
          ? activeCall.conversationId
          : incomingCall
            ? incomingCall.conversationId
            : null
      "
      :contact-name="
        activeCall
          ? activeCall.contactName
          : incomingCall
            ? incomingCall.contactName
            : ''
      "
      :contact-id="
        activeCall
          ? activeCall.contactId
          : incomingCall
            ? incomingCall.contactId
            : null
      "
      :inbox-id="
        activeCall
          ? activeCall.inboxId
          : incomingCall
            ? incomingCall.inboxId
            : null
      "
      :inbox-avatar-url="
        activeCall
          ? activeCall.inboxAvatarUrl
          : incomingCall
            ? incomingCall.inboxAvatarUrl
            : ''
      "
      :inbox-phone-number="
        activeCall
          ? activeCall.inboxPhoneNumber
          : incomingCall
            ? incomingCall.inboxPhoneNumber
            : ''
      "
      :avatar-url="
        activeCall
          ? activeCall.avatarUrl
          : incomingCall
            ? incomingCall.avatarUrl
            : ''
      "
      :phone-number="
        activeCall
          ? activeCall.phoneNumber
          : incomingCall
            ? incomingCall.phoneNumber
            : ''
      "
      use-web-rtc
      @call-ended="handleCallEnded"
      @call-joined="handleCallJoined"
      @call-rejected="handleCallRejected"
    />
    <ContextMenu
      v-if="contactMenuConfig.show"
      class="js-contact-context-menu"
      :x="contactMenuConfig.x"
      :y="contactMenuConfig.y"
      @close="closeContactMenu"
    >
      <DropdownMenu
        :menu-items="contactMenuItems"
        @action="handleContactMenuAction"
      />
    </ContextMenu>
    <CreateNewContactDialog
      ref="createNewContactDialog"
      @create="onCreateContact"
    />
    <LimitationModal />
  </div>
  <LoadingState v-else />
</template>

<style lang="scss">
@import './assets/scss/app';

.v-popper--theme-tooltip .v-popper__inner {
  background: black !important;
  font-size: 0.75rem;
  padding: 4px 8px !important;
  border-radius: 6px;
  font-weight: 400;
}

.v-popper--theme-tooltip .v-popper__arrow-container {
  display: none;
}
</style>
