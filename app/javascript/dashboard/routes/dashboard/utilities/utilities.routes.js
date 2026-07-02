import { frontendURL } from '../../../helper/URLHelper';

const Index = () => import('./Index.vue');
const ConversationSummary = () => import('./conversationSummary/Index.vue');

export const routes = [
  {
    path: frontendURL('accounts/:accountId/utilities'),
    component: Index,
    children: [
      {
        path: '',
        redirect: to => {
          return { name: 'utilities_conversation_summary', params: to.params };
        },
      },
      {
        path: 'conversation-summary',
        name: 'utilities_conversation_summary',
        meta: {
          permissions: ['administrator'],
        },
        component: ConversationSummary,
      },
    ],
  },
];
