describe 'CachedResource::post', ->
  {resourceInstance, $httpBackend, $timeout} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      $timeout = $injector.get '$timeout'
      CachedResource = $cachedResource 'instance-post-test', '/mock/:id', {id: '@id'}
      resourceInstance = new CachedResource id: 1, notes: 'this is a saved note'

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  describe 'while online', ->
    it 'POSTS the entire body of the resource', ->
      $httpBackend.expectPOST('/mock/1', { id: 1, notes: 'this is a saved note' }).respond 200
      resourceInstance.$save()
      $httpBackend.flush()

    it 'modifies existing resource attributes based on the response', ->
      $httpBackend.expectPOST('/mock/1').respond
        id: 1
        notes: 'this is a different note'
      resourceInstance.$save()
      $httpBackend.flush()
      expect(resourceInstance.notes).to.equal 'this is a different note'

    it 'removes resource attributes if the response does not have them', ->
      $httpBackend.expectPOST('/mock/1').respond id: 1
      resourceInstance.$save()
      $httpBackend.flush()
      expect(resourceInstance.notes).to.be.undefined

    it 'adds new resource attributes if the response has them', ->
      $httpBackend.expectPOST('/mock/1').respond id: 1, notes: 'this is a saved note', animal: 'squid'
      resourceInstance.$save()
      $httpBackend.flush()
      expect(resourceInstance.animal).to.equal 'squid'

  describe 'while offline', ->
    it 'allows you to save twice, even if it didn’t succeed the first time', ->
      $httpBackend.expectPOST('/mock/1', { id: 1, notes: 'this is a saved note' }).respond 500
      resourceInstance.$save()
      $httpBackend.flush()

      resourceInstance.notes = 'this is a doubly saved note'
      $httpBackend.expectPOST('/mock/1', { id: 1, notes: 'this is a doubly saved note' }).respond 500
      resourceInstance.$save()
      $httpBackend.flush()
