import { frontendURL } from '../../../../helper/URLHelper';
import CompanySetupIcon from '../../sidebarComponents/icons/CustomizeChatbot/CompanySetupIcon.vue';
import ProductIcon from '../../sidebarComponents/icons/CustomizeChatbot/ProductIcon.vue';
import ServiceIcon from '../../sidebarComponents/icons/CustomizeChatbot/ServiceIcon.vue';
import FAQsIcon from '../../sidebarComponents/icons/CustomizeChatbot/FAQsIcon.vue';
import ConfigChatbotIcon from '../../sidebarComponents/icons/CustomizeChatbot/ConfigChatbotIcon.vue';

const customizeChatbot = accountId => ({
  parentNav: 'customizeChatbot',
  routes: [
    'customizeChatbot_companySetup_index',
    'customizeChatbot_product_index',
  ],
  menuItems: [
    {
      icon: CompanySetupIcon,
      label: 'COMPANY_SETUP',
      key: 'companySetup',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/customize-chatbot/company`),
      toStateName: 'customizeChatbot_companySetup_index',
    },
    {
      icon: ProductIcon,
      key: 'product',
      label: 'PRODUCT',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/customize-chatbot/product`),
      toStateName: 'customizeChatbot_product_index',
    },
    ,
    {
      icon: ServiceIcon,
      key: 'service',
      label: 'SERVICE',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/customize-chatbot/product`),
      toStateName: 'customizeChatbot_service_index',
    },
    {
      icon: FAQsIcon,
      key: 'FAQS',
      label: 'FAQS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/customize-chatbot/product`),
      toStateName: 'customizeChatbot_FAQs_index',
    },
    {
      icon: ConfigChatbotIcon,
      key: 'configChatbot',
      label: 'CONFIG_CHATBOT',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/customize-chatbot/product`),
      toStateName: 'customizeChatbot_config_index',
    }
  ],
});

export default customizeChatbot;
