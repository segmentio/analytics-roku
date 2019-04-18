' Constructor
'
' Required params:
' @config configuration, must include writeKey. Optionally you can include:
' debug=true to receive debug logging
' messageQueue=[size] to limit how many messages get queued before performing a send operation.
' @port message port
function SegmentAnalytics(config as Object, port as Object) as Object
  'Invoking methods outright as this is the constructor for the library
  if _SegmentAnalytics_checkInvalidConfig(config) then
    return invalid
  end if

  if config.queueSize = invalid or (type(config.queueSize) <> "roInteger" and type(config.queueSize) <> "roInt") or config.queueSize < 1 then
    config.queueSize = 1
  end if

  if config.retryLimit = invalid or (type(config.retryLimit) <> "roInteger" and type(config.retryLimit) <> "roInt") or config.retryLimit < -1 then
    config.retryLimit = 1
  end if

  return {
    'public functions
    identify: _SegmentAnalytics_identify
    track: _SegmentAnalytics_track
    screen: _SegmentAnalytics_screen
    group: _SegmentAnalytics_group
    alias: _SegmentAnalytics_alias
    handleRequestMessage: _SegmentAnalytics_handleRequestMessage
    flush: _SegmentAnalytics_flush
    checkRequestQueue: _SegmentAnalytics_checkRequestQueue

    'private functions
    _createRequest: _SegmentAnalytics_createRequest
    _createPostOptions: _Segment_createPostOptions
    _sendRequest: _SegmentAnalytics_sendRequest
    _setRequestAsRetry: _SegmentAnalytics_setRequestAsRetry
    _checkValidId: _SegmentAnalytics_checkValidId
    _addValidFieldsToAA: _SegmentAnalytics_addValidFieldsToAA
    _addValidFieldToAA: _SegmentAnalytics_addValidFieldToAA
    _log: _SegmentAnalytics_log
    _queueMessage: _SegmentAnalytics_queueMessage
    _getDataBodySize: _SegmentAnalytics_getDataBodySize
    _minNumber: _SegmentAnalytics_minNumber

    'private variables
    _config: config
    _port: port
    _apiUrl: "https://api.segment.io/v1/batch"
    _device: CreateObject("roDeviceInfo")
    _libraryName: "analytics-roku"
    _libraryVersion: CreateObject("roAppInfo").getVersion()
    _queueSize: config.queueSize
    _messageQueue: []
    _maxBatchByteSize: 500000
    _maxMessageByteSize: 32000
    _serverRequestsById: {}
    _inProgressId: invalid
  }
end function


function _SegmentAnalytics_checkInvalidConfig(config)
  isInvalid = false

  if config = invalid then
    _SegmentAnalytics_log("No config found", "ERROR")
    isInvalid = true
  else if type(config) <> "roAssociativeArray"
    _SegmentAnalytics_log("Invalid config type found", "ERROR")
    isInvalid = true
  else if config.count() = 0 then
    _SegmentAnalytics_log("Empty config object", "ERROR")
    isInvalid = true
  else if config.writeKey = invalid then
    _SegmentAnalytics_log("No writeKey found in config object", "ERROR")
    isInvalid = true
  else if type(config.writeKey) <> "roString" and type(config.writeKey) <> "String" then
    _SegmentAnalytics_log("Invalid writeKey type found in config object", "ERROR")
    isInvalid = true
  else if config.writeKey.len() < 1 then
    _SegmentAnalytics_log("Empty writeKey string in config object", "ERROR")
    isInvalid = true
  end if

  return isInvalid
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

  m._queueMessage(data)
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

  m._queueMessage(data)
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
    m._log("Error missing name or category in screen call", "Error")
    return
  end if

  m._addValidFieldToAA(data, "name", name)
  m._addValidFieldToAA(data, "category", category)
  m._addValidFieldToAA(data, "properties", properties)
  m._addValidFieldsToAA(data, ["userId", "anonymousId", "context", "integrations", "messageId", "timestamp"], options)

  if not m._checkValidId(data) then return

  m._queueMessage(data)
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

  m._queueMessage(data)
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

  m._queueMessage(data)
