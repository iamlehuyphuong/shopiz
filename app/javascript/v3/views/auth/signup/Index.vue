<script setup>
import { ref, computed, onBeforeMount } from 'vue';
import { useStore } from 'vuex';
import SignupForm from './components/Signup/Form.vue';
import Spinner from 'shared/components/Spinner.vue';
import NetworkIllustration from 'v3/components/NetworkIllustration.vue';

const store = useStore();

const isLoading = ref(false);
const globalConfig = computed(() => store.getters['globalConfig/get']);
const isAChatwootInstance = computed(
  () => globalConfig.value.installationName === 'Chatwoot'
);

onBeforeMount(() => {
  isLoading.value = isAChatwootInstance.value;
});

const resizeContainers = () => {
  isLoading.value = false;
};
</script>

<template>
  <div class="flex min-h-screen w-full bg-white dark:bg-n-solid-2">
    <div
      v-show="!isLoading"
      class="flex-1 flex flex-col justify-center px-4 py-12 sm:px-6 lg:flex-none lg:w-[45%] lg:min-w-[500px] lg:max-w-[650px] lg:px-20 xl:px-24"
    >
      <div class="mx-auto w-full max-w-sm lg:max-w-md">
        <div class="mb-6">
          <img
            :src="globalConfig.logo"
            :alt="globalConfig.installationName"
            class="block w-auto h-14"
          />
          <h2 class="mt-6 text-2xl font-semibold text-n-slate-12">
            {{
              isAChatwootInstance
                ? $t('REGISTER.GET_STARTED')
                : $t('REGISTER.TRY_WOOT')
            }}
          </h2>
          <p class="mt-2 text-sm text-n-slate-11">
            {{ $t('REGISTER.HAVE_AN_ACCOUNT') }}{{ ' '
            }}<router-link
              class="text-n-orange-10 font-medium hover:text-n-orange-11"
              to="/app/login"
            >
              {{ $t('LOGIN.SUBMIT') }}
            </router-link>
          </p>
        </div>
        <SignupForm />
      </div>
    </div>

    <div v-show="!isLoading" class="hidden lg:flex flex-1 relative">
      <NetworkIllustration />
    </div>

    <div
      v-show="isLoading"
      class="absolute inset-0 flex items-center justify-center w-full h-full bg-white z-50"
    >
      <Spinner color-scheme="primary" size="" />
    </div>
  </div>
</template>
