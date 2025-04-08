<script>
import { OnClickOutside } from '@vueuse/components';
import { HELP_CENTER_MENU_ITEMS } from 'dashboard/helper/portalHelper';

import DropdownMenu from 'dashboard/components-next/dropdown-menu/DropdownMenu.vue';
import ConversationsIcon from 'components/layout/sidebarComponents/icons/ConversationsIcon.vue';
import ContactIcon from 'components/layout/sidebarComponents/icons/ContactIcon.vue';

export default {
  components: {
    ContactIcon,
    ConversationsIcon,
    DropdownMenu,
    OnClickOutside,
  },
  props: {
    to: {
      type: String,
      default: '',
    },
    id: {
      type: String,
      default: '',
    },
    name: {
      type: String,
      default: '',
    },
    icon: {
      type: [String, Object],
      default: '',
    },
    count: {
      type: String,
      default: '',
    },
    isChildMenuActive: {
      type: Boolean,
      default: false,
    },
    openInNewPage: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      helpCenterMenu: HELP_CENTER_MENU_ITEMS,
      showHelpCenterMenu: false,
    };
  },
  computed: {
    helpCenterMenuItems() {
      return this.helpCenterMenu.map(item => ({
        ...item,
        isSelected: this.isSelectedMenuItem(item),
      }));
    },
    isHelpCenter() {
      return this.id === 'helpcenter';
    },

    isHelpCenterSelected() {
      const routes = [
        'portals_new',
        'portals_index',
        'portals_articles_index',
        'portals_articles_new',
        'portals_articles_edit',
        'portals_categories_index',
        'portals_categories_articles_index',
        'portals_categories_articles_edit',
        'portals_locales_index',
        'portals_settings_index',
      ];
      return routes.includes(this.$route.name);
    },
  },
  methods: {
    isSelectedMenuItem(menuItem) {
      return menuItem.value.includes(this.$route.name);
    },
    toggleHelpCenterMenu() {
      this.showHelpCenterMenu = !this.showHelpCenterMenu;
    },
    handleHelpCenterAction({ action }) {
      this.$router.push({
        name: 'portals_index',
        params: {
          navigationPath: action,
        },
      });
    },
  },
};
</script>

<template>
  <OnClickOutside
    v-if="isHelpCenter"
    class="flex flex-col justify-center items-center my-1"
    @trigger="showHelpCenterMenu = false"
  >
    <button
      class="relative flex items-center justify-center w-10 h-10 hover:bg-[#793B40] rounded-lg text-white dark:text-slate-100"
      :class="{
        'bg-[#793B40]': isHelpCenterSelected,
      }"
      @click="toggleHelpCenterMenu"
      v-tooltip.bottom-start="$t(`SIDEBAR.${name}`)"
    >
      <component :is="icon" v-if="typeof icon === 'object'" :active="isHelpCenterSelected" />
      <fluent-icon v-else :icon="icon" />

      <DropdownMenu
        v-if="showHelpCenterMenu && isHelpCenter"
        :menu-items="helpCenterMenuItems"
        class="ltr:left-10 rtl:right-10 w-36 z-[100] top-0 overflow-y-auto max-h-52"
        @action="handleHelpCenterAction"
      />
    </button>
    <span
      class="font-inter inline-block text-white font-medium text-[0.625rem] text-center mt-[0.2rem] overflow-hidden text-ellipsis whitespace-nowrap max-w-[80px] px-2 w-full"
    >
      {{ $t(`SIDEBAR.${name}`) }}
    </span>
  </OnClickOutside>

  <router-link v-else v-slot="{ href, isActive, navigate }" :to="to" custom>
    <a
      v-tooltip.bottom-start="$t(`SIDEBAR.${name}`)"
      :href="href"
      class="relative flex items-center justify-center w-10 h-10 rounded-lg text-white hover:bg-[#793B40] dark:text-slate-100 mt-1"
      :class="{
        'bg-[#793B40]': isActive || isChildMenuActive,
      }"
      :rel="openInNewPage ? 'noopener noreferrer nofollow' : undefined"
      :target="openInNewPage ? '_blank' : undefined"
      @click="navigate"
    >
      <component :is="icon" v-if="typeof icon === 'object'" :active="isActive || isChildMenuActive" />
      <fluent-icon v-else :icon="icon" />

      <span class="sr-only">{{ name }}</span>
      <span
        v-if="count"
        class="absolute bg-yellow-500 text-black-900 -top-1 -right-1"
      >
        {{ count }}
      </span>
    </a>
    <span
      class="font-inter inline-block text-white font-medium text-[0.625rem] text-center mt-[0.2rem] mb-2 overflow-hidden text-ellipsis whitespace-nowrap max-w-[80px] px-2 w-full"
    >
      {{ $t(`SIDEBAR.${name}`) }}
    </span>
  </router-link>
</template>
