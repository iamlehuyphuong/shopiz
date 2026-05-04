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
    const entry = _state.records[conversationId];
    if (!entry) return [];
    // Support both old (array) and new (object) formats
    const orders = Array.isArray(entry)
      ? entry
      : entry.conversationOrders || [];
    return [...orders].sort((a, b) => b.id - a.id);
  },
  getContactOrdersByConversationId: _state => conversationId => {
    const entry = _state.records[conversationId];
    if (!entry || Array.isArray(entry)) return [];
    return entry.contactOrders || [];
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
    // data can be { conversation_orders, contact_orders } or a plain array
    const normalized =
      data.conversation_orders !== undefined
        ? {
            conversationOrders: data.conversation_orders || [],
            contactOrders: data.contact_orders || [],
          }
        : { conversationOrders: data, contactOrders: [] };
    $state.records = {
      ...$state.records,
      [conversationId]: normalized,
    };
  },

  [types.ADD_CONVERSATION_ORDER]($state, { conversationId, data }) {
    const entry = $state.records[conversationId] || {
      conversationOrders: [],
      contactOrders: [],
    };
    const orders = Array.isArray(entry)
      ? entry
      : entry.conversationOrders || [];
    $state.records = {
      ...$state.records,
      [conversationId]: {
        conversationOrders: [...orders, data],
        contactOrders: Array.isArray(entry) ? [] : entry.contactOrders || [],
      },
    };
  },

  [types.UPDATE_CONVERSATION_ORDER]($state, { conversationId, data }) {
    const entry = $state.records[conversationId] || {
      conversationOrders: [],
      contactOrders: [],
    };
    const orders = Array.isArray(entry)
      ? entry
      : entry.conversationOrders || [];
    const updatedOrders = orders.map(order =>
      order.id === data.id ? data : order
    );
    $state.records = {
      ...$state.records,
      [conversationId]: {
        conversationOrders: updatedOrders,
        contactOrders: Array.isArray(entry) ? [] : entry.contactOrders || [],
      },
    };
  },

  [types.DELETE_CONVERSATION_ORDER]($state, { conversationId, orderId }) {
    const entry = $state.records[conversationId] || {
      conversationOrders: [],
      contactOrders: [],
    };
    const orders = Array.isArray(entry)
      ? entry
      : entry.conversationOrders || [];
    $state.records = {
      ...$state.records,
      [conversationId]: {
        conversationOrders: orders.filter(order => order.id !== orderId),
        contactOrders: Array.isArray(entry) ? [] : entry.contactOrders || [],
      },
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
