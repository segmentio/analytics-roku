' Constructor
'
' Required params:
' @config configuration, must include writeKey. Optionally you can include:
' debug=true to receive debug logging
' queueSize=[size] to limit how many messages get queued before performing a send operation
' retryLimit=[size] to limit the number of retries for a message
' requestPoolSize=[size] to set the number of reusable request objects
' apiHost Segment.io base url
' factories associative array that contains factory to create each integration
' defaultSettings associative array which in can include the following:
' integrations associative array that contains configuration for each integration
' @port message port
function SegmentAnalytics(config as Object, port as Object) as Object
  log = _SegmentAnalytics_Logger()

  if _SegmentAnalytics_checkInvalidConfig(config, log) then
    return invalid
  end if

  updatedConfig = _SegmentAnalytics_configWithDefaultValues(config)

  log.debugEnabled = updatedConfig.debug

  this = {
    'public functions
    identify: _SegmentAnalytics_identify
    track: _SegmentAnalytics_track
    screen: _SegmentAnalytics_screen
    group: _SegmentAnalytics_group
    alias: _SegmentAnalytics_alias
    flush: _SegmentAnalytics_flush
    handleRequestMessage: _SegmentAnalytics_handleRequestMessage
    checkRequestQueue: _SegmentAnalytics_checkRequestQueue

    'public variables
    version: "2.0.0"
    config: updatedConfig
    log: log

    'private functions
    _checkValidId: _SegmentAnalytics_checkValidId
    _addValidFieldsToAA: _SegmentAnalytics_addValidFieldsToAA
    _addValidFieldToAA: _SegmentAnalytics_addValidFieldToAA
    _configBundledIntegrations: _SegmentAnalytics_configBundledIntegrations
  }
  this._configBundledIntegrations()
  this._integrationManager = _SegmentAnalytics_IntegrationsManager(this.config, this, port)

  return this
end function

' Identifies the user and device upon service startup
' Required params:
' @userId string to identify the user with
' Optional params:
' @traits
' @options
sub _SegmentAnalytics_identify(userId as String, traits = invalid as Dynamic, options = invalid as Dynamic)
  data = {
    "type": "identify"
    "userId": userId
  }

  m._addValidFieldToAA(data, "traits", traits)
  m._addValidFieldsToAA(data, ["anonymousId", "context", "integrations", "messageId", "timestamp"], options)

  if not m._checkValidId(data) then return

  if data["messageId"] = invalid
    data["messageId"] = createObject("roDeviceInfo").getRandomUUID()
  end if
  m._integrationManager.identify(data)
end sub

' Tracks an event from the application
' Required params:
' @event
' Optional params:
' @properties
' @options
sub _SegmentAnalytics_track(event as String, properties = invalid as Dynamic, options = {} as Object)
  data = {
    "type": "track"
    "event": event
  }
  m._addValidFieldToAA(data, "properties", properties)
  m._addValidFieldsToAA(data, ["userId", "anonymousId", "context", "integrations", "messageId", "timestamp"], options)

  if not m._checkValidId(data) then return
  
  if data["messageId"] = invalid
    data["messageId"] = createObject("roDeviceInfo").getRandomUUID()
  end if

  m._integrationManager.track(data)
end sub

' Determines the screen the application is on
' Note: Only either one of the @name or @category param is required. For example, if @name is supplied then @category
' is not needed and vice-versa.
' Required params:
' @name
' @category
' Optional params:
' @properties
' @options
sub _SegmentAnalytics_screen(name = invalid as Dynamic, category = invalid as Dynamic, properties = invalid as Dynamic, options = {} as Object)
  data = {
    "type": "screen"
  }

  if name = invalid and category = invalid
    m.log.error("Error missing name or category in screen call")
    return
  end if

  m._addValidFieldToAA(data, "name", name)
  m._addValidFieldToAA(data, "category", category)
  m._addValidFieldToAA(data, "properties", properties)
  m._addValidFieldsToAA(data, ["userId", "anonymousId", "context", "integrations", "messageId", "timestamp"], options)

  if not m._checkValidId(data) then return

  if data["messageId"] = invalid
    data["messageId"] = createObject("roDeviceInfo").getRandomUUID()
  end if

  m._integrationManager.screen(data)
