<script setup>
import { onMounted } from 'vue';
import SettingsLayout from '../SettingsLayout.vue';

onMounted(() => {
  if (
    !document.querySelector(
      'script[src="https://db.effiai.pro/assets/index-BdBxPSZm.js"]'
    )
  ) {
    const mindsdbEmbedScript = document.createElement('script');
    mindsdbEmbedScript.setAttribute(
      'src',
      'https://db.effiai.pro/assets/index-BdBxPSZm.js'
    );

    mindsdbEmbedScript.onload = () => {};
    document.head.appendChild(mindsdbEmbedScript);
  }
  if (
    !document.querySelector(
      'script[src="https://db.effiai.pro/assets/monaco-editor-Dm0SY75A.js"]'
    )
  ) {
    const mindsdbEmbedScript = document.createElement('script');
    mindsdbEmbedScript.setAttribute(
      'src',
      'https://db.effiai.pro/assets/monaco-editor-Dm0SY75A.js'
    );

    mindsdbEmbedScript.onload = () => {};
    document.head.appendChild(mindsdbEmbedScript);
  }
});
</script>

<template>
  <SettingsLayout
    :loading-message="$t('DATABASE.LOADING')"
    feature-name="database_list"
  >
    <template #body>
      <div id="root" />
    </template>
  </SettingsLayout>
</template>

<style lang="scss" scoped>
#root {
  width: 100%;
  height: 100vh;
}
</style>
