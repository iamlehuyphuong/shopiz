require 'fileutils'

def process_file(filepath)
  content = File.read(filepath)
  
  # 1. Imports
  unless content.include?("import Input from 'dashboard/components-next/input/Input.vue';")
    content.sub!("import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';",
                "import ComboBox from 'dashboard/components-next/combobox/ComboBox.vue';\nimport Input from 'dashboard/components-next/input/Input.vue';\nimport MultiImageUpload from 'dashboard/components-next/file-upload/MultiImageUpload.vue';")
  end

  # 2. Update form ref (imageUrl -> images: [])
  content.sub!("imageUrl: '',", "images: [],")

  # 3. Update payload handling
  content.sub!("images: form.value.imageUrl ? [form.value.imageUrl] : [],", "images: form.value.images || [],")
  # For edit view, it might be different, let's just make sure both files get updated correctly.
  
  # 4. Replace name input and error message block
  name_pattern = /<woot-input\s+v-model="form\.name"[\s\S]*?<\/span>\s*<\/div>/
  name_replacement = <<~VUE
    <Input
                    v-model="form.name"
                    class="w-full"
                    custom-input-class="!bg-n-surface-1"
                    :label="$t('SALES.PRODUCT_FORM.FIELDS.NAME.LABEL')"
                    :placeholder="$t('SALES.PRODUCT_FORM.FIELDS.NAME.PLACEHOLDER')"
                    :message="v$.form.name.$error ? $t('SALES.PRODUCT_FORM.FIELDS.NAME.ERROR') : ''"
                    :message-type="v$.form.name.$error ? 'error' : 'info'"
                    @blur="v$.form.name.$touch"
                  />
                </div>
  VUE
  content.sub!(name_pattern, name_replacement.strip)

  # 5. Replace imageUrl input with MultiImageUpload
  image_pattern = /<div class="w-full">\s*<woot-input\s+v-model="form\.imageUrl"[\s\S]*?<\/div>/
  image_replacement = <<~VUE
    <div class="w-full">
                  <label class="block text-sm font-medium text-n-slate-12 mb-2">
                    Hình ảnh
                  </label>
                  <MultiImageUpload
                    v-model="form.images"
                    :max-images="4"
                  />
                </div>
  VUE
  content.sub!(image_pattern, image_replacement.strip)

  # 6. Replace all other woot-inputs
  # We just replace `<woot-input` with `<Input` and add `custom-input-class="!bg-n-surface-1"`
  content.gsub!(/<woot-input\b/, '<Input custom-input-class="!bg-n-surface-1"')

  # 7. Update textarea
  content.gsub!(
    /class="w-full p-3 rounded-lg border border-n-weak bg-n-alpha-1 placeholder:text-n-slate-9 focus:outline-none focus:ring-1 focus:ring-n-brand focus:border-n-brand text-sm transition-shadow min-h-\[120px\]"/,
    'class="w-full p-3 rounded-lg border-0 outline outline-1 outline-n-weak outline-offset-[-1px] bg-n-surface-1 placeholder:text-n-slate-10 focus:outline-n-orange-9 transition-all duration-200 text-sm min-h-[120px]"'
  )

  # 8. Update TagInput wrappers
  content.gsub!(
    /class="w-full p-2 rounded-lg border border-n-weak bg-n-alpha-1 focus-within:ring-1 focus-within:ring-n-brand focus-within:border-n-brand transition-shadow min-h-\[42px\] flex items-center"/,
    'class="w-full p-2 rounded-lg border-0 outline outline-1 outline-n-weak outline-offset-[-1px] bg-n-surface-1 focus-within:outline-n-orange-9 transition-all duration-200 min-h-[42px] flex items-center"'
  )

  File.write(filepath, content)
end

process_file('app/javascript/dashboard/routes/dashboard/sales/products/New.vue')
process_file('app/javascript/dashboard/routes/dashboard/sales/products/Edit.vue')
