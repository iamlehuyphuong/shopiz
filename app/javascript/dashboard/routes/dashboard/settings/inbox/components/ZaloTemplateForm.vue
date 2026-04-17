<script setup>
import { reactive, watch } from 'vue';
import { useI18n } from 'vue-i18n';

import Input from 'dashboard/components-next/input/Input.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';

const props = defineProps({
  mode: {
    type: String,
    required: true,
    validator: value => ['edit', 'create'].includes(value),
  },
  selectedTemplate: {
    type: Object,
    default: () => ({}),
  },
});

const emit = defineEmits(['submit', 'cancel']);
const { t } = useI18n();

const TEMPLATE_TYPE_OPTIONS = [
  { value: 'transaction_order', label: 'Thông báo đơn hàng' },
  { value: 'transaction_payment', label: 'Thông báo thanh toán' },
  { value: 'transaction_shipping', label: 'Thông báo vận chuyển' },
  { value: 'transaction_otp', label: 'Xác thực OTP' },
  { value: 'transaction_reward', label: 'Tích điểm / Voucher' },
  { value: 'promotion', label: 'Tin truyền thông' },
];

const STATUS_OPTIONS = [
  { value: 'draft', label: 'Draft' },
  { value: 'active', label: 'Active' },
  { value: 'disabled', label: 'Disabled' },
];

const state = reactive({
  template_name: '',
  template_type: 'transaction_order',
  status: 'draft',
  header: '',
  content: '',
  buttonTitle: '',
  buttonUrl: '',
});

const resetState = () => {
  state.template_name = '';
  state.template_type = 'transaction_order';
  state.status = 'draft';
  state.header = '';
  state.content = '';
  state.buttonTitle = '';
  state.buttonUrl = '';
};

const loadFromTemplate = template => {
  if (!template) return;
  state.template_name = template.template_name || '';
  state.template_type = template.template_type || 'transaction_order';
  state.status = template.status || 'draft';

  const elements = template.template_content?.elements || [];
  const headerEl = elements.find(e => e.type === 'header');
  const textEl = elements.find(e => e.type === 'text');
  const buttonEl = elements.find(e => e.type === 'button');

  state.header = headerEl?.content || '';
  state.content = textEl?.content || '';
  state.buttonTitle = buttonEl?.title || '';
  state.buttonUrl = buttonEl?.payload?.url || '';
};

watch(
  () => props.selectedTemplate,
  newVal => {
    if (props.mode === 'edit' && newVal) {
      loadFromTemplate(newVal);
    }
  },
  { immediate: true }
);

const buildPayload = () => {
  const elements = [];

  if (state.header) {
    elements.push({ type: 'header', content: state.header });
  }
  if (state.content) {
    elements.push({ type: 'text', content: state.content });
  }
  if (state.buttonTitle) {
    elements.push({
      type: 'button',
      title: state.buttonTitle,
      payload: { url: state.buttonUrl },
    });
  }

  return {
    template_name: state.template_name,
    template_type: state.template_type,
    status: state.status,
    template_content: { elements },
  };
};

const handleSubmit = () => {
  if (!state.template_name || !state.content) return;
  emit('submit', buildPayload());
  if (props.mode === 'create') resetState();
};
</script>

<template>
  <form class="flex flex-col gap-4" @submit.prevent="handleSubmit">
    <Input
      v-model="state.template_name"
      :label="t('INBOX_MGMT.ZALO_TEMPLATES.FORM.NAME.LABEL')"
      :placeholder="t('INBOX_MGMT.ZALO_TEMPLATES.FORM.NAME.PLACEHOLDER')"
    />

    <div class="flex gap-4">
      <div class="flex flex-col gap-1 flex-1">
        <label class="mb-0.5 text-sm font-medium text-n-slate-12">
          {{ t('INBOX_MGMT.ZALO_TEMPLATES.FORM.TYPE.LABEL') }}
        </label>
        <ComboBox
          v-model="state.template_type"
          :options="TEMPLATE_TYPE_OPTIONS"
          :placeholder="t('INBOX_MGMT.ZALO_TEMPLATES.FORM.TYPE.PLACEHOLDER')"
          class="[&>div>button]:bg-n-alpha-black2"
        />
      </div>
      <div class="flex flex-col gap-1 flex-1">
        <label class="mb-0.5 text-sm font-medium text-n-slate-12">
          {{ t('INBOX_MGMT.ZALO_TEMPLATES.FORM.STATUS.LABEL') }}
        </label>
        <ComboBox
          v-model="state.status"
          :options="STATUS_OPTIONS"
          class="[&>div>button]:bg-n-alpha-black2"
        />
      </div>
    </div>

    <Input
      v-model="state.header"
      :label="t('INBOX_MGMT.ZALO_TEMPLATES.FORM.HEADER.LABEL')"
      :placeholder="t('INBOX_MGMT.ZALO_TEMPLATES.FORM.HEADER.PLACEHOLDER')"
    />

    <TextArea
      v-model="state.content"
      :label="t('INBOX_MGMT.ZALO_TEMPLATES.FORM.CONTENT.LABEL')"
      :placeholder="t('INBOX_MGMT.ZALO_TEMPLATES.FORM.CONTENT.PLACEHOLDER')"
      show-character-count
    />

    <div class="flex gap-4">
      <Input
        v-model="state.buttonTitle"
        :label="t('INBOX_MGMT.ZALO_TEMPLATES.FORM.BUTTON_TITLE.LABEL')"
        :placeholder="
          t('INBOX_MGMT.ZALO_TEMPLATES.FORM.BUTTON_TITLE.PLACEHOLDER')
        "
        class="flex-1"
      />
      <Input
        v-model="state.buttonUrl"
        :label="t('INBOX_MGMT.ZALO_TEMPLATES.FORM.BUTTON_URL.LABEL')"
        :placeholder="
          t('INBOX_MGMT.ZALO_TEMPLATES.FORM.BUTTON_URL.PLACEHOLDER')
        "
        class="flex-1"
      />
    </div>

    <div class="flex items-center justify-between w-full gap-3 pt-2">
      <Button
        variant="faded"
        color="slate"
        type="button"
        :label="t('INBOX_MGMT.ZALO_TEMPLATES.FORM.CANCEL')"
        class="w-full bg-n-alpha-2 n-orange-text hover:bg-n-alpha-3"
        @click="emit('cancel')"
      />
      <Button
        :label="
          mode === 'create'
            ? t('INBOX_MGMT.ZALO_TEMPLATES.FORM.CREATE')
            : t('INBOX_MGMT.ZALO_TEMPLATES.FORM.UPDATE')
        "
        class="w-full"
        type="submit"
      />
    </div>
  </form>
</template>
