describe 'cacheResource', ->
  {cacheResource, $httpBackend} = {}

  beforeEach ->
    module('cachedResource', 'ngResource')
    inject ($injector) ->
      cacheResource = $injector.get 'cacheResource'
      $httpBackend = $injector.get '$httpBackend'

  describe 'with empty cache', ->
    {resource} = {}

    beforeEach ->
      CachedResource = cacheResource('/mock/:parameter')
      expect(CachedResource).to.have.key 'get'

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
