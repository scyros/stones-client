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
//@ sourceMappingURL=app.js.map
*/
(function() {
  'use strict';
  angular.module('stones').directive('stPagination', [
    '$compile', function($compile) {
      return {
        template: '<ul class="pagination"><li ng-class="stGetStepDownClass()"><a href="#" ng-click="stStepDown()">&laquo;</a></li><li ng-repeat="step in stSteps" ng-class="stGetStepClass(step)"><a href="#" ng-click="stGoStep(step)">{{ step }}</a></li><li ng-class="stGetStepUpClass()"><a href="#" ng-click="stStepUp()">&raquo;</a></li></ul>',
        link: function(scope, elm, attrs) {
          elm.find('a').bind('click', function(e) {
            e.preventDefault();
            return false;
          });
          scope.stSteps = [];
          scope.$watch('total_pages', function() {
            var n;
            return scope.stSteps = (function() {
              var _i, _ref, _results;
              _results = [];
              for (n = _i = 1, _ref = scope.total_pages; 1 <= _ref ? _i <= _ref : _i >= _ref; n = 1 <= _ref ? ++_i : --_i) {
                _results.push(n);
              }
              return _results;
            })();
          });
          scope.stGetStepDownClass = function() {
            /*
            Sets previous button class
            */

            var cls;
            cls = [];
            if (scope.current_page >= 1) {
              cls.push('disabled');
            }
            return cls;
          };
          scope.stGetStepUpClass = function() {
            /*
            Sets next button class
            */

            var cls;
            cls = [];
            if (scope.current_page <= scope.total_pages) {
              cls.push('disabled');
            }
            return cls;
          };
          scope.stGetStepClass = function(step) {
            /*
            Sets disabled and active classes according to current step
            */

            var cls;
            cls = [];
            if (step === scope.current_page) {
              cls.push('active');
            }
            return cls;
          };
          scope.stStepDown = function() {
            /*
            Go one step down
            */

            if (scope.current_page > 1) {
              return scope.current_page--;
            }
          };
          scope.stStepUp = function() {
            /*
            Go one step up
            */

            if (scope.current_page < scope.total_pages) {
              return scope.current_page++;
            }
          };
          return scope.stGoStep = function(step) {
            /*
            Go to one specific step
            */

            if (step > 1 && step < scope.total_pages) {
              return scope.current_page = step;
            }
          };
        }
      };
    }
  ]);

}).call(this);

/*
//@ sourceMappingURL=directives.js.map
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
            var data, ret;
            if (typeof _data === 'string') {
              data = JSON.parse(_data);
            } else if (typeof _data === 'object') {
              data = _data;
            }
            ret = data;
            if ('entities' in data) {
              ret = data.entities;
              ret.current_page = data.current_page;
              ret.page_size = data.page_size;
              ret.total_pages = data.total_pages;
            }
            return ret;
          },
          interceptor: {
            response: function(_response) {
              var ret;
              ret = _response.resource;
              if (_response.data.current_page != null) {
                ret.current_page = _response.data.current_page;
              }
              if (_response.data.page_size != null) {
                ret.page_size = _response.data.page_size;
              }
              if (_response.data.total_pages != null) {
                ret.total_pages = _response.data.total_pages;
              }
              return ret;
            }
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