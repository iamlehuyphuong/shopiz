import { addClasses, removeClasses, toggleClass } from './DOMHelpers';
import { IFrameHelper } from './IFrameHelper';
import { isExpandedView } from './settingsHelper';
import {
  CHATWOOT_CLOSED,
  CHATWOOT_OPENED,
} from '../widget/constants/sdkEvents';
import { dispatchWindowEvent } from 'shared/helpers/CustomEventHelper';

export const bubbleSVG =
  'M240.808 240.808H122.123C56.6994 240.808 3.45695 187.562 3.45695 122.122C3.45695 56.7031 56.6994 3.45697 122.124 3.45697C187.566 3.45697 240.808 56.7031 240.808 122.122V240.808Z';

export const body = document.getElementsByTagName('body')[0];
export const widgetHolder = document.createElement('div');

export const bubbleHolder = document.createElement('div');
export const chatBubble = document.createElement('button');
export const closeBubble = document.createElement('button');
export const notificationBubble = document.createElement('span');

export const setBubbleText = bubbleText => {
  if (isExpandedView(window.$flowify.type)) {
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
  let bubbleClassName = `${className} woot-elements--${window.$flowify.position}`;
  if (bubbleAvatarUrl) {
    addImageToButton({
      target,
      imageUrl: bubbleAvatarUrl,
    });
    target.style.background = 'transparent';
  } else {
    const container = document.createElement('div');
    container.className = 'bubble-icon-container';
    const svg = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
    svg.setAttribute('viewBox', '0 0 240.808 240.808');
    svg.setAttribute('width', '32');
    svg.setAttribute('height', '32');
    const path = document.createElementNS('http://www.w3.org/2000/svg', 'path');
    path.setAttribute('d', bubbleSVG);
    path.setAttribute('fill', '#ffffff');
    svg.appendChild(path);
    container.appendChild(svg);
    target.appendChild(container);
    target.style.setProperty('background', widgetColor, 'important');
    target.style.borderRadius = '50%';
    target.style.boxShadow = '0 8px 24px rgba(0, 0, 0, .16)';
  }

  if (isExpandedView(window.$flowify.type) && window.$flowify.launcherTitle) {
    const title = document.createElement('span');
    title.id = 'woot-widget--launcher__text';
    title.className = 'woot-widget--bubble__text';
    title.innerText = window.$flowify.launcherTitle;
    title.style.background = widgetColor;
    target.insertBefore(title, target.firstChild);
  }

  target.className = bubbleClassName;
  // target.title = 'Open chat window';
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
  const { isOpen } = window.$flowify;
  if (isOpen === toggleValue) return;

  const newIsOpen = toggleValue === undefined ? !isOpen : toggleValue;
  window.$flowify.isOpen = newIsOpen;

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