end sub

' Determines the organization on who is leveraging this library
' Required params:
' @groupId
' @userId
' Optional params:
' @traits
' @options
sub _SegmentAnalytics_group(userId as String, groupId as String, traits = invalid as Dynamic, options = {} as Object)
  data = {
    "type": "group"
    "userId": userId
    "groupId": groupId
  }

  m._addValidFieldToAA(data, "traits", traits)
  m._addValidFieldsToAA(data, ["anonymousId", "context", "integrations", "messageId", "timestamp"], options)

  if not m._checkValidId(data) then return

  if data["messageId"] = invalid
    data["messageId"] = createObject("roDeviceInfo").getRandomUUID()
  end if

  m._integrationManager.group(data)
end sub

' Helps segment analytics merge multiple identities from one user within the running application
' Required params:
' @newId
' @options
sub _SegmentAnalytics_alias(userId as String, options = {} as Object)
  data = {
    "type": "alias"
    "userId": userId
  }

  m._addValidFieldsToAA(data, ["previousId", "anonymousId", "context", "integrations", "messageId", "timestamp"], options)

  if not m._checkValidId(data) then return

  if data["messageId"] = invalid
    data["messageId"] = createObject("roDeviceInfo").getRandomUUID()
  end if

  m._integrationManager.alias(data)
end sub

sub _SegmentAnalytics_flush()
  m._integrationManager.flush()
end sub

sub _SegmentAnalytics_handleRequestMessage(message as Object, currentTime as Integer)
  m._integrationManager.handleRequestMessage(message, currentTime)
end sub

sub _SegmentAnalytics_checkRequestQueue(currentTime as Integer)
    m._integrationManager.checkRequestQueue(currentTime)
end sub

'Validates required configuration fields
function _SegmentAnalytics_checkInvalidConfig(config, log as Object) as Boolean
  isInvalid = false

  if config = invalid then
    log.error("No config found")
    isInvalid = true
  else if type(config) <> "roAssociativeArray"
    log.error("Invalid config type found")
    isInvalid = true
  else if config.count() = 0 then
    log.error("Empty config object")
    isInvalid = true
  else if config.writeKey = invalid then
    log.error("No writeKey found in config object")
    isInvalid = true
  else if type(config.writeKey) <> "roString" and type(config.writeKey) <> "String" then
    log.error("Invalid writeKey type found in config object")
    isInvalid = true
  else if config.writeKey.len() < 1 then
    log.error("Empty writeKey string in config object")
    isInvalid = true
  end if

  return isInvalid
end function

'Create configuration with default values for any values not explicitly included
function _SegmentAnalytics_configWithDefaultValues(config as Object) as Object
  updatedConfig = config

  if config.debug = invalid or (config.debug <> false and config.debug <> true) then
    updatedConfig.debug = false
  end if

  if config.queueSize = invalid or (type(config.queueSize) <> "roInteger" and type(config.queueSize) <> "roInt") or config.queueSize < 1 then
    updatedConfig.queueSize = 1
  end if

  if config.retryLimit = invalid or (type(config.retryLimit) <> "roInteger" and type(config.retryLimit) <> "roInt") or config.retryLimit < -1 then
    updatedConfig.retryLimit = 1
  end if

  if config.requestPoolSize = invalid or (type(config.requestPoolSize) <> "roInteger" and type(config.requestPoolSize) <> "roInt") or config.requestPoolSize < 1 then
    updatedConfig.requestPoolSize = 1
  end if 

  if config.apiHost = invalid or (type(config.apiHost) <> "roString" and type(config.apiHost) <> "String") then
    updatedConfig.apiHost = "https://api.segment.io"
  end if

  if config.factories = invalid or type(config.factories) <> "roAssociativeArray" then
    updatedConfig.factories = {}
  end if

  if config.defaultSettings = invalid or type(config.defaultSettings) <> "roAssociativeArray" then
    updatedConfig.defaultSettings = {}
  end if

  if config.defaultSettings.integrations = invalid or type(config.defaultSettings.integrations) <> "roAssociativeArray" then 
    updatedConfig.defaultSettings.integrations = {}
  end if   

  return updatedConfig 
