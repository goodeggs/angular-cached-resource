describe 'custom actions with addtional URL parameters', ->
  {Group, $httpBackend} = {}

  beforeEach ->
    inject ($injector) ->
      $cachedResource = $injector.get '$cachedResource'
      $httpBackend = $injector.get '$httpBackend'
      Group = $cachedResource 'custom-actions-with-additonal-url-parameters', '/groups/:id', {id: '@id'},
        saveByContact:
          method: "PUT"
          url: '/contacts/:contactId/groups/:id'

  it 'sends a request to the custom URL', ->
    $httpBackend.expectPUT('/contacts/C-3PO/groups/cybot_galactica', { id: 'cybot_galactica', location: 'Etti IV'}).respond 200
    Group.saveByContact { contactId: 'C-3PO' }, { id: 'cybot_galactica', location: 'Etti IV' }
    $httpBackend.flush()

  it 'sends a request to the custom URL with an array', ->
    groups = []
    groups.push new Group id: 'cybot_galactica', location: 'Etti IV'
    groups.push new Group id: 'rebel_alliance', leader: 'Leia Organa'

    $httpBackend.expectPUT('/contacts/C-3PO/groups', [{ id: 'cybot_galactica', location: 'Etti IV'}, { id: 'rebel_alliance', leader: 'Leia Organa' }]).respond 200
    Group.saveByContact { contactId: 'C-3PO' }, groups
    $httpBackend.flush()
