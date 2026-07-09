<script setup>
import { reactive, computed, ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useMapGetter, useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useCaptain } from 'dashboard/composables/useCaptain';

import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import TagMultiSelectComboBox from 'dashboard/components-next/combobox/TagMultiSelectComboBox.vue';

const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: value => ['edit', 'create'].includes(value),
  },
  selectedCampaign: {
    type: Object,
    default: () => ({}),
  },
  showActionButtons: {
    type: Boolean,
    default: true,
  },
});

const emit = defineEmits(['submit', 'cancel']);

const { t } = useI18n();
const store = useStore();

const formState = {
  uiFlags: useMapGetter('campaigns/getUIFlags'),
  labels: useMapGetter('labels/getLabels'),
  inboxes: useMapGetter('inboxes/getFacebookInboxes'),
};

const senderList = ref([]);

const initialState = {
  title: '',
  message: '',
  inboxId: null,
  senderId: null,
  scheduledAt: null,
  selectedAudience: [],
};

const state = reactive({ ...initialState });

const rules = {
  title: { required, minLength: minLength(1) },
  message: { required, minLength: minLength(1) },
  inboxId: { required },
  senderId: { required },
  scheduledAt: { required },
  selectedAudience: { required },
};

const v$ = useVuelidate(rules, state);

const isCreating = computed(() => formState.uiFlags.value.isCreating);
const isImproving = ref(false);
const { processEvent } = useCaptain();

const currentDateTime = computed(() => {
  const now = new Date();
  const localTime = new Date(now.getTime() - now.getTimezoneOffset() * 60000);
  return localTime.toISOString().slice(0, 16);
});

const mapToOptions = (items, valueKey, labelKey) =>
  items?.map(item => ({
    value: item[valueKey],
    label: item[labelKey],
  })) ?? [];

const sendersAndBotList = computed(() => [
  { value: 0, label: t('CAMPAIGN.VOICE.CARD.CAMPAIGN_DETAILS.BOT') },
  ...mapToOptions(senderList.value, 'id', 'name'),
]);

const audienceList = computed(() =>
  mapToOptions(formState.labels.value, 'id', 'title')
);

const inboxOptions = computed(() =>
  mapToOptions(formState.inboxes.value, 'id', 'name')
);

const getErrorMessage = (field, errorKey) => {
  const baseKey = 'CAMPAIGN.FACEBOOK.CREATE.FORM';
  return v$.value[field].$error ? t(`${baseKey}.${errorKey}.ERROR`) : '';
};

const formErrors = computed(() => ({
  title: getErrorMessage('title', 'TITLE'),
  message: getErrorMessage('message', 'MESSAGE'),
  inbox: getErrorMessage('inboxId', 'INBOX'),
  scheduledAt: getErrorMessage('scheduledAt', 'SCHEDULED_AT'),
  audience: getErrorMessage('selectedAudience', 'AUDIENCE'),
}));

const isSubmitDisabled = computed(() => v$.value.$invalid);

const formatToUTCString = localDateTime =>
  localDateTime ? new Date(localDateTime).toISOString() : null;

const handleInboxChange = async inboxId => {
  if (!inboxId) {
    senderList.value = [];
    return;
  }

  try {
    const response = await store.dispatch('inboxMembers/get', { inboxId });
    senderList.value = response?.data?.payload ?? [];
  } catch (error) {
    senderList.value = [];
    useAlert(
      error?.response?.message ??
        t('CAMPAIGN.FACEBOOK.CREATE.FORM.API.ERROR_MESSAGE')
    );
  }
};

watch(
  () => state.inboxId,
  newInboxId => {
    if (newInboxId) {
      handleInboxChange(newInboxId);
    }
  },
  { immediate: true }
);

const resetState = () => {
  Object.assign(state, initialState);
};

const updateStateFromCampaign = campaign => {
  if (!campaign) return;

  const {
    title,
    message,
    inbox: { id: inboxId },
    sender,
    scheduled_at,
    audience,
  } = campaign;
  const selectedAudience = audience.map(item => item.id);
  const scheduled = new Date(
    scheduled_at * 1000 - new Date().getTimezoneOffset() * 60000
  )
    .toISOString()
    .slice(0, 16);

  Object.assign(state, {
    title,
    message,
    inboxId,
    senderId: sender?.id ?? 0,
    scheduledAt: scheduled,
    selectedAudience,
  });
};

const handleCancel = () => emit('cancel');

const improveMessage = async () => {
  if (!state.message) return;
  isImproving.value = true;
  try {
    const { message } = await processEvent(
      'improve_campaign_message',
      state.message
    );
    if (message) state.message = message;
  } finally {
    isImproving.value = false;
  }
};

const prepareCampaignDetails = () => ({
  title: state.title,
  message: state.message,
  inbox_id: state.inboxId,
  sender_id: state.senderId || null,
  scheduled_at: formatToUTCString(state.scheduledAt),
  audience: state.selectedAudience?.map(id => ({
    id,
    type: 'Label',
  })),
});

