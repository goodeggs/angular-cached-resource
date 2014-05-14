describe 'custom actions with addtional URL parameters', ->
  {Groups, $httpBackend} = {}

  beforeEach ->
    module('ngCachedResource')
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      Groups = $cachedResource 'custom-actions-with-additonal-url-parameters', '/groups/:id', {id: '@id'},
        saveByContact:
          method: "PUT"
          url: '/contacts/:contactId/groups/:id'

  afterEach ->
    $httpBackend.verifyNoOutstandingExpectation()
    $httpBackend.verifyNoOutstandingRequest()
    localStorage.clear()

  it 'sends a request to the custom URL', ->
    $httpBackend.expectPUT('/contacts/C3PO/groups/human_android_relations', { id: 'human_android_relations', location: 'Tattoine'}).respond 200
    Groups.saveByContact { contactId: 'C3PO' }, { id: 'human_android_relations', location: 'Tattoine' }
    $httpBackend.flush()
