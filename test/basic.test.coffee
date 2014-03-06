describe 'cacheResource', ->
  {cacheResource, $httpBackend, resource} = {}

  beforeEach ->
    module('cachedResource', 'ngResource')
    inject ($injector) ->
      cacheResource = $injector.get 'cacheResource'
      $httpBackend = $injector.get '$httpBackend'

  describe 'with empty cache', ->
    beforeEach ->
      CachedResource = cacheResource('/mock/:parameter')
      expect(CachedResource).to.have.key 'get'

      $httpBackend.when('GET', '/mock/1').respond
        parameter: 1
        magic: 'Here is the response'

      $httpBackend.expectGET '/mock/1'
      resource = CachedResource.get({parameter: 1})

    afterEach ->
      $httpBackend.verifyNoOutstandingExpectation()
      $httpBackend.verifyNoOutstandingRequest()
      localStorage.clear()

    it 'wraps the "get" function of a resource', (done) ->
      expect(resource).to.have.property '$promise'

      resource.$promise.then ->
        expect(resource).to.have.property 'magic', 'Here is the response'
        done()

      $httpBackend.flush()

    it 'adds the response to local storage', ->
      $httpBackend.flush()

      cachedResponse = JSON.parse localStorage.getItem '/mock/1'
      expect(cachedResponse).to.deep.equal
        parameter: 1
        magic: 'Here is the response'
