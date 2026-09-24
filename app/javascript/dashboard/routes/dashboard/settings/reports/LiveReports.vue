<script setup>
import { computed } from 'vue';
import { useRoute } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store.js';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

const route = useRoute();
const isFeatureEnabledonAccount = useMapGetter(
  'accounts/isFeatureEnabledonAccount'
);
const isTeamManagementEnabled = computed(() =>
  isFeatureEnabledonAccount.value(
    route.params.accountId,
    FEATURE_FLAGS.TEAM_MANAGEMENT
  )
);
import ReportHeader from './components/ReportHeader.vue';
import ConversationHeatmapContainer from './components/heatmaps/ConversationHeatmapContainer.vue';
import ResolutionHeatmapContainer from './components/heatmaps/ResolutionHeatmapContainer.vue';
import AgentLiveReportContainer from './components/AgentLiveReportContainer.vue';
import TeamLiveReportContainer from './components/TeamLiveReportContainer.vue';
import StatsLiveReportsContainer from './components/StatsLiveReportsContainer.vue';
</script>

<template>
  <ReportHeader :header-title="$t('OVERVIEW_REPORTS.HEADER')" />
  <div class="flex flex-col gap-4 pb-6">
    <StatsLiveReportsContainer />
    <ConversationHeatmapContainer />
    <ResolutionHeatmapContainer />
    <AgentLiveReportContainer />
    <TeamLiveReportContainer v-if="isTeamManagementEnabled" />
  </div>
</template>
