<script setup>
import { computed } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAdmin } from 'dashboard/composables/useAdmin';
import ButtonV4 from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const store = useStore();
const { accountScopedUrl } = useAccount();
const { isAdmin } = useAdmin();

const limitationModal = useMapGetter('accounts/getUIFlags');
const show = computed(() => limitationModal.value?.limitationModal?.show);
const resourceKey = computed(
  () => limitationModal.value?.limitationModal?.resourceKey
);

const translationKey = computed(() => {
  if (!resourceKey.value) return '';
  return resourceKey.value.toUpperCase();
});

const onClose = () => {
  store.dispatch('accounts/toggleLimitationModal', {
    show: false,
    resourceKey: '',
  });
};

const onClickUpgrade = () => {
  onClose();
  window.location.href = accountScopedUrl('settings/billing');
};
</script>

<template>
  <woot-modal :show="show" :on-close="onClose" size="small">
    <div class="flex flex-col gap-6 p-8">
      <div class="flex items-center gap-4">
        <div
          class="flex items-center justify-center size-10 rounded-full bg-n-solid-blue/20 shrink-0"
        >
          <Icon icon="i-lucide-lock-keyhole" class="size-4 text-n-brand" />
        </div>
        <h3 class="text-lg font-bold text-n-slate-12">
          {{ $t('LIMITATION.MODAL.TITLE') }}
        </h3>
      </div>
      <div class="flex flex-col gap-2">
        <p class="text-sm text-n-slate-11 leading-relaxed">
          {{ $t(`LIMITATION.MODAL.DESCRIPTION.${translationKey}`) }}
        </p>
        <p v-if="!isAdmin" class="mt-2 text-sm text-n-slate-11 italic">
          {{ $t('GENERAL_SETTINGS.LIMIT_MESSAGES.NON_ADMIN') }}
        </p>
      </div>
      <div class="flex w-full mt-2">
        <ButtonV4
          v-if="isAdmin"
          solid
          blue
          md
          icon="i-lucide-credit-card"
          class="flex-1"
          @click="onClickUpgrade"
        >
          {{ $t('LIMITATION.MODAL.UPGRADE_BUTTON') }}
        </ButtonV4>
      </div>
    </div>
  </woot-modal>
</template>
