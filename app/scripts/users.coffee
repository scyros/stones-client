'use strict'

class User
  ###
  Represents a user of the application.
  This model is so important to authentication system.
  ###

  apiUrlPrefix = '/auth'
  setApiUrlPrefix = (urlPrefix) ->
    apiUrlPrefix = urlPrefix

  $get = ($resource) ->
    ###
    User Service constructor.
    Requires AngularJS Resource Module.
    ###
    return $resource apiUrlPrefix + '/users/:key',
          {key: '@__key__'},
          {
            # Actions
            query:
              method: 'get'
              url: apiUrlPrefix + '/users/:key'
              withCredentials: true,
              isArray: true
              transformResponse: (_data, headers) ->
                ret = _data
                if 'entities' of _data
                  ret = _data.entities
                  ret.current_page = _data.current_page
                  ret.page_size = _data.page_size
                  ret.total_pages = _data.total_pages
                return ret
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
          }

  constructor: () ->
    return {
      $get: ['$resource', $get],
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
