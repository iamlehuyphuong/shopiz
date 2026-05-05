<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import AccordionItem from 'dashboard/components/Accordion/AccordionItem.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import OrderList from './OrderList.vue';
import OrderForm from './OrderForm.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
  pendingProduct: {
    type: Object,
    default: null,
  },
});

const emit = defineEmits(['product-consumed']);

const { t } = useI18n();
const store = useStore();

const showForm = ref(false);
const editingOrder = ref(null);
const initialProduct = ref(null);
const isOrderListOpen = ref(true);
const isContactOrdersOpen = ref(false);

const currentConversation = useMapGetter('getSelectedChat');
const isEcommerceChannel = computed(() => {
  const channelType = currentConversation.value?.meta?.channel;
  return channelType === 'Channel::TiktokShop' || channelType === 'Channel::Shopee';
});
const contact = computed(() => {
  const conversation = currentConversation.value;
  if (!conversation) return {};
  return (
    store.getters['contacts/getContact'](conversation.meta?.sender?.id) || {}
  );
});

const orders = computed(() =>
  store.getters['conversationOrders/getOrdersByConversationId'](
    props.conversationId
  )
);

const contactOrders = computed(() =>
  store.getters['conversationOrders/getContactOrdersByConversationId'](
    props.conversationId
  )
);

const uiFlags = computed(() => store.getters['conversationOrders/getUIFlags']);

const fetchOrders = () => {
  store.dispatch('conversationOrders/get', {
    conversationId: props.conversationId,
  });
};

const fetchContactDetails = () => {
  const cId = currentConversation.value?.meta?.sender?.id;
  if (cId) {
    store.dispatch('contacts/show', { id: cId });
  }
};

onMounted(() => {
  fetchOrders();
  fetchContactDetails();
});

watch(() => props.conversationId, () => {
  fetchOrders();
  fetchContactDetails();
});

watch(
  () => props.pendingProduct,
  product => {
    if (product) {
      // Find an existing order that we can edit (prefer draft, processing, confirmed)
      const existingOrder =
        orders.value.find(o =>
          ['draft', 'processing', 'confirmed'].includes(o.status)
        ) || orders.value[0];

      if (existingOrder) {
        editingOrder.value = existingOrder;
      } else {
        editingOrder.value = null;
      }
      initialProduct.value = product;
      showForm.value = true;
      emit('product-consumed');
    }
  },
  { immediate: true }
);

const handleNewOrder = () => {
  editingOrder.value = null;
  showForm.value = true;
};

const handleEditOrder = order => {
  editingOrder.value = order;
  showForm.value = true;
};

const handleFormSaved = () => {
  showForm.value = false;
  editingOrder.value = null;
  useAlert(t('CONVERSATION.ORDER_PANEL.SAVE_SUCCESS'));
};

const handleFormClose = () => {
  showForm.value = false;
  editingOrder.value = null;
  initialProduct.value = null;
};

const handleDeleteOrder = async order => {
  if (!window.confirm(t('CONVERSATION.ORDER_PANEL.DELETE_CONFIRM'))) return;
  try {
    await store.dispatch('conversationOrders/delete', {
      conversationId: props.conversationId,
      orderId: order.id,
    });
    useAlert(t('CONVERSATION.ORDER_PANEL.DELETE_SUCCESS'));
  } catch {
    useAlert(t('CONVERSATION.ORDER_PANEL.DELETE_ERROR'));
  }
};

const handlePushOrder = async order => {
  if (!window.confirm(t('CONVERSATION.ORDER_PANEL.PUSH_CONFIRM'))) return;
  try {
    await store.dispatch('conversationOrders/pushOrder', {
      conversationId: props.conversationId,
      orderId: order.id,
    });
    useAlert(t('CONVERSATION.ORDER_PANEL.PUSH_SUCCESS'));
  } catch (err) {
    useAlert(err.message || t('CONVERSATION.ORDER_PANEL.PUSH_ERROR'));
  }
};

