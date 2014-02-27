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
            false
        else
          elm.find('a').bind 'click', (e) ->
            e.preventDefault()
            false
  ]
