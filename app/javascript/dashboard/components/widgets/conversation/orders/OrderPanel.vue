<script setup>
import { ref, computed, watch, onMounted } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore, useMapGetter } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import { useToggle } from '@vueuse/core';
import AccordionItem from 'dashboard/components/Accordion/AccordionItem.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import OrderList from './OrderList.vue';
import OrderForm from './OrderForm.vue';
import ShopifyOrdersList from 'dashboard/components/widgets/conversation/ShopifyOrdersList.vue';
import { useFunctionGetter } from 'dashboard/composables/store';

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

const [showDeleteModal, toggleDeleteModal] = useToggle(false);
const [showPushModal, togglePushModal] = useToggle(false);
const selectedOrder = ref(null);

const isShopifyOrdersOpen = ref(false);

const shopifyIntegration = useFunctionGetter(
  'integrations/getIntegration',
  'shopify'
);

const isShopifyFeatureEnabled = computed(
  () => shopifyIntegration.value.enabled
);

const currentConversation = useMapGetter('getSelectedChat');
const isEcommerceChannel = computed(() => {
  const channelType = currentConversation.value?.meta?.channel;
  return (
    channelType === 'Channel::TiktokShop' || channelType === 'Channel::Shopee'
  );
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

watch(
  () => props.conversationId,
  () => {
    fetchOrders();
    fetchContactDetails();
  }
);

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

const handleUpdateOrderStatus = async (order, newStatus) => {
  if (order.status === newStatus) return;
  try {
    const orderData = { status: newStatus };
    if (order.external_source) {
      // Local update only for now if it's from external source
      await store.dispatch('conversationOrders/update', {
        conversationId: props.conversationId,
        orderId: order.id,
        orderData,
      });
    } else {
      await store.dispatch('conversationOrders/update', {
        conversationId: props.conversationId,
        orderId: order.id,
        orderData,
      });
      // Optionally sync to Sales API here if needed:
      // import SalesOrdersAPI from 'dashboard/api/sales/orders';
      // await SalesOrdersAPI.update(order.id, orderData);
    }
  } catch (error) {
    useAlert(t('CONVERSATION.ORDER_PANEL.UPDATE_FAILED') || 'Update failed');
  }
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

const handleDeleteOrder = order => {
  selectedOrder.value = order;
  toggleDeleteModal(true);
};

const executeDeleteOrder = async () => {
  try {
    await store.dispatch('conversationOrders/delete', {
      conversationId: props.conversationId,
      orderId: selectedOrder.value.id,
    });
    useAlert(t('CONVERSATION.ORDER_PANEL.DELETE_SUCCESS'));
  } catch {
    useAlert(t('CONVERSATION.ORDER_PANEL.DELETE_ERROR'));
  } finally {
    toggleDeleteModal(false);
    selectedOrder.value = null;
  }
};

const handlePushOrder = order => {
  selectedOrder.value = order;
  togglePushModal(true);
};

const executePushOrder = async () => {
  try {
    await store.dispatch('conversationOrders/pushOrder', {
      conversationId: props.conversationId,
      orderId: selectedOrder.value.id,
    });
    useAlert(t('CONVERSATION.ORDER_PANEL.PUSH_SUCCESS'));
  } catch (err) {
    useAlert(err.message || t('CONVERSATION.ORDER_PANEL.PUSH_ERROR'));
  } finally {
    togglePushModal(false);
    selectedOrder.value = null;
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
  <div class="flex flex-col w-full relative">
    <!-- Orders Accordion -->
    <div>
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

        <template v-else>
          <!-- Loading -->
          <div
            v-if="uiFlags.isFetching"
            class="flex items-center justify-center py-6"
          >
            <i class="i-lucide-loader-2 text-n-slate-10 animate-spin text-lg" />
          </div>

          <!-- Orders List -->
          <template v-else-if="orders.length">
            <OrderList
              :orders="orders"
              :allow-edit="!isEcommerceChannel"
              @edit="handleEditOrder"
              @delete="handleDeleteOrder"
              @push="handlePushOrder"
              @sync="handleSyncOrder"
              @update-status="handleUpdateOrderStatus"
            />
            <div
              v-if="!isEcommerceChannel"
              class="flex items-center justify-end px-1 pt-2 pb-3 pr-2"
            >
              <Button
                link
                xs
                icon="i-lucide-arrow-right"
                class="!gap-1"
                :label="t('CONVERSATION.ORDER_PANEL.NEW_ORDER')"
                @click="handleNewOrder"
              />
            </div>
          </template>

          <!-- Empty State -->
          <div v-else class="relative px-1 pt-1 pb-2">
            <div class="flex justify-between w-full mb-1">
              <p class="m-0 text-sm text-n-slate-10">
                {{ t('CONVERSATION.ORDER_PANEL.NO_ORDERS') }}
              </p>
            </div>
            <div
              v-if="!isEcommerceChannel"
              class="flex items-center justify-end mt-1 pb-3 pr-2"
            >
              <Button
                link
                xs
                icon="i-lucide-arrow-right"
                class="!gap-1"
                :label="t('CONVERSATION.ORDER_PANEL.NEW_ORDER')"
                @click="handleNewOrder"
              />
            </div>
          </div>
        </template>
      </AccordionItem>
    </div>

    <template v-if="!showForm">
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

      <!-- Shopify Orders -->
      <AccordionItem
        v-if="isShopifyFeatureEnabled"
        :title="t('CONVERSATION_SIDEBAR.ACCORDION.SHOPIFY_ORDERS')"
        :is-open="isShopifyOrdersOpen"
        compact
        class="mt-2"
        @toggle="isShopifyOrdersOpen = !isShopifyOrdersOpen"
      >
        <ShopifyOrdersList :contact-id="contact.id" />
      </AccordionItem>
    </template>

    <!-- Modals -->
    <woot-confirm-delete-modal
      v-if="showDeleteModal"
      v-model:show="showDeleteModal"
      :title="t('CONVERSATION.ORDER_PANEL.DELETE_CONFIRM_TITLE')"
      :message="
        t('CONVERSATION.ORDER_PANEL.DELETE_CONFIRM', { id: selectedOrder?.id })
      "
      :confirm-text="t('CONVERSATION.ORDER_PANEL.DELETE_CONFIRM_YES')"
      :reject-text="t('CONVERSATION.ORDER_PANEL.DELETE_CONFIRM_NO')"
      :confirm-value="selectedOrder?.id?.toString()"
      :confirm-place-holder-text="
        t('CONVERSATION.ORDER_PANEL.DELETE_CONFIRM_PLACEHOLDER', {
          id: selectedOrder?.id,
        })
      "
      @on-confirm="executeDeleteOrder"
      @on-close="toggleDeleteModal(false)"
    />

    <woot-confirm-modal
      v-if="showPushModal"
      v-model:show="showPushModal"
      :title="t('CONVERSATION.ORDER_PANEL.PUSH_CONFIRM_TITLE')"
      :description="t('CONVERSATION.ORDER_PANEL.PUSH_CONFIRM')"
      :confirm-label="t('CONVERSATION.ORDER_PANEL.PUSH')"
      :cancel-label="t('CONVERSATION.ORDER_PANEL.CANCEL')"
      @on-confirm="executePushOrder"
      @on-close="togglePushModal(false)"
    />
  </div>
</template>
