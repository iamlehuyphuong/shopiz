<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import DatePicker from 'vue-datepicker-next';
import ConversationApi from 'dashboard/api/inbox/conversation';
import NextSwitch from 'dashboard/components-next/switch/Switch.vue';
import NextSelect from 'dashboard/components-next/select/Select.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    DatePicker,
    NextSwitch,
    NextSelect,
    NextButton,
  },
  props: {
    conversationId: {
      type: [Number, String],
      required: true,
    },
  },
  data() {
    return {
      selectedType: 'weeks',
      unitCount: 1,
      customDate: null,
      remindBefore: false,
      isUpdating: false,
      isEditing: false,
    };
  },
  computed: {
    ...mapGetters({
      currentChat: 'getSelectedChat',
    }),
    formattedFollowUpTime() {
      if (!this.currentChat?.follow_up_at) return '';
      const d = new Date(this.currentChat.follow_up_at);
      const time = d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
      const date = d.toLocaleDateString('vi-VN');
      return `${time} - ${date}`;
    },
    followUpTypes() {
      return [
        { value: 'custom', label: this.$t('CONVERSATION_SIDEBAR.FOLLOW_UP.TYPE_CUSTOM') },
        { value: 'weeks', label: this.$t('CONVERSATION_SIDEBAR.FOLLOW_UP.TYPE_WEEKS') },
        { value: 'months', label: this.$t('CONVERSATION_SIDEBAR.FOLLOW_UP.TYPE_MONTHS') },
        { value: 'years', label: this.$t('CONVERSATION_SIDEBAR.FOLLOW_UP.TYPE_YEARS') },
      ];
    },
    unitLabel() {
      if (this.selectedType === 'weeks') return this.$t('CONVERSATION_SIDEBAR.FOLLOW_UP.WEEKS_COUNT');
      if (this.selectedType === 'months') return this.$t('CONVERSATION_SIDEBAR.FOLLOW_UP.MONTHS_COUNT');
      if (this.selectedType === 'years') return this.$t('CONVERSATION_SIDEBAR.FOLLOW_UP.YEARS_COUNT');
      return '';
    },
    defaultDate() {
      const d = new Date();
      d.setHours(9, 0, 0, 0);
      return d;
    }
  },
  watch: {
    conversationId: {
      handler() {
        this.initializeData();
      },
      immediate: true,
    },
    'currentChat.follow_up_at': {
      handler() {
        this.initializeData();
      },
    },
  },
  methods: {
    initializeData() {
      if (this.currentChat?.follow_up_at) {
        this.selectedType = 'custom';
        this.customDate = new Date(this.currentChat.follow_up_at);
      } else {
        this.selectedType = 'weeks';
        this.unitCount = 1;
        this.customDate = null;
      }
      this.remindBefore = this.currentChat?.follow_up_remind_before === 1;
      this.isEditing = false;
    },
    disabledDate(date) {
      const yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      return date < yesterday;
    },
    calculateDate() {
      if (this.selectedType === 'custom') {
        return this.customDate;
      }
      const d = new Date();
      if (this.selectedType === 'weeks') {
        d.setDate(d.getDate() + this.unitCount * 7);
      } else if (this.selectedType === 'months') {
        d.setMonth(d.getMonth() + this.unitCount);
      } else if (this.selectedType === 'years') {
        d.setFullYear(d.getFullYear() + this.unitCount);
      }
      d.setHours(9, 0, 0, 0);
      return d;
    },
    async saveFollowUp() {
      const finalDate = this.calculateDate();
      const followUpAt = finalDate ? finalDate.toISOString() : null;
      const remindBeforeVal = this.remindBefore ? 1 : 0;

      this.isUpdating = true;
      try {
        const response = await ConversationApi.update(this.conversationId, {
          follow_up_at: followUpAt,
          follow_up_remind_before: remindBeforeVal,
        });
        this.$store.dispatch('updateConversation', response.data);
        useAlert(this.$t('CONVERSATION.FOLLOW_UP.SUCCESS'));
        this.isEditing = false;
      } catch (error) {
        useAlert(this.$t('CONVERSATION.FOLLOW_UP.ERROR'));
      } finally {
        this.isUpdating = false;
      }
    },
    cancelEdit() {
      this.isEditing = false;
      this.initializeData();
    },
    async cancelFollowUp() {
      this.isUpdating = true;
      try {
        const response = await ConversationApi.update(this.conversationId, {
          follow_up_at: null,
          follow_up_remind_before: 0,
        });
        this.$store.dispatch('updateConversation', response.data);
        useAlert(this.$t('CONVERSATION.FOLLOW_UP.SUCCESS'));
        this.initializeData();
      } catch (error) {
        useAlert(this.$t('CONVERSATION.FOLLOW_UP.ERROR'));
      } finally {
        this.isUpdating = false;
      }
    }
  },
};
</script>