end sub

sub _SegmentAnalytics_handleRequestMessage(message as Object, currentTime as Integer)
  if m._serverRequestsById = invalid then return

  responseCode = message.getResponseCode()
  requestId = strI(message.getSourceIdentity(), 10)
  request = m._serverRequestsById[requestId]

  if (responseCode = 429 or responseCode >= 500) and request <> invalid and request.retryCount < m._config.retryLimit then
    m._setRequestAsRetry(request, currentTime)
  else if request <> invalid then
    request.handleMessage(message)
    m._inProgressId = invalid
    m._serverRequestsById.delete(requestId)
  end if
end sub

sub _SegmentAnalytics_sendRequest(messageQueue as Object)
  requestOptions = m._createPostOptions(messageQueue)

  request = m._createRequest(requestOptions)

  request.success(function(request, response)
    m.service._log("Successful request", "DEBUG")
  end function)

  request.error(function(request, response)
    m.service._log("Failed request", "DEBUG")
  end function)

  if m._serverRequestsById.count() >= 1000 then
    firstKey = m._serverRequestsById.keys()[0]
    m._log("----- Request queue is too full dropping request -----", "DEBUG")
    m._log(formatJSON(m._serverRequestsById[firstKey].data), "DEBUG")
    m._serverRequestsById.delete(firstKey)
  end if

  m._log("----- Adding request to send queue-----", "DEBUG")
  m._serverRequestsById.addReplace(request.id.toStr(), request)
end sub

function _Segment_createPostOptions(batchData)
  ba = createObject("roByteArray")
  ba.fromAsciiString(m._config.writeKey)

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

function _SegmentAnalytics_createRequest(options as Object) as Object
  return _SegmentAnalytics_Request(options, m._port, m._config)
end function

sub _SegmentAnalytics_log(message as String, logLevel = "NONE" as String)
  showDebugLog = invalid
  if m._config <> invalid then
    showDebugLog = m._config.debug
  end if

  if logLevel = "DEBUG" and (showDebugLog = invalid or not showDebugLog) then
    return
  end if
  print "SegmentAnalytics - [" + logLevel + "] " + message
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
      m._log("No user or anonymous id found in [" + callType + "] call" , "ERROR")
    return false
  end if

  return true
end function

'Adds multiple fields to the data request body being for
sub _SegmentAnalytics_addValidFieldsToAA(data as Object, fields as Object, inputData as Object)

  if data = invalid or not type(data) = "roAssociativeArray" then return
  if fields = invalid or not type(fields) = "roArray" or fields.count() = 0 then return
  if inputData = invalid or not type(inputData) = "roAssociativeArray" or inputData.count() = 0 then return

  for each field in fields
    m._addValidFieldToAA(data, field, inputData[field])
  end for
end sub

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

      m._log("No field (" + fieldType  + ") for (" + mapType + ") call to add in data request" , "DEBUG")
    end if
end sub

