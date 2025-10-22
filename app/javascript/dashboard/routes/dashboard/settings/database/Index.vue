<script setup>
import SettingsLayout from '../SettingsLayout.vue';
import { frontendURL } from 'dashboard/helper/URLHelper';
import { onMounted } from 'vue';
import { useRouter } from 'vue-router';

onMounted(() => {
  const router = useRouter();
  const { accountId } = router.currentRoute.value.params;
  if (!document.querySelector('script[src="https://db.effiai.pro/assets/index-BdBxPSZm.js"]')) {
    const mindsdbEmbedScript = document.createElement("script");
    mindsdbEmbedScript.setAttribute(
      "src",
      "https://db.effiai.pro/assets/index-BdBxPSZm.js"
    );

    mindsdbEmbedScript.onload = () => {

    };
    document.head.appendChild(mindsdbEmbedScript);
  }
  if (!document.querySelector('script[src="https://db.effiai.pro/assets/monaco-editor-Dm0SY75A.js"]')) {
    const mindsdbEmbedScript = document.createElement("script");
    mindsdbEmbedScript.setAttribute(
      "src",
      "https://db.effiai.pro/assets/monaco-editor-Dm0SY75A.js"
    );

    mindsdbEmbedScript.onload = () => {

    };
    document.head.appendChild(mindsdbEmbedScript);
  }
});
</script>

<template>
  <SettingsLayout
    :loading-message="$t('WORKFLOWS.LOADING')"
    feature-name="database_list"
  >
    <template #body>
      <div id="root"></div>
    </template>
  </SettingsLayout>
</template>

<style lang="scss" scoped>
#root {
  width: 100%;
  height: 100vh;
}
</style>
