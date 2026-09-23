<script setup>
import { ref, reactive, computed } from 'vue';
import Message from '../Message.vue';

const currentUserId = ref(1);

const state = reactive({
  useCurrentUserId: false,
});

const getMessage = overrides => {
  const contentAttributes = {
    inReplyTo: null,
    ...(overrides.contentAttributes ?? {}),
  };

  const sender = {
    additionalAttributes: {},
    customAttributes: {},
    email: 'hey@example.com',
    id: 597,
    identifier: null,
    name: 'John Doe',
    phoneNumber: null,
    thumbnail: '',
    type: 'contact',
    ...(overrides.sender ?? {}),
  };

  return {
    id: 5272,
    content: 'Hey, how are ya, I had a few questions about Chatwoot?',
    inboxId: 475,
    conversationId: 43,
    messageType: 0,
    contentType: 'text',
    status: 'sent',
    createdAt: 1732195656,
    private: false,
    sourceId: null,
    ...overrides,
    sender,
    contentAttributes,
  };
};

const baseSenderData = computed(() => {
  return {
    messageType: state.useCurrentUserId ? 1 : 0,
    senderId: state.useCurrentUserId ? currentUserId.value : 597,
    sender: {
      id: state.useCurrentUserId ? currentUserId.value : 597,
      type: state.useCurrentUserId ? 'User' : 'Contact',
    },
  };
});

const simpleText = computed(() =>
  getMessage({
    ...baseSenderData.value,
  })
);
const privateText = computed(() =>
  getMessage({ private: true, ...baseSenderData.value })
);

const activityMessage = computed(() =>
  getMessage({
    content: 'John self-assigned this conversation',
    messageType: 2,
  })
);
</script>

<template>
  <Story
    title="Components/Message Bubbles/Bubbles"
    :layout="{ type: 'grid', width: '800px' }"
  >
    <Variant title="Text">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="simpleText" />
      </div>
    </Variant>
    <Variant title="Activity">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="activityMessage" />
      </div>
    </Variant>
    <Variant title="Private Message">
      <div class="p-4 bg-n-background rounded-lg w-full min-w-5xl grid">
        <Message :current-user-id="1" v-bind="privateText" />
      </div>
    </Variant>
  </Story>
</template>
