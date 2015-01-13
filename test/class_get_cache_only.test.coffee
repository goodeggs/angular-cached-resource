describe 'GET cacheOnly=true', ->
  {CachedResource, $httpBackend, $timeout, resourceInstance} = {}

  beforeEach ->
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      $timeout = $injector.get '$timeout'
      CachedResource = $cachedResource 'class-get-cache-only-test', '/mock/:id', {id: '@_id'},
        getFromCache:
          method: 'GET'
          cacheOnly: true

  describe 'when resource is not in cache', ->
    it 'throws an error if nothing in the cache', (done) ->
      resource = CachedResource.getFromCache({id: 1})

      resource.$promise.catch (error) ->
        expect(error).to.be.ok
        done()

      $timeout.flush()
      $httpBackend.verifyNoOutstandingRequest()

  describe 'when resource is in cache', ->
    beforeEach ->
      CachedResource.$addToCache {_id: 1, test: 'help, I\'m stuck in a cache'}, false

    it 'returns the resource directly from cache (does not make a request)', (done) ->
      resource = CachedResource.getFromCache({id: 1})

      resource.$promise.then ->
        expect(resource).to.have.property '_id', 1
        expect(resource).to.have.property 'test', 'help, I\'m stuck in a cache'
        done()

      $timeout.flush()
      $httpBackend.verifyNoOutstandingRequest()
