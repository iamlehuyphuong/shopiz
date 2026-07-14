<script>
import { defineAsyncComponent, ref, computed, watch } from 'vue';

import NextSidebar from 'next/sidebar/Sidebar.vue';
import TopHeader from 'next/TopHeader.vue';
import WootKeyShortcutModal from 'dashboard/components/widgets/modal/WootKeyShortcutModal.vue';
import AddAccountModal from 'dashboard/components/app/AddAccountModal.vue';
import UpgradePage from 'dashboard/routes/dashboard/upgrade/UpgradePage.vue';

import { useUISettings } from 'dashboard/composables/useUISettings';
import { useAccount } from 'dashboard/composables/useAccount';
import { useWindowSize } from '@vueuse/core';

import wootConstants from 'dashboard/constants/globals';

const CommandBar = defineAsyncComponent(
  () => import('./commands/commandbar.vue')
);

const FloatingCallWidget = defineAsyncComponent(
  () => import('dashboard/components/widgets/FloatingCallWidget.vue')
);

import CopilotLauncher from 'dashboard/components-next/copilot/CopilotLauncher.vue';

import MobileSidebarLauncher from 'dashboard/components-next/sidebar/MobileSidebarLauncher.vue';
import { useCallsStore } from 'dashboard/stores/calls';
import { useRoute } from 'vue-router';
import { usePolicy } from 'dashboard/composables/usePolicy';
import FeatureLockOverlay from 'dashboard/routes/dashboard/upgrade/FeatureLockOverlay.vue';

export default {
  components: {
    TopHeader,
    NextSidebar,
    CommandBar,
    WootKeyShortcutModal,
    AddAccountModal,
    UpgradePage,
    CopilotLauncher,

    FloatingCallWidget,
    MobileSidebarLauncher,
    FeatureLockOverlay,
    OnboardingModal: defineAsyncComponent(
      () => import('dashboard/components/app/OnboardingModal.vue')
    ),
    WelcomeTrialModal: defineAsyncComponent(
      () => import('dashboard/components/app/WelcomeTrialModal.vue')
    ),
  },
  setup() {
    const upgradePageRef = ref(null);
    const { uiSettings, updateUISettings } = useUISettings();
    const { accountId } = useAccount();
    const { width: windowWidth } = useWindowSize();
    const callsStore = useCallsStore();
    const route = useRoute();
    const { shouldShowPaywall } = usePolicy();

    const isFeatureLocked = computed(() => {
      const featureFlag = route.meta?.featureFlag;
      if (!featureFlag) return false;
      return shouldShowPaywall(featureFlag);
    });

    const isAppReady = computed(() => !!accountId.value);
    const { currentAccount } = useAccount();
    const shouldShowOnboardingModal = computed(() => {
      if (!isAppReady.value) return false;

      const account = currentAccount.value || {};
      if (!account.id) return false; // wait until fully loaded

      const onboarding = account.onboarding || {};
      return onboarding.onboarding_completed !== true;
    });

    const showWelcomeTrialModal = ref(false);

    const onOnboardingCompleted = () => {
      showWelcomeTrialModal.value = true;
    };

    return {
      uiSettings,
      updateUISettings,
      accountId,
      upgradePageRef,
      windowWidth,
      hasActiveCall: computed(() => callsStore.hasActiveCall),
      hasIncomingCall: computed(() => callsStore.hasIncomingCall),
      route,
      isFeatureLocked,
      shouldShowOnboardingModal,
      showWelcomeTrialModal,
      onOnboardingCompleted,
    };
  },
  data() {
    return {
      showAccountModal: false,
      showCreateAccountModal: false,
      showShortcutModal: false,
      isMobileSidebarOpen: false,
    };
  },
  computed: {
    isSmallScreen() {
      return this.windowWidth < wootConstants.SMALL_SCREEN_BREAKPOINT;
    },
    showUpgradePage() {
      return this.upgradePageRef?.shouldShowUpgradePage;
    },
    bypassUpgradePage() {
      return [
        'billing_settings_index',
        'settings_inbox_list',
        'general_settings_index',
        'agent_list',
      ].includes(this.$route.name);
    },
    previouslyUsedDisplayType() {
      const {
        previously_used_conversation_display_type: conversationDisplayType,
      } = this.uiSettings;
      return conversationDisplayType;
    },
  },
  watch: {
    isSmallScreen: {
      handler() {
        const { LAYOUT_TYPES } = wootConstants;
        if (window.innerWidth <= wootConstants.SMALL_SCREEN_BREAKPOINT) {
          this.updateUISettings({
            conversation_display_type: LAYOUT_TYPES.EXPANDED,
          });
        } else {
          this.updateUISettings({
            conversation_display_type: this.previouslyUsedDisplayType,
          });
        }
      },
      immediate: true,
    },
  },
  mounted() {
    if (localStorage.getItem('shopiz_show_welcome_trial') === '1') {
      localStorage.removeItem('shopiz_show_welcome_trial');
      this.showWelcomeTrialModal = true;
    }
  },
  methods: {
    toggleMobileSidebar() {
      this.isMobileSidebarOpen = !this.isMobileSidebarOpen;
    },
    closeMobileSidebar() {
      this.isMobileSidebarOpen = false;
    },
    openCreateAccountModal() {
      this.showAccountModal = false;
      this.showCreateAccountModal = true;
    },
    closeCreateAccountModal() {
      this.showCreateAccountModal = false;
    },
    toggleAccountModal() {
      this.showAccountModal = !this.showAccountModal;
    },
    toggleKeyShortcutModal() {
      this.showShortcutModal = true;
    },
    closeKeyShortcutModal() {
      this.showShortcutModal = false;
    },
  },
};
</script>

