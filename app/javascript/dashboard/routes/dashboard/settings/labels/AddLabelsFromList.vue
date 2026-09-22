<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'vuex';
import { useI18n } from 'vue-i18n';
import { predefinedLabels } from './predefinedLabels';
import { useCaptain } from 'dashboard/composables/useCaptain';
import { useAlert } from 'dashboard/composables';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Switch from 'dashboard/components-next/switch/Switch.vue';

const emit = defineEmits(['close']);

const store = useStore();
const { t, locale } = useI18n();
const { processEvent, captainEnabled } = useCaptain();

const isLoading = ref(false);
const isTranslationEnabled = ref(false);
const targetLanguage = ref('');
const selectedLabels = ref([]);

const existingLabels = computed(() => store.getters['labels/getLabels']);

// We default to 'en' if locale is not 'vi'
const currentLocaleList = computed(() => {
  return predefinedLabels[locale.value] || predefinedLabels.en;
});

const isLabelSelected = label => {
  return selectedLabels.value.some(l => l.title === label.title);
};

const isLabelExisting = label => {
  return existingLabels.value.some(l => l.title === label.title);
};

const toggleLabel = label => {
  if (isLabelExisting(label)) return;
  const index = selectedLabels.value.findIndex(l => l.title === label.title);
  if (index > -1) {
    selectedLabels.value.splice(index, 1);
  } else {
    selectedLabels.value.push(label);
  }
};

const onClose = () => {
  emit('close');
};

const handleConfirm = async () => {
  if (selectedLabels.value.length === 0) {
    useAlert(
      t(
        'LABEL_MGMT.ADD_FROM_LIST.NO_LABELS_SELECTED',
        'Vui lòng chọn ít nhất một nhãn.'
      )
    );
    return;
  }

  isLoading.value = true;
  try {
    let labelsToCreate = [...selectedLabels.value];

    // If target language is provided and translation is enabled, call AI to translate
    if (
      isTranslationEnabled.value &&
      captainEnabled.value &&
      targetLanguage.value.trim() !== ''
    ) {
      const payload = JSON.stringify(labelsToCreate);
      const instruction = `Translate the 'title' and 'description' of these labels to ${targetLanguage.value.trim()}. Return ONLY a valid JSON array of objects with 'title', 'description', 'color', 'show_on_sidebar'. Payload: ${payload}`;

      const { message } = await processEvent('translate_labels', instruction);
      if (message) {
        try {
          // Attempt to parse the AI response as JSON
          const translatedLabels = JSON.parse(message);
          if (Array.isArray(translatedLabels)) {
            labelsToCreate = translatedLabels;
          }
        } catch (e) {
          console.error('Failed to parse AI translated labels', e);
          useAlert(
            t(
              'LABEL_MGMT.ADD_FROM_LIST.AI_ERROR',
              'Lỗi khi dịch nhãn. Sẽ sử dụng nhãn mặc định.'
            )
          );
        }
      }
    }

    // Create labels iteratively
    const promises = labelsToCreate.map(label =>
      store.dispatch('labels/create', {
        title: label.title,
        description: label.description,
        color: label.color,
        show_on_sidebar: label.show_on_sidebar,
      })
    );

    await Promise.all(promises);
    useAlert(t('LABEL_MGMT.ADD.API.SUCCESS_MESSAGE'));
    onClose();
  } catch (error) {
    const errorMessage = error.message || t('LABEL_MGMT.ADD.API.ERROR_MESSAGE');
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
        $t('LABEL_MGMT.ADD_FROM_LIST.TITLE', 'Thêm nhãn từ danh sách')
      "
      :header-content="
        $t(
          'LABEL_MGMT.ADD_FROM_LIST.DESC',
          'Chọn các nhãn có sẵn để thêm vào hệ thống của bạn.'
        )
      "
    />

    <div class="flex flex-col mx-0 px-8 pb-8 pt-6 gap-6">
      <!-- Label List -->
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
              v-for="(label, labelIndex) in group.labels"
              :key="labelIndex"
              class="flex items-center p-3 rounded-md gap-3"
              :class="
                isLabelExisting(label)
                  ? 'opacity-60 cursor-not-allowed bg-n-alpha-1'
                  : 'cursor-pointer bg-n-alpha-1 hover:bg-n-alpha-2'
              "
            >
              <input
                type="checkbox"
                :checked="isLabelSelected(label) || isLabelExisting(label)"
                :disabled="isLabelExisting(label)"
                @change="toggleLabel(label)"
              />
              <span
                class="w-3 h-3 rounded-full border border-n-weak flex-shrink-0"
                :style="{ backgroundColor: label.color }"
              />
              <span
                class="text-body-main text-n-slate-12 font-medium whitespace-nowrap"
                >{{ label.title }}</span>
              <span class="text-body-main text-n-slate-11 truncate">- {{ label.description }}</span>
              <span
                v-if="isLabelExisting(label)"
                class="ml-auto px-2 py-0.5 text-xs bg-n-slate-3 text-n-slate-11 rounded font-medium flex-shrink-0"
              >
                {{ $t('LABEL_MGMT.ADD_FROM_LIST.ALREADY_ADDED', 'Đã thêm') }}
              </span>
            </label>
          </div>
        </div>
      </div>

      <div class="flex flex-col gap-4 mt-2">
        <!-- AI Translation Input -->
        <div class="flex flex-col gap-3">
          <div class="flex items-center gap-3">
            <Switch
              v-model="isTranslationEnabled"
              :disabled="!captainEnabled"
            />
            <label class="text-body-main font-medium text-n-slate-12 m-0">
              {{
                $t(
                  'LABEL_MGMT.ADD_FROM_LIST.TRANSLATE_LABEL',
                  'Dịch sang ngôn ngữ khác'
                )
              }}
              <span
                v-if="!captainEnabled"
                class="text-n-slate-11 font-normal text-body-small ml-1"
                >{{
                  $t(
                    'LABEL_MGMT.ADD_FROM_LIST.AI_KEY_REQUIRED',
                    '(Cần cài đặt AI Key)'
                  )
                }}</span>
            </label>
          </div>
          <woot-input
            v-if="isTranslationEnabled"
            v-model="targetLanguage"
            class="w-full !mb-0"
            :placeholder="
              $t(
                'LABEL_MGMT.ADD_FROM_LIST.TRANSLATE_PLACEHOLDER',
                'Nhập ngôn ngữ, vd: Tiếng Nhật, Thái Lan...'
              )
            "
          />
        </div>

        <!-- Actions -->
        <div class="flex items-center justify-end w-full gap-2">
          <NextButton
            faded
            slate
            :label="$t('LABEL_MGMT.ADD_FROM_LIST.CANCEL', 'Hủy')"
            @click.prevent="onClose"
          />
          <NextButton
            data-testid="label-list-submit"
            :label="$t('LABEL_MGMT.ADD_FROM_LIST.SUBMIT', 'Thêm mới')"
            :disabled="selectedLabels.length === 0 || isLoading"
            :is-loading="isLoading"
            @click.prevent="handleConfirm"
          />
        </div>
      </div>
    </div>
  </div>
</template>
