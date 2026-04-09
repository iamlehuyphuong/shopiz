<script setup>
import { onMounted, onUnmounted, computed } from 'vue';
import { useRouter } from 'vue-router';
import { useKbd } from 'dashboard/composables/utils/useKbd';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';

import Logo from 'next/icon/Logo.vue';
import SidebarProfileMenu from './sidebar/SidebarProfileMenu.vue';
import SidebarAccountSwitcher from './sidebar/SidebarAccountSwitcher.vue';
import ComposeConversation from 'dashboard/components-next/NewConversation/ComposeConversation.vue';
import Button from 'dashboard/components-next/button/Button.vue';

const emit = defineEmits([
  'openKeyShortcutModal',
  'showCreateAccountModal',
  'toggleMobileSidebar',
]);

const { t } = useI18n();
const searchShortcut = useKbd([`$mod`, 'k']);
const store = useStore();
const router = useRouter();
const { accountScopedRoute, currentAccount } = useAccount();

const planName = computed(() => {
  return (
    currentAccount.value?.billing?.current_subscription?.plan_name ||
    currentAccount.value?.custom_attributes?.plan_name
  );
});

const handleKeyDown = e => {
  if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
    e.preventDefault();
    router.push(accountScopedRoute('search'));
  }
};

// We need to fetch inboxes if they are not loaded
onMounted(() => {
  store.dispatch('inboxes/get');
  window.addEventListener('keydown', handleKeyDown);
});

onUnmounted(() => {
  window.removeEventListener('keydown', handleKeyDown);
});
</script>

<template>
  <header
    class="flex items-center justify-between px-4 py-2 bg-n-solid-1 border-b border-n-weak w-full z-50 h-14"
  >
    <!-- Left Section: Mobile Toggle, Logo, Workspace, Search, Compose -->
    <div class="flex items-center flex-1 gap-4">
      <Button
        icon="i-lucide-menu"
        color="slate"
        variant="ghost"
        size="sm"
        class="md:hidden !text-n-slate-11"
        @click="emit('toggleMobileSidebar')"
      />
      <!-- Logo + Workspace Switcher -->
      <div class="flex items-center gap-2">
        <div
          class="grid flex-shrink-0 place-content-center size-8 bg-brand-500 rounded-lg shadow-sm"
        >
          <Logo class="size-5 text-white" />
        </div>
        <div class="flex-shrink-0 w-px h-5 bg-n-strong mx-2" />
        <SidebarAccountSwitcher
          class="w-[170px] flex-shrink-0"
          @show-create-account-modal="emit('showCreateAccountModal')"
        />
      </div>

      <!-- Search Bar -->
      <div class="hidden md:flex items-center w-[240px]">
        <RouterLink
          :to="accountScopedRoute('search')"
          class="flex gap-2 items-center px-3 py-1.5 w-full h-8 rounded-lg outline outline-1 outline-n-weak bg-n-solid-2 hover:bg-n-solid-3 dark:bg-n-black/30 dark:hover:bg-n-black/40 transition-colors"
        >
          <span class="flex-shrink-0 i-lucide-search size-4 text-n-slate-11" />
          <span class="flex-grow text-left text-n-slate-11 text-sm truncate">
            {{ t('COMBOBOX.SEARCH_PLACEHOLDER') }}
          </span>
          <span
            class="hidden md:block tracking-wide flex-shrink-0 pointer-events-none select-none text-n-slate-9 text-xs"
          >
            {{ searchShortcut }}
          </span>
        </RouterLink>
      </div>

      <!-- Compose Conversation -->
      <ComposeConversation is-modal class="hidden md:block">
        <template #trigger="{ toggle }">
          <Button
            icon="i-lucide-plus"
            label="Thêm Mới"
            color="blue"
            size="sm"
            class="!h-8 font-medium shadow-sm flex-shrink-0"
            @click="toggle"
          >
            {{ t('HOME.START_CONVERSATION') }}
          </Button>
        </template>
      </ComposeConversation>
    </div>

    <!-- Right Section: Mobile actions, Profile Menu -->
    <div class="flex items-center gap-3 flex-shrink-0">
      <!-- Mobile Search Icon -->
      <RouterLink
        :to="accountScopedRoute('search')"
        class="md:hidden flex items-center justify-center size-8 rounded-lg hover:bg-n-solid-3 text-n-slate-11"
      >
        <span class="i-lucide-search size-5" />
      </RouterLink>

      <!-- Mobile Compose Icon -->
      <ComposeConversation is-modal class="md:hidden">
        <template #trigger="{ toggle }">
          <Button
            icon="i-lucide-plus"
            color="blue"
            variant="ghost"
            size="sm"
            class="!text-n-slate-11 !h-8 w-8 !p-0"
            @click="toggle"
          />
        </template>
      </ComposeConversation>

      <RouterLink
        v-if="planName"
        :to="accountScopedRoute('billing_settings_index')"
        class="hidden lg:flex items-center px-2 py-0.5 rounded-full bg-n-brand text-[10px] font-bold uppercase tracking-wider text-white hover:opacity-90 transition-opacity whitespace-nowrap shadow-sm"
      >
        {{ planName }}
      </RouterLink>

      <div
        v-if="planName"
        class="flex-shrink-0 w-px h-5 bg-n-strong mx-1 hidden lg:block"
      />

      <SidebarProfileMenu
        position="top"
        @open-key-shortcut-modal="emit('openKeyShortcutModal')"
      />
    </div>
  </header>
</template>

<style scoped>
/* Optional specific overrides */
</style>
