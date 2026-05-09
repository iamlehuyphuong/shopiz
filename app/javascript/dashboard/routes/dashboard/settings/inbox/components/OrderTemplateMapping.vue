<script setup>
import { ref, computed, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import ZaloMessageTemplatesAPI from 'dashboard/api/zaloMessageTemplates';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Input from 'dashboard/components-next/input/Input.vue';
import SelectInput from 'dashboard/components-next/select/Select.vue';
import Spinner from 'dashboard/components-next/spinner/Spinner.vue';

const props = defineProps({
  inbox: {
    type: Object,
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const ORDER_STATUSES = [
  'draft',
  'pending_confirmation',
  'confirmed',
  'processing',
  'ready_for_pickup',
  'picking_up',
  'delivering',
  'delivered',
  'cancelled',
  'returned',
];

const STATUS_LABELS = {
  draft: 'Nháp (Draft)',
  pending_confirmation: 'Chờ xác nhận',
  confirmed: 'Đã xác nhận',
  processing: 'Đang xử lý',
  ready_for_pickup: 'Chờ lấy hàng',
  picking_up: 'Đang lấy hàng',
  delivering: 'Đang giao hàng',
  delivered: 'Đã giao hàng',
  cancelled: 'Đã huỷ',
  returned: 'Đã trả hàng',
};

const mappings = ref({});
const isSaving = ref(false);
const isLoadingTemplates = ref(false);
const zaloTemplates = ref([]);

const isWhatsApp = computed(() => props.inbox.channel_type === 'Channel::Whatsapp');
const isZaloOA = computed(() => props.inbox.channel_type === 'Channel::ZaloOa');

const fetchZaloTemplates = async () => {
  if (!isZaloOA.value || !props.inbox.channel_id) return;
  isLoadingTemplates.value = true;
  try {
    const response = await ZaloMessageTemplatesAPI.getByChannel(props.inbox.channel_id);
    zaloTemplates.value = response.data;
  } catch (error) {
    useAlert(t('INBOX_MGMT.ZALO_TEMPLATES.API.FETCH_ERROR'));
  } finally {
    isLoadingTemplates.value = false;
  }
};

onMounted(() => {
  const currentMappings = props.inbox.settings?.order_template_mapping || {};
  ORDER_STATUSES.forEach(status => {
    mappings.value[status] = currentMappings[status] || '';
  });
  fetchZaloTemplates();
});

const templateOptions = computed(() => {
  const options = [{ value: '', label: 'Không gửi / Sử dụng văn bản mặc định' }];
  zaloTemplates.value.forEach(tpl => {
    options.push({ value: String(tpl.template_id), label: `${tpl.template_name} (${tpl.template_id})` });
  });
  return options;
});

const handleSave = async () => {
  isSaving.value = true;
  try {
    await store.dispatch('inboxes/updateInbox', {
      id: props.inbox.id,
      formData: false,
      settings: {
        ...props.inbox.settings,
        order_template_mapping: mappings.value,
      },
    });
    useAlert(t('INBOX_MGMT.EDIT.API.SUCCESS_MESSAGE'));
  } catch (error) {
    useAlert(error.message || t('INBOX_MGMT.EDIT.API.ERROR_MESSAGE'));
  } finally {
    isSaving.value = false;
  }
};
</script>

<template>
  <div class="max-w-4xl mx-6">
    <div class="flex flex-col gap-6">
      <div class="flex flex-col gap-1">
        <h3 class="text-lg font-semibold text-n-slate-12">
          Ánh xạ Mẫu tin nhắn Đơn hàng
        </h3>
        <p class="text-sm text-n-slate-11">
          Cấu hình Mẫu tin nhắn ZNS hoặc WhatsApp tương ứng với từng trạng thái đơn hàng. Nếu để trống, hệ thống sẽ sử dụng Mẫu văn bản cấu hình trong Bán hàng.
        </p>
      </div>

      <div v-if="isLoadingTemplates" class="flex items-center justify-center py-10">
        <Spinner />
      </div>

      <div v-else class="flex flex-col gap-4">
        <div v-for="status in ORDER_STATUSES" :key="status" class="flex flex-col gap-1.5">
          <label class="text-sm font-medium text-n-slate-12">{{ STATUS_LABELS[status] }}</label>
          
          <SelectInput
            v-if="isZaloOA"
            v-model="mappings[status]"
            :options="templateOptions"
          />
          
          <Input
            v-else
            v-model="mappings[status]"
            placeholder="Nhập Tên Template WhatsApp"
          />
        </div>
      </div>

      <div class="flex justify-end pt-2">
        <NextButton
          label="Lưu cấu hình"
          :is-loading="isSaving"
          @click="handleSave"
        />
      </div>
    </div>
  </div>
</template>
