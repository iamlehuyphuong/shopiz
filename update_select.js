const fs = require('fs');
const filePath =
  'app/javascript/dashboard/routes/dashboard/sales/settings/Index.vue';
let content = fs.readFileSync(filePath, 'utf8');

const regex =
  /<div v-else class="flex flex-col gap-2">[\s\S]*?(?=<\/div>\n        <\/div>\n      <\/div>\n\n      <div class="w-full h-\[1px\] bg-n-weak my-4" \/>)/;
const replacement = `<div v-else class="relative w-full max-w-md">
            <select
              v-model="selectedIntegrationId"
              class="w-full appearance-none bg-n-solid-1 border border-n-weak rounded-xl text-sm text-n-slate-12 px-4 py-3 pr-10 hover:bg-n-alpha-1 focus:ring-1 focus:ring-n-brand outline-none transition-all cursor-pointer"
              @change="handleSave"
            >
              <option value="shopiz">Flowify</option>
              <option
                v-for="integration in integrations"
                :key="integration.hookId"
                :value="integration.hookId"
              >
                {{ integration.label }}
              </option>
            </select>
            <div class="absolute inset-y-0 right-0 flex items-center pr-4 pointer-events-none">
              <i class="i-lucide-chevron-down text-n-slate-10 text-sm" />
            </div>
          </div>`;

content = content.replace(regex, replacement);
fs.writeFileSync(filePath, content, 'utf8');
