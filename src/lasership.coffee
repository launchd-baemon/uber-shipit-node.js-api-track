{find} = require 'underscore'
moment = require 'moment'
{titleCase} = require 'change-case'
{ShipperClient} = require './shipper'

class LasershipClient extends ShipperClient

  constructor: (@options) ->
    super

  validateResponse: (response, cb) ->
    try
      response = JSON.parse response
      return cb(error: 'missing events') unless response['Events']?
      cb null, response
    catch error
      console.log "WARNING: parse error: #{JSON.stringify error}"

  presentAddress: (address) ->
    city = address['City']
    stateCode = address['State']
    postalCode = address['PostalCode']
    countryCode = address['Country']
    @presentLocation {city, stateCode, countryCode, postalCode}

  STATUS_MAP =
    'Delivered': ShipperClient.STATUS_TYPES.DELIVERED
    'OutForDelivery': ShipperClient.STATUS_TYPES.OUT_FOR_DELIVERY
    'Arrived': ShipperClient.STATUS_TYPES.EN_ROUTE
    'OrderReceived': ShipperClient.STATUS_TYPES.SHIPPING

  presentStatus: (eventType) ->
    STATUS_MAP[eventType] if eventType?

  getActivitiesAndStatus: (shipment) ->
    activities = []
    status = null
    rawActivities = shipment?['Events']
    for rawActivity in rawActivities or []
      location = @presentAddress rawActivity
      dateTime = rawActivity?['DateTime']
      timestamp = moment(dateTime).toDate() if dateTime?
      details = rawActivity?['EventShortText']
      if details? and location? and timestamp?
        activity = {timestamp, location, details}
        activities.push activity
      if !status
        status = @presentStatus rawActivity?['EventType']
    {activities, status}

  getEta: (shipment) ->
    return unless shipment?['EstimatedDeliveryDate']?
    moment(shipment['EstimatedDeliveryDate'], 'YYYY-MM-DD').toDate()

  getService: (shipment) ->

  getWeight: (shipment) ->
    return unless shipment?['Pieces']?.length
    piece = shipment['Pieces'][0]
    weight = "#{piece['Weight']}"
    units = piece['WeightUnit']
    weight = "#{weight} #{units}" if units?
    weight

  getDestination: (shipment) ->
    destination = shipment?['Destination']
    return unless destination?
    @presentAddress destination

  requestOptions: ({trackingNumber}) ->
    method: 'GET'
    uri: "http://www.lasership.com/track/#{trackingNumber}/json"


module.exports = {LasershipClient}
