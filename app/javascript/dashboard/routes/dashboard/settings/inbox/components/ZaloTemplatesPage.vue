<script setup>
import { ref, onMounted, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';

import ZaloMessageTemplatesAPI from 'dashboard/api/zaloMessageTemplates';
import Button from 'dashboard/components-next/button/Button.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';
import Dialog from 'dashboard/components-next/dialog/Dialog.vue';
import ZaloTemplateForm from './ZaloTemplateForm.vue';
import ZaloTemplateCard from './ZaloTemplateCard.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();

const templates = ref([]);
const isLoading = ref(false);
const selectedTemplate = ref(null);
const showCreateForm = ref(false);
const editDialogRef = ref(null);
const deleteDialogRef = ref(null);

const channelId = computed(() => props.inbox?.channel_id);

const hasTemplates = computed(() => templates.value.length > 0);

const TEMPLATE_TYPE_LABELS = {
  transaction_order: 'INBOX_MGMT.ZALO_TEMPLATES.TYPES.ORDER',
  transaction_payment: 'INBOX_MGMT.ZALO_TEMPLATES.TYPES.PAYMENT',
  transaction_shipping: 'INBOX_MGMT.ZALO_TEMPLATES.TYPES.SHIPPING',
  transaction_otp: 'INBOX_MGMT.ZALO_TEMPLATES.TYPES.OTP',
  transaction_reward: 'INBOX_MGMT.ZALO_TEMPLATES.TYPES.REWARD',
  promotion: 'INBOX_MGMT.ZALO_TEMPLATES.TYPES.PROMOTION',
};

const STATUS_COLORS = {
  draft: 'bg-n-amber-3 text-n-amber-11',
  active: 'bg-n-teal-3 text-n-teal-11',
  disabled: 'bg-n-slate-3 text-n-slate-11',
};

const fetchTemplates = async () => {
  if (!channelId.value) return;
  isLoading.value = true;
  try {
    const response = await ZaloMessageTemplatesAPI.getByChannel(
      channelId.value
    );
    templates.value = response.data;
  } catch (error) {
    useAlert(t('INBOX_MGMT.ZALO_TEMPLATES.API.FETCH_ERROR'));
  } finally {
    isLoading.value = false;
  }
};

const handleCreate = async templateData => {
  try {
    const response = await ZaloMessageTemplatesAPI.create({
      ...templateData,
      channel_id: channelId.value,
    });
    templates.value.push(response.data);
    showCreateForm.value = false;
    useAlert(t('INBOX_MGMT.ZALO_TEMPLATES.API.CREATE_SUCCESS'));
  } catch (error) {
    const msg =
      error?.response?.data?.errors?.join(', ') ||
      t('INBOX_MGMT.ZALO_TEMPLATES.API.CREATE_ERROR');
    useAlert(msg);
  }
};

const handleEdit = template => {
  selectedTemplate.value = template;
  editDialogRef.value?.open();
};

const handleUpdate = async templateData => {
  try {
    const response = await ZaloMessageTemplatesAPI.update(
      selectedTemplate.value.id,
      templateData
    );
    const index = templates.value.findIndex(
      tpl => tpl.id === selectedTemplate.value.id
    );
    if (index !== -1) templates.value[index] = response.data;
    editDialogRef.value?.close();
    useAlert(t('INBOX_MGMT.ZALO_TEMPLATES.API.UPDATE_SUCCESS'));
  } catch (error) {
    const msg =
      error?.response?.data?.errors?.join(', ') ||
      t('INBOX_MGMT.ZALO_TEMPLATES.API.UPDATE_ERROR');
    useAlert(msg);
  }
};

const confirmDelete = template => {
  selectedTemplate.value = template;
  deleteDialogRef.value?.open();
};

const handleDelete = async () => {
  try {
    await ZaloMessageTemplatesAPI.delete(selectedTemplate.value.id);
    templates.value = templates.value.filter(
      tpl => tpl.id !== selectedTemplate.value.id
    );
    deleteDialogRef.value?.close();
    useAlert(t('INBOX_MGMT.ZALO_TEMPLATES.API.DELETE_SUCCESS'));
  } catch (error) {
    useAlert(t('INBOX_MGMT.ZALO_TEMPLATES.API.DELETE_ERROR'));
  }
};

onMounted(fetchTemplates);
</script>

<template>
  <div class="flex flex-col gap-6 max-w-4xl">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h3 class="text-base font-medium text-n-slate-12">
          {{ t('INBOX_MGMT.ZALO_TEMPLATES.TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11 mt-1">
          {{ t('INBOX_MGMT.ZALO_TEMPLATES.SUBTITLE') }}
        </p>
      </div>
      <Button
        :label="t('INBOX_MGMT.ZALO_TEMPLATES.ADD_BUTTON')"
        icon="i-lucide-plus"
        @click="showCreateForm = !showCreateForm"
      />
    </div>

    <!-- Create Form (inline dropdown) -->
    <div
      v-if="showCreateForm"
      class="bg-n-alpha-3 backdrop-blur-[100px] p-6 rounded-xl border border-n-weak shadow-md"
    >
      <h4 class="text-sm font-medium text-n-slate-12 mb-4">
        {{ t('INBOX_MGMT.ZALO_TEMPLATES.CREATE_TITLE') }}
      </h4>
      <ZaloTemplateForm
        mode="create"
        @submit="handleCreate"
        @cancel="showCreateForm = false"
      />
    </div>

    <!-- Loading -->
    <div
      v-if="isLoading"
      class="flex items-center justify-center py-10 text-n-slate-11"
    >
      <Spinner />
    </div>

    <!-- Template List -->
    <div v-else-if="hasTemplates" class="flex flex-col gap-3">
      <ZaloTemplateCard
        v-for="template in templates"
        :key="template.id"
        :template="template"
        :type-labels="TEMPLATE_TYPE_LABELS"
        :status-colors="STATUS_COLORS"
        @edit="handleEdit"
        @delete="confirmDelete"
      />
    </div>

    <!-- Empty State -->
    <div
      v-else-if="!showCreateForm"
      class="flex flex-col items-center justify-center py-16 text-center"
    >
      <span class="i-lucide-file-text text-4xl text-n-slate-8 mb-3" />
      <p class="text-sm text-n-slate-11">
        {{ t('INBOX_MGMT.ZALO_TEMPLATES.EMPTY_STATE') }}
      </p>
    </div>

    <!-- Edit Dialog -->
    <Dialog
      ref="editDialogRef"
      type="edit"
      :title="t('INBOX_MGMT.ZALO_TEMPLATES.EDIT_TITLE')"
      overflow-y-auto
      @confirm="() => {}"
    >
      <ZaloTemplateForm
        mode="edit"
        :selected-template="selectedTemplate"
        @submit="handleUpdate"
        @cancel="editDialogRef?.close()"
      />
    </Dialog>

    <!-- Delete Confirmation Dialog -->
    <Dialog
      ref="deleteDialogRef"
      type="alert"
      :title="t('INBOX_MGMT.ZALO_TEMPLATES.DELETE_TITLE')"
      :message="t('INBOX_MGMT.ZALO_TEMPLATES.DELETE_CONFIRM')"
      confirm-button-variant="solid"
      confirm-button-color="ruby"
      :confirm-button-label="t('INBOX_MGMT.ZALO_TEMPLATES.DELETE_BUTTON')"
      @confirm="handleDelete"
    />
  </div>
</template>
