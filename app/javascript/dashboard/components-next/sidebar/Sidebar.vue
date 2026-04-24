<script setup>
import { h, ref, computed, onMounted } from 'vue';
import { provideSidebarContext, useSidebarResize } from './provider';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { vOnClickOutside } from '@vueuse/components';
import { useRouter, useRoute } from 'vue-router';
import { watch } from 'vue';
import { useWindowSize, useEventListener } from '@vueuse/core';

import SidebarGroup from './SidebarGroup.vue';
import SidebarChangelogCard from './SidebarChangelogCard.vue';
import ChannelLeaf from './ChannelLeaf.vue';
import ChannelIcon from 'next/icon/ChannelIcon.vue';
import { useSidebarKeyboardShortcuts } from './useSidebarKeyboardShortcuts';
import FeatureLockedModal from './FeatureLockedModal.vue';

const props = defineProps({
  isMobileSidebarOpen: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits([
  'closeMobileSidebar',
  'openKeyShortcutModal',
  'closeKeyShortcutModal',
]);

const { accountScopedRoute, isOnChatwootCloud } = useAccount();
const store = useStore();
const { t } = useI18n();
const router = useRouter();

const isACustomBrandedInstance = useMapGetter(
  'globalConfig/isACustomBrandedInstance'
);
const isRTL = useMapGetter('accounts/isRTL');

const { width: windowWidth } = useWindowSize();
const isMobile = computed(() => windowWidth.value < 768);
const toggleShortcutModalFn = show => {
  if (show) {
    emit('openKeyShortcutModal');
  } else {
    emit('closeKeyShortcutModal');
  }
};

useSidebarKeyboardShortcuts(toggleShortcutModalFn);

const expandedItem = ref(null);

const setExpandedItem = name => {
  expandedItem.value = expandedItem.value === name ? null : name;
};

const activeCategory = ref(null);
const route = useRoute();

const isLockedModalOpen = ref(false);
const lockedFeatureName = ref('');
const lockedFeatureFlag = ref('');

const openLockedModal = (featureName, featureFlag = '') => {
  lockedFeatureName.value = featureName;
  lockedFeatureFlag.value = featureFlag;
  isLockedModalOpen.value = true;
};

const closeLockedModal = () => {
  isLockedModalOpen.value = false;
};

const {
  sidebarWidth,
  isCollapsed,
  setSidebarWidth,
  saveWidth,
  snapToCollapsed,
  snapToExpanded,
  COLLAPSED_THRESHOLD,
} = useSidebarResize();

// Resize handle logic
const isResizing = ref(false);
const startX = ref(0);
const startWidth = ref(0);

// On mobile, sidebar is always expanded (flyout mode)
const isEffectivelyCollapsed = computed(
  () => !isMobile.value && isCollapsed.value
);

provideSidebarContext({
  expandedItem,
  setExpandedItem,
  isCollapsed: isEffectivelyCollapsed,
  sidebarWidth,
  isResizing,
  activeCategory,
  openLockedModal,
});

const getFirstNavigableChild = item => {
  if (item.to) return item.to;
  if (item.children && item.children.length > 0) {
    return getFirstNavigableChild(item.children[0]);
  }
  return null;
};
const inboxes = useMapGetter('inboxes/getInboxes');
const labels = useMapGetter('labels/getLabelsOnSidebar');
const teams = useMapGetter('teams/getMyTeams');
const contactCustomViews = useMapGetter('customViews/getContactCustomViews');
const conversationCustomViews = useMapGetter(
  'customViews/getConversationCustomViews'
);

const sortedInboxes = computed(() =>
  inboxes.value.slice().sort((a, b) => a.name.localeCompare(b.name))
);

const newReportRoutes = () => [
  {
    name: 'Reports Agent',
    label: t('SIDEBAR.REPORTS_AGENT'),
    icon: 'i-lucide-user',
    to: accountScopedRoute('agent_reports_index'),
    activeOn: ['agent_reports_show'],
  },
  {
    name: 'Reports Label',
    label: t('SIDEBAR.REPORTS_LABEL'),
    icon: 'i-lucide-tag',
    to: accountScopedRoute('label_reports_index'),
  },
  {
    name: 'Reports Inbox',
    label: t('SIDEBAR.REPORTS_INBOX'),
    icon: 'i-lucide-inbox',
    to: accountScopedRoute('inbox_reports_index'),
    activeOn: ['inbox_reports_show'],
  },
  {
    name: 'Reports Team',
    label: t('SIDEBAR.REPORTS_TEAM'),
    icon: 'i-lucide-users',
    to: accountScopedRoute('team_reports_index'),
    activeOn: ['team_reports_show'],
  },
];

const reportRoutes = computed(() => newReportRoutes());

const menuItems = computed(() => {
  return [
    {
      name: 'Inbox',
      label: t('SIDEBAR.INBOX'),
      icon: 'i-lucide-inbox',
      to: accountScopedRoute('inbox_view'),
      activeOn: ['inbox_view', 'inbox_view_conversation'],
      getterKeys: {
        count: 'notifications/getUnreadCount',
      },
    },
    {
      name: 'Conversation',
      label: t('SIDEBAR.CONVERSATIONS'),
      icon: 'i-lucide-message-circle',
      children: [
        {
          name: 'All',
          label: t('SIDEBAR.ALL_CONVERSATIONS'),
          icon: 'i-lucide-list',
          activeOn: ['inbox_conversation'],
          to: accountScopedRoute('home'),
        },
        {
          name: 'Mentions',
          label: t('SIDEBAR.MENTIONED_CONVERSATIONS'),
          icon: 'i-lucide-at-sign',
          activeOn: ['conversation_through_mentions'],
          to: accountScopedRoute('conversation_mentions'),
        },
        {
          name: 'Participating',
          label: t('SIDEBAR.PARTICIPATING_CONVERSATIONS'),
          icon: 'i-lucide-user-check',
          activeOn: ['conversation_through_participating'],
          to: accountScopedRoute('conversation_participating'),
        },
        {
          name: 'Unattended',
          activeOn: ['conversation_through_unattended'],
          label: t('SIDEBAR.UNATTENDED_CONVERSATIONS'),
          icon: 'i-lucide-clock-3',
          to: accountScopedRoute('conversation_unattended'),
        },
        {
          name: 'Folders',
          label: t('SIDEBAR.CUSTOM_VIEWS_FOLDER'),
          icon: 'i-lucide-folder',
          activeOn: ['conversations_through_folders'],
          children: conversationCustomViews.value.map(view => ({
            name: `${view.name}-${view.id}`,
            label: view.name,
            icon: 'i-lucide-hash',
            to: accountScopedRoute('folder_conversations', { id: view.id }),
          })),
        },
        {
          name: 'Teams',
          label: t('SIDEBAR.TEAMS'),
          icon: 'i-lucide-users',
          activeOn: ['conversations_through_team'],
          children: teams.value.map(team => ({
            name: `${team.name}-${team.id}`,
            label: team.name,
            icon: 'i-lucide-users',
            to: accountScopedRoute('team_conversations', { teamId: team.id }),
          })),
        },
        {
          name: 'Channels',
          label: t('SIDEBAR.CHANNELS'),
          icon: 'i-lucide-mailbox',
          activeOn: ['conversation_through_inbox'],
          children: sortedInboxes.value.map(inbox => ({
            name: `${inbox.name}-${inbox.id}`,
            label: inbox.name,
            icon: h(ChannelIcon, { inbox, class: 'size-[16px]' }),
            to: accountScopedRoute('inbox_dashboard', { inbox_id: inbox.id }),
            component: leafProps =>
              h(ChannelLeaf, {
                label: leafProps.label,
                active: leafProps.active,
                inbox,
              }),
          })),
        },
        {
          name: 'Labels',
          label: t('SIDEBAR.LABELS'),
          icon: 'i-lucide-tag',
          activeOn: ['conversations_through_label'],
          children: labels.value.map(label => ({
            name: `${label.title}-${label.id}`,
            label: label.title,
            icon: h('span', {
              class: `size-[8px] rounded-sm`,
              style: { backgroundColor: label.color },
            }),
            to: accountScopedRoute('label_conversations', {
              label: label.title,
            }),
          })),
        },
      ],
    },
    {
      name: 'Captain',
      icon: 'i-woot-captain',
      label: t('SIDEBAR.CAPTAIN'),
      activeOn: ['captain_assistants_create_index'],
      children: [
        {
          name: 'FAQs',
          label: t('SIDEBAR.CAPTAIN_RESPONSES'),
          icon: 'i-lucide-help-circle',
          activeOn: [
            'captain_assistants_responses_index',
            'captain_assistants_responses_pending',
          ],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_responses_index',
          }),
        },
        {
          name: 'Documents',
          label: t('SIDEBAR.CAPTAIN_DOCUMENTS'),
          icon: 'i-lucide-file-text',
          activeOn: ['captain_assistants_documents_index'],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_documents_index',
          }),
        },
        {
          name: 'Scenarios',
          label: t('SIDEBAR.CAPTAIN_SCENARIOS'),
          icon: 'i-lucide-route',
          activeOn: ['captain_assistants_scenarios_index'],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_scenarios_index',
          }),
        },
        {
          name: 'Playground',
          label: t('SIDEBAR.CAPTAIN_PLAYGROUND'),
          icon: 'i-lucide-terminal',
          activeOn: ['captain_assistants_playground_index'],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_playground_index',
          }),
        },
        {
          name: 'Inboxes',
          label: t('SIDEBAR.CAPTAIN_INBOXES'),
          icon: 'i-lucide-inbox',
          activeOn: ['captain_assistants_inboxes_index'],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_inboxes_index',
          }),
        },
        {
          name: 'Tools',
          label: t('SIDEBAR.CAPTAIN_TOOLS'),
          icon: 'i-lucide-wrench',
          activeOn: ['captain_tools_index'],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_tools_index',
          }),
        },
        {
          name: 'Settings',
          label: t('SIDEBAR.CAPTAIN_SETTINGS'),
          icon: 'i-lucide-settings-2',
          activeOn: [
            'captain_assistants_settings_index',
            'captain_assistants_guidelines_index',
            'captain_assistants_guardrails_index',
          ],
          to: accountScopedRoute('captain_assistants_index', {
            navigationPath: 'captain_assistants_settings_index',
          }),
        },
      ],
    },
    {
      name: 'Contacts',
      label: t('SIDEBAR.CONTACTS'),
      icon: 'i-lucide-contact',
      children: [
        {
          name: 'All Contacts',
          label: t('SIDEBAR.ALL_CONTACTS'),
          icon: 'i-lucide-users',
          to: accountScopedRoute(
            'contacts_dashboard_index',
            {},
            { page: 1, search: undefined }
          ),
          activeOn: ['contacts_dashboard_index', 'contacts_edit'],
        },
        {
          name: 'Active',
          label: t('SIDEBAR.ACTIVE'),
          icon: 'i-lucide-user-round-check',
          to: accountScopedRoute('contacts_dashboard_active'),
          activeOn: ['contacts_dashboard_active'],
        },
        {
          name: 'Segments',
          icon: 'i-lucide-group',
          label: t('SIDEBAR.CUSTOM_VIEWS_SEGMENTS'),
          children: contactCustomViews.value.map(view => ({
            name: `${view.name}-${view.id}`,
            label: view.name,
            to: accountScopedRoute(
              'contacts_dashboard_segments_index',
              { segmentId: view.id },
              { page: 1 }
            ),
            activeOn: [
              'contacts_dashboard_segments_index',
              'contacts_edit_segment',
            ],
          })),
        },
        {
          name: 'Tagged With',
          icon: 'i-lucide-tag',
          label: t('SIDEBAR.TAGGED_WITH'),
          children: labels.value.map(label => ({
            name: `${label.title}-${label.id}`,
            label: label.title,
            icon: h('span', {
              class: `size-[8px] rounded-sm`,
              style: { backgroundColor: label.color },
            }),
            to: accountScopedRoute(
              'contacts_dashboard_labels_index',
              { label: label.title },
              { page: 1, search: undefined }
            ),
            activeOn: [
              'contacts_dashboard_labels_index',
              'contacts_edit_label',
            ],
          })),
        },
      ],
    },
    {
      name: 'Reports',
      label: t('SIDEBAR.REPORTS'),
      icon: 'i-lucide-chart-spline',
      children: [
        {
          name: 'Report Overview',
          label: t('SIDEBAR.REPORTS_OVERVIEW'),
          icon: 'i-lucide-layout-dashboard',
          to: accountScopedRoute('account_overview_reports'),
        },
        {
          name: 'Report Conversation',
          label: t('SIDEBAR.REPORTS_CONVERSATION'),
          icon: 'i-lucide-message-square',
          to: accountScopedRoute('conversation_reports'),
        },
        ...reportRoutes.value,
        {
          name: 'Reports CSAT',
          label: t('SIDEBAR.CSAT'),
          icon: 'i-lucide-smile',
          to: accountScopedRoute('csat_reports'),
        },
        {
          name: 'Reports SLA',
          label: t('SIDEBAR.REPORTS_SLA'),
          icon: 'i-lucide-timer',
          to: accountScopedRoute('sla_reports'),
        },
        {
          name: 'Reports Bot',
          label: t('SIDEBAR.REPORTS_BOT'),
          icon: 'i-lucide-bot',
          to: accountScopedRoute('bot_reports'),
        },
      ],
    },
    {
      name: 'Campaigns',
      label: t('SIDEBAR.CAMPAIGNS'),
      icon: 'i-lucide-megaphone',
      children: [
        {
          name: 'Live chat',
          label: t('SIDEBAR.LIVE_CHAT'),
          icon: 'i-woot-website',
          to: accountScopedRoute('campaigns_livechat_index'),
        },
        {
          name: 'Zalo Personal',
          label: t('SIDEBAR.ZALO_PERSONAL'),
          icon: 'i-woot-zalo-personal',
          to: accountScopedRoute('campaigns_zalo_personal_index'),
        },
        {
          name: 'Zalo OA',
          label: 'Zalo OA',
          icon: 'i-woot-zalo-oa',
          to: accountScopedRoute('campaigns_zalo_oa_index'),
        },
        {
          name: 'WhatsApp',
          label: t('SIDEBAR.WHATSAPP'),
          icon: 'i-woot-whatsapp',
          to: accountScopedRoute('campaigns_whatsapp_index'),
        },
        {
          name: 'Facebook',
          label: 'Facebook',
          icon: 'i-ri-messenger-fill',
          to: accountScopedRoute('campaigns_facebook_index'),
        },
        {
          name: 'Telegram',
          label: 'Telegram',
          icon: 'i-woot-telegram',
          to: accountScopedRoute('campaigns_telegram_index'),
        },
        {
          name: 'LINE',
          label: 'LINE',
          icon: 'i-woot-line',
          to: accountScopedRoute('campaigns_line_index'),
        },
      ],
    },
    {
      name: 'Help Center',
      label: t('SIDEBAR.HELP_CENTER.TITLE'),
      icon: 'i-lucide-book',
      to: accountScopedRoute('portals_index', {
        navigationPath: 'portals_articles_index',
      }),
      activeOn: [
        'portals_index',
        'portals_articles_index',
        'portals_articles_new',
        'portals_articles_edit',
        'portals_landing_pages_index',
        'portals_categories_index',
        'portals_categories_articles_index',
        'portals_categories_articles_edit',
        'portals_locales_index',
        'portals_settings_index',
        'portals_new',
      ],
      children: [
        {
          name: 'Articles',
          label: t('SIDEBAR.HELP_CENTER.ARTICLES'),
          icon: 'i-lucide-file-text',
          activeOn: [
            'portals_articles_index',
            'portals_articles_new',
            'portals_articles_edit',
          ],
          to: accountScopedRoute('portals_index', {
            navigationPath: 'portals_articles_index',
          }),
        },
        {
          name: 'Categories',
          label: t('SIDEBAR.HELP_CENTER.CATEGORIES'),
          icon: 'i-lucide-folder',
          activeOn: [
            'portals_categories_index',
            'portals_categories_articles_index',
            'portals_categories_articles_edit',
          ],
          to: accountScopedRoute('portals_index', {
            navigationPath: 'portals_categories_index',
          }),
        },
        {
          name: 'Locales',
          label: t('SIDEBAR.HELP_CENTER.LOCALES'),
          icon: 'i-lucide-languages',
          activeOn: ['portals_locales_index'],
          to: accountScopedRoute('portals_index', {
            navigationPath: 'portals_locales_index',
          }),
        },
        {
          name: 'Settings',
          label: t('SIDEBAR.HELP_CENTER.SETTINGS'),
          icon: 'i-lucide-settings-2',
          activeOn: ['portals_settings_index'],
          to: accountScopedRoute('portals_index', {
            navigationPath: 'portals_settings_index',
          }),
        },
      ],
    },
    {
      name: 'Settings',
      label: t('SIDEBAR.SETTINGS'),
      icon: 'i-lucide-bolt',
      children: [
        {
          name: 'Settings Account Settings',
          label: t('SIDEBAR.ACCOUNT_SETTINGS'),
          icon: 'i-lucide-briefcase',
          to: accountScopedRoute('general_settings_index'),
        },
        {
          name: 'Settings Agents',
          label: t('SIDEBAR.AGENTS'),
          icon: 'i-lucide-square-user',
          to: accountScopedRoute('agent_list'),
        },
        {
          name: 'Settings Teams',
          label: t('SIDEBAR.TEAMS'),
          icon: 'i-lucide-users',
          activeOn: [
            'settings_teams_list',
            'settings_teams_new',
            'settings_teams_finish',
            'settings_teams_add_agents',
            'settings_teams_show',
            'settings_teams_edit',
            'settings_teams_edit_members',
            'settings_teams_edit_finish',
          ],
          to: accountScopedRoute('settings_teams_list'),
        },
        {
          name: 'Settings Agent Assignment',
          label: t('SIDEBAR.AGENT_ASSIGNMENT'),
          icon: 'i-lucide-user-cog',
          activeOn: [
            'assignment_policy_index',
            'agent_assignment_policy_index',
            'agent_assignment_policy_create',
            'agent_assignment_policy_edit',
            'agent_capacity_policy_index',
            'agent_capacity_policy_create',
            'agent_capacity_policy_edit',
          ],
          to: accountScopedRoute('assignment_policy_index'),
        },
        {
          name: 'Settings Inboxes',
          label: t('SIDEBAR.INBOXES'),
          icon: 'i-lucide-inbox',
          activeOn: [
            'settings_inbox_list',
            'settings_inbox_show',
            'settings_inbox_new',
            'settings_inbox_finish',
            'settings_inboxes_page_channel',
            'settings_inboxes_add_agents',
          ],
          to: accountScopedRoute('settings_inbox_list'),
        },
        {
          name: 'Settings Labels',
          label: t('SIDEBAR.LABELS'),
          icon: 'i-lucide-tags',
          to: accountScopedRoute('labels_list'),
        },
        {
          name: 'Settings Custom Attributes',
          label: t('SIDEBAR.CUSTOM_ATTRIBUTES'),
          icon: 'i-lucide-code',
          to: accountScopedRoute('attributes_list'),
        },
        {
          name: 'Settings Automation',
          label: t('SIDEBAR.AUTOMATION'),
          icon: 'i-lucide-repeat',
          to: accountScopedRoute('automation_list'),
        },
        {
          name: 'Settings Agent Bots',
          label: t('SIDEBAR.AGENT_BOTS'),
          icon: 'i-lucide-bot',
          to: accountScopedRoute('agent_bots'),
        },
        {
          name: 'Settings Macros',
          label: t('SIDEBAR.MACROS'),
          icon: 'i-lucide-zap',
          to: accountScopedRoute('macros_wrapper'),
        },
        {
          name: 'Settings Canned Responses',
          label: t('SIDEBAR.CANNED_RESPONSES'),
          icon: 'i-lucide-message-square-quote',
          to: accountScopedRoute('canned_list'),
        },
        {
          name: 'Settings Templates',
          label: t('SIDEBAR.TEMPLATES'),
          icon: 'i-lucide-file-text',
          to: accountScopedRoute('templates_list'),
        },
        {
          name: 'Settings Integrations',
          label: t('SIDEBAR.INTEGRATIONS'),
          icon: 'i-lucide-blocks',
          activeOn: [
            'settings_applications',
            'settings_applications_integration',
            'settings_integrations_slack',
            'settings_integrations_linear',
            'settings_integrations_notion',
            'settings_integrations_shopify',
            'settings_integrations_kiotviet',
            'settings_integrations_haravan',
            'settings_integrations_woocommerce',
            'settings_integrations_sapo',
            'settings_integrations_nhanhvn',
            'settings_integrations_webhook',
            'settings_integrations_dashboard_apps',
          ],
          to: accountScopedRoute('settings_applications'),
        },
        {
          name: 'Settings Audit Logs',
          label: t('SIDEBAR.AUDIT_LOGS'),
          icon: 'i-lucide-clipboard-list',
          to: accountScopedRoute('auditlogs_list'),
        },
        {
          name: 'Settings Custom Roles',
          label: t('SIDEBAR.CUSTOM_ROLES'),
          icon: 'i-lucide-shield-plus',
          to: accountScopedRoute('custom_roles_list'),
        },
        {
          name: 'Settings Sla',
          label: t('SIDEBAR.SLA'),
          icon: 'i-lucide-clock-alert',
          to: accountScopedRoute('sla_list'),
        },
        {
          name: 'Conversation Workflow',
          label: t('SIDEBAR.CONVERSATION_WORKFLOW'),
          icon: 'i-lucide-workflow',
          to: accountScopedRoute('conversation_workflow_index'),
        },

        {
          name: 'Settings Billing',
          label: t('SIDEBAR.BILLING'),
          icon: 'i-lucide-credit-card',
          to: accountScopedRoute('billing_settings_index'),
        },
      ],
    },
  ];
});

