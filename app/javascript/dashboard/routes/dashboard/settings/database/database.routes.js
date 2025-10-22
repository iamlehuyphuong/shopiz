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
      path: frontendURL('accounts/:accountId/settings/database'),
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'database_list',
          component: Index,
          meta: {
            featureFlag: FEATURE_FLAGS.DATABASE,
            permissions: [...ROLES, ...CONVERSATION_PERMISSIONS],
          },
        },
      ],
    },
  ],
};
