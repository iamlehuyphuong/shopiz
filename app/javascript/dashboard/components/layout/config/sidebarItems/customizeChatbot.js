import { frontendURL } from '../../../../helper/URLHelper';

const customizeChatbot = accountId => ({
  parentNav: 'customizeChatbot',
  routes: [
    'customizeChatbot_companySetup_index',
    'customizeChatbot_product_index',
  ],
  menuItems: [
    {
      icon: 'arrow-swap',
      label: 'COMPANY_SETUP',
      key: 'ongoingCampaigns',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/customize-chatbot/company`),
      toStateName: 'customizeChatbot_companySetup_index',
    },
    {
      key: 'oneOffCampaigns',
      icon: 'sound-source',
      label: 'PRODUCT',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/customize-chatbot/product`),
      toStateName: 'customizeChatbot_product_index',
    },
  ],
});

export default customizeChatbot;
