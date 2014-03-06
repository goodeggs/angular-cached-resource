describe 'cacheResource', ->
  {cacheResource, $resource, $httpBackend} = {}

  beforeEach ->
    module('cachedResource', 'ngResource')
    inject ($injector) ->
      cacheResource = $injector.get 'cacheResource'
      $resource = $injector.get '$resource'
      $httpBackend = $injector.get '$httpBackend'

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()

  it 'wraps the "get" function of a resource', (done) ->
    cached = cacheResource($resource('/mock/:parameter'))
    expect(cached).to.have.key 'get'

    $httpBackend.when('GET', '/mock/1').respond
      parameter: 1
      magic: 'Here is the response'

    $httpBackend.expectGET '/mock/1'

    resource = cached.get({parameter: 1})
    expect(resource).to.have.property '$promise'

    resource.$promise.then ->
      expect(resource).to.have.property 'magic', 'Here is the response'
      done()

    $httpBackend.flush()