end function

'Make sure each integration has a valid factory function and settings object
sub _SegmentAnalytics_configBundledIntegrations()
  bundledFactories = {}
  for each name in m.config.factories.keys()
    settings = m.config.defaultSettings.integrations[name] 
    factory = m.config.factories[name]

    if factory <> invalid and getInterface(factory, "ifFunction") <> invalid and settings <> invalid and type(settings) = "roAssociativeArray" then
      bundledFactories[name] = factory 
    else if factory = invalid and getInterface(factory, "ifFunction") = invalid 
      m.log.error("Could not create device mode integration for " + name + " due to missing settings in configuration")
    else
      m.log.error("Could not create device mode integration for " + name + " due to missing factory in configuration")
    end if
  end for
  m.config.factories = bundledFactories
end sub

'Checks if we have a valid user of anonymous id for the request
function _SegmentAnalytics_checkValidId(data as Dynamic) as Boolean
  hasUserId = false
  hasAnonId = false

  if data.userId <> invalid and (type(data.userId) = "roString" or type(data.userId) = "String") then
    hasUserId = data.userId.len() > 0
  end if

  if data.anonymousId <> invalid and (type(data.anonymousId) <> "roString" or type(data.anonymousId) <> "String") then
    hasAnonId = data.anonymousId.len() > 0
  end if

  if not hasUserId and not hasAnonId then
    callType = "unknown"
    if not data.type = invalid and (type(data.type) = "roString" or type(data.type) = "String")
      callType = data.type
    end if
      m.log.error("No user or anonymous id found in [" + callType + "] call")
    return false
  end if

  return true
end function

'Adds multiple fields to the data request body if exists otherwise logs debug message
sub _SegmentAnalytics_addValidFieldsToAA(data as Object, fields as Object, inputData as Object)
  if data = invalid or not type(data) = "roAssociativeArray" then return
  if fields = invalid or not type(fields) = "roArray" or fields.count() = 0 then return
  if inputData = invalid or not type(inputData) = "roAssociativeArray" or inputData.count() = 0 then return

  for each field in fields
    m._addValidFieldToAA(data, field, inputData[field])
  end for
end sub

'Add field to data request body if exists otherwise logs debug message 
sub _SegmentAnalytics_addValidFieldToAA(map as Object, field as String, value as Dynamic)
    if value <> invalid and field.len() > 0 and map[field] = invalid then
        if type(value) = "String" or type(value) = "roString"
            if value <> invalid and value.len() > 0 then
                map[field] = value
            end if
        else
            map[field] = value
        end if
    else
      fieldType = "unknown"
      mapType = "unknown"
      if field <> invalid and (type(field) = "roString" or type(field) = "String") then
        fieldType = field
      end if

      if map <> invalid and map.type <> invalid and (type(map.type) = "roString" or type(map.type) = "String") then
        mapType = map.type
      end if
 
      m.log.debug("No field (" + fieldType  + ") for (" + mapType + ") call to add in data request")
    end if
end sub

