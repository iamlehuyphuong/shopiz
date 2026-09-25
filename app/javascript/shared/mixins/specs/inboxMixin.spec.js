import { shallowMount } from '@vue/test-utils';
import inboxMixin from '../inboxMixin';

function getComponentConfigForInbox(channelType, additionalConfig = {}) {
  return {
    render() {},
    mixins: [inboxMixin],
    data() {
      return {
        inbox: {
          channel_type: channelType,
          ...additionalConfig,
        },
      };
    },
  };
}

function getComponentConfigForChat(chat) {
  return {
    render() {},
    mixins: [inboxMixin],
    data() {
      return {
        chat,
      };
    },
  };
}

describe('inboxMixin', () => {
  it('returns the correct channel type', () => {
    const Component = getComponentConfigForInbox('Channel::WebWidget');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.channelType).toBe('Channel::WebWidget');
  });

  it('isAPIInbox returns true if channel type is API', () => {
    const Component = getComponentConfigForInbox('Channel::Api');
    const wrapper = shallowMount(Component);
    expect(wrapper.vm.isAPIInbox).toBe(true);
  });

  describe('Badges', () => {
    it('inboxBadge returns string Channel::Telegram if channel is Telegram', () => {
      const Component = getComponentConfigForInbox('Channel::Telegram');
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.channelType).toBe('Channel::Telegram');
    });
    it('inboxBadge returns correct badge for WhatsApp channel', () => {
      const Component = getComponentConfigForInbox('Channel::Whatsapp');
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.inboxBadge).toBe('whatsapp');
    });

    it('inboxBadge returns "whatsapp" when isAWhatsAppChannel is true', () => {
      const Component = getComponentConfigForInbox('Channel::Whatsapp');
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.inboxBadge).toBe('whatsapp');
    });

    it('inboxBadge returns the channelType when no specific condition is true', () => {
      const Component = getComponentConfigForInbox('Channel::Unknown');
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.inboxBadge).toBe('Channel::Unknown');
    });
  });

  describe('#inboxHasFeature', () => {
    it('detects the correct feature', () => {
      const Component = getComponentConfigForInbox('Channel::Telegram');
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.inboxHasFeature('replyTo')).toBe(true);
      expect(wrapper.vm.inboxHasFeature('feature-does-not-exist')).toBe(false);
    });
  });

  describe('WhatsApp channel', () => {
    it('returns correct whatsAppAPIProvider', () => {
      const Component = getComponentConfigForInbox('Channel::Whatsapp', {
        provider: 'whatsapp_cloud',
      });
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.whatsAppAPIProvider).toBe('whatsapp_cloud');
    });

    it('returns empty whatsAppAPIProvider if nothing is present', () => {
      const Component = getComponentConfigForInbox('Channel::Whatsapp', {
        provider: undefined,
      });
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.whatsAppAPIProvider).toBe('');
    });

    it('isAWhatsAppCloudChannel returns true if channel type is WhatsApp and provider is whatsapp_cloud', () => {
      const Component = getComponentConfigForInbox('Channel::Whatsapp', {
        provider: 'whatsapp_cloud',
      });
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.isAWhatsAppCloudChannel).toBe(true);
    });

    it('is360DialogWhatsAppChannel returns true if channel type is WhatsApp and provider is default', () => {
      const Component = getComponentConfigForInbox('Channel::Whatsapp', {
        provider: 'default',
      });
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.is360DialogWhatsAppChannel).toBe(true);
    });

    it('isAWhatsAppChannel returns true if channel type is WhatsApp', () => {
      const Component = getComponentConfigForInbox('Channel::Whatsapp');
      const wrapper = shallowMount(Component);
      expect(wrapper.vm.isAWhatsAppChannel).toBe(true);
    });
  });
});
