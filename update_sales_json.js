const fs = require('fs');
const path = require('path');

const updateLocale = (localePath, isVi) => {
  const data = JSON.parse(fs.readFileSync(localePath, 'utf8'));
  
  if (isVi) {
    data.SALES.PRODUCT_FORM.FIELDS.BRAND.LABEL = "Thương hiệu";
    data.SALES.PRODUCT_FORM.FIELDS.STYLE.LABEL = "Phong cách";
    data.SALES.PRODUCT_FORM.FIELDS.ATTRIBUTES.LABEL = "Thuộc tính tuỳ chọn";
    data.SALES.PRODUCT_FORM.FIELDS.ATTRIBUTES.PLACEHOLDER = "Thêm các thuộc tính khác cho sản phẩm";
    
    // Add new labels for the custom attributes
    data.SALES.PRODUCT_FORM.FIELDS.CUSTOM_ATTR = {
      ADD_BUTTON: "Thêm thuộc tính",
      NAME: "Tên thuộc tính",
      KEYWORDS: "Từ khoá",
      TYPE: "Kiểu nội dung",
      DETAILS: "Nội dung chi tiết",
      REMOVE: "Xoá",
      TYPES: {
        TEXT: "Văn bản",
        NUMBER: "Số",
        DATE: "Ngày tháng"
      }
    };
  } else {
    data.SALES.PRODUCT_FORM.FIELDS.BRAND.LABEL = "Brand";
    data.SALES.PRODUCT_FORM.FIELDS.STYLE.LABEL = "Style";
    data.SALES.PRODUCT_FORM.FIELDS.ATTRIBUTES.LABEL = "Optional Attributes";
    data.SALES.PRODUCT_FORM.FIELDS.ATTRIBUTES.PLACEHOLDER = "Add other attributes for the product";
    
    data.SALES.PRODUCT_FORM.FIELDS.CUSTOM_ATTR = {
      ADD_BUTTON: "Add Attribute",
      NAME: "Attribute Name",
      KEYWORDS: "Keywords",
      TYPE: "Content Type",
      DETAILS: "Detailed Content",
      REMOVE: "Remove",
      TYPES: {
        TEXT: "Text",
        NUMBER: "Number",
        DATE: "Date"
      }
    };
  }

  fs.writeFileSync(localePath, JSON.stringify(data, null, 2) + '\n');
};

updateLocale('/Users/macos/Work/WebApps/shopiz/app/javascript/dashboard/i18n/locale/vi/sales.json', true);
updateLocale('/Users/macos/Work/WebApps/shopiz/app/javascript/dashboard/i18n/locale/en/sales.json', false);
console.log("Updated sales.json");
