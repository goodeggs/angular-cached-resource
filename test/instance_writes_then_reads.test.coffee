describe 'Instance writes, then reads', ->
  {CachedResource, instance, $httpBackend} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = $cachedResource 'instance-writes-then-reads-test', '/mock/:id', {id: '@id'}

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  describe 'when the write was unsuccessful', ->
    beforeEach ->
      $httpBackend.expectPOST('/mock/1').respond 503
      resourceInstance = new CachedResource id: 1, magic: 'Attempt to save resource'
      resourceInstance.$save()
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
      resourceInstance = new CachedResource {id: 2, worked: 'fromWrite'}
      resourceInstance.$save()
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
