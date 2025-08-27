import { FEATURE_FLAGS } from '../../../../featureFlags';
import Bot from './Index.vue';
import Flow from '../workflows/Index.vue';
import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/agent-bots'),
      meta: {
        permissions: ['administrator'],
      },
      component: SettingsWrapper,
      children: [
        {
          path: '',
          name: 'agent_bots',
          component: Bot,
          meta: {
            featureFlag: FEATURE_FLAGS.AGENT_BOTS,
            permissions: ['administrator'],
          },
        },
        {
          path: 'flows',
          name: 'agent_bots_flows',
          component: Flow,
          meta: {
            featureFlag: FEATURE_FLAGS.AGENT_BOTS,
            permissions: ['administrator'],
          },
          children: [
            {
              path: ':flowId',
              name: 'agent_bots_flow_edit',
              component: Flow,
              meta: {
                featureFlag: FEATURE_FLAGS.AGENT_BOTS,
                permissions: ['administrator'],
              },
            },
          ],
        },
      ],
    },
  ],
};
