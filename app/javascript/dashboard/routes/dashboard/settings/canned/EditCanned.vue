<script setup>
import { ref, computed } from 'vue';
import { useVuelidate } from '@vuelidate/core';
import { required, minLength } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useCaptain } from 'dashboard/composables/useCaptain';

import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import Modal from '../../../../components/Modal.vue';
import WootMessageEditor from 'dashboard/components/widgets/WootWriter/Editor.vue';

const props = defineProps({
  id: { type: Number, default: null },
  edcontent: { type: String, default: '' },
  edshortCode: { type: String, default: '' },
  existingFiles: { type: Array, default: () => [] },
  onClose: { type: Function, default: () => {} },
});

const MAX_FILES = 5;

const store = useStore();
const { t } = useI18n();

const shortCode = ref(props.edshortCode);
const content = ref(props.edcontent);
const show = ref(true);
const showLoading = ref(false);
const newFiles = ref([]);
const removedFileIds = ref([]);

const rules = {
  shortCode: { required, minLength: minLength(2) },
  content: { required },
};
const v$ = useVuelidate(rules, { shortCode, content });

const { processEvent } = useCaptain();
const isImproving = ref(false);

const pageTitle = computed(
  () => `${t('CANNED_MGMT.EDIT.TITLE')} - ${props.edshortCode}`
);

const remainingFiles = computed(() =>
  props.existingFiles.filter(f => !removedFileIds.value.includes(f.id))
);

const totalFileCount = computed(
  () => remainingFiles.value.length + newFiles.value.length
);

const fileButtonLabel = computed(() => {
  if (totalFileCount.value) {
    return `${totalFileCount.value} / ${MAX_FILES}`;
  }
  return t('CANNED_MGMT.EDIT.ATTACHMENTS.BUTTON');
});

function isImageType(contentType) {
  return contentType?.startsWith('image/');
}

function onFilesSelected(e) {
  const files = Array.from(e.target.files);
  if (totalFileCount.value + files.length > MAX_FILES) {
    useAlert(t('CANNED_MGMT.ADD.ATTACHMENTS.LIMIT_ERROR'));
    return;
  }
  files.forEach(file => {
    const preview = isImageType(file.type) ? URL.createObjectURL(file) : null;
    newFiles.value.push({ file, preview, type: file.type });
  });
  e.target.value = '';
}

function removeExistingFile(fileId) {
  removedFileIds.value.push(fileId);
}

function removeNewFile(idx) {
  const removed = newFiles.value.splice(idx, 1);
  if (removed[0]?.preview) URL.revokeObjectURL(removed[0].preview);
}

function resetForm() {
  shortCode.value = '';
  content.value = '';
  newFiles.value = [];
  removedFileIds.value = [];
  v$.value.shortCode.$reset();
  v$.value.content.$reset();
}

async function improveMessage() {
  if (!content.value) return;
  isImproving.value = true;
  try {
    const { message } = await processEvent(
      'improve_canned_response_message',
      content.value
    );
    if (message) content.value = message;
  } finally {
    isImproving.value = false;
  }
}

async function editCannedResponse() {
  showLoading.value = true;
  try {
    const payload = {
      id: props.id,
      short_code: shortCode.value,
      content: content.value,
    };
    if (newFiles.value.length) {
      payload.files = newFiles.value.map(f => f.file);
    }
    if (removedFileIds.value.length) {
      payload.removed_file_ids = removedFileIds.value;
    }
    await store.dispatch('updateCannedResponse', payload);
    showLoading.value = false;
    useAlert(t('CANNED_MGMT.EDIT.API.SUCCESS_MESSAGE'));
    resetForm();
    setTimeout(() => props.onClose(), 10);
  } catch (error) {
    showLoading.value = false;
    const errorMessage =
      error?.message || t('CANNED_MGMT.EDIT.API.ERROR_MESSAGE');
    useAlert(errorMessage);
  }
}
</script>

