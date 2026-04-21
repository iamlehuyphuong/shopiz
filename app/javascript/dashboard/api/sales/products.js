import CacheEnabledApiClient from '../CacheEnabledApiClient';
import ShopifyAPI from '../integrations/shopify';
class ProductsAPI extends CacheEnabledApiClient {
  constructor() {
    super('products', { accountScoped: true });
  }

  // eslint-disable-next-line class-methods-use-this
  get cacheModelName() {
    return 'product';
  }

  getProducts() {
    const shopifyProducts = ShopifyAPI.getProducts();
    const dummyProducts = axios.get(`https://dummyjson.com/products`);
    return Promise.all([shopifyProducts, dummyProducts]).then(
      ([shopifyRes, dummyRes]) => {
        // Normalize Shopify products
        const shopifyItems = (shopifyRes?.data?.products || []).map(item => ({
          ...item,
          description: item?.body_html || item.title,
          tags: item.tags.split(', '),
          category: item.product_type,
          availabilityStatus: item.stock_status,
          thumbnail: item?.image?.src || '',
          source: 'shopify',
          // add more fields as needed
        }));

        // Normalize Dummy products
        const dummyItems = (dummyRes?.data?.products || []).map(item => ({
          ...item,
          source: 'dummy',
          // add more fields as needed
        }));
        const response = {
          data: { products: [...shopifyItems, ...dummyItems] },
        };
        console.log('Response: ', response);
        return response;
      }
    );
  }
}

export default new ProductsAPI();
