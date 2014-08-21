describe 'class with custom actions', ->
  {CachedResource, $httpBackend} = {}

  beforeEach ->
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      CachedResource = $cachedResource 'class-with-custom-actions', '/mock/:id', {id: '@id'},
        charge:
          method: "PATCH"
        kiai:
          method: "put"

  it "has default actions", ->
    for action in ['get', 'query', 'save', 'remove', 'delete']
      expect( CachedResource ).to.have.property action

  it "has custom PATCH action", ->
    $httpBackend.expectPATCH('/mock/1', {id: 1, amount: '$77.00'}).respond 200
    expect( CachedResource ).to.have.property 'charge'
    CachedResource.charge id: 1, amount: '$77.00'
    $httpBackend.flush()

  it "has custom PUT action, even though the action was described in lowercase", ->
    $httpBackend.expectPUT('/mock/1', {id: 1, sound: 'Hi-ya!'}).respond 200
    expect( CachedResource ).to.have.property 'kiai'
    CachedResource.kiai id: 1, sound: 'Hi-ya!'
    $httpBackend.flush()

  describe 'resourceInstance', ->
    {resourceInstance} = {}

    beforeEach ->
      resourceInstance = new CachedResource id: 1, amount: '$77.00'

    it "has default actions", ->
      for action in ['$save', '$remove', '$delete']
        expect( resourceInstance ).to.have.property action

    it "has custom PATCH action", ->
      $httpBackend.expectPATCH('/mock/1', {id: 1, amount: '$77.00'}).respond 200
      expect( resourceInstance ).to.have.property '$charge'
      resourceInstance.$charge()
      $httpBackend.flush()

    it "has custom PUT action, even though the action was described in lowercase", ->
      $httpBackend.expectPUT('/mock/1', {id: 1, amount: '$77.00'}).respond 200
      expect( resourceInstance ).to.have.property '$kiai'
      resourceInstance.$kiai()
      $httpBackend.flush()
