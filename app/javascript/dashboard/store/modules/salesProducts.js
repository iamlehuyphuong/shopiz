// No Vue import needed
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import SalesProductsAPI from 'dashboard/api/sales/products';

const state = {
  records: [],
  meta: {
    current_page: 1,
    total_pages: 1,
    total_count: 0,
  },
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
    isSyncing: false,
  },
};

export const getters = {
  getProducts: $state => $state.records,
  getMeta: $state => $state.meta,
  getUIFlags: $state => $state.uiFlags,
};

export const actions = {
  get: async ({ commit }, params = {}) => {
    commit('SET_PRODUCT_UI_FLAG', { isFetching: true });
    try {
      const response = await SalesProductsAPI.get(params);
      commit('SET_PRODUCTS', response.data.payload || response.data);
      if (response.data.meta) {
        commit('SET_META', response.data.meta);
      }
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
  syncPlatform: async ({ commit }, platform) => {
    commit('SET_PRODUCT_UI_FLAG', { isSyncing: true });
    try {
      await SalesProductsAPI.sync(platform);
    } catch (error) {
      throw error;
    } finally {
      commit('SET_PRODUCT_UI_FLAG', { isSyncing: false });
    }
  },
  importProducts: async (_, file) => {
    await SalesProductsAPI.importProducts(file);
  },
  exportProducts: async (_, payload) => {
    const response = await SalesProductsAPI.exportProducts(payload);
    if (response.data && response.data.download_url) {
      window.open(response.data.download_url, '_blank');
    }
    return response.data;
  },
};

// Import removed from here

export const mutations = {
  SET_PRODUCT_UI_FLAG($state, data) {
    $state.uiFlags = { ...$state.uiFlags, ...data };
  },
  SET_PRODUCTS: MutationHelpers.set,
  SET_META($state, meta) {
    $state.meta = meta;
  },
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
