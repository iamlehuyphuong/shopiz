<script>
import Logo from './Logo.vue';
import PrimaryNavItem from './PrimaryNavItem.vue';
import OptionsMenu from './OptionsMenu.vue';
import AgentDetails from './AgentDetails.vue';
import NotificationBell from './NotificationBell.vue';
import wootConstants from 'dashboard/constants/globals';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { ACCOUNT_EVENTS } from '../../../helper/AnalyticsHelper/events';
import { useTrack } from 'dashboard/composables';
import ReadDocsIcon from 'components/layout/sidebarComponents/icons/ReadDocsIcon.vue';

export default {
  computed: {
    ReadDocsIcon() {
      return ReadDocsIcon
    }
  },
  components: {
    ReadDocsIcon,
    Logo,
    PrimaryNavItem,
    OptionsMenu,
    AgentDetails,
    NotificationBell,
  },
  props: {
    isACustomBrandedInstance: {
      type: Boolean,
      default: false,
    },
    logoSource: {
      type: String,
      default: '',
    },
    installationName: {
      type: String,
      default: '',
    },
    accountId: {
      type: Number,
      default: 0,
    },
    menuItems: {
      type: Array,
      default: () => [],
    },
    activeMenuItem: {
      type: String,
      default: '',
    },
  },
  emits: ['toggleAccounts', 'openNotificationPanel', 'openKeyShortcutModal'],
  data() {
    return {
      helpDocsURL: wootConstants.DOCS_URL,
      showOptionsMenu: false,
    };
  },
  methods: {
    frontendURL,
    toggleOptions() {
      this.showOptionsMenu = !this.showOptionsMenu;
    },
    toggleAccountModal() {
      this.$emit('toggleAccounts');
    },
    toggleSupportChatWindow() {
      window.$chatwoot.toggle();
    },
    openNotificationPanel() {
      useTrack(ACCOUNT_EVENTS.OPENED_NOTIFICATIONS);
      this.$emit('openNotificationPanel');
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col justify-between w-16 py-2 h-full bg-gradient-to-b from-[#E24C4A] to-[#386BB7]"
  >
    <div class="flex flex-col items-center">
      <Logo
        :source="logoSource"
        :name="installationName"
        :account-id="accountId"
        class="my-4 mx-auto"
      />
      <PrimaryNavItem
        v-for="menuItem in menuItems"
        :id="menuItem.key"
        :key="menuItem.toState"
        :icon="menuItem.icon"
        :name="menuItem.label"
        :to="menuItem.toState"
        :is-child-menu-active="menuItem.key === activeMenuItem"
      />
    </div>
    <div class="flex flex-col items-center justify-end pb-6">
      <a
        v-if="!isACustomBrandedInstance"
        v-tooltip.right="$t(`SIDEBAR.DOCS`)"
        :href="helpDocsURL"
        class="relative flex items-center justify-center w-10 px-1 h-10 my-2 rounded-lg text-white"
        rel="noopener noreferrer nofollow"
        target="_blank"
      >
        <component :is="ReadDocsIcon" />
        <span class="sr-only">{{ $t(`SIDEBAR.DOCS`) }}</span>
      </a>
      <NotificationBell @open-notification-panel="openNotificationPanel" />
      <AgentDetails @toggle-menu="toggleOptions" />
      <OptionsMenu
        :show="showOptionsMenu"
        @toggle-accounts="toggleAccountModal"
        @show-support-chat-window="toggleSupportChatWindow"
        @open-key-shortcut-modal="$emit('openKeyShortcutModal')"
        @close="toggleOptions"
      />
    </div>
  </div>
</template>
