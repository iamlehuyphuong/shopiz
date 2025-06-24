import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../../mutation-types';
import ProductsAPI from '../../../api/products';
import AnalyticsHelper from '../../../helper/AnalyticsHelper';
import { PRODUCT_EVENTS } from '../../../helper/AnalyticsHelper/events';

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
  getProducts(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getProductsOnSidebar(_state) {
    return _state.records
      .filter(record => record.show_on_sidebar)
      .sort((a, b) => a.title.localeCompare(b.title));
  },
  getProductById: _state => id => {
    return _state.records.find(record => record.id === Number(id));
  },
};

export const actions = {
  revalidate: async function revalidate({ commit }, { newKey }) {
    try {
      const isExistingKeyValid = await ProductsAPI.validateCacheKey(newKey);
      if (!isExistingKeyValid) {
        const response = await ProductsAPI.refetchAndCommit(newKey);
        commit(types.SET_PRODUCTS, response.data.payload);
      }
    } catch (error) {
      // Ignore error
    }
  },

  get: async function getProducts({ commit }) {
    commit(types.SET_PRODUCT_UI_FLAG, { isFetching: true });
    try {
      const response = await ProductsAPI.getProducts();
      const sortedProducts = response.data.products.sort((a, b) =>
        a.title.localeCompare(b.title)
      );
      commit(types.SET_PRODUCTS, sortedProducts);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_PRODUCT_UI_FLAG, { isFetching: false });
    }
  },

  create: async function createProducts({ commit }, cannedObj) {
    commit(types.SET_PRODUCT_UI_FLAG, { isCreating: true });
    try {
      const response = await ProductsAPI.create(cannedObj);
      AnalyticsHelper.track(PRODUCT_EVENTS.CREATE);
      commit(types.ADD_PRODUCT, response.data);
    } catch (error) {
      const errorMessage = error?.response?.data?.message;
      throw new Error(errorMessage);
    } finally {
      commit(types.SET_PRODUCT_UI_FLAG, { isCreating: false });
    }
  },

  update: async function updateProducts({ commit }, { id, ...updateObj }) {
    commit(types.SET_PRODUCT_UI_FLAG, { isUpdating: true });
    try {
      const response = await ProductsAPI.update(id, updateObj);
      AnalyticsHelper.track(PRODUCT_EVENTS.UPDATE);
      commit(types.EDIT_PRODUCT, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PRODUCT_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async function deleteProducts({ commit }, id) {
    commit(types.SET_PRODUCT_UI_FLAG, { isDeleting: true });
    try {
      await ProductsAPI.delete(id);
      AnalyticsHelper.track(PRODUCT_EVENTS.DELETED);
      commit(types.DELETE_PRODUCT, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_PRODUCT_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_PRODUCT_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_PRODUCTS]: MutationHelpers.set,
  [types.ADD_PRODUCT]: MutationHelpers.create,
  [types.EDIT_PRODUCT]: MutationHelpers.update,
  [types.DELETE_PRODUCT]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
