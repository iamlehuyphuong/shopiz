import { frontendURL } from 'dashboard/helper/URLHelper.js';

import CampaignsPageRouteView from './pages/CampaignsPageRouteView.vue';
import LiveChatCampaignsPage from './pages/LiveChatCampaignsPage.vue';
import SMSCampaignsPage from './pages/SMSCampaignsPage.vue';
import WhatsAppCampaignsPage from './pages/WhatsAppCampaignsPage.vue';
import ZaloPersonalCampaignsPage from './pages/ZaloPersonalCampaignsPage.vue';
import ZaloOaCampaignsPage from './pages/ZaloOaCampaignsPage.vue';
import FacebookCampaignsPage from './pages/FacebookCampaignsPage.vue';
import LineCampaignsPage from './pages/LineCampaignsPage.vue';
import TelegramCampaignsPage from './pages/TelegramCampaignsPage.vue';

import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const meta = {
  featureFlag: FEATURE_FLAGS.CAMPAIGNS,
  permissions: ['administrator'],
};

const campaignsRoutes = {
  routes: [
    {
      path: frontendURL('accounts/:accountId/campaigns'),
      component: CampaignsPageRouteView,
      children: [
        {
          path: '',
          redirect: to => {
            return { name: 'campaigns_ongoing_index', params: to.params };
          },
        },
        {
          path: 'ongoing',
          name: 'campaigns_ongoing_index',
          meta,
          redirect: to => {
            return { name: 'campaigns_livechat_index', params: to.params };
          },
        },
        {
          path: 'one_off',
          name: 'campaigns_one_off_index',
          meta,
          redirect: to => {
            return { name: 'campaigns_sms_index', params: to.params };
          },
        },
        {
          path: 'live_chat',
          name: 'campaigns_livechat_index',
          meta,
          component: LiveChatCampaignsPage,
        },
        {
          path: 'zalo_personal',
          name: 'campaigns_zalo_personal_index',
          meta: {
            ...meta,
            featureFlag: FEATURE_FLAGS.CHANNEL_ZALO_PERSONAL,
          },
          component: ZaloPersonalCampaignsPage,
        },
        {
          path: 'zalo_oa',
          name: 'campaigns_zalo_oa_index',
          meta,
          component: ZaloOaCampaignsPage,
        },
        {
          path: 'sms',
          name: 'campaigns_sms_index',
          meta,
          component: SMSCampaignsPage,
        },
        {
          path: 'whatsapp',
          name: 'campaigns_whatsapp_index',
          meta: {
            ...meta,
            featureFlag: FEATURE_FLAGS.WHATSAPP_CAMPAIGNS,
          },
          component: WhatsAppCampaignsPage,
        },
        {
          path: 'facebook',
          name: 'campaigns_facebook_index',
          meta,
          component: FacebookCampaignsPage,
        },
        {
          path: 'telegram',
          name: 'campaigns_telegram_index',
          meta,
          component: TelegramCampaignsPage,
        },
        {
          path: 'line',
          name: 'campaigns_line_index',
          meta,
          component: LineCampaignsPage,
        },
      ],
    },
  ],
};

export default campaignsRoutes;
