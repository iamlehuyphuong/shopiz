<template>
  <div class="column content-box">
    <div class="row">
      <div class="small-8 columns with-right-space">
        <h3 class="page-title">
          Tích hợp OmiCall - Gán Số Nội Bộ
        </h3>
        <p class="mb-4 text-slate-600">
          Vui lòng chọn Số máy lẻ tương ứng cho từng nhân sự để hệ thống đồng bộ tài khoản SIP vào Shopiz.
        </p>
        
        <div v-if="loading" class="flex items-center justify-center py-4">
          <woot-spinner size="small" />
          <span class="ml-2">Đang tải danh sách máy lẻ từ OmiCall...</span>
        </div>
        
        <div v-else-if="error" class="bg-red-100 text-red-800 p-4 rounded mb-4">
          {{ error }}
        </div>
        
        <div v-else class="bg-white rounded border border-slate-200">
          <table class="woot-table">
            <thead>
              <tr>
                <th>Nhân viên Shopiz</th>
                <th>Email</th>
                <th>Số Nội Bộ OmiCall</th>
                <th>Thao tác</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="agent in agents" :key="agent.id">
                <td>{{ agent.name }}</td>
                <td>{{ agent.email }}</td>
                <td>
                  <select v-model="selectedExtensions[agent.id]" class="w-full form-input">
                    <option :value="null">-- Chọn số nội bộ --</option>
                    <option v-for="ext in extensions" :key="ext.sip_user" :value="ext">
                      {{ ext.sip_user }} - {{ ext.full_name }} ({{ ext.domain }})
                    </option>
                  </select>
                </td>
                <td>
                  <woot-button 
                    size="small" 
                    variant="hollow" 
                    color="success"
                    @click="mapExtension(agent)"
                    :is-loading="savingAgentId === agent.id"
                  >
                    Lưu
                  </woot-button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';

const store = useStore();
const agents = useMapGetter('agents/getAgents');
const loading = ref(true);
const error = ref('');
const extensions = ref([]);
const selectedExtensions = ref({});
const savingAgentId = ref(null);

const fetchExtensions = async () => {
  loading.value = true;
  error.value = '';
  try {
    const accountId = window.location.pathname.split('/')[2];
    const response = await window.axios.get(`/api/v1/accounts/${accountId}/integrations/omicall/extensions`);
    if (response.data.payload && response.data.payload.items) {
      extensions.value = response.data.payload.items;
      
      // Pre-fill selected extensions based on custom_attributes
      agents.value.forEach(agent => {
        if (agent.custom_attributes?.sip_user) {
          const ext = extensions.value.find(e => e.sip_user === agent.custom_attributes.sip_user);
          if (ext) selectedExtensions.value[agent.id] = ext;
        }
      });
    }
  } catch (err) {
    error.value = 'Không thể lấy danh sách số nội bộ. Vui lòng kiểm tra lại API Key OmiCall trong mục ứng dụng hoặc thử lại sau.';
  } finally {
    loading.value = false;
  }
};

const mapExtension = async (agent) => {
  const selectedExt = selectedExtensions.value[agent.id];
  if (!selectedExt) {
    useAlert('Vui lòng chọn số nội bộ trước khi lưu!');
    return;
  }
  
  savingAgentId.value = agent.id;
  try {
    const accountId = window.location.pathname.split('/')[2];
    await window.axios.post(`/api/v1/accounts/${accountId}/integrations/omicall/map_extension`, {
      user_id: agent.id,
      sip_user: selectedExt.sip_user,
      sip_password: selectedExt.password,
      sip_domain: selectedExt.domain
    });
    
    // update agent in store
    store.commit('agents/UPDATE_AGENT', {
      ...agent,
      custom_attributes: {
        ...agent.custom_attributes,
        sip_user: selectedExt.sip_user,
        sip_password: selectedExt.password,
        sip_domain: selectedExt.domain
      }
    });
    
    useAlert(`Đã gán số ${selectedExt.sip_user} cho ${agent.name} thành công!`);
  } catch (err) {
    useAlert('Có lỗi xảy ra khi lưu thiết lập.');
  } finally {
    savingAgentId.value = null;
  }
};

onMounted(() => {
  store.dispatch('agents/get');
  fetchExtensions();
});
</script>

<style scoped>
.form-input {
  padding: 0.5rem;
  border: 1px solid var(--color-border);
  border-radius: var(--border-radius-normal);
  background: var(--color-background);
  color: var(--color-body);
}
</style>
