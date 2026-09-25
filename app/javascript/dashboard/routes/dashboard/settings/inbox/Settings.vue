<script>
import { mapGetters } from 'vuex';
import { shouldBeUrl } from 'shared/helpers/Validators';
import { useAlert } from 'dashboard/composables';
import Banner from 'dashboard/components-next/banner/Banner.vue';
import { useVuelidate } from '@vuelidate/core';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { ref } from 'vue';
import Avatar from 'next/avatar/Avatar.vue';
import SettingIntroBanner from 'dashboard/components/widgets/SettingIntroBanner.vue';
import SettingsToggleSection from 'dashboard/components-next/Settings/SettingsToggleSection.vue';
import SettingsFieldSection from 'dashboard/components-next/Settings/SettingsFieldSection.vue';
import SettingsAccordion from 'dashboard/components-next/Settings/SettingsAccordion.vue';
import inboxMixin from 'shared/mixins/inboxMixin';
import FacebookReauthorize from './facebook/Reauthorize.vue';
import FacebookPostsAndComments from './facebook/PostsAndComments.vue';
import InstagramReauthorize from './channels/instagram/Reauthorize.vue';
import TiktokReauthorize from './channels/tiktok/Reauthorize.vue';
import DuplicateInboxBanner from './channels/instagram/DuplicateInboxBanner.vue';
import ZaloReauthorize from './channels/zalo/Reauthorize.vue';
import ZaloPersonalLabelSync from './channels/zalo/LabelSync.vue';
import TextArea from 'next/textarea/TextArea.vue';

import WhatsappReauthorize from './channels/whatsapp/Reauthorize.vue';
import InboxHealthAPI from 'dashboard/api/inboxHealth';
import PreChatFormSettings from './PreChatForm/Settings.vue';
import WeeklyAvailability from './components/WeeklyAvailability.vue';
import GreetingsEditor from 'shared/components/GreetingsEditor.vue';
import ConfigurationPage from './settingsPage/ConfigurationPage.vue';
import CustomerSatisfactionPage from './settingsPage/CustomerSatisfactionPage.vue';
import CollaboratorsPage from './settingsPage/CollaboratorsPage.vue';
import BotConfiguration from './components/BotConfiguration.vue';
import AccountHealth from './components/AccountHealth.vue';
import { FEATURE_FLAGS } from '../../../../featureFlags';
import SenderNameExamplePreview from './components/SenderNameExamplePreview.vue';
import LockToSingleConversationPreview from './components/LockToSingleConversationPreview.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import SpinnerLoader from 'dashboard/components-next/spinner/Spinner.vue';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { getInboxIconByType } from 'dashboard/helper/inbox';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { LocalStorage } from 'shared/helpers/localStorage';
import FeatureLockOverlay from 'dashboard/routes/dashboard/upgrade/FeatureLockOverlay.vue';
import Editor from 'dashboard/components-next/Editor/Editor.vue';
import ColorPicker from 'dashboard/components-next/colorpicker/ColorPicker.vue';
import SelectInput from 'dashboard/components-next/select/Select.vue';
import FilterSelect from 'dashboard/components-next/filter/inputs/FilterSelect.vue';
import Widget from 'dashboard/modules/widget-preview/components/Widget.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';

import InboxReconnectionRequired from './components/InboxReconnectionRequired.vue';
import InboxesAPI from 'dashboard/api/inboxes';

