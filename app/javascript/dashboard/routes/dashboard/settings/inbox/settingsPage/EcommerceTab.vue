<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const emit = defineEmits(['update']);

const ECOMMERCE_APP_IDS = [
  'kiotviet',
  'sapo',
  'haravan',
  'shopify',
  'woocommerce',
  'nhanhvn',
  'tiktok_shop',
];

const PLATFORM_LABELS = {
  kiotviet: 'KiotViet',
  sapo: 'Sapo',
  haravan: 'Haravan',
  shopify: 'Shopify',
  woocommerce: 'WooCommerce',
  nhanhvn: 'Nhanh.vn',
  tiktok_shop: 'TikTok Shop',
};

const PLATFORM_ICONS = {
  kiotviet: 'i-lucide-store',
  sapo: 'i-lucide-shopping-bag',
  haravan: 'i-lucide-shopping-cart',
  shopify: 'i-lucide-package',
  woocommerce: 'i-lucide-globe',
  nhanhvn: 'i-lucide-zap',
  tiktok_shop: 'i-lucide-music',
};

const { t } = useI18n();
const store = useStore();

const selectedIntegrationId = ref(null);
const isSaving = ref(false);

const integrations = computed(() => {
  const allIntegrations = store.getters['integrations/getAppIntegrations'];
  return allIntegrations
    .filter(app => ECOMMERCE_APP_IDS.includes(app.id) && app.hooks?.length > 0)
    .map(app => ({
      hookId: app.hooks[0].id,
      appId: app.id,
      label: PLATFORM_LABELS[app.id] || app.id,
      icon: PLATFORM_ICONS[app.id] || 'i-lucide-box',
    }));
});

const isMarketplaceLocked = computed(
  () => props.inbox.marketplace_locked || false
);

const currentIntegration = computed(() =>
  integrations.value.find(i => i.hookId === selectedIntegrationId.value)
);

onMounted(() => {
  store.dispatch('integrations/get');
  selectedIntegrationId.value = props.inbox.ecommerce_integration?.id || null;
});

const handleSave = async () => {
  if (isMarketplaceLocked.value) return;

  isSaving.value = true;
  try {
    await store.dispatch('inboxes/updateInbox', {
      id: props.inbox.id,
      ecommerce_integration_id: selectedIntegrationId.value,
    });
    useAlert(t('INBOX_MGMT.ECOMMERCE.SAVE_SUCCESS'));
  } catch (error) {
    useAlert(error.message || t('INBOX_MGMT.ECOMMERCE.SAVE_ERROR'));
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <div class="max-w-4xl mx-6">
    <div class="flex flex-col gap-6">
      <!-- Header -->
      <div class="flex flex-col gap-1">
        <h3 class="text-lg font-semibold text-n-slate-12">
          {{ t('INBOX_MGMT.ECOMMERCE.TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11">
          {{ t('INBOX_MGMT.ECOMMERCE.DESCRIPTION') }}
        </p>
      </div>

      <!-- Marketplace locked banner -->
      <div
        v-if="isMarketplaceLocked"
        class="flex items-center gap-3 rounded-xl border border-n-teal-6 bg-n-teal-2 px-4 py-3"
      >
        <i class="i-lucide-lock text-n-teal-11 text-base" />
        <div class="flex-1">
          <p class="text-sm font-medium text-n-teal-12">
            {{
              t('INBOX_MGMT.ECOMMERCE.AUTO_LINKED', {
                platform:
                  PLATFORM_LABELS[inbox.ecommerce_integration?.app_id] ||
                  'Marketplace',
              })
            }}
          </p>
          <p class="text-xs text-n-teal-11 mt-0.5">
            {{ t('INBOX_MGMT.ECOMMERCE.MARKETPLACE_NOTE') }}
          </p>
        </div>
        <span
          v-if="inbox.ecommerce_integration"
          class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-n-teal-4 text-sm font-medium text-n-teal-12"
        >
          <i
            :class="
              PLATFORM_ICONS[inbox.ecommerce_integration.app_id] ||
              'i-lucide-box'
            "
            class="text-sm"
          />
          {{
            PLATFORM_LABELS[inbox.ecommerce_integration.app_id] ||
            inbox.ecommerce_integration.app_id
          }}
        </span>
      </div>

      <!-- Integration selector -->
      <div v-else class="flex flex-col gap-4">
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
            <!-- None option -->
            <button
              class="flex items-center gap-3 px-4 py-3 rounded-xl border transition-all"
              :class="
                selectedIntegrationId === null
                  ? 'border-n-brand bg-n-brand/5 ring-1 ring-n-brand/30'
                  : 'border-n-weak bg-n-solid-1 hover:bg-n-alpha-1'
              "
              @click="selectedIntegrationId = null"
            >
              <div
                class="w-8 h-8 rounded-lg flex items-center justify-center"
                :class="
                  selectedIntegrationId === null
                    ? 'bg-n-brand/10'
                    : 'bg-n-solid-3'
                "
              >
                <i
                  class="i-lucide-x text-sm"
                  :class="
                    selectedIntegrationId === null
                      ? 'text-n-brand'
                      : 'text-n-slate-10'
                  "
                />
              </div>
              <span
                class="text-sm"
                :class="
                  selectedIntegrationId === null
                    ? 'text-n-slate-12 font-medium'
                    : 'text-n-slate-11'
                "
              >
                {{ t('INBOX_MGMT.ECOMMERCE.NONE') }}
              </span>
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

        <!-- Save button -->
        <div class="flex justify-end pt-2">
          <NextButton
            :label="t('INBOX_MGMT.ECOMMERCE.SAVE')"
            sm
            :is-loading="isSaving"
            @click="handleSave"
          />
        </div>
      </div>
    </div>
  </div>
</template>
