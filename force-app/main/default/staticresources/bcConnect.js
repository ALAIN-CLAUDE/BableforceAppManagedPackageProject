(function(){function r(e,n,t){function o(i,f){if(!n[i]){if(!e[i]){var c="function"==typeof require&&require;if(!f&&c)return c(i,!0);if(u)return u(i,!0);var a=new Error("Cannot find module '"+i+"'");throw a.code="MODULE_NOT_FOUND",a}var p=n[i]={exports:{}};e[i][0].call(p.exports,function(r){var n=e[i][1][r];return o(n||r)},p,p.exports,r,e,n,t)}return n[i].exports}for(var u="function"==typeof require&&require,i=0;i<t.length;i++)o(t[i]);return o}return r})()({1:[function(require,module,exports){
"use strict";Object.defineProperty(exports,"__esModule",{value:!0}),exports.BabelconnectConnect=BabelconnectConnect;var ___bcci=0;function BabelconnectConnect(){function a(a){var b={},c=a.window||a.win||a.iframe;if(!c)throw new Error("no iframe window to connect to!");b.iframeWindow=c;b.on=function(a,b){c.parent.addEventListener("babelconnect.".concat(a),function(a){b(a.detail)})};var d=function(a,b,d){var e={type:"connect",module:a,name:b,args:d||void 0,time:Date.now()};console.debug("emit event to babelconnect",e),c.postMessage(e,"*")};return b.log={debug:function debug(){d("app","log",{level:"debug",arguments:arguments})},info:function info(){d("app","log",{level:"info",arguments:arguments})},error:function error(){d("app","log",{level:"error",arguments:arguments})},warn:function warn(){d("app","log",{level:"warn",arguments:arguments})}},b.dial=function(a){b.setTab(0),d("calls","dial",a)},b.setTab=function(a){d("app","setTab",{tab:a})},b.init=function(a){d("app","initParentFrame",a)},function init(){c.parent.addEventListener("message",function(a){if((function isDevDomain(a){return /http:\/\/(localhost|127\.0\.0\.1):\d+/.test(a)}(a.origin)||function isBabelforceDomain(a){return /^https:\/\/apps(|\..+)\.babelforce.com$/.test(a)}(a.origin))&&"event"in a.data){var b=a.data.event,d=a.data.data||void 0;if(b.startsWith("babelconnect.")){var e=b.replace(/^babelconnect\./,"");console.debug("received event from iframe",e,d);var f=new CustomEvent(b,{bubbles:!0,detail:d});return void c.parent.dispatchEvent(f)}}},!1)}(),b}var b={};return b.connect=function(b){var c=b.contentWindow;return a({window:c})},b.embed=function(a,c){c=c||{},c.id=c.id||"bc-iframe",c.name=c.name||"bc-embedded-babelconnect",c.url=c.url||"https://apps.babelforce.com/babelconnect/#/";var d=document.createElement("iframe");return d.setAttribute("id",c.id),d.setAttribute("name",c.name),d.setAttribute("src",c.url),d.setAttribute("scrolling","no"),d.setAttribute("width","100%"),d.setAttribute("height","100%"),d.setAttribute("style","width: 100%; height: 100%; border: none"),d.setAttribute("allow","autoplay; encrypted-media; microphone"),document.getElementById(a).appendChild(d),b.connect(d)},b}window.BabelconnectConnect=BabelconnectConnect;

},{}]},{},[1]);
