<!-- 
 /**
    * @domain Salesman - File Upload Component
    * @file FileUpload.vue
    * @description This component handles file uploads, including drag-and-drop functionality,
    *              file validation, and progress tracking.
    * 
    * This component is part of a larger application and is designed to work with Vue.js.
    * It includes methods for handling file selection, validating files, and managing upload progress.
    * 
    * Note: Ensure to replace the placeholder values with actual implementation details.
 */ 

-->
<template>
    <section class="overflow-hidden bg-white rounded-lg max-w-[911px]">


        <div class="flex flex-col items-start px-28 py-16 w-full max-md:px-5 max-md:max-w-full
        ">
            <div class="rounded-md border border-purple-500 border-dashed w-[420px]">
                <FileUploadPrompt @file-selected="handleFileSelected" :is-dragging="isDragging"
                    @drag-enter="isDragging = true" @drag-leave="isDragging = false" />

                <div v-if="uploadItems.length > 0" class="p-4 mt-4 max-w-full ">
                    <FileUploadItem v-for="(item, index) in uploadItems" :key="item.id" :state="item.state"
                        :fileName="item.fileName" :fileSize="item.fileSize" :progress="item.progress"
                        :class="{ 'mt-6': index > 0 }" @remove="removeUploadItem(item.id)"
                        @retry="retryUpload(item.id)" />
                </div>
            </div>
        </div>
    </section>
</template>

<script lang="ts">

import { defineComponent, ref } from "vue";
import FileUploadPrompt from "./FileUploadPrompt.vue";
import FileUploadItem from "./FileUploadItem.vue";
import { uploadFileDemo, formatFileSize, validateFile } from "./fileUploadService";
import { UploadItem } from "../../../shared/model/upload-file.model";

export default defineComponent({
    name: "FileUpload",
    components: {
        FileUploadPrompt,
        FileUploadItem,
    },
    setup() {
        const uploadItems = ref<UploadItem[]>([]);
        const isDragging = ref(false);

        // Handle file selection
        const handleFileSelected = (files: FileList | null) => {
            if (!files || files.length === 0) return;

            // Process each file
            Array.from(files).forEach((file) => {
                // Validate file
                const validation = validateFile(file, ["png", "jpg", "jpeg", "gif"], 5);

                if (!validation.valid) {
                    // Add file with error state
                    const errorItem: UploadItem = {
                        id: Math.random().toString(36).substring(2, 15),
                        file,
                        fileName: file.name,
                        fileSize: formatFileSize(file.size),
                        progress: 0,
                        state: "error",
                        errorMessage: validation.message,
                    };
                    uploadItems.value.push(errorItem);
                    return;
                }

                // Create upload item
                const uploadItem: UploadItem = {
                    id: Math.random().toString(36).substring(2, 15),
                    file,
                    fileName: file.name,
                    fileSize: formatFileSize(file.size),
                    progress: 0,
                    state: "uploading",
                };

                // Add to list
                uploadItems.value.push(uploadItem);

                // Start upload
                startUpload(uploadItem);
            });
        };

        // Start file upload
        const startUpload = (item: UploadItem) => {
            // Start upload with progress tracking
            const controller = uploadFileDemo(
                item.file,
                (progress) => {
                    // Update progress
                    const index = uploadItems.value.findIndex((i) => i.id === item.id);
                    if (index !== -1) {
                        uploadItems.value[index].progress = progress;
                    }
                },
                (response) => {
                    // Upload successful
                    const index = uploadItems.value.findIndex((i) => i.id === item.id);
                    if (index !== -1) {
                        uploadItems.value[index].state = "uploaded";
                        uploadItems.value[index].progress = 100;
                    }
                },
                (error) => {
                    // Upload failed
                    const index = uploadItems.value.findIndex((i) => i.id === item.id);
                    if (index !== -1) {
                        uploadItems.value[index].state = "error";
                        uploadItems.value[index].errorMessage = error.message;
                    }
                },
            );

            // Store controller for cancellation
            item.uploadController = controller;
        };

        // Remove upload item
        const removeUploadItem = (id: string) => {
            const index = uploadItems.value.findIndex((item) => item.id === id);
            if (index !== -1) {
                // Cancel upload if in progress
                if (
                    uploadItems.value[index].state === "uploading" &&
                    uploadItems.value[index].uploadController
                ) {
                    uploadItems.value[index].uploadController.cancel();
                }

                // Remove item
                uploadItems.value.splice(index, 1);
            }
        };

        // Retry upload
        const retryUpload = (id: string) => {
            const index = uploadItems.value.findIndex((item) => item.id === id);
            if (index !== -1) {
                // Reset state
                uploadItems.value[index].state = "uploading";
                uploadItems.value[index].progress = 0;
                uploadItems.value[index].errorMessage = undefined;

                // Start upload again
                startUpload(uploadItems.value[index]);
            }
        };

        return {
            uploadItems,
            isDragging,
            handleFileSelected,
            removeUploadItem,
            retryUpload,
        };
    },
});
</script>