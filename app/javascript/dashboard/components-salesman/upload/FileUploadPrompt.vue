<!-- 
 /**
    * @domain Salesman - File Upload Component
    * @file FileUploadPrompt.vue
    * FileUploadPrompt.vue
    * This component provides a drag-and-drop file upload interface.
    * It allows users to either click to select files or drag and drop files into the designated area.
    * The component emits events for file selection and drag events.
    *
    * @component
    * @example
    * <FileUploadPrompt @file-selected="handleFileSelected" />
    *
    * @props {Boolean} isDragging - Indicates if a drag event is currently active.
    *
    * @emits {FileList} file-selected - Emitted when files are selected or dropped.
    * @emits {Event} drag-enter - Emitted when a drag event enters the component.
    * @emits {Event} drag-leave - Emitted when a drag event leaves the component.
    */
 */ 
-->
<template>
    <div class="p-4 max-w-full" @dragover.prevent="handleDragOver" @dragleave.prevent="handleDragLeave"
        @drop.prevent="handleDrop">
        <!-- Rest State (when not dragging) -->
        <div v-if="!isDragging"
            class="flex flex-col p-4 w-full bg-white rounded-md border border-solid border-light-neutral-stroke-bold cursor-pointer"
            @click="triggerFileInput">
            <div class="self-center w-8">
                <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32" fill="none">
                    <g opacity="0.5">
                        <rect opacity="0.2" width="32" height="32" rx="3" fill="#0A0A0A" />
                    </g>
                </svg>
            </div>
            <div class="flex flex-col items-center mt-3 w-full tracking-normal text-center">
                <h2 class="text-base font-medium leading-6 text-neutral-950">
                    <span class="text-primary-700 text-center">Upload a file</span> or
                    drag and drop
                </h2>
                <p class="mt-1 text-sm leading-none text-light-neutral-teriaryS">
                    PNG, JPG, GIF upto 5MB
                </p>
            </div>

            <!-- Hidden file input -->
            <input type="file" ref="fileInput" class="hidden" accept=".png,.jpg,.jpeg,.gif" multiple
                @change="handleFileChange" />
        </div>

        <!-- Default State (when dragging) -->
        <div v-else class="flex flex-col p-4 w-full rounded-md border border-solid bg-neutral-100 border-neutral-300">
            <div class="self-center w-8">
                <div class="flex shrink-0 w-full h-8 rounded bg-neutral-950"></div>
            </div>
            <div class="flex flex-col items-start mt-3 w-full tracking-normal text-center">
                <h2 class="text-base font-medium leading-6 text-neutral-950">
                    <span style="color: rgba(56, 107, 183, 1)">Upload a file</span> or
                    drag and drop
                </h2>
                <p class="mt-1 text-sm leading-none text-zinc-500">
                    PNG, JPG, GIF upto 5MB
                </p>
            </div>
        </div>
    </div>
</template>

<script lang="ts">
import { defineComponent, ref } from "vue";

export default defineComponent({
    name: "FileUploadPrompt",
    props: {
        isDragging: {
            type: Boolean,
            default: false,
        },
    },
    emits: ["file-selected", "drag-enter", "drag-leave"],
    setup(props, { emit }) {
        const fileInput = ref<HTMLInputElement | null>(null);

        // Trigger file input click
        const triggerFileInput = () => {
            if (fileInput.value) {
                fileInput.value.click();
            }
        };

        // Handle file selection from input
        const handleFileChange = (event: Event) => {
            const target = event.target as HTMLInputElement;
            emit("file-selected", target.files);

            // Reset input to allow selecting the same file again
            if (fileInput.value) {
                fileInput.value.value = "";
            }
        };

        // Handle drag over
        const handleDragOver = (event: DragEvent) => {
            emit("drag-enter");
        };

        // Handle drag leave
        const handleDragLeave = (event: DragEvent) => {
            // Only emit drag-leave if we're leaving the component (not entering a child)
            if (
                event.currentTarget === event.target ||
                !event.relatedTarget ||
                !(event.currentTarget as Node).contains(event.relatedTarget as Node)
            ) {
                emit("drag-leave");
            }
        };

        // Handle drop
        const handleDrop = (event: DragEvent) => {
            emit("drag-leave");
            emit("file-selected", event.dataTransfer?.files || null);
        };

        return {
            fileInput,
            triggerFileInput,
            handleFileChange,
            handleDragOver,
            handleDragLeave,
            handleDrop,
        };
    },
});
</script>