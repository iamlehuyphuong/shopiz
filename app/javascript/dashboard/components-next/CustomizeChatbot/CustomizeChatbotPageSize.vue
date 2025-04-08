<template>
     <span class="text-base flex flex-row gap-1 items-center justify-center">
          {{
            $t(
              'CUSTOMIZE_CHATBOT_PRODUCT.CUSTOMIZE_CHATBOT_PAGINATION.ITEM_PER_PAGE'
            )
          }}

          <div class="border-solid border-[#D1D1D1] p-1 rounded border-[1px]">
            <input
              value="20"
              type="text"
              class="text-center justify-center items-center pagination-input"
            />
          </div>
          {{
            $t('CUSTOMIZE_CHATBOT_PRODUCT.CUSTOMIZE_CHATBOT_PAGINATION.TOTAL', {
              number: '1-20',
              total: '500',
            })
          }}
        </span>
</template>

<style scoped>

input {
  margin-bottom: 0 !important;
  border: none !important;
}
.pagination-input {
  width: 2.5rem !important;
  height: 1.25rem !important;
}

</style>