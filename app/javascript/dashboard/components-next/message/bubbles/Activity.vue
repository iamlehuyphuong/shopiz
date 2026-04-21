<script setup>
import { computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { messageTimestamp } from 'shared/helpers/timeHelper';
import BaseBubble from './Base.vue';
import { useMessageContext } from '../provider.js';

const { t, te } = useI18n();
const { content, createdAt, contentAttributes } = useMessageContext();

const readableTime = computed(() =>
  messageTimestamp(
    createdAt.value,
    t('GENERAL.DATETIME_FORMAT_WITH_SHORT_MONTH')
  )
);

const localizedContent = computed(() => {
  const attrs = contentAttributes?.value || {};
  const translationKey = attrs.translation_key || attrs.translationKey;

  if (translationKey) {
    const frontendTranslationKey = translationKey.replace(
      /^conversations\.activity\./,
      'CONVERSATION.ACTIVITY.'
    );

    if (te(frontendTranslationKey)) {
      const translationValues =
        attrs.translation_values || attrs.translationValues || {};

      // Convert camelCase keys back to snake_case just in case Axios intercepted them.
      // We expect `{user_name}` but interceptor might make it `{userName}`.
      const normalizedValues = {};
      Object.keys(translationValues).forEach(key => {
        const snakeKey = key.replace(
          /[A-Z]/g,
          letter => `_${letter.toLowerCase()}`
        );
        normalizedValues[snakeKey] = translationValues[key];
        normalizedValues[key] = translationValues[key]; // Keep original as fallback
      });

      return t(frontendTranslationKey, normalizedValues);
    }
  }
  return content.value;
});
</script>

<template>
  <BaseBubble
    v-tooltip.top="readableTime"
    class="px-3 py-1 !rounded-xl flex min-w-0 items-center gap-2"
    data-bubble-name="activity"
  >
    <span v-dompurify-html="localizedContent" :title="localizedContent" />
  </BaseBubble>
</template>
