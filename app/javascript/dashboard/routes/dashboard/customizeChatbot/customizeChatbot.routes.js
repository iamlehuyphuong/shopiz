/* eslint arrow-body-style: 0 */
import { frontendURL } from '../../../helper/URLHelper';
import CompanyCustomizePage from './pages/CompanyCustomizePage.vue';
import CustomizeChatbotView from './pages/CustomizePageRouteView.vue';
import ProductCustomizePage from './pages/ProductCustomizePage.vue';

const meta = {
  permissions: [
    'administrator',
    'agent',
    'conversation_manage',
    'conversation_unassigned_manage',
    'conversation_participating_manage',
  ],
};

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/customize-chatbot'),
      component: CustomizeChatbotView,
      children: [
        {
          path: '',
          redirect: to => {
            return {
              name: 'customizeChatbot_companySetup_index',
              params: to.params,
            };
          },
        },
        {
          path: 'company',
          name: 'customizeChatbot_companySetup_index',
          meta,
          component: CompanyCustomizePage,
        },
        {
          path: 'product',
          name: 'customizeChatbot_product_index',
          meta,
          component: ProductCustomizePage,
        },
        {
          path: 'service',
          name: 'customizeChatbot_service_index',
          meta,
          component: CustomizeChatbotView,
        },
        {
          path: 'FQAs',
          name: 'customizeChatbot_FQAs_index',
          meta,
          component: CustomizeChatbotView,
        },
        {
          path: 'config',
          name: 'customizeChatbot_config_index',
          meta,
          component: CustomizeChatbotView,
        },
      ],
    },
  ],
};
