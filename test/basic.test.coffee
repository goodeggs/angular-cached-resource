describe 'cacheResource', ->
  {cacheResource, $httpBackend} = {}

  beforeEach ->
    module('cachedResource')
    inject ($injector) ->
      cacheResource = $injector.get 'cacheResource'
      $httpBackend = $injector.get '$httpBackend'

  describe '::get', ->
    describe 'with empty cache', ->
      {resource} = {}

      beforeEach ->
        CachedResource = cacheResource('/mock/:parameter')
        expect(CachedResource).to.have.property 'get'

        $httpBackend.when('GET', '/mock/1').respond
          parameter: 1
          magic: 'Here is the response'

        $httpBackend.expectGET '/mock/1'
        resource = CachedResource.get({parameter: 1})

      afterEach ->
        $httpBackend.verifyNoOutstandingExpectation()
        $httpBackend.verifyNoOutstandingRequest()
        localStorage.clear()

      it 'has a promise', ->
        expect(resource).to.have.property '$promise'
        $httpBackend.flush()

      it 'resolves promise from response', (done) ->
        resource.$promise.then ->
          expect(resource).to.have.property 'magic', 'Here is the response'
          done()

        $httpBackend.flush()

      it 'adds the response to local storage', ->
        $httpBackend.flush()

        cachedResponse = JSON.parse localStorage.getItem '/mock/1'
        expect(cachedResponse).to.deep.equal
          parameter: 1
          magic: 'Here is the response'

    describe 'given cached data', ->
      {cachedData} = {}

      beforeEach ->
        cachedData =
          parameter: 1
          magic: 'I am the cache'
        localStorage.setItem '/mock/1', JSON.stringify cachedData

      describe 'offline', ->
        {resource} = {}

        beforeEach ->
          $httpBackend.when('GET', '/mock/1').respond
            parameter: 1
            magic: 'Not a cache'
          $httpBackend.expectGET '/mock/1'
          resource = cacheResource('/mock/:parameter').get({parameter: 1})

        it 'has data from the cache', ->
          expect(resource).to.be.defined
          expect(resource.parameter).to.equal cachedData.parameter
          expect(resource.magic).to.equal cachedData.magic

      describe 'online', ->
        {resource, updatedData} = {}

        beforeEach ->
          updatedData =
            parameter: 1
            magic: 'Updated thing'
          $httpBackend.when('GET', '/mock/1').respond updatedData
          $httpBackend.expectGET '/mock/1'
          resource = cacheResource('/mock/:parameter').get({parameter: 1})

        it 'has data from the cache', ->
          expect(resource).to.be.defined
          expect(resource.parameter).to.equal cachedData.parameter
          expect(resource.magic).to.equal cachedData.magic

          $httpBackend.flush()

        it 'fetches updated resource', (done) ->
          resource.$promise.then (data) ->
            expect(data).to.be.defined
            expect(data.parameter).to.equal updatedData.parameter
            expect(data.magic).to.equal updatedData.magic
            done()

          $httpBackend.flush()

        it 'updates the object in cache', ->
          $httpBackend.flush()

          data = JSON.parse localStorage.getItem '/mock/1'
          expect(data).to.deep.equal updatedData

  describe '::query', ->
    describe 'with empty cache', ->
      {resource, items} = {}

      beforeEach ->
        CachedResource = cacheResource('/mock/color/:color')
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
          resource = cacheResource('/mock/color/:color').query({color: 'red'})

        it 'has data from the cache', ->
          expect(resource.length).to.equal 2

          first = resource[0]
          expect(first.magic).to.equal cachedData[0].magic

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
          resource = cacheResource('/mock/color/:color').query({color: 'red'})

        it 'has data from the cache', ->
          expect(resource.length).to.equal cachedData.length
          first = resource[0]
          expect(first.magic).to.equal cachedData[0].magic

          $httpBackend.flush()

        it 'fetches updated resource', (done) ->
          resource.$promise.then (data) ->
            expect(data.length).to.equal updatedData.length
            expect(data[0].magic).to.equal updatedData[0].magic
            done()

          $httpBackend.flush()

        it 'updates the object in cache', ->
          $httpBackend.flush()

          data = JSON.parse localStorage.getItem '/mock/color/red'
          expect(data).to.deep.equal updatedData

