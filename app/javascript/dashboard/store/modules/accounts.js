import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import * as types from '../mutation-types';
import AccountAPI from '../../api/account';
import { differenceInDays } from 'date-fns';
import EnterpriseAccountAPI from '../../api/enterprise/account';
import { throwErrorMessage } from '../utils/api';
import { getLanguageDirection } from 'dashboard/components/widgets/conversation/advancedFilterItems/languages';

const findRecordById = ($state, id) =>
  $state.records.find(record => record.id === Number(id)) || {};

const TRIAL_PERIOD_DAYS = 15;

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isUpdating: false,
    isCheckoutInProcess: false,
    isFetchingLimits: false,
    isFetchingBillings: false,
    limitationModal: {
      show: false,
      resourceKey: '',
    },
  },
};

export const getters = {
  getAccount: $state => id => {
    return findRecordById($state, id);
  },
  getUIFlags($state) {
    return $state.uiFlags;
  },
  isRTL: ($state, _getters, rootState, rootGetters) => {
    const accountId = Number(rootState.route?.params?.accountId);
    const userLocale = rootGetters?.getUISettings?.locale;
    const accountLocale =
      accountId && findRecordById($state, accountId)?.locale;

    // Prefer user locale; fallback to account locale
    const effectiveLocale = userLocale ?? accountLocale;

    return effectiveLocale ? getLanguageDirection(effectiveLocale) : false;
  },
  isTrialAccount: $state => id => {
    const account = findRecordById($state, id);
    const createdAt = new Date(account.created_at);
    const diffDays = differenceInDays(new Date(), createdAt);

    return diffDays <= TRIAL_PERIOD_DAYS;
  },
  isFeatureEnabledonAccount: $state => (id, featureName) => {
    const record = findRecordById($state, id) || {};
    const { features = {} } = record;
    return features[featureName] || false;
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isFetchingItem: true });
    try {
      const response = await AccountAPI.get();
      commit(types.default.ADD_ACCOUNT, response.data);
      commit(types.default.SET_ACCOUNT_UI_FLAG, {
        isFetchingItem: false,
      });
    } catch (error) {
      commit(types.default.SET_ACCOUNT_UI_FLAG, {
        isFetchingItem: false,
      });
    }
  },
  update: async ({ commit }, { options, ...updateObj }) => {
    if (options?.silent !== true) {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: true });
    }

    try {
      const response = await AccountAPI.update('', updateObj);
      commit(types.default.EDIT_ACCOUNT, response.data);
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false });
      throw new Error(error);
    }
  },
  delete: async ({ commit }, { id }) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: true });
    try {
      await AccountAPI.delete(id);
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false });
      throw new Error(error);
    }
  },
  toggleDeletion: async (
    { commit },
    { action_type } = { action_type: 'delete' }
  ) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: true });
    try {
      await EnterpriseAccountAPI.toggleDeletion(action_type);
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false });
    } catch (error) {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false });
      throw new Error(error);
    }
  },
  create: async ({ commit }, accountInfo) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isCreating: true });
    try {
      const response = await AccountAPI.createAccount(accountInfo);
      const account_id = response.data.data.account_id;
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isCreating: false });
      return account_id;
    } catch (error) {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isCreating: false });
      throw error;
    }
  },

  checkout: async ({ commit }, paymentInfo) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isCheckoutInProcess: true });
    try {
      const response = await EnterpriseAccountAPI.checkout(paymentInfo);
      const {
        redirect_url: redirectUrl,
        form_params: formParams,
        method,
      } = response.data;

      if (method === 'POST' && formParams && redirectUrl) {
        // SePay: create hidden form and submit via POST
        const form = document.createElement('form');
        form.method = 'POST';
        form.action = redirectUrl;
        form.style.display = 'none';
        Object.entries(formParams).forEach(([key, value]) => {
          const input = document.createElement('input');
          input.type = 'hidden';
          input.name = key;
          input.value = value;
          form.appendChild(input);
        });
        document.body.appendChild(form);
        form.submit();
      } else if (redirectUrl) {
        window.location = redirectUrl;
      } else {
        throw new Error('Invalid redirect URL');
      }
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isCheckoutInProcess: false });
    }
  },

  subscription: async ({ commit }) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isCheckoutInProcess: true });
    try {
      await EnterpriseAccountAPI.subscription();
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isCheckoutInProcess: false });
    }
  },

  activateTrial: async ({ commit, dispatch }) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: true });
    try {
      await EnterpriseAccountAPI.activateTrial();
      await dispatch('get'); // Refresh account data
      await dispatch('billings'); // Refresh billing data
    } catch (error) {
      throwErrorMessage(error);
    } finally {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isUpdating: false });
    }
  },

  limits: async ({ commit }) => {
    commit(types.default.SET_ACCOUNT_UI_FLAG, { isFetchingLimits: true });
    try {
      const response = await EnterpriseAccountAPI.getLimits();
      commit(types.default.SET_ACCOUNT_LIMITS, response.data);
    } catch (error) {
      // silent error
    } finally {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isFetchingLimits: false });
    }
  },

  billings: async ({ commit, state: accountState }) => {
    if (accountState.uiFlags.isFetchingBillings) return;

    commit(types.default.SET_ACCOUNT_UI_FLAG, { isFetchingBillings: true });
    try {
      const response = await EnterpriseAccountAPI.getBillings();
      commit(types.default.SET_ACCOUNT_PLANS, response.data);
    } catch (error) {
      // silent error
    } finally {
      commit(types.default.SET_ACCOUNT_UI_FLAG, { isFetchingBillings: false });
    }
  },

  getCacheKeys: async () => {
    return AccountAPI.getCacheKeys();
  },

  toggleLimitationModal: ({ commit }, data) => {
    commit(types.default.SET_LIMITATION_MODAL, data);
  },
};

export const mutations = {
  [types.default.SET_ACCOUNT_UI_FLAG]($state, data) {
    $state.uiFlags = {
      ...$state.uiFlags,
      ...data,
    };
  },
  [types.default.ADD_ACCOUNT]: MutationHelpers.setSingleRecord,
  [types.default.EDIT_ACCOUNT]: MutationHelpers.update,
  [types.default.SET_ACCOUNT_LIMITS]: MutationHelpers.updateAttributes,
  [types.default.SET_ACCOUNT_PLANS]($state, { id, data }) {
    const recordIndex = $state.records.findIndex(
      record => record.id === Number(id)
    );
    if (recordIndex > -1) {
      const account = $state.records[recordIndex];
      $state.records[recordIndex] = {
        ...account,
        billing: { ...account.billing, ...data },
      };
    }
  },
  [types.default.SET_LIMITATION_MODAL]($state, data) {
    $state.uiFlags.limitationModal = {
      ...$state.uiFlags.limitationModal,
      ...data,
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
