import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { frontendURL } from 'dashboard/helper/URLHelper';
import SalesPageRouteView from './pages/SalesPageRouteView.vue';
import KanbanLeads from './components/KanbanLeads/Index.vue';

const meta = {
  featureFlag: FEATURE_FLAGS.CAMPAIGNS,
  permissions: ['administrator'],
};
export const routes = [
  {
    path: frontendURL('accounts/:accountId/sales'),
    component: SalesPageRouteView,
    children: [
      {
        path: '',
        redirect: to => {
          return { name: 'sales_leads_index', params: to.params };
        },
      },
      {
        path: 'leads',
        name: 'sales_leads_index',
        component: KanbanLeads,
        meta,
      },
    ],
  },
];
