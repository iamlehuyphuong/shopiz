import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from 'dashboard/helper/URLHelper';

import {
  ROLES,
  CONVERSATION_PERMISSIONS,
} from 'dashboard/constants/permissions.js';
import SettingsContent from '../Wrapper.vue';
import SettingsWrapper from '../SettingsWrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/flows'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'workflow_list',
          component: Index,
          meta: {
            featureFlag: FEATURE_FLAGS.WORKFLOWS,
            permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
          },
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/settings/flows'),
      meta: {
        featureFlag: FEATURE_FLAGS.WORKFLOWS,
        permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
      },
      component: SettingsContent,
      props: {
        headerTitle: 'WORKFLOW_SETTINGS.HEADER',
        icon: 'briefcase',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'workflows_settings_index',
          component: Index,
          meta: {
            featureFlag: FEATURE_FLAGS.WORKFLOWS,
            permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
          },
        },
        {
          path: ':flowId',
          name: 'workflows_settings_index',
          component: Index,
          meta: {
            featureFlag: FEATURE_FLAGS.WORKFLOWS,
            permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
          },
        },
      ],
    },
  ],
};
