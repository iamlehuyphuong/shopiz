import { LocalStorage } from 'shared/helpers/localStorage';
import { LOCAL_STORAGE_KEYS } from 'dashboard/constants/localStorage';

export const setColorTheme = isOSOnDarkMode => {
  const kanbanCss = document.getElementById('kanban-css');
  const selectedColorScheme =
    LocalStorage.get(LOCAL_STORAGE_KEYS.COLOR_SCHEME) || 'light';
  if (
    (selectedColorScheme === 'auto' && isOSOnDarkMode) ||
    selectedColorScheme === 'dark'
  ) {
    document.body.classList.add('dark');
    document.documentElement.style.setProperty('color-scheme', 'dark');
    if(kanbanCss) {
      kanbanCss.href = "https://cdn.syncfusion.com/ej2/30.1.37/tailwind3-dark.css"
    }
  } else {
    document.body.classList.remove('dark');
    document.documentElement.style.setProperty('color-scheme', 'light');
    if(kanbanCss) {
      kanbanCss.href = "https://cdn.syncfusion.com/ej2/30.1.37/tailwind3.css"
    }
  }
};
