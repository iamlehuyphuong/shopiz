<script setup>
import { computed } from 'vue';
import { useRouter } from 'vue-router';
import { useAccount } from 'dashboard/composables/useAccount';
import Icon from 'next/icon/Icon.vue';
import ChannelIcon from 'next/icon/ChannelIcon.vue';

const props = defineProps({
  label: {
    type: String,
    required: true,
  },
  // eslint-disable-next-line vue/no-unused-properties
  active: {
    type: Boolean,
    default: false,
  },
  inbox: {
    type: Object,
    required: true,
  },
});

const router = useRouter();
const { accountScopedRoute } = useAccount();

const reauthorizationRequired = computed(() => {
  return props.inbox.reauthorization_required;
});

const navigateToSettings = () => {
  router.push(
    accountScopedRoute('settings_inbox_show', { inboxId: props.inbox.id })
  );
};
</script>

<template>
  <span class="size-4 grid place-content-center rounded-full">
    <ChannelIcon :inbox="inbox" class="size-4" />
  </span>
  <div class="flex-1 truncate min-w-0">{{ label }}</div>
  <div
    v-if="reauthorizationRequired"
    v-tooltip.top-end="$t('SIDEBAR.REAUTHORIZE')"
    class="grid place-content-center size-5 bg-n-ruby-5/60 rounded-full cursor-pointer hover:bg-n-ruby-6/60 transition-colors"
    @click.prevent.stop="navigateToSettings"
  >
    <Icon icon="i-woot-alert" class="size-3 text-n-ruby-9" />
  </div>
</template>
