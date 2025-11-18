import { computed } from 'vue';
import { useStore } from 'dashboard/composables/store.js';
import { useAccount } from 'dashboard/composables/useAccount';
import { useConfig } from 'dashboard/composables/useConfig';
import { useCamelCase } from 'dashboard/composables/useTransformKeys';
import { FEATURE_FLAGS } from 'dashboard/featureFlags';

export function useCaptain() {
  const store = useStore();
  const { isCloudFeatureEnabled, currentAccount } = useAccount();
  const { isEnterprise } = useConfig();

  const captainEnabled = computed(() => {
    return isCloudFeatureEnabled(FEATURE_FLAGS.CAPTAIN);
  });

  const captainLimits = computed(() => {
    return currentAccount.value?.limits?.captain;
  });

  const documentLimits = computed(() => {
    if (captainLimits.value?.documents) {
      return useCamelCase(captainLimits.value.documents);
    }

    return null;
  });

  const responseLimits = computed(() => {
    if (captainLimits.value?.responses) {
      return useCamelCase(captainLimits.value.responses);
    }

    return null;
  });

  const faqLimits = computed(() => {
    if (captainLimits.value?.faqs) {
      return useCamelCase(captainLimits.value.faqs);
    }

    return null;
  });

  const assistantLimits = computed(() => {
    if (captainLimits.value?.assistants) {
      return useCamelCase(captainLimits.value.assistants);
    }

    return null;
  });

  const fetchLimits = () => {
    if (isEnterprise) {
      store.dispatch('accounts/limits');
    }
  };

  return {
    captainEnabled,
    captainLimits,
    documentLimits,
    responseLimits,
    faqLimits,
    assistantLimits,
    fetchLimits,
  };
}
