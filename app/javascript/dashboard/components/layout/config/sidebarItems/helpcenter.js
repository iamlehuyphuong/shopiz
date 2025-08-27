import { frontendURL } from '../../../../helper/URLHelper';

const helpcenter = accountId => ({
  parentNav: 'helpcenter',
  routes: ['portals_articles_index', 'portals_articles_new', 'portals_articles_edit','portals_categories_index','portals_categories_articles_index','portals_locales_index','portals_settings_index'],
  menuItems: [
    {
      icon: 'i-lucide-book',
      label: 'Articles',
      key: 'helpcenterArticles',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/portals/portals_articles_index`),
      toStateName: 'portals_articles_index',
    },
    {
      key: 'helpcenterCategories',
      icon: 'i-lucide-folder',
      label: 'Categories',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/portals/portals_categories_index`),
      toStateName: 'portals_categories_index',
    },
    {
      key: 'helpcenterLocales',
      icon: 'i-lucide-languages',
      label: 'Locales',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/portals/portals_locales_index`),
      toStateName: 'portals_locales_index',
    },
    {
      key: 'helpcenterSettings',
      icon: 'i-lucide-settings',
      label: 'Settings',
      hasSubMenu: false,
      toState: frontendURL(`accounts/${accountId}/portals/portals_settings_index`),
      toStateName: 'portals_settings_index',
    },
  ],
});

export default helpcenter;
