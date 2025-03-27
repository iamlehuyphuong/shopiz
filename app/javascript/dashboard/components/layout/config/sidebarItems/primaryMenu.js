import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';
import ContactIcon from 'components/layout/sidebarComponents/icons/ContactIcon.vue';
import ConversationsIcon from 'components/layout/sidebarComponents/icons/ConversationsIcon.vue';
import ReportIcon from 'components/layout/sidebarComponents/icons/ReportIcon.vue';
import HelpIcon from 'components/layout/sidebarComponents/icons/HelpIcon.vue';
import CompaignIcon from 'components/layout/sidebarComponents/icons/CompaignIcon.vue';
import SettingIcon from 'components/layout/sidebarComponents/icons/SettingIcon.vue';
import CustomizeChatbotIcon from 'components/layout/sidebarComponents/icons/CustomizeChatbotIcon.vue';

const primaryMenuItems = accountId => [
  {
    icon: 'mail-inbox',
    key: 'inboxView',
    label: 'INBOX_VIEW',
    featureFlag: FEATURE_FLAGS.INBOX_VIEW,
    toState: frontendURL(`accounts/${accountId}/inbox-view`),
    toStateName: 'inbox_view',
  },
  {
    icon: ConversationsIcon,
    key: 'conversations',
    label: 'Conversations',
    toState: frontendURL(`accounts/${accountId}/dashboard`),
    toStateName: 'home',
  },
  {
    icon: 'captain',
    key: 'Captain',
    label: 'CAPTAIN',
    featureFlag: FEATURE_FLAGS.CAPTAIN,
    toState: frontendURL(`accounts/${accountId}/captain/documents`),
    toStateName: 'captain',
  },
  {
    icon: ContactIcon,
    key: 'contacts',
    label: 'Contacts',
    featureFlag: FEATURE_FLAGS.CRM,
    toState: frontendURL(`accounts/${accountId}/contacts`),
    toStateName: 'contacts_dashboard_index',
  },
  {
    icon: ReportIcon,
    key: 'reports',
    label: 'Reports',
    featureFlag: FEATURE_FLAGS.REPORTS,
    toState: frontendURL(`accounts/${accountId}/reports`),
    toStateName: 'account_overview_reports',
  },
  {
    icon: CustomizeChatbotIcon,
    key: 'customizeChatbot',
    label: 'Customize Chatbot',
    toState: frontendURL(`accounts/${accountId}/customize-chatbot`),
    toStateName: 'account_overview_reports',
  },
  {
    icon: CompaignIcon,
    key: 'campaigns',
    label: 'Campaigns',
    featureFlag: FEATURE_FLAGS.CAMPAIGNS,
    toState: frontendURL(`accounts/${accountId}/campaigns`),
    toStateName: 'campaigns_ongoing_index',
  },
  {
    icon: HelpIcon,
    key: 'helpcenter',
    label: 'Helper center',
    featureFlag: FEATURE_FLAGS.HELP_CENTER,
    alwaysVisibleOnChatwootInstances: true,
    toState: frontendURL(`accounts/${accountId}/portals/portal_articles_index`),
    toStateName: 'portals_index',
  },
  {
    icon: SettingIcon,
    key: 'settings',
    label: 'Settings',
    toState: frontendURL(`accounts/${accountId}/settings`),
    toStateName: 'settings_home',
  },
];

export default primaryMenuItems;
