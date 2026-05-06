<script setup>
import { computed, ref, nextTick } from 'vue';
import { useRouter } from 'vue-router';
import { useMapGetter } from 'dashboard/composables/store';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';
import { useAccount } from 'dashboard/composables/useAccount';
import { useLimitation } from 'dashboard/composables/useLimitation';

import PageLayout from 'dashboard/components-next/captain/PageLayout.vue';
import CreateAssistantDialog from 'dashboard/components-next/captain/pageComponents/assistant/CreateAssistantDialog.vue';
import AssistantPageEmptyState from 'dashboard/components-next/captain/pageComponents/emptyStates/AssistantPageEmptyState.vue';
import FeatureSpotlightPopover from 'dashboard/components-next/feature-spotlight/FeatureSpotlightPopover.vue';
import BillingMeter from 'dashboard/routes/dashboard/settings/billing/components/BillingMeter.vue';
import AssistantCard from 'dashboard/components-next/captain/assistant/AssistantCard.vue';
import DeleteDialog from 'dashboard/components-next/captain/pageComponents/DeleteDialog.vue';

const { isOnChatwootCloud } = useAccount();
const { getUsage, checkLimitation } = useLimitation();

const dialogType = ref('');
const uiFlags = useMapGetter('captainAssistants/getUIFlags');
const isFetching = computed(() => uiFlags.value.fetchingList);

const selectedAssistant = ref(null);
const deleteAssistantDialog = ref(null);

const createAssistantDialog = ref(null);
const router = useRouter();

const handleCreate = () => {
  if (checkLimitation('captain_assistants')) {
    dialogType.value = 'create';
    nextTick(() => createAssistantDialog.value.dialogRef.open());
  }
};

const handleCreateClose = () => {
  dialogType.value = '';
  selectedAssistant.value = null;
};

const handleAfterCreate = newAssistant => {
  // Navigate directly to documents page with the new assistant ID
  if (newAssistant?.id) {
    router.push({
      name: 'captain_assistants_responses_index',
      params: {
        accountId: router.currentRoute.value.params.accountId,
        assistantId: newAssistant.id,
      },
    });
  }
};
</script>

<template>
  <PageLayout
    :header-title="$t('CAPTAIN.ASSISTANTS.HEADER')"
    :show-pagination-footer="false"
    :is-fetching="isFetching"
    :feature-flag="FEATURE_FLAGS.CAPTAIN"
    @click="handleCreate"
  >
    <template #usage>
      <BillingMeter
        v-if="isOnChatwootCloud"
        :consumed="getUsage('captain_assistants').consumed"
        :total-count="getUsage('captain_assistants').totalCount"
        :show-bar="false"
        :show-title="false"
        class="px-2 py-0.5 bg-slate-50 border border-slate-100 rounded-full w-auto block"
      />
    </template>
    <template #knowMore>
      <FeatureSpotlightPopover
        :button-label="$t('CAPTAIN.HEADER_KNOW_MORE')"
        :title="$t('CAPTAIN.ASSISTANTS.EMPTY_STATE.FEATURE_SPOTLIGHT.TITLE')"
        :note="$t('CAPTAIN.ASSISTANTS.EMPTY_STATE.FEATURE_SPOTLIGHT.NOTE')"
        :hide-actions="!isOnChatwootCloud"
        fallback-thumbnail="/assets/images/dashboard/captain/assistant-popover-light.svg"
        fallback-thumbnail-dark="/assets/images/dashboard/captain/assistant-popover-dark.svg"
        learn-more-url="https://www.shopiz.pro/docs/04-shopizai-copilot/02-knowledge-base"
      />
    </template>

    <template #emptyState>
      <AssistantPageEmptyState @click="handleCreate" />
    </template>

    <template #body>
      <div class="flex flex-col gap-4">
        <AssistantCard
          v-for="assistant in assistants"
          :id="assistant.id"
          :key="assistant.id"
          :name="assistant.name"
          :description="assistant.description"
          :updated-at="assistant.updated_at || assistant.created_at"
          :created-at="assistant.created_at"
          @action="handleAction"
        />
      </div>
    </template>

    <DeleteDialog
      v-if="selectedAssistant"
      ref="deleteAssistantDialog"
      :entity="selectedAssistant"
      type="Assistants"
    />

    <CreateAssistantDialog
      v-if="dialogType"
      ref="createAssistantDialog"
      :type="dialogType"
      :selected-assistant="selectedAssistant"
      @close="handleCreateClose"
      @created="handleAfterCreate"
    />
  </PageLayout>
</template>