const handleSubmit = async () => {
  const isFormValid = await v$.value.$validate();
  if (!isFormValid) return;

  emit('submit', prepareCampaignDetails());
  resetState();
  handleCancel();
};

watch(
  () => props.selectedCampaign,
  newCampaign => {
    if (props.mode === 'edit' && newCampaign) {
      updateStateFromCampaign(newCampaign);
    }
  },
  { immediate: true }
);

defineExpose({ prepareCampaignDetails, isSubmitDisabled });
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <Input
      v-model="state.title"
      :label="t('CAMPAIGN.FACEBOOK.CREATE.FORM.TITLE.LABEL')"
      :placeholder="t('CAMPAIGN.FACEBOOK.CREATE.FORM.TITLE.PLACEHOLDER')"
      :message="formErrors.title"
      :message-type="formErrors.title ? 'error' : 'info'"
    />

    <div class="flex flex-col gap-1 w-full">
      <TextArea
        v-model="state.message"
        :label="t('CAMPAIGN.FACEBOOK.CREATE.FORM.MESSAGE.LABEL')"
        :placeholder="t('CAMPAIGN.FACEBOOK.CREATE.FORM.MESSAGE.PLACEHOLDER')"
        show-character-count
        :message="formErrors.message"
        :message-type="formErrors.message ? 'error' : 'info'"
      />
      <div class="flex justify-start">
        <Button
          icon="i-lucide-wand-2"
          size="xs"
          color="slate"
          :label="t('TEAMS_SETTINGS.FORM.IMPROVE_BY_AI', 'Improve by AI')"
          :is-loading="isImproving"
          type="button"
          @click="improveMessage"
        />
      </div>
    </div>

    <div class="flex flex-col gap-1">
      <label for="inbox" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.FACEBOOK.CREATE.FORM.INBOX.LABEL') }}
      </label>
      <ComboBox
        id="inbox"
        v-model="state.inboxId"
        :options="inboxOptions"
        :has-error="!!formErrors.inbox"
        :placeholder="t('CAMPAIGN.FACEBOOK.CREATE.FORM.INBOX.PLACEHOLDER')"
        :message="formErrors.inbox"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
      />
    </div>

    <div class="flex flex-col gap-1">
      <label for="sender" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.FACEBOOK.CREATE.FORM.SENT_BY.LABEL') }}
      </label>
      <ComboBox
        id="sender"
        v-model="state.senderId"
        :options="sendersAndBotList"
        :has-error="!!formErrors.sender"
        :disabled="!state.inboxId"
        :placeholder="t('CAMPAIGN.FACEBOOK.CREATE.FORM.SENT_BY.PLACEHOLDER')"
        :message="formErrors.sender"
        class="[&>div>button]:bg-n-alpha-black2 [&>div>button:not(.focused)]:dark:outline-n-weak [&>div>button:not(.focused)]:hover:!outline-n-slate-6"
      />
    </div>

    <div class="flex flex-col gap-1">
      <label for="audience" class="mb-0.5 text-sm font-medium text-n-slate-12">
        {{ t('CAMPAIGN.FACEBOOK.CREATE.FORM.AUDIENCE.LABEL') }}
      </label>
      <TagMultiSelectComboBox
        v-model="state.selectedAudience"
        :options="audienceList"
        :label="t('CAMPAIGN.FACEBOOK.CREATE.FORM.AUDIENCE.LABEL')"
        :placeholder="t('CAMPAIGN.FACEBOOK.CREATE.FORM.AUDIENCE.PLACEHOLDER')"
        :has-error="!!formErrors.audience"
        :message="formErrors.audience"
        class="[&>div>button]:bg-n-alpha-black2"
      />
    </div>

    <Input
      v-model="state.scheduledAt"
      :label="t('CAMPAIGN.FACEBOOK.CREATE.FORM.SCHEDULED_AT.LABEL')"
      type="datetime-local"
      :min="currentDateTime"
      :placeholder="t('CAMPAIGN.FACEBOOK.CREATE.FORM.SCHEDULED_AT.PLACEHOLDER')"
      :message="formErrors.scheduledAt"
      :message-type="formErrors.scheduledAt ? 'error' : 'info'"
    />

    <div
      v-if="showActionButtons"
      class="flex items-center justify-between w-full gap-3"
    >
      <Button
        variant="faded"
        color="slate"
        type="button"
        :label="t('CAMPAIGN.FACEBOOK.CREATE.FORM.BUTTONS.CANCEL')"
        class="w-full bg-n-alpha-2 n-orange-text hover:bg-n-alpha-3"
        @click="handleCancel"
      />
      <Button
        :label="t('CAMPAIGN.FACEBOOK.CREATE.FORM.BUTTONS.CREATE')"
        class="w-full"
        type="submit"
        :is-loading="isCreating"
        :disabled="isCreating || isSubmitDisabled"
      />
    </div>
  </form>
</template>
