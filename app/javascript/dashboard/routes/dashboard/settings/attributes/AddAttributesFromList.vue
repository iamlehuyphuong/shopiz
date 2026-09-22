<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { predefinedAttributes } from './predefinedAttributes';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useAlert } from 'dashboard/composables';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const props = defineProps({});

const emit = defineEmits(['close']);

const store = useStore();
const { t, locale } = useI18n();
const { processEvent, captainEnabled } = useCaptain();

const isLoading = ref(false);
const isTranslationEnabled = ref(false);
const targetLanguage = ref('');
const selectedAttributes = ref([]);

const existingAttributes = computed(
  () => store.getters['attributes/getAttributes']
);

const currentLocaleList = computed(() => {
  const currentLangAttributes =
    predefinedAttributes[locale.value] || predefinedAttributes.en;
  return [
    {
      groupName: t(
        'ATTRIBUTES_MGMT.ATTRIBUTE_MODELS.CONVERSATION',
        'Hội thoại'
      ),
      model: 0,
      attributes: currentLangAttributes[0] || [],
    },
    {
      groupName: t('ATTRIBUTES_MGMT.ATTRIBUTE_MODELS.CONTACT', 'Khách hàng'),
      model: 1,
      attributes: currentLangAttributes[1] || [],
    },
  ];
});

const isAttributeSelected = (attr, modelId) => {
  return selectedAttributes.value.some(
    a => a.attribute_key === attr.attribute_key && a.attribute_model === modelId
  );
};

const isAttributeExisting = (attr, modelId) => {
  return existingAttributes.value.some(
    a =>
      a.attribute_key === attr.attribute_key &&
      a.attribute_model ===
        (modelId === 1 ? 'contact_attribute' : 'conversation_attribute')
  );
};

const toggleAttribute = (attr, modelId) => {
  if (isAttributeExisting(attr, modelId)) return;
  const attrWithModel = { ...attr, attribute_model: modelId };
  const index = selectedAttributes.value.findIndex(
    a => a.attribute_key === attr.attribute_key && a.attribute_model === modelId
  );
  if (index > -1) {
    selectedAttributes.value.splice(index, 1);
  } else {
    selectedAttributes.value.push(attrWithModel);
  }
};

const onClose = () => {
  emit('close');
};

