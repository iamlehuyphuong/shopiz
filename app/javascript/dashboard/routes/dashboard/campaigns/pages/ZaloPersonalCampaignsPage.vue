<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import CampaignList from 'dashboard/components-next/Campaigns/Pages/CampaignPage/CampaignList.vue';
import ZaloPersonalCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ZaloPersonal/ZaloPersonalCampaignDialog.vue';
import ConfirmDeleteCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ConfirmDeleteCampaignDialog.vue';
import ZaloPersonalCampaignEmptyState from 'dashboard/components-next/Campaigns/EmptyState/ZaloPersonalCampaignEmptyState.vue';
import EditZaloPersonalCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ZaloPersonal/EditZaloPersonalCampaignDialog.vue';

const { t } = useI18n();
const getters = useStoreGetters();

const selectedCampaign = ref(null);
const [showZaloPersonalCampaignDialog, toggleZaloPersonalCampaignDialog] =
  useToggle();

const uiFlags = useMapGetter('campaigns/getUIFlags');
const isFetchingCampaigns = computed(() => uiFlags.value.isFetching);

const confirmDeleteCampaignDialogRef = ref(null);
const editZaloPersonalCampaignDialogRef = ref(null);

const ZaloPersonalCampaigns = computed(
  () => getters['campaigns/getZaloPersonalCampaigns'].value
);

const hasNoZaloPersonalCampaigns = computed(
  () => ZaloPersonalCampaigns.value?.length === 0 && !isFetchingCampaigns.value
);

const handleDelete = campaign => {
  selectedCampaign.value = campaign;
  confirmDeleteCampaignDialogRef.value.dialogRef.open();
};

const handleEdit = campaign => {
  selectedCampaign.value = campaign;
  editZaloPersonalCampaignDialogRef.value.dialogRef.open();
};
</script>

<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.ZALO_PERSONAL.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.ZALO_PERSONAL.NEW_CAMPAIGN')"
    @click="toggleZaloPersonalCampaignDialog()"
    @close="toggleZaloPersonalCampaignDialog(false)"
  >
    <template #action>
      <ZaloPersonalCampaignDialog
        v-if="showZaloPersonalCampaignDialog"
        @close="toggleZaloPersonalCampaignDialog(false)"
      />
    </template>
    <div
      v-if="isFetchingCampaigns"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <CampaignList
      v-else-if="!hasNoZaloPersonalCampaigns"
      :campaigns="ZaloPersonalCampaigns"
      :is-zalo-personal-type="true"
      @delete="handleDelete"
      @edit="handleEdit"
    />
    <ZaloPersonalCampaignEmptyState
      v-else
      :title="t('CAMPAIGN.ZALO_PERSONAL.EMPTY_STATE.TITLE')"
      :subtitle="t('CAMPAIGN.ZALO_PERSONAL.EMPTY_STATE.SUBTITLE')"
      class="pt-14"
    />
    <ConfirmDeleteCampaignDialog
      ref="confirmDeleteCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
    <EditZaloPersonalCampaignDialog
      ref="editZaloPersonalCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
  </CampaignLayout>
</template>
