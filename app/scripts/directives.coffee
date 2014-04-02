'use strict'

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
100% height directive.
Sets box height to the maximum possible within body bounds.
###
angular.module('stones')
  .directive 'stHeight100', [
    () ->
      restrict: 'A'
      link: (scope, _elm, attrs) ->
        elm = $(_elm)
        body_height = $('body').height()
        top = elm.offset().top
        height = body_height - top
        elm.height(height)
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
