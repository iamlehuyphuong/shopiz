import { addClasses, removeClasses, toggleClass } from './DOMHelpers';
import { IFrameHelper } from './IFrameHelper';
import { isExpandedView } from './settingsHelper';
import {
  CHATWOOT_CLOSED,
  CHATWOOT_OPENED,
} from '../widget/constants/sdkEvents';
import { dispatchWindowEvent } from 'shared/helpers/CustomEventHelper';



export const body = document.getElementsByTagName('body')[0];
export const widgetHolder = document.createElement('div');

export const bubbleHolder = document.createElement('div');
export const chatBubble = document.createElement('button');
export const closeBubble = document.createElement('button');
export const notificationBubble = document.createElement('span');

export const setBubbleText = bubbleText => {
  if (isExpandedView(window.$shopiz.type)) {
    const textNode = document.getElementById('woot-widget--expanded__text');
    if (textNode) {
      textNode.innerText = bubbleText;
    }

    const launcherTextNode = document.getElementById(
      'woot-widget--launcher__text'
    );
    if (launcherTextNode) {
      launcherTextNode.innerText = bubbleText;
    }
  }
};

export const addImageToButton = ({ target, imageUrl }) => {
  if (!imageUrl) return;

  const container = document.createElement('div');
  container.className = 'bubble-icon-container';
  const img = document.createElement('img');
  img.className = 'bubble-icon';
  img.setAttribute('src', imageUrl);
  container.appendChild(img);
  target.appendChild(container);
};

export const createBubbleIcon = ({
  className,
  target,
  widgetColor,
  bubbleAvatarUrl,
}) => {
  let bubbleClassName = `${className} woot-elements--${window.$shopiz.position}`;
  if (bubbleAvatarUrl) {
    addImageToButton({
      target,
      imageUrl: bubbleAvatarUrl,
    });
    target.style.background = 'transparent';
  } else {
    const container = document.createElement('div');
    container.className = 'bubble-icon-container';
    container.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-message-circle-more-icon lucide-message-circle-more"><path d="M2.992 16.342a2 2 0 0 1 .094 1.167l-1.065 3.29a1 1 0 0 0 1.236 1.168l3.413-.998a2 2 0 0 1 1.099.092 10 10 0 1 0-4.777-4.719"/><path d="M8 12h.01"/><path d="M12 12h.01"/><path d="M16 12h.01"/></svg>';
    target.appendChild(container);
    target.style.setProperty('background', widgetColor, 'important');
    target.style.borderRadius = '50%';
    target.style.boxShadow = '0 8px 24px rgba(0, 0, 0, .16)';
  }

  if (isExpandedView(window.$shopiz.type) && window.$shopiz.launcherTitle) {
    const title = document.createElement('span');
    title.id = 'woot-widget--launcher__text';
    title.className = 'woot-widget--bubble__text';
    title.innerText = window.$shopiz.launcherTitle;
    title.style.background = widgetColor;
    target.insertBefore(title, target.firstChild);
  }

  target.className = bubbleClassName;
  // target.title = 'Open chat window';
  return target;
};

export const createCloseBubbleIcon = ({ className, target, widgetColor }) => {
  let bubbleClassName = `${className} woot-elements--${window.$shopiz.position}`;
  const container = document.createElement('div');
  container.className = 'bubble-icon-container';
  container.innerHTML = '<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-x-icon lucide-x"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>';
  target.appendChild(container);

  target.style.setProperty('background', widgetColor, 'important');
  target.style.borderRadius = '100px';
  target.style.boxShadow = '0 8px 24px rgba(0, 0, 0, .16)';

  target.className = bubbleClassName;
  return target;
};

export const createBubbleHolder = hideMessageBubble => {
  if (hideMessageBubble) {
    addClasses(bubbleHolder, 'woot-hidden');
  }
  addClasses(bubbleHolder, 'woot--bubble-holder');
  bubbleHolder.id = 'cw-bubble-holder';
  bubbleHolder.dataset.turboPermanent = true;
  body.appendChild(bubbleHolder);
};

const handleBubbleToggle = newIsOpen => {
  IFrameHelper.events.onBubbleToggle(newIsOpen);

  if (newIsOpen) {
    dispatchWindowEvent({ eventName: CHATWOOT_OPENED });
  } else {
    dispatchWindowEvent({ eventName: CHATWOOT_CLOSED });
    chatBubble.focus();
  }
};

export const onBubbleClick = (props = {}) => {
  const { toggleValue } = props;
  const { isOpen } = window.$shopiz;
  if (isOpen === toggleValue) return;

  const newIsOpen = toggleValue === undefined ? !isOpen : toggleValue;
  window.$shopiz.isOpen = newIsOpen;

  toggleClass(chatBubble, 'woot--hide');
  toggleClass(closeBubble, 'woot--hide');
  toggleClass(widgetHolder, 'woot--hide');

  handleBubbleToggle(newIsOpen);
};

export const onClickChatBubble = () => {
  bubbleHolder.addEventListener('click', onBubbleClick);
};

export const addUnreadClass = () => {
  const holderEl = document.querySelector('.woot-widget-holder');
  addClasses(holderEl, 'has-unread-view');
};

export const removeUnreadClass = () => {
  const holderEl = document.querySelector('.woot-widget-holder');
  removeClasses(holderEl, 'has-unread-view');
};
