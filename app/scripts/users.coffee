'use strict'

class User
  ###
  Represents a user of the application.
  This model is so important to authentication system.
  ###

  apiUrlPrefix = '/auth/users'
  setApiUrlPrefix = (urlPrefix) ->
    apiUrlPrefix = urlPrefix

  $get = ($resource) ->
    ###
    User Service constructor.
    Requires AngularJS Resource Module.
    ###
    return $resource apiUrlPrefix + '/:key',
          {key: '@__key__'},
          {
            # Actions
            resetPassword: {
              method: 'post',
              url: apiUrlPrefix + '/:key/password_reset/',
              withCredentials: true
            }
          }

  constructor: () ->
    return {
      $get: ['$resource', $get],
      setApiUrlPrefix: setApiUrlPrefix
    }

angular.module('stones')
  .provider('stones.User', User)
  .controller 'stones.UsersListCtrl', [
    '$scope',
    '$routeParams',
    'User',
    (scope, $routeParams, User) ->
      scope.users = [];

      User.query $routeParams, (users) ->
        scope.users = users;
        return

      return
  ]
