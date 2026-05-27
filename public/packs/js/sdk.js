(function(){"use strict";/*! js-cookie v3.0.5 | MIT */function B(e){for(var o=1;o<arguments.length;o++){var t=arguments[o];for(var c in t)e[c]=t[c]}return e}var te={read:function(e){return e[0]==='"'&&(e=e.slice(1,-1)),e.replace(/(%[\dA-F]{2})+/gi,decodeURIComponent)},write:function(e){return encodeURIComponent(e).replace(/%(2[346BF]|3[AC-F]|40|5[BDE]|60|7[BCD])/g,decodeURIComponent)}};function $(e,o){function t(l,n,u){if(!(typeof document>"u")){u=B({},o,u),typeof u.expires=="number"&&(u.expires=new Date(Date.now()+u.expires*864e5)),u.expires&&(u.expires=u.expires.toUTCString()),l=encodeURIComponent(l).replace(/%(2[346B]|5E|60|7C)/g,decodeURIComponent).replace(/[()]/g,escape);var i="";for(var h in u)u[h]&&(i+="; "+h,u[h]!==!0&&(i+="="+u[h].split(";")[0]));return document.cookie=l+"="+e.write(n,l)+i}}function c(l){if(!(typeof document>"u"||arguments.length&&!l)){for(var n=document.cookie?document.cookie.split("; "):[],u={},i=0;i<n.length;i++){var h=n[i].split("="),s=h.slice(1).join("=");try{var r=decodeURIComponent(h[0]);if(u[r]=e.read(s,r),l===r)break}catch{}}return l?u[l]:u}}return Object.create({set:t,get:c,remove:function(l,n){t(l,"",B({},n,{expires:-1}))},withAttributes:function(l){return $(this.converter,B({},this.attributes,l))},withConverter:function(l){return $(B({},this.converter,l),this.attributes)}},{attributes:{value:Object.freeze(o)},converter:{value:Object.freeze(e)}})}var x=$(te,{path:"/"});const oe=`
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
`,ne=()=>{const e=document.createElement("style");e.innerHTML=`${oe}`,e.id="cw-widget-styles",e.dataset.turboPermanent=!0,document.body.appendChild(e)},z=(e,o)=>{const t=document.getElementById(e),c=o.querySelector(`#${e}`);t&&!c&&o.appendChild(t)},M=e=>{z("cw-bubble-holder",e),z("cw-widget-holder",e),z("cw-widget-styles",e)},y=(e,o)=>{e.classList.add(...o.split(" "))},k=(e,o)=>{e.classList.toggle(o)},S=(e,o)=>{e.classList.remove(...o.split(" "))},O=({referrerURL:e,referrerHost:o})=>{p.events.onLocationChange({referrerURL:e,referrerHost:o})},ie=()=>{let e=document.location.href;const o=document.location.host,t={childList:!0,subtree:!0};O({referrerURL:e,referrerHost:o});const c=document.querySelector("body");new MutationObserver(n=>{n.forEach(()=>{e!==document.location.href&&(e=document.location.href,O({referrerURL:e,referrerHost:o}))})}).observe(c,t)},U=["standard","expanded_bubble"],R=["standard","flat"],N=["light","auto","dark"],H=e=>U.includes(e)?e:U[0],re=e=>H(e)===U[1],se=e=>R.includes(e)?e:R[0],W=e=>e==="flat",P=e=>N.includes(e)?e:N[0],ae="chatwoot:error",le="chatwoot:postback",de="chatwoot:ready",ce="chatwoot:opened",we="chatwoot:closed",ue=({eventName:e,data:o=null})=>{let t;return typeof window.CustomEvent=="function"?t=new CustomEvent(e,{detail:o}):(t=document.createEvent("CustomEvent"),t.initCustomEvent(e,!1,!1,o)),t},E=({eventName:e,data:o})=>{const t=ue({eventName:e,data:o});window.dispatchEvent(t)},pe="M240.808 240.808H122.123C56.6994 240.808 3.45695 187.562 3.45695 122.122C3.45695 56.7031 56.6994 3.45697 122.124 3.45697C187.566 3.45697 240.808 56.7031 240.808 122.122V240.808Z",j=document.getElementsByTagName("body")[0],v=document.createElement("div"),C=document.createElement("div"),A=document.createElement("button"),T=document.createElement("button");document.createElement("span");const he=e=>{if(re(window.$flowify.type)){const t=document.getElementById("woot-widget--expanded__text");t&&(t.innerText=e)}const o=document.getElementById("woot-widget--launcher__text");o&&(o.innerText=e)},V=({target:e,imageUrl:o})=>{if(!o)return;const t=document.createElement("div");t.className="bubble-icon-container";const c=document.createElement("img");c.className="bubble-icon",c.setAttribute("src",o),t.appendChild(c),e.appendChild(t)},ge=({className:e,target:o,widgetColor:t,bubbleAvatarUrl:c})=>{let l=`${e} woot-elements--${window.$flowify.position}`;if(c)V({target:o,imageUrl:c});else{const n=document.createElement("div");n.className="bubble-icon-container";const u=document.createElementNS("http://www.w3.org/2000/svg","svg");u.setAttribute("viewBox","0 0 240.808 240.808"),u.setAttribute("width","32"),u.setAttribute("height","32");const i=document.createElementNS("http://www.w3.org/2000/svg","path");i.setAttribute("d",pe),i.setAttribute("fill","#ffffff"),u.appendChild(i),n.appendChild(u),o.appendChild(n)}if(window.$flowify.launcherTitle){const n=document.createElement("span");n.id="woot-widget--launcher__text",n.className="woot-widget--bubble__text",n.innerText=window.$flowify.launcherTitle,n.style.background=t,o.insertBefore(n,o.firstChild)}return o.className=l,o},be=e=>{e&&y(C,"woot-hidden"),y(C,"woot--bubble-holder"),C.id="cw-bubble-holder",C.dataset.turboPermanent=!0,j.appendChild(C)},fe=e=>{p.events.onBubbleToggle(e),e?E({eventName:ce}):(E({eventName:we}),A.focus())},_=(e={})=>{const{toggleValue:o}=e,{isOpen:t}=window.$flowify;if(t===o)return;const c=o===void 0?!t:o;window.$flowify.isOpen=c,k(A,"woot--hide"),k(T,"woot--hide"),k(v,"woot--hide"),fe(c)},me=()=>{C.addEventListener("click",_)},ve=()=>{const e=document.querySelector(".woot-widget-holder");y(e,"has-unread-view")},q=()=>{const e=document.querySelector(".woot-widget-holder");S(e,"has-unread-view")},xe=e=>{const o=e.replace("#",""),t=parseInt(o.substr(0,2),16),c=parseInt(o.substr(2,2),16),l=parseInt(o.substr(4,2),16);return(t*299+c*587+l*114)/1e3>225},ye="SET_USER_ERROR";function Ce(e){return e&&e.__esModule&&Object.prototype.hasOwnProperty.call(e,"default")?e.default:e}var K={exports:{}},Y={exports:{}};(function(){var e="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",o={rotl:function(t,c){return t<<c|t>>>32-c},rotr:function(t,c){return t<<32-c|t>>>c},endian:function(t){if(t.constructor==Number)return o.rotl(t,8)&16711935|o.rotl(t,24)&4278255360;for(var c=0;c<t.length;c++)t[c]=o.endian(t[c]);return t},randomBytes:function(t){for(var c=[];t>0;t--)c.push(Math.floor(Math.random()*256));return c},bytesToWords:function(t){for(var c=[],l=0,n=0;l<t.length;l++,n+=8)c[n>>>5]|=t[l]<<24-n%32;return c},wordsToBytes:function(t){for(var c=[],l=0;l<t.length*32;l+=8)c.push(t[l>>>5]>>>24-l%32&255);return c},bytesToHex:function(t){for(var c=[],l=0;l<t.length;l++)c.push((t[l]>>>4).toString(16)),c.push((t[l]&15).toString(16));return c.join("")},hexToBytes:function(t){for(var c=[],l=0;l<t.length;l+=2)c.push(parseInt(t.substr(l,2),16));return c},bytesToBase64:function(t){for(var c=[],l=0;l<t.length;l+=3)for(var n=t[l]<<16|t[l+1]<<8|t[l+2],u=0;u<4;u++)l*8+u*6<=t.length*8?c.push(e.charAt(n>>>6*(3-u)&63)):c.push("=");return c.join("")},base64ToBytes:function(t){t=t.replace(/[^A-Z0-9+\/]/ig,"");for(var c=[],l=0,n=0;l<t.length;n=++l%4)n!=0&&c.push((e.indexOf(t.charAt(l-1))&Math.pow(2,-2*n+8)-1)<<n*2|e.indexOf(t.charAt(l))>>>6-n*2);return c}};Y.exports=o})();var Ee=Y.exports,F={utf8:{stringToBytes:function(e){return F.bin.stringToBytes(unescape(encodeURIComponent(e)))},bytesToString:function(e){return decodeURIComponent(escape(F.bin.bytesToString(e)))}},bin:{stringToBytes:function(e){for(var o=[],t=0;t<e.length;t++)o.push(e.charCodeAt(t)&255);return o},bytesToString:function(e){for(var o=[],t=0;t<e.length;t++)o.push(String.fromCharCode(e[t]));return o.join("")}}},G=F;/*!
 * Determine if an object is a Buffer
 *
 * @author   Feross Aboukhadijeh <https://feross.org>
 * @license  MIT
 */var _e=function(e){return e!=null&&(X(e)||Be(e)||!!e._isBuffer)};function X(e){return!!e.constructor&&typeof e.constructor.isBuffer=="function"&&e.constructor.isBuffer(e)}function Be(e){return typeof e.readFloatLE=="function"&&typeof e.slice=="function"&&X(e.slice(0,0))}(function(){var e=Ee,o=G.utf8,t=_e,c=G.bin,l=function(n,u){n.constructor==String?u&&u.encoding==="binary"?n=c.stringToBytes(n):n=o.stringToBytes(n):t(n)?n=Array.prototype.slice.call(n,0):!Array.isArray(n)&&n.constructor!==Uint8Array&&(n=n.toString());for(var i=e.bytesToWords(n),h=n.length*8,s=1732584193,r=-271733879,d=-1732584194,a=271733878,w=0;w<i.length;w++)i[w]=(i[w]<<8|i[w]>>>24)&16711935|(i[w]<<24|i[w]>>>8)&4278255360;i[h>>>5]|=128<<h%32,i[(h+64>>>9<<4)+14]=h;for(var g=l._ff,b=l._gg,f=l._hh,m=l._ii,w=0;w<i.length;w+=16){var Pe=s,je=r,Ve=d,qe=a;s=g(s,r,d,a,i[w+0],7,-680876936),a=g(a,s,r,d,i[w+1],12,-389564586),d=g(d,a,s,r,i[w+2],17,606105819),r=g(r,d,a,s,i[w+3],22,-1044525330),s=g(s,r,d,a,i[w+4],7,-176418897),a=g(a,s,r,d,i[w+5],12,1200080426),d=g(d,a,s,r,i[w+6],17,-1473231341),r=g(r,d,a,s,i[w+7],22,-45705983),s=g(s,r,d,a,i[w+8],7,1770035416),a=g(a,s,r,d,i[w+9],12,-1958414417),d=g(d,a,s,r,i[w+10],17,-42063),r=g(r,d,a,s,i[w+11],22,-1990404162),s=g(s,r,d,a,i[w+12],7,1804603682),a=g(a,s,r,d,i[w+13],12,-40341101),d=g(d,a,s,r,i[w+14],17,-1502002290),r=g(r,d,a,s,i[w+15],22,1236535329),s=b(s,r,d,a,i[w+1],5,-165796510),a=b(a,s,r,d,i[w+6],9,-1069501632),d=b(d,a,s,r,i[w+11],14,643717713),r=b(r,d,a,s,i[w+0],20,-373897302),s=b(s,r,d,a,i[w+5],5,-701558691),a=b(a,s,r,d,i[w+10],9,38016083),d=b(d,a,s,r,i[w+15],14,-660478335),r=b(r,d,a,s,i[w+4],20,-405537848),s=b(s,r,d,a,i[w+9],5,568446438),a=b(a,s,r,d,i[w+14],9,-1019803690),d=b(d,a,s,r,i[w+3],14,-187363961),r=b(r,d,a,s,i[w+8],20,1163531501),s=b(s,r,d,a,i[w+13],5,-1444681467),a=b(a,s,r,d,i[w+2],9,-51403784),d=b(d,a,s,r,i[w+7],14,1735328473),r=b(r,d,a,s,i[w+12],20,-1926607734),s=f(s,r,d,a,i[w+5],4,-378558),a=f(a,s,r,d,i[w+8],11,-2022574463),d=f(d,a,s,r,i[w+11],16,1839030562),r=f(r,d,a,s,i[w+14],23,-35309556),s=f(s,r,d,a,i[w+1],4,-1530992060),a=f(a,s,r,d,i[w+4],11,1272893353),d=f(d,a,s,r,i[w+7],16,-155497632),r=f(r,d,a,s,i[w+10],23,-1094730640),s=f(s,r,d,a,i[w+13],4,681279174),a=f(a,s,r,d,i[w+0],11,-358537222),d=f(d,a,s,r,i[w+3],16,-722521979),r=f(r,d,a,s,i[w+6],23,76029189),s=f(s,r,d,a,i[w+9],4,-640364487),a=f(a,s,r,d,i[w+12],11,-421815835),d=f(d,a,s,r,i[w+15],16,530742520),r=f(r,d,a,s,i[w+2],23,-995338651),s=m(s,r,d,a,i[w+0],6,-198630844),a=m(a,s,r,d,i[w+7],10,1126891415),d=m(d,a,s,r,i[w+14],15,-1416354905),r=m(r,d,a,s,i[w+5],21,-57434055),s=m(s,r,d,a,i[w+12],6,1700485571),a=m(a,s,r,d,i[w+3],10,-1894986606),d=m(d,a,s,r,i[w+10],15,-1051523),r=m(r,d,a,s,i[w+1],21,-2054922799),s=m(s,r,d,a,i[w+8],6,1873313359),a=m(a,s,r,d,i[w+15],10,-30611744),d=m(d,a,s,r,i[w+6],15,-1560198380),r=m(r,d,a,s,i[w+13],21,1309151649),s=m(s,r,d,a,i[w+4],6,-145523070),a=m(a,s,r,d,i[w+11],10,-1120210379),d=m(d,a,s,r,i[w+2],15,718787259),r=m(r,d,a,s,i[w+9],21,-343485551),s=s+Pe>>>0,r=r+je>>>0,d=d+Ve>>>0,a=a+qe>>>0}return e.endian([s,r,d,a])};l._ff=function(n,u,i,h,s,r,d){var a=n+(u&i|~u&h)+(s>>>0)+d;return(a<<r|a>>>32-r)+u},l._gg=function(n,u,i,h,s,r,d){var a=n+(u&h|i&~h)+(s>>>0)+d;return(a<<r|a>>>32-r)+u},l._hh=function(n,u,i,h,s,r,d){var a=n+(u^i^h)+(s>>>0)+d;return(a<<r|a>>>32-r)+u},l._ii=function(n,u,i,h,s,r,d){var a=n+(i^(u|~h))+(s>>>0)+d;return(a<<r|a>>>32-r)+u},l._blocksize=16,l._digestsize=16,K.exports=function(n,u){if(n==null)throw new Error("Illegal argument "+n);var i=e.wordsToBytes(l(n,u));return u&&u.asBytes?i:u&&u.asString?c.bytesToString(i):e.bytesToHex(i)}})();var Se=K.exports;const Te=Ce(Se),J=["avatar_url","email","name"],$e=[...J,"identifier_hash"],D=()=>{const e="cw_user_",{websiteToken:o}=window.$flowify;return`${e}${o}`},ze=({identifier:e="",user:o})=>`${$e.reduce((c,l)=>`${c}${l}${o[l]||""}`,"")}identifier${e}`,Me=(...e)=>Te(ze(...e)),ke=e=>J.reduce((o,t)=>o||!!e[t],!1),L=(e,o,{expires:t=365,baseDomain:c=void 0}={})=>{const l={expires:t,sameSite:"Lax",domain:c};typeof o=="object"&&(o=JSON.stringify(o)),x.set(e,o,l)},Z=["click","touchstart","keypress","keydown"],Ue=()=>{let e;try{e=new(window.AudioContext||window.webkitAudioContext)}catch{}return e},Ae=async(e="",o)=>{const t=Ue(),c=l=>{window.playAudioAlert=()=>{if(t){const n=t.createBufferSource();n.buffer=l,n.connect(t.destination),n.loop=!1,n.start()}}};if(t){const{type:l="dashboard",alertTone:n="ding"}=o||{},u=`${e}/audio/${l}/${n}.mp3`,i=new Request(u);fetch(i).then(h=>h.arrayBuffer()).then(h=>(t.decodeAudioData(h).then(c),new Promise(s=>s()))).catch(()=>{})}},Fe=({origin:e,conversationCookie:o,websiteToken:t,locale:c})=>{const l=new URL("/widget",e);return l.searchParams.append("cw_conversation",o),l.searchParams.append("website_token",t),l.searchParams.append("locale",c),l.toString()},De=(e,o,t,c)=>{try{const l=Fe({origin:e,websiteToken:o,locale:t,conversationCookie:c});window.open(l,`webwidget_session_${o}`,"resizable=off,width=400,height=600").focus()}catch(l){console.log(l)}};function Q(e){if(e===null||e===!0||e===!1)return NaN;var o=Number(e);return isNaN(o)?o:o<0?Math.ceil(o):Math.floor(o)}function I(e,o){if(o.length<e)throw new TypeError(e+" argument"+(e>1?"s":"")+" required, but only "+o.length+" present")}function Le(e){I(1,arguments);var o=Object.prototype.toString.call(e);return e instanceof Date||typeof e=="object"&&o==="[object Date]"?new Date(e.getTime()):typeof e=="number"||o==="[object Number]"?new Date(e):((typeof e=="string"||o==="[object String]")&&typeof console<"u"&&(console.warn("Starting with v2.0.0-beta.1 date-fns doesn't accept strings as date arguments. Please use `parseISO` to parse strings. See: https://git.io/fjule"),console.warn(new Error().stack)),new Date(NaN))}function Ie(e,o){I(2,arguments);var t=Le(e).getTime(),c=Q(o);return new Date(t+c)}var Oe=36e5;function Re(e,o){I(2,arguments);var t=Q(o);return Ie(e,t*Oe)}const ee=(e,o="")=>L("cw_conversation",e,{baseDomain:o}),Ne=e=>{const o=Re(new Date,1);L("cw_snooze_campaigns_till",Number(o),{expires:o,baseDomain:e})},p={getUrl({baseUrl:e,websiteToken:o}){return`${e}/widget?website_token=${o}`},createFrame:({baseUrl:e,websiteToken:o})=>{if(p.getAppFrame())return;ne();const t=document.createElement("iframe"),c=x.get("cw_conversation");let l=p.getUrl({baseUrl:e,websiteToken:o});c&&(l=`${l}&cw_conversation=${c}`),t.src=l,t.allow="camera;microphone;fullscreen;display-capture;picture-in-picture;clipboard-write;",t.id="chatwoot_live_chat_widget",t.style.visibility="hidden";let n=`woot-widget-holder woot--hide woot-elements--${window.$flowify.position}`;window.$flowify.hideMessageBubble&&(n+=" woot-widget--without-bubble"),W(window.$flowify.widgetStyle)&&(n+=" woot-widget-holder--flat"),y(v,n),v.id="cw-widget-holder",v.dataset.turboPermanent=!0,v.appendChild(t),j.appendChild(v),p.initPostMessageCommunication(),p.initWindowSizeListener(),p.preventDefaultScroll()},getAppFrame:()=>document.getElementById("chatwoot_live_chat_widget"),getBubbleHolder:()=>document.getElementsByClassName("woot--bubble-holder"),sendMessage:(e,o)=>{const t=p.getAppFrame();t&&t.contentWindow.postMessage(`chatwoot-widget:${JSON.stringify({event:e,...o})}`,"*")},initPostMessageCommunication:()=>{window.onmessage=e=>{if(typeof e.data!="string"||e.data.indexOf("chatwoot-widget:")!==0)return;const o=JSON.parse(e.data.replace("chatwoot-widget:",""));typeof p.events[o.event]=="function"&&p.events[o.event](o)}},initWindowSizeListener:()=>{window.addEventListener("resize",()=>p.toggleCloseButton())},preventDefaultScroll:()=>{v.addEventListener("wheel",e=>{const o=e.deltaY,t=v.scrollHeight,c=v.offsetHeight,l=v.scrollTop;(l===0&&o<0||c+l===t&&o>0)&&e.preventDefault()})},setFrameHeightToFitContent:(e,o)=>{const t=p.getAppFrame(),c=o?`${e}px`:"100%";t&&t.setAttribute("style",`height: ${c} !important`)},setupAudioListeners:()=>{const{baseUrl:e=""}=window.$flowify;Ae(e,{type:"widget",alertTone:"ding"}).then(()=>Z.forEach(o=>{document.removeEventListener(o,p.setupAudioListeners,!1)}))},events:{loaded:e=>{ee(e.config.authToken,window.$flowify.baseDomain),window.$flowify.hasLoaded=!0;const o=x.get("cw_snooze_campaigns_till");p.sendMessage("config-set",{locale:window.$flowify.locale,position:window.$flowify.position,hideMessageBubble:window.$flowify.hideMessageBubble,showPopoutButton:window.$flowify.showPopoutButton,widgetStyle:window.$flowify.widgetStyle,darkMode:window.$flowify.darkMode,showUnreadMessagesDialog:window.$flowify.showUnreadMessagesDialog,campaignsSnoozedTill:o,welcomeTitle:window.$flowify.welcomeTitle,welcomeDescription:window.$flowify.welcomeDescription,availableMessage:window.$flowify.availableMessage,unavailableMessage:window.$flowify.unavailableMessage,enableFileUpload:window.$flowify.enableFileUpload,enableEmojiPicker:window.$flowify.enableEmojiPicker,enableEndConversation:window.$flowify.enableEndConversation}),p.onLoad({widgetColor:e.config.channelConfig.widgetColor,bubbleAvatarUrl:e.config.channelConfig.bubbleAvatarUrl,closeBubbleAvatarUrl:e.config.channelConfig.closeBubbleAvatarUrl}),p.toggleCloseButton(),window.$flowify.user&&p.sendMessage("set-user",window.$flowify.user),window.playAudioAlert=()=>{},Z.forEach(t=>{document.addEventListener(t,p.setupAudioListeners,!1)}),window.$flowify.resetTriggered||E({eventName:de})},error:({errorType:e,data:o})=>{E({eventName:ae,data:o}),e===ye&&x.remove(D())},onEvent({eventIdentifier:e,data:o}){E({eventName:e,data:o})},setBubbleLabel(e){he(window.$flowify.launcherTitle||e.label)},setAuthCookie({data:{widgetAuthToken:e}}){ee(e,window.$flowify.baseDomain)},setCampaignReadOn(){Ne(window.$flowify.baseDomain)},postback(e){E({eventName:le,data:e})},toggleBubble:e=>{let o={};e==="open"?o.toggleValue=!0:e==="close"&&(o.toggleValue=!1),_(o)},popoutChatWindow:({baseUrl:e,websiteToken:o,locale:t})=>{const c=x.get("cw_conversation");window.$flowify.toggle("close"),De(e,o,t,c)},closeWindow:()=>{_({toggleValue:!1}),q()},onBubbleToggle:e=>{p.sendMessage("toggle-open",{isOpen:e}),e&&p.pushEvent("webwidget.triggered")},onLocationChange:({referrerURL:e,referrerHost:o})=>{p.sendMessage("change-url",{referrerURL:e,referrerHost:o})},updateIframeHeight:e=>{const{extraHeight:o=0,isFixedHeight:t}=e;p.setFrameHeightToFitContent(o,t)},setUnreadMode:()=>{ve(),_({toggleValue:!0})},resetUnreadMode:()=>q(),handleNotificationDot:e=>{if(window.$flowify.hideMessageBubble)return;const o=document.querySelector(".woot-widget-bubble");e.unreadMessageCount>0&&!o.classList.contains("unread-notification")?y(o,"unread-notification"):e.unreadMessageCount===0&&S(o,"unread-notification")},closeChat:()=>{_({toggleValue:!1})},playAudio:()=>{window.playAudioAlert()}},pushEvent:e=>{p.sendMessage("push-event",{eventName:e})},onLoad:({widgetColor:e,bubbleAvatarUrl:o,closeBubbleAvatarUrl:t})=>{const c=p.getAppFrame();if(c.style.visibility="",c.setAttribute("id","chatwoot_live_chat_widget"),p.getBubbleHolder().length)return;be(window.$flowify.hideMessageBubble),ie();let l="woot-widget-bubble",n=`woot-elements--${window.$flowify.position} woot-widget-bubble woot--close woot--hide`;W(window.$flowify.widgetStyle)&&(l+=" woot-widget-bubble--flat",n+=" woot-widget-bubble--flat"),xe(e)&&(l+=" woot-widget-bubble-color--lighter",n+=" woot-widget-bubble-color--lighter");const u=ge({className:l,target:A,widgetColor:e,bubbleAvatarUrl:o});y(T,n),V({target:T,imageUrl:t}),C.appendChild(u),C.appendChild(T),me()},toggleCloseButton:()=>{let e=!1;window.matchMedia("(max-width: 668px)").matches&&(e=!0),p.sendMessage("toggle-close-button",{isMobile:e})}},He="sdk-set-bubble-visibility",We=({baseUrl:e,websiteToken:o})=>{if(window.$flowify)return;document.addEventListener("turbo:before-render",n=>{n.detail.renderMethod!=="morph"&&M(n.detail.newBody)}),window.Turbolinks&&document.addEventListener("turbolinks:before-render",n=>{M(n.data.newBody)}),document.addEventListener("astro:before-swap",n=>M(n.newDocument.body));const t=window.flowifySettings||{};let c=t.locale,l=t.baseDomain;t.useBrowserLanguage&&(c=window.navigator.language.replace("-","_")),window.$flowify={baseUrl:e,baseDomain:l,hasLoaded:!1,hideMessageBubble:t.hideMessageBubble||!1,isOpen:!1,position:t.position==="left"?"left":"right",websiteToken:o,locale:c,useBrowserLanguage:t.useBrowserLanguage||!1,type:H(t.type),launcherTitle:t.launcherTitle||"",showPopoutButton:t.showPopoutButton||!1,showUnreadMessagesDialog:t.showUnreadMessagesDialog??!0,widgetStyle:se(t.widgetStyle)||"standard",resetTriggered:!1,darkMode:P(t.darkMode),welcomeTitle:t.welcomeTitle||"",welcomeDescription:t.welcomeDescription||"",availableMessage:t.availableMessage||"",unavailableMessage:t.unavailableMessage||"",enableFileUpload:t.enableFileUpload,enableEmojiPicker:t.enableEmojiPicker??!0,enableEndConversation:t.enableEndConversation??!0,toggle(n){p.events.toggleBubble(n)},toggleBubbleVisibility(n){let u=document.querySelector(".woot--bubble-holder"),i=document.querySelector(".woot-widget-holder");n==="hide"?(y(i,"woot-widget--without-bubble"),y(u,"woot-hidden"),window.$flowify.hideMessageBubble=!0):n==="show"&&(S(u,"woot-hidden"),S(i,"woot-widget--without-bubble"),window.$flowify.hideMessageBubble=!1),p.sendMessage(He,{hideMessageBubble:window.$flowify.hideMessageBubble})},popoutChatWindow(){p.events.popoutChatWindow({baseUrl:window.$flowify.baseUrl,websiteToken:window.$flowify.websiteToken,locale:c})},setUser(n,u){if(typeof n!="string"&&typeof n!="number")throw new Error("Identifier should be a string or a number");if(!ke(u))throw new Error("User object should have one of the keys [avatar_url, email, name]");const i=D(),h=x.get(i),s=Me({identifier:n,user:u});s!==h&&(window.$flowify.identifier=n,window.$flowify.user=u,p.sendMessage("set-user",{identifier:n,user:u}),L(i,s,{baseDomain:l}))},setCustomAttributes(n={}){if(!n||!Object.keys(n).length)throw new Error("Custom attributes should have atleast one key");p.sendMessage("set-custom-attributes",{customAttributes:n})},deleteCustomAttribute(n=""){if(n)p.sendMessage("delete-custom-attribute",{customAttribute:n});else throw new Error("Custom attribute is required")},setConversationCustomAttributes(n={}){if(!n||!Object.keys(n).length)throw new Error("Custom attributes should have atleast one key");p.sendMessage("set-conversation-custom-attributes",{customAttributes:n})},deleteConversationCustomAttribute(n=""){if(n)p.sendMessage("delete-conversation-custom-attribute",{customAttribute:n});else throw new Error("Custom attribute is required")},setLabel(n=""){p.sendMessage("set-label",{label:n})},removeLabel(n=""){p.sendMessage("remove-label",{label:n})},setLocale(n="en"){p.sendMessage("set-locale",{locale:n})},setColorScheme(n="light"){p.sendMessage("set-color-scheme",{darkMode:P(n)})},reset(){window.$flowify.isOpen&&p.events.toggleBubble(),x.remove("cw_conversation"),x.remove(D());const n=p.getAppFrame();n.src=p.getUrl({baseUrl:window.$flowify.baseUrl,websiteToken:window.$flowify.websiteToken}),window.$flowify.resetTriggered=!0}},p.createFrame({baseUrl:e,websiteToken:o})};window.flowifySDK={run:We}})();
