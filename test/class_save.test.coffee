describe 'cachedResource.save', ->
  {CachedResource, $httpBackend, $http, $timeout} = {}

  beforeEach ->
    module('cachedResource')
    inject ($injector) ->
      cachedResource = $injector.get 'cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      $http = $injector.get '$http'
      $timeout = $injector.get '$timeout'
      CachedResource = cachedResource 'class-save-test', '/mock/:id'

  afterEach ->
    $timeout.flush()
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  describe 'while online', ->
    it 'saves the resource normally', (done) ->
      $httpBackend.expectPOST('/mock/1', magic: 'This is a saved resource').respond
        id: 1
        magic: 'Here is the response'
      resource = CachedResource.save {id: 1}, {magic: 'This is a saved resource'}
      resource.$promise.then ->
        expect(resource.magic).to.equal 'Here is the response'
        done()
      $httpBackend.flush()

  describe 'when server is not reachable', ->

    {resource} = {}

    beforeEach ->
      $httpBackend.expectPOST('/mock/1', magic: 'Save #1').respond 504
      resource = CachedResource.save {id: 1}, {magic: 'Save #1'}
      $httpBackend.flush()

    it 'attempts the save again when a window.onOnline event is sent', ->
      $httpBackend.expectPOST('/mock/1', magic: 'Save #1').respond 200
      dispatchEvent(new Event 'online')
      $httpBackend.flush()

    # it 'attempts the save again after a timeout has passed', ->
    #   $httpBackend.expectPOST('/mock/1', magic: 'Save #1').respond 200
    #   $timeout.flush()
    #   $httpBackend.flush()

