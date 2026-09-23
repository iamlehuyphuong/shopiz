<script setup>
import { computed } from 'vue';
import { emitter } from 'shared/helpers/mitt';
import { useTrack } from 'dashboard/composables';

import { BUS_EVENTS } from 'shared/constants/busEvents';
import { INBOX_TYPES } from 'dashboard/helper/inbox';
import { COPILOT_EVENTS } from 'dashboard/helper/AnalyticsHelper/events';
import MessageFormatter from 'shared/helpers/MessageFormatter.js';

import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';

const props = defineProps({
  isLastMessage: {
    type: Boolean,
    default: false,
  },
  message: {
    type: Object,
    required: true,
  },
  conversationInboxType: {
    type: String,
    required: true,
  },
});
const hasEmptyMessageContent = computed(() => !props.message?.content);

const parsedScenario = computed(() => {
  try {
    const content = props.message?.content || '';
    if (content.includes('"scenario":')) {
      const match = content.match(/\{[\s\S]*"scenario"[\s\S]*\}/);
      if (match) {
        const json = JSON.parse(match[0]);
        if (json.success && json.scenario) return json.scenario;
      }
    }
  } catch (e) {
    // Ignore JSON parse errors
  }
  return null;
});

const showUseButton = computed(() => {
  return (
    !hasEmptyMessageContent.value &&
    (props.message.reply_suggestion || parsedScenario.value) &&
    props.isLastMessage
  );
});

const messageContent = computed(() => {
  if (parsedScenario.value) {
    return `**Kịch bản đề xuất:**\n- Tiêu đề: ${parsedScenario.value.title}\n- Mô tả: ${parsedScenario.value.description}\n\nNhấn "Sử dụng" để đưa nội dung này vào Editor.`;
  }
  const formatter = new MessageFormatter(props.message.content);
  return formatter.formattedMessage;
});

const insertIntoRichEditor = computed(() => {
  return [INBOX_TYPES.WEB, INBOX_TYPES.EMAIL].includes(
    props.conversationInboxType
  );
});

const useCopilotResponse = () => {
  if (parsedScenario.value) {
    emitter.emit('CAPTAIN_SUGGEST_SCENARIO_USE', { success: true, scenario: parsedScenario.value });
    return;
  }
  
  if (insertIntoRichEditor.value) {
    emitter.emit(BUS_EVENTS.INSERT_INTO_RICH_EDITOR, props.message?.content);
  } else {
    emitter.emit(BUS_EVENTS.INSERT_INTO_NORMAL_EDITOR, props.message?.content);
  }
  useTrack(COPILOT_EVENTS.USE_CAPTAIN_RESPONSE);
};
</script>

<template>
  <div class="flex flex-col gap-1 text-n-slate-12">
    <div class="flex items-center gap-2 font-medium">
      <Avatar
        :name="$t('CAPTAIN.NAME')"
        :size="20"
        icon-name="i-lucide-sparkles"
        branded
      />
      <span class="font-semibold">{{ $t('CAPTAIN.NAME') }}</span>
    </div>
    <span v-if="hasEmptyMessageContent" class="text-n-ruby-11">
      {{ $t('CAPTAIN.COPILOT.EMPTY_MESSAGE') }}
    </span>
    <div
      v-else
      v-dompurify-html="messageContent"
      class="prose-sm break-words"
    />
    <div class="flex flex-row mt-1">
      <Button
        v-if="showUseButton"
        :label="$t('CAPTAIN.COPILOT.USE')"
        faded
        sm
        slate
        @click="useCopilotResponse"
      />
    </div>
  </div>
</template>
