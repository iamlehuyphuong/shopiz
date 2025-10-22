import { frontendURL } from '../../../../helper/URLHelper';

const sales = accountId => ({
  parentNav: 'sales',
  routes: ['sales_pipeline_index', 'sales_catalog_index', 'sales_orders_index'],
  menuItems: [
    {
      icon: 'arrow-swap',
      label: 'SALES_PIPELINE',
      key: 'pipeline',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/sales/pipeline`),
      toStateName: 'sales_pipeline_index',
    },
    {
      key: 'orders',
      icon: 'sound-source',
      label: 'SALES_ORDERS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/sales/orders`),
      toStateName: 'sales_orders_index',
    },
    {
      key: 'catalog',
      icon: 'sound-source',
      label: 'SALES_CATALOG',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/sales/catalog`),
      toStateName: 'sales_catalog_index',
    },
  ],
});

export default sales;