<template>
  <div
    class="flex flex-col flex-grow overflow-hidden text-n-slate-12 h-screen w-full"
  >
    <TopHeader
      :is-mobile-sidebar-open="isMobileSidebarOpen"
      @toggle-mobile-sidebar="toggleMobileSidebar"
      @open-key-shortcut-modal="toggleKeyShortcutModal"
      @show-create-account-modal="openCreateAccountModal"
    />
    <div class="flex flex-1 overflow-hidden min-h-0">
      <NextSidebar
        :is-mobile-sidebar-open="isMobileSidebarOpen"
        @close-mobile-sidebar="closeMobileSidebar"
      />

      <main
        class="flex flex-1 h-full w-full min-h-0 px-0 overflow-hidden bg-n-surface-1"
      >
        <UpgradePage
          v-show="showUpgradePage"
          ref="upgradePageRef"
          :bypass-upgrade-page="bypassUpgradePage"
        >
          <MobileSidebarLauncher
            :is-mobile-sidebar-open="isMobileSidebarOpen"
            @toggle="toggleMobileSidebar"
          />
        </UpgradePage>
        <template v-if="!showUpgradePage">
          <div
            class="relative flex-1 overflow-hidden h-full flex flex-col min-w-0"
          >
            <router-view />
            <FeatureLockOverlay
              v-if="isFeatureLocked"
              :feature-flag="route.meta?.featureFlag"
              :feature-name="route.meta?.featureName || route.meta?.featureFlag"
            />
          </div>
          <CommandBar />
          <CopilotLauncher />
          <MobileSidebarLauncher
            :is-mobile-sidebar-open="isMobileSidebarOpen"
            @toggle="toggleMobileSidebar"
          />

          <FloatingCallWidget v-if="hasActiveCall || hasIncomingCall" />
        </template>
        <AddAccountModal
          :show="showCreateAccountModal"
          @close-account-create-modal="closeCreateAccountModal"
        />
        <WootKeyShortcutModal
          v-model:show="showShortcutModal"
          @close="closeKeyShortcutModal"
          @clickaway="closeKeyShortcutModal"
        />
        <OnboardingModal
          v-if="shouldShowOnboardingModal"
          :show="true"
          @completed="onOnboardingCompleted"
        />
        <WelcomeTrialModal
          :show="showWelcomeTrialModal"
          @close="showWelcomeTrialModal = false"
        />
      </main>
    </div>
  </div>
</template>
