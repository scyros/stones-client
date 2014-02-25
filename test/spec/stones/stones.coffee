'use strict'

'use strict'

describe 'Controller: UsersCtrl', () ->

  # load the controller's module
  beforeEach module 'stones'

  api_url_prefix = '/auth'
  users_url_prefix = api_url_prefix + '/users'
  httpBackend = null
  controller = null
  stonesUser = null
  windowMock = null
  UsersCtrl = {}
  scope = {}
  fixtures = {
    users: [{
      __key__: 'abc',
      __id__: 123,
      first_name: 'Carlos',
      last_name: 'León',
      email: 'carlos@me.com',
      profile_url: 'http://www.profile.com/carlos',
      picture_url: 'http://static.profile.com/carlos'
    }, {
      __key__: 'abd',
      __id__: 124,
      first_name: 'Eduardo',
      last_name: 'Franco',
      email: 'eduardo@me.com',
      profile_url: 'http://www.profile.com/eduardo',
      picture_url: 'http://static.profile.com/eduardo'
    }]
  }
  fixtures.user = fixtures.users[0]

  # Initialize the controller and a mock scope
  beforeEach inject ($controller, $rootScope, $httpBackend, _stonesUser_,
      $window) ->
    scope = $rootScope.$new()
    httpBackend = $httpBackend
    controller = $controller
    stonesUser = _stonesUser_
    windowMock = $window

    windowMock.logged_user = fixtures.user

  afterEach () ->
    httpBackend.verifyNoOutstandingExpectation()
    httpBackend.verifyNoOutstandingRequest()

  it 'User query OK test', () ->
    httpBackend.expectGET(users_url_prefix).respond(fixtures.users)
    UsersCtrl = controller 'stones.UsersListCtrl', {
      $scope: scope
    }
    httpBackend.flush()
    expect(scope.users.length).toBe 2
    expect(scope.users[0].__key__).toBe 'abc'
    expect(scope.users[0].__id__).toBe 123
    expect(scope.users[1].__key__).toBe 'abd'
    expect(scope.users[1].__id__).toBe 124

  it 'User paginated query OK test', () ->
    httpBackend.expectGET(users_url_prefix + '?p=1')
      .respond
        current_page: 1
        entities: fixtures.users
        page_size: 20
        total_pages: 1

    UsersCtrl = controller 'stones.UsersListCtrl', {
      $scope: scope
      $routeParams: {p: 1}
    }
    httpBackend.flush()
    expect(scope.users.length).toBe 2
    expect(scope.users[0].__key__).toBe 'abc'
    expect(scope.users[0].__id__).toBe 123
    expect(scope.users[1].__key__).toBe 'abd'
    expect(scope.users[1].__id__).toBe 124

  it 'User query KO test', () ->
    httpBackend.expectGET(users_url_prefix).respond(500, {msgs: [{
      msg: 'Server error',
      level: 'error'
    }]})
    UsersCtrl = controller 'stones.UsersListCtrl', {
      $scope: scope
    }
    httpBackend.flush()
    expect(scope.users.length).toBe 0

  it 'User reset password OK test', () ->
    httpBackend.expectGET(users_url_prefix).respond(fixtures.users)
    UsersCtrl = controller 'stones.UsersListCtrl', {
      $scope: scope
    }
    httpBackend.flush()
    user = scope.users[0]
    httpBackend.expectPOST(users_url_prefix + '/abc/password_reset')
      .respond(200, {msgs: [{
        msg: 'Successful password reset email send.',
        level: 'success'
      }]})
    user.$resetPassword()
    httpBackend.flush()

  it 'User OAuth2 login', () ->
    login_url = ''
    httpBackend.expectPOST(api_url_prefix + '/google/login?')
      .respond(200, 'GoogleLoginURL')
    user = stonesUser.oauth2login({provider: 'google'}, {provider: 'google'})
    user.$promise.then (url) ->
      login_url = url
    httpBackend.flush()
    expect(login_url).toBe 'GoogleLoginURL'

  it 'User logged present', () ->
    httpBackend.expectGET(users_url_prefix).respond(fixtures.users)
    UsersCtrl = controller 'stones.UsersListCtrl', {
      $scope: scope
    }
    httpBackend.flush()
    expect(scope.logged_user).toBe fixtures.user

describe 'Directive: stPagination', () ->
  beforeEach module 'stones'

  compile = null
  scope = null

  beforeEach inject ($rootScope, $compile) ->
    compile = $compile
    scope = $rootScope.$new()

  it 'Check scope', () ->
    scope.current_page = 1
    scope.page_size = 20
    scope.total_pages = 2
    elm = compile('<div st-pagination></div>')(scope)
    scope.$digest()
    expect(elm.find('li').length).toBe 4
