const fs = require('fs');
const filePath =
  'app/javascript/dashboard/routes/dashboard/sales/settings/Index.vue';
let content = fs.readFileSync(filePath, 'utf8');

const regex =
  /<!-- Ecom Integrations -->[\s\S]*?(?=<\/div>\n  <\/div>\n<\/template>)/;
const replacement = `<!-- Integration selector -->
      <div class="flex flex-col gap-4">
        <div class="flex flex-col gap-1.5">
          <label class="text-sm font-medium text-n-slate-12">
            {{ t('INBOX_MGMT.ECOMMERCE.SELECT_PLATFORM') }}
          </label>

          <div
            v-if="integrations.length === 0"
            class="flex flex-col items-center py-8 px-4"
          >
            <div
              class="w-12 h-12 rounded-xl bg-n-solid-3 flex items-center justify-center mb-3"
            >
              <i class="i-lucide-unplug text-xl text-n-slate-10" />
            </div>
            <p class="text-sm text-n-slate-11 text-center">
              {{ t('INBOX_MGMT.ECOMMERCE.NO_INTEGRATIONS') }}
            </p>
          </div>

          <div v-else class="flex flex-col gap-2">
            <!-- Flowify (Native) option -->
            <button
              class="flex items-center gap-3 px-4 py-3 rounded-xl border transition-all"
              :class="
                selectedIntegrationId === 'shopiz'
                  ? 'border-n-brand bg-n-brand/5 ring-1 ring-n-brand/30'
                  : 'border-n-weak bg-n-solid-1 hover:bg-n-alpha-1'
              "
              @click="selectedIntegrationId = 'shopiz'"
            >
              <div
                class="w-8 h-8 rounded-lg flex items-center justify-center"
                :class="
                  selectedIntegrationId === 'shopiz'
                    ? 'bg-n-brand/10'
                    : 'bg-n-solid-3'
                "
              >
                <i
                  class="i-lucide-shopping-bag text-sm"
                  :class="
                    selectedIntegrationId === 'shopiz'
                      ? 'text-n-brand'
                      : 'text-n-slate-10'
                  "
                />
              </div>
              <span
                class="text-sm"
                :class="
                  selectedIntegrationId === 'shopiz'
                    ? 'text-n-slate-12 font-medium'
                    : 'text-n-slate-11'
                "
              >
                Flowify
              </span>
              <i
                v-if="selectedIntegrationId === 'shopiz'"
                class="i-lucide-check text-n-brand text-sm ml-auto"
              />
            </button>

            <!-- Platform options -->
            <button
              v-for="integration in integrations"
              :key="integration.hookId"
              class="flex items-center gap-3 px-4 py-3 rounded-xl border transition-all"
              :class="
                selectedIntegrationId === integration.hookId
                  ? 'border-n-brand bg-n-brand/5 ring-1 ring-n-brand/30'
                  : 'border-n-weak bg-n-solid-1 hover:bg-n-alpha-1'
              "
              @click="selectedIntegrationId = integration.hookId"
            >
              <div
                class="w-8 h-8 rounded-lg flex items-center justify-center"
                :class="
                  selectedIntegrationId === integration.hookId
                    ? 'bg-n-brand/10'
                    : 'bg-n-solid-3'
                "
              >
                <i :class="integration.icon" class="text-sm" />
              </div>
              <span
                class="text-sm"
                :class="
                  selectedIntegrationId === integration.hookId
                    ? 'text-n-slate-12 font-medium'
                    : 'text-n-slate-11'
                "
              >
                {{ integration.label }}
              </span>
              <i
                v-if="selectedIntegrationId === integration.hookId"
                class="i-lucide-check text-n-brand text-sm ml-auto"
              />
            </button>
          </div>
        </div>
      </div>

      <div class="w-full h-[1px] bg-n-weak my-4" />

      <!-- Sales settings: AI Order + Templates -->
      <div class="flex flex-col gap-6">
        <!-- Trợ lý AI tạo đơn hàng -->
        <div class="flex flex-col gap-4">
          <div class="flex flex-col gap-1">
            <h3 class="text-lg font-semibold text-n-slate-12">
              {{ t('INBOX_MGMT.ECOMMERCE.AI_ORDER_TITLE') }}
            </h3>
            <p class="text-sm text-n-slate-11">
              {{ t('INBOX_MGMT.ECOMMERCE.AI_ORDER_DESCRIPTION') }}
            </p>
          </div>
          <div class="flex items-center gap-3">
            <Switch v-model="allowAiCreateOrder" />
            <span class="text-sm text-n-slate-12">{{
              t('INBOX_MGMT.ECOMMERCE.AI_ORDER_TOGGLE')
            }}</span>
          </div>
        </div>

        <div class="w-full h-[1px] bg-n-weak my-2" />

        <!-- Mẫu thông báo đơn hàng -->
        <div class="flex flex-col gap-4">
          <div class="flex flex-row items-start justify-between gap-4">
            <div class="flex flex-col gap-1">
              <h3 class="text-lg font-semibold text-n-slate-12">
                {{ t('INBOX_MGMT.ECOMMERCE.TEMPLATES_TITLE') }}
              </h3>
              <p class="text-sm text-n-slate-11">
                {{ t('INBOX_MGMT.ECOMMERCE.TEMPLATES_DESCRIPTION') }}
              </p>
            </div>
          </div>

          <!-- Toggle customize templates -->
          <div class="flex items-center gap-3">
            <Switch v-model="customizeTemplates" />
            <span class="text-sm text-n-slate-12">
              {{ t('INBOX_MGMT.ECOMMERCE.CUSTOMIZE_TEMPLATES_TOGGLE') }}
            </span>
          </div>

          <template v-if="customizeTemplates">
            <!-- Variable tags helper -->
            <div class="flex flex-col gap-2">
              <p class="text-xs font-medium text-n-slate-11">
                {{ t('INBOX_MGMT.ECOMMERCE.VARIABLE_TAGS_LABEL') }}
              </p>
              <div class="flex flex-wrap gap-1.5">
                <button
                  v-for="variable in TEMPLATE_VARIABLES"
                  :key="variable.key"
                  type="button"
                  class="inline-flex items-center gap-1 px-2 py-1 rounded-md bg-n-alpha-2 border border-n-weak text-xs font-mono text-n-slate-11 hover:bg-n-alpha-3 hover:text-n-slate-12 hover:border-n-slate-6 transition-all cursor-pointer select-none"
                  :title="
                    t('INBOX_MGMT.ECOMMERCE.VARIABLE_TAG_TOOLTIP', {
                      variable: variable.key,
                    })
                  "
                  @click="insertVariable(variable.key)"
                >
                  <i class="i-lucide-code text-[10px] opacity-60" />
                  {{ t(variable.labelKey) }}
                </button>
              </div>
            </div>

            <div class="flex justify-end">
              <NextButton
                sm
                outline
                slate
                icon="i-lucide-wand-2"
                class="flex-shrink-0"
                @click="fillDefaultTemplates"
              >
                {{ t('INBOX_MGMT.ECOMMERCE.FILL_DEFAULT_TEMPLATES') }}
              </NextButton>
            </div>

            <div class="grid gap-4">
              <WithLabel
                name="template-draft"
                :label="$t('SALES.MODULE_ORDERS.STATUS.DRAFT')"
              >
                <div data-template-key="draft" class="w-full">
                  <textarea
                    v-model="salesOrderNotificationTemplates.draft"
                    class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                    :placeholder="
                      t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_DRAFT')
                    "
                    @focus="onTextareaFocus"
                  />
                </div>
              </WithLabel>
              <WithLabel
                name="template-confirmed"
                :label="$t('SALES.MODULE_ORDERS.STATUS.CONFIRMED')"
              >
                <div data-template-key="confirmed" class="w-full">
                  <textarea
                    v-model="salesOrderNotificationTemplates.confirmed"
                    class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                    :placeholder="
                      t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_CONFIRMED')
                    "
                    @focus="onTextareaFocus"
                  />
                </div>
              </WithLabel>
              <WithLabel
                name="template-processing"
                :label="$t('SALES.MODULE_ORDERS.STATUS.PROCESSING')"
              >
                <div data-template-key="processing" class="w-full">
                  <textarea
                    v-model="salesOrderNotificationTemplates.processing"
                    class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                    :placeholder="
                      t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_PROCESSING')
                    "
                    @focus="onTextareaFocus"
                  />
                </div>
              </WithLabel>
              <WithLabel
                name="template-shipped"
                :label="$t('SALES.MODULE_ORDERS.STATUS.SHIPPED')"
              >
                <div data-template-key="shipped" class="w-full">
                  <textarea
                    v-model="salesOrderNotificationTemplates.shipped"
                    class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                    :placeholder="
                      t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_SHIPPED')
                    "
                    @focus="onTextareaFocus"
                  />
                </div>
              </WithLabel>
              <WithLabel
                name="template-delivered"
                :label="$t('SALES.MODULE_ORDERS.STATUS.DELIVERED')"
              >
                <div data-template-key="delivered" class="w-full">
                  <textarea
                    v-model="salesOrderNotificationTemplates.delivered"
                    class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                    :placeholder="
                      t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_DELIVERED')
                    "
                    @focus="onTextareaFocus"
                  />
                </div>
              </WithLabel>
              <WithLabel
                name="template-cancelled"
                :label="$t('SALES.MODULE_ORDERS.STATUS.CANCELLED')"
              >
                <div data-template-key="cancelled" class="w-full">
                  <textarea
                    v-model="salesOrderNotificationTemplates.cancelled"
                    class="w-full min-h-[80px] rounded-lg bg-n-alpha-black2 p-3 text-sm text-n-slate-12 outline outline-1 outline-offset-[-1px] outline-n-weak hover:outline-n-slate-6 focus:outline-n-orange focus:ring-0 border-none"
                    :placeholder="
                      t('INBOX_MGMT.ECOMMERCE.TEMPLATES_PLACEHOLDER_CANCELLED')
                    "
                    @focus="onTextareaFocus"
                  />
                </div>
              </WithLabel>
            </div>
          </template>
        </div>
      </div>

      <!-- Save button (unified: integration + sales settings) -->
      <div class="flex justify-end pt-2">
        <NextButton
          :label="t('INBOX_MGMT.ECOMMERCE.SAVE')"
          sm
          :is-loading="isSaving"
          @click="handleSave"
        />
      </div>

      <div class="w-full h-[1px] bg-n-weak my-6" />

      <!-- Ecom Integrations -->
      <div class="flex flex-col gap-4">
        <div class="flex flex-col gap-1">
          <h3 class="text-lg font-semibold text-n-slate-12">
            Liên kết phần mềm bán hàng
          </h3>
          <p class="text-sm text-n-slate-11">
            Quản lý và cài đặt các liên kết với hệ thống bên thứ ba.
          </p>
        </div>
        <div
          class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 xl:grid-cols-3 gap-6"
        >
          <IntegrationItem
            v-for="item in ecomIntegrations"
            :id="item.id"
            :key="item.id"
            :logo="item.logo"
            :name="item.name"
            :description="item.description"
            :enabled="item.enabled"
            :is-active="item.is_active"
          />
        </div>
      </div>`;

content = content.replace(regex, replacement);
fs.writeFileSync(filePath, content, 'utf8');
