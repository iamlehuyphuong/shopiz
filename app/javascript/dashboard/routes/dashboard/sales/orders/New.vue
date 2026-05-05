<script setup></script>

<template>
  <div class="h-full w-full bg-white dark:bg-slate-900 overflow-y-auto">
    <div
      class="flex items-center gap-3 px-8 py-5 border-b border-n-weak sticky top-0 bg-white dark:bg-slate-900 z-10"
    >
      <router-link
        :to="{ name: 'sales_orders_list' }"
        class="p-2 -ml-2 text-n-slate-11 hover:text-n-slate-12 hover:bg-n-alpha-1 rounded-lg transition-colors"
      >
        <span class="icon-arrow-left text-xl" />
      </router-link>
      <h2 class="text-xl font-semibold text-n-slate-12 mb-0">
        Tạo đơn hàng mới
      </h2>
    </div>
    <div class="p-8 max-w-3xl mx-auto">
      <p class="text-n-slate-11">
        Màn hình tạo đơn hàng mới đang được xây dựng...
      </p>
    </div>
  </div>
</template>
