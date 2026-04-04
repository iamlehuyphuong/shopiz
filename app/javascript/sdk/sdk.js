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
  background: transparent !important;
  border-radius: 0px !important;
  border: none !important;
  bottom: 20px;
  cursor: pointer;
  height: 90px !important;
  width: 90px !important;
  min-width: 90px !important;
  min-height: 90px !important;
  max-width: 90px !important;
  max-height: 90px !important;
  padding: 0px !important;
  position: fixed;
  user-select: none;
  z-index: 2147483000 !important;
  display: flex !important;
  align-items: center !important;
  justify-content: center !important;
  box-sizing: border-box !important;
  outline: none !important;
  aspect-ratio: 1 / 1 !important;
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
  border-radius: 50% !important;
  pointer-events: none;
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
  bottom: 24px;
  display: flex !important;
  height: 90px !important;
  width: 90px !important;
  min-width: 90px !important;
  min-height: 90px !important;
  align-items: center !important;
  justify-content: center !important;
}

.woot-widget-bubble.woot-widget--expanded div {
  display: none !important;
}

.woot-widget-bubble.woot-widget--expanded.woot-widget-bubble-color--lighter div{
  color: var(--s-700);
}

.woot-widget-bubble.woot-widget--expanded svg {
  height: 20px;
  margin: 14px 8px 14px 16px;
  width: 20px;
}

.woot-widget-bubble.woot-elements--left {
  left: 20px;
}

.woot-widget-bubble.woot-elements--right {
  right: 20px;
}

.woot-widget-bubble svg {
  all: revert;
  height: 24px;
  margin: 20px;
  width: 24px;
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

.woot--close::before,
.woot--close::after {
  background: #fff;
  content: "";
  height: 2px;
  left: 31px;
  position: absolute;
  top: 44px;
  width: 28px;
}

.woot--close::before {
  transform: rotate(45deg);
}

.woot--close::after {
  transform: rotate(-45deg);
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
  background: transparent !important;
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