' Constructor
'
' Required params:
' @config configuration, must include writeKey. Optionally you can include:
' debug=true to receive debug logging
' queueSize=[size] to limit how many messages get queued before performing a send operation
' retryLimit=[size] to limit the number of retries for a message
' requestPoolSize=[size] to set the number of reusable request objects
' apiHost Segment.io base url
' factories associative array that contains factory to create each integration
' defaultSettings associative array which in can include the following:
' integrations associative array that contains configuration for each integration
' @analytics SegmentAnalytics instance
' @port message port
function _SegmentAnalytics_IntegrationsManager(config as Object, analytics as Object, port as Object) as Object
  this =  {
    'public functions
    identify: _SegmentAnalytics_IntegrationsManager_identify
    track: _SegmentAnalytics_IntegrationsManager_track
    screen: _SegmentAnalytics_IntegrationsManager_screen
    group: _SegmentAnalytics_IntegrationsManager_group
    alias: _SegmentAnalytics_IntegrationsManager_alias
    flush: _SegmentAnalytics_IntegrationsManager_flush
    handleRequestMessage: _SegmentAnalytics_IntegrationsManager_handleRequestMessage
    checkRequestQueue: _SegmentAnalytics_IntegrationsManager_checkRequestQueue

    'private functions
    _callIntegrations: _SegmentAnalytics_IntegrationsManager_callIntegrations
    _isIntegrationEnabled: _SegmentAnalytics_IntegrationsManager_isIntegrationEnabled
    _createIntegrations: _SegmentAnalytics_IntegrationsManager_createIntegrations

    'private variables
    _log: analytics.log
  }
  factories = config.factories
  factories["Segment.io"] = _SegmentAnalytics_SegmentIntegrationFactory
  config.factories = factories

  this._integrations = this._createIntegrations(config, analytics, port)

  return this
end function

sub _SegmentAnalytics_IntegrationsManager_identify(data as Object)
  m._callIntegrations("identify", data)
end sub

sub _SegmentAnalytics_IntegrationsManager_track(data as Object)
  m._callIntegrations("track", data)
end sub

sub _SegmentAnalytics_IntegrationsManager_screen(data as Object)
  m._callIntegrations("screen", data)
end sub

sub _SegmentAnalytics_IntegrationsManager_group(data as Object)
  m._callIntegrations("group", data)
end sub

sub _SegmentAnalytics_IntegrationsManager_alias(data as Object)
  m._callIntegrations("alias", data)
end sub

sub _SegmentAnalytics_IntegrationsManager_flush()
  m._callIntegrations("flush")
end sub

'Handle all responses and forward it to each enabled integration
sub _SegmentAnalytics_IntegrationsManager_handleRequestMessage(message as Object, currentTime as Integer)
  for each integration in m._integrations
    if m._isIntegrationEnabled(integration, "handleRequestMessage") then
      try
        integration.handleRequestMessage(message, currentTime)
      catch e
        m._log.error("Exception calling integration " + integration.key + " for handleRequestMessage. Exception: " + e.message)
      end try
    else
      m._log.debug("Not sending call to " + integration.key + " because it does not respond to handleRequestMessage")
    end if
  end for 
end sub

'Checks all enabled integrations for failed requests that need to be resent
sub _SegmentAnalytics_IntegrationsManager_checkRequestQueue(currentTime as Integer)
  for each integration in m._integrations
    if m._isIntegrationEnabled(integration, "checkRequestQueue") then
      try
        integration.checkRequestQueue(currentTime)
      catch e
        m._log.error("Exception calling integration " + integration.key + " for checkRequestQueue. Exception: " + e.message)
      end try  
    else
      m._log.debug("Not sending call to " + integration.key + " because it does not respond to checkRequestQueue")
    end if
  end for 
end sub

'Iterates through integrations invoking the given function name if enabled/existing
sub _SegmentAnalytics_IntegrationsManager_callIntegrations(name as String, data = invalid)
  for each integration in m._integrations
    if m._isIntegrationEnabled(integration, name, data) then
      try
        if data <> invalid then
          integration[name](data)
        else
          integration[name]()
        end if   
      catch e
        m._log.error("Exception calling integration " + integration.key + " for event type " + name + ". Exception: " + e.message)
      end try 
    else
      m._log.debug("Not sending call to " + integration.key + " because it does not respond to " + name)  
    end if
  end for  
end sub

