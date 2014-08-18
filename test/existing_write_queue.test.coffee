describe 'an existing write queue', ->
  {$cachedResource, $httpBackend} = {}

  beforeEach ->
    localStorage.setItem 'cachedResource://existing-write-queue-test/write', angular.toJson [{params: {id: 1}, resourceParams: {id: 1}, action: 'save'}]
    localStorage.setItem 'cachedResource://existing-write-queue-test?id=1', angular.toJson value: magic: 'from the cache'

    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'

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
