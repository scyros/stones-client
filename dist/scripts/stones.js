/*
# Stones _(Client Side)_

Library built on top of AngularJS to work in conjunction with Stones Server to
automate and standarize client-server communications.
*/


(function() {
  'use strict';
  var stones, uniqueId, _STONES_CACHE;

  uniqueId = function(length) {
    var id;
    if (length == null) {
      length = 8;
    }
    id = "";
    while (id.length < length) {
      id += Math.random().toString(36).substr(2);
    }
    return id.substr(0, length);
  };

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

  /*
  Returns the default actions related to CRUD operations with Stones Server
  */


  stones.factory('stResourceActionsBuilder', [
    function() {
      var default_actions;
      default_actions = {
        query: {
          method: 'get',
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
            request: function(_request) {
              console.log(_request);
              return _request;
            },
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
        update: {
          method: 'put',
          withCredentials: true
        }
      };
      return function() {
        return angular.copy(default_actions);
      };
    }
  ]);

}).call(this);

/*
//@ sourceMappingURL=app.js.map
*/
(function() {
  'use strict';
  /*
  Pagination directive.
  It uses Bootstrap pagination CSS classes.
  */

  angular.module('stones').directive('stPagination', [
    '$compile', '$timeout', function($compile, $timeout) {
      return {
        template: '<ul class="pagination"><li ng-class="stGetStepDownClass()"><a href="#" ng-click="stStepDown()">&laquo;</a></li><li ng-repeat="step in stSteps" ng-class="stGetStepClass(step)"><a href="#" ng-click="stGoStep(step)">{{ step }}</a></li><li ng-class="stGetStepUpClass()"><a href="#" ng-click="stStepUp()">&raquo;</a></li></ul>',
        link: function(scope, elm, attrs) {
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
          scope.$watch('stSteps', function() {
            $timeout(function() {
              elm.find('a').bind('click', function(e) {
                e.preventDefault();
                return false;
              });
            }, 500);
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

  /*
  Tooltip directive.
  It uses Bootstrap tooltip.
  */


  angular.module('stones').directive('stTitle', [
    '$compile', function($compile) {
      return {
        restrict: 'A',
        link: function(scope, elm, attrs) {
          var title;
          title = attrs.stTitle;
          elm.attr('title', title);
          return elm.tooltip({
            title: title,
            container: 'body',
            placement: 'auto bottom'
          });
        }
      };
    }
  ]);

  /*
  100% height directive.
  Sets box height to the maximum possible within body bounds.
  */


  angular.module('stones').directive('stHeight100', [
    function() {
      return {
        restrict: 'A',
        link: function(scope, _elm, attrs) {
          var body_height, elm, height, top;
          elm = $(_elm);
          body_height = $('body').height();
          top = elm.offset().top;
          height = body_height - top;
          return elm.height(height);
        }
      };
    }
  ]);

  /*
  No navigation directive.
  Prevents anchor default behavior.
  It prevents from follow links in all anchors inside element where the directive
  has been declarated.
  If that element is an anchor itself, its behavior is modified.
  */


  angular.module('stones').directive('stNoNav', [
    function() {
      return {
        restrict: 'A',
        link: function(scope, _elm, attrs) {
          var elm;
          elm = $(_elm);
          if (elm.prop('tagName').toLowerCase() === 'a') {
            return elm.bind('click', function(e) {
              return e.preventDefault();
            });
          } else {
            return elm.find('a').bind('click', function(e) {
              return e.preventDefault();
            });
          }
        }
      };
    }
  ]);

  /*
  Spy directives.
  Allows DOM movement accordingly with sections positions.
  Inspired in: https://gist.github.com/alxhill/6886760
  */


  angular.module('stones').directive('stSpy', [
    '$window', function($window) {
      return {
        restrict: 'A',
        require: '^stScrollSpy',
        link: function(scope, elm, attrs, stScrollSpy) {
          var speed, _ref;
          speed = (_ref = attrs.stSpeed) != null ? _ref : 1500;
          stScrollSpy.addSpy({
            id: attrs.stSpy,
            "in": function() {
              return elm.addClass('active');
            },
            out: function() {
              return elm.removeClass('active');
            }
          });
          return elm.bind('click', function(e) {
            return $('html, body').animate({
              scrollTop: $('#' + attrs.stSpy).offset().top
            }, speed);
          });
        }
      };
    }
  ]);

  angular.module('stones').directive('stScrollSpy', [
    '$window', function($window) {
      return {
        restrict: 'A',
        controller: [
          '$scope', function(scope) {
            scope.spies = [];
            this.addSpy = function(spyObj) {
              return scope.spies.push(spyObj);
            };
          }
        ],
        link: function(scope, elm, attrs) {
          var spyElems;
          spyElems = [];
          scope.$watch('spies', function(spies) {
            var spy, _i, _len, _results;
            _results = [];
            for (_i = 0, _len = spies.length; _i < _len; _i++) {
              spy = spies[_i];
              if (spyElems[spy.id] == null) {
                _results.push(spyElems[spy.id] = $('#' + spy.id));
              } else {
                _results.push(void 0);
              }
            }
            return _results;
          });
          return $($window).scroll(function() {
            var highlightSpy, pos, spy, _i, _len, _ref;
            highlightSpy = null;
            _ref = scope.spies;
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              spy = _ref[_i];
              spy.out();
              spyElems[spy.id] = spyElems[spy.id].length === 0 ? $('#' + spy.id) : spyElems[spy.id];
              if (spyElems[spy.id].length !== 0) {
                if ((pos = spyElems[spy.id].offset().top) - $window.scrollY <= 0) {
                  spy.pos = pos;
                  if (highlightSpy == null) {
                    highlightSpy = spy;
                  }
                  if (highlightSpy.pos < spy.pos) {
                    highlightSpy = spy;
                  }
                }
              }
            }
            return highlightSpy != null ? highlightSpy["in"]() : void 0;
          });
        }
      };
    }
  ]);

  /*
  File control directive.
  Allow uploads.
  */


  angular.module('stones').directive('stFileUploader', [
    '$window', '$compile', '$http', '$parse', 'growl', function($window, $compile, $http, $parse, growl) {
      return {
        restrict: 'EA',
        scope: true,
        replace: true,
        template: function(elm, attrs) {
          var tpl;
          tpl = '<div class="st-file-uploader"><div class="st-file-display-container hidden"><div class="st-file-remove-overlay"><i class="fa fa-times-circle"></i></div>';
          if (elm[0].tagName === 'IMG') {
            tpl += '<img class="img-responsive img-rounded" />';
            attrs.$attr.stMimeType = 'st-mime-type';
            attrs.$set('stMimeType', 'image.*');
          }
          tpl += '</div><div class="st-file-control-container"><span class="btn btn-primary btn-sm">Selecciona</span><br />- o -<br />Arrastra aquí el archivo</div></div>';
          return tpl;
        },
        link: function(scope, _elm, attrs) {
          var button, elm, fileDragOverHandler, fileSelectHandler, getter, input, input_tpl, isFileAPI, setter;
          isFileAPI = $window.File && $window.FileReader && $window.FileList && $window.Blob;
          if (!isFileAPI) {
            throw new Error('FileAPI not supported');
          }
          getter = $parse(attrs.stFileUploader);
          setter = getter.assign;
          input_tpl = '<input type="file" name="' + attrs.name + '" class="invisible" ' + (attrs.required != null ? ' required' : '') + '>';
          input = $compile(input_tpl)(scope);
          elm = $window.jQuery(_elm);
          elm.find('.st-file-control-container').append(input);
          elm.css('position', 'relative');
          elm.css('min-height', '130px');
          button = elm.find('.btn').add('.st-file-uploader button');
          if (button) {
            button.bind('click', function(e) {
              input.trigger('click');
            });
          }
          elm.find('.st-file-remove-overlay').bind('click', function(e) {
            setter(scope, null);
            elm.find('.st-file-control-container').removeClass('hidden');
            elm.find('.st-file-display-container').addClass('hidden');
            return scope.$apply();
          });
          fileSelectHandler = function(e) {
            var file, reader;
            e.stopPropagation();
            e.preventDefault();
            file = e.dataTransfer != null ? e.dataTransfer.files[0] : e.target.files[0];
            reader = new FileReader();
            reader.onload = function(e) {
              if (attrs.stMimeType === 'image.*') {
                if (!file.type.match(attrs.stMimeType)) {
                  growl.addErrorMessage("File should be an image");
                  throw Error('stFileUploaderError: File should be an image');
                }
                setter(scope, e.target.result);
                elm.find('img').attr('src', e.target.result);
                elm.find('.st-file-display-container').removeClass('hidden');
                elm.find('.st-file-control-container').addClass('hidden');
              }
              scope.$apply();
            };
            reader.readAsDataURL(file);
          };
          fileDragOverHandler = function(e) {
            e.stopPropagation();
            e.preventDefault();
            e.dataTransfer.dropEffect = 'copy';
          };
          elm.find('input[type=file]').bind('change', function(e) {
            return fileSelectHandler(e);
          });
          elm.bind('dragover', function(e) {
            return fileDragOverHandler(e.originalEvent);
          });
          elm.bind('drop', function(e) {
            return fileSelectHandler(e.originalEvent);
          });
          scope.$watch(attrs.stFileUploader, function(newValue, oldValue) {
            var base64_pattern, http_request;
            base64_pattern = /data:\w*\/.+;base64/i;
            if ((newValue == null) || base64_pattern.test(newValue)) {
              if (attrs.stMimeType === 'image.*') {
                elm.find('img').removeAttr('src');
                elm.find('.st-file-display-container').addClass('hidden');
                elm.find('.st-file-control-container').removeClass('hidden');
              }
              return;
            }
            http_request = $http.get('/get_blob/' + newValue, {
              cache: true
            });
            http_request.success(function(data) {
              if (attrs.stMimeType === 'image.*') {
                elm.find('img').attr('src', data);
                elm.find('.st-file-display-container').removeClass('hidden');
                elm.find('.st-file-control-container').addClass('hidden');
              }
            });
            http_request.error(function(data) {
              if (attrs.stMimeType === 'image.*') {
                elm.find('img').removeAttr('src');
                elm.find('.st-file-display-container').addClass('hidden');
                elm.find('.st-file-control-container').removeClass('hidden');
              }
            });
          });
        }
      };
    }
  ]);

  /*
  File control directive.
  Allow chunked uploads.
  */


  angular.module('stones').directive('stChunkedFileUploader', [
    '$window', '$compile', '$http', '$parse', 'growl', function($window, $compile, $http, $parse, growl) {
      return {
        restrict: 'EA',
        require: 'ngModel',
        scope: true,
        replace: true,
        template: '<div class="st-chunked-file-uploader clearfix"><div class="col-md-10"><div class="progress"><div class="progress-bar" role="progressbar" aria-valuenow="{{ stprogress }}" aria-valuemin="{{ stmin }}" aria-valuemax="{{ stmax }}" ng-style="stProgressStyle()" ng-class="stProgressClass()">{{ stprogress }}%</div></div></div><div class="col-md-2"><span class="btn btn-default btn-xs">Subir</span></div><input type="file" class="hidden"></div>',
        link: function(scope, _elm, attrs, ngModel) {
          var allowed_mime_pattern, button, chunk_size, elm, file, fileDragOverHandler, fileSelectHandler, filename, input, max_size, readChunk, reader, set_filename_func, start, stop, upload_url, _ref, _ref1;
          elm = $window.jQuery(_elm);
          upload_url = attrs.stChunkedFileUploader;
          set_filename_func = $parse(attrs.stSetFilename);
          allowed_mime_pattern = new RegExp(attrs.stAllowedMimetype, 'i');
          max_size = attrs.stMaxSize ? parseFloat(attrs.stMaxSize) : null;
          scope.stprogress = 0;
          scope.stmin = (_ref = attrs.stMin) != null ? _ref : 0;
          scope.stmax = (_ref1 = attrs.stMax) != null ? _ref1 : 100;
          if (angular.isFunction(set_filename_func(scope))) {
            set_filename_func = set_filename_func(scope);
          } else {
            set_filename_func = function() {
              return uniqueId(32);
            };
          }
          file = null;
          filename = null;
          reader = new FileReader();
          chunk_size = (256 * 1024 * 4) * 2;
          start = 0;
          stop = start + chunk_size - 1;
          input = elm.find('input[type=file]');
          button = elm.find('.btn');
          if (button) {
            button.bind('click', function(e) {
              input.trigger('click');
            });
          }
          readChunk = function(_start, _stop) {
            var blob;
            if (file.webkitSlice != null) {
              blob = file.webkitSlice(_start, _stop);
            } else if (file.mozSlice != null) {
              blob = file.mozSlice(_start, _stop);
            } else {
              blob = file.slice(_start, _stop);
            }
            return reader.readAsDataURL(blob);
          };
          reader.onloadend = function(e) {
            var config, content, stop_, upload_request;
            if (e.target.readyState === FileReader.DONE) {
              stop_ = stop < file.size ? stop : file.size;
              stop_ -= 1;
              content = e.target.result.split(',')[1];
              config = {
                url: upload_url,
                method: 'POST',
                headers: {
                  'Content-Range': "bytes " + start + "-" + stop_ + "/" + file.size,
                  'Content-Type': "" + file.type
                },
                params: {
                  filename: filename
                },
                data: content
              };
              if (start > 0) {
                config.method = 'PUT';
              }
              upload_request = $http(config);
              upload_request.success(function(data) {
                scope.stprogress = Math.floor((stop_ + 1) / file.size * 100);
                if (stop < file.size) {
                  start = stop;
                  stop = start + chunk_size;
                  readChunk(start, stop);
                } else {
                  ngModel.$setViewValue(data.key);
                  if (scope.save != null) {
                    scope.save();
                  }
                }
              });
            }
          };
          fileSelectHandler = function(e) {
            e.stopPropagation();
            e.preventDefault();
            start = 0;
            stop = start + chunk_size - 1;
            file = e.dataTransfer != null ? e.dataTransfer.files[0] : e.target.files[0];
            if (!allowed_mime_pattern.test(file.type)) {
              growl.addErrorMessage("StFileUploaderError: " + file.type + " mimetype not allowed.");
              throw new Error("StFileUploaderError: " + file.type + " mimetype not allowed.");
            } else if (max_size && file.size > max_size) {
              growl.addErrorMessage("StFileUploaderError: " + file.name + " is bigger than permitted.");
              throw new Error("StFileUploaderError: " + file.name + " is bigger than permitted.");
            }
            filename = set_filename_func();
            readChunk(start, stop);
          };
          fileDragOverHandler = function(e) {
            e.stopPropagation();
            e.preventDefault();
            e.dataTransfer.dropEffect = 'copy';
          };
          elm.find('input[type=file]').bind('change', function(e) {
            return fileSelectHandler(e);
          });
          elm.bind('dragover', function(e) {
            return fileDragOverHandler(e.originalEvent);
          });
          elm.bind('drop', function(e) {
            return fileSelectHandler(e.originalEvent);
          });
          scope.stProgressStyle = function() {
            return {
              width: "" + scope.stprogress + "%"
            };
          };
          scope.stProgressClass = function() {
            if (scope.stprogress < 100) {
              return 'progress-bar-warning';
            } else {
              return 'progress-bar-success';
            }
          };
          return scope.$watch(attrs.ngModel, function(newValue, oldValue) {
            if (((newValue != null ? newValue.length : void 0) != null) && newValue.length > 0) {
              return scope.stprogress = 100;
            } else {
              return scope.stprogress = 0;
            }
          });
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
  angular.module('stones').filter('stTriState', [
    '$sce', function($sce) {
      return function(input) {
        var out;
        out = '';
        if (input === true) {
          out += '<i class="fa fa-check-circle" style="color:green;"></i> ';
        } else if (input === false) {
          out += '<i class="fa fa-times-circle" style="color:red;"></i> ';
        } else {
          out += '<i class="fa fa-question-circle" style="color:yellow;"></i> ';
        }
        return $sce.trustAsHtml(out);
      };
    }
  ]);

}).call(this);

/*
//@ sourceMappingURL=filters.js.map
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

    $get = function($resource, actions_builder) {
      /*
      User Service constructor.
      Requires AngularJS Resource Module.
      */

      var actions;
      actions = {
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
      };
      angular.extend(actions, actions_builder());
      return $resource(apiUrlPrefix + '/users/:key', {
        key: '@__key__'
      }, actions);
    };

    function User() {
      return {
        $get: ['$resource', 'stResourceActionsBuilder', $get],
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