import { describe, it, expect, vi } from 'vitest';
import { defineComponent, h } from 'vue';
import { createStore } from 'vuex';
import { mount } from '@vue/test-utils';
import { useInbox } from '../useInbox';
import { INBOX_TYPES } from 'dashboard/helper/inbox';

vi.mock('dashboard/composables/store');
vi.mock('dashboard/composables/useTransformKeys');

// Mock the dependencies
const mockStore = createStore({
  modules: {
    conversations: {
      namespaced: false,
      getters: {
        getSelectedChat: () => ({ inbox_id: 1 }),
      },
    },
    inboxes: {
      namespaced: true,
      getters: {
        getInboxById: () => id => {
          const inboxes = {
            1: {
              id: 1,
              channel_type: INBOX_TYPES.WHATSAPP,
              provider: 'whatsapp_cloud',
            },
            11: { id: 11, channel_type: INBOX_TYPES.API },
            13: { id: 13, channel_type: INBOX_TYPES.INSTAGRAM },
            15: { id: 15, channel_type: INBOX_TYPES.TIKTOK },
          };
          return inboxes[id] || null;
        },
      },
    },
  },
});

// Mock useMapGetter to return mock store getters
vi.mock('dashboard/composables/store', () => ({
  useMapGetter: vi.fn(getter => {
    if (getter === 'getSelectedChat') {
      return { value: { inbox_id: 1 } };
    }
    if (getter === 'inboxes/getInboxById') {
      return { value: mockStore.getters['inboxes/getInboxById'] };
    }
    return { value: null };
  }),
}));

// Mock useCamelCase to return the data as-is for testing
vi.mock('dashboard/composables/useTransformKeys', () => ({
  useCamelCase: vi.fn(data => ({
    ...data,
    channelType: data?.channel_type,
  })),
}));

describe('useInbox', () => {
  const createTestComponent = inboxId =>
    defineComponent({
      setup() {
        return useInbox(inboxId);
      },
      render() {
        return h('div');
      },
    });

  describe('with current chat context (no inboxId provided)', () => {
    it('identifies WhatsApp Cloud channel correctly', () => {
      const wrapper = mount(createTestComponent(), {
        global: { plugins: [mockStore] },
      });

      expect(wrapper.vm.isAWhatsAppCloudChannel).toBe(true);
      expect(wrapper.vm.isAWhatsAppChannel).toBe(true);
    });

    it('returns correct inbox object', () => {
      const wrapper = mount(createTestComponent(), {
        global: { plugins: [mockStore] },
      });

      expect(wrapper.vm.inbox).toEqual({
        id: 1,
        channel_type: INBOX_TYPES.WHATSAPP,
        provider: 'whatsapp_cloud',
        channelType: INBOX_TYPES.WHATSAPP,
      });
    });
  });

  describe('with explicit inboxId provided', () => {
    it('identifies Facebook inbox correctly', () => {
      const wrapper = mount(createTestComponent(2), {
        global: { plugins: [mockStore] },
      });

      expect(wrapper.vm.isAFacebookInbox).toBe(true);
      expect(wrapper.vm.isAWhatsAppChannel).toBe(false);
    });

    it('identifies 360Dialog WhatsApp channel correctly', () => {
      const wrapper = mount(createTestComponent(7), {
        global: { plugins: [mockStore] },
      });

      expect(wrapper.vm.is360DialogWhatsAppChannel).toBe(true);
      expect(wrapper.vm.isAWhatsAppChannel).toBe(true);
      expect(wrapper.vm.isAWhatsAppCloudChannel).toBe(false);
    });

    it('identifies all other channel types correctly', () => {
      // Test Telegram
      let wrapper = mount(createTestComponent(8), {
        global: { plugins: [mockStore] },
      });
      expect(wrapper.vm.isATelegramChannel).toBe(true);

      // Test Web Widget
      wrapper = mount(createTestComponent(10), {
        global: { plugins: [mockStore] },
      });
      expect(wrapper.vm.isAWebWidgetInbox).toBe(true);

      // Test API
      wrapper = mount(createTestComponent(11), {
        global: { plugins: [mockStore] },
      });
      expect(wrapper.vm.isAPIInbox).toBe(true);

      // Test Instagram
      wrapper = mount(createTestComponent(13), {
        global: { plugins: [mockStore] },
      });
      expect(wrapper.vm.isAnInstagramChannel).toBe(true);

      // Test Tiktok
      wrapper = mount(createTestComponent(15), {
        global: { plugins: [mockStore] },
      });
      expect(wrapper.vm.isATiktokChannel).toBe(true);
    });
  });

  describe('edge cases', () => {
    it('handles non-existent inbox ID gracefully', () => {
      const wrapper = mount(createTestComponent(999), {
        global: { plugins: [mockStore] },
      });

      // useCamelCase still processes null data, so we get an object with channelType: undefined
      expect(wrapper.vm.inbox).toEqual({ channelType: undefined });
      expect(wrapper.vm.isAWhatsAppChannel).toBe(false);
      expect(wrapper.vm.isAFacebookInbox).toBe(false);
    });

    it('handles inbox with no data correctly', () => {
      // The mock will return null for non-existent IDs, but useCamelCase processes it
      const wrapper = mount(createTestComponent(999), {
        global: { plugins: [mockStore] },
      });

      expect(wrapper.vm.inbox.channelType).toBeUndefined();
      expect(wrapper.vm.isAWhatsAppChannel).toBe(false);
      expect(wrapper.vm.isAFacebookInbox).toBe(false);
      expect(wrapper.vm.isATelegramChannel).toBe(false);
    });
  });

  describe('return object completeness', () => {
    it('returns all expected properties', () => {
      const wrapper = mount(createTestComponent(1), {
        global: { plugins: [mockStore] },
      });

      const expectedProperties = [
        'inbox',
        'isAFacebookInbox',
        'isAPIInbox',
        'isATelegramChannel',
        'isAWebWidgetInbox',
        'isAWhatsAppChannel',
        'isAWhatsAppCloudChannel',
        'is360DialogWhatsAppChannel',
        'isAnInstagramChannel',
        'isATiktokChannel',
      ];

      expectedProperties.forEach(prop => {
        expect(wrapper.vm).toHaveProperty(prop);
      });
    });
  });
});
