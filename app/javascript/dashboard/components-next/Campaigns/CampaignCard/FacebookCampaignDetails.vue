<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { messageStamp } from 'shared/helpers/timeHelper';

import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

const props = defineProps({
  sender: {
    type: Object,
    default: null,
  },
  inboxName: {
    type: String,
    default: '',
  },
  inboxIcon: {
    type: String,
    default: '',
  },
  campaign: {
    type: Object,
    default: () => ({}),
  },
  scheduledAt: {
    type: Number,
    default: 0,
  },
});

const { t } = useI18n();

const senderName = computed(
  () => props.sender?.name || t('CAMPAIGN.FACEBOOK.CARD.CAMPAIGN_DETAILS.BOT')
);

const senderThumbnail = computed(() => props.sender?.thumbnail || '');

const metrics = computed(() => props.campaign?.campaign_metrics || {});
const hasMetrics = computed(() => Object.keys(metrics.value).length > 0);
const isCompleted = computed(
  () => props.campaign?.campaign_status === 'completed'
);
</script>

<template>
  <div class="flex items-center gap-2 w-full overflow-hidden">
    <span class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap">
      {{ t('CAMPAIGN.FACEBOOK.CARD.CAMPAIGN_DETAILS.SENT_BY') }}
    </span>
    <div class="flex items-center gap-1.5 flex-shrink-0">
      <Avatar :name="senderName" :src="senderThumbnail" :size="16" branded />
      <span class="text-sm font-medium text-n-slate-12">
        {{ senderName }}
      </span>
    </div>
    <span class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap">
      {{ t('CAMPAIGN.FACEBOOK.CARD.CAMPAIGN_DETAILS.SENT_FROM') }}
    </span>
    <div class="flex items-center gap-1.5 flex-shrink-0">
      <Icon :icon="inboxIcon" class="flex-shrink-0 text-n-slate-12 size-3" />
      <span class="text-sm font-medium text-n-slate-12">
        {{ inboxName }}
      </span>
    </div>
    <span class="flex-shrink-0 text-sm text-n-slate-11 whitespace-nowrap">
      {{ t('CAMPAIGN.FACEBOOK.CARD.CAMPAIGN_DETAILS.ON') }}
    </span>
    <span class="flex-shrink-0 text-sm font-medium text-n-slate-12">
      {{
        messageStamp(
          new Date(scheduledAt),
          t('GENERAL.DATETIME_FORMAT_WITH_SHORT_MONTH')
        )
      }}
    </span>
    <!-- Campaign Metrics -->
    <template v-if="isCompleted && hasMetrics">
      <span class="text-n-slate-7 mx-1">|</span>
      <div class="flex items-center gap-3 flex-shrink-0">
        <span class="text-xs text-n-slate-11">
          {{ t('CAMPAIGN.FACEBOOK.CARD.METRICS.TOTAL_SENT') }}:
          <strong class="text-n-slate-12">{{ metrics.total_sent || 0 }}</strong>
        </span>
        <span class="text-xs text-n-teal-11">
          {{ t('CAMPAIGN.FACEBOOK.CARD.METRICS.DELIVERED') }}:
          <strong>{{ metrics.delivered || 0 }}</strong>
        </span>
        <span class="text-xs text-n-ruby-11">
          {{ t('CAMPAIGN.FACEBOOK.CARD.METRICS.FAILED') }}:
          <strong>{{ metrics.failed || 0 }}</strong>
        </span>
        <span class="text-xs text-n-slate-11">
          {{ t('CAMPAIGN.FACEBOOK.CARD.METRICS.DELIVERY_RATE') }}:
          <strong class="text-n-teal-11">
            {{ campaign.delivery_rate || 0 }}%
          </strong>
        </span>
      </div>
    </template>
  </div>
</template>
