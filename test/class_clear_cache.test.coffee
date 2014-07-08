describe 'CachedResource.$clearCache()', ->
  {CachedResource, $cachedResource, $httpBackend, rabbits, combos} = {}

  beforeEach ->
    localStorage.clear() # TODO this should not be actually necessary
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
    CachedResource = $cachedResource 'class-clear-test', '/animals/:name', {name: '@name'}

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  describe 'with a populated cache', ->

    beforeEach ->
      CachedResource.$addArrayToCache type: 'fictional-rabbits', [
        { name: 'white-rabbit', source: 'Alice In Wonderland' }
        { name: 'peppy-hare', source: 'Starfox' }
        { name: 'energizer-bunny', source: 'Energizer' }
        { name: 'frank', source: 'Donnie Darko' }
      ]
      CachedResource.$addArrayToCache type: 'combos', [
        { name: 'liger', from: ['Lion', 'Tiger'] }
        { name: 'groler-bear', from: ['Grizzly Bear', 'Polar Bear'] }
      ]

    it 'should remove all entries from the cache', ->
      CachedResource.$clearCache()
      expect(localStorage.length).to.equal 0

    it 'should remove all entries from the cache except for those specified by a key', ->
      CachedResource.$clearCache exceptFor: [{name: 'frank'}]
      expect(localStorage.length).to.equal 1
      expect(localStorage.getItem('cachedResource://class-clear-test?name=frank')).to.contain 'Donnie Darko'

    it 'should remove all entries from the cache except for those specified by resource instance', ->
      CachedResource.$clearCache exceptFor: rabbits[0...1]
      expect(localStorage.length).to.equal 1
      expect(localStorage.getItem('cachedResource://class-clear-test?name=white-rabbit')).to.contain 'Alice In Wonderland'

    it 'should remove all entries from the cache except for those in an array specified by key', ->
      CachedResource.$clearCache exceptFor: type: 'combos'
      expect(localStorage.length).to.equal 3
      expect(localStorage.getItem('cachedResource://class-clear-test/array?type=combos')).to.contain 'liger'
      expect(localStorage.getItem('cachedResource://class-clear-test?name=liger')).to.contain 'Lion'
      expect(localStorage.getItem('cachedResource://class-clear-test?name=groler-bear')).to.contain 'Grizzly'

    describe 'and with pending writes', ->

      beforeEach ->
        $httpBackend.whenPOST('/animals/chinchilla').respond 500
        chinchilla = new CachedResource(name: 'chinchilla', fuzziness: 10)
        chinchilla.$save()
        $httpBackend.flush()

      it 'should not remove pending write from cache', ->
        CachedResource.$clearCache()
        expect(localStorage.length).to.equal 2
        expect(localStorage.getItem 'cachedResource://class-clear-test/write').to.contain 'chinchilla'
        expect(localStorage.getItem 'cachedResource://class-clear-test?name=chinchilla').to.contain 'fuzziness'

      it 'should remove pending write from cache if clearPendingWrites is set', ->
        CachedResource.$clearCache clearPendingWrites: yes
        expect(localStorage.length).to.equal 0
