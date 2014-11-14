describe 'Class multiple writes', ->
  {CachedResource, $httpBackend} = {}

  beforeEach ->
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = $cachedResource 'class-multiple-writes-test', '/mock/:id', {id: '@id'}

  describe 'when making two writes', ->
    beforeEach ->
      for id in [1, 2]
        $httpBackend.expectPOST("/mock/#{id}").respond 200, {id: id, worked: 'fromWrite'}
        CachedResource.save {id: id}, {worked: 'fromWrite', id: id}

      $httpBackend.flush()

    it 'should return make exactly two calls to the server', ->
      $httpBackend.verifyNoOutstandingExpectation()
      $httpBackend.verifyNoOutstandingRequest()

    it 'should return the cached saved version of the resources on read', ->
      for id in [1, 2]
        resourceInstance = CachedResource.get {id: id}
        expect(resourceInstance).to.have.property 'worked', 'fromWrite'
        $httpBackend.expectGET("/mock/#{id}").respond 200
        $httpBackend.flush()

    it 'should update the resources with new server version', ->
      for id in [1, 2]
        resourceInstance = CachedResource.get {id: id}
        $httpBackend.expectGET("/mock/#{id}").respond 200, {id: id, worked: 'fromRead'}
        $httpBackend.flush()
        expect(resourceInstance).to.have.property 'worked', 'fromRead'

