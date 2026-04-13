<script setup>
import { computed } from 'vue';
import { useMapGetter } from 'dashboard/composables/store';
import { useAdmin } from 'dashboard/composables/useAdmin';
import { useAccount } from 'dashboard/composables/useAccount';
import { useI18n } from 'vue-i18n';
import { useRouter } from 'vue-router';
import Banner from 'dashboard/components/ui/Banner.vue';

const { isAdmin } = useAdmin();
const { accountId } = useAccount();
const { t } = useI18n();
const router = useRouter();

const getAccount = useMapGetter('accounts/getAccount');

const subscriptionInfo = computed(() => {
  const account = getAccount.value(accountId.value);
  if (!account) return { status: null, endsOn: null, gracePeriodEndsAt: null };

  const { custom_attributes: attrs } = account;
  if (!attrs) return { status: null, endsOn: null, gracePeriodEndsAt: null };

  return {
    status: attrs.subscription_status,
    endsOn: attrs.subscription_ends_on
      ? new Date(attrs.subscription_ends_on)
      : null,
    gracePeriodEndsAt: attrs.grace_period_ends_at
      ? new Date(attrs.grace_period_ends_at)
      : null,
  };
});

const isExpiredOrGracePeriod = computed(() => {
  const { status, endsOn, gracePeriodEndsAt } = subscriptionInfo.value;
  if (!status || !endsOn) return false;

  const now = new Date();

  // Show banner if subscription is expired and still in grace period
  if (status === 'expired' && gracePeriodEndsAt && gracePeriodEndsAt > now) {
    return true;
  }

  // Show banner if subscription_ends_on is in the past
  if (endsOn < now && status !== 'active') {
    return true;
  }

  // Show banner for Stripe past_due status
  if (status === 'past_due' && endsOn < now) {
    return true;
  }

  return false;
});

const gracePeriodDaysRemaining = computed(() => {
  const { gracePeriodEndsAt } = subscriptionInfo.value;
  if (!gracePeriodEndsAt) return 0;

  const now = new Date();
  const diff = gracePeriodEndsAt - now;
  return Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)));
});

const bannerMessage = computed(() => {
  const days = gracePeriodDaysRemaining.value;
  if (days > 0) {
    return t('GENERAL_SETTINGS.SUBSCRIPTION_EXPIRED_GRACE', { days });
  }
  return t('GENERAL_SETTINGS.SUBSCRIPTION_EXPIRED');
});

const actionButtonMessage = computed(() => {
  return t('GENERAL_SETTINGS.OPEN_BILLING');
});

const shouldShowBanner = computed(() => {
  if (!isAdmin.value) return false;
  return isExpiredOrGracePeriod.value;
});

const routeToBilling = () => {
  router.push({
    name: 'billing_settings_index',
    params: { accountId: accountId.value },
  });
};
</script>

<!-- eslint-disable-next-line vue/no-root-v-if -->
<template>
  <Banner
    v-if="shouldShowBanner"
    color-scheme="alert"
    :banner-message="bannerMessage"
    :action-button-label="actionButtonMessage"
    has-action-button
    @primary-action="routeToBilling"
  />
</template>
