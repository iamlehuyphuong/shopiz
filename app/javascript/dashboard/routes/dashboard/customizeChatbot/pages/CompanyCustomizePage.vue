<script>
import CustomizeChatbotHeader from '../../../../components-next/CustomizeChatbot/CustomizeChatbotHeader.vue';

import ComboBox from '../../../../components-next/combobox/ComboBox.vue';
import Input from '../../../../components-next/input/Input.vue';
import TextArea from '../../../../components-next/textarea/TextArea.vue';

export default {
  components: { CustomizeChatbotHeader, ComboBox, Input, TextArea },
  methods: {
    updateSettings() {
      // TODO: Update settings
    },
  },
};
</script>

<template>
  <div class="w-full h-full bg-white dark:bg-slate-900 dark:border-~slate-800/50">
    <CustomizeChatbotHeader :title="$t('CUSTOMIZE_CHATBOT_COMPANY.TITLE')"
      :button-text="$t('CUSTOMIZE_CHATBOT_COMPANY.BUTTON')" @button-click="updateSettings" />
    <!-- #Company Name -->
    <div class="border-b-[0.5px] border-light-neutral-stroke-bold dark:border-black-neutral-stroke-bold py-6">
      <div class="grid grid-cols-12 gap-4 px-6 pb-5">
        <div class="col-span-4">
          <p class="text-base font-semibold">
            {{ $t('CUSTOMIZE_CHATBOT_COMPANY.COMPANY_NAME.LABEL') }}
          </p>
          <span class="text-sm">
            {{ $t('CUSTOMIZE_CHATBOT_COMPANY.COMPANY_NAME.DESCRIPTION') }}
          </span>
        </div>
        <div class="col-span-8">
          <Input type="text" customInputClass="h-12" :placeholder="$t('CUSTOMIZE_CHATBOT_COMPANY.COMPANY_NAME.PLACEHOLDER')
            " />
        </div>
      </div>
    </div>

    <!-- #Company description -->
    <div class="border-b-[0.5px] border-light-neutral-stroke-bold dark:border-black-neutral-stroke-bold py-6">
      <div class="grid grid-cols-12 gap-4 px-6 pb-5">
        <div class="col-span-4">
          <p class="text-base font-semibold">
            {{ $t('CUSTOMIZE_CHATBOT_COMPANY.COMPANY_DESCRIPTION.LABEL') }}
          </p>
          <span class="text-sm">
            {{
              $t('CUSTOMIZE_CHATBOT_COMPANY.COMPANY_DESCRIPTION.DESCRIPTION')
            }}
          </span>
        </div>
        <div class="col-span-8">
          <TextArea custom-text-area-wrapper-class="bg-transparent" custom-text-area-class="h-40" :placeholder="$t('CUSTOMIZE_CHATBOT_COMPANY.COMPANY_DESCRIPTION.PLACEHOLDER')
            " />
        </div>
      </div>
    </div>

    <!-- #Phone number -->
    <div class="border-b-[0.5px] border-light-neutral-stroke-bold dark:border-black-neutral-stroke-bold py-6">
      <div class="grid grid-cols-12 gap-4 px-6 pb-5">
        <div class="col-span-4">
          <p class="text-base font-semibold">
            {{ $t('CUSTOMIZE_CHATBOT_COMPANY.PHONE_NUMBER.LABEL') }}
          </p>
          <span class="text-sm">
            {{ $t('CUSTOMIZE_CHATBOT_COMPANY.PHONE_NUMBER.DESCRIPTION') }}
          </span>
        </div>
        <div class="col-span-8">
          <Input type="text" customInputClass="h-12" :placeholder="$t('CUSTOMIZE_CHATBOT_COMPANY.PHONE_NUMBER.PLACEHOLDER')
            " />
        </div>
      </div>
    </div>

    <!-- #Address -->
    <div class="border-b-[0.5px] border-light-neutral-stroke-bold dark:border-black-neutral-stroke-bold py-6">
      <div class="grid grid-cols-12 gap-4 px-6 pb-5">
        <!-- Label -->
        <div class="col-span-4">
          <p class="text-base font-semibold">
            {{ $t('CUSTOMIZE_CHATBOT_COMPANY.ADDRESS.LABEL') }}
          </p>
          <span class="text-sm">
            {{ $t('CUSTOMIZE_CHATBOT_COMPANY.ADDRESS.DESCRIPTION') }}
          </span>
        </div>
        <!-- Input/Select -->
        <div class="col-span-8">
          <div class="grid grid-cols-2 gap-5">
            <!-- Select: Counrtry -->
            <ComboBox :searchAble="true" :options="[]" customButtonClass="h-12" :placeholder="$t('CUSTOMIZE_CHATBOT_COMPANY.ADDRESS.SELECT_COUNTRY')
              " />

            <!-- Select: City -->
            <ComboBox :searchAble="true" :options="[]" customButtonClass="h-12"
              :placeholder="$t('CUSTOMIZE_CHATBOT_COMPANY.ADDRESS.SELECT_CITY')" />

            <!-- Select: District -->
            <ComboBox :searchAble="true" :options="[]" customButtonClass="h-12" :placeholder="$t('CUSTOMIZE_CHATBOT_COMPANY.ADDRESS.SELECT_DISTRICT')
              " />

            <!-- Input: Address -->
            <Input type="text" customInputClass="h-12"
              :placeholder="$t('CUSTOMIZE_CHATBOT_COMPANY.ADDRESS.PLACEHOLDER')" />
          </div>
        </div>
      </div>
    </div>

    <!-- #Website  -->
    <div class="border-b-[0.5px] border-light-neutral-stroke-bold dark:border-black-neutral-stroke-bold py-6">
      <div class="grid grid-cols-12 gap-4 px-6 pb-5">
        <div class="col-span-4">
          <p class="text-base font-semibold">
            {{ $t('CUSTOMIZE_CHATBOT_COMPANY.WEBSITE.LABEL') }}
          </p>
          <span class="text-sm">
            {{ $t('CUSTOMIZE_CHATBOT_COMPANY.WEBSITE.DESCRIPTION') }}
          </span>
        </div>
        <div class="col-span-8">
          <Input type="text" customInputClass="h-12"
            :placeholder="$t('CUSTOMIZE_CHATBOT_COMPANY.WEBSITE.PLACEHOLDER')" />
        </div>
      </div>
    </div>

    <!-- #Industry -->
    <div class="border-b-[0.5px] border-light-neutral-stroke-bold dark:border-black-neutral-stroke-bold py-6">
      <div class="grid grid-cols-12 gap-4 px-6 pb-5">
        <div class="col-span-4">
          <p class="text-base font-semibold">
            {{ $t('CUSTOMIZE_CHATBOT_COMPANY.INDUSTRY.LABEL') }}
          </p>
          <span class="text-sm">
            {{ $t('CUSTOMIZE_CHATBOT_COMPANY.INDUSTRY.DESCRIPTION') }}
          </span>
        </div>
        <div class="col-span-8">
          <ComboBox :searchAble="true" :options="[]" customButtonClass="h-12" :placeholder="$t('CUSTOMIZE_CHATBOT_COMPANY.INDUSTRY.DEFAULT_OPTION')
            " />
        </div>
      </div>
    </div>

    <!-- #Language  -->
    <div class="border-b-[0.5px] border-light-neutral-stroke-bold dark:border-black-neutral-stroke-bold py-6">
      <div class="grid grid-cols-12 gap-4 px-6 pb-5">
        <div class="col-span-4">
          <p class="text-base font-semibold">
            {{ $t('CUSTOMIZE_CHATBOT_COMPANY.LANGUAGE.LABEL') }}
          </p>
          <span class="text-sm">
            {{ $t('CUSTOMIZE_CHATBOT_COMPANY.LANGUAGE.DESCRIPTION') }}
          </span>
        </div>
        <div class="col-span-8">
          <ComboBox :searchAble="true" :options="[]" customButtonClass="h-12" :placeholder="$t('CUSTOMIZE_CHATBOT_COMPANY.LANGUAGE.DEFAULT_OPTION')
            " />
        </div>
      </div>
    </div>

    <!-- #Time Zone  -->
    <div class="border-b-[0.5px] border-light-neutral-stroke-bold dark:border-black-neutral-stroke-bold py-6">
      <div class="grid grid-cols-12 gap-4 px-6 pb-5">
        <div class="col-span-4">
          <p class="text-base font-semibold">
            {{ $t('CUSTOMIZE_CHATBOT_COMPANY.TIME_ZONE.LABEL') }}
          </p>
          <span class="text-sm font">
            {{ $t('CUSTOMIZE_CHATBOT_COMPANY.TIME_ZONE.DESCRIPTION') }}
          </span>
        </div>
        <div class="col-span-8">
          <ComboBox :searchAble="true" :options="[]" customButtonClass="h-12" :placeholder="$t('CUSTOMIZE_CHATBOT_COMPANY.TIME_ZONE.DEFAULT_OPTION')
            " />
        </div>
      </div>
    </div>
  </div>
</template>