<template>
  <Modal v-model:show="show" :on-close="onClose">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="pageTitle" />
      <form class="flex flex-col w-full" @submit.prevent="editCannedResponse()">
        <div class="w-full">
          <label :class="{ error: v$.shortCode.$error }">
            {{ $t('CANNED_MGMT.EDIT.FORM.SHORT_CODE.LABEL') }}
            <input
              v-model="shortCode"
              type="text"
              :placeholder="$t('CANNED_MGMT.EDIT.FORM.SHORT_CODE.PLACEHOLDER')"
              @input="v$.shortCode.$touch"
            />
          </label>
        </div>

        <div class="w-full">
          <label :class="{ error: v$.content.$error }">
            {{ $t('CANNED_MGMT.EDIT.FORM.CONTENT.LABEL') }}
          </label>
          <div class="flex flex-col gap-1 w-full">
            <div class="editor-wrap">
              <WootMessageEditor
                v-model="content"
                class="message-editor [&>div]:px-1"
                :class="{ editor_warning: v$.content.$error }"
                channel-type="Context::Default"
                enable-variables
                :enable-canned-responses="false"
                :placeholder="$t('CANNED_MGMT.EDIT.FORM.CONTENT.PLACEHOLDER')"
                @blur="v$.content.$touch"
              />
            </div>
            <div class="flex justify-start mb-2">
              <NextButton
                icon="i-lucide-wand-2"
                size="xs"
                color="slate"
                :label="
                  $t('TEAMS_SETTINGS.FORM.IMPROVE_BY_AI', 'Improve by AI')
                "
                :is-loading="isImproving"
                @click.prevent="improveMessage"
              />
            </div>
          </div>
        </div>

        <div class="w-full mt-3">
          <label>{{ $t('CANNED_MGMT.EDIT.ATTACHMENTS.LABEL') }}</label>
          <label
            class="inline-flex items-center gap-1.5 px-3 py-1.5 text-sm font-medium rounded-lg cursor-pointer transition-colors bg-n-alpha-2 text-n-slate-12 hover:bg-n-alpha-3 border border-n-weak"
            :class="{
              'opacity-50 pointer-events-none': totalFileCount >= MAX_FILES,
            }"
          >
            <Icon icon="i-ph-paperclip" class="size-4" />
            {{ fileButtonLabel }}
            <input
              type="file"
              multiple
              accept="image/*,video/*,audio/*,application/pdf,.doc,.docx,.xls,.xlsx,.csv,.txt,.zip,.rar"
              class="hidden"
              :disabled="totalFileCount >= MAX_FILES"
              @change="onFilesSelected"
            />
          </label>
          <div
            v-if="remainingFiles.length || newFiles.length"
            class="flex flex-wrap gap-2 mt-2"
          >
            <!-- Existing files from server -->
            <div
              v-for="file in remainingFiles"
              :key="'existing-' + file.id"
              class="relative group"
            >
              <img
                v-if="isImageType(file.content_type)"
                :src="file.url"
                class="size-16 object-cover rounded-lg border border-n-weak"
              />
              <div
                v-else
                class="size-16 rounded-lg border border-n-weak bg-n-slate-2 flex items-center justify-center"
              >
                <Icon icon="i-lucide-file" class="size-5 text-n-slate-11" />
              </div>
              <button
                type="button"
                class="absolute -top-2 -right-2 bg-n-ruby-9 text-white rounded-full w-5 h-5 p-0 border-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
                @click="removeExistingFile(file.id)"
              >
                <span class="text-xs leading-none font-bold mb-[1px]">&times;</span>
              </button>
              <p class="text-xs text-n-slate-10 truncate w-16 mt-0.5">
                {{ file.filename }}
              </p>
            </div>
            <!-- Newly added files -->
            <div
              v-for="(item, idx) in newFiles"
              :key="'new-' + idx"
              class="relative group"
            >
              <img
                v-if="item.preview"
                :src="item.preview"
                class="size-16 object-cover rounded-lg border border-n-weak"
              />
              <div
                v-else
                class="size-16 rounded-lg border border-n-weak bg-n-slate-2 flex items-center justify-center"
              >
                <Icon icon="i-lucide-file" class="size-5 text-n-slate-11" />
              </div>
              <button
                type="button"
                class="absolute -top-2 -right-2 bg-n-ruby-9 text-white rounded-full w-5 h-5 p-0 border-0 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity"
                @click="removeNewFile(idx)"
              >
                <span class="text-xs leading-none font-bold mb-[1px]">&times;</span>
              </button>
              <p class="text-xs text-n-slate-10 truncate w-16 mt-0.5">
                {{ item.file.name }}
              </p>
            </div>
          </div>
        </div>

        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <NextButton
            faded
            slate
            type="reset"
            :label="$t('CANNED_MGMT.EDIT.CANCEL_BUTTON_TEXT')"
            @click.prevent="onClose"
          />
          <NextButton
            type="submit"
            :label="$t('CANNED_MGMT.EDIT.FORM.SUBMIT')"
            :disabled="
              v$.content.$invalid || v$.shortCode.$invalid || showLoading
            "
            :is-loading="showLoading"
          />
        </div>
      </form>
    </div>
  </Modal>
</template>

<style scoped lang="scss">
::v-deep {
  .ProseMirror-menubar {
    @apply hidden;
  }

  .ProseMirror-woot-style {
    @apply min-h-[12.5rem];

    p {
      @apply text-sm;
    }
  }
}
</style>
