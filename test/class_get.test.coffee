describe 'CachedResource.get', ->
  {$cachedResource, $httpBackend} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'

  describe 'with empty cache', ->
    {resource} = {}

    beforeEach ->
      CachedResource = $cachedResource('class-get-test', '/mock/:parameter')
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

    it 'has a http promise', ->
      expect(resource).to.have.property '$httpPromise'
      $httpBackend.flush()

    it 'resolves promise from response', (done) ->
      resource.$promise.then ->
        expect(resource).to.have.property 'magic', 'Here is the response'
        done()

      $httpBackend.flush()

    it 'adds the response to local storage', ->
      $httpBackend.flush()

      cachedResponse = JSON.parse localStorage.getItem 'cachedResource://class-get-test?parameter=1'
      expect(cachedResponse.value).to.deep.equal
        parameter: 1
        magic: 'Here is the response'

  describe 'given cached data', ->
    {cachedData} = {}

    beforeEach ->
      cachedData =
        parameter: 1
        magic: 'I am the cache'
      localStorage.setItem 'cachedResource://class-get-test?parameter=1', JSON.stringify value: cachedData

    describe 'offline', ->
      {resource} = {}

      beforeEach ->
        $httpBackend.when('GET', '/mock/1').respond
          parameter: 1
          magic: 'Not a cache'
        $httpBackend.expectGET '/mock/1'
        resource = $cachedResource('class-get-test', '/mock/:parameter').get({parameter: 1})

      it 'has data from the cache', ->
        expect(resource).to.be.defined
        expect(resource.parameter).to.equal cachedData.parameter
        expect(resource.magic).to.equal cachedData.magic

      it 'resolves the promise with cached data', (done) ->
        resource.$promise.then (data) ->
          expect(data.magic).to.equal cachedData.magic
          done()
        $httpBackend.flush()

    describe 'online', ->
      {resource, updatedData} = {}

      beforeEach ->
        updatedData =
          parameter: 1
          magic: 'Updated thing'
        $httpBackend.when('GET', '/mock/1').respond updatedData
        $httpBackend.expectGET '/mock/1'
        resource = $cachedResource('class-get-test', '/mock/:parameter').get({parameter: 1})

      it 'has data from the cache', ->
        expect(resource).to.be.defined
        expect(resource.parameter).to.equal cachedData.parameter
        expect(resource.magic).to.equal cachedData.magic

        $httpBackend.flush()

      describe '$httpPromise', ->
        it 'fetches updated resource', (done) ->
          resource.$httpPromise.then (data) ->
            expect(data).to.be.defined
            expect(data.parameter).to.equal updatedData.parameter
            expect(data.magic).to.equal updatedData.magic
            done()

          $httpBackend.flush()

        it 'updates the object in cache', ->
          $httpBackend.flush()

          data = JSON.parse localStorage.getItem 'cachedResource://class-get-test?parameter=1'
          expect(data.value).to.deep.equal updatedData

      describe '$promise', ->
        it 'resolves with cached data', (done) ->
          resource.$promise.then (data) ->
            expect(data.magic).to.equal cachedData.magic
            done()
          $httpBackend.flush()

