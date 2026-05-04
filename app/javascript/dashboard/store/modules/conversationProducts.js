import types from '../mutation-types';
import ConversationProductsAPI from '../../api/conversationProducts';

export const state = {
  products: [],
  categories: [],
  uiFlags: {
    isFetching: false,
    isFetchingCategories: false,
  },
};

export const getters = {
  getProducts: _state => _state.products,
  getCategories: _state => _state.categories,
  getUIFlags: _state => _state.uiFlags,
};

export const actions = {
  async fetchCategories({ commit }, { conversationId }) {
    commit(types.SET_CONVERSATION_PRODUCTS_UI_FLAG, {
      isFetchingCategories: true,
    });
    try {
      const { data } =
        await ConversationProductsAPI.getCategories(conversationId);
      commit(types.SET_CONVERSATION_PRODUCT_CATEGORIES, data.categories || []);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CONVERSATION_PRODUCTS_UI_FLAG, {
        isFetchingCategories: false,
      });
    }
  },

  async fetchProducts({ commit }, { conversationId, query, categoryId, page }) {
    commit(types.SET_CONVERSATION_PRODUCTS_UI_FLAG, { isFetching: true });
    try {
      const { data } = await ConversationProductsAPI.getProducts(
        conversationId,
        { query, categoryId, page }
      );
      commit(types.SET_CONVERSATION_PRODUCTS, {
        products: data.products || [],
        append: page > 0,
      });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CONVERSATION_PRODUCTS_UI_FLAG, { isFetching: false });
    }
  },
};

export const mutations = {
  [types.SET_CONVERSATION_PRODUCTS_UI_FLAG](_state, data) {
    _state.uiFlags = { ..._state.uiFlags, ...data };
  },

  [types.SET_CONVERSATION_PRODUCTS](_state, { products, append }) {
    _state.products = append ? [..._state.products, ...products] : products;
  },

  [types.SET_CONVERSATION_PRODUCT_CATEGORIES](_state, categories) {
    _state.categories = categories;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
