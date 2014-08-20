describe 'disabling cache for certain actions', ->
  {Goat, $httpBackend} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      Goat = $cachedResource 'disable-cache-test', '/goats/:name', {name: '@name'},
        bleat: { url: '/goats/:name/bleat', method: 'PUT', cache: off }
        kick: { url: '/goats/:name/kick', method: 'PUT' }

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  describe 'Goat class', ->
    it 'does not cache when bleating', ->
      $httpBackend.expectPUT('/goats/houdini/bleat').respond 500
      Goat.bleat name: 'houdini'
      $httpBackend.flush()
      expect(Goat.$writes.queue.length).to.equal 0

    it 'caches when kicking', ->
      $httpBackend.expectPUT('/goats/houdini/kick').respond 500
      Goat.kick name: 'houdini'
      $httpBackend.flush()
      expect(Goat.$writes.queue.length).to.equal 1

  describe 'Goat instance', ->
    {houdini} = {}

    beforeEach ->
      houdini = new Goat name: 'houdini'

    it 'does not cache when bleating', ->
      $httpBackend.expectPUT('/goats/houdini/bleat').respond 500
      houdini.$bleat()
      $httpBackend.flush()
      expect(Goat.$writes.queue.length).to.equal 0

    it 'caches when kicking', ->
      $httpBackend.expectPUT('/goats/houdini/kick').respond 500
      houdini.$kick()
      $httpBackend.flush()
      expect(Goat.$writes.queue.length).to.equal 1
