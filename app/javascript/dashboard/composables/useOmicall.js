import { ref } from 'vue';
import ContactAPI from 'dashboard/api/contacts';
import router from 'dashboard/routes/index';
import { useAlert } from 'dashboard/composables';

const OMICALL_SDK_URL = 'https://cdn.omicrm.com/sdk/web/3.0.41/core.min.js';

const isInitialized = ref(false);
const isReady = ref(false);
const connectionStatus = ref('disconnect');
const currentCall = ref(null);
const currentSipUser = ref(null);
const sipCredentials = ref(null);
const isOmicallConfigured = ref(false);
const isRegistering = ref(false);
const isSDKLoading = ref(false);

const checkIsConnected = status => {
  if (!status) return false;
  const s = status.toLowerCase();
  return ['connected', 'registered', 'success'].includes(s);
};

/**
 * Dynamically injects the OMICall SDK script into the page.
 * Returns a promise that resolves to true when the SDK global is available,
 * or false if loading fails.
 */
const loadSDK = async () => {
  // Already available
  if (typeof window.OMICallSDK !== 'undefined') return true;

  // Already loading — just wait for it
  if (isSDKLoading.value) {
    const waitForGlobal = async (retries = 20, delay = 500) => {
      for (let i = 0; i < retries; i++) {
        if (typeof window.OMICallSDK !== 'undefined') return true;
        await new Promise(resolve => setTimeout(resolve, delay));
      }
      return false;
    };
    return waitForGlobal();
  }

  isSDKLoading.value = true;

  return new Promise(resolve => {
    const script = document.createElement('script');
    script.setAttribute('omi-call-sdk', '');
    script.src = OMICALL_SDK_URL;
    script.async = true;

    script.onload = async () => {
      // SDK script loaded — wait for global to become available
      const waitForGlobal = async (retries = 20, delay = 250) => {
        for (let i = 0; i < retries; i++) {
          if (typeof window.OMICallSDK !== 'undefined') return true;
          await new Promise(r => setTimeout(r, delay));
        }
        return false;
      };
      const available = await waitForGlobal();
      isSDKLoading.value = false;
      resolve(available);
    };

    script.onerror = () => {
      isSDKLoading.value = false;
      console.error('Failed to load OmiCall SDK from CDN.');
      resolve(false);
    };

    document.head.appendChild(script);
  });
};

