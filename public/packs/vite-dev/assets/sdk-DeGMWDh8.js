import{a as w}from"./js.cookie-Cz0CWeBA.js";import{C as F,a as H,p as I,S as R,b as W,c as P,d as V,e as q,f as K}from"./sharedFrameEvents-0qZ2yOho.js";import{i as X}from"./colorHelper-DkkSNPxc.js";import{m as j}from"./md5-BDNM3NLy.js";import"./index-DN3rM4CW.js";import"./_commonjsHelpers-BosuxZz1.js";const Y=`
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
  background: #1f93ff;
  border-radius: 100px;
  border-width: 0px;
  bottom: 20px;
  box-shadow: 0 8px 24px rgba(0, 0, 0, .16) !important;
  cursor: pointer;
  height: 64px;
  padding: 0px;
  position: fixed;
  user-select: none;
  width: 64px;
  z-index: 2147483000 !important;
  overflow: hidden;
}

.woot-widget-bubble.woot-widget-bubble--flat {
  border-radius: 0;
}

.woot-widget-holder.woot-widget-holder--flat {
  bottom: 90px;
}

.woot-widget-bubble.woot-widget-bubble--flat {
  height: 56px;
  width: 56px;
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
  display: flex;
  height: 48px !important;
  width: auto !important;
  align-items: center;
}

.woot-widget-bubble.woot-widget--expanded div {
  align-items: center;
  color: #fff;
  display: flex;
  font-family: system-ui, -apple-system, BlinkMacSystemFont, Segoe UI, Roboto, Oxygen-Sans, Ubuntu, Cantarell, Helvetica Neue, Arial, sans-serif;
  font-size: 16px;
  font-weight: 500;
  justify-content: center;
  padding-right: 20px;
  width: auto !important;
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

.woot-widget-bubble:hover {
  background: #1f93ff;
  box-shadow: 0 8px 32px rgba(0, 0, 0, .4) !important;
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

.woot--close:hover {
  opacity: 1;
}

.woot--close::before, .woot--close::after {
  background-color: #fff;
  content: ' ';
  display: inline;
  height: 24px;
  left: 32px;
  position: absolute;
  top: 20px;
  width: 2px;
}

.woot-widget-bubble-color--lighter.woot--close::before, .woot-widget-bubble-color--lighter.woot--close::after {
  background-color: var(--s-700);
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
.woot-widget-bubble.woot--hide {
  transform: translateX(8px) scale(.75) rotate(-30deg);
  transition: transform 300ms ease, opacity 200ms ease, visibility 0ms linear 500ms, bottom 0ms ease 200ms;
}

.woot-widget-bubble.woot-widget--expanded {
  transform: translateX(0px);
  transition: transform 300ms ease, opacity 100ms ease, visibility 0ms linear 0ms, bottom 0ms linear 0ms;
}
.woot-widget-bubble.woot-widget--expanded.woot--hide {
  transform: translateX(8px);
  transition: transform 300ms ease, opacity 200ms ease, visibility 0ms linear 500ms, bottom 0ms ease 200ms;
}
.woot-widget-bubble.woot-widget-bubble--flat.woot--close {
  transform: translateX(0px);
  transition: transform 300ms ease, opacity 10ms ease, visibility 0ms linear 0ms, bottom 0ms linear 0ms;
}
.woot-widget-bubble.woot-widget-bubble--flat.woot--close.woot--hide {
  transform: translateX(8px);
  transition: transform 300ms ease, opacity 200ms ease, visibility 0ms linear 500ms, bottom 0ms ease 200ms;
}
.woot-widget-bubble.woot-widget--expanded.woot-widget-bubble--flat {
  transform: translateX(0px);
  transition: transform 300ms ease, opacity 200ms ease, visibility 0ms linear 0ms, bottom 0ms linear 0ms;
}
.woot-widget-bubble.woot-widget--expanded.woot-widget-bubble--flat.woot--hide {
  transform: translateX(8px);
  transition: transform 300ms ease, opacity 200ms ease, visibility 0ms linear 500ms, bottom 0ms ease 200ms;
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
    bottom: 104px;
    height: calc(90% - 64px - 20px);
    max-height: 640px !important;
    min-height: 250px !important;
    width: 400px !important;
 }
}

.woot-hidden {
  display: none !important;
}
`,G=()=>{const e=document.createElement("style");e.innerHTML=`${Y}`,e.id="cw-widget-styles",e.dataset.turboPermanent=!0,document.body.appendChild(e)},v=(e,t)=>{const o=document.getElementById(e),n=t.querySelector(`#${e}`);o&&!n&&t.appendChild(o)},x=e=>{v("cw-bubble-holder",e),v("cw-widget-holder",e),v("cw-widget-styles",e)},b=(e,t)=>{e.classList.add(...t.split(" "))},y=(e,t)=>{e.classList.toggle(t)},f=(e,t)=>{e.classList.remove(...t.split(" "))},z=({referrerURL:e,referrerHost:t})=>{s.events.onLocationChange({referrerURL:e,referrerHost:t})},J=()=>{let e=document.location.href;const t=document.location.host,o={childList:!0,subtree:!0};z({referrerURL:e,referrerHost:t});const n=document.querySelector("body");new MutationObserver(i=>{i.forEach(()=>{e!==document.location.href&&(e=document.location.href,z({referrerURL:e,referrerHost:t}))})}).observe(n,o)},C=["standard","expanded_bubble"],M=["standard","flat"],B=["light","auto","dark"],D=e=>C.includes(e)?e:C[0],U=e=>D(e)===C[1],Q=e=>M.includes(e)?e:M[0],_=e=>e==="flat",T=e=>B.includes(e)?e:B[0],Z=({eventName:e,data:t=null})=>{let o;return typeof window.CustomEvent=="function"?o=new CustomEvent(e,{detail:t}):(o=document.createEvent("CustomEvent"),o.initCustomEvent(e,!1,!1,t)),o},u=({eventName:e,data:t})=>{const o=Z({eventName:e,data:t});window.dispatchEvent(o)},ee="M240.808 240.808H122.123C56.6994 240.808 3.45695 187.562 3.45695 122.122C3.45695 56.7031 56.6994 3.45697 122.124 3.45697C187.566 3.45697 240.808 56.7031 240.808 122.122V240.808Z",O=document.getElementsByTagName("body")[0],l=document.createElement("div"),d=document.createElement("div"),S=document.createElement("button"),m=document.createElement("button");document.createElement("span");const te=e=>{if(U(window.$shopiz.type)){const t=document.getElementById("woot-widget--expanded__text");t.innerText=e}},oe=({className:e,path:t,target:o})=>{let n=`${e} woot-elements--${window.$shopiz.position}`;const a=document.createElementNS("http://www.w3.org/2000/svg","svg");a.setAttributeNS(null,"id","woot-widget-bubble-icon"),a.setAttributeNS(null,"width","24"),a.setAttributeNS(null,"height","24"),a.setAttributeNS(null,"viewBox","0 0 240 240"),a.setAttributeNS(null,"fill","none"),a.setAttribute("xmlns","http://www.w3.org/2000/svg");const i=document.createElementNS("http://www.w3.org/2000/svg","path");if(i.setAttributeNS(null,"d",t),i.setAttributeNS(null,"fill","#FFFFFF"),a.appendChild(i),o.appendChild(a),U(window.$shopiz.type)){const r=document.createElement("div");r.id="woot-widget--expanded__text",r.innerText="",o.appendChild(r),n+=" woot-widget--expanded"}return o.className=n,o.title="Open chat window",o},ie=e=>{e&&b(d,"woot-hidden"),b(d,"woot--bubble-holder"),d.id="cw-bubble-holder",d.dataset.turboPermanent=!0,O.appendChild(d)},se=e=>{s.events.onBubbleToggle(e),e?u({eventName:F}):(u({eventName:H}),S.focus())},h=(e={})=>{const{toggleValue:t}=e,{isOpen:o}=window.$shopiz;if(o===t)return;const n=t===void 0?!o:t;window.$shopiz.isOpen=n,y(S,"woot--hide"),y(m,"woot--hide"),y(l,"woot--hide"),se(n)},ne=()=>{d.addEventListener("click",h)},ae=()=>{const e=document.querySelector(".woot-widget-holder");b(e,"has-unread-view")},k=()=>{const e=document.querySelector(".woot-widget-holder");f(e,"has-unread-view")},N=["avatar_url","email","name"],re=[...N,"identifier_hash"],E=()=>{const e="cw_user_",{websiteToken:t}=window.$shopiz;return`${e}${t}`},le=({identifier:e="",user:t})=>`${re.reduce((n,a)=>`${n}${a}${t[a]||""}`,"")}identifier${e}`,de=(...e)=>j(le(...e)),we=e=>N.reduce((t,o)=>t||!!e[o],!1),$=(e,t,{expires:o=365,baseDomain:n=void 0}={})=>{const a={expires:o,sameSite:"Lax",domain:n};typeof t=="object"&&(t=JSON.stringify(t)),w.set(e,t,a)},L=["click","touchstart","keypress","keydown"],be=()=>{let e;try{e=new(window.AudioContext||window.webkitAudioContext)}catch{}return e},ce=async(e="",t)=>{const o=be(),n=a=>{window.playAudioAlert=()=>{if(o){const i=o.createBufferSource();i.buffer=a,i.connect(o.destination),i.loop=!1,i.start()}}};if(o){const{type:a="dashboard",alertTone:i="ding"}=t||{},r=`${e}/audio/${a}/${i}.mp3`,c=new Request(r);fetch(c).then(g=>g.arrayBuffer()).then(g=>(o.decodeAudioData(g).then(n),new Promise(p=>p()))).catch(()=>{})}},A=(e,t="")=>$("cw_conversation",e,{baseDomain:t}),ue=e=>{const t=W(new Date,1);$("cw_snooze_campaigns_till",Number(t),{expires:t,baseDomain:e})},s={getUrl({baseUrl:e,websiteToken:t}){return`${e}/widget?website_token=${t}`},createFrame:({baseUrl:e,websiteToken:t})=>{if(s.getAppFrame())return;G();const o=document.createElement("iframe"),n=w.get("cw_conversation");let a=s.getUrl({baseUrl:e,websiteToken:t});n&&(a=`${a}&cw_conversation=${n}`),o.src=a,o.allow="camera;microphone;fullscreen;display-capture;picture-in-picture;clipboard-write;",o.id="chatwoot_live_chat_widget",o.style.visibility="hidden";let i=`woot-widget-holder woot--hide woot-elements--${window.$shopiz.position}`;window.$shopiz.hideMessageBubble&&(i+=" woot-widget--without-bubble"),_(window.$shopiz.widgetStyle)&&(i+=" woot-widget-holder--flat"),b(l,i),l.id="cw-widget-holder",l.dataset.turboPermanent=!0,l.appendChild(o),O.appendChild(l),s.initPostMessageCommunication(),s.initWindowSizeListener(),s.preventDefaultScroll()},getAppFrame:()=>document.getElementById("chatwoot_live_chat_widget"),getBubbleHolder:()=>document.getElementsByClassName("woot--bubble-holder"),sendMessage:(e,t)=>{s.getAppFrame().contentWindow.postMessage(`chatwoot-widget:${JSON.stringify({event:e,...t})}`,"*")},initPostMessageCommunication:()=>{window.onmessage=e=>{if(typeof e.data!="string"||e.data.indexOf("chatwoot-widget:")!==0)return;const t=JSON.parse(e.data.replace("chatwoot-widget:",""));typeof s.events[t.event]=="function"&&s.events[t.event](t)}},initWindowSizeListener:()=>{window.addEventListener("resize",()=>s.toggleCloseButton())},preventDefaultScroll:()=>{l.addEventListener("wheel",e=>{const t=e.deltaY,o=l.scrollHeight,n=l.offsetHeight,a=l.scrollTop;(a===0&&t<0||n+a===o&&t>0)&&e.preventDefault()})},setFrameHeightToFitContent:(e,t)=>{const o=s.getAppFrame(),n=t?`${e}px`:"100%";o&&o.setAttribute("style",`height: ${n} !important`)},setupAudioListeners:()=>{const{baseUrl:e=""}=window.$shopiz;ce(e,{type:"widget",alertTone:"ding"}).then(()=>L.forEach(t=>{document.removeEventListener(t,s.setupAudioListeners,!1)}))},events:{loaded:e=>{A(e.config.authToken,window.$shopiz.baseDomain),window.$shopiz.hasLoaded=!0;const t=w.get("cw_snooze_campaigns_till");s.sendMessage("config-set",{locale:window.$shopiz.locale,position:window.$shopiz.position,hideMessageBubble:window.$shopiz.hideMessageBubble,showPopoutButton:window.$shopiz.showPopoutButton,widgetStyle:window.$shopiz.widgetStyle,darkMode:window.$shopiz.darkMode,showUnreadMessagesDialog:window.$shopiz.showUnreadMessagesDialog,campaignsSnoozedTill:t,welcomeTitle:window.$shopiz.welcomeTitle,welcomeDescription:window.$shopiz.welcomeDescription,availableMessage:window.$shopiz.availableMessage,unavailableMessage:window.$shopiz.unavailableMessage,enableFileUpload:window.$shopiz.enableFileUpload,enableEmojiPicker:window.$shopiz.enableEmojiPicker,enableEndConversation:window.$shopiz.enableEndConversation}),s.onLoad({widgetColor:e.config.channelConfig.widgetColor}),s.toggleCloseButton(),window.$shopiz.user&&s.sendMessage("set-user",window.$shopiz.user),window.playAudioAlert=()=>{},L.forEach(o=>{document.addEventListener(o,s.setupAudioListeners,!1)}),window.$shopiz.resetTriggered||u({eventName:q})},error:({errorType:e,data:t})=>{u({eventName:V,data:t}),e===R&&w.remove(E())},onEvent({eventIdentifier:e,data:t}){u({eventName:e,data:t})},setBubbleLabel(e){te(window.$shopiz.launcherTitle||e.label)},setAuthCookie({data:{widgetAuthToken:e}}){A(e,window.$shopiz.baseDomain)},setCampaignReadOn(){ue(window.$shopiz.baseDomain)},postback(e){u({eventName:P,data:e})},toggleBubble:e=>{let t={};e==="open"?t.toggleValue=!0:e==="close"&&(t.toggleValue=!1),h(t)},popoutChatWindow:({baseUrl:e,websiteToken:t,locale:o})=>{const n=w.get("cw_conversation");window.$shopiz.toggle("close"),I(e,t,o,n)},closeWindow:()=>{h({toggleValue:!1}),k()},onBubbleToggle:e=>{s.sendMessage("toggle-open",{isOpen:e}),e&&s.pushEvent("webwidget.triggered")},onLocationChange:({referrerURL:e,referrerHost:t})=>{s.sendMessage("change-url",{referrerURL:e,referrerHost:t})},updateIframeHeight:e=>{const{extraHeight:t=0,isFixedHeight:o}=e;s.setFrameHeightToFitContent(t,o)},setUnreadMode:()=>{ae(),h({toggleValue:!0})},resetUnreadMode:()=>k(),handleNotificationDot:e=>{if(window.$shopiz.hideMessageBubble)return;const t=document.querySelector(".woot-widget-bubble");e.unreadMessageCount>0&&!t.classList.contains("unread-notification")?b(t,"unread-notification"):e.unreadMessageCount===0&&f(t,"unread-notification")},closeChat:()=>{h({toggleValue:!1})},playAudio:()=>{window.playAudioAlert()}},pushEvent:e=>{s.sendMessage("push-event",{eventName:e})},onLoad:({widgetColor:e})=>{const t=s.getAppFrame();if(t.style.visibility="",t.setAttribute("id","chatwoot_live_chat_widget"),s.getBubbleHolder().length)return;ie(window.$shopiz.hideMessageBubble),J();let o="woot-widget-bubble",n=`woot-elements--${window.$shopiz.position} woot-widget-bubble woot--close woot--hide`;_(window.$shopiz.widgetStyle)&&(o+=" woot-widget-bubble--flat",n+=" woot-widget-bubble--flat"),X(e)&&(o+=" woot-widget-bubble-color--lighter",n+=" woot-widget-bubble-color--lighter");const a=oe({className:o,path:ee,target:S});b(m,n),a.style.background=e,m.style.background=e,d.appendChild(a),d.appendChild(m),ne()},toggleCloseButton:()=>{let e=!1;window.matchMedia("(max-width: 668px)").matches&&(e=!0),s.sendMessage("toggle-close-button",{isMobile:e})}},ge=({baseUrl:e,websiteToken:t})=>{if(window.$shopiz)return;document.addEventListener("turbo:before-render",i=>{i.detail.renderMethod!=="morph"&&x(i.detail.newBody)}),window.Turbolinks&&document.addEventListener("turbolinks:before-render",i=>{x(i.data.newBody)}),document.addEventListener("astro:before-swap",i=>x(i.newDocument.body));const o=window.shopizSettings||{};let n=o.locale,a=o.baseDomain;o.useBrowserLanguage&&(n=window.navigator.language.replace("-","_")),window.$shopiz={baseUrl:e,baseDomain:a,hasLoaded:!1,hideMessageBubble:o.hideMessageBubble||!1,isOpen:!1,position:o.position==="left"?"left":"right",websiteToken:t,locale:n,useBrowserLanguage:o.useBrowserLanguage||!1,type:D(o.type),launcherTitle:o.launcherTitle||"",showPopoutButton:o.showPopoutButton||!1,showUnreadMessagesDialog:o.showUnreadMessagesDialog??!0,widgetStyle:Q(o.widgetStyle)||"standard",resetTriggered:!1,darkMode:T(o.darkMode),welcomeTitle:o.welcomeTitle||"",welcomeDescription:o.welcomeDescription||"",availableMessage:o.availableMessage||"",unavailableMessage:o.unavailableMessage||"",enableFileUpload:o.enableFileUpload??!0,enableEmojiPicker:o.enableEmojiPicker??!0,enableEndConversation:o.enableEndConversation??!0,toggle(i){s.events.toggleBubble(i)},toggleBubbleVisibility(i){let r=document.querySelector(".woot--bubble-holder"),c=document.querySelector(".woot-widget-holder");i==="hide"?(b(c,"woot-widget--without-bubble"),b(r,"woot-hidden"),window.$shopiz.hideMessageBubble=!0):i==="show"&&(f(r,"woot-hidden"),f(c,"woot-widget--without-bubble"),window.$shopiz.hideMessageBubble=!1),s.sendMessage(K,{hideMessageBubble:window.$shopiz.hideMessageBubble})},popoutChatWindow(){s.events.popoutChatWindow({baseUrl:window.$shopiz.baseUrl,websiteToken:window.$shopiz.websiteToken,locale:n})},setUser(i,r){if(typeof i!="string"&&typeof i!="number")throw new Error("Identifier should be a string or a number");if(!we(r))throw new Error("User object should have one of the keys [avatar_url, email, name]");const c=E(),g=w.get(c),p=de({identifier:i,user:r});p!==g&&(window.$shopiz.identifier=i,window.$shopiz.user=r,s.sendMessage("set-user",{identifier:i,user:r}),$(c,p,{baseDomain:a}))},setCustomAttributes(i={}){if(!i||!Object.keys(i).length)throw new Error("Custom attributes should have atleast one key");s.sendMessage("set-custom-attributes",{customAttributes:i})},deleteCustomAttribute(i=""){if(i)s.sendMessage("delete-custom-attribute",{customAttribute:i});else throw new Error("Custom attribute is required")},setConversationCustomAttributes(i={}){if(!i||!Object.keys(i).length)throw new Error("Custom attributes should have atleast one key");s.sendMessage("set-conversation-custom-attributes",{customAttributes:i})},deleteConversationCustomAttribute(i=""){if(i)s.sendMessage("delete-conversation-custom-attribute",{customAttribute:i});else throw new Error("Custom attribute is required")},setLabel(i=""){s.sendMessage("set-label",{label:i})},removeLabel(i=""){s.sendMessage("remove-label",{label:i})},setLocale(i="en"){s.sendMessage("set-locale",{locale:i})},setColorScheme(i="light"){s.sendMessage("set-color-scheme",{darkMode:T(i)})},reset(){window.$shopiz.isOpen&&s.events.toggleBubble(),w.remove("cw_conversation"),w.remove(E());const i=s.getAppFrame();i.src=s.getUrl({baseUrl:window.$shopiz.baseUrl,websiteToken:window.$shopiz.websiteToken}),window.$shopiz.resetTriggered=!0}},s.createFrame({baseUrl:e,websiteToken:t})};window.shopizSDK={run:ge};