const syncActiveCategory = () => {
  const currentRouteName = route.name;
  const activeItem = menuItems.value.find(item => {
    if (item.activeOn?.includes(currentRouteName)) return true;
    if (item.to?.name === currentRouteName) return true;
    if (item.children) {
      return item.children.some(child => {
        if (child.activeOn?.includes(currentRouteName)) return true;
        if (child.to?.name === currentRouteName) return true;
        if (child.children) {
          return child.children.some(grandChild => {
            if (grandChild.activeOn?.includes(currentRouteName)) return true;
            if (grandChild.to?.name === currentRouteName) return true;
            return false;
          });
        }
        return false;
      });
    }
    return false;
  });

  if (activeItem) {
    activeCategory.value = activeItem.name;
  }
};

watch(
  () => route.path,
  () => {
    syncActiveCategory();
  }
);

// Get clientX from mouse or touch event
const getClientX = event =>
  event.touches ? event.touches[0].clientX : event.clientX;

const onResizeStart = event => {
  isResizing.value = true;
  startX.value = getClientX(event);
  startWidth.value = sidebarWidth.value;
  Object.assign(document.body.style, {
    cursor: 'col-resize',
    userSelect: 'none',
  });
  // Prevent default to avoid scrolling on touch
  event.preventDefault();
};

