describe 'an existing write queue', ->
  {$cachedResource, $httpBackend, $timeout, CachedResourceClass} = {}

  beforeEach ->
    localStorage.setItem 'cachedResource://existing-write-queue-test/write', angular.toJson [{params: {id: 1}, resourceParams: {id: 1}, action: 'save'}]
    localStorage.setItem 'cachedResource://existing-write-queue-test?id=1', angular.toJson value: magic: 'from the cache'

    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      $timeout = $injector.get '$timeout'

  afterEach ->
    localStorage.clear()
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()

  it 'saves the item that was stored in the cache', ->
    $httpBackend.expectPOST('/mock/1', magic: 'from the cache').respond 200
    $cachedResource 'existing-write-queue-test', '/mock/:id'
    $httpBackend.flush()

  it 'only writes each item once when multiple cachedResources are created', ->
    # there was a bug by which each call the create a cachedResource would resend the write queue for prior cachedResources
    $httpBackend.expectPOST('/mock/1', magic: 'from the cache').respond 200
    $cachedResource 'existing-write-queue-test', '/mock/:id'
    $cachedResource 'existing-write-queue-test2', '/mock/:id'
    $httpBackend.flush()

  describe 'before the pending writes have completed', ->
    beforeEach ->
      $httpBackend.expectPOST('/mock/1', magic: 'from the cache').respond 200
      CachedResourceClass = $cachedResource 'existing-write-queue-test', '/mock/:id'

    afterEach ->
      $httpBackend.flush()

    it 'starts out with 1 pending write', ->
      expect(CachedResourceClass.$writes.queue.length).to.equal 1

    it 'has an unresolved promise', ->
      promiseFinished = false
      CachedResourceClass.$writes.promise.then -> promiseFinished = true
      # propagate promise resolution
      $timeout.flush(0)
      expect(promiseFinished).to.not.be.ok

  describe 'where the server is not reachable during startup', ->
    beforeEach ->
      $httpBackend.expectPOST('/mock/1', magic: 'from the cache').respond 504
      CachedResourceClass = $cachedResource 'existing-write-queue-test', '/mock/:id'
      $httpBackend.flush()

    it 'still has 1 pending write', ->
      expect(CachedResourceClass.$writes.queue.length).to.equal 1

    it 'has an unresolved promise', ->
      promiseFinished = false
      CachedResourceClass.$writes.promise.then -> promiseFinished = true
      # propagate promise resolution
      $timeout.flush(0)
      expect(promiseFinished).to.not.be.ok

    it 'has a flush method that takes a callback that runs when the queue is empty', ->
      callbackRun = false
      $httpBackend.expectPOST('/mock/1', magic: 'from the cache').respond 200
      CachedResourceClass.$writes.flush -> callbackRun = true
      # propagate promise resolution
      $timeout.flush(0)
      expect(callbackRun).to.not.be.ok
      $httpBackend.flush()
      expect(callbackRun).to.be.ok

    it 'will prevent a query from clobbering the pending writes', ->
      # a bug in which the query would execute immediately and the returned value would clobber the pending
      # write (the magic parameter in this case)

      # before the fix, the get would execute first and clobber the data of the post
      $httpBackend.expectPOST('/mock/1', magic: 'from the cache').respond 200
      $httpBackend.expectGET('/mock').respond [{id: 1, magic: 'some different server value'}, {id: 2}]
      CachedResourceClass.query()

      $httpBackend.flush()
