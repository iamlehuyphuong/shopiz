<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import CampaignList from 'dashboard/components-next/Campaigns/Pages/CampaignPage/CampaignList.vue';
import LineCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/LineCampaign/LineCampaignDialog.vue';
import ConfirmDeleteCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ConfirmDeleteCampaignDialog.vue';
import LineCampaignEmptyState from 'dashboard/components-next/Campaigns/EmptyState/LineCampaignEmptyState.vue';

const { t } = useI18n();
const getters = useStoreGetters();

const selectedCampaign = ref(null);
const [showLineCampaignDialog, toggleLineCampaignDialog] = useToggle();

const uiFlags = useMapGetter('campaigns/getUIFlags');
const isFetchingCampaigns = computed(() => uiFlags.value.isFetching);

const confirmDeleteCampaignDialogRef = ref(null);

const LineCampaigns = computed(() => getters['campaigns/getLineCampaigns'].value);

const hasNoLineCampaigns = computed(
  () => LineCampaigns.value?.length === 0 && !isFetchingCampaigns.value
);

const handleDelete = campaign => {
  selectedCampaign.value = campaign;
  confirmDeleteCampaignDialogRef.value.dialogRef.open();
};
</script>

<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.LINE.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.LINE.NEW_CAMPAIGN')"
    @click="toggleLineCampaignDialog()"
    @close="toggleLineCampaignDialog(false)"
  >
    <template #action>
      <LineCampaignDialog
        v-if="showLineCampaignDialog"
        @close="toggleLineCampaignDialog(false)"
      />
    </template>
    <div
      v-if="isFetchingCampaigns"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <CampaignList
      v-else-if="!hasNoLineCampaigns"
      :campaigns="LineCampaigns"
      @delete="handleDelete"
    />
    <LineCampaignEmptyState
      v-else
      :title="t('CAMPAIGN.LINE.EMPTY_STATE.TITLE')"
      :subtitle="t('CAMPAIGN.LINE.EMPTY_STATE.SUBTITLE')"
      class="pt-14"
    />
    <ConfirmDeleteCampaignDialog
      ref="confirmDeleteCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
  </CampaignLayout>
</template>
