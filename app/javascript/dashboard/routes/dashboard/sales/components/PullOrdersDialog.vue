<script setup>
import { ref, onMounted } from 'vue';
import { useStore } from 'vuex';
import NextButton from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits(['close', 'sync']);

const store = useStore();

const platforms = [
  { id: 'kiotviet', name: 'KiotViet', logo: 'kiotviet' },
  { id: 'sapo', name: 'Sapo', logo: 'sapo' },
  { id: 'haravan', name: 'Haravan', logo: 'haravan' },
  { id: 'shopify', name: 'Shopify', logo: 'shopify' },
  { id: 'woocommerce', name: 'WooCommerce', logo: 'woocommerce' },
  { id: 'nhanhvn', name: 'Nhanh.vn', logo: 'nhanhvn' },
];

const selectedPlatform = ref(null);

const onImageError = e => {
  e.target.style.display = 'none';
};

const selectPlatform = platform => {
  selectedPlatform.value = platform.id;
};

const isPlatformConnected = platformId => {
  if (platformId === 'tiktok_shop') {
    const inboxes = store.getters['inboxes/getInboxes'] || [];
    return inboxes.some(inbox => inbox.channel_type === 'Channel::TiktokShop');
  }
  const integration = store.getters['integrations/getIntegration'](platformId);
  return integration && integration.hooks && integration.hooks.length > 0;
};

onMounted(() => {
  store.dispatch('integrations/get');
});

const onSync = () => {
  if (selectedPlatform.value) {
    emit('sync', selectedPlatform.value);
  }
};

const onClose = () => {
  selectedPlatform.value = null;
  emit('close');
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="$t('SALES.DIALOG_PULL_ORDERS.TITLE')"
      :header-content="$t('SALES.DIALOG_PULL_ORDERS.DESC')"
    />
    <div class="flex flex-col w-full mt-4">
      <div class="w-full px-8 pb-4">
        <div class="grid grid-cols-2 gap-3">
          <button
            v-for="platform in platforms"
            :key="platform.id"
            type="button"
            class="flex items-center gap-3 p-4 rounded-xl border transition-all duration-200 text-left relative"
            :class="[
              selectedPlatform === platform.id
                ? 'border-n-brand bg-n-brand/5 ring-1 ring-n-brand'
                : 'border-n-slate-6 bg-white dark:bg-n-solid-1 hover:border-n-slate-8',
              !isPlatformConnected(platform.id)
                ? '!opacity-50 cursor-not-allowed !border-n-weak hover:!border-n-weak !bg-n-alpha-1'
                : '',
            ]"
            :disabled="!isPlatformConnected(platform.id)"
            @click="selectPlatform(platform)"
          >
            <div
              class="flex h-9 w-9 items-center justify-center rounded-lg bg-white dark:bg-n-solid-2 border border-n-strong/20 shadow-sm overflow-hidden flex-shrink-0"
            >
              <img
                :src="`/dashboard/images/integrations/${platform.logo}.png`"
                class="h-6 w-6 object-contain block dark:hidden"
                :alt="platform.name"
                @error="onImageError"
              />
              <img
                :src="`/dashboard/images/integrations/${platform.logo}-dark.png`"
                class="h-6 w-6 object-contain hidden dark:block"
                :alt="platform.name"
                @error="onImageError"
              />
            </div>
            <span class="text-sm font-medium text-n-slate-12">
              {{ platform.name }}
            </span>
          </button>
        </div>
      </div>
      <div
        class="flex items-center justify-end w-full gap-2 px-8 py-4 border-t border-n-strong/10 bg-n-alpha-1/50"
      >
        <NextButton
          faded
          slate
          :label="$t('SALES.DIALOG_PULL_ORDERS.FORM.CANCEL')"
          @click="onClose"
        />
        <NextButton
          :label="$t('SALES.DIALOG_PULL_ORDERS.FORM.SUBMIT')"
          :disabled="!selectedPlatform"
          @click="onSync"
        />
      </div>
    </div>
  </div>
</template>
