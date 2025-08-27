import axios from 'axios';

const { apiHost = '' } = window.shopizConfig || {};
const wootAPI = axios.create({ baseURL: `${apiHost}/` });

export default wootAPI;
