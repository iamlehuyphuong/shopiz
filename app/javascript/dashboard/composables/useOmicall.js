import { ref } from 'vue';
import ContactAPI from 'dashboard/api/contacts';
import router from 'dashboard/routes/index';

const isInitialized = ref(false);
const isReady = ref(false);
const connectionStatus = ref('disconnect');
const currentCall = ref(null);

export const useOmicall = () => {
  const initOmicall = async (sipUsername, sipPassword, sipDomain) => {
    if (typeof window.OMICallSDK === 'undefined') {
      console.error('OmiCall SDK not loaded. Ensure core.min.js is injected.');
      return;
    }

    if (!isInitialized.value) {
      try {
        const initSuccess = await window.OMICallSDK.init({
          lng: 'vi',
          ui: {
            toggleDial: 'hide', // Ẩn nút mặc định để dùng nút riêng của Shopiz trên Sidebar
            theme: {
              primary: '#1f93ff', // Màu xanh đặc trưng của Shopiz
            }
          },
          searchRemoteContact: async (callData) => {
            if (!callData || !callData.remoteNumber) return null;
            try {
              // Extract phone number from sip uri like sip:100@domain if needed
              let searchNumber = callData.remoteNumber;
              if (searchNumber.includes('sip:')) {
                searchNumber = searchNumber.split(':')[1].split('@')[0];
              }
              const response = await ContactAPI.search(searchNumber);
              if (response.data.payload && response.data.payload.length > 0) {
                const contact = response.data.payload[0];
                return {
                  name: contact.name,
                  avatar: contact.thumbnail,
                  gender: 'other', // Optional
                  contactId: contact.id, // Store for CTA button
                };
              }
            } catch (error) {
              console.error('Lỗi khi tìm kiếm khách hàng Shopiz:', error);
            }
            return null;
          },
          ctaButtons: {
            exists: [
              {
                action: 'open_profile',
                label: 'Mở Hồ Sơ',
                icon: 'ic_fluent_contact_card_24_filled',
              }
            ],
            onClick: (callData) => {
              if (callData.remoteContact && callData.remoteContact.contactId) {
                const accountId = window.location.pathname.split('/')[2];
                router.push(`/app/accounts/${accountId}/contacts/${callData.remoteContact.contactId}`);
              }
            }
          }
        });
        
        if (!initSuccess) {
          console.error('Lỗi khởi tạo OMICall SDK v3');
          return;
        }
        
        isInitialized.value = true;
      } catch (error) {
        console.error('Error initializing OmiCall SDK:', error);
        return;
      }
    }

    try {
      const registerStatus = await window.OMICallSDK.register({
        sipRealm: sipDomain,
        sipUser: sipUsername,
        sipPassword: sipPassword,
      });

      if (!registerStatus.status) {
        console.error('Lỗi kết nối tổng đài:', registerStatus.message);
        return;
      }

      window.OMICallSDK.on('register', (data) => {
        connectionStatus.value = data.status;
        isReady.value = data.status === 'connected';
      });

      window.OMICallSDK.on('connecting', (call) => {
        currentCall.value = call;
      });
      
      window.OMICallSDK.on('ringing', (call) => {
        currentCall.value = call;
      });

      window.OMICallSDK.on('accepted', (call) => {
        currentCall.value = call;
      });

      window.OMICallSDK.on('ended', () => {
        currentCall.value = null;
      });

    } catch (error) {
      console.error('Error registering OmiCall SIP:', error);
    }
  };

  const makeCall = (phoneNumber) => {
    if (!isReady.value || typeof window.OMICallSDK === 'undefined') {
      console.warn('OmiCall is not ready to make calls.');
      return;
    }
    try {
      window.OMICallSDK.makeCall(phoneNumber);
    } catch (error) {
      console.error('Error making call:', error);
    }
  };

  const toggleDial = () => {
    if (typeof window.OMICallUI !== 'undefined') {
      window.OMICallUI.toggleDial();
    }
  };

  return {
    isInitialized,
    isReady,
    connectionStatus,
    currentCall,
    initOmicall,
    makeCall,
    toggleDial,
  };
};
