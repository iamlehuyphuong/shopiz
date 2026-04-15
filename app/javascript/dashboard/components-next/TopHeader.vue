<script setup>
import { onMounted, onUnmounted, computed, ref, getCurrentInstance } from 'vue';
import { useRouter } from 'vue-router';
import { useKbd } from 'dashboard/composables/utils/useKbd';
import { useI18n } from 'vue-i18n';
import { useStore } from 'vuex';
import { useAccount } from 'dashboard/composables/useAccount';
import { useUISettings } from 'dashboard/composables/useUISettings';

import Logo from 'next/icon/Logo.vue';
import SidebarProfileMenu from './sidebar/SidebarProfileMenu.vue';
import SidebarAccountSwitcher from './sidebar/SidebarAccountSwitcher.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { vOnClickOutside } from '@vueuse/components';

const emit = defineEmits([
  'openKeyShortcutModal',
  'showCreateAccountModal',
  'toggleMobileSidebar',
]);

const instance = getCurrentInstance();
const { t, te, locale } = useI18n();
const searchShortcut = useKbd([`$mod`, '+', 'k']);
const store = useStore();
const router = useRouter();
const { accountScopedRoute, currentAccount } = useAccount();
const { updateUISettings, uiSettings } = useUISettings();

const planName = computed(() => {
  return (
    currentAccount.value?.billing?.current_subscription?.plan_name ||
    currentAccount.value?.custom_attributes?.plan_name
  );
});

const localizedPlanName = computed(() => {
  if (!planName.value) return '';
  const key = `BILLING_SETTINGS.PRICING_PACKAGES.PLANS.${planName.value.toUpperCase()}`;
  return te(key) ? t(key) : planName.value.toUpperCase();
});

const showLanguageDropdownDesktop = ref(false);
const showLanguageDropdownMobile = ref(false);

const isVietnamese = computed({
  get: () => {
    const localeToUse = uiSettings.value?.locale || locale.value || 'en';
    return localeToUse === 'vi';
  },
  set: async (val) => {
    try {
      const newLocale = val ? 'vi' : 'en';
      await store.dispatch('accounts/update', { locale: newLocale });
      await updateUISettings({ locale: newLocale });
      locale.value = newLocale;
      
      const rootProxy = instance?.root?.proxy || instance?.appContext?.config?.globalProperties;
      if (rootProxy && rootProxy.$i18n) {
        rootProxy.$i18n.locale = newLocale;
      }
    } catch {}
  }
});

const languageItems = computed(() => [
  {
    action: 'languageSelect',
    value: 'en',
    label: 'English',
    emoji: '🇬🇧',
    isSelected: !isVietnamese.value,
  },
  {
    action: 'languageSelect',
    value: 'vi',
    label: 'Tiếng Việt',
    emoji: '🇻🇳',
    isSelected: isVietnamese.value,
  }
]);

const handleLanguageAction = (item) => {
  if (item.action === 'languageSelect') {
    isVietnamese.value = item.value === 'vi';
    showLanguageDropdownDesktop.value = false;
    showLanguageDropdownMobile.value = false;
  }
};

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
          class="flex items-center justify-center flex-shrink-0 size-8"
        >
          <Logo class="size-8 text-brand-500" />
        </div>
        <div class="flex-shrink-0 w-px h-5 bg-n-strong mx-2" />
        <SidebarAccountSwitcher
          class="w-[170px] flex-shrink-0"
          @show-create-account-modal="emit('showCreateAccountModal')"
        />
      </div>

      <!-- Search Bar -->
      <div class="hidden md:flex items-center w-[200px]">
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

      <!-- Language Dropdown Desktop -->
      <div v-on-click-outside="() => showLanguageDropdownDesktop = false" class="hidden md:block relative w-[140px]">
        <button
          type="button"
          class="flex items-center justify-between w-full h-8 px-3 rounded-lg outline outline-1 outline-n-weak bg-n-solid-2 hover:bg-n-solid-3 dark:bg-n-black/30 dark:hover:bg-n-black/40 transition-colors"
          @click="showLanguageDropdownDesktop = !showLanguageDropdownDesktop"
        >
          <div class="flex items-center gap-2 overflow-hidden">
            <span class="text-lg leading-none">{{ isVietnamese ? '🇻🇳' : '🇬🇧' }}</span>
            <span class="text-sm truncate pt-0.5 font-medium text-n-slate-12">
              {{ isVietnamese ? 'Tiếng Việt' : 'English' }}
            </span>
          </div>
          <Icon icon="i-lucide-chevron-down" class="size-4 opacity-50 flex-shrink-0" />
        </button>
        <DropdownMenu
          v-if="showLanguageDropdownDesktop"
          :menu-items="languageItems"
          class="top-full mt-1 left-0 w-full"
          @action="handleLanguageAction"
        />
      </div>
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

      <!-- Language Dropdown Mobile -->
      <div v-on-click-outside="() => showLanguageDropdownMobile = false" class="md:hidden relative w-[130px]">
        <button
          type="button"
          class="flex items-center justify-between w-full h-8 px-2 rounded-lg outline outline-1 outline-n-weak bg-n-solid-2 hover:bg-n-solid-3 dark:bg-n-black/30 dark:hover:bg-n-black/40 transition-colors"
          @click="showLanguageDropdownMobile = !showLanguageDropdownMobile"
        >
          <div class="flex items-center gap-2 overflow-hidden">
            <span class="text-lg leading-none">{{ isVietnamese ? '🇻🇳' : '🇬🇧' }}</span>
            <span class="text-sm truncate pt-0.5 font-medium text-n-slate-12">
              {{ isVietnamese ? 'Tiếng Việt' : 'English' }}
            </span>
          </div>
          <Icon icon="i-lucide-chevron-down" class="size-4 opacity-50 flex-shrink-0" />
        </button>
        <DropdownMenu
          v-if="showLanguageDropdownMobile"
          :menu-items="languageItems"
          class="top-full mt-1 right-0 w-full"
          @action="handleLanguageAction"
        />
      </div>

      <RouterLink
        v-if="localizedPlanName"
        :to="accountScopedRoute('billing_settings_index')"
        class="hidden lg:flex items-center px-2 py-0.5 rounded-full bg-n-brand text-[10px] font-bold uppercase tracking-wider text-white hover:opacity-90 transition-opacity whitespace-nowrap shadow-sm"
      >
        {{ localizedPlanName }}
      </RouterLink>

      <div
        v-if="localizedPlanName"
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
