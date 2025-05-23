<template>
  <div class="flex items-center space-x-2 m-5">
    <button
      class="bg-gray-200 border border-gray-300 p-1 text-base rounded hover:bg-gray-300"
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="10"
        height="10"
        viewBox="0 0 10 10"
        fill="none"
      >
        <path
          d="M4.66696 9C4.66696 9 0.667001 6.05404 0.666992 4.99997C0.666983 3.94589 4.66699 1 4.66699 1"
          stroke="#0A0A0A"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M9.33395 9C9.33395 9 5.33399 6.05404 5.33398 4.99997C5.33398 3.94589 9.33398 1 9.33398 1"
          stroke="#0A0A0A"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </svg>
    </button>
    <button
      class="bg-gray-200 border border-gray-300 p-1 text-base rounded hover:bg-gray-300 flex flex-row gap-2"
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="6"
        height="10"
        viewBox="0 0 6 10"
        fill="none"
      >
        <path
          d="M4.99997 1C4.99997 1 1.00001 3.94596 1 5.00003C0.999991 6.05411 5 9 5 9"
          stroke="#0A0A0A"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </svg>
      <b class="bg-gray-200 p-1 text-base rounded">
        {{
          $t('CUSTOMIZE_CHATBOT_PRODUCT.CUSTOMIZE_CHATBOT_PAGINATION.PREVIOUS')
        }}
      </b>
    </button>
    <span class="text-base flex flex-row gap-1 items-center justify-center">
      <div class="border-solid border-[#D1D1D1] p-1 rounded border-[1px]">
        <input
          value="1"
          type="text"
          class="text-center justify-center items-center"
        />
      </div>
      {{
        $t('CUSTOMIZE_CHATBOT_PRODUCT.CUSTOMIZE_CHATBOT_PAGINATION.COUNT', {
          page: 8,
        })
      }}
    </span>
    <button
      class="bg-gray-200 border border-gray-300 p-1 text-base rounded hover:bg-gray-300 flex flex-row gap-2"
    >
      <b class="text-base">
        {{ $t('CUSTOMIZE_CHATBOT_PRODUCT.CUSTOMIZE_CHATBOT_PAGINATION.NEXT') }}
      </b>
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="6"
        height="10"
        viewBox="0 0 6 10"
        fill="none"
      >
        <path
          d="M1.00003 1C1.00003 1 4.99999 3.94596 5 5.00003C5.00001 6.05411 1 9 1 9"
          stroke="#0A0A0A"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </svg>
    </button>
    <button
      class="bg-gray-200 border border-gray-300 p-1 text-base rounded hover:bg-gray-300"
    >
      <svg
        xmlns="http://www.w3.org/2000/svg"
        width="10"
        height="10"
        viewBox="0 0 10 10"
        fill="none"
      >
        <path
          d="M5.33402 9C5.33402 9 9.33398 6.05404 9.33398 4.99997C9.33399 3.94589 5.33398 1 5.33398 1"
          stroke="#0A0A0A"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
        <path
          d="M0.667023 9C0.667023 9 4.66698 6.05404 4.66699 4.99997C4.667 3.94589 0.666992 1 0.666992 1"
          stroke="#0A0A0A"
          stroke-linecap="round"
          stroke-linejoin="round"
        />
      </svg>
    </button>
  </div>
</template>

<style scoped>
input {
  width: 2.5rem !important;
  height: 1.25rem !important;
  margin-bottom: 0 !important;
  border: none !important;
}
</style>
