import { frontendURL } from '../../../../helper/URLHelper';
import SettingsContent from '../Wrapper.vue';
import Index from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/workflows'),
      meta: {
        permissions: ['administrator'],
      },
      component: SettingsContent,
      props: {
        headerTitle: 'WORKFLOW_SETTINGS.TITLE',
        icon: 'briefcase',
        showNewButton: false,
      },
      children: [
        {
          path: '',
          name: 'workflows_settings_index',
          component: Index,
          meta: {
            permissions: ['administrator'],
          },
        },
      ],
    },
  ],
};
