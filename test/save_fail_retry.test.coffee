# for reference: https://github.com/goodeggs/angular-cached-resource/pull/6

describe 'attempting to save a resource after a resource with the same cache key previously failed to save', ->
  {$cachedResource, $httpBackend} = {}

  beforeEach ->
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = $cachedResource 'save-fail-retry', '/mock/:id', {id: '@id'}

      $httpBackend.expectGET('/mock/1').respond { id: 1, notes: 'this is a note' }
      resourceInstance = CachedResource.get { id: 1 }
      $httpBackend.flush()

      # add the failed save to the cache
      $httpBackend.expectPOST('/mock/1').respond 500
      resourceInstance.notes = 'this is a saved note'
      resourceInstance.$save()
      $httpBackend.flush()

  it 'successfully saves the second resource with the same cache key', ->
    $httpBackend.expectPOST('/mock/1', { id: 1, notes: 'this is a saved note' }).respond 500
    CachedResource = $cachedResource 'save-fail-retry', '/mock/:id', {id: '@id'}
    $httpBackend.flush()

    $httpBackend.expectPOST('/mock/1', { id: 1, notes: 'this is a doubly saved note' }).respond
      id: 1
      notes: 'this is a doubly saved note'
    resourceInstance2 = CachedResource.save { id: 1, notes: 'this is a doubly saved note' }
    $httpBackend.flush()
