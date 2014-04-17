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
    it 'saves the resource normally', ->
      $httpBackend.expectPOST('/mock/1', { id: 1, notes: 'this is a saved note' }).respond
        id: 1
        notes: 'this is a saved note'

      resourceInstance.$save()
      $httpBackend.flush()

    it 'updates the resource from the response', ->
      $httpBackend.expectPOST('/mock/1').respond
        id: 1
        notes: 'this is a different note'
      resourceInstance.$save()
      $httpBackend.flush()
      expect(resourceInstance.notes).to.equal 'this is a different note'

  describe 'while offline', ->
    it 'allows you to save twice, even if it didn’t succeed the first time', ->
      $httpBackend.expectPOST('/mock/1', { id: 1, notes: 'this is a saved note' }).respond 500
      resourceInstance.$save()
      $httpBackend.flush()

      resourceInstance.notes = 'this is a doubly saved note'
      $httpBackend.expectPOST('/mock/1', { id: 1, notes: 'this is a doubly saved note' }).respond 500
      resourceInstance.$save()
      $httpBackend.flush()
