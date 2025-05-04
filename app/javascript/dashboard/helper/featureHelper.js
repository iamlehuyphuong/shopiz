const FEATURE_HELP_URLS = {
  agent_bots: 'https://salesman.effiai.pro/hc/agent-bots',
  agents: 'https://salesman.effiai.pro/hc/agents',
  audit_logs: 'https://salesman.effiai.pro/hc/audit-logs',
  campaigns: 'https://salesman.effiai.pro/hc/campaigns',
  canned_responses: 'https://salesman.effiai.pro/hc/canned',
  channel_email: 'https://salesman.effiai.pro/hc/email',
  channel_facebook: 'https://salesman.effiai.pro/hc/fb',
  custom_attributes: 'https://salesman.effiai.pro/hc/custom-attributes',
  dashboard_apps: 'https://salesman.effiai.pro/hc/dashboard-apps',
  help_center: 'https://salesman.effiai.pro/hc/help-center',
  inboxes: 'https://salesman.effiai.pro/hc/inboxes',
  integrations: 'https://salesman.effiai.pro/hc/integrations',
  labels: 'https://salesman.effiai.pro/hc/labels',
  macros: 'https://salesman.effiai.pro/hc/macros',
  message_reply_to: 'https://salesman.effiai.pro/hc/reply-to',
  reports: 'https://salesman.effiai.pro/hc/reports',
  sla: 'https://salesman.effiai.pro/hc/sla',
  team_management: 'https://salesman.effiai.pro/hc/teams',
  webhook: 'https://salesman.effiai.pro/hc/webhooks',
  billing: 'https://salesman.effiai.pro/pricing',
};

export function getHelpUrlForFeature(featureName) {
  return FEATURE_HELP_URLS[featureName];
}
