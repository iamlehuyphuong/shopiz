<script>
import SnackbarContainer from './components/SnackBar/Container.vue';

export default {
  components: { SnackbarContainer },
  data() {
    return { theme: 'light' };
  },
  mounted() {
    this.setColorTheme();
    this.listenToThemeChanges();
    let locale = window.shopizConfig.selectedLocale;
    if (locale === 'en') {
      const browserLocale = navigator.language || navigator.userLanguage;
      if (browserLocale.startsWith('vi')) {
        locale = 'vi';
      }
    }
    this.setLocale(locale);
  },
  methods: {
    setColorTheme() {
      this.theme = 'light';
      document.documentElement.classList.remove('dark');
    },
    listenToThemeChanges() {
      // Disabled to force light theme
    },
    setLocale(locale) {
      this.$root.$i18n.locale = locale;
    },
  },
};
</script>

<template>
  <div class="h-full min-h-screen w-full antialiased" :class="theme">
    <router-view />
    <SnackbarContainer />
  </div>
</template>

<style lang="scss">
@tailwind base;
@tailwind components;
@tailwind utilities;

@import '../dashboard/assets/scss/next-colors';

html,
body {
  font-family:
    'Nunito Sans',
    -apple-system,
    BlinkMacSystemFont,
    'Segoe UI',
    Roboto,
    'Oxygen-Sans',
    'Ubuntu',
    'Cantarell',
    'Helvetica Neue',
    sans-serif;
  @apply h-full w-full;

  input,
  select {
    outline: none;
  }
}

.text-link {
  @apply font-medium;
  color: #e06720;
  &:hover {
    color: rgb(var(--orange-10));
  }
}

.v-popper--theme-tooltip .v-popper__inner {
  background: black !important;
  font-size: 0.75rem;
  padding: 4px 8px !important;
  border-radius: 6px;
  font-weight: 400;
}

.v-popper--theme-tooltip .v-popper__arrow-container {
  display: none;
}
</style>
