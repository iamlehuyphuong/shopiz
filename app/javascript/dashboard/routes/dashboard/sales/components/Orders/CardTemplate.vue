<template let-data>
  <div class="card-template">
    <div class="e-card-header">
      <div class="e-card-header-caption">
        <div class="e-card-header-title e-tooltip-text">{{data.Title}}</div>
      </div>
    </div>
    <div class="e-card-content e-tooltip-text">
      <div class="e-text">{{data.Summary}}</div>
    </div>
    <div class="e-card-custom-footer" v-html="getCardFooter(data)"></div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      data: {}
    };
  },
  methods: {
    getString: function(name) {
      return name.match(/\b(\w)/g).join("").toUpperCase();
    },
    getCardFooter: function(data) {
      let productDiv = "";
      let products = data.products;
      for (let product of products) {
        productDiv += "<div class='e-card-tag-field e-tooltip-text'>" + product.title + "</div>";
      }
      productDiv += "<div class='e-card-avatar'>" + this.getString(data.source) + "</div>";
      return productDiv;
    }
  }
};
</script>