###
# Stones _(Client Side)_

Library built on top of AngularJS to work in conjunction with Stones Server to
automate and standarize client-server communications.
###
'use strict'

# Angular cache to requests.
_STONES_CACHE = null;


stones = angular.module('stones', [
  'ngCookies',
  'ngSanitize',
  'ngRoute',
  'ngResource',
  'ngAnimate',
  'angular-growl'
])

stones.config [
  '$locationProvider',
  'growlProvider',
  '$httpProvider',
  ($locationProvider, growlProvider, $httpProvider) ->
    ###
    Stones dependencies configuration.
    ###

    # We want to use hashPrefix to allow friendly ajax SEO.
    $locationProvider.hashPrefix '!';

    # growl Config
    growlProvider.onlyUniqueMessages false;
    growlProvider.globalTimeToLive 5000;
    growlProvider.globalEnableHtml true;
    growlProvider.messagesKey('msgs');
    growlProvider.messageTextKey('msg');
    growlProvider.messageSeverityKey('level');
    $httpProvider.responseInterceptors
      .push(growlProvider.serverMessagesInterceptor);
]

stones.run [
  '$rootScope',
  '$cacheFactory',
  '$window',
  ($rootScope, $cacheFactory, $window) ->
    ###
    Stones inner variables initialization.
    ###
    _STONES_CACHE = $cacheFactory(_STONES_CACHE, 500);
]
