import types from '../mutation-types';
import ConversationOrdersAPI from '../../api/conversationOrders';

export const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getOrdersByConversationId: _state => conversationId => {
    const records = _state.records[conversationId] || [];
    return records.sort((a, b) => b.id - a.id);
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  async get({ commit }, { conversationId }) {
    commit(types.SET_CONVERSATION_ORDERS_UI_FLAG, { isFetching: true });
    try {
      const { data } = await ConversationOrdersAPI.getOrders(conversationId);
      commit(types.SET_CONVERSATION_ORDERS, { conversationId, data });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CONVERSATION_ORDERS_UI_FLAG, { isFetching: false });
    }
  },

  async create({ commit }, { conversationId, orderData }) {
    commit(types.SET_CONVERSATION_ORDERS_UI_FLAG, { isCreating: true });
    try {
      const { data } = await ConversationOrdersAPI.createOrder(
        conversationId,
        orderData
      );
      commit(types.ADD_CONVERSATION_ORDER, { conversationId, data });
      return data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CONVERSATION_ORDERS_UI_FLAG, { isCreating: false });
    }
  },

  async update({ commit }, { conversationId, orderId, orderData }) {
    commit(types.SET_CONVERSATION_ORDERS_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await ConversationOrdersAPI.updateOrder(
        conversationId,
        orderId,
        orderData
      );
      commit(types.UPDATE_CONVERSATION_ORDER, { conversationId, data });
      return data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CONVERSATION_ORDERS_UI_FLAG, { isUpdating: false });
    }
  },

  async delete({ commit }, { conversationId, orderId }) {
    commit(types.SET_CONVERSATION_ORDERS_UI_FLAG, { isDeleting: true });
    try {
      await ConversationOrdersAPI.deleteOrder(conversationId, orderId);
      commit(types.DELETE_CONVERSATION_ORDER, { conversationId, orderId });
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CONVERSATION_ORDERS_UI_FLAG, { isDeleting: false });
    }
  },

  async pushOrder({ commit }, { conversationId, orderId }) {
    commit(types.SET_CONVERSATION_ORDERS_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await ConversationOrdersAPI.pushOrder(
        conversationId,
        orderId
      );
      commit(types.UPDATE_CONVERSATION_ORDER, { conversationId, data });
      return data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CONVERSATION_ORDERS_UI_FLAG, { isUpdating: false });
    }
  },

  async syncOrder({ commit }, { conversationId, orderId }) {
    commit(types.SET_CONVERSATION_ORDERS_UI_FLAG, { isUpdating: true });
    try {
      const { data } = await ConversationOrdersAPI.syncOrder(
        conversationId,
        orderId
      );
      commit(types.UPDATE_CONVERSATION_ORDER, { conversationId, data });
      return data;
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_CONVERSATION_ORDERS_UI_FLAG, { isUpdating: false });
    }
  },
};

export const mutations = {
  [types.SET_CONVERSATION_ORDERS_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_CONVERSATION_ORDERS]($state, { conversationId, data }) {
    $state.records = {
      ...$state.records,
      [conversationId]: data,
    };
  },

  [types.ADD_CONVERSATION_ORDER]($state, { conversationId, data }) {
    const orders = $state.records[conversationId] || [];
    $state.records = {
      ...$state.records,
      [conversationId]: [...orders, data],
    };
  },

  [types.UPDATE_CONVERSATION_ORDER]($state, { conversationId, data }) {
    const orders = $state.records[conversationId] || [];
    const updatedOrders = orders.map(order =>
      order.id === data.id ? data : order
    );
    $state.records = {
      ...$state.records,
      [conversationId]: updatedOrders,
    };
  },

  [types.DELETE_CONVERSATION_ORDER]($state, { conversationId, orderId }) {
    const orders = $state.records[conversationId] || [];
    $state.records = {
      ...$state.records,
      [conversationId]: orders.filter(order => order.id !== orderId),
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
