<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import ContactPanel from 'dashboard/routes/dashboard/conversation/ContactPanel.vue';
import Copilot from 'dashboard/components-next/copilot/Copilot.vue';
import OrderPanel from 'dashboard/components/widgets/conversation/orders/OrderPanel.vue';
import ProductPanel from 'dashboard/components/widgets/conversation/products/ProductPanel.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { useWindowSize } from '@vueuse/core';
import { vOnClickOutside } from '@vueuse/components';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useConfig } from 'dashboard/composables/useConfig';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import wootConstants from 'dashboard/constants/globals';
import { emitter } from 'shared/helpers/mitt';
import { BUS_EVENTS } from 'shared/constants/busEvents';

const props = defineProps({
  currentChat: {
    required: true,
    type: Object,
  },
});

const store = useStore();
const { uiSettings, updateUISettings } = useUISettings();
const { isEnterprise } = useConfig();
const { width: windowWidth } = useWindowSize();

// --- Tab state ---
const isContactTabActive = computed(
  () => uiSettings.value.is_contact_sidebar_open
);
const isCopilotTabActive = computed(
  () => uiSettings.value.is_copilot_panel_open
);
const isOrderTabActive = computed(() => uiSettings.value.is_order_sidebar_open);
const isProductTabActive = computed(
  () => uiSettings.value.is_product_sidebar_open
);

const isSidebarVisible = computed(
  () =>
    isContactTabActive.value ||
    isCopilotTabActive.value ||
    isOrderTabActive.value ||
    isProductTabActive.value
);

const isSmallScreen = computed(
  () => windowWidth.value < wootConstants.SMALL_SCREEN_BREAKPOINT
);

// --- Captain / Copilot feature check ---
const currentAccountId = useMapGetter('getCurrentAccountId');
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);

const showCopilotTab = computed(() => {
  if (!isEnterprise) return false;
  return isFeatureEnabledonAccount.value(
    currentAccountId.value,
    FEATURE_FLAGS.CAPTAIN
  );
});

// --- Copilot data (migrated from CopilotContainer) ---
const currentUser = useMapGetter('getCurrentUser');
const assistants = useMapGetter('captainAssistants/getRecords');
const uiFlags = useMapGetter('captainAssistants/getUIFlags');
const inboxAssistant = useMapGetter('getCopilotAssistant');

const selectedCopilotThreadId = ref(null);
const messages = computed(() =>
  store.getters['copilotMessages/getMessagesByThreadId'](
    selectedCopilotThreadId.value
  )
);

const selectedAssistantId = ref(null);

const activeAssistant = computed(() => {
  const preferredId = uiSettings.value.preferred_captain_assistant_id;

  // If the user has selected a specific assistant, it takes first preference for Copilot.
  if (preferredId) {
    const preferredAssistant = assistants.value.find(a => a.id === preferredId);
    // Return the preferred assistant if found, otherwise continue to next cases
    if (preferredAssistant) return preferredAssistant;
  }

  // If the above is not available, the assistant connected to the inbox takes preference.
  if (inboxAssistant.value) {
    const inboxMatchedAssistant = assistants.value.find(
      a => a.id === inboxAssistant.value.id
    );
    if (inboxMatchedAssistant) return inboxMatchedAssistant;
  }
  // If neither of the above is available, the first assistant in the account takes preference.
  return assistants.value[0];
});

const shouldShowCopilotContent = computed(() => {
  if (!isEnterprise) return false;
  const isCaptainEnabled = isFeatureEnabledonAccount.value(
    currentAccountId.value,
    FEATURE_FLAGS.CAPTAIN
  );
  return isCaptainEnabled && !uiFlags.value.fetchingList;
});

const setAssistant = async assistant => {
  selectedAssistantId.value = assistant.id;
  await updateUISettings({
    preferred_captain_assistant_id: assistant.id,
  });
};

const handleCopilotReset = () => {
  selectedCopilotThreadId.value = null;
};

const sendCopilotMessage = async message => {
  try {
    if (selectedCopilotThreadId.value) {
      await store.dispatch('copilotMessages/create', {
        assistant_id: activeAssistant.value.id,
        conversation_id: props.currentChat?.id,
        threadId: selectedCopilotThreadId.value,
        message,
      });
    } else {
      const response = await store.dispatch('copilotThreads/create', {
        assistant_id: activeAssistant.value.id,
        conversation_id: props.currentChat?.id,
        message,
      });
      selectedCopilotThreadId.value = response.id;
    }
  } catch (error) {
    useAlert(error.message);
  }
};

// --- Tab switching ---
const switchToContactTab = () => {
  updateUISettings({
    is_contact_sidebar_open: true,
    is_copilot_panel_open: false,
    is_order_sidebar_open: false,
    is_product_sidebar_open: false,
  });
};

const switchToCopilotTab = () => {
  updateUISettings({
    is_contact_sidebar_open: false,
    is_copilot_panel_open: true,
    is_order_sidebar_open: false,
    is_product_sidebar_open: false,
  });
};

const switchToOrderTab = () => {
  updateUISettings({
    is_contact_sidebar_open: false,
    is_copilot_panel_open: false,
    is_order_sidebar_open: true,
    is_product_sidebar_open: false,
  });
};

