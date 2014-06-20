describe 'write cache introspection', ->
  {Album, $httpBackend, $timeout} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      $timeout = $injector.get '$timeout'
      Album = $cachedResource 'album', '/album/:id', {id: '@id'}

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  describe 'before write', ->

    it 'has 0 pending writes', ->
      expect(Album.$writes.count).to.equal 0

    it 'has a promise that resolves immediately', ->
      wasInPromise = false
      Album.$writes.promise.then -> wasInPromise = true
      $timeout.flush 0
      expect(wasInPromise).to.be.ok

    it 'has a flush method that takes a callback that immediately runs', ->
      wasInCallback = false
      Album.$writes.flush -> wasInCallback = true
      $timeout.flush 0
      expect(wasInCallback).to.be.ok

  describe 'after write', ->

    beforeEach ->
      Album.save { id: 1, name: 'Hi Scores', artist: 'Boards of Canada' }
      $httpBackend.whenPOST('/album/1').respond 200

    it 'has 1 pending write before the response', ->
      expect(Album.$writes.count).to.equal 1
      $httpBackend.flush()

    it 'has 0 pending writes after the response', ->
      $httpBackend.flush()
      expect(Album.$writes.count).to.equal 0

    it 'has a promise that resolves after the request completes', ->
      wasInPromise = false
      Album.$writes.promise.then -> wasInPromise = true
      $timeout.flush 0
      expect(wasInPromise).to.not.be.ok
      $httpBackend.flush()
      expect(wasInPromise).to.be.ok

    it 'has a flush method that takes a callback that runs when the queue is empty', ->
      wasInCallback = false
      Album.$writes.flush -> wasInCallback = true
      $timeout.flush 0
      expect(wasInCallback).to.not.be.ok
      $httpBackend.flush()
      expect(wasInCallback).to.be.ok
