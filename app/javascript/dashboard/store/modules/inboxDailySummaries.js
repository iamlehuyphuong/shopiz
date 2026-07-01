import types from '../mutation-types';
import InboxDailySummariesAPI from '../../api/inboxDailySummaries';

export const state = {
  record: null,
  uiFlags: {
    isFetching: false,
    isUpdating: false,
  },
};

export const getters = {
  getRecord(_state) {
    return _state.record || {};
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
};

export const actions = {
  get: async ({ commit }) => {
    commit(types.SET_INBOX_DAILY_SUMMARIES_UI_FLAG, { isFetching: true });
    try {
      const response = await InboxDailySummariesAPI.get();
      // Since it's a singleton, the controller returns a single object
      commit(types.SET_INBOX_DAILY_SUMMARIES, response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_INBOX_DAILY_SUMMARIES_UI_FLAG, { isFetching: false });
    }
  },
  update: async ({ commit }, { id, ...data }) => {
    commit(types.SET_INBOX_DAILY_SUMMARIES_UI_FLAG, { isUpdating: true });
    try {
      // Pass the id to satisfy the RESTful route, even though the backend acts as a singleton
      const response = await InboxDailySummariesAPI.update(id, data);
      commit(types.SET_INBOX_DAILY_SUMMARIES, response.data);
      return response.data;
    } finally {
      commit(types.SET_INBOX_DAILY_SUMMARIES_UI_FLAG, { isUpdating: false });
    }
  },
};

export const mutations = {
  [types.SET_INBOX_DAILY_SUMMARIES_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },
  [types.SET_INBOX_DAILY_SUMMARIES](_state, data) {
    _state.record = data;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
