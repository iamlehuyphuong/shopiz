<script setup>
import Banner from 'dashboard/components-next/banner/Banner.vue';

const showBanner = false;
defineExpose({ showBanner });
</script>

<template>
  <Banner v-show="showBanner" color="amber" />
</template>
