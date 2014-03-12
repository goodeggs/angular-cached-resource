describe 'cachedResource.query', ->
  {cachedResource, $httpBackend} = {}

  beforeEach ->
    module('cachedResource')
    inject ($injector) ->
      cachedResource = $injector.get 'cachedResource'
      $httpBackend = $injector.get '$httpBackend'

  describe 'with empty cache', ->
    {resource, items} = {}

    beforeEach ->
      CachedResource = cachedResource('/mock/color/:color')
      expect(CachedResource).to.have.property 'query'

      items = [
        {parameter: 1, magic: 'Here is the response'}
        {parameter: 2, magic: 'Here is the second response'}
      ]

      $httpBackend.when('GET', '/mock/color/red').respond items

      $httpBackend.expectGET '/mock/color/red'
      resource = CachedResource.query({color: 'red'})

    afterEach ->
      $httpBackend.verifyNoOutstandingExpectation()
      $httpBackend.verifyNoOutstandingRequest()
      localStorage.clear()

    it 'has a promise', ->
      expect(resource).to.have.property '$promise'
      $httpBackend.flush()

    it 'has an http promise', ->
      expect(resource).to.have.property '$httpPromise'
      $httpBackend.flush()

    it 'resolves promise from response', (done) ->
      resource.$promise.then ->
        expect(resource.length).to.equal 2

        first = resource[0]
        expect(first).to.have.property 'magic', 'Here is the response'
        done()

      $httpBackend.flush()

    it 'adds the response to local storage', ->
      $httpBackend.flush()

      cachedItems = JSON.parse localStorage.getItem '/mock/color/red'
      expect(cachedItems).to.deep.equal items

  describe 'given cached data', ->
    {cachedData} = {}

    beforeEach ->
      cachedData = [
        {parameter: 1, magic: 'I am the cache'}
        {parameter: 2, magic: 'I am the second cache'}
      ]
      localStorage.setItem '/mock/color/red', JSON.stringify cachedData

    describe 'offline', ->
      {resource} = {}

      beforeEach ->
        $httpBackend.when('GET', '/mock/color/red').respond [
          {parameter: 1, magic: 'Not a cache'}
          {parameter: 2, magic: 'Not a second cache'}
          {parameter: 3, magic: 'Not a third cache'}
        ]
        $httpBackend.expectGET '/mock/color/red'
        resource = cachedResource('/mock/color/:color').query({color: 'red'})

      it 'has data from the cache', ->
        expect(resource.length).to.equal 2

        first = resource[0]
        expect(first.magic).to.equal cachedData[0].magic

      it 'resolves promise from cache', (done) ->
        resource.$promise.then (data) ->
          expect(data[0].magic).to.equal cachedData[0].magic
          done()
        $httpBackend.flush()

    describe 'online', ->
      {resource, updatedData} = {}

      beforeEach ->
        updatedData = [
          {parameter: 1, magic: 'Updated cache'}
          {parameter: 2, magic: 'Updated second cache'}
          {parameter: 3, magic: 'Updated third cache'}
        ]
        $httpBackend.when('GET', '/mock/color/red').respond updatedData
        $httpBackend.expectGET '/mock/color/red'
        resource = cachedResource('/mock/color/:color').query({color: 'red'})

      it 'has data from the cache', ->
        expect(resource.length).to.equal cachedData.length
        first = resource[0]
        expect(first.magic).to.equal cachedData[0].magic

        $httpBackend.flush()

      describe '$promise', ->
        it 'resolves from cache', (done) ->
          resource.$promise.then (data) ->
            expect(data.length).to.equal cachedData.length
            expect(data[0].magic).to.equal cachedData[0].magic
            done()

          $httpBackend.flush()

      describe '$httpPromise', ->
        it 'fetches updated resource', (done) ->
          resource.$httpPromise.then (data) ->
            expect(data.length).to.equal updatedData.length
            expect(data[0].magic).to.equal updatedData[0].magic
            done()

          $httpBackend.flush()

        it 'updates the object in cache', ->
          $httpBackend.flush()

          data = JSON.parse localStorage.getItem '/mock/color/red'
          expect(data).to.deep.equal updatedData
