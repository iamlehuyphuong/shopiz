<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import CampaignList from 'dashboard/components-next/Campaigns/Pages/CampaignPage/CampaignList.vue';
import ZaloOaCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ZaloOa/ZaloOaCampaignDialog.vue';
import ConfirmDeleteCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ConfirmDeleteCampaignDialog.vue';
import ZaloOaCampaignEmptyState from 'dashboard/components-next/Campaigns/EmptyState/ZaloOaCampaignEmptyState.vue';
import EditZaloOaCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ZaloOa/EditZaloOaCampaignDialog.vue';

const { t } = useI18n();
const getters = useStoreGetters();

const selectedCampaign = ref(null);
const [showZaloOaCampaignDialog, toggleZaloOaCampaignDialog] = useToggle();

const uiFlags = useMapGetter('campaigns/getUIFlags');
const isFetchingCampaigns = computed(() => uiFlags.value.isFetching);

const confirmDeleteCampaignDialogRef = ref(null);
const editZaloOaCampaignDialogRef = ref(null);

const ZaloOaCampaigns = computed(
  () => getters['campaigns/getZaloOaCampaigns'].value
);

const hasNoZaloOaCampaigns = computed(
  () => ZaloOaCampaigns.value?.length === 0 && !isFetchingCampaigns.value
);

const handleDelete = campaign => {
  selectedCampaign.value = campaign;
  confirmDeleteCampaignDialogRef.value.dialogRef.open();
};

const handleEdit = campaign => {
  selectedCampaign.value = campaign;
  editZaloOaCampaignDialogRef.value.dialogRef.open();
};
</script>

<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.ZALO_OA.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.ZALO_OA.NEW_CAMPAIGN')"
    @click="toggleZaloOaCampaignDialog()"
    @close="toggleZaloOaCampaignDialog(false)"
  >
    <template #action>
      <ZaloOaCampaignDialog
        v-if="showZaloOaCampaignDialog"
        @close="toggleZaloOaCampaignDialog(false)"
      />
    </template>
    <div
      v-if="isFetchingCampaigns"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <CampaignList
      v-else-if="!hasNoZaloOaCampaigns"
      :campaigns="ZaloOaCampaigns"
      @delete="handleDelete"
      @edit="handleEdit"
    />
    <ZaloOaCampaignEmptyState
      v-else
      :title="t('CAMPAIGN.ZALO_OA.EMPTY_STATE.TITLE')"
      :subtitle="t('CAMPAIGN.ZALO_OA.EMPTY_STATE.SUBTITLE')"
      class="pt-14"
    />
    <ConfirmDeleteCampaignDialog
      ref="confirmDeleteCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
    <EditZaloOaCampaignDialog
      ref="editZaloOaCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
  </CampaignLayout>
</template>
