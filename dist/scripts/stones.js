/*
# Stones _(Client Side)_

Library built on top of AngularJS to work in conjunction with Stones Server to
automate and standarize client-server communications.
*/


(function() {
  'use strict';
  var stones, _STONES_CACHE;

  _STONES_CACHE = null;

  stones = angular.module('stones', ['ngCookies', 'ngSanitize', 'ngRoute', 'ngResource', 'ngAnimate', 'angular-growl']);

  stones.config([
    '$locationProvider', 'growlProvider', '$httpProvider', function($locationProvider, growlProvider, $httpProvider) {
      /*
      Stones dependencies configuration.
      */

      $locationProvider.hashPrefix('!');
      growlProvider.onlyUniqueMessages(false);
      growlProvider.globalTimeToLive(5000);
      growlProvider.globalEnableHtml(true);
      growlProvider.messagesKey('msgs');
      growlProvider.messageTextKey('msg');
      growlProvider.messageSeverityKey('level');
      return $httpProvider.responseInterceptors.push(growlProvider.serverMessagesInterceptor);
    }
  ]);

  stones.run([
    '$rootScope', '$cacheFactory', '$window', function($rootScope, $cacheFactory, $window) {
      /*
      Stones inner variables initialization.
      */

      _STONES_CACHE = $cacheFactory(_STONES_CACHE, 500);
      return $rootScope.logged_user = $window.logged_user;
    }
  ]);

}).call(this);

/*
//@ sourceMappingURL=stones.js.map
*/
(function() {
  'use strict';
  var User;

  User = (function() {
    /*
    Represents a user of the application.
    This model is so important to authentication system.
    */

    var $get, apiUrlPrefix, setApiUrlPrefix;

    apiUrlPrefix = '/auth';

    setApiUrlPrefix = function(urlPrefix) {
      return apiUrlPrefix = urlPrefix;
    };

    $get = function($resource) {
      /*
      User Service constructor.
      Requires AngularJS Resource Module.
      */

      return $resource(apiUrlPrefix + '/users/:key', {
        key: '@__key__'
      }, {
        query: {
          method: 'get',
          url: apiUrlPrefix + '/users/:key',
          withCredentials: true,
          isArray: true,
          transformResponse: function(_data, headers) {
            var ret;
            if (typeof _data === 'string') {
              ret = JSON.parse(_data);
            } else if (typeof _data === 'object') {
              ret = _data;
            }
            if ('entities' in _data) {
              ret = _data.entities;
              ret.current_page = _data.current_page;
              ret.page_size = _data.page_size;
              ret.total_pages = _data.total_pages;
            }
            return ret;
          }
        },
        resetPassword: {
          method: 'post',
          url: apiUrlPrefix + '/users/:key/password_reset',
          withCredentials: true
        },
        oauth2login: {
          method: 'post',
          url: apiUrlPrefix + '/:provider/login',
          withCredentials: true,
          interceptor: {
            response: function(_response) {
              return _response.data;
            }
          }
        }
      });
    };

    function User() {
      return {
        $get: ['$resource', $get],
        setApiUrlPrefix: setApiUrlPrefix
      };
    }

    return User;

  })();

  angular.module('stones').provider('stonesUser', User).controller('stones.UsersListCtrl', [
    '$scope', '$routeParams', 'stonesUser', function(scope, $routeParams, User) {
      scope.users = [];
      User.query($routeParams, function(users) {
        scope.users = users;
      });
    }
  ]);

}).call(this);

/*
//@ sourceMappingURL=users.js.map
*/