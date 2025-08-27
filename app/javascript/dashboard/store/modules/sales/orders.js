import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../../mutation-types';
import OrdersAPI from '../../../api/sales/orders';
import AnalyticsHelper from '../../../helper/AnalyticsHelper';
import { ORDER_EVENTS } from '../../../helper/AnalyticsHelper/events';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isFetchingItem: false,
    isCreating: false,
    isDeleting: false,
  },
};

export const getters = {
  getOrders(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getOrdersOnSidebar(_state) {
    return _state.records
      .filter(record => record.show_on_sidebar)
      .sort((a, b) => a.title.localeCompare(b.title));
  },
  getOrderById: _state => id => {
    return _state.records.find(record => record.id === Number(id));
  },
};

export const actions = {
  revalidate: async function revalidate({ commit }, { newKey }) {
    try {
      const isExistingKeyValid = await OrdersAPI.validateCacheKey(newKey);
      if (!isExistingKeyValid) {
        const response = await OrdersAPI.refetchAndCommit(newKey);
        commit(types.SET_ORDERS, response.data.payload);
      }
    } catch (error) {
      // Ignore error
    }
  },

  get: async function getOrders({ commit }) {
    commit(types.SET_ORDER_UI_FLAG, { isFetching: true });
    try {
      const response = await OrdersAPI.getOrders();
      console.log("ORDERS",response)
      const sortedOrders = response.data.orders.sort((a, b) =>
        a.title.localeCompare(b.title)
      );
      commit(types.SET_ORDERS, sortedOrders);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_ORDER_UI_FLAG, { isFetching: false });
    }
  },

  create: async function createOrders({ commit }, cannedObj) {
    commit(types.SET_ORDER_UI_FLAG, { isCreating: true });
    try {
      const response = await OrdersAPI.create(cannedObj);
      AnalyticsHelper.track(ORDER_EVENTS.CREATE);
      commit(types.ADD_ORDER, response.data);
    } catch (error) {
      const errorMessage = error?.response?.data?.message;
      throw new Error(errorMessage);
    } finally {
      commit(types.SET_ORDER_UI_FLAG, { isCreating: false });
    }
  },

  update: async function updateOrders({ commit }, { id, ...updateObj }) {
    commit(types.SET_ORDER_UI_FLAG, { isUpdating: true });
    try {
      const response = await OrdersAPI.update(id, updateObj);
      AnalyticsHelper.track(ORDER_EVENTS.UPDATE);
      commit(types.EDIT_ORDER, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_ORDER_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async function deleteOrders({ commit }, id) {
    commit(types.SET_ORDER_UI_FLAG, { isDeleting: true });
    try {
      await OrdersAPI.delete(id);
      AnalyticsHelper.track(ORDER_EVENTS.DELETED);
      commit(types.DELETE_ORDER, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_ORDER_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_ORDER_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_ORDERS]: MutationHelpers.set,
  [types.ADD_ORDER]: MutationHelpers.create,
  [types.EDIT_ORDER]: MutationHelpers.update,
  [types.DELETE_ORDER]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
