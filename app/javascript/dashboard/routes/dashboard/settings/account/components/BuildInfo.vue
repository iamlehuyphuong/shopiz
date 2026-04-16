<script setup>
import { computed } from 'vue';
import { useAccount } from 'dashboard/composables/useAccount';
import { useMapGetter } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';

import semver from 'semver';

const { t } = useI18n();
const { currentAccount } = useAccount();

const latestChatwootVersion = computed(() => {
  return currentAccount.value.latest_chatwoot_version;
});

const globalConfig = useMapGetter('globalConfig/get');

const hasAnUpdateAvailable = computed(() => {
  if (!semver.valid(latestChatwootVersion.value)) {
    return false;
  }

  return semver.lt(globalConfig.value.appVersion, latestChatwootVersion.value);
});
</script>

<template>
  <div class="p-4 text-sm text-center text-n-slate-11">
    <div v-if="hasAnUpdateAvailable && globalConfig.displayManifest">
      {{
        t('GENERAL_SETTINGS.UPDATE_CHATWOOT', {
          latestChatwootVersion: latestChatwootVersion,
        })
      }}
    </div>
    <div class="flex items-center justify-center divide-x divide-n-slate-9">
      <span class="px-2">{{
        t('GENERAL_SETTINGS.VERSION', { version: globalConfig.appVersion || '1.0.0' })
      }}</span>
      <span v-if="globalConfig.gitSha" class="px-2">
        Commit ID: {{ globalConfig.gitSha.slice(-9) }}
      </span>
    </div>
  </div>
</template>
