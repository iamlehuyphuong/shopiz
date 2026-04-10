import { computed, onMounted } from 'vue';
import { useAccount } from './useAccount';
import { useStore } from './store';

export const useLimitation = () => {
  const store = useStore();
  const { currentAccount } = useAccount();

  const usageData = computed(() => {
    return currentAccount.value?.billing?.usage || {};
  });

  onMounted(() => {
    const hasUsageData = Object.keys(usageData.value).length > 0;
    if (!hasUsageData && currentAccount.value?.id) {
      store.dispatch('accounts/billings');
    }
  });

  const parseUsage = usageString => {
    if (!usageString) return { consumed: 0, totalCount: 0 };
    if (typeof usageString === 'number')
      return { consumed: usageString, totalCount: 0 };
    const [consumed, totalCount] = usageString.split(' / ').map(v => Number(v));
    return { consumed: consumed || 0, totalCount: totalCount || 0 };
  };

  const getUsage = resourceKey => {
    const rawUsage = usageData.value[resourceKey];
    const { consumed, totalCount } = parseUsage(rawUsage);
    const isReached = totalCount > 0 && consumed >= totalCount;
    return {
      consumed,
      totalCount,
      isReached,
      rawUsage: rawUsage || '0 / 0',
    };
  };

  const checkLimitation = resourceKey => {
    const { isReached } = getUsage(resourceKey);
    if (isReached) {
      // Trigger modal (will be implemented next)
      store.dispatch('accounts/toggleLimitationModal', {
        show: true,
        resourceKey,
      });
      return false;
    }
    return true;
  };

  return {
    getUsage,
    checkLimitation,
    usageData,
  };
};
