<script setup>
import { computed, watch, onMounted, ref, onErrorCaptured } from 'vue';
import {
  useMapGetter,
  useFunctionGetter,
  useStore,
} from 'dashboard/composables/store';
import { useAccount } from 'dashboard/composables/useAccount';
import { useUISettings } from 'dashboard/composables/useUISettings';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

import AccordionItem from 'dashboard/components/Accordion/AccordionItem.vue';
import ContactConversations from './ContactConversations.vue';
import ConversationAction from './ConversationAction.vue';
import ConversationReminder from './ConversationReminder.vue';
import ConversationParticipant from './ConversationParticipant.vue';
import ContactInfo from './contact/ContactInfo.vue';
import ContactNotes from './contact/ContactNotes.vue';
import ConversationInfo from './ConversationInfo.vue';
import CustomAttributes from './customAttributes/CustomAttributes.vue';
import Draggable from 'vuedraggable';
import MacrosList from './Macros/List.vue';
import ZaloGroupMembers from './zalo/ZaloGroupMembers.vue';
import OrderPanel from 'dashboard/components/widgets/conversation/orders/OrderPanel.vue';
import OmicallContactPanel from './omicall/OmicallContactPanel.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  inboxId: {
    type: Number,
    default: undefined,
  },
  pendingProduct: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['product-consumed']);

const {
  updateUISettings,
  isContactSidebarItemOpen,
  conversationSidebarItemsOrder,
  toggleSidebarUIState,
} = useUISettings();

const dragging = ref(false);
const conversationSidebarItems = ref([]);

const store = useStore();
const currentChat = useMapGetter('getSelectedChat');
const conversationId = computed(() => props.conversationId);
const conversationMetadataGetter = useMapGetter(
  'conversationMetadata/getConversationMetadata'
);
const currentConversationMetaData = computed(() =>
  conversationMetadataGetter.value(conversationId.value)
);
const conversationAdditionalAttributes = computed(
  () =>
    currentChat.value.additional_attributes ||
    currentConversationMetaData.value.additional_attributes ||
    {}
);

const channelType = computed(() => currentChat.value.meta?.channel);

const contactGetter = useMapGetter('contacts/getContact');
const contactId = computed(() => currentChat.value.meta?.sender?.id);
const contact = computed(() => contactGetter.value(contactId.value));
const contactAdditionalAttributes = computed(
  () => contact.value.additional_attributes || {}
);

const conversationInboxId = computed(() => currentChat.value?.inbox_id);

const isZaloGroupConversation = computed(() => {
  const isZalo = channelType.value === 'Channel::ZaloPersonal';
  if (!isZalo) return false;
  const type = conversationAdditionalAttributes.value?.type;
  return type === 1 || !!conversationAdditionalAttributes.value?.group;
});

import { useI18n } from 'vue-i18n';

const currentUser = useMapGetter('getCurrentUser');
const sipUsername = computed(
  () =>
    currentUser.value?.omicall_sip_info?.sip_user ||
    currentUser.value?.custom_attributes?.sip_user
);
const { t } = useI18n();
const omicallTitle = computed(() => {
  return sipUsername.value
    ? `${t('CONTACT_PANEL.OMICALL.TITLE')} #${sipUsername.value}`
    : t('CONTACT_PANEL.OMICALL.TITLE');
});

const getContactDetails = () => {
  if (contactId.value) {
    store.dispatch('contacts/show', { id: contactId.value });
  }
};

watch(contactId, (newContactId, prevContactId) => {
  if (newContactId && newContactId !== prevContactId) {
    getContactDetails();
  }
});

const onDragEnd = () => {
  dragging.value = false;
  updateUISettings({
    conversation_sidebar_items_order: conversationSidebarItems.value,
  });
};

onMounted(() => {
  conversationSidebarItems.value = conversationSidebarItemsOrder.value;
  getContactDetails();
  store.dispatch('attributes/get', 0);
  // Load integrations to ensure linear integration state is available
  store.dispatch('integrations/get', 'linear');
});

const errorMsg = ref('');
onErrorCaptured(err => {
  errorMsg.value = err.message + '\n' + err.stack;
  return false;
});
</script>

