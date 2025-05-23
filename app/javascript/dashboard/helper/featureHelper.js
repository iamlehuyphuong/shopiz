const FEATURE_HELP_URLS = {
  agent_bots: 'https://shopiz.pro/hc/agent-bots',
  agents: 'https://shopiz.pro/hc/agents',
  audit_logs: 'https://shopiz.pro/hc/audit-logs',
  campaigns: 'https://shopiz.pro/hc/campaigns',
  canned_responses: 'https://shopiz.pro/hc/canned',
  channel_email: 'https://shopiz.pro/hc/email',
  channel_facebook: 'https://shopiz.pro/hc/fb',
  custom_attributes: 'https://shopiz.pro/hc/custom-attributes',
  dashboard_apps: 'https://shopiz.pro/hc/dashboard-apps',
  help_center: 'https://shopiz.pro/hc/help-center',
  inboxes: 'https://shopiz.pro/hc/inboxes',
  integrations: 'https://shopiz.pro/hc/integrations',
  labels: 'https://shopiz.pro/hc/labels',
  macros: 'https://shopiz.pro/hc/macros',
  message_reply_to: 'https://shopiz.pro/hc/reply-to',
  reports: 'https://shopiz.pro/hc/reports',
  sla: 'https://shopiz.pro/hc/sla',
  team_management: 'https://shopiz.pro/hc/teams',
  webhook: 'https://shopiz.pro/hc/webhooks',
  billing: 'https://shopiz.pro/pricing',
};

export function getHelpUrlForFeature(featureName) {
  return FEATURE_HELP_URLS[featureName];
}
