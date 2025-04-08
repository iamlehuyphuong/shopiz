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
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';
import CloseNavIcon from './icons/CloseNavIcon.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';

export default {
 
  components: {
    ReadDocsIcon,
    Logo,
    PrimaryNavItem,
    OptionsMenu,
    AgentDetails,
    NotificationBell,
    CloseNavIcon,
  },
  setup() {
    const { uiSettings } = useUISettings();

    return {
      uiSettings,
    };
  },

  computed: {
    ReadDocsIcon() {
      return ReadDocsIcon;
    },
    isSidebarOpen() {
      const { show_secondary_sidebar: showSecondarySidebar } = this.uiSettings;
      return showSecondarySidebar;
    },
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
    onMenuItemClick() {
      emitter.emit(BUS_EVENTS.TOGGLE_SIDEMENU);
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col justify-between w-[4.5rem] h-full bg-linear-primary-y-b"
  >
    <div class="flex flex-col items-center">
      <Logo
        :source="logoSource"
        :name="installationName"
        :account-id="accountId"
        class="mt-5 my-6 mx-auto rounded-lg bg-white p-1"
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
    <div class="flex flex-col items-center justify-end pb-6 gap-4">
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
      <label class="cursor-pointer">
        <input type="checkbox" class="hidden peer" @change="onMenuItemClick"
        :checked="isSidebarOpen"
        />
        <CloseNavIcon
          class="transition-transform duration-300 peer-checked:-scale-x-100"
        />
      </label>
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
