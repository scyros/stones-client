(function(){"use strict";var a,b;b=null,a=angular.module("stones",["ngCookies","ngSanitize","ngRoute","ngResource","ngAnimate","angular-growl"]),a.config(["$locationProvider","growlProvider","$httpProvider",function(a,b,c){return a.hashPrefix("!"),b.onlyUniqueMessages(!1),b.globalTimeToLive(5e3),b.globalEnableHtml(!0),b.messagesKey("msgs"),b.messageTextKey("msg"),b.messageSeverityKey("level"),c.responseInterceptors.push(b.serverMessagesInterceptor)}]),a.run(["$rootScope","$cacheFactory","$window",function(a,c){return b=c(b,500)}])}).call(this),function(){"use strict";var a;a=function(){function a(){return{$get:["$resource",b],setApiUrlPrefix:d}}var b,c,d;return c="/auth",d=function(a){return c=a},b=function(a){return a(c+"/users/:key",{key:"@__key__"},{resetPassword:{method:"post",url:c+"/users/:key/password_reset",withCredentials:!0},oauth2login:{method:"post",url:c+"/:provider/login",withCredentials:!0,interceptor:{response:function(a){return a.data}}}})},a}(),angular.module("stones").provider("stonesUser",a).controller("stones.UsersListCtrl",["$scope","$routeParams","stonesUser",function(a,b,c){a.users=[],c.query(b,function(b){a.users=b})}])}.call(this);