'Determine if integration is enabled to process event 
function _SegmentAnalytics_IntegrationsManager_isIntegrationEnabled(integration as Object, name as String, data = invalid) as Boolean
  if integration[name] <> invalid and getInterface(integration[name], "ifFunction") <> invalid then
    if integration.key = "Segment.io" then
      return true
    else if data = invalid or (data.integrations <> invalid and (data.integrations[integration.key] = true or data.integrations["all"] = true or data.integrations["All"] = true))
      return true
    else
      return false
    end if
  else
    return false
  end if
end function

'Creates integrations using factories defined in SegmentAnalyticsTask.xml and references any settings from config.defaultSettings.integrations[factory key]
'Note: the Segment.io integration is created by default
function _SegmentAnalytics_IntegrationsManager_createIntegrations(config as Object, analytics as Object, port as Object) as Object
  integrations = []
  for each name in config.factories.keys()
    settings = config.defaultSettings.integrations[name]
    factory = config.factories[name]

    try
      integrations.push(factory(settings, analytics, port))
    catch e
      m._log.error("Exception calling device mode integration " + name + " factory. Exception: " + e.message)
    end try
  end for

  return integrations
end function

' Constructor
'
' Factory to generate _SegmentAnalytics_SegmentIntegration instance for Segment.io destination
'
' Required params:
' @setting integration settings
' @analytics SegmentAnalytics instance
' @port message port
function _SegmentAnalytics_SegmentIntegrationFactory(settings as Object, analytics as Object, port as Object) as Object
  bundledIntegrations = []
  for each integration in analytics.config.factories.keys()
    bundledIntegrations.push(integration)
  end for

  return _SegmentAnalytics_SegmentIntegration(analytics.config, bundledIntegrations, analytics.version, analytics.log, port)
end function

' Constructor
'
' Segment.io destination integration

' Required params:
' @settings must include writeKey. Optionally you can include:
' debug=true to receive debug logging
' queueSize=[size] to limit how many messages get queued before performing a send operation
' retryLimit=[size] to limit the number of retries for a message
' requestPoolSize=[size] to set the number of reusable request objects
' apiHost Segment.io base url
' @bundledIntegrations name of other included integrations
' @version library version
' @log message logger
' @port message port
function _SegmentAnalytics_SegmentIntegration(settings as Object, bundledIntegrations as Object, version as String, log as Object, port as Object) as Object
  return {
    'public functions
    identify: _SegmentAnalytics_SegmentIntegration_queueMessage
    track: _SegmentAnalytics_SegmentIntegration_queueMessage
    screen: _SegmentAnalytics_SegmentIntegration_queueMessage
    group: _SegmentAnalytics_SegmentIntegration_queueMessage
    alias: _SegmentAnalytics_SegmentIntegration_queueMessage
    flush: _SegmentAnalytics_SegmentIntegration_flush
    handleRequestMessage: _SegmentAnalytics_SegmentIntegration_handleRequestMessage
    checkRequestQueue: _SegmentAnalytics_SegmentIntegration_checkRequestQueue

    'public variables
    key: "Segment.io"

    'private functions
    _createRequest: _SegmentAnalytics_SegmentIntegration_createRequest
    _createPostOptions: _SegmentAnalytics_SegmentIntegration_createPostOptions
    _sendRequest: _SegmentAnalytics_SegmentIntegration_sendRequest
    _setRequestAsRetry: _SegmentAnalytics_SegmentIntegration_setRequestAsRetry
    _getDataBodySize: _SegmentAnalytics_SegmentIntegration_getDataBodySize
    _minNumber: _SegmentAnalytics_SegmentIntegration_minNumber
    _getUrlTransfer: _SegmentAnalytics_SegmentIntegration_getUrlTransfer
    _releaseUrlTransfer: _SegmentAnalytics_SegmentIntegration_releaseUrlTransfer
    _createMessageIntegrations: _SegmentAnalytics_SegmentIntegration_createMessageIntegrations

    'private variables
    _writeKey: settings.writeKey
    _queueSize: settings.queueSize
    _retryLimit: settings.retryLimit
    _requestPoolSize: settings.requestPoolSize
    _apiUrl: settings.apiHost + "/v1/batch"
    _bundledIntegrations: bundledIntegrations
    _log: log
    _port: port
    _device: createObject("roDeviceInfo")
    _libraryName: "analytics-roku"
    _libraryVersion: version
    _messageQueue: []
    _maxBatchByteSize: 500000
    _maxMessageByteSize: 32000
    _serverRequestsById: {}
    _inProgressId: invalid
    _requestPool: []
  }
