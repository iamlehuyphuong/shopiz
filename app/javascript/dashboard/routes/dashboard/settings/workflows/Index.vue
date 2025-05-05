<script setup>
import SettingsLayout from '../SettingsLayout.vue';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { onMounted } from 'vue';
import { useRouter } from 'vue-router';
onMounted(() => {
  const router = useRouter();
  const { accountId } = router.currentRoute.value.params;
  window.addEventListener('popstate', () => {
    const route = window.activepieces.extractActivepiecesRouteFromUrl({
      vendorUrl: window.location.href,
    });
    window.activepieces.navigate({ route });
  });
  window.addEventListener('load', () => {
    const route = window.activepieces.extractActivepiecesRouteFromUrl({
      vendorUrl: window.location.href,
    });
    window.activepieces.navigate({ route });
  });
  window.activepieces.configure({
    prefix: frontendURL(`accounts/${accountId}/settings/agent-bots`),
    instanceUrl: window.salesmanConfig.activepiecesInstanceUrl,
    jwtToken: window.salesmanConfig.activepiecesJwtSecret,
    embedding: {
      containerId: 'workflow-container',
      builder: {
        disableNavigation: false,
        hideLogo: true,
        hideFlowName: false,
      },
      dashboard: {
        hideSidebar: true,
      },
      hideFolders: false,
      navigation: {
        handler: ({ route }) => {
          // The iframe route has changed, make sure you check the navigation section.
          // console.log('Route changed to: ', frontendURL(`accounts/${accountId}/settings${route}`));
          // console.log(route);
          // route can include search params at the end of it
          if (!window.location.href.endsWith(route)) {
            window.history.pushState({}, '', window.location.origin + route);
          }
          // router.replace(route);
        },
      },
    },
  });
});
</script>

<template>
  <SettingsLayout
    :loading-message="$t('WORKFLOWS.LOADING')"
    feature-name="workflow_list"
  >
    <template #body>
      <div id="workflow-container" />
    </template>
  </SettingsLayout>
</template>

<style lang="scss" scoped>
#workflow-container {
  width: 100%;
  height: 100vh;
}
#workflow-container :deep(iframe) {
  width: 100%;
  height: 100vh;
}
</style>