sub _SegmentAnalytics_queueMessage(data as Object)
  if data = invalid then
    m._log("Error missing when queuing message", "ERROR")
    return
  else if data.userId = invalid and data.anonymousId = invalid then
    m._log("Error missing either a user or anonymous ID for (" + data.type + ") call", "ERROR")
    return
  end if

  if data["messageId"] = invalid
    data["messageId"] = CreateObject("roDeviceInfo").GetRandomUUID()
  end if

  if m._getDataBodySize(data) > m._maxMessageByteSize then
    m._log("Message size over 32KB", "ERROR")
  else
    tempQueue = []
    tempQueue.append(m._messageQueue)
    tempQueue.push(data)
    m._log("Current batch size is: ", "DEBUG")
    m._log(strI(m._getDataBodySize(m._messageQueue)), "DEBUG")
    m._log("New batch size is: ", "DEBUG")
    m._log(strI(m._getDataBodySize(tempQueue)), "DEBUG")

    if m._messageQueue.count() > 0 and m._getDataBodySize(tempQueue) > m._maxBatchByteSize then
      m._sendRequest(m._messageQueue)
      m._messageQueue = []

      m._log("---- Queueing message after sending a request -----", "DEBUG")
      m._log(formatJSON(data), "DEBUG")
      m._messageQueue.push(data)
    else
      m._log("---- Queueing message -----", "DEBUG")
      m._log(formatJSON(data), "DEBUG")
      m._messageQueue.push(data)

      if m._messageQueue.count() = m._queueSize then
        m._sendRequest(m._messageQueue)
        m._messageQueue = []
      end if
    end if
  end if
end sub

function _SegmentAnalytics_getDataBodySize(data as Object) as Integer
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

sub _SegmentAnalytics_flush()
  m._log("clearing message queue", "DEBUG")
  if m._messageQueue.count() > 0
    m._sendRequest(m._messageQueue)
    m._messageQueue = []
  end if
end sub

sub _SegmentAnalytics_checkRequestQueue(currentTime as Integer)
  if m._serverRequestsById.count() > 0 then
    for each requestId in m._serverRequestsById.keys()
      nextRetryTime = m._serverRequestsById[requestId].nextRetryTime
      if currentTime > nextRetryTime
        if nextRetryTime > 0
          m._log("Retrying send request: " + requestId , "DEBUG")
        else
          m._log("Sending request: " + requestId , "DEBUG")
        end if
        m._log(formatJSON(m._serverRequestsById[requestId]._data), "DEBUG")
        m._serverRequestsById[requestId].send()
        m._inProgressId = requestId
        return
      end if
    end for
  end if
end sub

'When we retry a request we limit how fast we send off at a time (Jitter algorithm) to prevent an overload of requests to the server
sub _SegmentAnalytics_setRequestAsRetry(request as Object, currentTime as Integer)
  capSeconds = 600
  baseSeconds = 1
  jitterTimeSeconds = rnd(m._minNumber(capSeconds, baseSeconds * 2 * request.retryCount))
  m._log("Setting retry time request", "DEBUG")
  request.retryCount = request.retryCount + 1
  request.nextRetryTime = currentTime + jitterTimeSeconds
end sub

function _SegmentAnalytics_minNumber(numberOne as Integer, numberTwo as Integer)
  if numberOne > numberTwo
    return numberTwo
  end if

  return numberOne
end function

'HTTP request handler
function _SegmentAnalytics_Request(options as Object, port as Object, config as Object) as Object
  this = {
    'public variable
    id: invalid
    retryCount: 0
    nextRetryTime: 0

    'private variables
    _method: UCase(options.method)
    _url: options.url
    _params: options.params
    _headers: options.headers
    _data: options.data
    _urlTransfer: createObject("roUrlTransfer")
    _responseCode: invalid
    _successHandlers: []
    _errorHandlers: []
    _log: _SegmentAnalytics_log
    _config: config
  }

  this.success = function(handler)
    m._successHandlers.push(handler)
  end function

  this.error = function(handler)
    m._errorHandlers.push(handler)
  end function

  this.send = function()
    m._log("Sending out request", "DEBUG")
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
    if type(message) <> "roUrlEvent" then return false

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
        parsedResponse = parseJSON(rawResponse)
      else
        parsedResponse = {}
      end if
    else
      parsedResponse = {}
    end if

    if responseCode >= 200 and responseCode <= 299 and parsedResponse <> invalid then
        for each handler in m._successHandlers
          handler(parsedResponse, m)
        end for
    else
      errorReason = message.getFailureReason()
      error = {url: m._url, reason: errorReason, response: rawResponse, responseCode: responseCode}

      for each handler in m._errorHandlers
        handler(error, m)
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