'use strict'

class User
  ###
  Represents a user of the application.
  This model is so important to authentication system.
  ###

  apiUrlPrefix = '/auth'
  setApiUrlPrefix = (urlPrefix) ->
    apiUrlPrefix = urlPrefix

  $get = ($resource, actions_builder) ->
    ###
    User Service constructor.
    Requires AngularJS Resource Module.
    ###
    actions =
      resetPassword:
        method: 'post'
        url: apiUrlPrefix + '/users/:key/password_reset'
        withCredentials: true
      oauth2login:
        method: 'post'
        url: apiUrlPrefix + '/:provider/login'
        withCredentials: true,
        interceptor:
          response: (_response) ->
            _response.data

    angular.extend(actions, actions_builder())

    return $resource apiUrlPrefix + '/users/:key',
          {key: '@__key__'},
          actions

  constructor: () ->
    return {
      $get: ['$resource', 'stResourceActionsBuilder', $get],
      setApiUrlPrefix: setApiUrlPrefix
    }

angular.module('stones')
  .provider('stonesUser', User)
  .controller 'stones.UsersListCtrl', [
    '$scope',
    '$routeParams',
    'stonesUser',
    (scope, $routeParams, User) ->
      scope.users = [];

      User.query $routeParams, (users) ->
        scope.users = users;
        return

      return
  ]