export const useOmicall = () => {
  const initOmicall = async (sipUsername, sipPassword, sipDomain) => {
    isOmicallConfigured.value = true;
    sipCredentials.value = { sipUsername, sipPassword, sipDomain };

    // Lazy-load the SDK only when we actually have credentials
    const isLoaded = await loadSDK();
    if (!isLoaded) {
      console.error(
        'OmiCall SDK not loaded after retries. Ensure CDN is reachable.'
      );
      return;
    }

    if (!window.OMICallSDK_Initialized) {
      const hideStyle = document.getElementById('omicall-hide-ui');
      if (hideStyle) hideStyle.remove();

      try {
        const initSuccess = await window.OMICallSDK.init({
          lng: 'vi',
          ui: {
            toggleDial: 'hide', // Ẩn nút mặc định để dùng nút riêng của Shopiz trên Sidebar
          },
          searchRemoteContact: async callData => {
            if (!isOmicallConfigured.value) return null;
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
              },
            ],
            onClick: callData => {
              if (!isOmicallConfigured.value) return;
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
          if (!isOmicallConfigured.value) return;
          const statusStr =
            typeof data === 'string' ? data : data?.status || 'unknown';
          connectionStatus.value = statusStr;
          isReady.value = checkIsConnected(statusStr);
          console.log('[OMICall] register event received:', statusStr);
        });

        window.OMICallSDK.on('connecting', call => {
          if (!isOmicallConfigured.value) return;
          currentCall.value = call;
        });

        window.OMICallSDK.on('ringing', call => {
          if (!isOmicallConfigured.value) return;
          currentCall.value = call;
        });

        window.OMICallSDK.on('accepted', call => {
          if (!isOmicallConfigured.value) return;
          currentCall.value = call;
        });

        window.OMICallSDK.on('ended', () => {
          if (!isOmicallConfigured.value) return;
          currentCall.value = null;
        });

        // Xử lý ghi đè màu text bị ám cam từ primary theme của OMiCall SDK
        if (!document.getElementById('omicall-custom-styles')) {
          const style = document.createElement('style');
          style.id = 'omicall-custom-styles';
          style.innerHTML = `
            .omi-custom-theme ::-webkit-scrollbar-thumb {
              background-color: #cbd5e1 !important;
              border-radius: 4px !important;
            }
            .omi-custom-theme ::-webkit-scrollbar-track {
              background-color: transparent !important;
            }
            .omi-custom-theme input::placeholder,
            .omi-custom-theme textarea::placeholder {
              color: #9ca3af !important;
            }
            .omi-custom-theme input::-webkit-input-placeholder,
            .omi-custom-theme textarea::-webkit-input-placeholder {
              color: #9ca3af !important;
            }
          `;
          document.head.appendChild(style);
        }

        const applyCustomTextColors = () => {
          try {
            const headings = document.evaluate(
              "//text()[normalize-space()='Thông tin cuộc gọi']/parent::*",
              document,
              null,
              XPathResult.UNORDERED_NODE_SNAPSHOT_TYPE,
              null
            );
            for (let i = 0; i < headings.snapshotLength; i++) {
              let headingEl = headings.snapshotItem(i);
              headingEl.style.setProperty('color', '#000000', 'important');

              // Tìm popup wrapper để gán theme ghi đè scrollbar & placeholder
              let parent = headingEl.parentElement;
              while (parent && parent !== document.body) {
                const pos = window.getComputedStyle(parent).position;
                if (pos === 'fixed' || pos === 'absolute') {
                  parent.classList.add('omi-custom-theme');
                  break;
                }
                parent = parent.parentElement;
              }
            }
          } catch (e) {
            // ignore
          }
        };

        const observer = new MutationObserver(mutations => {
          let hasNewNodes = false;
          for (let m of mutations) {
            if (m.addedNodes.length > 0) {
              hasNewNodes = true;
              break;
            }
          }
          if (hasNewNodes) {
            applyCustomTextColors();
          }
        });
        observer.observe(document.body, { childList: true, subtree: true });

        window.OMICallSDK_Initialized = true;
      } catch (error) {
        console.error('Error initializing OmiCall SDK:', error);
        return;
      }
    }

    isInitialized.value = true;

    // Đăng ký kết nối với tổng đài (Register)
    const isCurrentlyConnected = checkIsConnected(connectionStatus.value);

    if (
      isCurrentlyConnected &&
      currentSipUser.value === sipUsername
    ) {
      return;
    }

    if (
      isCurrentlyConnected &&
      currentSipUser.value !== sipUsername
    ) {
      try {
        await window.OMICallSDK.unregister();
      } catch (error) {
        console.error('Error unregistering previous OmiCall SIP:', error);
      }
    }

    if (isRegistering.value) return;

    try {
      isRegistering.value = true;
      const registerStatus = await window.OMICallSDK.register({
        sipRealm: sipDomain,
        sipUser: sipUsername,
        sipPassword: sipPassword,
      });

      if (!registerStatus.status) {
        const errorMsg = registerStatus.message || 'Unknown error';
        console.error(
          '[OMICall] Lỗi kết nối tổng đài (Register failed):',
          errorMsg,
          '| SIP User:', sipUsername,
          '| SIP Domain:', sipDomain
        );
        if (registerStatus.message) {
          useAlert(`Lỗi kết nối OMICall: ${errorMsg}`);
        }
      } else {
        currentSipUser.value = sipUsername;
        connectionStatus.value = 'registered';
        isReady.value = true;
      }
    } catch (error) {
      console.error('Error registering OmiCall SIP:', error);
    } finally {
      isRegistering.value = false;
    }
  };

  const resetOmicall = async () => {
    if (typeof window.OMICallSDK !== 'undefined' && isInitialized.value) {
      try {
        await window.OMICallSDK.unregister();
      } catch (error) {
        console.error('Error unregistering OmiCall SIP:', error);
      }
    }
    isInitialized.value = false;
    isReady.value = false;
    connectionStatus.value = 'disconnect';
    currentCall.value = null;
    currentSipUser.value = null;
    sipCredentials.value = null;
    isOmicallConfigured.value = false;

    // Hide any OMICall SDK injected UI (widgets, etc.)
    let hideStyle = document.getElementById('omicall-hide-ui');
    if (!hideStyle) {
      hideStyle = document.createElement('style');
      hideStyle.id = 'omicall-hide-ui';
      hideStyle.innerHTML =
        '#omicall-ui-container, .omi-custom-theme { display: none !important; }';
      document.head.appendChild(hideStyle);
    }
  };

  const makeCall = async phoneNumber => {
    if (!isOmicallConfigured.value || !sipCredentials.value) {
      useAlert('Chưa có thông tin cấu hình OMiCall cho tài khoản này.');
      return;
    }

    if (typeof window.OMICallSDK === 'undefined') {
      useAlert('SDK OMiCall chưa được tải. Vui lòng tải lại trang.');
      return;
    }

    // Nếu rớt kết nối, thử register lại
    if (!checkIsConnected(connectionStatus.value)) {
      if (isRegistering.value) {
        useAlert('Đang kết nối tổng đài, vui lòng đợi trong giây lát...');
        return;
      }

      useAlert('Đang kết nối lại với tổng đài OMiCall...');
      try {
        isRegistering.value = true;
        const registerStatus = await window.OMICallSDK.register({
          sipRealm: sipCredentials.value.sipDomain,
          sipUser: sipCredentials.value.sipUsername,
          sipPassword: sipCredentials.value.sipPassword,
        });

        if (!registerStatus.status) {
          useAlert(
            'Lỗi kết nối tổng đài: ' +
              (registerStatus.message || 'Unknown error')
          );
          return;
        }

        currentSipUser.value = sipCredentials.value.sipUsername;
        connectionStatus.value = 'registered';
        isReady.value = true;
        // Đợi 500ms để đảm bảo socket connected event được nhận diện
        await new Promise(resolve => setTimeout(resolve, 500));
      } catch (error) {
        console.error('Error reconnecting OmiCall SIP:', error);
        useAlert('Lỗi kết nối tổng đài OMiCall.');
        return;
      } finally {
        isRegistering.value = false;
      }
    }

    if (!checkIsConnected(connectionStatus.value)) {
      useAlert('Tổng đài OMiCall chưa sẵn sàng. Vui lòng thử lại sau.');
      return;
    }
    try {
      let formattedNumber = phoneNumber;
      if (formattedNumber && formattedNumber.startsWith('+84')) {
        formattedNumber = '0' + formattedNumber.slice(3);
      }
      window.OMICallSDK.makeCall(formattedNumber);
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
    resetOmicall,
    makeCall,
    toggleDial,
    isOmicallConfigured,
  };
};
