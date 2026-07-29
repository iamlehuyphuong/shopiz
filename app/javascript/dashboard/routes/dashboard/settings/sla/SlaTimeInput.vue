<script>
import validations from './validations';
import { useVuelidate } from '@vuelidate/core';
import FilterSelect from 'dashboard/components-next/filter/inputs/FilterSelect.vue';

export default {
  components: {
    FilterSelect,
  },
  props: {
    threshold: {
      type: Number,
      default: null,
    },
    thresholdUnit: {
      type: String,
      default: 'Minutes',
    },
    label: {
      type: String,
      default: '',
    },
    placeholder: {
      type: String,
      default: '',
    },
  },
  emits: ['unit', 'isInValid', 'updateThreshold'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      thresholdTime: this.threshold || '',
      thresholdUnitValue: this.thresholdUnit,
    };
  },
  validations,
  computed: {
    options() {
      return [
        { value: 'Minutes', label: this.$t('DURATION_INPUT.MINUTES') },
        { value: 'Hours', label: this.$t('DURATION_INPUT.HOURS') },
        { value: 'Days', label: this.$t('DURATION_INPUT.DAYS') },
      ];
    },
    thresholdTimeErrorMessage() {
      let errorMessage = '';
      if (this.v$.thresholdTime.$error) {
        if (!this.v$.thresholdTime.numeric || !this.v$.thresholdTime.minValue) {
          errorMessage = this.$t(
            'SLA.FORM.THRESHOLD_TIME.INVALID_FORMAT_ERROR'
          );
        }
      }
      return errorMessage;
    },
  },
  watch: {
    threshold: {
      immediate: true,
      handler(value) {
        if (!Number.isNaN(value)) {
          this.thresholdTime = value;
        }
      },
    },
    thresholdUnit: {
      immediate: true,
      handler(value) {
        this.thresholdUnitValue = value;
      },
    },
  },
  methods: {
    onThresholdUnitChange() {
      this.$emit('unit', this.thresholdUnitValue);
    },
    onThresholdTimeChange() {
      this.v$.thresholdTime.$touch();
      const isInvalid = this.v$.thresholdTime.$invalid;
      this.$emit('isInValid', isInvalid);
      this.$emit(
        'updateThreshold',
        this.thresholdTime ? Number(this.thresholdTime) : null
      );
    },
  },
};
</script>

<template>
  <div class="flex items-start w-full gap-3">
    <woot-input
      v-model="thresholdTime"
      type="number"
      :class="{ error: v$.thresholdTime.$error }"
      class="flex-grow"
      :styles="{
        borderRadius: '0.75rem',
        padding: '0.375rem 0.75rem',
        fontSize: '0.875rem',
      }"
      :label="label"
      :placeholder="placeholder"
      :error="thresholdTimeErrorMessage"
      @update:model-value="onThresholdTimeChange"
    />
    <!-- the mt-7 handles the label offset -->
    <div class="mt-7">
      <FilterSelect
        v-model="thresholdUnitValue"
        :options="options"
        class="min-w-[6.5rem] [&_button]:w-full [&_button]:justify-between [&>.absolute]:w-full [&_.min-w-56]:!min-w-full [&_.min-w-56]:!w-full [&_button]:!h-[38px]"
        @update:model-value="onThresholdUnitChange"
      />
    </div>
  </div>
</template>
