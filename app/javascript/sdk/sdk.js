export const SDK_CSS = `
:root {
  --b-100: #F2F3F7;
  --s-700: #37546D;
}

.woot-widget-holder {
  box-shadow: 0 5px 40px rgba(0, 0, 0, .16);
  opacity: 1;
  will-change: transform, opacity;
  transform: translateY(0);
  overflow: hidden !important;
  position: fixed !important;
  transition: opacity 0.2s linear, transform 0.25s linear;
  z-index: 2147483000 !important;
}

.woot-widget-holder.woot-widget-holder--flat {
  box-shadow: none;
  border-radius: 0;
  border: 1px solid var(--b-100);
}

.woot-widget-holder iframe {
  border: 0;
  color-scheme: normal;
  height: 100% !important;
  width: 100% !important;
  max-height: 100vh !important;
}

.woot-widget-holder.has-unread-view {
  border-radius: 0 !important;
  min-height: 80px !important;
  height: auto;
  bottom: 94px;
  box-shadow: none !important;
  border: 0;
}

.woot-widget-bubble {
  border-radius: 100px !important;
  border: none !important;
  bottom: 20px;
  cursor: pointer;
  height: 64px !important;
  width: 64px !important;
  min-width: 64px !important;
  min-height: 64px !important;
  max-width: 64px !important;
  max-height: 64px !important;
  padding: 0px !important;
  position: fixed;
  user-select: none;
  z-index: 2147483000 !important;
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
  box-sizing: border-box !important;
  outline: none !important;
  flex-shrink: 0 !important;
}

.woot-widget-bubble .woot-widget--bubble__text {
  position: absolute !important;
  right: calc(100% + 16px) !important;
  white-space: nowrap !important;
  padding: 10px 18px !important;
  border-radius: 12px;
  top: 50% !important;
  transform: translateY(-50%) !important;
  font-size: 15px;
  font-weight: 600;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.15);
  transition: all 0.3s ease;
  color: #fff !important;
  background: linear-gradient(135deg, #28307f, #363c70) !important;
  pointer-events: none;
  display: block !important;
}

.woot-elements--left .woot-widget--bubble__text {
  right: auto !important;
  left: calc(100% + 16px) !important;
}

@media only screen and (min-width: 1441px) {
  .woot-widget-bubble .woot-widget--bubble__text {
    right: calc(100% + 16px);
  }
  .woot-elements--left .woot-widget--bubble__text {
    left: calc(100% + 16px);
  }
}

.woot-widget-bubble .bubble-icon-container {
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
  width: 100% !important;
  height: 100% !important;
  overflow: hidden !important;
  border-radius: inherit !important;
  pointer-events: none;
}

.woot-widget-bubble .bubble-icon {
  display: block;
  width: 100% !important;
  height: 100% !important;
  object-fit: cover !important;
  pointer-events: none;
  border-radius: 50% !important;
}

.woot-widget-bubble.woot-widget-bubble--flat {
  border-radius: 0;
}

.woot-widget-holder.woot-widget-holder--flat {
  bottom: 90px;
}

.woot-widget-bubble.woot-widget-bubble--flat {
  height: 56px !important;
  width: 56px !important;
}

.woot-widget-bubble.woot-widget-bubble--flat svg {
  margin: 16px;
}

.woot-widget-bubble.woot-widget-bubble--flat.woot--close::before,
.woot-widget-bubble.woot-widget-bubble--flat.woot--close::after {
  left: 28px;
  top: 16px;
}

.woot-widget-bubble.unread-notification::after {
  content: '';
  position: absolute;
  width: 12px;
  height: 12px;
  background: #ff4040;
  border-radius: 100%;
  top: 0px;
  right: 0px;
  border: 2px solid #ffffff;
  transition: background 0.2s ease;
}

.woot-widget-bubble.woot-widget--expanded {
  width: auto !important;
  max-width: none !important;
  border-radius: 100px !important;
  padding: 0 16px !important;
}

.woot-widget-bubble.woot-widget--expanded .bubble-icon-container {
  width: auto !important;
  height: auto !important;
  overflow: visible !important;
  border-radius: 0 !important;
}

.woot-widget-bubble.woot-widget--expanded .woot-widget--bubble__text {
  position: static !important;
  background: transparent !important;
  box-shadow: none !important;
  transform: none !important;
  color: white !important;
  padding: 0 !important;
  margin-left: 8px !important;
}

.woot-elements--left.woot-widget-bubble.woot-widget--expanded .woot-widget--bubble__text {
  margin-left: 0 !important;
  margin-right: 8px !important;
}

.woot-widget-bubble.woot-widget--expanded.woot-widget-bubble-color--lighter .woot-widget--bubble__text {
  color: var(--s-700) !important;
}

.woot-widget-bubble.woot-elements--left {
  left: 20px;
}

.woot-widget-bubble.woot-elements--right {
  right: 20px;
}

.woot-widget-bubble svg {
  height: 24px;
  margin: 20px;
  width: 24px;
}

.woot-widget-bubble.woot-widget--expanded svg {
  margin: 0;
}

.woot-widget-bubble.woot-widget-bubble-color--lighter path{
  fill: var(--s-700);
}

@media only screen and (min-width: 667px) {
  .woot-widget-holder.woot-elements--left {
    left: 20px;
 }
  .woot-widget-holder.woot-elements--right {
    right: 20px;
 }
}

@media only screen and (min-width: 1441px) {
  .woot-widget-holder.woot-elements--left {
    left: 40px;
 }
  .woot-widget-holder.woot-elements--right {
    right: 40px;
 }

 .woot-widget-bubble.woot-elements--left {
    left: 40px;
  }

  .woot-widget-bubble.woot-elements--right {
    right: 40px;
  }
}


.woot--hide {
  bottom: -100vh !important;
  top: unset !important;
  opacity: 0;
  visibility: hidden !important;
  z-index: -1 !important;
}

.woot-widget--without-bubble {
  bottom: 20px !important;
}
.woot-widget-holder.woot--hide{
  transform: translateY(40px);
}
.woot-widget-bubble.woot--close {
  transform: translateX(0px) scale(1) rotate(0deg);
  transition: transform 300ms ease, opacity 100ms ease, visibility 0ms linear 0ms, bottom 0ms linear 0ms;
}
.woot-widget-bubble.woot--close.woot--hide {
  transform: translateX(8px) scale(.75) rotate(45deg);
  transition: transform 300ms ease, opacity 200ms ease, visibility 0ms linear 500ms, bottom 0ms ease 200ms;
}

.woot-widget-bubble {
  transform-origin: center;
  will-change: transform, opacity;
  transform: translateX(0) scale(1) rotate(0deg);
  transition: transform 300ms ease, opacity 100ms ease, visibility 0ms linear 0ms, bottom 0ms linear 0ms;
}

@media only screen and (max-width: 667px) {
  .woot-widget-holder {
    height: 100%;
    right: 0;
    top: 0;
    width: 100%;
 }

 .woot-widget-holder iframe {
    min-height: 100% !important;
  }


 .woot-widget-holder.has-unread-view {
    height: auto;
    right: 0;
    width: auto;
    bottom: 0;
    top: auto;
    max-height: 100vh;
    padding: 0 8px;
  }

  .woot-widget-holder.has-unread-view iframe {
    min-height: unset !important;
  }

 .woot-widget-holder.has-unread-view.woot-elements--left {
    left: 0;
  }

  .woot-widget-bubble.woot--close {
    bottom: 60px;
    opacity: 0;
    visibility: hidden !important;
    z-index: -1 !important;
  }
}

@media only screen and (min-width: 667px) {
  .woot-widget-holder {
    border-radius: 16px;
    bottom: 124px;
    height: calc(90% - 64px - 20px);
    max-height: 640px !important;
    min-height: 250px !important;
    width: 400px !important;
 }
}

@media only screen and (min-width: 1441px) {
  .woot-widget-holder {
    bottom: 140px;
 }
}

.woot-hidden {
  display: none !important;
}

.woot-widget--bubble__text {
}
`;