<template>
  <div class="w-full">
    <div
      v-if="errorMsg"
      class="p-4 bg-red-100 text-red-800 text-xs whitespace-pre-wrap"
    >
      {{ errorMsg }}
    </div>
    <ContactInfo :contact="contact" :channel-type="channelType" />
    <div class="px-2 pb-8 list-group">
      <Draggable
        :list="conversationSidebarItems"
        animation="200"
        ghost-class="ghost"
        handle=".drag-handle"
        item-key="name"
        class="flex flex-col gap-3"
        @start="dragging = true"
        @end="onDragEnd"
      >
        <template #item="{ element }">
          <div
            v-if="element.name === 'conversation_actions'"
            class="conversation--actions"
          >
            <AccordionItem
              :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_ACTIONS')"
              :is-open="isContactSidebarItemOpen('is_conv_actions_open')"
              @toggle="
                value => toggleSidebarUIState('is_conv_actions_open', value)
              "
            >
              <ConversationAction
                :conversation-id="conversationId"
                :inbox-id="inboxId"
              />
            </AccordionItem>
          </div>
          <div
            v-else-if="element.name === 'conversation_reminder'"
            class="conversation--actions"
          >
            <AccordionItem
              :title="$t('CONVERSATION_SIDEBAR.REMINDER_TITLE')"
              :is-open="isContactSidebarItemOpen('is_conv_reminder_open')"
              @toggle="
                value => toggleSidebarUIState('is_conv_reminder_open', value)
              "
            >
              <ConversationReminder
                :conversation-id="conversationId"
                :inbox-id="inboxId"
              />
            </AccordionItem>
          </div>
          <div
            v-else-if="element.name === 'orders'"
            class="conversation--actions"
          >
            <OrderPanel
              :conversation-id="conversationId"
              :pending-product="pendingProduct"
              @product-consumed="emit('product-consumed')"
            />
          </div>
          <div
            v-else-if="element.name === 'omicall'"
            class="conversation--actions"
          >
            <AccordionItem
              :title="omicallTitle"
              :is-open="isContactSidebarItemOpen('is_omicall_open')"
              @toggle="value => toggleSidebarUIState('is_omicall_open', value)"
            >
              <OmicallContactPanel
                :contact="contact"
                :is-expanded="isContactSidebarItemOpen('is_omicall_open')"
              />
            </AccordionItem>
          </div>
          <div
            v-else-if="element.name === 'conversation_participants'"
            class="conversation--actions"
          >
            <AccordionItem
              :title="$t('CONVERSATION_PARTICIPANTS.SIDEBAR_TITLE')"
              :is-open="isContactSidebarItemOpen('is_conv_participants_open')"
              @toggle="
                value =>
                  toggleSidebarUIState('is_conv_participants_open', value)
              "
            >
              <ConversationParticipant
                :conversation-id="conversationId"
                :inbox-id="inboxId"
              />
            </AccordionItem>
          </div>
          <div v-else-if="element.name === 'conversation_info'">
            <AccordionItem
              :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONVERSATION_INFO')"
              :is-open="isContactSidebarItemOpen('is_conv_details_open')"
              compact
              @toggle="
                value => toggleSidebarUIState('is_conv_details_open', value)
              "
            >
              <ConversationInfo
                :conversation-attributes="conversationAdditionalAttributes"
                :contact-attributes="contactAdditionalAttributes"
                :empty-state-message="
                  $t('CONVERSATION_CUSTOM_ATTRIBUTES.NO_RECORDS_FOUND')
                "
              />
            </AccordionItem>
          </div>
          <div v-else-if="element.name === 'contact_attributes'">
            <AccordionItem
              :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONTACT_ATTRIBUTES')"
              :is-open="isContactSidebarItemOpen('is_contact_attributes_open')"
              compact
              @toggle="
                value =>
                  toggleSidebarUIState('is_contact_attributes_open', value)
              "
            >
              <CustomAttributes
                attribute-type="contact_attribute"
                attribute-from="conversation_contact_panel"
                :contact-id="contact.id"
                :empty-state-message="
                  $t('CONVERSATION_CUSTOM_ATTRIBUTES.NO_RECORDS_FOUND')
                "
              />
            </AccordionItem>
          </div>
          <div v-else-if="element.name === 'previous_conversation'">
            <AccordionItem
              v-if="contact.id"
              :title="
                $t('CONVERSATION_SIDEBAR.ACCORDION.PREVIOUS_CONVERSATION')
              "
              :is-open="isContactSidebarItemOpen('is_previous_conv_open')"
              compact
              @toggle="
                value => toggleSidebarUIState('is_previous_conv_open', value)
              "
            >
              <ContactConversations
                :contact-id="contact.id"
                :conversation-id="conversationId"
              />
            </AccordionItem>
          </div>
          <woot-feature-toggle
            v-else-if="element.name === 'macros'"
            feature-key="macros"
          >
            <AccordionItem
              :title="$t('CONVERSATION_SIDEBAR.ACCORDION.MACROS')"
              :is-open="isContactSidebarItemOpen('is_macro_open')"
              compact
              @toggle="value => toggleSidebarUIState('is_macro_open', value)"
            >
              <MacrosList :conversation-id="conversationId" />
            </AccordionItem>
          </woot-feature-toggle>
          <div
            v-else-if="
              element.name === 'zalo_group_members' && isZaloGroupConversation
            "
          >
            <AccordionItem
              title="Thành viên nhóm"
              :is-open="isContactSidebarItemOpen('is_zalo_group_members_open')"
              compact
              @toggle="
                value =>
                  toggleSidebarUIState('is_zalo_group_members_open', value)
              "
            >
              <ZaloGroupMembers
                :conversation-id="conversationId"
                :conversation-inbox-id="conversationInboxId"
              />
            </AccordionItem>
          </div>
          <div v-else-if="element.name === 'contact_notes'">
            <AccordionItem
              :title="$t('CONVERSATION_SIDEBAR.ACCORDION.CONTACT_NOTES')"
              :is-open="isContactSidebarItemOpen('is_contact_notes_open')"
              compact
              @toggle="
                value => toggleSidebarUIState('is_contact_notes_open', value)
              "
            >
              <ContactNotes :contact-id="contactId" />
            </AccordionItem>
          </div>
        </template>
      </Draggable>
    </div>
  </div>
</template>

<style lang="scss" scoped>
::v-deep {
  .contact--profile {
    @apply pb-3 border-b border-solid border-n-weak;
  }
}
</style>
