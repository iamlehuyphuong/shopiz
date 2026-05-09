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
];
