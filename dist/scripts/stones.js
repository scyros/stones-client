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
  var uniqueId;

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
  Google Maps geocoding directive
  Allow to pick a location from Google Maps geocoding options fetched.
  */


  angular.module('stones').directive('stGeocoding', [
    '$http', function($http) {
      return {
        restrict: 'EA',
        require: ['stGeocoding', 'stTypeahead'],
        controller: [
          function() {
            var _this = this;
            this.url = null;
            this.getGeocoding = function(searchTerm, components, region) {
              var http_opts;
              if (_this.url == null) {
                throw 'stGeocodingError: URL not defined.';
              }
              http_opts = {
                url: _this.url,
                method: 'GET',
                params: {
                  q: searchTerm,
                  c: components,
                  r: region
                }
              };
              return $http(http_opts);
            };
          }
        ],
        link: function(scope, elm, attrs, ctrls, transcludeFn) {
          var stGeocodingCtrl, stTypeaheadCtrl;
          stGeocodingCtrl = ctrls[0];
          stTypeaheadCtrl = ctrls[1];
          if (attrs.stGeocoding == null) {
            throw 'stGeocodingError: URL not defined in DOM attr st-geocoding';
          }
          stGeocodingCtrl.url = attrs.stGeocoding;
          stTypeaheadCtrl.ngModel.$viewChangeListeners.push(function() {
            var ngModel, req;
            ngModel = stTypeaheadCtrl.ngModel;
            if (ngModel.$viewValue.length < 3) {
              return;
            }
            req = stGeocodingCtrl.getGeocoding(ngModel.$viewValue, attrs.stGeocodingComponents);
            req.success(function(data) {
              return stTypeaheadCtrl.setSource(data);
            });
          });
        }
      };
    }
  ]);

  /*
  Typeahead directive
  Allow to fetch and pick data based on typed characters.
  */


  angular.module('stones').directive('stTypeahead', [
    '$parse', '$compile', function($parse, $compile) {
      return {
        scope: true,
        restrict: 'EA',
        require: ['stTypeahead', '^?ngModel'],
        controller: [
          '$scope', '$element', '$attrs', '$transclude', function(scope, elm, attrs, transcludeFn) {
            var tpl,
              _this = this;
            this.source = [];
            this.ngModel = null;
            this.dropdown = null;
            this.currentItem = null;
            this.selected = false;
            this.focused = false;
            this.mousedOver = false;
            this.allowNew = false;
            this.index = scope.$index;
            this.typedCounter = 0;
            this.sortFn = function(a, b) {
              if (a.label > b.label) {
                return 1;
              } else if (b.label > a.label) {
                return -1;
              } else {
                return 0;
              }
            };
            this.selectFn = function(value, index) {};
            this.setSource = function(source) {
              var getLabel, getValue, item, key, value, _i, _len;
              getLabel = function(item) {
                if (attrs.stTypeaheadLabel != null) {
                  return item[attrs.stTypeaheadLabel];
                } else if (item.label != null) {
                  return item.label;
                }
                return item;
              };
              getValue = function(item) {
                if (attrs.stTypeaheadValue != null) {
                  return item[attrs.stTypeaheadValue];
                } else if (item.value != null) {
                  return item.value;
                }
                return item;
              };
              _this.source = [];
              if (angular.isArray(source)) {
                for (_i = 0, _len = source.length; _i < _len; _i++) {
                  item = source[_i];
                  _this.source.push({
                    label: getLabel(item),
                    value: getValue(item)
                  });
                }
              } else if (angular.isObject(source)) {
                for (key in source) {
                  value = source[key];
                  _this.source.push({
                    label: key,
                    value: getValue(value)
                  });
                }
              }
              _this.matchItems();
            };
            this.matchItems = function(value) {
              var item, re;
              if (_this.typedCounter === 0) {
                return;
              }
              if ((value == null) || value === '') {
                scope.stMatchedItems = _this.source;
              } else {
                re = new RegExp(value, 'i');
                scope.stMatchedItems = (function() {
                  var _i, _len, _ref, _results;
                  _ref = this.source;
                  _results = [];
                  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                    item = _ref[_i];
                    if (re.test(item.label)) {
                      _results.push(item);
                    }
                  }
                  return _results;
                }).call(_this);
                _this.currentItem = (function() {
                  var _i, _len, _ref, _results;
                  _ref = scope.stMatchedItems;
                  _results = [];
                  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
                    item = _ref[_i];
                    if (item.label === value) {
                      _results.push(item);
                    }
                  }
                  return _results;
                })();
              }
              scope.stMatchedItems.sort(_this.sortFn);
              _this.show();
            };
            this.selectItem = function(item_) {
              var item;
              item = item_ != null ? item_ : _this.currentItem;
              if (item != null) {
                _this.currentItem = item;
                _this.ngModel.$setViewValue(item.label);
                elm.val(item.label);
                _this.selectFn(item.value, _this.index);
              } else {
                if (!_this.allowNew) {
                  _this.currentItem = null;
                  _this.ngModel.$setViewValue('');
                  elm.val('');
                  _this.selectFn('', _this.index);
                }
              }
              _this.hide();
              _this.typedCounter = 0;
            };
            this.setItemClass = function(item) {
              if (item === _this.currentItem) {
                return 'active';
              }
            };
            this.prev = function() {
              var index;
              index = scope.stMatchedItems.indexOf(_this.currentItem);
              if (index === (scope.stMatchedItems.length - 1)) {
                index -= 1;
              }
              _this.currentItem = scope.stMatchedItems[index + 1];
            };
            this.next = function() {
              var index;
              index = scope.stMatchedItems.indexOf(_this.currentItem);
              if (index === 0) {
                index += 1;
              }
              _this.currentItem = scope.stMatchedItems[index - 1];
            };
            this.hide = function() {
              _this.dropdown.hide();
            };
            this.show = function() {
              var offset;
              if (scope.stMatchedItems.length) {
                offset = elm.offset();
                offset.top += elm[0].offsetHeight + 2;
                _this.dropdown.css('top', offset.top);
                _this.dropdown.css('left', offset.left);
                _this.dropdown.show();
              } else {
                _this.hide();
              }
            };
            this.keydownFn = function(e) {
              switch (e.keyCode) {
                case 9:
                  _this.selectItem();
                  break;
                case 13:
                  e.preventDefault();
                  _this.selectItem();
                  break;
                case 38:
                  _this.next();
                  break;
                case 40:
                  _this.prev();
                  break;
                case 27:
                  _this.hide();
                  break;
                default:
                  _this.typedCounter++;
              }
              scope.$apply();
            };
            this.focusFn = function(e) {
              var empty;
              empty = e.currentTarget.value === '';
              if (empty) {
                _this.typedCounter++;
              }
              _this.focused = true;
              _this.matchItems(e.currentTarget.value);
              scope.$apply();
            };
            this.blurFn = function(e) {
              _this.focused = false;
              if (!_this.mousedOver) {
                _this.hide();
              }
              scope.$apply();
            };
            this.mouseenterFn = function(e) {
              _this.mousedOver = true;
              _this.dropdown.find('li').removeClass('active');
              scope.$apply();
            };
            this.mouseleaveFn = function(e) {
              var index;
              _this.mousedOver = false;
              index = scope.stMatchedItems.indexOf(_this.currentItem);
              if (index !== -1) {
                _this.dropdown.find('li').eq(index).addClass('active');
              }
              scope.$apply();
            };
            scope.stSelectItem = this.selectItem;
            scope.stSetItemClass = this.setItemClass;
            if ($parse(attrs.stTypeaheadSelectFn)(scope) != null) {
              this.selectFn = $parse(attrs.stTypeaheadSelectFn)(scope);
            }
            if ($parse(attrs.stTypeadeadSortFn)(scope) != null) {
              this.sortFn = $parse(attrs.stTypeaheadSortFn)(scope);
            }
            scope.$watch(attrs.stTypeahead, function(value, old) {
              if ((value != null) && value !== old) {
                this.setSource(value);
              }
            });
            tpl = '\
<ul class="typeahead dropdown-menu">\
  <li ng-repeat="stItem in stMatchedItems" ng-click="stSelectItem(stItem)" ng-class="stSetItemClass(stItem)">\
    <a href="">{{ stItem.label }}</a>\
  </li>\
</ul>';
            this.dropdown = $compile(tpl)(scope);
            angular.element('body').append(this.dropdown);
            this.dropdown.bind('mouseenter', this.mouseenterFn);
            this.dropdown.bind('mouseleave', this.mouseleaveFn);
            scope.$on('$destroy', function(e) {
              _this.dropdown.remove();
            });
            elm.bind('keydown', this.keydownFn);
            elm.bind('focus', this.focusFn);
            elm.bind('blur', this.blurFn);
          }
        ],
        link: function(scope, elm, attrs, ctrls, transcludeFn) {
          var ngModel, stTypeaheadCtrl;
          stTypeaheadCtrl = ctrls[0];
          ngModel = ctrls[1];
          if ((ngModel == null) || (stTypeaheadCtrl == null)) {
            return;
          }
          stTypeaheadCtrl.ngModel = ngModel;
          ngModel.$viewChangeListeners.push(function() {
            stTypeaheadCtrl.matchItems(ngModel.$viewValue);
          });
        }
      };
    }
  ]);

  /*
  Google Maps directive
  Load a map inside element with custom properties.
  */


  angular.module('stones').directive('stGoogleMaps', [
    '$window', '$parse', function($window, $parse) {
      return {
        restrict: 'EA',
        link: function(scope, elm, attrs, ctrls, transcludeFn) {
          var google, mapOpts;
          google = $window.google;
          if (google == null) {
            throw 'stGoogleMapsError: Google Maps not loaded.';
          }
          mapOpts = $parse(attrs.stGoogleMaps)(scope);
          if (mapOpts == null) {
            throw 'stGoogleMapsError: no map options found.';
          }
          return scope.stMap = new google.maps.Map(elm[0], mapOpts);
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