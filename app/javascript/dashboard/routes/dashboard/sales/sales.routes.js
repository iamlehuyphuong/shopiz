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
    path: frontendURL('accounts/:accountId/sales/settings'),
    component: () => import('./settings/Index.vue'),
    children: [
      {
        path: '',
        redirect: 'tool',
      },
      {
        path: 'tool',
        name: 'sales_settings_tool',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () => import('./settings/tabs/Tool.vue'),
      },
      {
        path: 'assistant',
        name: 'sales_settings_assistant',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () => import('./settings/tabs/Assistant.vue'),
      },
      {
        path: 'payment',
        name: 'sales_settings_payment',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () => import('./settings/tabs/Payment.vue'),
      },
      {
        path: 'invoice',
        name: 'sales_settings_invoice',
        meta: {
          permissions: ['administrator', 'sales_manage'],
          featureFlag: FEATURE_FLAGS.SALES,
        },
        component: () => import('./settings/tabs/Invoice.vue'),
      },
    ],
  },
  {
    path: frontendURL('accounts/:accountId/sales/settings/tool/woocommerce'),
    name: 'sales_settings_tool_woocommerce',
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
    path: frontendURL('accounts/:accountId/sales/settings/tool/kiotviet'),
    name: 'sales_settings_tool_kiotviet',
    meta: {
      permissions: ['administrator', 'sales_manage'],
      featureFlag: FEATURE_FLAGS.SALES,
    },
    component: () =>
      import('dashboard/routes/dashboard/settings/integrations/Kiotviet.vue'),
  },
  {
    path: frontendURL('accounts/:accountId/sales/settings/tool/haravan'),
    name: 'sales_settings_tool_haravan',
    meta: {
      permissions: ['administrator', 'sales_manage'],
      featureFlag: FEATURE_FLAGS.SALES,
    },
    component: () =>
      import('dashboard/routes/dashboard/settings/integrations/Haravan.vue'),
  },
  {
    path: frontendURL('accounts/:accountId/sales/settings/tool/sapo'),
    name: 'sales_settings_tool_sapo',
    meta: {
      permissions: ['administrator', 'sales_manage'],
      featureFlag: FEATURE_FLAGS.SALES,
    },
    component: () =>
      import('dashboard/routes/dashboard/settings/integrations/Sapo.vue'),
  },
  {
    path: frontendURL('accounts/:accountId/sales/settings/tool/nhanhvn'),
    name: 'sales_settings_tool_nhanhvn',
    meta: {
      permissions: ['administrator', 'sales_manage'],
      featureFlag: FEATURE_FLAGS.SALES,
    },
    component: () =>
      import('dashboard/routes/dashboard/settings/integrations/Nhanhvn.vue'),
  },
  {
    path: frontendURL(
      'accounts/:accountId/sales/settings/tool/google_calendar'
    ),
    name: 'sales_settings_tool_google_calendar',
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
    path: frontendURL(
      'accounts/:accountId/sales/settings/tool/:integration_id'
    ),
    name: 'sales_settings_tool_integration',
    meta: {
      permissions: ['administrator', 'sales_manage'],
      featureFlag: FEATURE_FLAGS.SALES,
    },
    props: route => ({ integrationId: route.params.integration_id }),
    component: () =>
      import(
        'dashboard/routes/dashboard/settings/integrations/IntegrationHooks.vue'
      ),
  },
  {
    path: frontendURL('accounts/:accountId/sales/settings/payment/sepay'),
    name: 'sales_settings_payment_sepay',
    meta: {
      permissions: ['administrator', 'sales_manage'],
      featureFlag: FEATURE_FLAGS.SALES,
    },
    component: () => import('./settings/integrations/Sepay.vue'),
  },
  {
    path: frontendURL('accounts/:accountId/sales/settings/payment/payos'),
    name: 'sales_settings_payment_payos',
    meta: {
      permissions: ['administrator', 'sales_manage'],
      featureFlag: FEATURE_FLAGS.SALES,
    },
    component: () => import('./settings/integrations/Payos.vue'),
  },
  {
    path: frontendURL('accounts/:accountId/sales/settings/payment/tingee'),
    name: 'sales_settings_payment_tingee',
    meta: {
      permissions: ['administrator', 'sales_manage'],
      featureFlag: FEATURE_FLAGS.SALES,
    },
    component: () => import('./settings/integrations/Tingee.vue'),
  },
];
