<template>
  <SurveyCreatorComponent :model="creator" />
</template>
<script lang="ts" setup>
import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';
import { SurveyCreatorModel } from "survey-creator-core";
import { SurveyCreatorComponent } from "survey-creator-vue";
import { Serializer, Action, ComputedUpdater, createDropdownActionModel, QuestionSelectBase } from "survey-core";
import { surveyJSON } from "./data";
import "survey-core/i18n/vietnamese";
import SurveyCreatorTheme from "survey-creator-core/themes";
import { LayeredDarkPanelless, LayeredLightPanelless } from "survey-core/themes";
import { registerCreatorTheme } from "survey-creator-core";
import { slk } from "survey-core";

const shopizThemeVariables = {
  "--sjs-code-gray-700": "#B6B6B6FF",
  "--sjs-code-blue-500": "#326FCAFF",
  "--sjs-code-gray-300": "#505050FF",
  "--sjs-code-green-500": "#08997CFF",
  "--sjs-code-red-500": "#F41B50FF",
  "--sjs-code-purple-500": "#C22FA2FF",
  "--sjs-code-yellow-500": "#F58D06FF",
  "--sjs-code-gray-500": "#8A8A8AFF"
}
const shopizThemeDark = {
    themeName: "Dark",
    isLight: false,
    cssVariables: { 
      ...SurveyCreatorTheme.DefaultDark.cssVariables,
      ...shopizThemeVariables
    }
};

const shopizThemeLight = {
    themeName: "Light",
    isLight: true,
    cssVariables: { 
      ...SurveyCreatorTheme.DefaultContrast.cssVariables,
      ...shopizThemeVariables
    }
};

registerCreatorTheme(
  shopizThemeDark,
  shopizThemeLight
);

const setColorTheme = isOSOnDarkMode => {
  const selectedColorScheme =
    LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME) || 'light';
  if (
    (selectedColorScheme === 'auto' && isOSOnDarkMode) ||
    selectedColorScheme === 'dark'
  ) {
    creator.applyCreatorTheme(shopizThemeDark)
    creator.applyTheme(LayeredDarkPanelless)
  } else {
    creator.applyCreatorTheme(shopizThemeLight)
    creator.applyTheme(LayeredLightPanelless)
  }
};

const mql = window.matchMedia('(prefers-color-scheme: dark)');
mql.onchange = e => setColorTheme(e.matches);

slk("YjA3ZGFkZTMtNjU5NS00YTYxLTkzZmEtYWJiOThjMWVhNjk3JmRvbWFpbnM6c3VydmV5anM7MT0yMDM0LTEwLTE2LDI9MjAzNC0xMC0xNiw0PTIwMzQtMTAtMTY=");
const creator = new SurveyCreatorModel();
creator.locale = "vn";
setColorTheme(window.matchMedia('(prefers-color-scheme: dark)').matches);

function queryAI(query: string, callback: (response: string | null, error: string | null) => void): void {
  const url = `/api/AI/query`;
  try {
    fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ text: query }),
    })
    .then(x => x.json())
    .then((data: { text: string, error: string }) => callback(data.text, data.error));
  } catch (error: any) {
    callback(null, error.message);
  }
}

interface AIOption {
  id: string;
  title: string;
  query: string;
}

function createAIAction(selectBaseQuestion: QuestionSelectBase): Action {
  const AIOptions: AIOption[] = [
    { id: "title-to-choices", title: "Generate choices by title", query: "Generate unique choices by title and replace 'choices' field in this object: " },
    { id: "add-more-choices", title: "Generate more choices", query: "Generate more unique choices by title and add them to the 'choices' field in this object: " },
    { id: "randomize", title: "Randomize choice order", query: "Randomize choice order and replace them in 'choices' field: " },
    { id: "grammar", title: "Fix grammar errors", query: "Fix grammar errors in the 'choices' and 'title' fields: " }
  ];
  const action = createDropdownActionModel({
    id: "AI",   
    title: "AI",
    iconName: "icon-wand-24x24",
    visibleIndex: 8
  }, {
    items: AIOptions,
    onSelectionChanged: (item: AIOption) => {
      action.title = "AI";
      let query = item.query;
      query += JSON.stringify({
        title: selectBaseQuestion.title,
        choices: selectBaseQuestion.choices.map((c: any) => c.title)
      }) + "\n";
      query += "Use JSON format as output.";

      queryAI(query, (response, error) => {
        if (error) {
          creator.notify(error, "error")
        } else if (response) {
          const data = JSON.parse(response);
          selectBaseQuestion.title = data.title;
          selectBaseQuestion.choices = [];
          selectBaseQuestion.choices = data.choices;
        }
      });
    },
    verticalPosition: "top",
    horizontalPosition: "center"
  });
  return action;
}

creator.onElementGetActions.add((_: any, options: any) => {
  const question = options.element;

  // Create the "AI" adorner for all choice-based questions
  if (question instanceof QuestionSelectBase) {
    const AIAdorner = createAIAction(question);
    options.actions.push(AIAdorner);
  }
});

creator.JSON = surveyJSON;
</script>
<style src="survey-core/survey-core.css"></style>
<style src="survey-creator-core/survey-creator-core.css"></style>