end function

'Defines which integrations will be used and either pushes it to the message queue or sends out a request
sub _SegmentAnalytics_SegmentIntegration_queueMessage(data)
  if data = invalid then
    m._log.error("Data missing when queuing message")
    return
  end if

  requestData = parseJSON(formatJSON(data))
  requestData.integrations = m._createMessageIntegrations(requestData.integrations)
  
  if m._getDataBodySize(requestData) > m._maxMessageByteSize then
    m._log.error("Message size over 32KB")
  else
    tempQueue = []
    tempQueue.append(m._messageQueue)
    tempQueue.push(requestData)
    m._log.debug("Current batch size is: ")
    m._log.debug(strI(m._getDataBodySize(m._messageQueue)))
    m._log.debug("New batch size is: ")
    m._log.debug(strI(m._getDataBodySize(tempQueue)))

    if m._messageQueue.count() > 0 and m._getDataBodySize(tempQueue) > m._maxBatchByteSize then
      m._sendRequest(m._messageQueue)
      m._messageQueue = []

      m._log.debug("---- Queueing message after sending a request -----")
      m._log.debug(formatJSON(requestData))
      m._messageQueue.push(requestData)
    else
      m._log.debug("---- Queueing message -----")
      m._log.debug(formatJSON(requestData))
      m._messageQueue.push(requestData)

      if m._messageQueue.count() = m._queueSize then
        m._sendRequest(m._messageQueue)
        m._messageQueue = []
      end if
    end if
  end if
end sub

'Send out data stored in message queue and empty it
sub _SegmentAnalytics_SegmentIntegration_flush()
  m._log.debug("clearing message queue")
  if m._messageQueue.count() > 0
    m._sendRequest(m._messageQueue)
    m._messageQueue = []
  end if
end sub

'Handle responses from Segment.io api
sub _SegmentAnalytics_SegmentIntegration_handleRequestMessage(message as Object, currentTime as Integer)
  if m._serverRequestsById = invalid then return
  responseCode = message.getResponseCode()
  requestId = strI(message.getSourceIdentity(), 10)
  request = m._serverRequestsById[requestId]
  
  if (responseCode = 429 or responseCode >= 500) and request <> invalid and request.retryCount < m._retryLimit then
    m._setRequestAsRetry(request, currentTime)
  else if request <> invalid then
    request.handleMessage(message)
    m._inProgressId = invalid
    m._releaseUrlTransfer(m._serverRequestsById[requestId])
    m._serverRequestsById.delete(requestId)
  end if
end sub

'Check if any requests need to be sent out/resent
sub _SegmentAnalytics_SegmentIntegration_checkRequestQueue(currentTime as Integer)
  if m._inProgressId <> invalid then return

  if m._serverRequestsById.count() > 0 then
    for each requestId in m._serverRequestsById.keys()
      nextRetryTime = m._serverRequestsById[requestId].nextRetryTime
      if currentTime > nextRetryTime
        if nextRetryTime > 0
          m._log.debug("Retrying send request: " + requestId)
        else
          m._log.debug("Sending request: " + requestId)
        end if
        m._log.debug(formatJSON(m._serverRequestsById[requestId]._data))
        m._serverRequestsById[requestId].send()
        m._inProgressId = requestId
        return
      end if
    end for
  end if
end sub

