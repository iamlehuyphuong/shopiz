import types from '../mutation-types';
import ConversationProductsAPI from '../../api/conversationProducts';

export const state = {
  products: [],
  uiFlags: {
    isFetching: false,
  },
};

export const getters = {
  getProducts: _state => _state.products,
  getUIFlags: _state => _state.uiFlags,
};

export const actions = {
  async fetchProducts({ commit }, { conversationId, query, page }) {
    commit(types.SET_CONVERSATION_PRODUCTS_UI_FLAG, { isFetching: true });
    try {
      const { data } = await ConversationProductsAPI.getProducts(
        conversationId,
        { query, page }
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
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
