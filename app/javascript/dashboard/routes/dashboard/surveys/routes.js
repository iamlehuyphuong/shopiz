import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { frontendURL } from 'dashboard/helper/URLHelper';
import SurveyCreator from '../../../components-next/SurveyCreator/SurveyCreator.vue';

const meta = {
  featureFlag: FEATURE_FLAGS.CAMPAIGNS,
  permissions: ['administrator'],
};
export const routes = [
  {
    path: frontendURL('accounts/:accountId/campaigns'),
    children: [
      {
        path: 'surveys',
        name: 'campaigns_survey_index',
        component: SurveyCreator,
        meta,
      },
    ],
  },
];
