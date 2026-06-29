import { ref } from 'vue';
import ContactAPI from 'dashboard/api/contacts';
import router from 'dashboard/routes/index';

const isInitialized = ref(false);
const isReady = ref(false);
const connectionStatus = ref('disconnect');
const currentCall = ref(null);

export const useOmicall = () => {
  const initOmicall = async (sipUsername, sipPassword, sipDomain) => {
    // Wait for the SDK to be injected (up to 5 seconds)
    const waitForSDK = async (retries = 10, delay = 500) => {
      for (let i = 0; i < retries; i++) {
        if (typeof window.OMICallSDK !== 'undefined') return true;
        await new Promise(resolve => setTimeout(resolve, delay));
      }
      return false;
    };

    const isLoaded = await waitForSDK();
    if (!isLoaded) {
      console.error(
        'OmiCall SDK not loaded after retries. Ensure core.min.js is injected.'
      );
      return;
    }

    if (!isInitialized.value) {
      try {
        const initSuccess = await window.OMICallSDK.init({
          lng: 'vi',
          ui: {
            toggleDial: 'hide', // Ẩn nút mặc định để dùng nút riêng của Shopiz trên Sidebar
            theme: {
              primary: '#E06720', // Màu cam đặc trưng của Shopiz
              fontFamily: '"Nunito Sans", -apple-system, system-ui, sans-serif',
            },
          },
          searchRemoteContact: async callData => {
            if (!callData || !callData.remoteNumber) return null;
            try {
              let searchNumber = callData.remoteNumber;
              if (searchNumber.includes('sip:')) {
                searchNumber = searchNumber.split(':')[1].split('@')[0];
              }
              const response = await ContactAPI.search(searchNumber);
              if (response.data.payload && response.data.payload.length > 0) {
                const contact = response.data.payload[0];
                let avatarUrl = contact.thumbnail;
                if (!avatarUrl) {
                  const nameStr = encodeURIComponent(contact.name || 'User');
                  avatarUrl = `https://ui-avatars.com/api/?name=${nameStr}&background=E06720&color=fff&rounded=true&bold=true`;
                }
                return {
                  name: contact.name,
                  avatar: avatarUrl,
                  gender: 'other',
                  contactId: contact.id,
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
                icon: 'data:image/svg+xml;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgc3Ryb2tlPSIjZmZmZmZmIiBzdHJva2Utd2lkdGg9IjIiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCI+PHBhdGggZD0iTTIwIDIxdi0yYTQgNCAwIDAgMC00LTRIOGE0IDQgMCAwIDAtNCA0djIiLz48Y2lyY2xlIGN4PSIxMiIgY3k9IjciIHI9IjQiLz48L3N2Zz4=',
              },
            ],
            onClick: callData => {
              if (callData.remoteContact && callData.remoteContact.contactId) {
                const accountId = window.location.pathname.split('/')[2];
                router.push(
                  `/app/accounts/${accountId}/contacts/${callData.remoteContact.contactId}`
                );
              }
            },
          },
        });

        if (!initSuccess) {
          console.error('Lỗi khởi tạo OMICall SDK v3');
          return;
        }

        // Đăng ký sự kiện chỉ một lần duy nhất trong vòng đời của ứng dụng
        window.OMICallSDK.on('register', data => {
          connectionStatus.value = data.status;
          isReady.value = data.status === 'connected';
        });

        window.OMICallSDK.on('connecting', call => {
          currentCall.value = call;
        });

        window.OMICallSDK.on('ringing', call => {
          currentCall.value = call;
        });

        window.OMICallSDK.on('accepted', call => {
          currentCall.value = call;
        });

        window.OMICallSDK.on('ended', () => {
          currentCall.value = null;
        });

        isInitialized.value = true;
      } catch (error) {
        console.error('Error initializing OmiCall SDK:', error);
        return;
      }
    }

    // Đăng ký kết nối với tổng đài (Register)
    if (connectionStatus.value === 'connected') {
      return;
    }

    try {
      const registerStatus = await window.OMICallSDK.register({
        sipRealm: sipDomain,
        sipUser: sipUsername,
        sipPassword: sipPassword,
      });

      if (!registerStatus.status) {
        console.error(
          'Lỗi kết nối tổng đài:',
          registerStatus.message || 'Unknown error'
        );
      }
    } catch (error) {
      console.error('Error registering OmiCall SIP:', error);
    }
  };

  const makeCall = phoneNumber => {
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
