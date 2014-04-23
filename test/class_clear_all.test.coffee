describe 'CachedResource.$clearAll()', ->
  {CachedResource, $cachedResource, $httpBackend, rabbits, combos} = {}

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
      $httpBackend.whenGET('/animals?type=fictional-rabbits').respond 200, [
        { name: 'white-rabbit', source: 'Alice In Wonderland' }
        { name: 'peppy-hare', source: 'Starfox' }
        { name: 'energizer-bunny', source: 'Energizer' }
        { name: 'frank', source: 'Donnie Darko' }
      ]
      $httpBackend.whenGET('/animals?type=combos').respond 200, [
        { name: 'liger', from: ['Lion', 'Tiger'] }
        { name: 'groler-bear', from: ['Grizzly Bear', 'Polar Bear'] }
      ]
      CachedResource = $cachedResource 'class-clear-test', '/animals/:name', {name: '@name'}
      rabbits = CachedResource.query type: 'fictional-rabbits'
      combos = CachedResource.query type: 'combos'
      $httpBackend.flush()

    it 'should remove all entries from the cache', ->
      CachedResource.$clearAll()
      expect(localStorage.length).to.equal 0

    it 'should remove all entries from the cache except for those specified by a key', ->
      CachedResource.$clearAll exceptFor: [{name: 'frank'}]
      expect(localStorage.length).to.equal 1
      expect(localStorage.getItem('cachedResource://class-clear-test?name=frank')).to.contain 'Donnie Darko'

    it 'should remove all entries from the cache except for those specified by resource instance', ->
      CachedResource.$clearAll exceptFor: rabbits[0...1]
      expect(localStorage.length).to.equal 1
      expect(localStorage.getItem('cachedResource://class-clear-test?name=white-rabbit')).to.contain 'Alice In Wonderland'

    it 'should remove all entries from the cache except for those in an array specified by key', ->
      CachedResource.$clearAll exceptFor: type: 'combos'
      expect(localStorage.length).to.equal 3
      expect(localStorage.getItem('cachedResource://class-clear-test/array?type=combos')).to.contain 'liger'
      expect(localStorage.getItem('cachedResource://class-clear-test?name=liger')).to.contain 'Lion'
      expect(localStorage.getItem('cachedResource://class-clear-test?name=groler-bear')).to.contain 'Grizzly'
