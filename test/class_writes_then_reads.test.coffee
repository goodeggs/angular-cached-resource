describe 'Class writes, then reads', ->
  {CachedResource, $httpBackend} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = $cachedResource 'class-writes-then-reads-test', '/mock/:id', {id: '@id'}

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  describe 'when the write was unsuccessful', ->
    beforeEach ->
      $httpBackend.expectPOST('/mock/1').respond 503
      CachedResource.save {id: 1}, {magic: 'Attempt to save resource', id: 1}
      $httpBackend.flush()

    it 'returns a cached, saved version of the resource on read', ->
      resourceInstance = CachedResource.get {id: 1}
      expect(resourceInstance).to.have.property 'magic', 'Attempt to save resource'

      $httpBackend.expectPOST('/mock/1').respond 200
      $httpBackend.expectGET('/mock/1').respond magic: 'Resource saved'
      $httpBackend.flush()

      expect(resourceInstance).to.have.property 'magic', 'Resource saved'

    it 'defers response for isArray query on the same resource until write is successful', ->
      resourceArray = CachedResource.query {herp: 'derp'}
      expect(resourceArray).to.have.length 0

      $httpBackend.expectPOST('/mock/1').respond 200
      $httpBackend.expectGET('/mock?herp=derp').respond [{id: 1, magic: 'fromRead'}]
      $httpBackend.flush()

      expect(resourceArray).to.have.length 1
      expect(resourceArray[0]).to.have.property 'magic', 'fromRead'

  describe 'when the write was okay', ->
    beforeEach ->
      $httpBackend.expectPOST('/mock/2').respond 200, {id: 2, worked: 'fromWrite'}
      CachedResource.save {id: 2}, {worked: 'fromWrite', id: 2}
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
