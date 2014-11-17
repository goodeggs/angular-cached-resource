describe 'Updating existing cache value', ->
  {CachedResource, $httpBackend, $cachedResource, $timeout} = {}

  beforeEach ->
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      $timeout = $injector.get '$timeout'

  describe 'bound parameters match route parameters', ->

    beforeEach ->
      CachedResource = $cachedResource 'class-save-test', '/mock/:id', {id: '@id'}

    describe 'get resource with nested values', ->
      beforeEach ->
        CachedResource.$addToCache {
          id: 1
          magic:
            beans: ['old nested value']
        }, false

        $httpBackend.expectGET('/mock/1').respond
          id: 1
          magic: beans: ['new nested value']

      it 'updates nested values without changing the memory reference', ->
        resource = CachedResource.get {id: 1}
        cachedBeans = resource.magic.beans
        $httpBackend.flush()
        expect(cachedBeans[0]).to.equal 'new nested value'

    describe 'query resource with nested values', ->
      beforeEach ->
        CachedResource.$addArrayToCache {type: 'foo'}, [
          id: 1
          magic: beans: ['old nested value']
        ], false

        $httpBackend.expectGET('/mock?type=foo').respond [
          id: 1
          magic: beans: ['new nested value']
        ]

      it 'updates nested values without changing the memory reference', ->
        resource = CachedResource.query {type: 'foo'}
        cachedBeans = resource[0].magic.beans
        $httpBackend.flush()
        expect(cachedBeans[0]).to.equal 'new nested value'

    describe 'query resource with nested array', ->
      beforeEach ->
        CachedResource.$addArrayToCache {type: 'foo'}, [
          id: 1
          magic: beans: ['item 1', 'item 2', 'item 3']
        ], false

        $httpBackend.expectGET('/mock?type=foo').respond [
          id: 1
          magic: beans: ['item 2', 'item 1']
        ]

      it 'updates nested array', ->
        resource = CachedResource.query {type: 'foo'}
        cachedBeans = resource[0].magic.beans
        $httpBackend.flush()
        expect(cachedBeans[0]).to.equal 'item 2'
        expect(cachedBeans[1]).to.equal 'item 1'
        expect(cachedBeans.length).to.equal 2

  describe 'bound parameters named differntly than route parameters', ->
    describe 'Updating existing cache value', ->
      beforeEach ->
        CachedResource = $cachedResource 'class-save-test', '/mock/:routeId', {routeId: '@_id'}

      describe 'get resource with nested values', ->
        beforeEach ->
          CachedResource.$addToCache {
            _id: 1
            magic:
              beans: ['old nested value']
          }, false

          $httpBackend.expectGET('/mock/1').respond
            _id: 1
            magic: beans: ['new nested value']

        it 'updates nested values without changing the memory reference', ->
          resource = CachedResource.get {routeId: 1}
          cachedBeans = resource.magic.beans
          $httpBackend.flush()
          expect(cachedBeans[0]).to.equal 'new nested value'

      describe 'query resource with nested values', ->
        beforeEach ->
          CachedResource.$addArrayToCache {type: 'foo'}, [
            _id: 1
            magic: beans: ['old nested value']
          ], false

          $httpBackend.expectGET('/mock?type=foo').respond [
            _id: 1
            magic: beans: ['new nested value']
          ]

        it 'updates nested values without changing the memory reference', ->
          resource = CachedResource.query {type: 'foo'}
          cachedBeans = resource[0].magic.beans
          $httpBackend.flush()
          expect(cachedBeans[0]).to.equal 'new nested value'

      describe 'query resource with nested array', ->
        beforeEach ->
          CachedResource.$addArrayToCache {type: 'foo'}, [
            _id: 1
            magic: beans: ['item 1', 'item 2', 'item 3']
          ], false

          $httpBackend.expectGET('/mock?type=foo').respond [
            _id: 1
            magic: beans: ['item 2', 'item 1']
          ]

        it 'updates nested array', ->
          resource = CachedResource.query {type: 'foo'}
          cachedBeans = resource[0].magic.beans
          $httpBackend.flush()
          expect(cachedBeans[0]).to.equal 'item 2'
          expect(cachedBeans[1]).to.equal 'item 1'
          expect(cachedBeans.length).to.equal 2

