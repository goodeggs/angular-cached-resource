describe 'POST cacheOnly=true', ->
  {CachedResource, $httpBackend, $timeout, resourceInstance} = {}

  beforeEach ->
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      $timeout = $injector.get '$timeout'
      CachedResource = $cachedResource 'class-post-cache-only-test', '/mock/:id', {id: '@_id'},
        saveToCache:
          method: 'POST'
          cacheOnly: true
        getFromCache:
          method: 'GET'
          cacheOnly: true

  it 'POSTs the resource only to the cache', (done) ->
    resource = CachedResource.saveToCache({_id: 1, test: 'I want to go to the cache!'})

    resource.$promise.then ->
      expect(resource.test).to.equal 'I want to go to the cache!'
      done()

    $httpBackend.verifyNoOutstandingRequest()
    $timeout.flush()

  it 'POSTs the resource instance only to the cache', (done) ->
    resource = new CachedResource({_id: 2, test: 'I love caches'})

    resource.$saveToCache().$promise.then ->
      expect(resource).to.have.property '_id', 2
      expect(resource).to.have.property 'test', 'I love caches'
      done()

    $timeout.flush()
    $httpBackend.verifyNoOutstandingRequest()
