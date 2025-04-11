<!-- 
 /**
    * @domain Salesman - File Upload Component
    * @file FileUploadItem.vue
    * This component represents a file upload item in the UI.
    * It displays the file name, size, and upload progress.
    * It also provides an action button to remove or retry the upload.
    * 
    * @component
    * @prop {string} state - The current state of the file upload (uploading, uploaded, error).
    * @prop {string} fileName - The name of the file being uploaded.
    * @prop {string} fileSize - The size of the file being uploaded.
    * @prop {number} progress - The current upload progress percentage.
    * @emit remove - Emitted when the remove action is triggered.
    * @emit retry - Emitted when the retry action is triggered.
 */ 
-->
<!-- 1. Template -->
<template>
    <div class="flex flex-col justify-center py-4 w-full rounded-md">
        <div class="w-full">
            <div class="flex gap-6 justify-center items-center w-full">
                <div class="flex flex-1 shrink gap-3 items-center self-stretch my-auto basis-3 min-w-60">
                    <!-- File Icon -->
                    <div
                        class="flex gap-2 justify-center items-center self-stretch px-1.5 my-auto w-8 h-8 rounded-2xl bg-light-neutral-s min-h-8">
                        <div class="self-stretch my-auto w-4">
                            <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 16 16"
                                fill="none">
                                <g opacity="0.5">
                                    <rect opacity="0.2" width="16" height="16" rx="2.4" fill="#386BB7" />
                                </g>
                            </svg>
                        </div>
                    </div>

                    <!-- File Details -->
                    <div class="flex-1 shrink self-stretch my-auto basis-3 min-w-60">
                        <h3 class="text-base text-neutral-950" :class="{ 'font-medium': state !== 'uploading' }">
                            {{ fileName }}
                        </h3>

                        <!-- Progress Bar (Only for uploading state) -->
                        <ProgressBar v-if="state === 'uploading'" :progress="progress" />

                        <!-- Status Text -->
                        <p class="gap-2 mt-2 w-full text-sm leading-none" :class="{
                            'text-zinc-500': state !== 'error',
                            'text-red-500': state === 'error',
                        }">
                            <template v-if="state === 'uploading'">
                                {{ fileSize }} • {{ progress }}% uploaded
                            </template>
                            <template v-else-if="state === 'uploaded'">
                                {{ fileSize }} • 100% uploaded
                            </template>
                            <template v-else-if="state === 'error'">
                                Oops! Upload failed
                            </template>
                        </p>
                    </div>
                </div>

                <!-- Action Icon -->
                <button
                    class="flex gap-2.5 justify-center items-center self-stretch px-1.5 my-auto w-8 h-8 rounded-3xl min-h-8"
                    :class="{
                        'bg-neutral-100': state !== 'uploaded',
                        'bg-red-50': state === 'uploaded',
                    }" @click="handleAction" aria-label="File action">
                    <img src="assets/images/other/trash-red-icon.svg" v-if="$props.state === 'uploaded'"
                        class="object-contain self-stretch my-auto w-5 aspect-square" alt="Action icon" />

                    <img src="assets/images/other/repeat-icon.svg" v-if="$props.state === 'error'"
                        class="object-contain self-stretch my-auto w-5 aspect-square" alt="Action icon" />

                    <img src="assets/images/other/cancel-icon.svg" v-if="$props.state === 'uploading'"
                        class="object-contain self-stretch my-auto w-5 aspect-square" alt="Action icon" />

                </button>
            </div>
        </div>
    </div>
</template>

<!-- 2. Script -->
<script lang="ts">
import { defineComponent, computed } from "vue";
import ProgressBar from "./ProgressBar.vue";

export default defineComponent({
    name: "FileUploadItem",
    components: {
        ProgressBar,
    },
    props: {
        state: {
            type: String,
            required: true,
            validator: (value: string) =>
                ["uploading", "uploaded", "error"].includes(value),
        },
        fileName: {
            type: String,
            required: true,
        },
        fileSize: {
            type: String,
            default: "",
        },
        progress: {
            type: Number,
            default: 0,
        },
    },
    emits: ["remove", "retry"],
    setup(props, { emit }) {


        const handleAction = () => {
            switch (props.state) {
                case "uploading":
                case "uploaded":
                    emit("remove");
                    break;
                case "error":
                    emit("retry");
                    break;
            }
        };

        return {
            handleAction,
        };
    },
});
</script>