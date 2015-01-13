describe 'CachedResource.get array resource collections', ->
  {$httpBackend, $timeout, CachedResource, resourceCollection} = {}

  beforeEach ->
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      $timeout = $injector.get '$timeout'
      CachedResource = $cachedResource 'class-get-array-cache-only-test', '/colors/:color', {color: '@color'},
        queryFromCache:
          method: 'GET'
          isArray: true
          cacheOnly: true

  describe 'when resource is not in cache', ->
    it 'throws an error if nothing in the cache', (done) ->
      resources = CachedResource.queryFromCache()

      resources.$promise.catch (error) ->
        expect(error).to.be.ok
        done()

      $timeout.flush()
      $httpBackend.verifyNoOutstandingRequest()

  describe 'when resource is in cache', ->
    beforeEach ->
      colors = [
        { color: 'red', hex: '#FF0000' }
        { color: 'green', hex: '#00FF00' }
        { color: 'blue', hex: '#0000FF' }
        { color: 'papayawhip', hex: '#FFEFD5' }
      ]
      CachedResource.$addArrayToCache {}, colors, false


    it 'returns the resources directly from cache (does not make a request)', (done) ->
      resources = CachedResource.queryFromCache()

      resources.$promise.then ->
        expect(resources.length).to.equal 4
        expect(resources[0]).to.have.property 'color', 'red'
        expect(resources[0]).to.have.property 'hex', '#FF0000'
        done()

      $timeout.flush()
      $httpBackend.verifyNoOutstandingRequest()