const switchToProductTab = () => {
  updateUISettings({
    is_contact_sidebar_open: false,
    is_copilot_panel_open: false,
    is_order_sidebar_open: false,
    is_product_sidebar_open: true,
  });
};

const closeSidebar = () => {
  updateUISettings({
    is_contact_sidebar_open: false,
    is_copilot_panel_open: false,
    is_order_sidebar_open: false,
    is_product_sidebar_open: false,
  });
};

const handleClickOutside = () => {
  if (isSmallScreen.value && isSidebarVisible.value) {
    closeSidebar();
  }
};

const conversationInboxType = computed(
  () => props.currentChat.meta?.channel || ''
);

const pendingProduct = ref(null);

const handleAddProductToOrder = product => {
  pendingProduct.value = { ...product, _timestamp: Date.now() };
  switchToOrderTab();
};

onMounted(() => {
  if (isEnterprise) {
    store.dispatch('captainAssistants/get');
  }
  emitter.on(BUS_EVENTS.ADD_PRODUCT_TO_ORDER, handleAddProductToOrder);
});

onUnmounted(() => {
  emitter.off(BUS_EVENTS.ADD_PRODUCT_TO_ORDER, handleAddProductToOrder);
});
</script>

<template>
  <div
    v-if="isSidebarVisible"
    v-on-click-outside="() => handleClickOutside()"
    class="bg-n-surface-2 overflow-hidden flex flex-col fixed top-14 h-[calc(100vh-3.5rem)] z-40 w-full max-w-sm transition-transform duration-300 ease-in-out ltr:right-0 rtl:left-0 md:static md:h-full md:w-[320px] md:min-w-[320px] ltr:border-l rtl:border-r border-n-weak 2xl:min-w-[360px] 2xl:w-[360px] shadow-lg md:shadow-none"
  >
    <!-- Tab Header -->
    <div class="flex items-center border-b border-n-weak h-12 px-1 shrink-0 overflow-x-auto no-scrollbar">
      <div class="flex items-center gap-0.5 min-w-max">
        <button
          class="px-3 py-1.5 text-sm rounded-md transition-colors duration-150 whitespace-nowrap"
          :class="
            isContactTabActive
              ? 'bg-n-alpha-2 text-n-slate-12 font-medium'
              : 'text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-1'
          "
          @click="switchToContactTab"
        >
          {{ $t('CONVERSATION.SIDEBAR.CONTACT') }}
        </button>
        <button
          v-if="showCopilotTab"
          class="px-3 py-1.5 text-sm rounded-md transition-colors duration-150 whitespace-nowrap"
          :class="
            isCopilotTabActive
              ? 'bg-n-alpha-2 text-n-slate-12 font-medium'
              : 'text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-1'
          "
          @click="switchToCopilotTab"
        >
          {{ $t('CONVERSATION.SIDEBAR.COPILOT') }}
        </button>
        <button
          class="px-3 py-1.5 text-sm rounded-md transition-colors duration-150 whitespace-nowrap"
          :class="
            isOrderTabActive
              ? 'bg-n-alpha-2 text-n-slate-12 font-medium'
              : 'text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-1'
          "
          @click="switchToOrderTab"
        >
          {{ $t('CONVERSATION.SIDEBAR.ORDERS') }}
        </button>
        <button
          class="px-3 py-1.5 text-sm rounded-md transition-colors duration-150 whitespace-nowrap"
          :class="
            isProductTabActive
              ? 'bg-n-alpha-2 text-n-slate-12 font-medium'
              : 'text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-1'
          "
          @click="switchToProductTab"
        >
          {{ $t('CONVERSATION.PRODUCT_PANEL.TITLE') }}
        </button>
      </div>
      <Button
        v-tooltip="$t('GENERAL.CLOSE')"
        icon="i-lucide-x"
        ghost
        sm
        @click="closeSidebar"
      />
    </div>

    <!-- Contact Panel -->
    <div v-if="isContactTabActive" class="flex flex-1 overflow-auto">
      <ContactPanel
        :conversation-id="currentChat.id"
        :inbox-id="currentChat.inbox_id"
      />
    </div>

    <!-- Copilot Panel -->
    <div
      v-else-if="isCopilotTabActive && shouldShowCopilotContent"
      class="flex flex-1 overflow-hidden"
    >
      <Copilot
        :messages="messages"
        :support-agent="currentUser"
        :conversation-inbox-type="conversationInboxType"
        :assistants="assistants"
        :active-assistant="activeAssistant"
        @set-assistant="setAssistant"
        @send-message="sendCopilotMessage"
        @reset="handleCopilotReset"
      />
    </div>

    <!-- Order Panel -->
    <div v-else-if="isOrderTabActive" class="flex flex-1 overflow-hidden">
      <OrderPanel
        :conversation-id="currentChat.id"
        :pending-product="pendingProduct"
        @product-consumed="pendingProduct = null"
      />
    </div>

    <!-- Product Panel -->
    <div v-else-if="isProductTabActive" class="flex flex-1 overflow-hidden">
      <ProductPanel :conversation-id="currentChat.id" />
    </div>
  </div>
  <template v-else />
</template>
