describe 'resource instance returned by CachedResource.get', ->
  {CachedResource, $httpBackend, resourceInstance} = {}

  beforeEach ->
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = $cachedResource('class-get-test', '/mock/:id')

  describe 'when cache is empty', ->
    expectSuccessfulGET = ->
      $httpBackend.expectGET('/mock/1').respond magic: 'Here is the response'

    expectFailingGET = ->
      $httpBackend.expectGET('/mock/1').respond 500

    beforeEach ->
      resourceInstance = CachedResource.get id: 1

    describe 'has a $promise that', ->
      {$promise} = {}

      beforeEach ->
        expect(resourceInstance).to.have.property '$promise'
        {$promise} = resourceInstance

      it 'resolves when the request is complete', (done) ->
        expectSuccessfulGET()
        $promise.then ->
          expect(resourceInstance).to.have.property 'magic', 'Here is the response'
          done()
        $httpBackend.flush()

    describe 'has an $httpPromise that', ->
      {$httpPromise} = {}

      beforeEach ->
        expect(resourceInstance).to.have.property '$httpPromise'
        {$httpPromise} = resourceInstance

      it 'resolves when the request is complete', (done) ->
        expectSuccessfulGET()
        $httpPromise.then ->
          expect(resourceInstance).to.have.property 'magic', 'Here is the response'
          done()
        $httpBackend.flush()

      it 'is rejected when the request fails', (done) ->
        expectFailingGET()
        $httpPromise.catch (error) ->
          expect(error.status).to.equal 500
          done()
        $httpBackend.flush()

  describe 'when cache is full', ->
    beforeEach ->
      $httpBackend.expectGET('/mock/1').respond magic: 'Help, I have been added to a cache'
      CachedResource.get id: 1
      $httpBackend.flush()

    describe 'and connection is unavailable', ->
      beforeEach ->
        $httpBackend.expectGET('/mock/1').respond 500
        resourceInstance = CachedResource.get id: 1

      it 'immediately contains data from the cache', ->
        expect(resourceInstance.magic).to.equal 'Help, I have been added to a cache'
        $httpBackend.flush()

      it 'has a $promise that immediately resolves with the cached data', (done) ->
        resourceInstance.$promise.then (data) ->
          expect(data.magic).to.equal 'Help, I have been added to a cache'
          done()
        $httpBackend.flush()

      it 'has an $httpPromise that gets rejected', (done) ->
        resourceInstance.$httpPromise.catch (error) ->
          expect(error.status).to.equal 500
          done()
        $httpBackend.flush()

      it 'contains data from the cache even after the server returns the error', ->
        $httpBackend.flush()
        expect(resourceInstance.magic).to.equal 'Help, I have been added to a cache'

    describe 'and connection is available', ->
      beforeEach ->
        $httpBackend.expectGET('/mock/1').respond magic: 'I am updated now'
        resourceInstance = CachedResource.get id: 1

      it 'immediately contains data from the cache', ->
        expect(resourceInstance.magic).to.equal 'Help, I have been added to a cache'
        $httpBackend.flush()

      it 'has a $promise that immediately resolves with the cached data', (done) ->
        resourceInstance.$promise.then (data) ->
          expect(data.magic).to.equal 'Help, I have been added to a cache'
          done()
        $httpBackend.flush()

      it 'has an $httpPromise that gets resolved with the new data', (done) ->
        resourceInstance.$httpPromise.then (data) ->
          expect(data.magic).to.equal 'I am updated now'
          done()
        $httpBackend.flush()

      it 'updates the object in memory after HTTP request is made', ->
        $httpBackend.flush()
        expect(resourceInstance.magic).to.equal 'I am updated now'
