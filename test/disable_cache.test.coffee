describe 'disabling cache for certain actions', ->
  {Goat, $httpBackend} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      Goat = $cachedResource 'disable-cache-test', '/goats/:name', {name: '@name'},
        bleat: { method: 'PUT', cache: off }
        kick: { method: 'PUT' }

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  describe 'class', ->

  describe 'instance', ->
