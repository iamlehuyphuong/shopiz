<script setup>
import { computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { useI18n, I18nT } from 'vue-i18n';
import CloudWhatsapp from './CloudWhatsapp.vue';
import WhatsappEmbeddedSignup from './WhatsappEmbeddedSignup.vue';

const route = useRoute();
const router = useRouter();
const { t } = useI18n();

const PROVIDER_TYPES = {
  WHATSAPP: 'whatsapp',
  TWILIO: 'twilio',
  WHATSAPP_CLOUD: 'whatsapp_cloud',
  WHATSAPP_EMBEDDED: 'whatsapp_embedded',
  WHATSAPP_MANUAL: 'whatsapp_manual',
  THREE_SIXTY_DIALOG: '360dialog',
};

const hasWhatsappAppId = computed(() => {
  return (
    window.shopizConfig?.whatsappAppId &&
    window.shopizConfig.whatsappAppId !== 'none'
  );
});

const selectedProvider = computed(
  () => route.query.provider || PROVIDER_TYPES.WHATSAPP
);

const showProviderSelection = false;
const showConfiguration = true;

const selectProvider = providerValue => {
  router.push({
    name: route.name,
    params: route.params,
    query: { provider: providerValue },
  });
};

const shouldShowCloudWhatsapp = provider => {
  return (
    provider === PROVIDER_TYPES.WHATSAPP_MANUAL ||
    (provider === PROVIDER_TYPES.WHATSAPP && !hasWhatsappAppId.value)
  );
};

const handleManualLinkClick = () => {
  selectProvider(PROVIDER_TYPES.WHATSAPP_MANUAL);
};
</script>

<template>
  <div class="overflow-auto col-span-6 p-6 w-full h-full">
    <div v-if="showConfiguration">
      <div class="px-6 py-5 rounded-2xl border border-n-weak">
        <!-- Show embedded signup if app ID is configured -->
        <div
          v-if="
            hasWhatsappAppId && selectedProvider === PROVIDER_TYPES.WHATSAPP
          "
        >
          <WhatsappEmbeddedSignup />

          <!-- Manual setup fallback option -->
          <div class="pt-6 mt-6 border-t border-n-weak">
            <I18nT
              keypath="INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.MANUAL_FALLBACK"
              tag="p"
              class="text-sm text-n-slate-11"
            >
              <template #link>
                <a
                  href="#"
                  class="underline text-n-brand"
                  @click.prevent="handleManualLinkClick"
                >
                  {{
                    $t(
                      'INBOX_MGMT.ADD.WHATSAPP.EMBEDDED_SIGNUP.MANUAL_LINK_TEXT'
                    )
                  }}
                </a>
              </template>
            </I18nT>
          </div>
        </div>

        <!-- Show manual setup -->
        <CloudWhatsapp v-else-if="shouldShowCloudWhatsapp(selectedProvider)" />
        <CloudWhatsapp v-else />
      </div>
    </div>
  </div>
</template>
