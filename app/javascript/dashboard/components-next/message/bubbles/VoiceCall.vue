<script setup>
import { computed } from 'vue';
import { useMessageContext } from '../provider.js';
import { MESSAGE_TYPES, VOICE_CALL_STATUS } from '../constants';

import Icon from 'dashboard/components-next/icon/Icon.vue';
import BaseBubble from 'next/message/bubbles/Base.vue';

const LABEL_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'CALL_IN_PROGRESS',
  [VOICE_CALL_STATUS.COMPLETED]: 'CALL_ENDED',
};

const SUBTEXT_MAP = {
  [VOICE_CALL_STATUS.RINGING]: 'NOT_ANSWERED_YET',
  [VOICE_CALL_STATUS.COMPLETED]: 'CALL_ENDED',
};

const ICON_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'i-ph-phone-call',
  [VOICE_CALL_STATUS.NO_ANSWER]: 'i-ph-phone-x',
  [VOICE_CALL_STATUS.FAILED]: 'i-ph-phone-x',
};

const VIDEO_ICON_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'i-ph-video-camera',
  [VOICE_CALL_STATUS.NO_ANSWER]: 'i-ph-video-camera-slash',
  [VOICE_CALL_STATUS.FAILED]: 'i-ph-video-camera-slash',
};

const BG_COLOR_MAP = {
  [VOICE_CALL_STATUS.IN_PROGRESS]: 'bg-n-teal-9',
  [VOICE_CALL_STATUS.RINGING]: 'bg-n-teal-9 animate-pulse',
  [VOICE_CALL_STATUS.COMPLETED]: 'bg-n-slate-11',
  [VOICE_CALL_STATUS.NO_ANSWER]: 'bg-n-ruby-9',
  [VOICE_CALL_STATUS.FAILED]: 'bg-n-ruby-9',
};

const { contentAttributes, messageType } = useMessageContext();

const data = computed(() => contentAttributes.value?.data);
const status = computed(() => data.value?.status?.toString());
const duration = computed(() => data.value?.duration || 0);
const isVideo = computed(() => data.value?.callType === 'video');
const baseKey = computed(() =>
  isVideo.value ? 'CONVERSATION.VIDEO_CALL' : 'CONVERSATION.VOICE_CALL'
);

const formattedDuration = computed(() => {
  if (!duration.value) return '';
  const m = Math.floor(duration.value / 60);
  const s = duration.value % 60;
  if (m > 0) return `${m} phút ${s} giây`;
  return `${s} giây`;
});

const isOutbound = computed(() => messageType.value === MESSAGE_TYPES.OUTGOING);
const isFailed = computed(() =>
  [VOICE_CALL_STATUS.NO_ANSWER, VOICE_CALL_STATUS.FAILED].includes(status.value)
);

const labelKey = computed(() => {
  if (LABEL_MAP[status.value])
    return `${baseKey.value}.${LABEL_MAP[status.value]}`;
  if (status.value === VOICE_CALL_STATUS.RINGING) {
    return isOutbound.value
      ? `${baseKey.value}.OUTGOING_CALL`
      : `${baseKey.value}.INCOMING_CALL`;
  }
  return isFailed.value
    ? `${baseKey.value}.MISSED_CALL`
    : `${baseKey.value}.INCOMING_CALL`;
});

const subtextKey = computed(() => {
  if (SUBTEXT_MAP[status.value])
    return `${baseKey.value}.${SUBTEXT_MAP[status.value]}`;
  if (status.value === VOICE_CALL_STATUS.IN_PROGRESS) {
    return isOutbound.value
      ? `${baseKey.value}.THEY_ANSWERED`
      : `${baseKey.value}.YOU_ANSWERED`;
  }
  return isFailed.value
    ? `${baseKey.value}.NO_ANSWER`
    : `${baseKey.value}.NOT_ANSWERED_YET`;
});

const iconName = computed(() => {
  if (isVideo.value) {
    if (VIDEO_ICON_MAP[status.value]) return VIDEO_ICON_MAP[status.value];
    return 'i-ph-video-camera';
  }
  if (ICON_MAP[status.value]) return ICON_MAP[status.value];
  return isOutbound.value ? 'i-ph-phone-outgoing' : 'i-ph-phone-incoming';
});

const bgColor = computed(() => BG_COLOR_MAP[status.value] || 'bg-n-teal-9');
</script>

<template>
  <BaseBubble class="p-0 border-none" hide-meta>
    <div class="flex overflow-hidden flex-col w-full max-w-xs">
      <div class="flex gap-3 items-center p-3 w-full">
        <div
          class="flex justify-center items-center rounded-full size-10 shrink-0"
          :class="bgColor"
        >
          <Icon
            class="size-5"
            :icon="iconName"
            :class="{
              'text-n-slate-1': status === VOICE_CALL_STATUS.COMPLETED,
              'text-white': status !== VOICE_CALL_STATUS.COMPLETED,
            }"
          />
        </div>

        <div class="flex overflow-hidden flex-col flex-grow">
          <span class="text-sm font-medium truncate text-n-slate-12">
            {{ $t(labelKey) }}
          </span>
          <span class="text-xs text-n-slate-11">
            <template
              v-if="status === VOICE_CALL_STATUS.COMPLETED && duration > 0"
            >
              {{ formattedDuration }}
            </template>
            <template v-else>
              {{ $t(subtextKey) }}
            </template>
          </span>
        </div>
      </div>
    </div>
  </BaseBubble>
</template>
