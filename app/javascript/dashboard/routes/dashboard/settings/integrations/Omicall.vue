<script>
import { isEmptyObject } from '../../../../helper/commons';
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import { useIntegrationHook } from 'dashboard/composables/useIntegrationHook';
import NewHook from './NewHook.vue';
import SingleIntegrationHooks from './SingleIntegrationHooks.vue';
import SettingsLayout from '../SettingsLayout.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';
import Avatar from 'next/avatar/Avatar.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import FilterSelect from 'dashboard/components-next/filter/inputs/FilterSelect.vue';

export default {
  components: {
    NewHook,
    SingleIntegrationHooks,
    SettingsLayout,
    BaseSettingsHeader,
    Avatar,
    Button,
    FilterSelect,
  },
  setup() {
    const integrationId = 'omicall';

    const { integration, isIntegrationSingle, hasConnectedHooks } =
      useIntegrationHook(integrationId);

    return {
      integrationId,
      integration,
      isIntegrationSingle,
      hasConnectedHooks,
    };
  },
  data() {
    return {
      showAddHookModal: false,
      showDeleteConfirmationPopup: false,
      selectedHook: {},
      alertMessage: '',

      // Omicall specific data
      loadingExtensions: true,
      errorExtensions: '',
      extensions: [],
      selectedExtensions: {},
      savingAgentId: null,
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'integrations/getUIFlags',
      agents: 'agents/getAgents',
    }),
    showIntegrationHooks() {
      return !this.uiFlags.isFetching && !isEmptyObject(this.integration);
    },
    deleteTitle() {
      return this.$t('INTEGRATION_APPS.DELETE.TITLE.ACCOUNT');
    },
    deleteMessage() {
      return this.$t('INTEGRATION_APPS.DELETE.MESSAGE.ACCOUNT');
    },
    confirmText() {
      return this.$t('INTEGRATION_APPS.DELETE.CONFIRM_BUTTON_TEXT.ACCOUNT');
    },
    cancelText() {
      return this.$t('INTEGRATION_APPS.DELETE.CANCEL_BUTTON_TEXT');
    },
  },
  watch: {
    hasConnectedHooks(newVal) {
      if (newVal) {
        this.fetchExtensions();
      }
    },
  },
  mounted() {
    this.$store.dispatch('integrations/get');
    this.$store.dispatch('agents/get');
    if (this.hasConnectedHooks) {
      this.fetchExtensions();
    }
  },
  methods: {
    openAddHookModal() {
      this.showAddHookModal = true;
    },
    hideAddHookModal() {
      this.showAddHookModal = false;
    },
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedHook = response;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    async confirmDeletion() {
      try {
        await this.$store.dispatch('integrations/deleteHook', {
          hookId: this.selectedHook.id,
          appId: this.selectedHook.app_id,
        });
        this.alertMessage = this.$t(
          'INTEGRATION_APPS.DELETE.API.SUCCESS_MESSAGE'
        );
        this.closeDeletePopup();
      } catch (error) {
        const errorMessage = error?.response?.data?.message;
        this.alertMessage =
          errorMessage || this.$t('INTEGRATION_APPS.DELETE.API.ERROR_MESSAGE');
      } finally {
        useAlert(this.alertMessage);
      }
    },

    // Omicall specific methods
    async fetchExtensions() {
      this.loadingExtensions = true;
      this.errorExtensions = '';
      try {
        const accountId = this.$store.getters.getCurrentAccountId;
        const response = await window.axios.get(
          `/api/v1/accounts/${accountId}/integrations/omicall/extensions`
        );
        if (response.data.payload && response.data.payload.items) {
          this.extensions = response.data.payload.items;

          this.agents.forEach(agent => {
            const sipUser = agent.omicall_sip_info?.sip_user;
            if (sipUser) {
              const ext = this.extensions.find(e => e.sip_user === sipUser);
              this.selectedExtensions[agent.id] = ext ? ext.sip_user : '';
            } else {
              this.selectedExtensions[agent.id] = '';
            }
          });
        }
      } catch (err) {
        this.errorExtensions =
          'Không thể lấy danh sách số nội bộ. Vui lòng kiểm tra lại API Key OmiCall trong mục ứng dụng hoặc thử lại sau.';
      } finally {
        this.loadingExtensions = false;
      }
    },
    async mapExtension(agent) {
      const selectedSipUser = this.selectedExtensions[agent.id];
      if (!selectedSipUser) {
        useAlert('Vui lòng chọn số nội bộ trước khi lưu!');
        return;
      }

      const selectedExt = this.extensions.find(e => e.sip_user === selectedSipUser);
      if (!selectedExt) {
        useAlert('Số nội bộ không hợp lệ!');
        return;
      }

      this.savingAgentId = agent.id;
      try {
        const accountId = this.$store.getters.getCurrentAccountId;
        await window.axios.post(
          `/api/v1/accounts/${accountId}/integrations/omicall/map_extension`,
          {
            user_id: agent.id,
            sip_user: selectedExt.sip_user,
            sip_password: selectedExt.password,
            sip_domain: selectedExt.domain,
            outbound_proxy: selectedExt.outbound_proxy,
          }
        );

        const sipInfo = {
          sip_user: selectedExt.sip_user,
          sip_password: selectedExt.password,
          sip_domain: selectedExt.domain,
          outbound_proxy: selectedExt.outbound_proxy,
        };

        this.$store.commit('agents/UPDATE_AGENT', {
          ...agent,
          omicall_sip_info: sipInfo,
        });

        // If the mapped agent is the current user, update auth store as well
        if (agent.id === this.$store.getters.getCurrentUserID) {
          const currentUser = this.$store.getters.getCurrentUser;
          this.$store.commit('SET_CURRENT_USER', {
            ...currentUser,
            omicall_sip_info: sipInfo,
          });
        }

        useAlert(
          `Đã gán số ${selectedExt.sip_user} cho ${agent.name} thành công!`
        );
      } catch (err) {
        useAlert('Có lỗi xảy ra khi lưu thiết lập.');
      } finally {
        this.savingAgentId = null;
      }
    },
  },
};
</script>

