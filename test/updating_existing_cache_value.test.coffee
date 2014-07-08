describe 'Updating existing cache value', ->
  {CachedResource, $httpBackend, $timeout} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      $timeout = $injector.get '$timeout'
      CachedResource = $cachedResource 'class-save-test', '/mock/:id', {id: '@id'}

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  describe 'resource with nested values', ->
    beforeEach ->
      CachedResource.$addToCache {
        id: 1
        magic:
          beans: ['old nested value']
      }, false

      $httpBackend.expectGET('/mock/1').respond
        id: 1
        magic: beans: ['new nested value']

    it 'updates nested values without changing the memory reference', ->
      resource = CachedResource.get {id: 1}
      cachedBeans = resource.magic.beans
      $httpBackend.flush()
      expect(cachedBeans[0]).to.equal 'new nested value'
