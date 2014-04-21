describe 'CachedResource.$clear()', ->
  {CachedResource, $cachedResource, $httpBackend} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  describe 'with a populated cache', ->

    beforeEach ->
      $httpBackend.whenGET('/fictional-rabbits').respond 200, [
        { name: 'white-rabbit', source: 'Alice In Wonderland' }
        { name: 'peppy-hare', source: 'Starfox' }
        { name: 'energizer-bunny', source: 'Energizer' }
        { name: 'frank', source: 'Donnie Darko' }
      ]
      CachedResource = $cachedResource 'class-clear-test', '/fictional-rabbits/:name', {name: '@name'}
      CachedResource.query()
      $httpBackend.flush()

    it 'should remove all entries from the cache', ->
      CachedResource.$clear()
      expect(localStorage.length).to.equal 0
