'use strict'

# Generates UUIDs
uniqueId = (length=8) ->
  id = ""
  id += Math.random().toString(36).substr(2) while id.length < length
  id.substr 0, length


###
Pagination directive.
It uses Bootstrap pagination CSS classes.
###
angular.module('stones')
  .directive 'stPagination', [
    '$compile',
    '$timeout',
    ($compile, $timeout) ->
      template: '<ul class="pagination"><li ng-class="stGetStepDownClass()"><a href="#" ng-click="stStepDown()">&laquo;</a></li><li ng-repeat="step in stSteps" ng-class="stGetStepClass(step)"><a href="#" ng-click="stGoStep(step)">{{ step }}</a></li><li ng-class="stGetStepUpClass()"><a href="#" ng-click="stStepUp()">&raquo;</a></li></ul>'
      link: (scope, elm, attrs) ->
        scope.stSteps = []

        scope.$watch 'total_pages', () ->
          scope.stSteps = (n for n in [1..scope.total_pages])
        scope.$watch 'stSteps', () ->
          $timeout () ->
            elm.find('a')
              .bind 'click', (e) ->
                e.preventDefault()
                false
              return
          , 500
          return

        scope.stGetStepDownClass = () ->
          ###
          Sets previous button class
          ###
          cls = []
          if scope.current_page >= 1 then cls.push 'disabled'
          return cls

        scope.stGetStepUpClass = () ->
          ###
          Sets next button class
          ###
          cls = []
          if scope.current_page <= scope.total_pages then cls.push 'disabled'
          return cls

        scope.stGetStepClass = (step) ->
          ###
          Sets disabled and active classes according to current step
          ###
          cls = []
          if step is scope.current_page
            cls.push 'active'
          return cls

        scope.stStepDown = () ->
          ###
          Go one step down
          ###
          if scope.current_page > 1 then scope.current_page--

        scope.stStepUp = () ->
          ###
          Go one step up
          ###
          if scope.current_page < scope.total_pages then scope.current_page++

        scope.stGoStep = (step) ->
          ###
          Go to one specific step
          ###
          if step > 1 and step < scope.total_pages
            scope.current_page = step
    ]


###
Tooltip directive.
It uses Bootstrap tooltip.
###
angular.module('stones')
  .directive 'stTitle', [
    '$compile',
    ($compile) ->
      restrict: 'A'
      link: (scope, elm, attrs) ->
        title = attrs.stTitle
        elm.attr 'title', title
        elm.tooltip
          title: title
          container: 'body'
          placement: 'auto bottom'
  ]


###
No navigation directive.
Prevents anchor default behavior.
It prevents from follow links in all anchors inside element where the directive
has been declarated.
If that element is an anchor itself, its behavior is modified.
###
angular.module('stones')
  .directive 'stNoNav', [
    () ->
      restrict: 'A'
      link: (scope, _elm, attrs) ->
        elm = $(_elm)
        if elm.prop('tagName').toLowerCase() is 'a'
          elm.bind 'click', (e) ->
            e.preventDefault()
        else
          elm.find('a').bind 'click', (e) ->
            e.preventDefault()
  ]


###
Spy directives.
Allows DOM movement accordingly with sections positions.
Inspired in: https://gist.github.com/alxhill/6886760
###
angular.module('stones')
  .directive 'stSpy', [
    '$window',
    ($window) ->
      restrict: 'A'
      require: '^stScrollSpy'
      link: (scope, elm, attrs, stScrollSpy) ->
        speed = attrs.stSpeed ? 1500
        stScrollSpy.addSpy
          id: attrs.stSpy
          in: -> elm.addClass 'active'
          out: -> elm.removeClass 'active'

        elm.bind 'click', (e) ->
          $('html, body').animate
            scrollTop: $('#' + attrs.stSpy).offset().top
          , speed
  ]

angular.module('stones')
  .directive 'stScrollSpy', [
    '$window',
    ($window) ->
      restrict: 'A'
      controller: [
        '$scope',
        (scope) ->
          scope.spies = []
          @addSpy = (spyObj) -> scope.spies.push spyObj
          return
      ]
      link: (scope, elm, attrs) ->
        spyElems = []

        scope.$watch 'spies', (spies) ->
          for spy in spies
            unless spyElems[spy.id]?
              spyElems[spy.id] = $('#' + spy.id)

        $($window).scroll ->
          highlightSpy = null
          for spy in scope.spies
            spy.out()

            # the elem might not have been available when it was originally cached,
            # so we check again to get another element in case this one doesn't exist.
            spyElems[spy.id] =
              if spyElems[spy.id].length is 0
                $('#' + spy.id)
              else
                spyElems[spy.id]

            # the element could still not exist, so we check first to avoid errors
            if spyElems[spy.id].length isnt 0
              if (pos = spyElems[spy.id].offset().top) - $window.scrollY <= 0
                spy.pos = pos
                highlightSpy ?= spy
                if highlightSpy.pos < spy.pos
                  highlightSpy = spy

          highlightSpy?.in()
  ]


