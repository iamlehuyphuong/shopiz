<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import UpgradePage from '../components/UpgradePage.vue';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const route = useRoute();
const store = useStore();
const { uiSettings, updateUISettings } = useUISettings();

const isReady = ref(false);

const accountId = computed(() => store.getters.getCurrentAccountId);
const portals = computed(() => store.getters['portals/allPortals']);
const isFeatureEnabledonAccount = (id, flag) =>
  store.getters['accounts/isFeatureEnabledonAccount'](id, flag);

const isHelpCenterEnabled = computed(() =>
  isFeatureEnabledonAccount(accountId.value, FEATURE_FLAGS.HELP_CENTER)
);

const selectedPortal = computed(() => {
  const slug =
    route.params.portalSlug || uiSettings.value.last_active_portal_slug;
  if (slug) return store.getters['portals/portalBySlug'](slug);
  return portals.value[0];
});

const defaultPortalLocale = computed(() =>
  selectedPortal.value ? selectedPortal.value.meta?.default_locale : ''
);
const selectedLocaleInPortal = computed(
  () => route.params.locale || defaultPortalLocale.value
);

const selectedPortalSlug = computed(() =>
  selectedPortal.value ? selectedPortal.value.slug : ''
);

const fetchPortalAndItsCategories = async () => {
  await store.dispatch('portals/index');
  const selectedPortalParam = {
    portalSlug: selectedPortalSlug.value,
    locale: selectedLocaleInPortal.value,
  };
  await Promise.all([
    store.dispatch('portals/show', selectedPortalParam),
    store.dispatch('categories/index', selectedPortalParam),
    store.dispatch('agents/get'),
  ]);
  isReady.value = true;
};

onMounted(() => fetchPortalAndItsCategories());

watch(
  () => route.params.portalSlug,
  newSlug => {
    if (newSlug && newSlug !== uiSettings.value.last_active_portal_slug) {
      updateUISettings({
        last_active_portal_slug: newSlug,
        last_active_locale_code: selectedLocaleInPortal.value,
      });
    }
  }
);
</script>

<template>
  <div class="flex w-full h-full min-h-0">
    <section
      v-if="isHelpCenterEnabled"
      class="flex flex-1 h-full px-0 overflow-hidden bg-n-surface-1"
    >
      <div
        v-if="!isReady"
        class="flex items-center justify-center w-full h-full text-n-slate-11"
      >
        <Spinner />
      </div>
      <router-view v-else />
    </section>
    <UpgradePage v-else />
  </div>
</template>
