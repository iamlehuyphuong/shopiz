<script setup>
import { computed, onMounted, ref, watch } from 'vue';
import { useStoreGetters, useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import SettingsLayout from '../../settings/SettingsLayout.vue';
import BaseSettingsHeader from '../../settings/components/BaseSettingsHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import MultiSelect from 'dashboard/components-next/filter/inputs/MultiSelect.vue';
import Switch from 'next/switch/Switch.vue';
import WithLabel from 'v3/components/Form/WithLabel.vue';
import TextArea from 'next/textarea/TextArea.vue';
import { useAlert } from 'dashboard/composables';

import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';
import { timeZoneOptions } from '../../settings/inbox/helpers/businessHour';
import { useCaptain } from 'dashboard/composables/useCaptain';

const { t } = useI18n();
const getters = useStoreGetters();
const store = useStore();
const { processEvent } = useCaptain();

const uiFlags = computed(() => getters['inboxDailySummaries/getUIFlags'].value);
const record = computed(() => getters['inboxDailySummaries/getRecord'].value);
const inboxes = computed(() => getters['inboxes/getInboxes'].value);
const agents = computed(() => getters['agents/getAgents'].value);

const form = ref({
  enabled: false,
  summary_instruction: '',
  reporting_instruction: '',
  inbox_ids: [],
  user_ids: [],
  schedule_times: [],
  timezone: 'Asia/Ho_Chi_Minh',
});

const isImproving = ref({
  summary_instruction: false,
  reporting_instruction: false,
});

const improveInstruction = async field => {
  if (!form.value[field]) return;

  isImproving.value[field] = true;
  try {
    const eventName =
      field === 'summary_instruction'
        ? 'improve_summary_instruction'
        : 'improve_reporting_instruction';

    const { message } = await processEvent(eventName, form.value[field]);

    if (message) {
      form.value[field] = message;
    }
  } catch (error) {
    // Errors are handled inside processEvent (via handleAPIError)
  } finally {
    isImproving.value[field] = false;
  }
};

const timeZones = computed(() => timeZoneOptions());

const timeZoneValue = computed({
  get: () => {
    let tz =
      form.value.timezone || Intl.DateTimeFormat().resolvedOptions().timeZone;
    if (tz === 'Asia/Saigon') tz = 'Asia/Ho_Chi_Minh';
    return timeZones.value.some(tzOpt => tzOpt.value === tz)
      ? tz
      : 'Asia/Ho_Chi_Minh';
  },
  set: val => {
    form.value.timezone = val;
  },
});

const inboxOptions = computed(() => {
  return inboxes.value.map(inbox => ({
    id: inbox.id,
    name: inbox.name,
    icon: 'i-lucide-inbox',
  }));
});

const agentOptions = computed(() => {
  return agents.value.map(agent => ({
    id: agent.id,
    name: agent.name,
    icon: 'i-lucide-user',
  }));
});

const scheduleOptions = computed(() => {
  return Array.from({ length: 24 }).map((_, i) => {
    const hour = i.toString().padStart(2, '0');
    const time = `${hour}:00`;
    return { id: time, name: time, icon: 'i-lucide-clock' };
  });
});

const selectedInboxes = computed({
  get: () =>
    inboxOptions.value.filter(opt => form.value.inbox_ids.includes(opt.id)),
  set: val => {
    form.value.inbox_ids = val.map(v => v.id);
  },
});

const selectedAgents = computed({
  get: () =>
    agentOptions.value.filter(opt => form.value.user_ids.includes(opt.id)),
  set: val => {
    form.value.user_ids = val.map(v => v.id);
  },
});

const selectedSchedules = computed({
  get: () =>
    scheduleOptions.value.filter(opt =>
      form.value.schedule_times.includes(opt.id)
    ),
  set: val => {
    form.value.schedule_times = val.map(v => v.id);
  },
});

onMounted(() => {
  store.dispatch('inboxes/get');
  store.dispatch('agents/get');
  store.dispatch('inboxDailySummaries/get');
});

watch(
  record,
  newRecord => {
    if (newRecord && Object.keys(newRecord).length > 0) {
      const currentUser = getters.getCurrentUser?.value;
      const currentAccount = getters.getCurrentAccount?.value;
      const userTimezone =
        currentUser?.custom_attributes?.timezone ||
        currentUser?.ui_settings?.timezone;
      const accountTimezone = currentAccount?.custom_attributes?.timezone;

      let resolvedTimezone =
        newRecord.timezone ||
        userTimezone ||
        accountTimezone ||
        Intl.DateTimeFormat().resolvedOptions().timeZone;
      if (resolvedTimezone === 'Asia/Saigon')
        resolvedTimezone = 'Asia/Ho_Chi_Minh';
      if (!timeZones.value.some(tzOpt => tzOpt.value === resolvedTimezone)) {
        resolvedTimezone = 'Asia/Ho_Chi_Minh';
      }

      form.value = {
        enabled: newRecord.enabled ?? false,
        summary_instruction: newRecord.summary_instruction ?? '',
        reporting_instruction: newRecord.reporting_instruction ?? '',
        inbox_ids: [...(newRecord.inbox_ids || [])],
        user_ids: [...(newRecord.user_ids || [])],
        schedule_times: [...(newRecord.schedule_times || [])],
        timezone: resolvedTimezone,
      };
    }
  },
  { immediate: true }
);

const saveConfig = async () => {
  try {
    await store.dispatch('inboxDailySummaries/update', {
      id: record.value?.id,
      ...form.value,
    });
    useAlert(t('DAILY_SUMMARY.ALERTS.SUCCESS'));
  } catch (error) {
    const backendError = error?.response?.data?.error;
    useAlert(backendError || t('DAILY_SUMMARY.ALERTS.ERROR'));
  }
};
</script>

<template>
  <SettingsLayout :is-loading="uiFlags.isFetching" :no-records-found="false">
    <template #header>
      <BaseSettingsHeader
        :title="$t('DAILY_SUMMARY.TITLE')"
        :description="$t('DAILY_SUMMARY.DESCRIPTION')"
      />
    </template>

    <template #body>
      <div class="flex flex-col gap-6 mt-4 pb-8">
        <div
          class="flex flex-col w-full outline-1 outline outline-n-container rounded-xl bg-n-solid-2 divide-y divide-n-weak"
        >
          <div class="flex flex-col gap-2 items-start px-5 py-4">
            <div class="flex justify-between items-center w-full">
              <h3 class="text-heading-2 text-n-slate-12">
                {{ $t('DAILY_SUMMARY.CONFIG_SECTION.TITLE') }}
              </h3>
              <div class="flex justify-end">
                <Switch v-model="form.enabled" />
              </div>
            </div>
            <p class="mb-0 text-body-para text-n-slate-11">
              {{ $t('DAILY_SUMMARY.CONFIG_SECTION.DESCRIPTION') }}
            </p>
          </div>

          <div v-if="form.enabled" class="px-5 py-4">
            <form class="grid gap-5" @submit.prevent="saveConfig">
              <WithLabel
                :label="$t('DAILY_SUMMARY.FORM.INBOXES.LABEL')"
                :help-message="$t('DAILY_SUMMARY.FORM.INBOXES.HELP')"
              >
                <MultiSelect
                  v-model="selectedInboxes"
                  :options="inboxOptions"
                  :max-chips="5"
                />
              </WithLabel>

              <WithLabel
                :label="$t('DAILY_SUMMARY.FORM.RECIPIENTS.LABEL')"
                :help-message="$t('DAILY_SUMMARY.FORM.RECIPIENTS.HELP')"
              >
                <MultiSelect
                  v-model="selectedAgents"
                  :options="agentOptions"
                  :max-chips="5"
                />
              </WithLabel>

              <WithLabel
                :label="$t('DAILY_SUMMARY.FORM.SCHEDULE.LABEL')"
                :help-message="$t('DAILY_SUMMARY.FORM.SCHEDULE.HELP')"
              >
                <div class="flex flex-col gap-3 w-full">
                  <MultiSelect
                    v-model="selectedSchedules"
                    :options="scheduleOptions"
                    :max-chips="10"
                  />

                  <div class="w-full sm:w-[320px]">
                    <ComboBox
                      v-model="timeZoneValue"
                      :options="timeZones"
                      :placeholder="
                        $t('DAILY_SUMMARY.FORM.TIMEZONE.PLACEHOLDER')
                      "
                      class="[&>div>button]:!bg-n-alpha-2 [&>div>button]:!border-none [&>div>button]:!h-8 [&>div>button]:!rounded-lg"
                    />
                  </div>
                </div>
              </WithLabel>

              <WithLabel
                :label="$t('DAILY_SUMMARY.FORM.SUMMARY_INSTRUCTION.LABEL')"
                :help-message="
                  $t('DAILY_SUMMARY.FORM.SUMMARY_INSTRUCTION.HELP')
                "
              >
                <div class="flex flex-col gap-2 w-full">
                  <TextArea
                    v-model="form.summary_instruction"
                    class="w-full"
                    auto-height
                    min-height="6rem"
                    :placeholder="
                      $t('DAILY_SUMMARY.FORM.SUMMARY_INSTRUCTION.PLACEHOLDER')
                    "
                  />
                  <div class="flex justify-start">
                    <NextButton
                      icon="i-lucide-wand-2"
                      size="xs"
                      color="slate"
                      :label="
                        $t('DAILY_SUMMARY.FORM.IMPROVE_BY_AI', 'Improve by AI')
                      "
                      :is-loading="isImproving.summary_instruction"
                      @click="improveInstruction('summary_instruction')"
                    />
                  </div>
                </div>
              </WithLabel>

              <WithLabel
                :label="$t('DAILY_SUMMARY.FORM.REPORTING_INSTRUCTION.LABEL')"
                :help-message="
                  $t('DAILY_SUMMARY.FORM.REPORTING_INSTRUCTION.HELP')
                "
              >
                <div class="flex flex-col gap-2 w-full">
                  <TextArea
                    v-model="form.reporting_instruction"
                    class="w-full"
                    auto-height
                    min-height="6rem"
                    :placeholder="
                      $t('DAILY_SUMMARY.FORM.REPORTING_INSTRUCTION.PLACEHOLDER')
                    "
                  />
                  <div class="flex justify-start">
                    <NextButton
                      icon="i-lucide-wand-2"
                      size="xs"
                      color="slate"
                      :label="
                        $t('DAILY_SUMMARY.FORM.IMPROVE_BY_AI', 'Improve by AI')
                      "
                      :is-loading="isImproving.reporting_instruction"
                      @click="improveInstruction('reporting_instruction')"
                    />
                  </div>
                </div>
              </WithLabel>

              <div class="flex gap-2">
                <NextButton
                  blue
                  type="submit"
                  :is-loading="uiFlags.isUpdating"
                  :label="$t('DAILY_SUMMARY.FORM.SAVE')"
                />
              </div>
            </form>
          </div>
        </div>
      </div>
    </template>
  </SettingsLayout>
</template>
