import { frontendURL } from '../../../../helper/URLHelper';

const captain = accountId => ({
  parentNav: 'captain',
  routes: [
    'captain_assistants_index',
    'captain_assistants_edit',
    'captain_assistants_inboxes_index',
    'captain_documents_index',
    'captain_responses_index',
  ],
  menuItems: [
    {
      icon: 'captain',
      label: 'CAPTAIN_ASSISTANTS',
      key: 'captainAssistants',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/captain/assistants`),
      toStateName: 'captain_assistants_index',
    },
    {
      key: 'captainDocuments',
      icon: 'document',
      label: 'CAPTAIN_DOCUMENTS',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/captain/documents`),
      toStateName: 'captain_documents_index',
    },
    {
      key: 'captainResponses',
      icon: 'library',
      label: 'CAPTAIN_RESPONSES',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/captain/responses`),
      toStateName: 'captain_responses_index',
    },
  ],
});

export default captain;
