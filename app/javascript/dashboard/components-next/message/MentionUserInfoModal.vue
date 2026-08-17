<script setup>
import { ref, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import NextButton from 'dashboard/components-next/button/Button.vue';
import ZaloPersonalChannel from 'dashboard/api/channel/zalopersonalChannel';
import Spinner from 'shared/components/Spinner.vue';

const props = defineProps({
  uid: { type: [String, Number], required: true },
  inboxId: { type: [String, Number], required: true },
  show: { type: Boolean, default: false },
});

const emit = defineEmits(['close', 'update:show']);
const { t } = useI18n();

const isLoading = ref(true);
const error = ref(null);
const zaloProfile = ref({});

const closeModal = () => {
  emit('update:show', false);
  emit('close');
};

const fetchUserInfo = async () => {
  if (!props.uid || !props.inboxId) return;

  isLoading.value = true;
  error.value = null;

  try {
    const response = await ZaloPersonalChannel.getUserInfo({
      uid: props.uid,
      inboxId: props.inboxId,
    });

    zaloProfile.value = response.data?.data || {};
  } catch (err) {
    error.value =
      err?.response?.data?.error ||
      t('CONTACT_PANEL.ZALO_PERSONAL.FETCH_USER_INFO_FAILED');
  } finally {
    isLoading.value = false;
  }
};

onMounted(() => {
  if (props.show) {
    fetchUserInfo();
  }
});

watch(
  () => props.show,
  newVal => {
    if (newVal) {
      fetchUserInfo();
    }
  }
);

watch(
  () => props.uid,
  () => {
    if (props.show) {
      fetchUserInfo();
    }
  }
);
</script>

<template>
  <teleport to="body">
    <woot-modal :show="show" :on-close="closeModal" :show-close-button="false">
      <div
        class="flex flex-col h-auto w-full sm:w-[600px] max-w-full relative bg-white dark:bg-slate-800 rounded-xl overflow-hidden"
      >
        <div
          class="px-6 py-4 flex items-center justify-between border-b border-slate-200 dark:border-slate-700 bg-white dark:bg-slate-800 sticky top-0 z-20"
        >
          <div class="text-lg font-semibold text-slate-900 dark:text-slate-50">
            {{ $t('CONTACT_PANEL.ZALO_PERSONAL.ZALO_ACCOUNT_INFO') }}
          </div>
          <NextButton
            ghost
            slate
            icon="i-lucide-x"
            class="!m-0 !p-1 -mr-2"
            @click.prevent="closeModal"
          />
        </div>

        <div v-if="isLoading" class="p-8 flex justify-center items-center">
          <Spinner size="lg" />
        </div>

        <div v-else-if="error" class="p-8 text-center text-red-500">
          {{ error }}
        </div>

        <template v-else>
          <div
            class="relative bg-white dark:bg-slate-800 border-b border-slate-200 dark:border-slate-700 pb-4"
          >
            <div class="h-[140px] w-full">
              <img
                :src="
                  zaloProfile.cover ||
                  'https://images.unsplash.com/photo-1579546929518-9e396f3cc809?w=600&h=200&fit=crop'
                "
                class="w-full h-full object-cover"
              />
            </div>
            <div class="flex items-end px-6 -mt-12 relative z-10">
              <div
                class="w-24 h-24 rounded-full border-4 border-white dark:border-slate-800 overflow-hidden bg-slate-200 dark:bg-slate-700 shrink-0"
              >
                <img
                  :src="zaloProfile.avatar || 'https://i.pravatar.cc/150?img=5'"
                  class="w-full h-full object-cover"
                />
              </div>
              <div class="ml-4 pb-2">
                <h3
                  class="text-xl font-semibold text-slate-900 dark:text-slate-50 m-0 flex items-center gap-2"
                >
                  {{
                    zaloProfile.name ||
                    $t('CONTACT_PANEL.ZALO_PERSONAL.ZALO_USER')
                  }}
                </h3>
              </div>
            </div>
          </div>

          <div class="px-6 py-4 bg-white dark:bg-slate-800">
            <div class="flex items-center justify-between mb-4">
              <h4
                class="font-semibold text-base text-slate-900 dark:text-slate-50"
              >
                {{ $t('CONTACT_PANEL.ZALO_PERSONAL.PERSONAL_INFO') }}
              </h4>
              <div
                v-if="zaloProfile.is_friend"
                class="flex items-center gap-1.5 text-green-600 font-medium text-sm bg-green-50 px-3 py-1 rounded-lg"
              >
                <fluent-icon icon="checkmark-circle" size="16" />
                {{ $t('CONTACT_PANEL.ZALO_PERSONAL.ALREADY_FRIEND') }}
              </div>
            </div>

            <div class="grid grid-cols-[100px_1fr] gap-x-2 gap-y-3 text-sm">
              <div class="text-slate-500 dark:text-slate-400">
                {{ $t('CONTACT_PANEL.ZALO_PERSONAL.BIO') }}
              </div>
              <div
                class="text-slate-900 dark:text-slate-100 whitespace-pre-line"
              >
                {{
                  zaloProfile.bio ||
                  $t('CONTACT_PANEL.ZALO_PERSONAL.NOT_UPDATED')
                }}
              </div>

              <div class="text-slate-500 dark:text-slate-400">
                {{ $t('CONTACT_PANEL.ZALO_PERSONAL.GENDER') }}
              </div>
              <div class="text-slate-900 dark:text-slate-100">
                {{
                  zaloProfile.gender ||
                  $t('CONTACT_PANEL.ZALO_PERSONAL.NOT_UPDATED')
                }}
              </div>

              <div class="text-slate-500 dark:text-slate-400">
                {{ $t('CONTACT_PANEL.ZALO_PERSONAL.DOB') }}
              </div>
              <div class="text-slate-900 dark:text-slate-100">
                {{
                  zaloProfile.dob ||
                  $t('CONTACT_PANEL.ZALO_PERSONAL.NOT_UPDATED')
                }}
              </div>
            </div>
          </div>

          <div
            class="flex items-center justify-end w-full gap-2 px-6 py-4 bg-white dark:bg-slate-800 border-t border-slate-200 dark:border-slate-700"
          >
            <NextButton
              faded
              slate
              :label="$t('CONTACT_PANEL.ZALO_PERSONAL.CLOSE')"
              @click.prevent="closeModal"
            />
          </div>
        </template>
      </div>
    </woot-modal>
  </teleport>
</template>
