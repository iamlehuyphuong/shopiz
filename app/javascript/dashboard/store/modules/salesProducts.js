// No Vue import needed
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import SalesProductsAPI from 'dashboard/api/sales/products';

const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getProducts: $state => $state.records,
  getUIFlags: $state => $state.uiFlags,
};

export const actions = {
  get: async ({ commit }) => {
    commit('SET_PRODUCT_UI_FLAG', { isFetching: true });
    try {
      const response = await SalesProductsAPI.get();
      commit('SET_PRODUCTS', response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit('SET_PRODUCT_UI_FLAG', { isFetching: false });
    }
  },
  create: async ({ commit }, productObj) => {
    commit('SET_PRODUCT_UI_FLAG', { isCreating: true });
    try {
      const response = await SalesProductsAPI.create(productObj);
      commit('ADD_PRODUCT', response.data);
    } catch (error) {
      throw error;
    } finally {
      commit('SET_PRODUCT_UI_FLAG', { isCreating: false });
    }
  },
  update: async ({ commit }, { id, ...productObj }) => {
    commit('SET_PRODUCT_UI_FLAG', { isUpdating: true });
    try {
      const response = await SalesProductsAPI.update(id, productObj);
      commit('UPDATE_PRODUCT', response.data);
    } catch (error) {
      throw error;
    } finally {
      commit('SET_PRODUCT_UI_FLAG', { isUpdating: false });
    }
  },
  delete: async ({ commit }, id) => {
    commit('SET_PRODUCT_UI_FLAG', { isDeleting: true });
    try {
      await SalesProductsAPI.delete(id);
      commit('DELETE_PRODUCT', id);
    } catch (error) {
      throw error;
    } finally {
      commit('SET_PRODUCT_UI_FLAG', { isDeleting: false });
    }
  },
};

// Import removed from here

export const mutations = {
  SET_PRODUCT_UI_FLAG($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  SET_PRODUCTS: MutationHelpers.set,
  ADD_PRODUCT: MutationHelpers.create,
  UPDATE_PRODUCT: MutationHelpers.update,
  DELETE_PRODUCT: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