const handleConfirm = async () => {
  if (selectedAttributes.value.length === 0) {
    useAlert(
      t(
        'ATTRIBUTES_MGMT.ADD_FROM_LIST.NO_ATTRIBUTES_SELECTED',
        'Vui lòng chọn ít nhất một thuộc tính.'
      )
    );
    return;
  }

  isLoading.value = true;
  try {
    let attributesToCreate = [...selectedAttributes.value];

    if (
      isTranslationEnabled.value &&
      captainEnabled.value &&
      targetLanguage.value.trim() !== ''
    ) {
      const payload = JSON.stringify(attributesToCreate);
      const instruction = `Translate the 'attribute_display_name', 'attribute_description', and 'attribute_values' of these attributes to ${targetLanguage.value.trim()}. Return ONLY a valid JSON array of objects with the exact same structure. Payload: ${payload}`;

      const { message } = await processEvent('translate_labels', instruction);
      if (message) {
        try {
          const translatedAttributes = JSON.parse(message);
          if (Array.isArray(translatedAttributes)) {
            attributesToCreate = translatedAttributes;
          }
        } catch (e) {
          console.error('Failed to parse AI translated attributes', e);
          useAlert('Lỗi khi dịch thuộc tính. Sẽ sử dụng thuộc tính mặc định.');
        }
      }
    }

    const promises = attributesToCreate.map(attr =>
      store.dispatch('attributes/create', {
        attribute_display_name: attr.attribute_display_name,
        attribute_description: attr.attribute_description,
        attribute_key: attr.attribute_key,
        attribute_display_type: attr.attribute_display_type,
        attribute_model: attr.attribute_model,
        attribute_values: attr.attribute_values || [],
      })
    );

    await Promise.all(promises);
    useAlert(t('ATTRIBUTES_MGMT.ADD.API.SUCCESS_MESSAGE'));
    onClose();
  } catch (error) {
    const errorMessage =
      error.message || t('ATTRIBUTES_MGMT.ADD.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  } finally {
    isLoading.value = false;
  }
};
</script>

<template>
  <div class="flex flex-col h-auto overflow-auto">
    <woot-modal-header
      :header-title="
        $t('ATTRIBUTES_MGMT.ADD_FROM_LIST.TITLE', 'Thêm từ danh sách')
      "
      :header-content="
        $t(
          'ATTRIBUTES_MGMT.ADD_FROM_LIST.DESC',
          'Chọn các thuộc tính tùy chỉnh có sẵn để thêm vào hệ thống của bạn.'
        )
      "
    />

    <div class="flex flex-col mx-0 px-8 pb-8 pt-6 gap-6">
      <div class="flex flex-col gap-6 max-h-[55vh] overflow-y-auto pr-2">
        <div
          v-for="(group, groupIndex) in currentLocaleList"
          :key="groupIndex"
          class="flex flex-col gap-3"
        >
          <h4 class="text-heading-3 text-n-slate-12 m-0">
            {{ group.groupName }}
          </h4>
          <div class="flex flex-col gap-2">
            <label
              v-for="(attr, index) in group.attributes"
              :key="index"
              class="flex items-center p-3 rounded-md gap-3"
              :class="
                isAttributeExisting(attr, group.model)
                  ? 'opacity-60 cursor-not-allowed bg-n-alpha-1'
                  : 'cursor-pointer bg-n-alpha-1 hover:bg-n-alpha-2'
              "
            >
              <input
                type="checkbox"
                :checked="
                  isAttributeSelected(attr, group.model) ||
                  isAttributeExisting(attr, group.model)
                "
                :disabled="isAttributeExisting(attr, group.model)"
                @change="toggleAttribute(attr, group.model)"
              />
              <span
                class="text-body-main text-n-slate-12 font-medium whitespace-nowrap"
                >{{ attr.attribute_display_name }}</span>
              <span class="text-body-main text-n-slate-11 truncate">- {{ attr.attribute_description }}</span>
              <span
                v-if="isAttributeExisting(attr, group.model)"
                class="ml-auto px-2 py-0.5 text-xs bg-n-slate-3 text-n-slate-11 rounded font-medium flex-shrink-0"
              >
                Đã thêm
              </span>
            </label>
          </div>
        </div>
      </div>

      <div class="flex flex-col gap-4 mt-2">
        <div class="flex flex-col gap-3">
          <div class="flex items-center gap-3">
            <Switch
              v-model="isTranslationEnabled"
              :disabled="!captainEnabled"
            />
            <label class="text-body-main font-medium text-n-slate-12 m-0">
              {{
                $t(
                  'ATTRIBUTES_MGMT.ADD_FROM_LIST.TRANSLATE_LABEL',
                  'Dịch sang ngôn ngữ khác'
                )
              }}
              <span
                v-if="!captainEnabled"
                class="text-n-slate-11 font-normal text-body-small ml-1"
                >(Cần cài đặt AI Key)</span>
            </label>
          </div>
          <woot-input
            v-if="isTranslationEnabled"
            v-model="targetLanguage"
            class="w-full !mb-0"
            :placeholder="
              $t(
                'ATTRIBUTES_MGMT.ADD_FROM_LIST.TRANSLATE_PLACEHOLDER',
                'Nhập ngôn ngữ, vd: Tiếng Nhật, Thái Lan...'
              )
            "
          />
        </div>

        <div class="flex items-center justify-end w-full gap-2">
          <NextButton
            faded
            slate
            :label="$t('ATTRIBUTES_MGMT.ADD_FROM_LIST.CANCEL', 'Hủy')"
            @click.prevent="onClose"
          />
          <NextButton
            data-testid="attribute-list-submit"
            :label="$t('ATTRIBUTES_MGMT.ADD_FROM_LIST.SUBMIT', 'Thêm mới')"
            :disabled="selectedAttributes.length === 0 || isLoading"
            :is-loading="isLoading"
            @click.prevent="handleConfirm"
          />
        </div>
      </div>
    </div>
  </div>
</template>