const onResizeMove = event => {
  if (!isResizing.value) return;

  const delta = isRTL.value
    ? startX.value - getClientX(event)
    : getClientX(event) - startX.value;
  setSidebarWidth(startWidth.value + delta);
};

const onResizeEnd = () => {
  if (!isResizing.value) return;

  isResizing.value = false;
  Object.assign(document.body.style, { cursor: '', userSelect: '' });

  // Snap to collapsed state if below threshold
  if (sidebarWidth.value < COLLAPSED_THRESHOLD) {
    snapToCollapsed();
  } else {
    saveWidth();
  }
};

const onResizeHandleDoubleClick = () => {
  if (isCollapsed.value) snapToExpanded();
  else snapToCollapsed();
};

// Support both mouse and touch events
useEventListener(document, 'mousemove', onResizeMove);
useEventListener(document, 'mouseup', onResizeEnd);
useEventListener(document, 'touchmove', onResizeMove, { passive: false });
useEventListener(document, 'touchend', onResizeEnd);

onMounted(() => {
  syncActiveCategory();
  store.dispatch('labels/get');
  store.dispatch('inboxes/get');
  store.dispatch('notifications/unReadCount');
  store.dispatch('teams/get');
  store.dispatch('attributes/get');
  store.dispatch('customViews/get', 'conversation');
  store.dispatch('customViews/get', 'contact');
});

