<script setup>
import Badge from './Badge.vue';

// Constants for documentation
const VARIANTS = ['solid', 'outline', 'faded', 'link', 'ghost'];
const COLORS = ['blue', 'ruby', 'amber', 'slate', 'teal'];
const SIZES = ['default', 'sm', 'lg'];
</script>

<template>
  <Story title="Components/Badge" :layout="{ type: 'grid', width: '800px' }">
    <!-- Basic Variants -->
    <Variant title="Basic Variants">
      <div class="flex flex-wrap gap-2 p-4 bg-white dark:bg-slate-900">
        <Badge
          v-for="variant in VARIANTS"
          :key="variant"
          :label="variant"
          :variant="variant"
        />
      </div>
    </Variant>

    <!-- Colors -->
    <Variant title="Color Variants">
      <div class="flex flex-wrap gap-2 p-4 bg-white dark:bg-slate-900">
        <Badge
          v-for="color in COLORS"
          :key="color"
          :label="color"
          :color="color"
        />
      </div>
    </Variant>

    <!-- Sizes -->
    <Variant title="Size Variants">
      <div
        class="flex flex-wrap items-center gap-2 p-4 bg-white dark:bg-slate-900"
      >
        <Badge v-for="size in SIZES" :key="size" :label="size" :size="size" />
      </div>
    </Variant>

    <!-- Icons -->
    <Variant title="Icons">
      <div class="flex flex-wrap gap-2 p-4 bg-white dark:bg-slate-900">
        <Badge label="Leading Icon" icon="i-lucide-plus" />
        <Badge label="Trailing Icon" icon="i-lucide-plus" trailing-icon />
        <Badge icon="i-lucide-plus" />
      </div>
    </Variant>

    <!-- Loading State -->
    <Variant title="Loading State">
      <div class="flex flex-wrap gap-2 p-4 bg-white dark:bg-slate-900">
        <Badge label="Loading" is-loading />
        <Badge label="Loading" variant="outline" is-loading />
        <Badge is-loading icon="i-lucide-plus" />
      </div>
    </Variant>

    <!-- Disabled State -->
    <Variant title="Disabled State">
      <div class="flex flex-wrap gap-2 p-4 bg-white dark:bg-slate-900">
        <Badge label="Disabled" disabled />
        <Badge label="Disabled Outline" variant="outline" disabled />
        <Badge label="Disabled Icon" icon="delete" disabled />
        <Badge
          label="Disabled Destructive"
          color="ruby"
          disabled
          icon="delete"
          size="sm"
        />
      </div>
    </Variant>

    <!-- Color Combinations -->
    <Variant title="Color & Variant Combinations">
      <div class="flex flex-wrap gap-2 p-4 bg-white dark:bg-slate-900">
        <template v-for="color in COLORS" :key="color">
          <Badge
            v-for="variant in VARIANTS"
            :key="`${color}-${variant}`"
            :label="`${color} ${variant}`"
            :color="color"
            :variant="variant"
          />
        </template>
      </div>
    </Variant>

    <!-- Icon Positions -->
    <Variant title="Icon Positions & Sizes">
      <div class="flex flex-wrap gap-2 p-4 bg-white dark:bg-slate-900">
        <template v-for="size in SIZES" :key="size">
          <Badge
            :label="`${size} Leading`"
            icon="i-lucide-plus"
            :size="size"
          />
          <Badge
            :label="`${size} Trailing`"
            icon="i-lucide-plus"
            trailing-icon
            :size="size"
          />
          <Badge icon="i-lucide-plus" :size="size" />
        </template>
      </div>
    </Variant>

    <!-- Ghost & Link Variants -->
    <Variant title="Ghost & Link Variants">
      <div class="flex flex-wrap gap-2 p-4 bg-white dark:bg-slate-900">
        <Badge label="Ghost Button" variant="ghost" color="slate" />
        <Badge
          label="Ghost with Icon"
          variant="ghost"
          color="slate"
          icon="i-lucide-plus"
        />
        <Badge label="Link Button" variant="link" />
        <Badge label="Link with Icon" variant="link" icon="i-lucide-plus" />
      </div>
    </Variant>
  </Story>
</template>
