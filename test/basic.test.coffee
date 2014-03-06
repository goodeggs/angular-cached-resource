describe 'cacheResource', ->
  {cacheResource, $httpBackend} = {}

  beforeEach ->
    module('cachedResource', 'ngResource')
    inject ($injector) ->
      cacheResource = $injector.get 'cacheResource'
      $httpBackend = $injector.get '$httpBackend'

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()

  it 'wraps the "get" function of a resource', (done) ->
    CachedResource = cacheResource('/mock/:parameter')
    expect(CachedResource).to.have.key 'get'

    $httpBackend.when('GET', '/mock/1').respond
      parameter: 1
      magic: 'Here is the response'

    $httpBackend.expectGET '/mock/1'

    resource = CachedResource.get({parameter: 1})
    expect(resource).to.have.property '$promise'

    resource.$promise.then ->
      expect(resource).to.have.property 'magic', 'Here is the response'
      done()

    resource.$save

    $httpBackend.flush()