###
Google Maps geocoding directive
Allow to pick a location from Google Maps geocoding options fetched.
###
angular.module('stones').
  directive 'stGeocoding', [
    '$http'
    ($http) ->
      restrict: 'EA'
      require: ['stGeocoding', 'stTypeahead']
      controller: [
        () ->
          @url = null
          @getGeocoding = (searchTerm, components, region) =>
            if not @url?
              throw 'stGeocodingError: URL not defined.'

            http_opts =
              url: @url
              method: 'GET'
              params:
                q: searchTerm
                c: components
                r: region

            return $http http_opts

          return
      ]
      link: (scope, elm, attrs, ctrls, transcludeFn) ->
        stGeocodingCtrl = ctrls[0]
        stTypeaheadCtrl = ctrls[1]

        if not attrs.stGeocoding?
          throw 'stGeocodingError: URL not defined in DOM attr st-geocoding'

        stGeocodingCtrl.url = attrs.stGeocoding

        # listen for changes
        stTypeaheadCtrl.ngModel.$viewChangeListeners.push () ->
          ngModel = stTypeaheadCtrl.ngModel
          if ngModel.$viewValue.length < 3 then return

          req = stGeocodingCtrl.getGeocoding ngModel.$viewValue, attrs.stGeocodingComponents
          req.success (data) ->
            stTypeaheadCtrl.setSource data
          return

        return
  ]