export default {
  components: {
    Banner,
    BotConfiguration,
    CollaboratorsPage,
    ConfigurationPage,
    CustomerSatisfactionPage,
    FacebookReauthorize,
    FacebookPostsAndComments,
    GreetingsEditor,
    PreChatFormSettings,
    SettingIntroBanner,
    SettingsToggleSection,
    SettingsFieldSection,
    SettingsAccordion,
    TextArea,
    WeeklyAvailability,
    SenderNameExamplePreview,
    LockToSingleConversationPreview,
    ZaloReauthorize,
    ZaloPersonalLabelSync,

    NextButton,
    SpinnerLoader,
    InstagramReauthorize,
    TiktokReauthorize,
    WhatsappReauthorize,
    DuplicateInboxBanner,
    Editor,
    Avatar,
    ColorPicker,
    SelectInput,
    FilterSelect,
    AccountHealth,
    Widget,
    Dialog,

    FeatureLockOverlay,
    InboxReconnectionRequired,
  },
  mixins: [inboxMixin],
  setup() {
    const { processEvent } = useCaptain();
    const isImprovingZaloFriend = ref(false);
    const isImprovingZaloGreeting = ref(false);
    const isImprovingAutoFollowUps = ref({});

    return {
      v$: useVuelidate(),
      processEvent,
      isImprovingZaloFriend,
      isImprovingZaloGreeting,
      isImprovingAutoFollowUps,
    };
  },
  data() {
    return {
      avatarFile: null,
      avatarUrl: '',
      bubbleAvatarUrl: '',
      greetingEnabled: true,
      greetingMessage: '',
      senderNameType: 'friendly',
      businessName: '',
      locktoSingleConversation: false,
      allowMessagesAfterResolved: true,
      selectedInboxName: '',
      channelWebsiteUrl: '',
      webhookUrl: '',
      channelWelcomeTitle: '',
      channelWelcomeTagline: '',
      selectedFeatureFlags: [],
      replyTime: '',
      selectedTabIndex: 0,
      showBusinessNameInput: false,
      healthData: null,
      isLoadingHealth: false,
      healthError: null,
      isRegisteringWebhook: false,
      widgetBubblePosition: 'right',
      widgetBubbleType: 'standard',
      widgetBubbleLauncherTitle: '',
      autoFollowUpEnabled: false,
      autoFollowUpMaxAttempts: 1,
      autoFollowUpIntervalHours: 24,
      autoFollowUpTimeMode: 'relative',
      autoFollowUpFixedTime: '09:00',
      autoFollowUpTimezone: 'Asia/Ho_Chi_Minh',
      autoFollowUpAiRewrite: false,
      autoFollowUpPredefinedMessage: '',
      autoFollowUpPredefinedMessages: Array.from({ length: 15 }, () => ''),
      autoLabelEnabled: false,
      labelSuggestionEnabled: false,
      zaloReauthorizeModalVisible: false,
      isCheckingConnection: false,
      isSyncingFriends: false,
      zaloPersonalDefaultFriendRequestMessage: '',
      zaloPersonalDefaultGreetingMessage: '',
    };
  },
  computed: {
    ...mapGetters({
      accountId: 'getCurrentAccountId',
      isFeatureEnabledonAccount: 'accounts/isFeatureEnabledonAccount',
      uiFlags: 'inboxes/getUIFlags',
      macros: 'macros/getMacros',
    }),
    isCaptainEnabled() {
      return this.isFeatureEnabledonAccount(
        this.accountId,
        FEATURE_FLAGS.CAPTAIN
      );
    },
    selectedTabKey() {
      return this.tabs[this.selectedTabIndex]?.key;
    },
    shouldShowWhatsAppConfiguration() {
      return this.isAWhatsAppCloudChannel;
    },
    whatsAppAPIProviderName() {
      if (this.isAWhatsAppCloudChannel) {
        return this.$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.WHATSAPP_CLOUD');
      }
      if (this.is360DialogWhatsAppChannel) {
        return this.$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.360_DIALOG');
      }
      return '';
    },
    tabs() {
      let visibleToAllChannelTabs = [
        {
          key: 'inbox-settings',
          name: this.$t('INBOX_MGMT.TABS.SETTINGS'),
        },
        {
          key: 'collaborators',
          name: this.$t('INBOX_MGMT.TABS.COLLABORATORS'),
        },
        {
          key: 'business-hours',
          name: this.$t('INBOX_MGMT.TABS.BUSINESS_HOURS'),
        },
      ];

      if (this.isAWebWidgetInbox) {
        visibleToAllChannelTabs = [
          ...visibleToAllChannelTabs,
          {
            key: 'pre-chat-form',
            name: this.$t('INBOX_MGMT.TABS.PRE_CHAT_FORM'),
          },
        ];
      }

      if (
        this.isAZaloPersonalChannel ||
        this.isAPIInbox ||
        this.shouldShowWhatsAppConfiguration ||
        this.isAWebWidgetInbox ||
        this.isAFacebookInbox ||
        this.isAnInstagramChannel ||
        this.isATelegramChannel
      ) {
        visibleToAllChannelTabs = [
          ...visibleToAllChannelTabs,
          {
            key: 'configuration',
            name: this.$t('INBOX_MGMT.TABS.CONFIGURATION'),
          },
        ];
      }

      if (this.isAZaloPersonalChannel) {
        visibleToAllChannelTabs = [
          ...visibleToAllChannelTabs,
          {
            key: 'label-sync',
            name: this.$t('INBOX_MGMT.LABEL_SYNC.TITLE'),
          },
        ];
      }

      if (
        this.isAFacebookInbox ||
        this.isAnInstagramChannel ||
        this.isATiktokChannel
      ) {
        visibleToAllChannelTabs = [
          ...visibleToAllChannelTabs,
          {
            key: 'posts-and-comments',
            name: this.$t('INBOX_MGMT.TABS.POSTS_AND_COMMENTS'),
          },
        ];
      }

      if (
        this.isFeatureEnabledonAccount(this.accountId, FEATURE_FLAGS.AGENT_BOTS)
      ) {
        visibleToAllChannelTabs = [
          ...visibleToAllChannelTabs,
          {
            key: 'bot-configuration',
            name: this.$t('INBOX_MGMT.TABS.BOT_CONFIGURATION'),
          },
        ];
      }
      if (this.shouldShowWhatsAppConfiguration) {
        visibleToAllChannelTabs = [
          ...visibleToAllChannelTabs,
          {
            key: 'whatsapp-health',
            name: this.$t('INBOX_MGMT.TABS.ACCOUNT_HEALTH'),
          },
        ];
      }

      return visibleToAllChannelTabs;
    },
    currentInboxId() {
      return this.$route.params.inboxId;
    },
    inbox() {
      return this.$store.getters['inboxes/getInbox'](this.currentInboxId);
    },
    inboxIcon() {
      const { medium, channel_type: type } = this.inbox;
      return getInboxIconByType(type, medium, 'line');
    },
    bannerMaxWidth() {
      const narrowTabs = [
        'collaborators',
        'bot-configuration',
        'business-hours',
        'posts-and-comments',
        'label-sync',
      ];
      const wideIfWebWidget = ['configuration', 'inbox-settings'];
      if (narrowTabs.includes(this.selectedTabKey)) return 'max-w-4xl';
      if (wideIfWebWidget.includes(this.selectedTabKey)) {
        return this.isAWebWidgetInbox ? 'max-w-7xl' : 'max-w-4xl';
      }
      return 'max-w-7xl';
    },
    inboxName() {
      if (this.isAWhatsAppChannel) {
        return `${this.inbox.name} (${this.inbox.phone_number})`;
      }
      return this.inbox.name;
    },
    canLocktoSingleConversation() {
      return (
        this.isAWhatsAppChannel ||
        this.isAFacebookInbox ||
        this.isAPIInbox ||
        this.isAnInstagramChannel ||
        this.isATiktokChannel ||
        this.isATelegramChannel
      );
    },
    inboxNameLabel() {
      if (this.isAWebWidgetInbox) {
        return this.$t('INBOX_MGMT.ADD.WEBSITE_NAME.LABEL');
      }
      return this.$t('INBOX_MGMT.ADD.CHANNEL_NAME.LABEL');
    },
    inboxNamePlaceHolder() {
      if (this.isAWebWidgetInbox) {
        return this.$t('INBOX_MGMT.ADD.WEBSITE_NAME.PLACEHOLDER');
      }
      return this.$t('INBOX_MGMT.ADD.CHANNEL_NAME.PLACEHOLDER');
    },
    textAreaChannels() {
      if (
        this.isAFacebookInbox
      )
        return true;
      return false;
    },
    instagramUnauthorized() {
      return this.isAnInstagramChannel && this.inbox.reauthorization_required;
    },
    zaloPersonalUnauthorized() {
      return this.isAZaloPersonalChannel && this.inbox.reauthorization_required;
    },
    tiktokUnauthorized() {
      return this.isATiktokChannel && this.inbox.reauthorization_required;
    },
    // Check if a instagram inbox exists with the same instagram_id
    hasDuplicateInstagramInbox() {
      const instagramId = this.inbox.instagram_id;
      const instagramInbox =
        this.$store.getters['inboxes/getInstagramInboxByInstagramId'](
          instagramId
        );

      return this.inbox.channel_type === INBOX_TYPES.FB && instagramInbox;
    },
    facebookUnauthorized() {
      return this.isAFacebookInbox && this.inbox.reauthorization_required;
    },
    isEmbeddedSignupWhatsApp() {
      return this.inbox.provider_config?.source === 'embedded_signup';
    },
    whatsappUnauthorized() {
      return (
        this.isAWhatsAppCloudChannel &&
        this.isEmbeddedSignupWhatsApp &&
        this.inbox.reauthorization_required
      );
    },
    whatsappRegistrationIncomplete() {
      if (
        !this.healthData ||
        !this.isAWhatsAppCloudChannel ||
        !this.isEmbeddedSignupWhatsApp
      ) {
        return false;
      }

      return (
        this.healthData.platform_type === 'NOT_APPLICABLE' ||
        this.healthData.throughput?.level === 'NOT_APPLICABLE'
      );
    },
    widgetBuilderStorageKey() {
      return `${LOCAL_STORAGE_KEYS.WIDGET_BUILDER}${this.inbox.id}`;
    },
    dynamicMaxAttemptsOptions() {
      let upperLimit = 168; // 7 days fallback for standard UI threshold

      if (
        this.isAWhatsAppChannel ||
        this.isAWhatsAppCloudChannel ||
        this.is360DialogWhatsAppChannel
      ) {
        upperLimit = 24;
      } else if (this.isAZaloOaChannel) {
        upperLimit = 48;
      } else if (this.isAZaloPersonalChannel) {
        upperLimit = 999; // ZaloPersonal không giới hạn thời gian gửi tin
      } else if (this.isAnInstagramChannel || this.isAFacebookInbox) {
        upperLimit = 168; // 7 days with HUMAN_AGENT tag
      } else if (this.isAWebWidgetInbox) {
        upperLimit = 999;
      }

      let maxNumber = 10;
      if (upperLimit < 999 && this.autoFollowUpIntervalHours > 0) {
        maxNumber = Math.floor(upperLimit / this.autoFollowUpIntervalHours);
      }

      if (maxNumber < 1) maxNumber = 1;
      if (maxNumber > 10) maxNumber = 10;

      return Array.from({ length: maxNumber }, (_, i) => ({
        label: `${i + 1} Lần`,
        value: i + 1,
      }));
    },
  },
  watch: {
    $route(to, from) {
      if (to.name === 'settings_inbox_show') {
        const inboxChanged = to.params.inboxId !== from.params.inboxId;
        if (inboxChanged) {
          this.syncInboxData();
          this.setTabFromRouteParam();
        }
      }
    },
    inbox: {
      handler(newInbox, oldInbox) {
        if (newInbox?.id !== oldInbox?.id) {
          this.syncInboxData();
          this.fetchHealthData();
          this.$nextTick(() => {
            this.setTabFromRouteParam();
          });
        } else {
          this.selectedFeatureFlags = newInbox?.selected_feature_flags || [];
        }
      },
      immediate: true,
    },
  },
  mounted() {
    this.fetchSharedData();
  },
  methods: {
    async improveZaloFriend() {
      if (!this.zaloPersonalDefaultFriendRequestMessage) return;
      this.isImprovingZaloFriend = true;
      try {
        const { message } = await this.processEvent(
          'improve_zalo_friend_request',
          this.zaloPersonalDefaultFriendRequestMessage
        );
        if (message) this.zaloPersonalDefaultFriendRequestMessage = message;
      } finally {
        this.isImprovingZaloFriend = false;
      }
    },
    async improveZaloGreeting() {
      if (!this.zaloPersonalDefaultGreetingMessage) return;
      this.isImprovingZaloGreeting = true;
      try {
        const { message } = await this.processEvent(
          'improve_zalo_greeting',
          this.zaloPersonalDefaultGreetingMessage
        );
        if (message) this.zaloPersonalDefaultGreetingMessage = message;
      } finally {
        this.isImprovingZaloGreeting = false;
      }
    },
    async improveAutoFollowUp(index) {
      if (!this.autoFollowUpPredefinedMessages[index]) return;
      this.isImprovingAutoFollowUps[index] = true;
      try {
        const { message } = await this.processEvent(
          'improve_auto_followup_message',
          this.autoFollowUpPredefinedMessages[index]
        );
        if (message) this.autoFollowUpPredefinedMessages[index] = message;
      } finally {
        this.isImprovingAutoFollowUps[index] = false;
      }
    },
    async checkZaloPersonalConnection() {
      if (this.isCheckingConnection) return;

      this.isCheckingConnection = true;
      try {
        const { data } = await InboxesAPI.checkConnection(this.inbox.id);
        if (data.reauthorization_required) {
          this.$store.dispatch('inboxes/get');
          useAlert(
            this.$t('INBOX_MGMT.ZALO_PERSONAL_CONNECTION.DISCONNECTED_ALERT')
          );
        } else {
          useAlert(
            this.$t('INBOX_MGMT.ZALO_PERSONAL_CONNECTION.CONNECTED_ALERT')
          );
        }
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.ZALO_PERSONAL_CONNECTION.CHECK_ERROR'));
      } finally {
        this.isCheckingConnection = false;
      }
    },
    async syncZaloPersonalFriends() {
      if (this.isSyncingFriends) return;

      this.isSyncingFriends = true;
      try {
        await InboxesAPI.syncFriends(this.inbox.id);
        useAlert(
          this.$t('INBOX_MGMT.ZALO_PERSONAL_CONNECTION.SYNC_FRIENDS_SUCCESS')
        );
      } catch (error) {
        useAlert(
          this.$t('INBOX_MGMT.ZALO_PERSONAL_CONNECTION.SYNC_FRIENDS_ERROR')
        );
      } finally {
        this.isSyncingFriends = false;
      }
    },
    fetchSharedData() {
      this.$store.dispatch('agents/get');
      this.$store.dispatch('teams/get');
      this.$store.dispatch('labels/get');
      this.$store.dispatch('macros/get');
    },
    syncInboxData() {
      if (!this.inbox || !this.inbox.id) return;

      this.avatarUrl = this.inbox.avatar_url;
      this.bubbleAvatarUrl = this.inbox.bubble_avatar_url;
      this.selectedInboxName = this.inbox.name;
      this.webhookUrl = this.inbox.webhook_url;
      this.greetingEnabled = this.inbox.greeting_enabled || false;
      this.greetingMessage = this.inbox.greeting_message || '';
      this.senderNameType = this.inbox.sender_name_type;
      this.businessName = this.inbox.business_name;
      this.allowMessagesAfterResolved =
        this.inbox.allow_messages_after_resolved;
      this.channelWebsiteUrl = this.inbox.website_url;
      this.channelWelcomeTitle = this.inbox.welcome_title;
      this.channelWelcomeTagline = this.inbox.welcome_tagline || '';
      this.selectedFeatureFlags = this.inbox.selected_feature_flags || [];
      this.replyTime = this.inbox.reply_time;
      this.locktoSingleConversation = this.inbox.lock_to_single_conversation;

      const savedBubbleSettings = LocalStorage.get(
        this.widgetBuilderStorageKey
      );
      if (savedBubbleSettings) {
        this.widgetBubblePosition = savedBubbleSettings.position || 'right';
        this.widgetBubbleType = savedBubbleSettings.type || 'standard';
        this.widgetBubbleLauncherTitle =
          savedBubbleSettings.launcherTitle || '';
      } else {
        this.widgetBubblePosition = 'right';
        this.widgetBubbleType = 'standard';
        this.widgetBubbleLauncherTitle = '';
      }

      this.autoFollowUpEnabled =
        this.inbox.auto_follow_up_config?.enabled || false;
      this.autoFollowUpMaxAttempts =
        this.inbox.auto_follow_up_config?.max_attempts || 1;
      this.autoFollowUpIntervalHours =
        this.inbox.auto_follow_up_config?.interval_hours || 24;
      this.autoFollowUpTimeMode =
        this.inbox.auto_follow_up_config?.time_mode || 'relative';
      this.autoFollowUpFixedTime =
        this.inbox.auto_follow_up_config?.fixed_time || '09:00';
      this.autoFollowUpTimezone =
        this.inbox.auto_follow_up_config?.timezone || 'Asia/Ho_Chi_Minh';
      this.autoFollowUpAiRewrite =
        this.inbox.auto_follow_up_config?.ai_rewrite || false;
      this.autoLabelEnabled = this.inbox.auto_label_enabled || false;
      this.labelSuggestionEnabled =
        this.inbox.label_suggestion_enabled || false;
      this.autoFollowUpPredefinedMessage =
        this.inbox.auto_follow_up_config?.predefined_message || '';

      const defaultMessages = Array.from({ length: 15 }, () => '');
      this.autoFollowUpPredefinedMessages =
        this.inbox.auto_follow_up_config?.predefined_messages ||
        [
          this.inbox.auto_follow_up_config?.predefined_message || '',
          ...defaultMessages,
        ].slice(0, 15);

      this.zaloPersonalDefaultFriendRequestMessage =
        this.inbox.provider_config?.default_friend_request_message || '';
      this.zaloPersonalDefaultGreetingMessage =
        this.inbox.provider_config?.default_greeting_message || '';
    },
    async fetchHealthData() {
      if (!this.inbox) return;

      if (!this.isAWhatsAppCloudChannel) {
        return;
      }

      try {
        this.isLoadingHealth = true;
        this.healthError = null;
        const response = await InboxHealthAPI.getHealthStatus(this.inbox.id);
        this.healthData = response.data;
      } catch (error) {
        this.healthError = error.message || 'Failed to fetch health data';
      } finally {
        this.isLoadingHealth = false;
      }
    },
    async registerWebhook() {
      if (!this.inbox) return;

      try {
        this.isRegisteringWebhook = true;
        await InboxHealthAPI.registerWebhook(this.inbox.id);
        useAlert(this.$t('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.REGISTER_SUCCESS'));
        await this.fetchHealthData();
      } catch (error) {
        useAlert(
          error.message ||
            this.$t('INBOX_MGMT.ACCOUNT_HEALTH.WEBHOOK.REGISTER_ERROR')
        );
      } finally {
        this.isRegisteringWebhook = false;
      }
    },
    handleFeatureFlag(e) {
      this.selectedFeatureFlags = this.toggleInput(
        this.selectedFeatureFlags,
        e.target.value
      );
    },
    toggleInput(selected, current) {
      if (selected.includes(current)) {
        const newSelectedFlags = selected.filter(flag => flag !== current);
        return newSelectedFlags;
      }
      return [...selected, current];
    },
    onTabChange(selectedTabIndex) {
      this.selectedTabIndex = selectedTabIndex;
      this.updateRouteWithoutRefresh(selectedTabIndex);
    },
    updateRouteWithoutRefresh(selectedTabIndex) {
      const tab = this.tabs[selectedTabIndex];
      if (!tab) return;

      const { accountId, inboxId } = this.$route.params;
      const baseUrl = `/app/accounts/${accountId}/settings/inboxes/${inboxId}`;

      // Append the tab key only if it's not the default.
      const newUrl =
        tab.key === 'inbox-settings' ? baseUrl : `${baseUrl}/${tab.key}`;
      // Update URL without triggering route watcher
      window.history.replaceState(null, '', newUrl);
    },
    setTabFromRouteParam() {
      const { tab: tabParam } = this.$route.params;
      if (!tabParam) {
        this.selectedTabIndex = 0;
        return;
      }
      const tabIndex = this.tabs.findIndex(tab => tab.key === tabParam);
      this.selectedTabIndex = tabIndex === -1 ? 0 : tabIndex;
    },
    async updateInbox() {
      const bubbleSettings = {
        position: this.widgetBubblePosition,
        type: this.widgetBubbleType,
        launcherTitle: this.widgetBubbleLauncherTitle,
      };
      LocalStorage.set(this.widgetBuilderStorageKey, bubbleSettings);

      try {
        const payload = {
          id: this.currentInboxId,
          name: this.selectedInboxName?.trim(),
          allow_messages_after_resolved: this.allowMessagesAfterResolved,
          greeting_enabled: this.greetingEnabled,
          greeting_message: this.greetingMessage || '',
          lock_to_single_conversation: this.locktoSingleConversation,
          sender_name_type: this.senderNameType,
          business_name: this.businessName || null,
          auto_label_enabled: this.autoLabelEnabled,
          label_suggestion_enabled: this.labelSuggestionEnabled,
          auto_follow_up_config:
            this.avatarFile || this.bubbleAvatarFile
              ? JSON.stringify({
                  enabled: this.autoFollowUpEnabled,
                  max_attempts: this.autoFollowUpMaxAttempts,
                  interval_hours: this.autoFollowUpIntervalHours,
                  time_mode: this.autoFollowUpTimeMode,
                  fixed_time: this.autoFollowUpFixedTime,
                  timezone: this.autoFollowUpTimezone,
                  ai_rewrite: this.autoFollowUpAiRewrite,
                  predefined_message: this.autoFollowUpPredefinedMessage,
                  predefined_messages: this.autoFollowUpPredefinedMessages,
                })
              : {
                  enabled: this.autoFollowUpEnabled,
                  max_attempts: this.autoFollowUpMaxAttempts,
                  interval_hours: this.autoFollowUpIntervalHours,
                  time_mode: this.autoFollowUpTimeMode,
                  fixed_time: this.autoFollowUpFixedTime,
                  timezone: this.autoFollowUpTimezone,
                  ai_rewrite: this.autoFollowUpAiRewrite,
                  predefined_message: this.autoFollowUpPredefinedMessage,
                  predefined_messages: this.autoFollowUpPredefinedMessages,
                },
          channel: {
            widget_color: this.inbox.widget_color,
            website_url: this.channelWebsiteUrl,
            webhook_url: this.webhookUrl,
            welcome_title: this.channelWelcomeTitle || '',
            welcome_tagline: this.channelWelcomeTagline || '',
            selectedFeatureFlags: this.selectedFeatureFlags,
            reply_time: this.replyTime || 'in_a_few_minutes',
            ...(this.isAZaloPersonalChannel && {
              default_friend_request_message:
                this.zaloPersonalDefaultFriendRequestMessage,
              default_greeting_message: this.zaloPersonalDefaultGreetingMessage,
            }),
          },
        };
        if (this.avatarFile || this.bubbleAvatarFile) {
          if (this.avatarFile) payload.avatar = this.avatarFile;
          if (this.bubbleAvatarFile)
            payload.channel.bubble_avatar = this.bubbleAvatarFile;
        } else {
          payload.formData = false;
        }
        await this.$store.dispatch('inboxes/updateInbox', payload);
        useAlert(this.$t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
        this.showBusinessNameInput = false;
      } catch (error) {
        useAlert(error.message || this.$t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
      }
    },
    handleImageUpload({ file, url }) {
      this.avatarFile = file;
      this.avatarUrl = url;
    },
    handleBubbleImageUpload({ file, url }) {
      this.bubbleAvatarFile = file;
      this.bubbleAvatarUrl = url;
    },

    async handleAvatarDelete() {
      try {
        await this.$store.dispatch(
          'inboxes/deleteInboxAvatar',
          this.currentInboxId
        );
        this.avatarFile = null;
        this.avatarUrl = '';
        useAlert(this.$t('INBOX_MGMT.DELETE.API.AVATAR_SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(
          error.message
            ? error.message
            : this.$t('INBOX_MGMT.DELETE.API.AVATAR_ERROR_MESSAGE')
        );
      }
    },
    async handleBubbleAvatarDelete() {
      try {
        await this.$store.dispatch(
          'inboxes/deleteBubbleAvatar',
          this.currentInboxId
        );
        this.bubbleAvatarFile = null;
        this.bubbleAvatarUrl = '';
        useAlert(this.$t('INBOX_MGMT.DELETE.API.AVATAR_SUCCESS_MESSAGE'));
      } catch (error) {
        useAlert(
          error.message
            ? error.message
            : this.$t('INBOX_MGMT.DELETE.API.AVATAR_ERROR_MESSAGE')
        );
      }
    },

    toggleSenderNameType(key) {
      this.senderNameType = key;
    },
    onClickShowBusinessNameInput() {
      this.showBusinessNameInput = true;
      this.$nextTick(() => {
        this.$refs.businessNameInput?.focus();
      });
    },
    handleZaloReauthorizeSuccess() {
      this.zaloReauthorizeModalVisible = false;
      this.$refs.zaloReauthorizeSuccessDialog.open();
      this.$store.dispatch('inboxes/get');
      setTimeout(() => {
        if (this.$refs.zaloReauthorizeSuccessDialog) {
          this.$refs.zaloReauthorizeSuccessDialog.close();
        }
      }, 3000);
    },
    closeZaloSuccessDialog() {
      if (this.$refs.zaloReauthorizeSuccessDialog) {
        this.$refs.zaloReauthorizeSuccessDialog.close();
      }
    },
    hideBusinessNameInput() {
      this.showBusinessNameInput = false;
    },
    toggleLockToSingleConversation(value) {
      this.locktoSingleConversation = value;
    },
  },
  validations: {
    webhookUrl: {
      shouldBeUrl,
    },
    selectedInboxName: {},
  },
};
</script>

<template>
  <div
    v-if="uiFlags.isFetching"
    class="flex items-center justify-center h-full w-full"
  >
    <SpinnerLoader :size="28" class="text-n-orange-9" />
  </div>
  <div
    v-else
    class="grid grid-rows-[auto_1fr] h-full flex-grow flex-shrink pr-0 pl-0 w-full min-w-0 settings"
  >
    <SettingIntroBanner
      :header-image="inbox.avatarUrl"
      :header-title="inboxName"
    >
      <woot-tabs
        class="[&_ul]:p-0 top-px relative"
        :index="selectedTabIndex"
        :border="false"
        @change="onTabChange"
      >
        <woot-tabs-item
          v-for="(tab, index) in tabs"
          :key="tab.key"
          :index="index"
          :name="tab.name"
          :show-badge="false"
          is-compact
        />
      </woot-tabs>
    </SettingIntroBanner>
    <section class="w-full overflow-auto py-8">
      <div class="max-w-7xl mx-auto w-full">
        <FacebookReauthorize
          v-if="facebookUnauthorized"
          :inbox="inbox"
          class="mb-4"
          :class="bannerMaxWidth"
        />
        <InstagramReauthorize
          v-if="instagramUnauthorized"
          :inbox="inbox"
          class="mb-4"
          :class="bannerMaxWidth"
        />
        <TiktokReauthorize
          v-if="tiktokUnauthorized"
          :inbox="inbox"
          class="mb-4"
          :class="bannerMaxWidth"
        />
        <WhatsappReauthorize
          v-if="whatsappUnauthorized"
          :whatsapp-registration-incomplete="whatsappRegistrationIncomplete"
          :inbox="inbox"
          class="mb-4"
          :class="bannerMaxWidth"
        />
        <DuplicateInboxBanner
          v-if="hasDuplicateInstagramInbox"
          :content="$t('INBOX_MGMT.ADD.INSTAGRAM.DUPLICATE_INBOX_BANNER')"
          class="mx-6 mb-4"
          :class="bannerMaxWidth"
        />
        <InboxReconnectionRequired
          v-if="zaloPersonalUnauthorized"
          class="mx-6 mb-4"
          :class="bannerMaxWidth"
          @reauthorize="zaloReauthorizeModalVisible = true"
        />
        <Banner
          v-if="isAZaloPersonalChannel && !zaloPersonalUnauthorized"
          color="blue"
          class="mx-6 mb-4"
          :class="bannerMaxWidth"
          :action-label="
            isCheckingConnection
              ? $t('INBOX_MGMT.ZALO_PERSONAL_CONNECTION.CHECKING')
              : $t('INBOX_MGMT.ZALO_PERSONAL_CONNECTION.CHECK_BUTTON')
          "
          :action-label-secondary="
            $t('INBOX_MGMT.ZALO_PERSONAL_CONNECTION.RECONNECT_BUTTON')
          "
          :action-label-tertiary="
            isSyncingFriends
              ? $t('INBOX_MGMT.ZALO_PERSONAL_CONNECTION.CHECKING')
              : $t('INBOX_MGMT.ZALO_PERSONAL_CONNECTION.SYNC_FRIENDS_BUTTON')
          "
          @action="checkZaloPersonalConnection"
          @secondary-action="zaloReauthorizeModalVisible = true"
          @tertiary-action="syncZaloPersonalFriends"
        >
          {{ $t('INBOX_MGMT.ZALO_PERSONAL_CONNECTION.CONNECTED') }}
        </Banner>

        <div
          v-if="selectedTabKey === 'inbox-settings'"
          class="flex flex-col md:flex-row items-center lg:items-start justify-between gap-5 lg:gap-10 mx-6"
        >
          <div
            class="flex-1 flex flex-col min-w-0"
            :class="{
              'max-w-2xl': isAWebWidgetInbox,
              'max-w-4xl': !isAWebWidgetInbox,
            }"
          >
            <div class="flex flex-wrap gap-6 mb-4">
              <div class="flex flex-col gap-1 items-start">
                <label class="text-heading-3 text-n-slate-12">
                  {{
                    $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_AVATAR.LABEL')
                  }}
                </label>
                <Avatar
                  :src="avatarUrl"
                  :size="64"
                  :icon-name="inboxIcon"
                  name=""
                  allow-upload
                  branded
                  @upload="handleImageUpload"
                  @delete="handleAvatarDelete"
                />
              </div>
            </div>
            <SettingsFieldSection :label="inboxNameLabel">
              <woot-input
                v-model="selectedInboxName"
                class="[&_input]:!mb-0"
                :class="{ error: v$.selectedInboxName.$error }"
                :placeholder="inboxNamePlaceHolder"
                :error="
                  v$.selectedInboxName.$error
                    ? $t('INBOX_MGMT.ADD.CHANNEL_NAME.ERROR')
                    : ''
                "
                @blur="v$.selectedInboxName.$touch"
              />
            </SettingsFieldSection>
            <SettingsFieldSection
              v-if="isAPIInbox"
              :label="
                $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WEBHOOK_URL.LABEL')
              "
            >
              <woot-input
                v-model="webhookUrl"
                class="[&_input]:!mb-0"
                :class="{ error: v$.webhookUrl.$error }"
                :placeholder="
                  $t(
                    'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WEBHOOK_URL.PLACEHOLDER'
                  )
                "
                :error="
                  v$.webhookUrl.$error
                    ? $t(
                        'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WEBHOOK_URL.ERROR'
                      )
                    : ''
                "
                @blur="v$.webhookUrl.$touch"
              />
            </SettingsFieldSection>

            <SettingsFieldSection
              v-if="isAWebWidgetInbox"
              :label="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.LABEL')"
            >
              <woot-input
                v-model="channelWebsiteUrl"
                class="[&_input]:!mb-0"
                :placeholder="
                  $t(
                    'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_DOMAIN.PLACEHOLDER'
                  )
                "
              />
            </SettingsFieldSection>

            <SettingsFieldSection
              v-if="isAWhatsAppChannel"
              :label="$t('INBOX_MGMT.ADD.WHATSAPP.PROVIDERS.LABEL')"
            >
              <input
                v-model="whatsAppAPIProviderName"
                type="text"
                disabled
                class="!mb-0"
              />
            </SettingsFieldSection>

            <SettingsFieldSection
              v-if="canLocktoSingleConversation"
              :label="
                $t('INBOX_MGMT.SETTINGS_POPUP.LOCK_TO_SINGLE_CONVERSATION')
              "
              class="[&>div>div]:justify-end [&>div>div]:flex lg:[&>div:first-child]:h-12 [&>div:first-child]:h-16"
            >
              <template #extra>
                <LockToSingleConversationPreview
                  :lock-to-single-conversation="locktoSingleConversation"
                  @update="toggleLockToSingleConversation"
                />
              </template>
            </SettingsFieldSection>

            <SettingsFieldSection
              v-if="isAWebWidgetInbox"
              :label="$t('INBOX_MGMT.EDIT.SENDER_NAME_SECTION.TITLE')"
              class="[&>div>div]:justify-end [&>div>div]:flex lg:[&>div:first-child]:h-12 [&>div:first-child]:h-16"
            >
              <NextButton
                v-if="!showBusinessNameInput"
                ghost
                blue
                sm
                :label="
                  $t(
                    'INBOX_MGMT.EDIT.SENDER_NAME_SECTION.BUSINESS_NAME.BUTTON_TEXT'
                  )
                "
                @click="onClickShowBusinessNameInput"
              />

              <div
                v-if="showBusinessNameInput"
                v-on-clickaway="hideBusinessNameInput"
                class="flex justify-end gap-2 w-full"
              >
                <input
                  ref="businessNameInput"
                  v-model="businessName"
                  :placeholder="
                    $t(
                      'INBOX_MGMT.EDIT.SENDER_NAME_SECTION.BUSINESS_NAME.PLACEHOLDER'
                    )
                  "
                  class="!mb-0"
                  type="text"
                />
                <NextButton
                  :label="
                    $t(
                      'INBOX_MGMT.EDIT.SENDER_NAME_SECTION.BUSINESS_NAME.SAVE_BUTTON_TEXT'
                    )
                  "
                  class="flex-shrink-0"
                  @click="updateInbox"
                />
              </div>

              <template #extra>
                <SenderNameExamplePreview
                  :sender-name-type="senderNameType"
                  :business-name="businessName"
                  :is-website-channel="isAWebWidgetInbox"
                  @update="toggleSenderNameType"
                />
              </template>
            </SettingsFieldSection>

            <SettingsAccordion
              v-if="isAWebWidgetInbox"
              :title="$t('INBOX_MGMT.WIDGET_FEATURES')"
              class="mt-6"
            >
              <SettingsFieldSection
                :label="
                  $t(
                    'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TITLE.LABEL'
                  )
                "
              >
                <woot-input
                  v-model="channelWelcomeTitle"
                  class="[&_input]:!mb-0"
                  :placeholder="
                    $t(
                      'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TITLE.PLACEHOLDER'
                    )
                  "
                />
              </SettingsFieldSection>

              <SettingsFieldSection
                :label="
                  $t(
                    'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TAGLINE.LABEL'
                  )
                "
                class="[&>div]:!items-start [&>div>label]:mt-1"
              >
                <Editor
                  v-model="channelWelcomeTagline"
                  :placeholder="
                    $t(
                      'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_WELCOME_TAGLINE.PLACEHOLDER'
                    )
                  "
                  :max-length="255"
                  channel-type="Context::InboxSettings"
                />
              </SettingsFieldSection>

              <SettingsFieldSection
                :label="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.WIDGET_COLOR.LABEL')"
              >
                <div class="justify-start">
                  <ColorPicker v-model="inbox.widget_color" />
                </div>
              </SettingsFieldSection>
              <SettingsFieldSection
                :label="
                  $t('INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE')
                "
              >
                <div class="flex flex-col gap-6">
                  <div class="flex items-center gap-6">
                    <div class="flex items-center gap-2">
                      <label class="text-n-slate-11 text-heading-3">
                        {{
                          $t(
                            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_POSITION_LABEL'
                          )
                        }}
                      </label>
                      <FilterSelect
                        v-model="widgetBubblePosition"
                        :options="[
                          {
                            label: $t(
                              'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_POSITION.LEFT'
                            ),
                            value: 'left',
                          },
                          {
                            label: $t(
                              'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_POSITION.RIGHT'
                            ),
                            value: 'right',
                          },
                        ]"
                        class="[&>button]:!py-0 [&>button]:!pl-0 [&>button]:!pr-1 [&>button]:!bg-transparent [&>button]:!border-0 min-w-16"
                      />
                    </div>
                    <div class="h-3 w-px bg-n-weak rounded-lg" />
                    <div class="flex items-center gap-2">
                      <label class="text-n-slate-11 text-heading-3">
                        {{
                          $t(
                            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_TYPE_LABEL'
                          )
                        }}
                      </label>
                      <FilterSelect
                        v-model="widgetBubbleType"
                        :options="[
                          {
                            label: $t(
                              'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_TYPE.STANDARD'
                            ),
                            value: 'standard',
                          },
                          {
                            label: $t(
                              'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_TYPE.EXPANDED_BUBBLE'
                            ),
                            value: 'expanded_bubble',
                          },
                        ]"
                        class="[&>button]:!py-0 [&>button]:!pl-0 [&>button]:!pr-1 [&>button]:!bg-transparent [&>button]:!border-0 min-w-16"
                      />
                    </div>
                  </div>
                  <div v-if="false" class="flex items-center gap-6">
                    <div class="flex flex-col gap-1 items-start">
                      <label class="text-heading-3 text-n-slate-12">
                        {{
                          $t(
                            'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.BUBBLE_AVATAR.OPEN_LABEL'
                          )
                        }}
                      </label>
                      <Avatar
                        :src="bubbleAvatarUrl"
                        icon-name="i-lucide-message-circle-more"
                        :hide-delete="!bubbleAvatarUrl"
                        :size="64"
                        name=""
                        allow-upload
                        branded
                        @upload="handleBubbleImageUpload"
                        @delete="handleBubbleAvatarDelete"
                      />
                    </div>
                  </div>
                </div>
              </SettingsFieldSection>

              <SettingsFieldSection
                v-if="widgetBubbleType === 'expanded_bubble'"
                :label="
                  $t(
                    'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_LAUNCHER_TITLE.LABEL'
                  )
                "
              >
                <woot-input
                  v-model="widgetBubbleLauncherTitle"
                  :placeholder="
                    $t(
                      'INBOX_MGMT.WIDGET_BUILDER.WIDGET_OPTIONS.WIDGET_BUBBLE_LAUNCHER_TITLE.PLACE_HOLDER'
                    )
                  "
                  class="[&_input]:!mb-0"
                />
              </SettingsFieldSection>
              <SettingsFieldSection
                :label="$t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.TITLE')"
                :help-text="
                  $t('INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.HELP_TEXT')
                "
              >
                <SelectInput
                  v-model="replyTime"
                  :options="[
                    {
                      value: 'in_a_few_minutes',
                      label: $t(
                        'INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.IN_A_FEW_MINUTES'
                      ),
                    },
                    {
                      value: 'in_a_few_hours',
                      label: $t(
                        'INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.IN_A_FEW_HOURS'
                      ),
                    },
                    {
                      value: 'in_a_day',
                      label: $t(
                        'INBOX_MGMT.ADD.WEBSITE_CHANNEL.REPLY_TIME.IN_A_DAY'
                      ),
                    },
                  ]"
                />
              </SettingsFieldSection>

              <SettingsFieldSection
                :label="$t('INBOX_MGMT.FEATURES.LABEL')"
                class="[&>div]:!items-start [&>div>label]:mt-2"
              >
                <div class="flex flex-col gap-1 items-start">
                  <div class="flex gap-2 pt-2 py-0.5">
                    <input
                      v-model="selectedFeatureFlags"
                      type="checkbox"
                      value="attachments"
                      @input="handleFeatureFlag"
                    />
                    <label for="attachments">
                      {{ $t('INBOX_MGMT.FEATURES.DISPLAY_FILE_PICKER') }}
                    </label>
                  </div>
                  <div class="flex gap-2 py-0.5">
                    <input
                      v-model="selectedFeatureFlags"
                      type="checkbox"
                      value="emoji_picker"
                      @input="handleFeatureFlag"
                    />
                    <label for="emoji_picker">
                      {{ $t('INBOX_MGMT.FEATURES.DISPLAY_EMOJI_PICKER') }}
                    </label>
                  </div>
                  <div class="flex gap-2 py-0.5">
                    <input
                      v-model="selectedFeatureFlags"
                      type="checkbox"
                      value="end_conversation"
                      @input="handleFeatureFlag"
                    />
                    <label for="end_conversation">
                      {{ $t('INBOX_MGMT.FEATURES.ALLOW_END_CONVERSATION') }}
                    </label>
                  </div>
                  <div class="flex gap-2 py-0.5">
                    <input
                      v-model="selectedFeatureFlags"
                      type="checkbox"
                      value="use_inbox_avatar_for_bot"
                      @input="handleFeatureFlag"
                    />
                    <label for="use_inbox_avatar_for_bot">
                      {{ $t('INBOX_MGMT.FEATURES.USE_INBOX_AVATAR_FOR_BOT') }}
                    </label>
                  </div>
                </div>
              </SettingsFieldSection>
            </SettingsAccordion>

            <SettingsAccordion
              :title="$t('INBOX_MGMT.CHANNEL_PREFERENCES')"
              class="mt-6"
            >
              <SettingsToggleSection
                v-model="greetingEnabled"
                :header="
                  $t(
                    'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_TOGGLE.LABEL'
                  )
                "
                :description="
                  $t(
                    'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_TOGGLE.HELP_TEXT'
                  )
                "
              >
                <template v-if="greetingEnabled" #editor>
                  <GreetingsEditor
                    v-model="greetingMessage"
                    :label="
                      $t(
                        'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_MESSAGE.LABEL'
                      )
                    "
                    :placeholder="
                      $t(
                        'INBOX_MGMT.ADD.WEBSITE_CHANNEL.CHANNEL_GREETING_MESSAGE.PLACEHOLDER'
                      )
                    "
                    :richtext="!textAreaChannels"
                  />
                </template>
              </SettingsToggleSection>

              <SettingsToggleSection
                v-if="isAWebWidgetInbox"
                v-model="allowMessagesAfterResolved"
                :header="
                  $t('INBOX_MGMT.SETTINGS_POPUP.ALLOW_MESSAGES_AFTER_RESOLVED')
                "
                :description="
                  $t(
                    'INBOX_MGMT.SETTINGS_POPUP.ALLOW_MESSAGES_AFTER_RESOLVED_SUB_TEXT'
                  )
                "
              />
            </SettingsAccordion>

            <div v-if="isAZaloPersonalChannel" class="mt-6">
              <SettingsAccordion
                :title="$t('INBOX_MGMT.ADD.ZALO_PERSONAL.CONFIGURATION_TITLE')"
              >
                <div class="flex flex-col gap-4 mt-2 mb-2">
                  <div class="flex flex-col w-full">
                    <TextArea
                      v-model="zaloPersonalDefaultFriendRequestMessage"
                      :label="
                        $t(
                          'INBOX_MGMT.ADD.ZALO_PERSONAL.DEFAULT_FRIEND_REQUEST_MESSAGE_TITLE'
                        )
                      "
                      :message="
                        $t(
                          'INBOX_MGMT.ADD.ZALO_PERSONAL.DEFAULT_FRIEND_REQUEST_MESSAGE_SUBTITLE'
                        )
                      "
                      auto-height
                      class="w-full"
                    />
                    <div class="flex justify-start mt-2">
                      <NextButton
                        icon="i-lucide-wand-2"
                        size="xs"
                        color="slate"
                        :label="
                          $t(
                            'TEAMS_SETTINGS.FORM.IMPROVE_BY_AI',
                            'Improve by AI'
                          )
                        "
                        :is-loading="isImprovingZaloFriend"
                        @click.prevent="improveZaloFriend"
                      />
                    </div>
                  </div>
                  <div class="flex flex-col w-full">
                    <TextArea
                      v-model="zaloPersonalDefaultGreetingMessage"
                      :label="
                        $t(
                          'INBOX_MGMT.ADD.ZALO_PERSONAL.DEFAULT_GREETING_MESSAGE_TITLE'
                        )
                      "
                      :message="
                        $t(
                          'INBOX_MGMT.ADD.ZALO_PERSONAL.DEFAULT_GREETING_MESSAGE_SUBTITLE'
                        )
                      "
                      auto-height
                      class="w-full"
                    />
                    <div class="flex justify-start mt-2">
                      <NextButton
                        icon="i-lucide-wand-2"
                        size="xs"
                        color="slate"
                        :label="
                          $t(
                            'TEAMS_SETTINGS.FORM.IMPROVE_BY_AI',
                            'Improve by AI'
                          )
                        "
                        :is-loading="isImprovingZaloGreeting"
                        @click.prevent="improveZaloGreeting"
                      />
                    </div>
                  </div>
                </div>
              </SettingsAccordion>
            </div>

            <div class="w-full flex justify-end items-center py-4 mt-2">
              <NextButton
                v-if="isAPIInbox"
                type="submit"
                :disabled="v$.webhookUrl.$invalid"
                :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
                :is-loading="uiFlags.isUpdating"
                @click="updateInbox"
              />
              <NextButton
                v-else
                type="submit"
                :disabled="v$.$invalid"
                :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
                :is-loading="uiFlags.isUpdating"
                @click="updateInbox"
              />
            </div>
          </div>

          <div
            v-if="isAWebWidgetInbox"
            class="flex-1 sticky top-4 self-start max-w-lg flex-shrink-0 w-full min-w-0"
          >
            <div
              class="flex flex-col outline -outline-offset-1 outline-1 outline-n-weak w-full px-3 pt-3 pb-8 bg-n-surface-1 rounded-2xl min-h-[45rem] overflow-hidden"
            >
              <Widget
                :welcome-heading="channelWelcomeTitle"
                :welcome-tagline="channelWelcomeTagline"
                :website-name="selectedInboxName"
                :logo="avatarUrl"
                is-online
                :reply-time="inbox.active_bot ? 'in_a_few_minutes' : replyTime"
                :color="inbox.widget_color"
                :widget-bubble-position="widgetBubblePosition"
                :widget-bubble-launcher-title="widgetBubbleLauncherTitle"
                :widget-bubble-type="widgetBubbleType"
                :bubble-logo="bubbleAvatarUrl"
                :web-widget-script="inbox.web_widget_script"
              />
            </div>
          </div>
        </div>

        <div v-if="selectedTabKey === 'collaborators'" class="mx-6 max-w-4xl">
          <CollaboratorsPage :inbox="inbox" />
        </div>
        <div
          v-if="selectedTabKey === 'configuration'"
          class="mx-6"
          :class="isAWebWidgetInbox ? 'max-w-7xl' : 'max-w-4xl'"
        >
          <ConfigurationPage :inbox="inbox" />
          <div class="relative mt-6">
            <SettingsAccordion
              :title="$t('INBOX_MGMT.SETTINGS_POPUP.AUTO_LABEL_TITLE')"
            >
              <SettingsToggleSection
                v-model="labelSuggestionEnabled"
                :disabled="!isCaptainEnabled"
                :header="
                  $t(
                    'INBOX_MGMT.SETTINGS_POPUP.LABEL_SUGGESTION_TOGGLE',
                    'Suggest labels to agents'
                  )
                "
                :description="
                  $t(
                    'INBOX_MGMT.SETTINGS_POPUP.LABEL_SUGGESTION_DESC',
                    'Shows AI-generated label suggestions in the conversation view.'
                  )
                "
              />

              <SettingsToggleSection
                v-model="autoLabelEnabled"
                :disabled="!isCaptainEnabled"
                :header="$t('INBOX_MGMT.SETTINGS_POPUP.AUTO_LABEL_TOGGLE')"
                :description="$t('INBOX_MGMT.SETTINGS_POPUP.AUTO_LABEL_DESC')"
                class="mt-4"
              />
            </SettingsAccordion>

            <SettingsAccordion
              v-if="!isAWebWidgetInbox"
              :title="$t('INBOX_MGMT.SETTINGS_POPUP.AUTO_FOLLOWUP_TITLE')"
              class="mt-6"
            >
              <SettingsToggleSection
                v-model="autoFollowUpEnabled"
                :header="$t('INBOX_MGMT.SETTINGS_POPUP.AUTO_FOLLOWUP_TOGGLE')"
                :description="
                  $t('INBOX_MGMT.SETTINGS_POPUP.AUTO_FOLLOWUP_DESC')
                "
              >
                <template v-if="autoFollowUpEnabled" #editor>
                  <div class="flex flex-col gap-4 mt-2">
                    <div class="flex flex-col gap-1">
                      <label class="text-n-slate-11 text-small font-medium">
                        {{
                          $t(
                            'INBOX_MGMT.SETTINGS_POPUP.AUTO_FOLLOWUP_DELAY_LABEL'
                          )
                        }}
                      </label>
                      <div class="flex items-center gap-2">
                        <woot-input
                          v-model="autoFollowUpIntervalHours"
                          type="number"
                          min="1"
                          max="999"
                          class="[&_input]:!mb-0 w-[150px]"
                        />
                      </div>
                      <p class="text-[12px] text-n-slate-11">
                        {{
                          $t(
                            'INBOX_MGMT.SETTINGS_POPUP.AUTO_FOLLOWUP_LIMIT_WARNING'
                          )
                        }}
                      </p>
                    </div>

                    <div class="flex flex-col gap-1 mt-2">
                      <label class="text-n-slate-11 text-small font-medium">
                        {{
                          $t(
                            'INBOX_MGMT.SETTINGS_POPUP.AUTO_FOLLOWUP_MAX_ATTEMPTS'
                          )
                        }}
                      </label>
                      <FilterSelect
                        v-model="autoFollowUpMaxAttempts"
                        :options="dynamicMaxAttemptsOptions"
                        class="w-full mt-1 [&_button]:w-full [&_button]:justify-between [&>.absolute]:w-full [&_.min-w-56]:!min-w-full [&_.min-w-56]:!w-full [&_button]:!h-[38px] [&_button]:!border-n-weak [&_button]:!bg-n-alpha-1"
                      />
                    </div>

                    <div class="flex flex-col gap-1 mt-2">
                      <label class="text-n-slate-11 text-small font-medium">
                        {{
                          $t(
                            'INBOX_MGMT.SETTINGS_POPUP.AUTO_FOLLOWUP_TIME_MODE'
                          )
                        }}
                      </label>
                      <FilterSelect
                        v-model="autoFollowUpTimeMode"
                        :options="[
                          {
                            value: 'relative',
                            label: $t(
                              'INBOX_MGMT.SETTINGS_POPUP.AUTO_FOLLOWUP_TIME_MODE_RELATIVE'
                            ),
                          },
                          {
                            value: 'fixed',
                            label: $t(
                              'INBOX_MGMT.SETTINGS_POPUP.AUTO_FOLLOWUP_TIME_MODE_FIXED'
                            ),
                          },
                        ]"
                        class="w-full mt-1 [&_button]:w-full [&_button]:justify-between [&>.absolute]:w-full [&_.min-w-56]:!min-w-full [&_.min-w-56]:!w-full [&_button]:!h-[38px] [&_button]:!border-n-weak [&_button]:!bg-n-alpha-1"
                      />
                    </div>

                    <div
                      v-if="autoFollowUpTimeMode === 'fixed'"
                      class="flex gap-4 mt-2"
                    >
                      <div class="flex flex-col gap-1 w-1/2">
                        <label class="text-n-slate-11 text-small font-medium">
                          {{
                            $t(
                              'INBOX_MGMT.SETTINGS_POPUP.AUTO_FOLLOWUP_FIXED_TIME_LABEL'
                            )
                          }}
                        </label>
                        <woot-input
                          v-model="autoFollowUpFixedTime"
                          type="time"
                          class="[&_input]:!mb-0"
                        />
                      </div>
                      <div class="flex flex-col gap-1 w-1/2">
                        <label class="text-n-slate-11 text-small font-medium">
                          {{
                            $t(
                              'INBOX_MGMT.SETTINGS_POPUP.AUTO_FOLLOWUP_TIMEZONE_LABEL'
                            )
                          }}
                        </label>
                        <woot-input
                          v-model="autoFollowUpTimezone"
                          type="text"
                          class="[&_input]:!mb-0"
                        />
                      </div>
                    </div>

                    <SettingsToggleSection
                      v-model="autoFollowUpAiRewrite"
                      :header="
                        $t(
                          'INBOX_MGMT.SETTINGS_POPUP.AUTO_FOLLOWUP_AI_REWRITE_TOGGLE',
                          'Sử dụng AI viết lại nội dung'
                        )
                      "
                      :description="
                        $t(
                          'INBOX_MGMT.SETTINGS_POPUP.AUTO_FOLLOWUP_AI_REWRITE_DESC',
                          'AI sẽ dựa vào ngữ cảnh cuộc trò chuyện để viết lại tin nhắn mẫu một cách tự nhiên.'
                        )
                      "
                      class="mt-4 bg-transparent p-0 border-0"
                    />

                    <div class="flex flex-col gap-3 mt-3">
                      <div
                        v-for="(n, index) in autoFollowUpMaxAttempts"
                        :key="'predefined-' + index"
                        class="w-full mt-2"
                      >
                        <TextArea
                          v-model="autoFollowUpPredefinedMessages[index]"
                          :label="`${$t('INBOX_MGMT.SETTINGS_POPUP.AUTO_FOLLOWUP_PREDEFINED_MESSAGE')} ${index + 1}`"
                          placeholder="Hello, are you still there?"
                          auto-height
                          class="w-full"
                        />
                        <div class="flex justify-start mt-2">
                          <NextButton
                            icon="i-lucide-wand-2"
                            size="xs"
                            color="slate"
                            :label="
                              $t(
                                'TEAMS_SETTINGS.FORM.IMPROVE_BY_AI',
                                'Improve by AI'
                              )
                            "
                            :is-loading="isImprovingAutoFollowUps[index]"
                            @click.prevent="improveAutoFollowUp(index)"
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                </template>
              </SettingsToggleSection>
            </SettingsAccordion>
          </div>

          <div class="w-full flex justify-end items-center py-4 mb-4">
            <NextButton
              type="submit"
              :label="$t('INBOX_MGMT.SETTINGS_POPUP.UPDATE')"
              :is-loading="uiFlags.isUpdating"
              @click="updateInbox"
            />
          </div>
        </div>

        <div v-if="selectedTabKey === 'pre-chat-form'">
          <PreChatFormSettings :inbox="inbox" />
        </div>
        <div v-if="selectedTabKey === 'business-hours'">
          <WeeklyAvailability :inbox="inbox" />
        </div>
        <div
          v-if="selectedTabKey === 'bot-configuration'"
          class="relative min-h-[400px]"
        >
          <BotConfiguration :inbox="inbox" />
        </div>
        <div v-if="selectedTabKey === 'posts-and-comments'">
          <FacebookPostsAndComments :inbox="inbox" />
        </div>

        <div v-if="selectedTabKey === 'label-sync'" class="mx-6 max-w-4xl">
          <ZaloPersonalLabelSync :inbox="inbox" />
        </div>

        <div v-if="selectedTabKey === 'whatsapp-health'">
          <AccountHealth
            :health-data="healthData"
            :is-registering-webhook="isRegisteringWebhook"
            @register-webhook="registerWebhook"
          />
        </div>
      </div>
    </section>

    <woot-modal
      v-model:show="zaloReauthorizeModalVisible"
      :on-close="
        () => {
          zaloReauthorizeModalVisible = false;
        }
      "
    >
      <div class="flex flex-col h-auto overflow-auto">
        <div class="px-8 pb-8 pt-2">
          <ZaloReauthorize
            :inbox="inbox"
            @success="handleZaloReauthorizeSuccess"
          />
        </div>
      </div>
    </woot-modal>

    <Dialog
      ref="zaloReauthorizeSuccessDialog"
      :title="$t('INBOX_MGMT.ZALO_PERSONAL_CONNECTION.RECONNECT_SUCCESS.TITLE')"
      :description="
        $t('INBOX_MGMT.ZALO_PERSONAL_CONNECTION.RECONNECT_SUCCESS.DESCRIPTION')
      "
      width="sm"
      :show-cancel-button="false"
      :show-confirm-button="false"
    >
      <template #footer>
        <div class="w-full">
          <NextButton
            class="w-full"
            color="blue"
            :label="
              $t('INBOX_MGMT.ZALO_PERSONAL_CONNECTION.RECONNECT_SUCCESS.CLOSE')
            "
            @click="closeZaloSuccessDialog"
          />
        </div>
      </template>
    </Dialog>
  </div>
</template>
