import testimonials from './testimonials.json';

export const getTestimonialContent = () => {
  return Promise.resolve({ data: testimonials });
};
