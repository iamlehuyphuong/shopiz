const fs = require('fs');
const file = 'app/javascript/dashboard/routes/dashboard/sales/sales.routes.js';
let content = fs.readFileSync(file, 'utf8');

const toolsRoute = `
  {
    path: frontendURL('accounts/:accountId/sales/tools'),
    name: 'sales_tools_index',
    meta: {
      permissions: ['administrator', 'sales_manage'],
      featureFlag: FEATURE_FLAGS.SALES,
    },
    component: () => import('./tools/Index.vue'),
  },`;

content = content.replace(/,\s*\{[\s]*path: frontendURL\('accounts\/:accountId\/sales\/settings'\)/, toolsRoute + '\n  {\n    path: frontendURL(\'accounts/:accountId/sales/settings\')');

fs.writeFileSync(file, content);
