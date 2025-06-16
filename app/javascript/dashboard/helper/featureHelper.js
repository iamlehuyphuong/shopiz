const FEATURE_HELP_URLS = {
  agent_bots: 'https://help.shopiz.pro/hc/agent-bots',
  agents: 'https://help.shopiz.pro/hc/agents',
  audit_logs: 'https://help.shopiz.pro/hc/audit-logs',
  campaigns: 'https://help.shopiz.pro/hc/campaigns',
  canned_responses: 'https://help.shopiz.pro/hc/canned',
  channel_email: 'https://help.shopiz.pro/hc/email',
  channel_facebook: 'https://help.shopiz.pro/hc/fb',
  custom_attributes: 'https://help.shopiz.pro/hc/custom-attributes',
  dashboard_apps: 'https://help.shopiz.pro/hc/dashboard-apps',
  help_center: 'https://help.shopiz.pro/hc/help-center',
  inboxes: 'https://help.shopiz.pro/hc/inboxes',
  integrations: 'https://help.shopiz.pro/hc/integrations',
  labels: 'https://help.shopiz.pro/hc/labels',
  macros: 'https://help.shopiz.pro/hc/macros',
  message_reply_to: 'https://help.shopiz.pro/hc/reply-to',
  reports: 'https://help.shopiz.pro/hc/reports',
  sla: 'https://help.shopiz.pro/hc/sla',
  team_management: 'https://help.shopiz.pro/hc/teams',
  webhook: 'https://help.shopiz.pro/hc/webhooks',
  billing: 'https://www.shopiz.pro/pricing',
};

export function getHelpUrlForFeature(featureName) {
  return FEATURE_HELP_URLS[featureName];
}