<template>
  <div class="flex flex-col gap-3">
    <!-- State 1: No Follow-Up and Not Editing -->
    <div v-if="!currentChat?.follow_up_at && !isEditing" class="relative">
      <div class="flex justify-between w-full mb-1">
        <p class="m-0 text-sm text-n-slate-10">{{ $t('CONVERSATION_SIDEBAR.FOLLOW_UP.EMPTY_TEXT') }}</p>
      </div>
      <div class="flex items-center justify-end mt-1">
        <NextButton
          link
          xs
          icon="i-lucide-arrow-right"
          class="!gap-1"
          :label="$t('CONVERSATION_SIDEBAR.FOLLOW_UP.ADD_BUTTON')"
          @click="isEditing = true"
        />
      </div>
    </div>

    <!-- State 2: Active Follow-Up (View Mode) -->
    <div v-else-if="currentChat?.follow_up_at && !isEditing" class="flex flex-col gap-3">
      <div class="flex flex-col gap-1">
        <span class="text-xs font-medium text-slate-500 dark:text-slate-400">{{ $t('CONVERSATION_SIDEBAR.FOLLOW_UP.TIME_LABEL') }}</span>
        <span class="text-sm font-medium text-slate-800 dark:text-slate-200">
          {{ formattedFollowUpTime }}
        </span>
      </div>
      <div v-if="currentChat.follow_up_remind_before === 1" class="flex flex-col gap-1">
        <span class="text-xs font-medium text-slate-500 dark:text-slate-400">{{ $t('CONVERSATION_SIDEBAR.FOLLOW_UP.REMIND_LABEL') }}</span>
        <span class="text-sm font-medium text-slate-800 dark:text-slate-200">{{ $t('CONVERSATION_SIDEBAR.FOLLOW_UP.REMIND_VALUE') }}</span>
      </div>
      
      <div class="flex items-center gap-2 mt-1">
        <NextButton
          sm
          class="flex-1"
          color="slate"
          variant="outline"
          :is-loading="isUpdating"
          :label="$t('CONVERSATION_SIDEBAR.FOLLOW_UP.EDIT_BUTTON')"
          @click="isEditing = true"
        />
        <NextButton
          sm
          class="flex-1"
          color="ruby"
          variant="outline"
          :is-loading="isUpdating"
          :label="$t('CONVERSATION_SIDEBAR.FOLLOW_UP.DELETE_BUTTON')"
          @click="cancelFollowUp"
        />
      </div>
    </div>

    <!-- State 3: Editing / Creating Form -->
    <div v-else class="flex flex-col gap-2">
      <div class="flex flex-col gap-1">
        <label class="text-sm font-medium text-slate-800 dark:text-slate-200">
          {{ $t('CONVERSATION_SIDEBAR.FOLLOW_UP_PLACEHOLDER') }}
        </label>
        <NextSelect
          v-model="selectedType"
          :options="followUpTypes"
          class="!w-full h-10"
        />
      </div>

      <div v-if="selectedType !== 'custom'" class="flex flex-col gap-1">
        <label class="text-sm font-medium text-slate-800 dark:text-slate-200">
          {{ unitLabel }}
        </label>
        <input
          type="number"
          v-model.number="unitCount"
          min="1"
          class="w-full h-10 px-3 text-sm border rounded-md border-slate-200 bg-white text-slate-700 focus:outline-none focus:ring-1 focus:ring-woot-500 dark:bg-slate-900 dark:border-slate-700 dark:text-slate-200"
        />
      </div>

      <div v-if="selectedType === 'custom'" class="flex flex-col gap-1">
        <DatePicker
          v-model:value="customDate"
          type="datetime"
          confirm
          clearable
          :default-value="defaultDate"
          :placeholder="$t('CONVERSATION_SIDEBAR.FOLLOW_UP_PLACEHOLDER')"
          :disabled-date="disabledDate"
          class="w-full !mt-0"
          input-class="w-full h-10 px-3 text-sm border rounded-md border-slate-200 bg-white text-slate-700 focus:outline-none focus:ring-1 focus:ring-woot-500 dark:bg-slate-900 dark:border-slate-700 dark:text-slate-200"
        />
      </div>

      <div class="flex items-center gap-2 mt-1">
        <input type="checkbox" v-model="remindBefore" class="w-4 h-4 mt-0.5 self-start text-woot-500 rounded border-slate-300 focus:ring-woot-500 dark:border-slate-600 dark:bg-slate-900" />
        <div class="flex flex-col gap-0.5">
          <span class="text-sm font-medium text-slate-800 dark:text-slate-200">
            {{ $t('CONVERSATION_SIDEBAR.FOLLOW_UP.REMIND_BEFORE') }}
          </span>
          <span class="text-xs text-slate-500 dark:text-slate-400">
            {{ $t('CONVERSATION_SIDEBAR.FOLLOW_UP.REMIND_BEFORE_DESC') }}
          </span>
        </div>
      </div>

      <div class="flex items-center gap-2 mt-1">
        <NextButton
          sm
          class="flex-1"
          color="blue"
          :is-loading="isUpdating"
          :label="$t('CONVERSATION_SIDEBAR.FOLLOW_UP.SAVE')"
          @click="saveFollowUp"
        />
        <NextButton
          sm
          class="flex-1"
          color="slate"
          variant="outline"
          :is-loading="isUpdating"
          :label="$t('CONVERSATION_SIDEBAR.FOLLOW_UP.CANCEL')"
          @click="cancelEdit"
        />
      </div>
    </div>
  </div>
</template>
