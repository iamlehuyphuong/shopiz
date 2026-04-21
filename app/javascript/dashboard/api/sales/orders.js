import CacheEnabledApiClient from '../CacheEnabledApiClient';
import ShopifyAPI from '../integrations/shopify';
class OrdersAPI extends CacheEnabledApiClient {
  constructor() {
    super('orders', { accountScoped: true });
  }

  // eslint-disable-next-line class-methods-use-this
  get cacheModelName() {
    return 'order';
  }

  getOrders() {
    const shopifyOrders = ShopifyAPI.getOrders();
    const dummyOrders = axios.get(`https://dummyjson.com/carts`);
    return Promise.all([shopifyOrders, dummyOrders]).then(
      ([shopifyRes, dummyRes]) => {
        // Normalize Shopify orders
        const shopifyItems = (shopifyRes?.data?.orders || []).map(item => ({
          id: item.id,
          title: item.title,
          description: item?.body_html || item.title,
          tags: item.tags.split(', '),
          stock: item.stock,
          category: item.order_type,
          availabilityStatus: item.stock_status,
          thumbnail: item?.image?.src || '',
          source: 'shopify',
          // add more fields as needed
        }));

        // Normalize Dummy orders
        const dummyItems = (dummyRes?.data?.orders || []).map(item => ({
          ...item,
          source: 'dummy',
          // add more fields as needed
        }));
        const response = { data: { orders: [...shopifyItems, ...dummyItems] } };
        console.log('Response: ', response);
        return response;
      }
    );
  }
}

export default new OrdersAPI();