const handleSyncOrder = async order => {
  try {
    await store.dispatch('conversationOrders/syncOrder', {
      conversationId: props.conversationId,
      orderId: order.id,
    });
    useAlert(t('CONVERSATION.ORDER_PANEL.SYNC_SUCCESS'));
  } catch (err) {
    useAlert(err.message || t('CONVERSATION.ORDER_PANEL.SYNC_ERROR'));
  }
};
</script>

<template>
  <div class="flex flex-col w-full h-full">
    <!-- Form Mode -->
    <OrderForm
      v-if="showForm"
      :conversation-id="conversationId"
      :contact="contact"
      :order="editingOrder"
      :initial-product="initialProduct"
      @close="handleFormClose"
      @saved="handleFormSaved"
    />

    <!-- List Mode -->
    <div v-else class="flex flex-col w-full h-full relative">
      <!-- Orders Accordion -->
      <div class="flex-1 overflow-y-auto px-2 pb-4 pt-3">
        <AccordionItem
          :title="t('CONVERSATION.ORDER_PANEL.TITLE')"
          :is-open="isOrderListOpen"
          compact
          @toggle="isOrderListOpen = !isOrderListOpen"
        >
          <template #button>
            <span
              v-if="orders.length"
              class="inline-flex items-center justify-center min-w-[20px] h-5 px-1.5 rounded-full bg-n-alpha-2 text-xs font-medium text-n-slate-11 mr-2"
            >
              {{ orders.length }}
            </span>
          </template>

          <!-- Loading -->
          <div
            v-if="uiFlags.isFetching"
            class="flex items-center justify-center py-6"
          >
            <i class="i-lucide-loader-2 text-n-slate-10 animate-spin text-lg" />
          </div>

          <!-- Orders List -->
          <OrderList
            v-else-if="orders.length"
            :orders="orders"
            :allow-edit="!isEcommerceChannel"
            @edit="handleEditOrder"
            @delete="handleDeleteOrder"
            @push="handlePushOrder"
            @sync="handleSyncOrder"
          />

          <!-- Empty State -->
          <div v-else class="flex flex-col items-center py-6 px-4">
            <div
              class="w-10 h-10 rounded-xl bg-n-solid-3 flex items-center justify-center mb-2.5"
            >
              <i class="i-lucide-shopping-bag text-base text-n-slate-10" />
            </div>
            <p class="text-xs text-n-slate-10 text-center leading-relaxed">
              {{ t('CONVERSATION.ORDER_PANEL.NO_ORDERS') }}
            </p>
          </div>
        </AccordionItem>

        <!-- Contact's Previous Orders -->
        <AccordionItem
          v-if="contactOrders.length"
          :title="t('CONVERSATION.ORDER_PANEL.CONTACT_ORDERS')"
          :is-open="isContactOrdersOpen"
          compact
          class="mt-2"
          @toggle="isContactOrdersOpen = !isContactOrdersOpen"
        >
          <template #button>
            <span
              class="inline-flex items-center justify-center min-w-[20px] h-5 px-1.5 rounded-full bg-n-alpha-2 text-xs font-medium text-n-slate-11 mr-2"
            >
              {{ contactOrders.length }}
            </span>
          </template>

          <OrderList
            :orders="contactOrders"
            readonly
            @edit="handleEditOrder"
            @delete="handleDeleteOrder"
            @push="handlePushOrder"
            @sync="handleSyncOrder"
          />
        </AccordionItem>
      </div>

      <!-- Quick Actions (Bottom Fixed) -->
      <div v-if="!isEcommerceChannel" class="shrink-0 p-3 border-t border-n-weak bg-n-solid-1 z-10">
        <Button
          :label="t('CONVERSATION.ORDER_PANEL.NEW_ORDER')"
          icon="i-lucide-plus"
          sm
          class="w-full"
          @click="handleNewOrder"
        />
      </div>
    </div>
  </div>
</template>
