<script setup>
import { SURVEY_CAMPAIGN_EMPTY_STATE_CONTENT } from './CampaignEmptyStateContent';
import { useI18n } from 'vue-i18n';

import EmptyStateLayout from './CustomEmptyStateLayout.vue';
import CampaignCard from 'dashboard/components-next/Campaigns/CampaignCard/CampaignCard.vue';

defineProps({
  title: {
    type: String,
    default: '',
  },
  subtitle: {
    type: String,
    default: '',
  },
});

const { t } = useI18n();
</script>

<template>
  <EmptyStateLayout :title="title" :subtitle="subtitle">
    <template #empty-state-item>
      <div class="flex flex-col gap-4 p-px">
        <div
          v-for="(campaign, index) in SURVEY_CAMPAIGN_EMPTY_STATE_CONTENT"
          :key="campaign.id"
          :style="{
            opacity: index === 0 ? 1 : index === 1 ? 0.7 : index === 2 ? 0.4 : 0.2
          }"
        >
          <CampaignCard
            :title="$t(campaign.title)"
            :message="$t(campaign.message)"
            :is-enabled="campaign.enabled"
            :status="campaign.campaign_status"
            :sender="campaign.sender"
            :inbox="campaign.inbox"
            :scheduled-at="campaign.scheduled_at"
            :is-voice-type="true"
          />
        </div>
      </div>
    </template>
  </EmptyStateLayout>
</template>
