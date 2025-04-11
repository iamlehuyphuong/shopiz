<template>

    <div>
        <section class="flex flex-col gap-4">
            <div class="flex flex-col gap-2">
                <h1 class="text-2xl font-bold">Salesman Component</h1>
                <p class="text-gray-600">This is a demo page for the Salesman component.</p>
            </div>

            <div class="">
                <h3>Button Component</h3>
                <p class="text-gray-600">This is a demo for the button component.</p>
                <ul>
                    <li><Button color="primary">Primary button</Button></li>
                </ul>
            </div>

        </section>
    </div>

</template>

<script lang="ts" setup>
import Button from './button/Button.vue';
</script>
