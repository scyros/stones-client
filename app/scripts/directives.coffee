'use strict'

angular.module('stones')
  .directive 'stPagination', [
    '$compile',
    ($compile) ->
      template: '<ul class="pagination"><li ng-class="stGetStepDownClass()"><a href="#" ng-click="stStepDown()">&laquo;</a></li><li ng-repeat="step in stSteps" ng-class="stGetStepClass(step)"><a href="#" ng-click="stGoStep(step)">{{ step }}</a></li><li ng-class="stGetStepUpClass()"><a href="#" ng-click="stStepUp()">&raquo;</a></li></ul>'
      link: (scope, elm, attrs) ->
        elm.find('a')
          .bind 'click', (e) ->
            e.preventDefault()
            false
        scope.stSteps = []

        scope.$watch 'total_pages', () ->
          scope.stSteps = (n for n in [1..scope.total_pages])

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
