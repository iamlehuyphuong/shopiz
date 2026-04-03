import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { frontendURL } from 'dashboard/helper/URLHelper';
import SalesPageRouteView from './pages/SalesPageRouteView.vue';
import Pipeline from './components/Pipeline/Index.vue';
import Catalog from './components/Catalog/Index.vue';
import Orders from './components/Orders/Index.vue';

const meta = {
  permissions: ['administrator', 'agent', 'custom_role', 'sales_manage'],
};

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/sales'),
      component: SalesPageRouteView,
      meta,
      children: [
        {
          path: '',
          meta,
          redirect: to => {
            return { name: 'sales_pipeline_index', params: to.params };
          },
        },
        {
          path: 'pipeline',
          name: 'sales_pipeline_index',
          component: Pipeline,
          meta,
        },
        {
          path: 'orders',
          name: 'sales_orders_index',
          component: Orders,
          meta,
        },
        {
          path: 'catalog',
          name: 'sales_catalog_index',
          component: Catalog,
          meta,
        },
      ],
    },
  ],
};
