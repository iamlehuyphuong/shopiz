<script setup>
import { computed, ref } from 'vue';
import { useI18n } from 'vue-i18n';
import { useToggle } from '@vueuse/core';
import { useStoreGetters, useMapGetter } from 'dashboard/composables/store';

import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import CampaignLayout from 'dashboard/components-next/Campaigns/CampaignLayout.vue';
import CampaignList from 'dashboard/components-next/Campaigns/Pages/CampaignPage/CampaignList.vue';
import FacebookCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/FacebookCampaign/FacebookCampaignDialog.vue';
import ConfirmDeleteCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/ConfirmDeleteCampaignDialog.vue';
import FacebookCampaignEmptyState from 'dashboard/components-next/Campaigns/EmptyState/FacebookCampaignEmptyState.vue';
import EditFacebookCampaignDialog from 'dashboard/components-next/Campaigns/Pages/CampaignPage/FacebookCampaign/EditFacebookCampaignDialog.vue';

const { t } = useI18n();
const getters = useStoreGetters();

const selectedCampaign = ref(null);
const [showFacebookCampaignDialog, toggleFacebookCampaignDialog] = useToggle();

const uiFlags = useMapGetter('campaigns/getUIFlags');
const isFetchingCampaigns = computed(() => uiFlags.value.isFetching);

const confirmDeleteCampaignDialogRef = ref(null);
const editFacebookCampaignDialogRef = ref(null);

const facebookCampaigns = computed(
  () => getters['campaigns/getFacebookCampaigns'].value
);

const hasNoFacebookCampaigns = computed(
  () => facebookCampaigns.value?.length === 0 && !isFetchingCampaigns.value
);

const handleDelete = campaign => {
  selectedCampaign.value = campaign;
  confirmDeleteCampaignDialogRef.value.dialogRef.open();
};

const handleEdit = campaign => {
  selectedCampaign.value = campaign;
  editFacebookCampaignDialogRef.value.dialogRef.open();
};
</script>

<template>
  <CampaignLayout
    :header-title="t('CAMPAIGN.FACEBOOK.HEADER_TITLE')"
    :button-label="t('CAMPAIGN.FACEBOOK.NEW_CAMPAIGN')"
    @click="toggleFacebookCampaignDialog()"
    @close="toggleFacebookCampaignDialog(false)"
  >
    <template #action>
      <FacebookCampaignDialog
        v-if="showFacebookCampaignDialog"
        @close="toggleFacebookCampaignDialog(false)"
      />
    </template>
    <div
      v-if="isFetchingCampaigns"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>
    <CampaignList
      v-else-if="!hasNoFacebookCampaigns"
      :campaigns="facebookCampaigns"
      is-facebook-type
      @delete="handleDelete"
      @edit="handleEdit"
    />
    <FacebookCampaignEmptyState
      v-else
      :title="t('CAMPAIGN.FACEBOOK.EMPTY_STATE.TITLE')"
      :subtitle="t('CAMPAIGN.FACEBOOK.EMPTY_STATE.SUBTITLE')"
      class="pt-14"
    />
    <ConfirmDeleteCampaignDialog
      ref="confirmDeleteCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
    <EditFacebookCampaignDialog
      ref="editFacebookCampaignDialogRef"
      :selected-campaign="selectedCampaign"
    />
  </CampaignLayout>
</template>
