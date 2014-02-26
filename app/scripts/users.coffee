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
                if typeof _data is 'string'
                  data = JSON.parse(_data)
                else if typeof _data is 'object'
                  data = _data

                ret = data
                if ('entities' of data)
                  ret = data.entities
                  ret.current_page = data.current_page
                  ret.page_size = data.page_size
                  ret.total_pages = data.total_pages
                return ret
              interceptor:
                response: (_response) ->
                  ret = _response.resource
                  if _response.data.current_page?
                    ret.current_page = _response.data.current_page
                  if _response.data.page_size?
                    ret.page_size = _response.data.page_size
                  if _response.data.total_pages?
                    ret.total_pages = _response.data.total_pages
                  ret
            update:
              method: 'put'
              withCredentials: true
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
