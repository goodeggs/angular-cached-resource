describe 'CachedResource::post', ->
  {resourceInstance, $httpBackend, $timeout} = {}

  beforeEach ->
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      $timeout = $injector.get '$timeout'
      CachedResource = $cachedResource 'instance-post-test', '/mock/:id', {id: '@id'}
      resourceInstance = new CachedResource id: 1, notes: 'this is a saved note', list: [1,2,3]

  describe 'while online', ->
    it 'POSTS the entire body of the resource', ->
      $httpBackend.expectPOST('/mock/1', { id: 1, notes: 'this is a saved note', list: [1,2,3] }).respond 200
      resourceInstance.$save()
      $httpBackend.flush()

    it 'modifies existing resource attributes based on the response', ->
      $httpBackend.whenPOST('/mock/1').respond
        id: 1
        notes: 'this is a different note'
        list: [1,2,3]
      resourceInstance.$save()
      $httpBackend.flush()
      expect(resourceInstance.notes).to.equal 'this is a different note'

    it 'removes resource attributes if the response does not have them', ->
      $httpBackend.whenPOST('/mock/1').respond id: 1
      resourceInstance.$save()
      $httpBackend.flush()
      expect(resourceInstance.notes).to.be.undefined
      expect(resourceInstance.list).to.be.undefined

    it 'does not remove resource attributes that have been added but not saved to local storage', ->
      $httpBackend.whenPOST('/mock/1').respond id: 1, notes: 'from the server'
      resourceInstance.$save()
      resourceInstance.localChange = 'added after save request but before httpResponse resolved'
      $httpBackend.flush()
      expect(resourceInstance.localChange).to.be.defined

    it 'adds new resource attributes if the response has them', ->
      $httpBackend.whenPOST('/mock/1').respond
        id: 1
        notes: 'this is a saved note'
        list: [1,2,3]
        animal: 'squid'
      resourceInstance.$save()
      $httpBackend.flush()
      expect(resourceInstance.animal).to.equal 'squid'

    it 'does not replace resource attributes that have not changed', ->
      oldListRef = resourceInstance.list
      $httpBackend.whenPOST('/mock/1').respond
        id: 1
        notes: 'this is a saved note'
        list: [1,2,3]
      resourceInstance.$save()
      $httpBackend.flush()
      expect(resourceInstance.list).to.equal oldListRef, 'expected lists to point to the same memory location'

    it 'does not replace resource attributes that have not been written to local storage and exist in the response', ->
      $httpBackend.whenPOST('/mock/1').respond
        id: 1
        notes: 'this is a saved note'
        list: [1,2,3]
        animal: 'squid'

      resourceInstance.notes = 'this is a saved note'
      savingInstance = resourceInstance.$save()
      resourceInstance.notes = 'work in progress'
      # post goes through after local changes after requesting a save
      $httpBackend.flush()
      expect(resourceInstance.notes).to.equal 'work in progress'

  describe 'while offline', ->
    it 'allows you to save twice, even if it didn’t succeed the first time', ->
      $httpBackend.expectPOST('/mock/1', { id: 1, notes: 'this is a saved note', list: [1,2,3] }).respond 500
      resourceInstance.$save()
      $httpBackend.flush()

      resourceInstance.notes = 'this is a doubly saved note'
      $httpBackend.expectPOST('/mock/1', { id: 1, notes: 'this is a doubly saved note', list: [1,2,3] }).respond 500
      resourceInstance.$save()
      $httpBackend.flush()

    it 'stops trying to save the second resource if the server responds with a 400-style error', ->
      $httpBackend.expectPOST('/mock/1', { id: 1, notes: 'this is a saved note', list: [1,2,3] }).respond 409
      resourceInstance.$save()
      $httpBackend.flush()
      $timeout.flush()
