describe 'cachedResource.save', ->
  {CachedResource, $httpBackend} = {}

  beforeEach ->
    module('cachedResource')
    inject ($injector) ->
      cachedResource = $injector.get 'cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = cachedResource '/mock/:id'

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  describe 'while online', ->

    it 'saves the resource normally', ->
      $httpBackend.expectPOST('/mock/1', magic: 'This is a saved resource').respond
        id: 1
        magic: 'Here is the response'
      CachedResource.save {id: 1}, {magic: 'This is a saved resource'}
      $httpBackend.flush()

  describe 'when server is not reachable', ->
    it 'attempts the save again when a different network request is made'
    it 'attempts the save again when a navigator.online event is sent'
    it 'attempts the save again after a timeout has passed'

