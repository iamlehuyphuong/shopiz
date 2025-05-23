import { frontendURL } from 'dashboard/helper/URLHelper.js';

import InsightsPageRouteView from './pages/InsightsPageRouteView.vue';
import TopicAnalysisPage from './pages/TopicAnalysisPage.vue';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const meta = {
  featureFlag: FEATURE_FLAGS.CAMPAIGNS,
  permissions: ['administrator'],
};

const insightsRoutes = {
  routes: [
    {
      path: frontendURL('accounts/:accountId/insights'),
      component: InsightsPageRouteView,
      children: [
        {
          path: 'topic-analysis',
          name: 'insights_topic_analysis_index',
          meta,
          component: TopicAnalysisPage,
        },
      ],
    },
  ],
};

export default insightsRoutes;