const closeMobileSidebar = () => {
  if (!props.isMobileSidebarOpen) return;
  emit('closeMobileSidebar');
};

// Calculate active menu items
const activeMainMenuName = computed(() => {
  return activeCategory.value || menuItems.value[0]?.name;
});

const activeMainMenuItem = computed(() => {
  return menuItems.value.find(item => item.name === activeMainMenuName.value);
});

const handleMainMenuClick = item => {
  activeCategory.value = item.name;

  const navigableChild = getFirstNavigableChild(item);
  if (navigableChild) {
    router.push(navigableChild);
  }
};
</script>

<template>
  <aside
    v-on-click-outside="[
      closeMobileSidebar,
      { ignore: ['#mobile-sidebar-launcher'] },
    ]"
    class="flex h-full flex-shrink-0 fixed top-0 ltr:left-0 rtl:right-0 z-40 transition-transform duration-200 ease-in-out md:static md:ltr:translate-x-0 md:rtl:translate-x-0"
    :class="[
      {
        'shadow-lg md:shadow-none': isMobileSidebarOpen,
        'ltr:-translate-x-full rtl:translate-x-full': !isMobileSidebarOpen,
        'transition-transform duration-200 ease-out md:transition-[width]':
          !isResizing,
      },
    ]"
    :style="isMobile ? undefined : { width: `${sidebarWidth}px` }"
  >
    <!-- Column 1: Main Menu Icons -->
    <nav
      class="flex flex-col items-center py-4 w-16 bg-n-solid-2 border-r border-n-weak flex-shrink-0 relative h-full overflow-y-auto no-scrollbar"
    >
      <ul class="flex flex-col gap-2 w-full px-2 list-none m-0" role="menu">
        <li
          v-for="item in menuItems"
          :key="item.name"
          class="w-full flex justify-center relative"
        >
          <button
            v-tooltip.right="item.label"
            class="flex items-center justify-center rounded-xl transition-all w-10 h-10 relative flex-shrink-0 outline-none"
            :class="[
              activeMainMenuName === item.name
                ? 'bg-[#E06720] text-white shadow-sm dark:bg-[#E06720]'
                : 'bg-transparent text-n-slate-12 hover:bg-[#E06720]/10 dark:text-n-slate-11 hover:text-n-slate-12 dark:hover:bg-[#E06720]/20 dark:hover:text-white',
            ]"
            @click="handleMainMenuClick(item)"
          >
            <span :class="item.icon" class="size-4" />
          </button>
        </li>
      </ul>
      <div class="mt-auto flex flex-col gap-2 w-full px-2 items-center pb-2">
        <SidebarChangelogCard
          v-if="isOnChatwootCloud && !isACustomBrandedInstance"
        />
      </div>
    </nav>

    <!-- Column 2: Secondary Menu Items -->
    <div
      v-show="!isEffectivelyCollapsed"
      class="flex-1 bg-n-solid-1 md:bg-[#F9FAFB] dark:md:bg-n-solid-1 border-r border-n-weak flex flex-col flex-shrink-0 h-full overflow-y-auto no-scrollbar"
    >
      <div
        class="px-4 pt-5 pb-3 sticky top-0 md:bg-[#F9FAFB] dark:md:bg-n-solid-1 z-10 flex items-center justify-between"
      >
        <h2 class="text-base font-semibold text-n-slate-12">
          {{ activeMainMenuItem?.label || '' }}
        </h2>
      </div>
      <ul class="flex flex-col gap-1.5 px-3 pb-5 m-0 list-none">
        <template v-if="activeMainMenuItem && activeMainMenuItem.children">
          <SidebarGroup
            v-for="child in activeMainMenuItem.children"
            :key="child.name"
            v-bind="child"
          />
        </template>
        <!-- Render single item if no children -->
        <SidebarGroup
          v-else-if="activeMainMenuItem && !activeMainMenuItem.children"
          v-bind="activeMainMenuItem"
        />
      </ul>
    </div>
    <!-- Resize Handle -->
    <div
      v-show="!isMobile"
      class="absolute top-0 ltr:right-0 rtl:left-0 w-1 h-full cursor-col-resize hover:bg-n-orange/10 transition-colors z-[100] group hidden md:block"
      @mousedown="onResizeStart"
      @touchstart="onResizeStart"
      @dblclick="onResizeHandleDoubleClick"
    >
      <div
        class="absolute ltr:right-0 rtl:left-0 h-full w-[1px] bg-n-weak group-hover:bg-n-orange transition-colors"
      />
    </div>
    <!-- Feature Locked Modal -->
    <FeatureLockedModal
      :show="isLockedModalOpen"
      :feature-name="lockedFeatureName"
      :feature-flag="lockedFeatureFlag"
      @close="closeLockedModal"
    />
  </aside>
</template>
