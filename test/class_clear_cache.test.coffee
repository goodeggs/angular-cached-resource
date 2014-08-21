describe 'CachedResource.$clearCache()', ->
  {CachedResource, $cachedResource, $httpBackend, rabbits, combos} = {}

  beforeEach ->
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
    CachedResource = $cachedResource 'class-clear-test', '/animals/:name', {name: '@name'}

  describe 'with a populated cache', ->
    beforeEach ->
      CachedResource.$addArrayToCache type: 'fictional-rabbits', rabbits = [
        { name: 'white-rabbit', source: 'Alice In Wonderland' }
        { name: 'peppy-hare', source: 'Starfox' }
        { name: 'energizer-bunny', source: 'Energizer' }
        { name: 'frank', source: 'Donnie Darko' }
      ]
      CachedResource.$addArrayToCache type: 'combos', combos = [
        { name: 'liger', from: ['Lion', 'Tiger'] }
        { name: 'groler-bear', from: ['Grizzly Bear', 'Polar Bear'] }
      ]
      $httpBackend.expectGET('/animals?type=fictional-rabbits').respond rabbits
      $httpBackend.expectGET('/animals?type=combos').respond combos
      rabbits = CachedResource.query type: 'fictional-rabbits'
      combos = CachedResource.query type: 'combos'
      $httpBackend.flush()

    describe "when called with no arguments", ->
      it 'should remove all entries from the cache', ->
        CachedResource.$clearCache()
        expect(localStorage.length).to.equal 0

    describe "when called with `exceptFor` argument", ->
      it 'should remove all entries from the cache, except for those with given parameters', ->
        CachedResource.$clearCache({
          exceptFor: [{name: 'frank'}]
        })
        expect(localStorage.length).to.equal 1
        expect(localStorage.getItem('cachedResource://class-clear-test?name=frank')).to.contain 'Donnie Darko'

        CachedResource.$clearCache({
          exceptFor: {name: 'frank'}
        })
        expect(localStorage.length).to.equal 1
        expect(localStorage.getItem('cachedResource://class-clear-test?name=frank')).to.contain 'Donnie Darko'

      it 'should remove all entries from the cache, except for those specified by resource instance', ->
        CachedResource.$clearCache({
          exceptFor: rabbits[0...1]
        })
        expect(localStorage.length).to.equal 1
        expect(localStorage.getItem('cachedResource://class-clear-test?name=white-rabbit')).to.contain 'Alice In Wonderland'

        CachedResource.$clearCache({
          exceptFor: rabbits[0]
        })
        expect(localStorage.length).to.equal 1
        expect(localStorage.getItem('cachedResource://class-clear-test?name=white-rabbit')).to.contain 'Alice In Wonderland'

      describe "and with `isArray: true, clearChildren: true` argument", ->
        it 'should remove all entries from the cache, except for the given array (but entries stored in that array will be cleared anyway)', ->
          CachedResource.$clearCache({
            exceptFor: {type: 'combos'},
            isArray: true,
            clearChildren: true
          })
          expect(localStorage.length).to.equal 1
          expect(localStorage.getItem('cachedResource://class-clear-test/array?type=combos')).to.contain 'liger'
          expect(localStorage.getItem('cachedResource://class-clear-test?name=liger')).to.equal null
          expect(localStorage.getItem('cachedResource://class-clear-test?name=groler-bear')).to.equal null

      describe "and with `isArray: true, clearChildren: false` argument", ->
        it 'should remove all entries from the cache, except for the given array and entries stored in that array', ->
          CachedResource.$clearCache({
            exceptFor: {type: 'combos'},
            isArray: true,
            clearChildren: false
          })
          expect(localStorage.length).to.equal 3
          expect(localStorage.getItem('cachedResource://class-clear-test/array?type=combos')).to.contain 'liger'
          expect(localStorage.getItem('cachedResource://class-clear-test?name=liger')).to.contain 'Lion'
          expect(localStorage.getItem('cachedResource://class-clear-test?name=groler-bear')).to.contain 'Grizzly'

    describe "when called with `where` argument", ->
      it 'should remove entries with given parameters', ->
        CachedResource.$clearCache({
          where: [{name: 'frank'}]
        })
        expect(localStorage.getItem('cachedResource://class-clear-test?name=frank')).to.equal null

        CachedResource.$clearCache({
          where: {name: 'frank'}
        })
        expect(localStorage.getItem('cachedResource://class-clear-test?name=frank')).to.equal null

      it 'should remove entries specified by resource instance', ->
        CachedResource.$clearCache({
          where: rabbits[0...1]
        })
        expect(localStorage.getItem('cachedResource://class-clear-test?name=white-rabbit')).to.equal null

        CachedResource.$clearCache({
          where: rabbits[0]
        })
        expect(localStorage.getItem('cachedResource://class-clear-test?name=white-rabbit')).to.equal null

      describe "and with `isArray: true, clearChildren: true` arguments", ->
        it 'should remove given array entry and all entries stored in that array', ->
          CachedResource.$clearCache({
            where: {type: 'combos'},
            isArray: true,
            clearChildren: true
          })
          expect(localStorage.getItem('cachedResource://class-clear-test/array?type=combos')).to.equal null
          expect(localStorage.getItem('cachedResource://class-clear-test?name=liger')).to.equal null
          expect(localStorage.getItem('cachedResource://class-clear-test?name=groler-bear')).to.equal null

      describe "and with `isArray: true, clearChildren: false` arguments", ->
        it 'should remove given array entry, but not the entries stored in that array', ->
          CachedResource.$clearCache({
            where: {type: 'combos'},
            isArray: true,
            clearChildren: false
          })
          expect(localStorage.getItem('cachedResource://class-clear-test/array?type=combos')).to.equal null
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

  describe 'cached resource with parameters that do not match the underlying object', ->
    {RouteResource, easy, hard} = {}

    beforeEach ->
      RouteResource = $cachedResource 'route-resource', '/routes/:routeId', {routeId: '@_id'}

    describe 'populated cache', ->
      beforeEach ->
        $httpBackend.whenGET('/routes?type=easy').respond 200, [
          { _id: 1, style: 'direct' }
          { _id: 2, style: 'teleportation' }
        ]
        $httpBackend.whenGET('/routes?type=hard').respond 200, [
          { _id: 3, style: 'crawl' }
        ]

        easy = RouteResource.query type: 'easy'
        hard = RouteResource.query type: 'hard'
        $httpBackend.flush()

      describe "when called with no arguments", ->
        it 'should remove all entries from the cache', ->
          RouteResource.$clearCache()
          expect(localStorage.length).to.equal 0

      describe "when called with `exceptFor, isArray: true` arguments", ->
        it 'should remove all entries from the cache, except for the specified array and entries stored in that array', ->
          RouteResource.$clearCache exceptFor: {type: 'easy'}, isArray: true
          expect(localStorage.length).to.equal 3
          expect(localStorage.getItem('cachedResource://route-resource/array?type=easy')).to.contain 1
          expect(localStorage.getItem('cachedResource://route-resource?routeId=1')).to.contain 'direct'
          expect(localStorage.getItem('cachedResource://route-resource?routeId=2')).to.contain 'teleportation'
