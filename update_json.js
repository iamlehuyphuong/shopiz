const fs = require('fs');

const updateLocale = (path, lang) => {
  const content = fs.readFileSync(path, 'utf8');
  const data = JSON.parse(content);
  
  // Product Form Updates
  data.SALES.PRODUCT_FORM.STEP_3.DESCRIPTION = lang === 'vi' ? 'Mô tả' : 'Description';
  data.SALES.PRODUCT_FORM.STEP_3.ATTRIBUTES = lang === 'vi' ? 'Thuộc tính' : 'Attributes';
  
  data.SALES.PRODUCT_FORM.FIELDS.HAS_VARIANTS = {
    TITLE: lang === 'vi' ? 'Sản phẩm có nhiều biến thể' : 'Product has multiple variants',
    DESC: lang === 'vi' ? 'Bật nếu sản phẩm có nhiều tuỳ chọn như kích thước, màu sắc' : 'Enable if the product has options like size, color'
  };

  // Order Form Updates
  if (lang === 'vi') {
    data.SALES.ORDER_FORM.WIZARD.STEP_1.TITLE = 'Thanh toán';
    data.SALES.ORDER_FORM.WIZARD.STEP_1.BODY = 'Thiết lập thuế, phí giao hàng và giảm giá.';
  } else {
    data.SALES.ORDER_FORM.WIZARD.STEP_1.TITLE = 'Payment';
    data.SALES.ORDER_FORM.WIZARD.STEP_1.BODY = 'Set taxes, shipping fees, and discounts.';
  }

  data.SALES.ORDER_FORM.LABELS = {
    PRODUCTS: lang === 'vi' ? 'Sản phẩm' : 'Products',
    PRODUCT_LIST: lang === 'vi' ? 'Danh sách sản phẩm' : 'Product List',
    SUBTOTAL: lang === 'vi' ? 'Tạm tính' : 'Subtotal',
    SUBTOTAL_EST: lang === 'vi' ? 'Tổng tạm tính' : 'Estimated Subtotal',
    TOTAL_EST: lang === 'vi' ? 'Tổng tiền (Tạm tính)' : 'Estimated Total',
    PAYMENT_INFO: lang === 'vi' ? 'Thông tin thanh toán' : 'Payment Information',
    PAYMENT_METHOD: lang === 'vi' ? 'Phương thức thanh toán' : 'Payment Method',
    PAYMENT_STATUS: {
      LABEL: lang === 'vi' ? 'Trạng thái thanh toán' : 'Payment Status',
      UNPAID: lang === 'vi' ? 'Chưa thanh toán' : 'Unpaid',
      PAID: lang === 'vi' ? 'Đã thanh toán' : 'Paid',
      PARTIALLY_REFUNDED: lang === 'vi' ? 'Hoàn tiền một phần' : 'Partially Refunded',
      REFUNDED: lang === 'vi' ? 'Hoàn tiền' : 'Refunded'
    },
    PAYMENT_METHODS: {
      COD: 'COD',
      BANK_TRANSFER: lang === 'vi' ? 'Chuyển khoản' : 'Bank Transfer',
      CARD: lang === 'vi' ? 'Thẻ / Ví điện tử' : 'Card / Wallet'
    },
    TAX: lang === 'vi' ? 'Thuế' : 'Tax',
    TAX_PERCENTAGE: lang === 'vi' ? 'Thuế (%)' : 'Tax (%)',
    DISCOUNT: lang === 'vi' ? 'Giảm giá' : 'Discount',
    SHIPPING_FEE: lang === 'vi' ? 'Phí giao hàng' : 'Shipping Fee',
    TOTAL: lang === 'vi' ? 'Tổng cộng' : 'Total',
    TOTAL_PAYMENT: lang === 'vi' ? 'Tổng thanh toán' : 'Total Payment',
    CUSTOMER: lang === 'vi' ? 'Khách hàng' : 'Customer',
    CUSTOMER_INFO: lang === 'vi' ? 'Thông tin khách hàng' : 'Customer Information',
    NO_CUSTOMER_INFO: lang === 'vi' ? 'Chưa có thông tin khách hàng' : 'No customer information',
    CUSTOMER_NAME: lang === 'vi' ? 'Tên khách hàng' : 'Customer Name',
    INPUT_CUSTOMER_NAME: lang === 'vi' ? 'Nhập tên khách hàng' : 'Enter customer name',
    CREATE_ORDER: lang === 'vi' ? 'Tạo đơn hàng' : 'Create Order',
    STATUS: lang === 'vi' ? 'Trạng thái' : 'Status',
    COMPLETE: lang === 'vi' ? 'Hoàn thành' : 'Complete'
  };

  fs.writeFileSync(path, JSON.stringify(data, null, 2) + '\n', 'utf8');
  console.log(`Updated ${path}`);
};

updateLocale('app/javascript/dashboard/i18n/locale/en/sales.json', 'en');
updateLocale('app/javascript/dashboard/i18n/locale/vi/sales.json', 'vi');
