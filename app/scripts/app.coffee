###
# Stones _(Client Side)_

Library built on top of AngularJS to work in conjunction with Stones Server to
automate and standarize client-server communications.
###
'use strict'

# Angular cache to requests.
_STONES_CACHE = null;


transformDates = (obj) ->
  ###
  Transform dates into string with the right format to be accepted by the server
  ###
  for key, value of obj
    if angular.isObject value
      if value.isLeapYear?  # moment object
        obj[key] = value.format('YYYY-MM-DDTHH:mm:ss') + 'Z'
      else if value.getDate?  # native date object
        obj[key] = moment(value).format('YYYY-MM-DDTHH:mm:ss') + 'Z'
      else
        transformDates value
  return


cleanUp = (obj) ->
  ###
  Clean object deleting empty attributes
  ###
  for key, value of obj
    if angular.isObject value
      keys = (_key for own _key, _value of value)
      if keys.length is 0
        delete obj[key]
      else
        cleanUp value
    else
      if not value?
        delete obj[key]
  return

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

    # Set logged user if any
    $rootScope.logged_user = $window.logged_user
]

###
Returns the default actions related to CRUD operations with Stones Server
###
stones.factory 'stResourceActionsBuilder', [
  () ->
    default_actions =
      query:
        method: 'get'
        withCredentials: true,
        isArray: true
        transformResponse: (_data, headers) ->
          if angular.isString _data
            data = JSON.parse _data
          else if angular.isObject _data
            data = _data

          ret = data
          if ('entities' of data)
            ret = data.entities
            ret.current_page = data.current_page
            ret.page_size = data.page_size
            ret.total_pages = data.total_pages
          ret
        interceptor:
          response: (_response) ->
            ret = _response.resource
            if _response.data.current_page?
              ret.current_page = _response.data.current_page
            if _response.data.page_size?
              ret.page_size = _response.data.page_size
            if _response.data.total_pages?
              ret.total_pages = _response.data.total_pages
            ret
      update:
        method: 'put'
        withCredentials: true
        transformRequest: (data) ->
          transformDates data
          cleanUp data  # fist time to delete inner empties
          cleanUp data  # second time to delete emptied objects
          angular.toJson data

    return () ->
      angular.copy default_actions
]
