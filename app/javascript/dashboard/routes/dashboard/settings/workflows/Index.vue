<script>
export default {
  name: 'WorkflowEmbed',
  mounted() {
    window.activepieces.configure({
      prefix: '/',
      instanceUrl: window.chatwootConfig.activepiecesInstanceUrl,
      jwtToken: window.chatwootConfig.activepiecesJwtSecret,
      embedding: {
        containerId: 'workflow-container',
        builder: {
          disableNavigation: true,
          hideLogo: true,
          hideFlowName: true,
        },
        dashboard: {
          hideSidebar: true,
        },
        hideFolders: true,
        navigation: {
          handler: ({ route }) => {
            // The iframe route has changed, make sure you check the navigation section.
            console.log(route);
          },
        },
      },
    });
  },
};
</script>

<template>
  <div class="flex-grow flex-shrink min-w-0 p-6 overflow-auto">
    <div id="workflow-container" />
  </div>
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
