import { FEATURE_FLAGS } from '../../../../featureFlags';
import { frontendURL } from '../../../../helper/URLHelper';
import SettingsWrapper from '../SettingsWrapper.vue';
import IntegrationHooks from './IntegrationHooks.vue';
import Index from './Index.vue';
import Webhook from './Webhooks/Index.vue';

import Slack from './Slack.vue';
import Linear from './Linear.vue';
import Notion from './Notion.vue';
import Shopify from './Shopify.vue';
import Kiotviet from './Kiotviet.vue';
import Haravan from './Haravan.vue';
import Woocommerce from './Woocommerce.vue';
import Sapo from './Sapo.vue';
import Nhanhvn from './Nhanhvn.vue';
import Omicall from './Omicall.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/settings/integrations'),
      component: SettingsWrapper,
      props: {},
      children: [
        {
          path: '',
          name: 'settings_applications',
          component: Index,
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
        },

        {
          path: 'webhook',
          component: Webhook,
          name: 'settings_integrations_webhook',
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
        },
      ],
    },
    {
      path: frontendURL('accounts/:accountId/settings/integrations'),
      component: SettingsWrapper,
      children: [
        {
          path: 'slack',
          name: 'settings_integrations_slack',
          component: Slack,
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
          props: route => ({ code: route.query.code }),
        },
        {
          path: 'linear',
          name: 'settings_integrations_linear',
          component: Linear,
          meta: {
            permissions: ['administrator'],
          },
          props: route => ({ code: route.query.code }),
        },
        {
          path: 'notion',
          name: 'settings_integrations_notion',
          component: Notion,
          meta: {
            permissions: ['administrator'],
          },
          props: route => ({ code: route.query.code }),
        },
        {
          path: 'shopify',
          name: 'settings_integrations_shopify',
          component: Shopify,
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
          props: route => ({ error: route.query.error }),
        },
        {
          path: 'kiotviet',
          name: 'settings_integrations_kiotviet',
          component: Kiotviet,
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
        },
        {
          path: 'haravan',
          name: 'settings_integrations_haravan',
          component: Haravan,
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
        },
        {
          path: 'woocommerce',
          name: 'settings_integrations_woocommerce',
          component: Woocommerce,
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
        },
        {
          path: 'sapo',
          name: 'settings_integrations_sapo',
          component: Sapo,
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
        },
        {
          path: 'nhanhvn',
          name: 'settings_integrations_nhanhvn',
          component: Nhanhvn,
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
        },
        {
          path: 'omicall',
          name: 'settings_integrations_omicall',
          component: Omicall,
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
        },
        {
          path: ':integration_id',
          name: 'settings_applications_integration',
          component: IntegrationHooks,
          meta: {
            featureFlag: FEATURE_FLAGS.INTEGRATIONS,
            permissions: ['administrator'],
          },
          props: route => ({
            integrationId: route.params.integration_id,
          }),
        },
      ],
    },
  ],
};