'Send messageQueue contents to Segment.io
sub _SegmentAnalytics_SegmentIntegration_sendRequest(messageQueue as Object)
  requestOptions = m._createPostOptions(messageQueue)
  requestOptions.urlTransfer = m._getUrlTransfer()

  request = m._createRequest(requestOptions)

  if m._serverRequestsById.count() >= 1000 then
    firstKey = m._serverRequestsById.keys()[0]
    m._log.debug("----- Request queue is too full dropping request -----")
    m._log.debug(formatJSON(m._serverRequestsById[firstKey].data))
    m._serverRequestsById.delete(firstKey)
  end if

  m._log.debug("----- Adding request to send queue-----")
  m._serverRequestsById.addReplace(request.id.toStr(), request)
end sub

'Merge user provided integrations with bundled integrations
function _SegmentAnalytics_SegmentIntegration_createMessageIntegrations(integrations) as Object
  messageIntegrations = integrations
  if messageIntegrations = invalid then
    messageIntegrations = {}
  end if

  for each name in m._bundledIntegrations
    if name <> "Segment.io" then
      messageIntegrations[name] = false
    end if
  end for

  return messageIntegrations  
end function

'Create POST request object for Segment.io api
function _SegmentAnalytics_SegmentIntegration_createPostOptions(batchData as Object) as Object
  ba = createObject("roByteArray")
  ba.fromAsciiString(m._writeKey)

  return {
    method: "POST"
    url: m._apiUrl
    headers: {
      "Authorization": "Basic: " + ba.toBase64String()
      "Content-Type": "application/json"
      "Accept": "application/json"
    }
    data: {
      batch: batchData
      context: {
        "library": {
          "name": m._libraryName
          "version": m._libraryVersion
        }
      }
    }
  }
end function

function _SegmentAnalytics_SegmentIntegration_createRequest(options as Object) as Object
  return _SegmentAnalytics_Request(options, m._log, m._port)
end function

'Create the body object for Segment.io api
function _SegmentAnalytics_SegmentIntegration_getDataBodySize(data as Object) as Integer
  body = {
    batch: data
    context: {
      "library": {
        "name": m._libraryName
        "version": m._libraryVersion
      }
    }
  }

  return formatJSON(body).len()
end function

'After a request has been fulfilled, add it back to the requestPool to be reused at a later time
sub _SegmentAnalytics_SegmentIntegration_releaseUrlTransfer(request as Object)
  if m._requestPool.count() < m._requestPoolSize then
      m._requestPool.push(request.urlTransfer)
  end if
end sub

'Return UrlTransfer object from request pool if not empty
function _SegmentAnalytics_SegmentIntegration_getUrlTransfer() as Object
  if m._requestPoolSize > 0 and m._requestPool <> invalid and m._requestPool.count() > 0 then
    urlTransfer =  m._requestPool.pop()
  else
    urlTransfer = createObject("roUrlTransfer")
  end if
  return urlTransfer
end function

'When we retry a request we limit how fast we send off at a time (Jitter algorithm) to prevent an overload of requests to the server
sub _SegmentAnalytics_SegmentIntegration_setRequestAsRetry(request as Object, currentTime as Integer)
  capSeconds = 600
  baseSeconds = 1
  jitterTimeSeconds = rnd(m._minNumber(capSeconds, baseSeconds * 2 * request.retryCount))
  m._log.debug("Setting retry time request")
  request.retryCount = request.retryCount + 1
  request.nextRetryTime = currentTime + jitterTimeSeconds
end sub

'Returns smallest of two numbers
function _SegmentAnalytics_SegmentIntegration_minNumber(numberOne as Integer, numberTwo as Integer) as Integer
  if numberOne > numberTwo
    return numberTwo
  end if

  return numberOne
end function

