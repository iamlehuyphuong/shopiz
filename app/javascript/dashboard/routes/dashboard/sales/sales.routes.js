import { frontendURL } from '../../../helper/URLHelper';
import Dashboard from './Dashboard.vue';
import Orders from './Orders.vue';
import Products from './Products.vue';
import Tools from './Tools.vue';

export const routes = [
  {
    path: frontendURL('accounts/:accountId/sales/dashboard'),
    name: 'sales_dashboard',
    meta: {
      permissions: ['administrator', 'sales_manage'],
    },
    component: Dashboard,
  },
  {
    path: frontendURL('accounts/:accountId/sales/orders'),
    name: 'sales_orders',
    meta: {
      permissions: ['administrator', 'sales_manage'],
    },
    component: Orders,
  },
  {
    path: frontendURL('accounts/:accountId/sales/products'),
    name: 'sales_products',
    meta: {
      permissions: ['administrator', 'sales_manage'],
    },
    component: Products,
  },
  {
    path: frontendURL('accounts/:accountId/sales/tools'),
    name: 'sales_tools',
    meta: {
      permissions: ['administrator', 'sales_manage'],
    },
    component: Tools,
  },
];
