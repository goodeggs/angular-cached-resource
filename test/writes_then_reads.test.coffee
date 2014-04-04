describe 'read a resource after writing to it', ->
  {CachedResource, $httpBackend} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = $cachedResource 'write-then-read-test', '/mock/:id'

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  describe 'when the write was unsuccessful', ->
    beforeEach ->
      $httpBackend.expectPOST('/mock/1').respond 503
      CachedResource.save {id: 1}, {magic: 'Attempt to save resource'}
      $httpBackend.flush()

    it 'returns a cached, saved version of the resource on read', ->
      resourceInstance = CachedResource.get {id: 1}
      expect(resourceInstance).to.have.property 'magic', 'Attempt to save resource'

      $httpBackend.expectPOST('/mock/1').respond 200
      $httpBackend.expectGET('/mock/1').respond magic: 'Resource saved'
      $httpBackend.flush()

      expect(resourceInstance).to.have.property 'magic', 'Resource saved'

  describe 'when the write was okay', ->
    beforeEach ->
      $httpBackend.expectPOST('/mock/2').respond 200, {id: 2, worked: 'fromWrite'}
      CachedResource.save {id: 2}, {worked: 'fromWrite'}
      $httpBackend.flush()

    it 'should return the cached saved version of the resource on read', ->
      resourceInstance = CachedResource.get {id: 2}
      expect(resourceInstance).to.have.property 'worked', 'fromWrite'
      $httpBackend.expectGET('/mock/2').respond 200
      $httpBackend.flush()

    it 'should update the resource with new server version', ->
      resourceInstance = CachedResource.get {id: 2}
      $httpBackend.expectGET('/mock/2').respond 200, {id: 2, worked: 'fromRead'}
      $httpBackend.flush()
      expect(resourceInstance).to.have.property 'worked', 'fromRead'
