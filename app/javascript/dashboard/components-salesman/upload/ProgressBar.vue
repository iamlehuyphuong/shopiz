<!-- 
    /**
     * @domain Salesman - File Upload Component
     * @file ProgressBar.vue
     * 
     * This component is a progress bar that visually represents the progress of a task.
     * It is designed to be used in a Vue.js application and is styled using Tailwind CSS.
     * 
     * Props:
     * - progress: A number between 0 and 100 representing the current progress percentage.
     * 
     * Usage:
     * <ProgressBar :progress="50" />
     * 
     * Note: The progress prop must be a number between 0 and 100.
     */        
-->

<template>
    <div class="flex items-start mt-2 w-full">
        <div class="overflow-hidden flex-1 shrink w-full basis-0 min-w-60">
            <div class="text-base font-medium tracking-normal text-neutral-950 hidden">
                Label
            </div>
            <div class="flex overflow-hidden mt-1.5 w-full min-h-8 rounded-[100px]">
                <!-- Progress blocks -->
                <template v-for="index in 10" :key="index">
                    <div v-if="index < Math.floor(progress / 10)" class="flex-1 shrink basis-0">
                        <div class="flex shrink-0 h-8 bg-primary-700"></div>
                    </div>

                    <svg v-else-if="
                        index === Math.ceil(progress / 10)" xmlns=" http://www.w3.org/2000/svg" width="29" height="32"
                        viewBox="0 0 29 32" fill="none">
                        <path
                            d="M0.199219 0H12.9992C21.8358 0 28.9992 7.16345 28.9992 16V16C28.9992 24.8366 21.8358 32 12.9992 32H0.199219V0Z"
                            fill="#386BB7" />
                    </svg>

                    <div v-else-if="index === Math.floor(progress / 10)" class="flex-1 shrink basis-0">
                        <div class="flex shrink-0 h-8 bg-primary-700"></div>
                    </div>

                    <div v-else class="flex flex-1 shrink h-8 basis-0 w-[29px]"></div>

                </template>
            </div>
            <div class="mt-1.5 text-sm tracking-normal leading-none text-zinc-500 hidden">
                Caption
            </div>
        </div>
    </div>
</template>

<script lang="ts">
import { defineComponent } from "vue";

export default defineComponent({
    name: "ProgressBar",
    props: {
        progress: {
            type: Number,
            required: true,
            validator: (value: number) => value >= 0 && value <= 100,
        },
    },
});
</script>