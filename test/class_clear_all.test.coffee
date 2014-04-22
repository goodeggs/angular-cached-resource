describe 'CachedResource.$clearAll()', ->
  {CachedResource, $cachedResource, $httpBackend, rabbits} = {}

  beforeEach ->
    localStorage.clear() # TODO this should not be actually necessary
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
      rabbits = CachedResource.query()
      $httpBackend.flush()

    it 'should remove all entries from the cache', ->
      CachedResource.$clearAll()
      expect(localStorage.length).to.equal 0

    it 'should remove all entries from the cache except for those specified by key', ->
      CachedResource.$clearAll exceptFor: [{name: 'frank'}]
      expect(localStorage.length).to.equal 1
      expect(localStorage.getItem('cachedResource://class-clear-test?name=frank')).to.contain 'Donnie Darko'

    it 'should remove all entries from the cache except for those specified by resource instance', ->
      CachedResource.$clearAll exceptFor: rabbits[0...1]
      expect(localStorage.length).to.equal 1
      expect(localStorage.getItem('cachedResource://class-clear-test?name=white-rabbit')).to.contain 'Alice In Wonderland'
