<!-- components/SurveyCreator.vue -->
<script setup lang="ts">
import type { ICreatorOptions } from "survey-creator-core";
import { SurveyCreatorModel } from "survey-creator-core";
import { SurveyCreatorComponent } from "survey-creator-vue";
import { slk } from "survey-core";

const creatorOptions: ICreatorOptions = {
  autoSaveEnabled: true,
  collapseOnDrag: true
};

const defaultJson = {
  pages: [{
    name: "Name",
    elements: [{
      name: "FirstName",
      title: "Enter your first name:",
      type: "text"
    }, {
      name: "LastName",
      title: "Enter your last name:",
      type: "text"
    }]
  }]
};
slk("YjA3ZGFkZTMtNjU5NS00YTYxLTkzZmEtYWJiOThjMWVhNjk3JmRvbWFpbnM6c3VydmV5anM7MT0yMDM0LTEwLTE2LDI9MjAzNC0xMC0xNiw0PTIwMzQtMTAtMTY=");
const creator = new SurveyCreatorModel(creatorOptions);
creator.text = window.localStorage.getItem("survey-json") || JSON.stringify(defaultJson);
creator.saveSurveyFunc = (saveNo: number, callback: Function) => { 
  window.localStorage.setItem("survey-json", creator.text);
  callback(saveNo, true);
  // saveSurveyJson(
  //     "https://your-web-service.com/",
  //     creator.JSON,
  //     saveNo,
  //     callback
  // );
};

// function saveSurveyJson(url: string, json: object, saveNo: number, callback: Function) {
//   fetch(url, {
//     method: 'POST',
//     headers: {
//       'Content-Type': 'application/json;charset=UTF-8'
//     },
//     body: JSON.stringify(json)
//   })
//   .then(response => {
//     if (response.ok) {
//       callback(saveNo, true);
//     } else {
//       callback(saveNo, false);
//     }
//   })
//   .catch(error => {
//     callback(saveNo, false);
//   });
// }
</script>

<template>
  <SurveyCreatorComponent :model="creator" />
</template>
<style src="survey-core/survey-core.css"></style>
<style src="survey-creator-core/survey-creator-core.css"></style>