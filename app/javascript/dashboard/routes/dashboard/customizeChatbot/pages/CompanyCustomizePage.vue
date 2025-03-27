<script>
import CustomizeChatbotHeader from '../../../../components-next/CustomizeChatbot/CustomizeChatbotHeader.vue';

export default {
  components: { CustomizeChatbotHeader },
  methods: {
    updateSettings() {
      // TODO: Update settings
    },
  },
};
</script>

<template>
  <div class="w-full h-full bg-white">
    <CustomizeChatbotHeader
      :title="$t('CUSTOMIZE_CHATBOT_COMPANY.COMPANY_NAME.TITLE')"
      :button-text="$t('CUSTOMIZE_CHATBOT_COMPANY.COMPANY_NAME.BUTTON')"
      @button-click="updateSettings"
    />
    <!-- #Company Name -->
    <div class="border-b-[0.5px] border-[#D1D1D1] py-6">
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
          <input
            type="text"
            class="p-3 gap-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 w-full h-12"
            :placeholder="
              $t('CUSTOMIZE_CHATBOT_COMPANY.COMPANY_NAME.PLACEHOLDER')
            "
          />
        </div>
      </div>
    </div>

    <!-- #Company description -->
    <div class="border-b-[0.5px] border-[#D1D1D1] py-6">
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
          <textarea
            class="w-full h-40 p-2 border border-gray-300 rounded-md"
            :placeholder="
              $t('CUSTOMIZE_CHATBOT_COMPANY.COMPANY_DESCRIPTION.PLACEHOLDER')
            "
          />
        </div>
      </div>
    </div>

    <!-- #Phone number -->
    <div class="border-b-[0.5px] border-[#D1D1D1] py-6">
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
          <input
            type="text"
            class="p-3 gap-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 w-full h-12"
            :placeholder="
              $t('CUSTOMIZE_CHATBOT_COMPANY.PHONE_NUMBER.PLACEHOLDER')
            "
          />
        </div>
      </div>
    </div>

    <!-- #Address -->
    <div class="border-b-[0.5px] border-[#D1D1D1] py-6">
      <div class="grid grid-cols-12 gap-4 px-6 pb-5">
        <div class="col-span-4">
          <p class="text-base font-semibold">
            {{ $t('CUSTOMIZE_CHATBOT_COMPANY.ADDRESS.LABEL') }}
          </p>
          <span class="text-sm">
            {{ $t('CUSTOMIZE_CHATBOT_COMPANY.ADDRESS.DESCRIPTION') }}
          </span>
        </div>
        <div class="col-span-8">
          <div class="grid grid-cols-2 gap-5">
            <select class="col-span-1 border border-gray-300 rounded-md">
              <option value="" disabled selected hidden>
                {{ $t('CUSTOMIZE_CHATBOT_COMPANY.ADDRESS.SELECT_COUNTRY') }}
              </option>
            </select>
            <select class="col-span-1 border border-gray-300 rounded-md">
              <option value="" disabled selected hidden class="text-[#575757]">
                {{ $t('CUSTOMIZE_CHATBOT_COMPANY.ADDRESS.SELECT_CITY') }}
              </option>
            </select>
            <select class="col-span-1 border border-gray-300 rounded-md">
              <option value="" disabled selected hidden class="text-[#575757]">
                {{ $t('CUSTOMIZE_CHATBOT_COMPANY.ADDRESS.SELECT_DISTRICT') }}
              </option>
            </select>
            <input
              type="text"
              :placeholder="$t('CUSTOMIZE_CHATBOT_COMPANY.ADDRESS.PLACEHOLDER')"
              class="p-3 gap-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 col-span-1 h-12"
            />
          </div>
        </div>
      </div>
    </div>

    <!-- #Website  -->
    <div class="border-b-[0.5px] border-[#D1D1D1] py-6">
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
          <input
            type="text"
            class="p-3 gap-1 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 w-full h-12"
            :placeholder="$t('CUSTOMIZE_CHATBOT_COMPANY.WEBSITE.PLACEHOLDER')"
          />
        </div>
      </div>
    </div>

    <!-- #Industry -->
    <div class="border-b-[0.5px] border-[#D1D1D1] py-6">
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
          <select class="col-span-1 border border-gray-300 rounded-md">
            <option value="">
              {{ $t('CUSTOMIZE_CHATBOT_COMPANY.INDUSTRY.DEFAULT_OPTION') }}
            </option>
          </select>
        </div>
      </div>
    </div>

    <!-- #Language  -->
    <div class="border-b-[0.5px] border-[#D1D1D1] py-6">
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
          <select class="col-span-1 border border-gray-300 rounded-md">
            <option value="">
              {{ $t('CUSTOMIZE_CHATBOT_COMPANY.LANGUAGE.DEFAULT_OPTION') }}
            </option>
          </select>
        </div>
      </div>
    </div>

    <!-- #Time Zone  -->
    <div class="border-b-[0.5px] border-[#D1D1D1] py-6">
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
          <select class="col-span-1 border border-gray-300 rounded-md">
            <option value="">
              {{ $t('CUSTOMIZE_CHATBOT_COMPANY.TIME_ZONE.DEFAULT_OPTION') }}
            </option>
          </select>
        </div>
      </div>
    </div>
  </div>
</template>