<template>
  <!-- eslint-disable vue/no-bare-strings-in-template -->
  <!-- eslint-disable prettier/prettier -->
  <SettingsLayout :is-loading="uiFlags.isFetching">
    <template v-if="isIntegrationSingle" #header>
      <BaseSettingsHeader
        :title="integration.name || ''"
        description=""
        :feature-name="integrationId"
        :back-button-label="
          $route.path.includes('/sales/')
            ? $t('SALES.MODULE_TOOLS.HEADER.TITLE')
            : $t('INTEGRATION_SETTINGS.HEADER')
        "
      />
    </template>
    <template #body>
      <div v-if="showIntegrationHooks" class="w-full flex flex-col gap-6">
        <div v-if="isIntegrationSingle">
          <SingleIntegrationHooks
            :integration-id="integrationId"
            @add="openAddHookModal"
            @delete="openDeletePopup"
          />
        </div>

        <!-- Extension Mapping Card -->
        <div v-if="hasConnectedHooks" class="mt-2">
          <div class="row">
            <div class="small-12 columns">
              <div class="flex items-center justify-between mb-2">
                <h3 class="page-title text-lg font-medium text-n-slate-12 mb-0">
                  Quản Lý Số Nội Bộ
                </h3>
                <woot-button
                  class="text-sm font-normal !bg-[#e46a25] !border-[#e46a25] text-white hover:!bg-[#c9591c] !px-4 !py-1.5 !rounded-lg"
                  :is-loading="loadingExtensions"
                  @click="fetchExtensions"
                >
                  Lấy số nội bộ
                </woot-button>
              </div>
              <p class="mb-4 text-slate-600 text-sm text-n-slate-11">
                Vui lòng chọn Số máy lẻ tương ứng cho từng nhân sự để hệ thống
                đồng bộ tài khoản SIP vào Shopiz.
              </p>

              <div
                v-if="loadingExtensions"
                class="flex items-center justify-center py-4"
              >
                <woot-spinner size="small" />
                <span class="ml-2">Đang tải danh sách máy lẻ từ OmiCall...</span>
              </div>

              <div
                v-else-if="errorExtensions"
                class="bg-red-100 text-red-800 p-4 rounded mb-4"
              >
                {{ errorExtensions }}
              </div>

              <div v-else class="mt-6">
                <!-- Header Row -->
                <div class="grid grid-cols-12 gap-4 pb-2 border-b border-n-strong px-2">
                  <div class="col-span-3 text-sm font-bold text-n-slate-11">
                    Nhân viên
                  </div>
                  <div class="col-span-4 text-sm font-bold text-n-slate-11">
                    Email
                  </div>
                  <div class="col-span-4 text-sm font-bold text-n-slate-11">
                    Số nội bộ
                  </div>
                  <div class="col-span-1 text-sm font-bold text-n-slate-11 text-right">
                    Thao tác
                  </div>
                </div>

                <!-- Body Rows -->
                <div class="flex flex-col">
                  <div
                    v-for="agent in agents"
                    :key="agent.id"
                    class="grid grid-cols-12 gap-4 py-4 px-2 items-center border-b border-n-weak last:border-b-0"
                  >
                    <!-- Tên + Avatar -->
                    <div class="col-span-3 flex items-center gap-3">
                      <Avatar
                        :src="agent.thumbnail"
                        :name="agent.name"
                        :status="agent.availability_status"
                        :size="36"
                        hide-offline-status
                        branded
                      />
                      <div class="flex flex-col justify-center min-w-0">
                        <span class="text-sm font-medium text-n-slate-12 capitalize truncate leading-none">
                          {{ agent.name }}
                        </span>
                        <span class="text-xs text-n-slate-11 truncate mt-1.5 leading-none">
                          {{ agent.role ? $t(`AGENT_MGMT.AGENT_TYPES.${agent.role.toUpperCase()}`) : 'Nhân viên' }}
                        </span>
                      </div>
                    </div>

                    <!-- Email -->
                    <div class="col-span-4 flex items-center gap-2 truncate">
                      <span class="text-body-main text-n-slate-11 truncate">{{ agent.email }}</span>
                    </div>

                    <!-- Dropdown -->
                    <div class="col-span-4 pr-4">
                      <FilterSelect
                        v-model="selectedExtensions[agent.id]"
                        :options="[
                          { value: '', label: 'Chưa gán số nội bộ' },
                          ...extensions.map(ext => ({
                            value: ext.sip_user,
                            label: `${ext.sip_user} - ${ext.full_name} (${ext.domain})`
                          }))
                        ]"
                        class="w-full mt-1 !mb-0 [&_button]:w-full [&_button]:justify-between [&>.absolute]:w-full [&_.min-w-56]:!min-w-full [&_.min-w-56]:!w-full [&_button]:!h-[38px] [&_button]:!border-n-weak [&_button]:!bg-n-alpha-1"
                      />
                    </div>

                    <!-- Action -->
                    <div class="col-span-1 flex justify-end items-center">
                      <button
                        v-tooltip.top="'Lưu'"
                        class="w-9 h-9 flex items-center justify-center text-slate-500 hover:text-slate-700 hover:bg-slate-50 dark:hover:bg-n-solid-2 transition-colors bg-white dark:bg-n-solid-1 border border-slate-500 dark:border-slate-400 rounded-lg outline outline-1 outline-slate-300 dark:outline-slate-600 cursor-pointer shadow-none"
                        :disabled="savingAgentId === agent.id"
                        @click="mapExtension(agent)"
                      >
                        <woot-spinner v-if="savingAgentId === agent.id" size="small" />
                        <i v-else class="i-lucide-save text-sm font-light" style="stroke-width: 1.5" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </template>

    <woot-modal v-model:show="showAddHookModal" :on-close="hideAddHookModal">
      <NewHook :integration-id="integrationId" @close="hideAddHookModal" />
    </woot-modal>

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="deleteTitle"
      :message="deleteMessage"
      :confirm-text="confirmText"
      :reject-text="cancelText"
    />
  </SettingsLayout>
</template>
