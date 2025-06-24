import CacheEnabledApiClient from './CacheEnabledApiClient';

class ProductsAPI extends CacheEnabledApiClient {
  constructor() {
    super('products', { accountScoped: true });
  }

  // eslint-disable-next-line class-methods-use-this
  get cacheModelName() {
    return 'product';
  }

  getProducts() {
    return axios.get(`https://dummyjson.com/products`);
  }
}

export default new ProductsAPI();
