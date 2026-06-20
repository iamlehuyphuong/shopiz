(function(){"use strict";/*! js-cookie v3.0.5 | MIT */function B(e){for(var t=1;t<arguments.length;t++){var o=arguments[t];for(var c in o)e[c]=o[c]}return e}var te={read:function(e){return e[0]==='"'&&(e=e.slice(1,-1)),e.replace(/(%[\dA-F]{2})+/gi,decodeURIComponent)},write:function(e){return encodeURIComponent(e).replace(/%(2[346BF]|3[AC-F]|40|5[BDE]|60|7[BCD])/g,decodeURIComponent)}};function S(e,t){function o(r,n,u){if(!(typeof document>"u")){u=B({},t,u),typeof u.expires=="number"&&(u.expires=new Date(Date.now()+u.expires*864e5)),u.expires&&(u.expires=u.expires.toUTCString()),r=encodeURIComponent(r).replace(/%(2[346B]|5E|60|7C)/g,decodeURIComponent).replace(/[()]/g,escape);var i="";for(var h in u)u[h]&&(i+="; "+h,u[h]!==!0&&(i+="="+u[h].split(";")[0]));return document.cookie=r+"="+e.write(n,r)+i}}function c(r){if(!(typeof document>"u"||arguments.length&&!r)){for(var n=document.cookie?document.cookie.split("; "):[],u={},i=0;i<n.length;i++){var h=n[i].split("="),a=h.slice(1).join("=");try{var s=decodeURIComponent(h[0]);if(u[s]=e.read(a,s),r===s)break}catch{}}return r?u[r]:u}}return Object.create({set:o,get:c,remove:function(r,n){o(r,"",B({},n,{expires:-1}))},withAttributes:function(r){return S(this.converter,B({},this.attributes,r))},withConverter:function(r){return S(B({},this.converter,r),this.attributes)}},{attributes:{value:Object.freeze(t)},converter:{value:Object.freeze(e)}})}var x=S(te,{path:"/"});const oe=`
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
`,ne=()=>{const e=document.createElement("style");e.innerHTML=`${oe}`,e.id="cw-widget-styles",e.dataset.turboPermanent=!0,document.body.appendChild(e)},T=(e,t)=>{const o=document.getElementById(e),c=t.querySelector(`#${e}`);o&&!c&&t.appendChild(o)},z=e=>{T("cw-bubble-holder",e),T("cw-widget-holder",e),T("cw-widget-styles",e)},y=(e,t)=>{e.classList.add(...t.split(" "))},M=(e,t)=>{e.classList.toggle(t)},$=(e,t)=>{e.classList.remove(...t.split(" "))},R=({referrerURL:e,referrerHost:t})=>{p.events.onLocationChange({referrerURL:e,referrerHost:t})},ie=()=>{let e=document.location.href;const t=document.location.host,o={childList:!0,subtree:!0};R({referrerURL:e,referrerHost:t});const c=document.querySelector("body");new MutationObserver(n=>{n.forEach(()=>{e!==document.location.href&&(e=document.location.href,R({referrerURL:e,referrerHost:t}))})}).observe(c,o)},k=["standard","expanded_bubble"],N=["standard","flat"],H=["light","auto","dark"],W=e=>k.includes(e)?e:k[0],U=e=>W(e)===k[1],re=e=>N.includes(e)?e:N[0],P=e=>e==="flat",j=e=>H.includes(e)?e:H[0],se="chatwoot:error",ae="chatwoot:postback",le="chatwoot:ready",de="chatwoot:opened",ce="chatwoot:closed",we=({eventName:e,data:t=null})=>{let o;return typeof window.CustomEvent=="function"?o=new CustomEvent(e,{detail:t}):(o=document.createEvent("CustomEvent"),o.initCustomEvent(e,!1,!1,t)),o},E=({eventName:e,data:t})=>{const o=we({eventName:e,data:t});window.dispatchEvent(o)},q=document.getElementsByTagName("body")[0],v=document.createElement("div"),C=document.createElement("div"),A=document.createElement("button"),F=document.createElement("button");document.createElement("span");const ue=e=>{if(U(window.$shopiz.type)){const t=document.getElementById("woot-widget--expanded__text");t&&(t.innerText=e);const o=document.getElementById("woot-widget--launcher__text");o&&(o.innerText=e)}},pe=({target:e,imageUrl:t})=>{if(!t)return;const o=document.createElement("div");o.className="bubble-icon-container";const c=document.createElement("img");c.className="bubble-icon",c.setAttribute("src",t),o.appendChild(c),e.appendChild(o)},he=({className:e,target:t,widgetColor:o,bubbleAvatarUrl:c})=>{let r=`${e} woot-elements--${window.$shopiz.position}`;if(c)pe({target:t,imageUrl:c}),t.style.background="transparent";else{const n=document.createElement("div");n.className="bubble-icon-container",n.innerHTML='<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-message-circle-more-icon lucide-message-circle-more"><path d="M2.992 16.342a2 2 0 0 1 .094 1.167l-1.065 3.29a1 1 0 0 0 1.236 1.168l3.413-.998a2 2 0 0 1 1.099.092 10 10 0 1 0-4.777-4.719"/><path d="M8 12h.01"/><path d="M12 12h.01"/><path d="M16 12h.01"/></svg>',t.appendChild(n),t.style.setProperty("background",o,"important"),t.style.borderRadius="50%",t.style.boxShadow="0 8px 24px rgba(0, 0, 0, .16)"}if(U(window.$shopiz.type)&&window.$shopiz.launcherTitle){const n=document.createElement("span");n.id="woot-widget--launcher__text",n.className="woot-widget--bubble__text",n.innerText=window.$shopiz.launcherTitle,t.appendChild(n)}return t.className=r,t},ge=({className:e,target:t,widgetColor:o})=>{let c=`${e} woot-elements--${window.$shopiz.position}`;const r=document.createElement("div");return r.className="bubble-icon-container",r.innerHTML='<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="#ffffff" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="lucide lucide-x-icon lucide-x"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>',t.appendChild(r),t.style.setProperty("background",o,"important"),t.style.borderRadius="100px",t.style.boxShadow="0 8px 24px rgba(0, 0, 0, .16)",t.className=c,t},be=e=>{e&&y(C,"woot-hidden"),y(C,"woot--bubble-holder"),C.id="cw-bubble-holder",C.dataset.turboPermanent=!0,q.appendChild(C)},me=e=>{p.events.onBubbleToggle(e),e?E({eventName:de}):(E({eventName:ce}),A.focus())},_=(e={})=>{const{toggleValue:t}=e,{isOpen:o}=window.$shopiz;if(o===t)return;const c=t===void 0?!o:t;window.$shopiz.isOpen=c,M(A,"woot--hide"),M(F,"woot--hide"),M(v,"woot--hide"),me(c)},fe=()=>{C.addEventListener("click",_)},ve=()=>{const e=document.querySelector(".woot-widget-holder");y(e,"has-unread-view")},K=()=>{const e=document.querySelector(".woot-widget-holder");$(e,"has-unread-view")},xe=e=>{if(!e||typeof e!="string")return!1;const t=e.replace("#",""),o=parseInt(t.substr(0,2),16),c=parseInt(t.substr(2,2),16),r=parseInt(t.substr(4,2),16);return(o*299+c*587+r*114)/1e3>225},ye="SET_USER_ERROR";function Ce(e){return e&&e.__esModule&&Object.prototype.hasOwnProperty.call(e,"default")?e.default:e}var V={exports:{}},Y={exports:{}};(function(){var e="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",t={rotl:function(o,c){return o<<c|o>>>32-c},rotr:function(o,c){return o<<32-c|o>>>c},endian:function(o){if(o.constructor==Number)return t.rotl(o,8)&16711935|t.rotl(o,24)&4278255360;for(var c=0;c<o.length;c++)o[c]=t.endian(o[c]);return o},randomBytes:function(o){for(var c=[];o>0;o--)c.push(Math.floor(Math.random()*256));return c},bytesToWords:function(o){for(var c=[],r=0,n=0;r<o.length;r++,n+=8)c[n>>>5]|=o[r]<<24-n%32;return c},wordsToBytes:function(o){for(var c=[],r=0;r<o.length*32;r+=8)c.push(o[r>>>5]>>>24-r%32&255);return c},bytesToHex:function(o){for(var c=[],r=0;r<o.length;r++)c.push((o[r]>>>4).toString(16)),c.push((o[r]&15).toString(16));return c.join("")},hexToBytes:function(o){for(var c=[],r=0;r<o.length;r+=2)c.push(parseInt(o.substr(r,2),16));return c},bytesToBase64:function(o){for(var c=[],r=0;r<o.length;r+=3)for(var n=o[r]<<16|o[r+1]<<8|o[r+2],u=0;u<4;u++)r*8+u*6<=o.length*8?c.push(e.charAt(n>>>6*(3-u)&63)):c.push("=");return c.join("")},base64ToBytes:function(o){o=o.replace(/[^A-Z0-9+\/]/ig,"");for(var c=[],r=0,n=0;r<o.length;n=++r%4)n!=0&&c.push((e.indexOf(o.charAt(r-1))&Math.pow(2,-2*n+8)-1)<<n*2|e.indexOf(o.charAt(r))>>>6-n*2);return c}};Y.exports=t})();var Ee=Y.exports,L={utf8:{stringToBytes:function(e){return L.bin.stringToBytes(unescape(encodeURIComponent(e)))},bytesToString:function(e){return decodeURIComponent(escape(L.bin.bytesToString(e)))}},bin:{stringToBytes:function(e){for(var t=[],o=0;o<e.length;o++)t.push(e.charCodeAt(o)&255);return t},bytesToString:function(e){for(var t=[],o=0;o<e.length;o++)t.push(String.fromCharCode(e[o]));return t.join("")}}},G=L;/*!
 * Determine if an object is a Buffer
 *
 * @author   Feross Aboukhadijeh <https://feross.org>
 * @license  MIT
 */var _e=function(e){return e!=null&&(X(e)||Be(e)||!!e._isBuffer)};function X(e){return!!e.constructor&&typeof e.constructor.isBuffer=="function"&&e.constructor.isBuffer(e)}function Be(e){return typeof e.readFloatLE=="function"&&typeof e.slice=="function"&&X(e.slice(0,0))}(function(){var e=Ee,t=G.utf8,o=_e,c=G.bin,r=function(n,u){n.constructor==String?u&&u.encoding==="binary"?n=c.stringToBytes(n):n=t.stringToBytes(n):o(n)?n=Array.prototype.slice.call(n,0):!Array.isArray(n)&&n.constructor!==Uint8Array&&(n=n.toString());for(var i=e.bytesToWords(n),h=n.length*8,a=1732584193,s=-271733879,d=-1732584194,l=271733878,w=0;w<i.length;w++)i[w]=(i[w]<<8|i[w]>>>24)&16711935|(i[w]<<24|i[w]>>>8)&4278255360;i[h>>>5]|=128<<h%32,i[(h+64>>>9<<4)+14]=h;for(var g=r._ff,b=r._gg,m=r._hh,f=r._ii,w=0;w<i.length;w+=16){var je=a,qe=s,Ke=d,Ve=l;a=g(a,s,d,l,i[w+0],7,-680876936),l=g(l,a,s,d,i[w+1],12,-389564586),d=g(d,l,a,s,i[w+2],17,606105819),s=g(s,d,l,a,i[w+3],22,-1044525330),a=g(a,s,d,l,i[w+4],7,-176418897),l=g(l,a,s,d,i[w+5],12,1200080426),d=g(d,l,a,s,i[w+6],17,-1473231341),s=g(s,d,l,a,i[w+7],22,-45705983),a=g(a,s,d,l,i[w+8],7,1770035416),l=g(l,a,s,d,i[w+9],12,-1958414417),d=g(d,l,a,s,i[w+10],17,-42063),s=g(s,d,l,a,i[w+11],22,-1990404162),a=g(a,s,d,l,i[w+12],7,1804603682),l=g(l,a,s,d,i[w+13],12,-40341101),d=g(d,l,a,s,i[w+14],17,-1502002290),s=g(s,d,l,a,i[w+15],22,1236535329),a=b(a,s,d,l,i[w+1],5,-165796510),l=b(l,a,s,d,i[w+6],9,-1069501632),d=b(d,l,a,s,i[w+11],14,643717713),s=b(s,d,l,a,i[w+0],20,-373897302),a=b(a,s,d,l,i[w+5],5,-701558691),l=b(l,a,s,d,i[w+10],9,38016083),d=b(d,l,a,s,i[w+15],14,-660478335),s=b(s,d,l,a,i[w+4],20,-405537848),a=b(a,s,d,l,i[w+9],5,568446438),l=b(l,a,s,d,i[w+14],9,-1019803690),d=b(d,l,a,s,i[w+3],14,-187363961),s=b(s,d,l,a,i[w+8],20,1163531501),a=b(a,s,d,l,i[w+13],5,-1444681467),l=b(l,a,s,d,i[w+2],9,-51403784),d=b(d,l,a,s,i[w+7],14,1735328473),s=b(s,d,l,a,i[w+12],20,-1926607734),a=m(a,s,d,l,i[w+5],4,-378558),l=m(l,a,s,d,i[w+8],11,-2022574463),d=m(d,l,a,s,i[w+11],16,1839030562),s=m(s,d,l,a,i[w+14],23,-35309556),a=m(a,s,d,l,i[w+1],4,-1530992060),l=m(l,a,s,d,i[w+4],11,1272893353),d=m(d,l,a,s,i[w+7],16,-155497632),s=m(s,d,l,a,i[w+10],23,-1094730640),a=m(a,s,d,l,i[w+13],4,681279174),l=m(l,a,s,d,i[w+0],11,-358537222),d=m(d,l,a,s,i[w+3],16,-722521979),s=m(s,d,l,a,i[w+6],23,76029189),a=m(a,s,d,l,i[w+9],4,-640364487),l=m(l,a,s,d,i[w+12],11,-421815835),d=m(d,l,a,s,i[w+15],16,530742520),s=m(s,d,l,a,i[w+2],23,-995338651),a=f(a,s,d,l,i[w+0],6,-198630844),l=f(l,a,s,d,i[w+7],10,1126891415),d=f(d,l,a,s,i[w+14],15,-1416354905),s=f(s,d,l,a,i[w+5],21,-57434055),a=f(a,s,d,l,i[w+12],6,1700485571),l=f(l,a,s,d,i[w+3],10,-1894986606),d=f(d,l,a,s,i[w+10],15,-1051523),s=f(s,d,l,a,i[w+1],21,-2054922799),a=f(a,s,d,l,i[w+8],6,1873313359),l=f(l,a,s,d,i[w+15],10,-30611744),d=f(d,l,a,s,i[w+6],15,-1560198380),s=f(s,d,l,a,i[w+13],21,1309151649),a=f(a,s,d,l,i[w+4],6,-145523070),l=f(l,a,s,d,i[w+11],10,-1120210379),d=f(d,l,a,s,i[w+2],15,718787259),s=f(s,d,l,a,i[w+9],21,-343485551),a=a+je>>>0,s=s+qe>>>0,d=d+Ke>>>0,l=l+Ve>>>0}return e.endian([a,s,d,l])};r._ff=function(n,u,i,h,a,s,d){var l=n+(u&i|~u&h)+(a>>>0)+d;return(l<<s|l>>>32-s)+u},r._gg=function(n,u,i,h,a,s,d){var l=n+(u&h|i&~h)+(a>>>0)+d;return(l<<s|l>>>32-s)+u},r._hh=function(n,u,i,h,a,s,d){var l=n+(u^i^h)+(a>>>0)+d;return(l<<s|l>>>32-s)+u},r._ii=function(n,u,i,h,a,s,d){var l=n+(i^(u|~h))+(a>>>0)+d;return(l<<s|l>>>32-s)+u},r._blocksize=16,r._digestsize=16,V.exports=function(n,u){if(n==null)throw new Error("Illegal argument "+n);var i=e.wordsToBytes(r(n,u));return u&&u.asBytes?i:u&&u.asString?c.bytesToString(i):e.bytesToHex(i)}})();var $e=V.exports;const Se=Ce($e),J=["avatar_url","email","name"],Te=[...J,"identifier_hash"],D=()=>{const e="cw_user_",{websiteToken:t}=window.$shopiz;return`${e}${t}`},ze=({identifier:e="",user:t})=>`${Te.reduce((c,r)=>`${c}${r}${t[r]||""}`,"")}identifier${e}`,Me=(...e)=>Se(ze(...e)),ke=e=>J.reduce((t,o)=>t||!!e[o],!1),I=(e,t,{expires:o=365,baseDomain:c=void 0}={})=>{const r={expires:o,sameSite:"Lax",domain:c};typeof t=="object"&&(t=JSON.stringify(t)),x.set(e,t,r)},Q=["click","touchstart","keypress","keydown"],Ue=()=>{let e;try{e=new(window.AudioContext||window.webkitAudioContext)}catch{}return e},Ae=async(e="",t)=>{const o=Ue(),c=r=>{window.playAudioAlert=()=>{if(o){const n=o.createBufferSource();n.buffer=r,n.connect(o.destination),n.loop=!1,n.start()}}};if(o){const{type:r="dashboard",alertTone:n="pium_pium"}=t||{},u=`${e}/audio/${r}/${n}.mp3`,i=new Request(u);fetch(i).then(h=>h.arrayBuffer()).then(h=>(o.decodeAudioData(h).then(c),new Promise(a=>a()))).catch(()=>{})}},Fe=({origin:e,conversationCookie:t,websiteToken:o,locale:c})=>{const r=new URL("/widget",e);return r.searchParams.append("cw_conversation",t),r.searchParams.append("website_token",o),r.searchParams.append("locale",c),r.toString()},Le=(e,t,o,c)=>{try{const r=Fe({origin:e,websiteToken:t,locale:o,conversationCookie:c});window.open(r,`webwidget_session_${t}`,"resizable=off,width=400,height=600").focus()}catch(r){console.log(r)}};function Z(e){if(e===null||e===!0||e===!1)return NaN;var t=Number(e);return isNaN(t)?t:t<0?Math.ceil(t):Math.floor(t)}function O(e,t){if(t.length<e)throw new TypeError(e+" argument"+(e>1?"s":"")+" required, but only "+t.length+" present")}function De(e){O(1,arguments);var t=Object.prototype.toString.call(e);return e instanceof Date||typeof e=="object"&&t==="[object Date]"?new Date(e.getTime()):typeof e=="number"||t==="[object Number]"?new Date(e):((typeof e=="string"||t==="[object String]")&&typeof console<"u"&&(console.warn("Starting with v2.0.0-beta.1 date-fns doesn't accept strings as date arguments. Please use `parseISO` to parse strings. See: https://git.io/fjule"),console.warn(new Error().stack)),new Date(NaN))}function Ie(e,t){O(2,arguments);var o=De(e).getTime(),c=Z(t);return new Date(o+c)}var Oe=36e5;function Re(e,t){O(2,arguments);var o=Z(t);return Ie(e,o*Oe)}const Ne=e=>e?e.startsWith("http://")||e.startsWith("https://")||e.startsWith("data:")?e:`${window.$shopiz.baseUrl.replace(/\/$/,"")}${e.startsWith("/")?"":"/"}${e}`:"",ee=(e,t="")=>I("cw_conversation",e,{baseDomain:t}),He=e=>{const t=Re(new Date,1);I("cw_snooze_campaigns_till",Number(t),{expires:t,baseDomain:e})},p={getUrl({baseUrl:e,websiteToken:t}){return`${e}/widget?website_token=${t}`},createFrame:({baseUrl:e,websiteToken:t})=>{if(p.getAppFrame())return;ne();const o=document.createElement("iframe"),c=x.get("cw_conversation");let r=p.getUrl({baseUrl:e,websiteToken:t});c&&(r=`${r}&cw_conversation=${c}`),o.src=r,o.allow="camera;microphone;fullscreen;display-capture;picture-in-picture;clipboard-write;",o.id="chatwoot_live_chat_widget",o.style.visibility="hidden";let n=`woot-widget-holder woot--hide woot-elements--${window.$shopiz.position}`;window.$shopiz.hideMessageBubble&&(n+=" woot-widget--without-bubble"),P(window.$shopiz.widgetStyle)&&(n+=" woot-widget-holder--flat"),y(v,n),v.id="cw-widget-holder",v.dataset.turboPermanent=!0,v.appendChild(o),q.appendChild(v),p.initPostMessageCommunication(),p.initWindowSizeListener(),p.preventDefaultScroll()},getAppFrame:()=>document.getElementById("chatwoot_live_chat_widget"),getBubbleHolder:()=>document.getElementsByClassName("woot--bubble-holder"),sendMessage:(e,t)=>{const o=p.getAppFrame();o&&o.contentWindow.postMessage(`chatwoot-widget:${JSON.stringify({event:e,...t})}`,"*")},initPostMessageCommunication:()=>{window.onmessage=e=>{if(typeof e.data!="string"||e.data.indexOf("chatwoot-widget:")!==0)return;const t=JSON.parse(e.data.replace("chatwoot-widget:",""));typeof p.events[t.event]=="function"&&p.events[t.event](t)}},initWindowSizeListener:()=>{window.addEventListener("resize",()=>p.toggleCloseButton())},preventDefaultScroll:()=>{v.addEventListener("wheel",e=>{const t=e.deltaY,o=v.scrollHeight,c=v.offsetHeight,r=v.scrollTop;(r===0&&t<0||c+r===o&&t>0)&&e.preventDefault()})},setFrameHeightToFitContent:(e,t)=>{const o=p.getAppFrame(),c=t?`${e}px`:"100%";o&&o.setAttribute("style",`height: ${c} !important`)},setupAudioListeners:()=>{const{baseUrl:e=""}=window.$shopiz;Ae(e,{type:"widget",alertTone:"ding"}).then(()=>Q.forEach(t=>{document.removeEventListener(t,p.setupAudioListeners,!1)}))},events:{loaded:e=>{ee(e.config.authToken,window.$shopiz.baseDomain),window.$shopiz.hasLoaded=!0;const t=x.get("cw_snooze_campaigns_till");p.sendMessage("config-set",{locale:window.$shopiz.locale,position:window.$shopiz.position,hideMessageBubble:window.$shopiz.hideMessageBubble,showPopoutButton:window.$shopiz.showPopoutButton,widgetStyle:window.$shopiz.widgetStyle,darkMode:window.$shopiz.darkMode,showUnreadMessagesDialog:window.$shopiz.showUnreadMessagesDialog,campaignsSnoozedTill:t,welcomeTitle:window.$shopiz.welcomeTitle,welcomeDescription:window.$shopiz.welcomeDescription,availableMessage:window.$shopiz.availableMessage,unavailableMessage:window.$shopiz.unavailableMessage,enableFileUpload:window.$shopiz.enableFileUpload,enableEmojiPicker:window.$shopiz.enableEmojiPicker,enableEndConversation:window.$shopiz.enableEndConversation,widgetColor:window.$shopiz.widgetColor||e.config.channelConfig.widgetColor}),p.onLoad({widgetColor:e.config.channelConfig.widgetColor,bubbleAvatarUrl:e.config.channelConfig.bubbleAvatarUrl,closeBubbleAvatarUrl:e.config.channelConfig.closeBubbleAvatarUrl}),p.toggleCloseButton(),window.$shopiz.user&&p.sendMessage("set-user",window.$shopiz.user),window.playAudioAlert=()=>{},Q.forEach(o=>{document.addEventListener(o,p.setupAudioListeners,!1)}),window.$shopiz.resetTriggered||E({eventName:le})},error:({errorType:e,data:t})=>{E({eventName:se,data:t}),e===ye&&x.remove(D())},onEvent({eventIdentifier:e,data:t}){E({eventName:e,data:t})},setBubbleLabel(e){ue(window.$shopiz.launcherTitle||e.label)},setAuthCookie({data:{widgetAuthToken:e}}){ee(e,window.$shopiz.baseDomain)},setCampaignReadOn(){He(window.$shopiz.baseDomain)},postback(e){E({eventName:ae,data:e})},toggleBubble:e=>{let t={};e==="open"?t.toggleValue=!0:e==="close"&&(t.toggleValue=!1),_(t)},popoutChatWindow:({baseUrl:e,websiteToken:t,locale:o})=>{const c=x.get("cw_conversation");window.$shopiz.toggle("close"),Le(e,t,o,c)},closeWindow:()=>{_({toggleValue:!1}),K()},onBubbleToggle:e=>{p.sendMessage("toggle-open",{isOpen:e}),e&&p.pushEvent("webwidget.triggered")},onLocationChange:({referrerURL:e,referrerHost:t})=>{p.sendMessage("change-url",{referrerURL:e,referrerHost:t})},updateIframeHeight:e=>{const{extraHeight:t=0,isFixedHeight:o}=e;p.setFrameHeightToFitContent(t,o)},setUnreadMode:()=>{ve(),_({toggleValue:!0})},resetUnreadMode:()=>K(),handleNotificationDot:e=>{if(window.$shopiz.hideMessageBubble)return;const t=document.querySelector(".woot-widget-bubble");e.unreadMessageCount>0&&!t.classList.contains("unread-notification")?y(t,"unread-notification"):e.unreadMessageCount===0&&$(t,"unread-notification")},closeChat:()=>{_({toggleValue:!1})},playAudio:()=>{window.playAudioAlert()}},pushEvent:e=>{p.sendMessage("push-event",{eventName:e})},onLoad:({widgetColor:e,bubbleAvatarUrl:t,closeBubbleAvatarUrl:o})=>{const c=p.getAppFrame();if(c.style.visibility="",c.setAttribute("id","chatwoot_live_chat_widget"),p.getBubbleHolder().length)return;be(window.$shopiz.hideMessageBubble),ie();let r="woot-widget-bubble",n=`woot-elements--${window.$shopiz.position} woot-widget-bubble woot--close woot--hide`;P(window.$shopiz.widgetStyle)&&(r+=" woot-widget-bubble--flat",n+=" woot-widget-bubble--flat"),U(window.$shopiz.type)&&(r+=" woot-widget--expanded");const u=window.$shopiz.widgetColor||e;xe(u)&&(r+=" woot-widget-bubble-color--lighter",n+=" woot-widget-bubble-color--lighter");const i=he({className:r,target:A,widgetColor:u,bubbleAvatarUrl:Ne(t)}),h=ge({className:r.replace(" woot-widget--expanded",""),target:F,widgetColor:u});y(h,n),C.appendChild(i),C.appendChild(F),fe()},toggleCloseButton:()=>{let e=!1;window.matchMedia("(max-width: 668px)").matches&&(e=!0),p.sendMessage("toggle-close-button",{isMobile:e})}},We="sdk-set-bubble-visibility",Pe=({baseUrl:e,websiteToken:t})=>{if(window.$shopiz)return;document.addEventListener("turbo:before-render",n=>{n.detail.renderMethod!=="morph"&&z(n.detail.newBody)}),window.Turbolinks&&document.addEventListener("turbolinks:before-render",n=>{z(n.data.newBody)}),document.addEventListener("astro:before-swap",n=>z(n.newDocument.body));const o=window.shopizSettings||{};let c=o.locale,r=o.baseDomain;o.useBrowserLanguage&&(c=window.navigator.language.replace("-","_")),window.$shopiz={baseUrl:e,baseDomain:r,hasLoaded:!1,hideMessageBubble:o.hideMessageBubble||!1,isOpen:!1,position:o.position==="left"?"left":"right",websiteToken:t,locale:c,useBrowserLanguage:o.useBrowserLanguage||!1,type:W(o.type),launcherTitle:o.launcherTitle||"",showPopoutButton:o.showPopoutButton||!1,showUnreadMessagesDialog:o.showUnreadMessagesDialog??!0,widgetStyle:re(o.widgetStyle)||"standard",resetTriggered:!1,darkMode:j(o.darkMode),welcomeTitle:o.welcomeTitle||"",welcomeDescription:o.welcomeDescription||"",availableMessage:o.availableMessage||"",unavailableMessage:o.unavailableMessage||"",enableFileUpload:o.enableFileUpload,enableEmojiPicker:o.enableEmojiPicker??!0,enableEndConversation:o.enableEndConversation??!0,widgetColor:o.widgetColor||"",toggle(n){p.events.toggleBubble(n)},toggleBubbleVisibility(n){let u=document.querySelector(".woot--bubble-holder"),i=document.querySelector(".woot-widget-holder");n==="hide"?(y(i,"woot-widget--without-bubble"),y(u,"woot-hidden"),window.$shopiz.hideMessageBubble=!0):n==="show"&&($(u,"woot-hidden"),$(i,"woot-widget--without-bubble"),window.$shopiz.hideMessageBubble=!1),p.sendMessage(We,{hideMessageBubble:window.$shopiz.hideMessageBubble})},popoutChatWindow(){p.events.popoutChatWindow({baseUrl:window.$shopiz.baseUrl,websiteToken:window.$shopiz.websiteToken,locale:c})},setUser(n,u){if(typeof n!="string"&&typeof n!="number")throw new Error("Identifier should be a string or a number");if(!ke(u))throw new Error("User object should have one of the keys [avatar_url, email, name]");const i=D(),h=x.get(i),a=Me({identifier:n,user:u});a!==h&&(window.$shopiz.identifier=n,window.$shopiz.user=u,p.sendMessage("set-user",{identifier:n,user:u}),I(i,a,{baseDomain:r}))},setCustomAttributes(n={}){if(!n||!Object.keys(n).length)throw new Error("Custom attributes should have atleast one key");p.sendMessage("set-custom-attributes",{customAttributes:n})},deleteCustomAttribute(n=""){if(n)p.sendMessage("delete-custom-attribute",{customAttribute:n});else throw new Error("Custom attribute is required")},setConversationCustomAttributes(n={}){if(!n||!Object.keys(n).length)throw new Error("Custom attributes should have atleast one key");p.sendMessage("set-conversation-custom-attributes",{customAttributes:n})},deleteConversationCustomAttribute(n=""){if(n)p.sendMessage("delete-conversation-custom-attribute",{customAttribute:n});else throw new Error("Custom attribute is required")},setLabel(n=""){p.sendMessage("set-label",{label:n})},removeLabel(n=""){p.sendMessage("remove-label",{label:n})},setLocale(n="en"){p.sendMessage("set-locale",{locale:n})},setColorScheme(n="light"){p.sendMessage("set-color-scheme",{darkMode:j(n)})},reset(){window.$shopiz.isOpen&&p.events.toggleBubble(),x.remove("cw_conversation"),x.remove(D());const n=p.getAppFrame();n.src=p.getUrl({baseUrl:window.$shopiz.baseUrl,websiteToken:window.$shopiz.websiteToken}),window.$shopiz.resetTriggered=!0}},p.createFrame({baseUrl:e,websiteToken:t})};window.shopizSDK={run:Pe}})();
