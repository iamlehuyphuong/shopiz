import { frontendURL } from '../../../helper/URLHelper';
import Dashboard from './Dashboard.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
export const routes = [
  {
    path: frontendURL('accounts/:accountId/sales/dashboard'),
    name: 'sales_dashboard',
    meta: {
      permissions: ['administrator', 'sales_manage'],
      featureFlag: FEATURE_FLAGS.SALES,
    },
    component: Dashboard,
  },
  {
    path: frontendURL('accounts/:accountId/sales/orders'),
    component: () => import('./orders/Index.vue'),
    children: [
      {
        path: '',
        redirect: 'list',
      },
      {
        path: 'list',
        name: 'sales_orders_list',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () => import('./orders/List.vue'),
      },
      {
        path: 'new',
        name: 'sales_orders_new',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () => import('./orders/New.vue'),
      },
      {
        path: ':id',
        name: 'sales_orders_show',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () => import('./orders/Show.vue'),
      },
      {
        path: ':id/edit',
        name: 'sales_orders_edit',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () => import('./orders/Edit.vue'),
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/sales/products'),
    component: () => import('./products/Index.vue'),
    children: [
      {
        path: '',
        redirect: 'list',
      },
      {
        path: 'list',
        name: 'sales_products_list',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () => import('./products/List.vue'),
      },
      {
        path: 'new',
        name: 'sales_products_new',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () => import('./products/New.vue'),
      },
      {
        path: ':id',
        name: 'sales_products_show',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () => import('./products/Show.vue'),
      },
      {
        path: ':id/edit',
        name: 'sales_products_edit',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () => import('./products/Edit.vue'),
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/sales/tools'),
    component: () =>
      import('dashboard/routes/dashboard/settings/SettingsWrapper.vue'),
    children: [
      {
        path: '',
        name: 'sales_tools_index',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () => import('./tools/Index.vue'),
      },
      {
        path: 'woocommerce',
        name: 'sales_tools_woocommerce',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () =>
          import(
            'dashboard/routes/dashboard/settings/integrations/Woocommerce.vue'
          ),
      },
      {
        path: 'kiotviet',
        name: 'sales_tools_kiotviet',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () =>
          import(
            'dashboard/routes/dashboard/settings/integrations/Kiotviet.vue'
          ),
      },
      {
        path: 'haravan',
        name: 'sales_tools_haravan',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () =>
          import(
            'dashboard/routes/dashboard/settings/integrations/Haravan.vue'
          ),
      },
      {
        path: 'sapo',
        name: 'sales_tools_sapo',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () =>
          import('dashboard/routes/dashboard/settings/integrations/Sapo.vue'),
      },
      {
        path: 'nhanhvn',
        name: 'sales_tools_nhanhvn',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () =>
          import(
            'dashboard/routes/dashboard/settings/integrations/Nhanhvn.vue'
          ),
      },
      {
        path: 'google_calendar',
        name: 'sales_tools_google_calendar',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () =>
          import(
            'dashboard/routes/dashboard/settings/integrations/GoogleCalendar.vue'
          ),
      },
      {
        path: ':integration_id',
        name: 'sales_tools_integration',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        props: route => ({
          integrationId: route.params.integration_id,
        }),
        component: () =>
          import(
            'dashboard/routes/dashboard/settings/integrations/IntegrationHooks.vue'
          ),
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/sales/settings'),
    name: 'sales_settings_index',
    meta: {
      permissions: ['administrator', 'sales_manage'],
      featureFlag: FEATURE_FLAGS.SALES,
    },
    component: () => import('./settings/Index.vue'),
  },
];
