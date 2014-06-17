describe '$cachedResource.clearAll()', ->
  {$cachedResource, $httpBackend} = {}

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
      for category, example of {animal: 'cuttlefish', vegetable: 'romanesco', mineral: 'gneiss'}
        $httpBackend.whenGET(///^\/#{category}///).respond 200, {example}
        CachedResource = $cachedResource "clearing-cache-#{category}", "/#{category}/:id", id: '@id'
        for i in [0..5]
          CachedResource.get id: i
          $httpBackend.flush()

    it 'removes all cache entries', ->
      $cachedResource.clearAll()
      expect(localStorage.length).to.equal 0

    it 'removes all cache entries with exceptions', ->
      $cachedResource.clearAll exceptFor: ['clearing-cache-animal', 'clearing-cache-vegetable']
      expect(localStorage.length).to.equal 12

    describe 'and something else in localStorage', ->

      beforeEach ->
        localStorage.setItem('shoop', 'de whoop')

      it 'leaves unrelated localStorage entries alone', ->
        $cachedResource.clearAll()
        expect(localStorage.getItem('shoop')).to.equal 'de whoop'

    describe 'and with pending writes', ->

      beforeEach ->
        $httpBackend.whenPOST('/phase/1').respond 500
        Phase = $cachedResource "clearing-cache-phase", "/phase/:id", id: '@id'
        plasma = new Phase id: 1, example: 'plasma'
        plasma.$save()
        $httpBackend.flush()

      it 'should not remove pending write from cache', ->
        $cachedResource.clearAll()
        expect(localStorage.length).to.equal 2
        expect(localStorage.getItem 'cachedResource://clearing-cache-phase/write').to.contain '1'
        expect(localStorage.getItem 'cachedResource://clearing-cache-phase?id=1').to.contain 'plasma'