###
Typeahead directive
Allow to fetch and pick data based on typed characters.
###
angular.module('stones').
  directive 'stTypeahead', [
    '$parse',
    '$compile',
    ($parse, $compile) ->
      scope: true
      restrict: 'EA'
      require: ['stTypeahead', '^?ngModel']
      controller: [
        '$scope',
        '$element',
        '$attrs',
        '$transclude',
        (scope, elm, attrs, transcludeFn) ->
          @source = []
          @ngModel = null
          @dropdown = null
          @currentItem = null
          @selected = false
          @focused = false
          @mousedOver = false
          @allowNew = false
          @index = scope.$index
          @typedCounter = 0
          @sortFn = (a, b) =>
            if a.label > b.label
              return 1
            else if b.label > a.label
              return -1
            else
              return 0
          @selectFn = (value, index) => return

          # Set source to perform searches
          @setSource = (source) =>
            getLabel = (item) ->
              if attrs.stTypeaheadLabel?
                return item[attrs.stTypeaheadLabel]
              else if item.label?
                return item.label
              return item

            getValue = (item) ->
              if attrs.stTypeaheadValue?
                return item[attrs.stTypeaheadValue]
              else if item.value?
                return item.value
              return item

            @source = []

            if angular.isArray source
              for item in source
                @source.push
                  label: getLabel item
                  value: getValue item
            else if angular.isObject source
              for key, value of source
                @source.push
                  label: key
                  value: getValue value

            @matchItems()
            return

          # Find items according to typed characters
          @matchItems = (value) =>
            # Don't match anything if there aren't typed characters
            if @typedCounter is 0 then return

            if not value? or value is ''
              scope.stMatchedItems = @source
            else
              re = new RegExp value, 'i'
              scope.stMatchedItems = (item for item in @source when re.test item.label)
              @currentItem = (item for item in scope.stMatchedItems when item.label is value)

            scope.stMatchedItems.sort @sortFn
            @show()
            return

          # Propagate selection made
          @selectItem = (item_) =>
            item = if item_? then item_ else @currentItem

            if item?
              @currentItem = item
              @ngModel.$setViewValue item.label
              elm.val item.label
              @selectFn item.value, @index
            else
              if not @allowNew
                @currentItem = null
                @ngModel.$setViewValue ''
                elm.val ''
                @selectFn '', @index

            @hide()
            @typedCounter = 0
            return

          # Add or removes 'active' class to/from dropdown items
          @setItemClass = (item) =>
            if item is @currentItem
              return 'active'
            return

          # Go one item up
          @prev = () =>
            index = scope.stMatchedItems.indexOf @currentItem
            if index is (scope.stMatchedItems.length - 1) then index -= 1
            @currentItem = scope.stMatchedItems[index + 1]
            return

          # Go one item down
          @next = () =>
            index = scope.stMatchedItems.indexOf @currentItem
            if index is 0 then index += 1
            @currentItem = scope.stMatchedItems[index - 1]
            return

          # Hide dropdown
          @hide = () =>
            @dropdown.hide()
            return

          # Show dropdown
          @show = () =>
            if scope.stMatchedItems.length
              offset = elm.offset()
              offset.top += elm[0].offsetHeight + 2
              @dropdown.css 'top', offset.top
              @dropdown.css 'left', offset.left
              @dropdown.show()
            else
              @hide()
            return

          # Binding to keydown event
          @keydownFn = (e) =>
            switch e.keyCode
              when 9 then @selectItem()
              when 13
                e.preventDefault()
                @selectItem()
              when 38 then @next()
              when 40 then @prev()
              when 27 then @hide()
              else @typedCounter++
            scope.$apply()
            return

          # Binding to focus event
          @focusFn = (e) =>
            empty = e.currentTarget.value is ''
            if empty then @typedCounter++
            @focused = true
            @matchItems e.currentTarget.value
            scope.$apply()
            return

          # Binding to blur event
          @blurFn = (e) =>
            @focused = false
            if not @mousedOver then @hide()
            scope.$apply()
            return

          # Binding to mouseenter event
          @mouseenterFn = (e) =>
            @mousedOver = true
            @dropdown.find('li').removeClass 'active'
            scope.$apply()
            return

          # Binding to mouseleave event
          @mouseleaveFn = (e) =>
            @mousedOver = false
            index = scope.stMatchedItems.indexOf @currentItem
            if index isnt -1
              @dropdown.find('li').eq(index).addClass 'active'
            scope.$apply()
            return

          # Scope bindings
          scope.stSelectItem = @selectItem
          scope.stSetItemClass = @setItemClass

          if $parse(attrs.stTypeaheadSelectFn)(scope)?
            @selectFn = $parse(attrs.stTypeaheadSelectFn)(scope)
          if $parse(attrs.stTypeadeadSortFn)(scope)?
            @sortFn = $parse(attrs.stTypeaheadSortFn)(scope)

          # Change source
          scope.$watch attrs.stTypeahead, (value, old) ->
            if value? and value isnt old
              @setSource value
            return

          # Add dropdown to DOM
          tpl = '
<ul class="typeahead dropdown-menu">
  <li ng-repeat="stItem in stMatchedItems" ng-click="stSelectItem(stItem)" ng-class="stSetItemClass(stItem)">
    <a href="">{{ stItem.label }}</a>
  </li>
</ul>'
          @dropdown = $compile(tpl)(scope)
          angular.element('body').append @dropdown
          @dropdown.bind 'mouseenter', @mouseenterFn
          @dropdown.bind 'mouseleave', @mouseleaveFn

          # Clear dropdown from DOM
          scope.$on '$destroy', (e) =>
            @dropdown.remove()
            return

          # Element events
          elm.bind 'keydown', @keydownFn
          elm.bind 'focus', @focusFn
          elm.bind 'blur', @blurFn

          return
        ]
      link: (scope, elm, attrs, ctrls, transcludeFn) ->
        stTypeaheadCtrl = ctrls[0]
        ngModel = ctrls[1]
        if not ngModel? or not stTypeaheadCtrl? then return

        stTypeaheadCtrl.ngModel = ngModel

        # Update view if model changes
        ngModel.$viewChangeListeners.push () ->
          stTypeaheadCtrl.matchItems ngModel.$viewValue
          return

        return
  ]

###
Google Maps directive
Load a map inside element with custom properties.
###
angular.module('stones')
  .directive 'stGoogleMaps', [
    '$window',
    '$parse',
    ($window, $parse) ->
      restrict: 'EA'
      link: (scope, elm, attrs, ctrls, transcludeFn) ->
        google = $window.google
        if not google?
          throw 'stGoogleMapsError: Google Maps not loaded.'
        mapOpts = $parse(attrs.stGoogleMaps)(scope)
        if not mapOpts?
          throw 'stGoogleMapsError: no map options found.'

        scope.stMap = new google.maps.Map elm[0], mapOpts
  ]
