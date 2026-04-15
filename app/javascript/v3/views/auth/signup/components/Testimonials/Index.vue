<script setup>
import { ref, computed, onBeforeMount } from 'vue';
import { useI18n } from 'vue-i18n';
import TestimonialCard from './TestimonialCard.vue';
import { getTestimonialContent } from '../../../../../api/testimonials';

const emit = defineEmits(['resizeContainers']);
const { locale } = useI18n();

const testimonial = ref(null);

const testimonialReview = computed(() => {
  if (!testimonial.value) return '';
  return locale.value === 'vi'
    ? testimonial.value.authorReviewVi
    : testimonial.value.authorReviewEn;
});

const testimonialCompany = computed(() => {
  if (!testimonial.value) return '';
  return locale.value === 'vi'
    ? testimonial.value.authorCompanyVi
    : testimonial.value.authorCompanyEn;
});

const fetchTestimonials = async () => {
  try {
    const { data } = await getTestimonialContent();
    if (data.length) {
      testimonial.value = data[Math.floor(Math.random() * data.length)];
    }
  } catch {
    // Ignoring the error as the UI wouldn't break
  } finally {
    emit('resizeContainers', !!testimonial.value);
  }
};

onBeforeMount(() => {
  fetchTestimonials();
});
</script>

<template>
  <div
    class="relative flex-1 flex flex-col items-start justify-center bg-n-alpha-black2 dark:bg-n-solid-3 px-12 py-14 rounded-e-lg"
  >
    <TestimonialCard
      v-if="testimonial"
      :review-content="testimonialReview"
      :author-image="testimonial.authorImage"
      :author-name="testimonial.authorName"
      :author-designation="testimonialCompany"
    />
    <div class="absolute bottom-8 right-8 grid grid-cols-3 gap-1.5">
      <span class="w-2 h-2 rounded-full bg-n-gray-5" />
      <span class="w-2 h-2 rounded-full bg-n-gray-5" />
      <span class="w-2 h-2 rounded-full bg-n-gray-5" />
      <span class="w-2 h-2 rounded-full bg-n-gray-5" />
      <span class="w-2 h-2 rounded-full bg-n-gray-5" />
      <span class="w-2 h-2 rounded-full bg-n-gray-5" />
    </div>
  </div>
</template>