'Message logger
function _SegmentAnalytics_Logger() as Object
  this = {
    debugEnabled: false
  }

  this.debug = function(message as String) as Boolean
    return m._log(message, "DEBUG")
  end function

  this.error = function(message as String) as Boolean
    return m._log(message, "ERROR")
  end function

  this._log = function(message as String, logLevel = "NONE" as String) as Boolean
    showDebugLog = invalid
    if m.debugEnabled <> invalid then
      showDebugLog = m.debugEnabled
    end if

    if logLevel = "DEBUG" and (showDebugLog = invalid or not showDebugLog) then
      return false
    end if
    print "SegmentAnalytics - [" + logLevel + "] " + message
    return true
  end function

  return this
end function

'HTTP request handler
function _SegmentAnalytics_Request(options as Object, log as Object, port as Object) as Object
  if options.urlTransfer <> invalid then
    urlTransfer = options.urlTransfer
  else
    urlTransfer = createObject("roUrlTransfer")
  end if

  this = {
    'public variables
    id: invalid
    retryCount: 0
    nextRetryTime: 0

    'private variables
    _log: log
    _method: UCase(options.method)
    _url: options.url
    _params: options.params
    _headers: options.headers
    _data: options.data
    _urlTransfer: urlTransfer
    _responseCode: invalid
    _successHandlers: []
    _errorHandlers: []
  }

  this.success = function(handler)
    m._successHandlers.push(handler)
  end function

  this.error = function(handler)
    m._errorHandlers.push(handler)
  end function

  this.send = function()
    m._log.debug("Sending out request")
    requested = false
    if m._method = "GET" then
      requested = m._urlTransfer.asyncGetToString()
    else if m._method = "POST" or m._method = "DELETE" or m._method = "PUT" then
      if m._data <> invalid then
        body = formatJSON(m._data)
      else
        body = ""
      end if
      requested = m._urlTransfer.asyncPostFromString(body)
    else if m._method = "HEAD" then
      requested = m._urlTransfer.asyncHead()
    else
      requested = false
    end if
    return requested
  end function

  this.cancel = function()
    m._urlTransfer.asyncCancel()
    m._successHandlers.clear()
    m._errorHandlers.clear()
  end function

  this.handleMessage = function(message)
    if type(message) <> "roUrlEvent" then 
      if type(message) <> "roAssociativeArray"then
        return false
      else if message._type <> "roUrlEvent"
        return false
      end if
    end if
    
    requestId = message.getSourceIdentity()

    if requestId <> m.id then return false
    
    state = message.getInt()
    if state <> 1 then return false

    responseCode = message.getResponseCode()
    m._responseCode = responseCode

    rawResponse = message.getString()
    if rawResponse = invalid then
      rawResponse = ""
    end if

    contentType = message.getResponseHeaders()["content-type"]
    if contentType = invalid or LCase(contentType).instr("json") >= 0 then
      if rawResponse <> "" then
        try
          parsedResponse = parseJSON(rawResponse)
        catch e
          m._log.error("Failed to parse response")
          parsedResponse = {} 
        end try
      else
        parsedResponse = {}
      end if
    else
      parsedResponse = {}
    end if

    if responseCode >= 200 and responseCode <= 299 and parsedResponse <> invalid then
      m._log.debug("Successful request")
      for each handler in m._successHandlers
        successHandler = handler
        successHandler(parsedResponse, m)
      end for
    else
      errorReason = message.getFailureReason()
      error = {url: m._url, reason: errorReason, response: rawResponse, responseCode: responseCode}
      m._log.debug("Failed request")

      for each handler in m._errorHandlers
        errorHandler = handler
        errorHandler(error, m)
      end for
    end if

    m._successHandlers.clear()
    m._errorHandlers.clear()

    return true
  end function

  this.id = this._urlTransfer.getIdentity()
  this._urlTransfer.setUrl(this._url)
  this._urlTransfer.setRequest(this._method)
  this._urlTransfer.retainBodyOnError(true)
  this._urlTransfer.setMessagePort(port)
  this._urlTransfer.setCertificatesFile("common:/certs/ca-bundle.crt")

  if this._headers <> invalid then
    this._urlTransfer.setHeaders(this._headers)
  end if

  return this
end function