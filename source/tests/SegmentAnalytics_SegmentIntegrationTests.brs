'@TestSuite [SA_SIT] SegmentAnalytics_SegmentIntegrationTests

'@Setup
function SA_SIT__SetUp() as void
  m.allowNonExistingMethodsOnMocks = false
end function

'@BeforeEach
function SA_SIT_BeforeEach()
  m.settings = {
    writeKey: "test"
    queueSize: 1
    retryLimit: 1
    requestpoolSize: 1
    apiHost: "https://api.segment.io"
  }
  m.port = {}
  m.version = "2.0.0"
  m.log = _SegmentAnalytics_Logger()
  m.bundledIntegrations = []
  
  m.segmentIntegration = _SegmentAnalytics_SegmentIntegration(m.settings, m.bundledIntegrations, m.version, m.log)
end function
  
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test valid initial constructor
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test basic constructor values
function SA_SIT__constructor_basic_success_initial() as void
  m.AssertEqual(m.segmentIntegration.key, "Segment.io")
  m.AssertEqual(m.segmentIntegration._writeKey, "test")
  m.AssertEqual(m.segmentIntegration._queueSize, m.settings.queueSize)
  m.AssertEqual(m.segmentIntegration._retryLimit, m.settings.retryLimit)
  m.AssertEqual(m.segmentIntegration._requestPoolSize, m.settings.requestpoolSize)
  m.AssertEqual(m.segmentIntegration._apiUrl, "https://api.segment.io/v1/batch")
  m.AssertEqual(m.segmentIntegration._bundledIntegrations, m.bundledIntegrations)
  m.AssertEqual(m.segmentIntegration._log, m.log)
  m.AssertEqual(m.segmentIntegration._libraryVersion, m.version)
  m.AssertEqual(m.segmentIntegration._messageQueue, [])
  m.AssertEqual(m.segmentIntegration._maxBatchByteSize, 500000)
  m.AssertEqual(m.segmentIntegration._maxMessageByteSize, 32000)
  m.AssertEqual(m.segmentIntegration._serverRequestsById, {})
  m.AssertEqual(m.segmentIntegration._inProgressId, invalid)
  m.AssertEqual(m.segmentIntegration._requestPool, [])
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test other valid constructor values
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test other valid constructor values
'@Params[{"writeKey":"test", "queueSize":1, "retryLimit":1, "requestPoolSize":1, "apiHost":"https://api.segment.io"}, [], {"writeKey": "test", "queueSize": 1, "retryLimit": 1, "requestPoolSize": 1, "apiHost":"https://api.segment.io/v1/batch"}]
'@Params[{"writeKey":"test1", "queueSize":2, "retryLimit":2, "requestPoolSize":2, "apiHost":"https://api2.segment.io"}, ["Test"], {"writeKey":"test1", "queueSize":2, "retryLimit":2, "requestPoolSize":2, "apiHost":"https://api2.segment.io/v1/batch"}]
function SA_SIT__constructor_basic_success_otherValues(settings, bundledIntegrations, expectedConfig) as void
  segmentIntegration = _SegmentAnalytics_SegmentIntegration(settings, bundledIntegrations, m.version, m.log)

  m.AssertEqual(segmentIntegration.key, "Segment.io")
  m.AssertEqual(segmentIntegration._writeKey, expectedConfig.writeKey)
  m.AssertEqual(segmentIntegration._queueSize, expectedConfig.queueSize)
  m.AssertEqual(segmentIntegration._retryLimit, expectedConfig.retryLimit)
  m.AssertEqual(segmentIntegration._requestPoolSize, expectedConfig.requestpoolSize)
  m.AssertEqual(segmentIntegration._apiUrl, expectedConfig.apiHost)
  m.AssertEqual(segmentIntegration._bundledIntegrations, bundledIntegrations)
  m.AssertEqual(segmentIntegration._messageQueue, [])
  m.AssertEqual(segmentIntegration._maxBatchByteSize, 500000)
  m.AssertEqual(segmentIntegration._maxMessageByteSize, 32000)
  m.AssertEqual(segmentIntegration._serverRequestsById, {})
  m.AssertEqual(segmentIntegration._inProgressId, invalid)
  m.AssertEqual(segmentIntegration._requestPool, [])
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test identify call works as expected
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test identify
'@Params[{"userId": "testUserId", "traits": null, "options": null}]
'@Params[{"userId": "testUserId", "traits": "test", "options": {"test": "test"}}]
'@Params[{"userId": "testUserId", "traits": {}, "options": {}}]
function SA_SIT__identify(testObj) as void
  m.ExpectOnce(m.segmentIntegration, "_sendRequest")
  m.segmentIntegration.identify(testObj)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test track call works as expected
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test track
'@Params[{"event": "testEvent", "properties": null, "options": {"userId": "testUserId"}}]
'@Params[{"event": "testEvent", "properties": {}, "options": {"userId": "testUserId"}}]
'@Params[{"event": "testEvent", "properties": "testProperties", "options": {"userId": "testUserId"}}]
function SA_SIT__track(testObj) as void
  m.ExpectOnce(m.segmentIntegration, "_sendRequest")
  m.segmentIntegration.track(testObj)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test screen call works as expected
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test screen
'@Params[{"name": "testName", "category": null, "properties": null, "options": {"userId": "testUserId"}}]
'@Params[{"name": "valid, "category": "testCategory", "properties": {}, "options": {"userId": "testUserId"}}]
'@Params[{"name": "testName", "category": "testCategory", "properties": "test", "options": {"userId": "testUserId"}}]
function SA_SIT__screen(testObj) as void
  m.ExpectOnce(m.segmentIntegration, "_sendRequest")
  m.segmentIntegration.screen(testObj)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test group call works as expected
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test group
'@Params[{"userId": "testUserId", "groupId": "testGroupId", "traits": null, "options": null}]
'@Params[{"userId": "testUserId", "groupId": "testGroupId", "traits": "testTraits", "options": "testOptions"}]
'@Params[{"userId": "testUserId", "groupId": "testGroupId", "traits": {}, "options": {}}]
function SA_SIT__group(testObj) as void
  m.ExpectOnce(m.segmentIntegration, "_sendRequest")
  m.segmentIntegration.group(testObj)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test alias call works as expected
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test alias
'@Params[{"userId": "testUserId", "options": null}]
'@Params[{"userId": "testUserId", "options": {}}]
'@Params[{"userId": "testUserId", "options": {"test": "test"}]
function SA_SIT__alias(testObj) as void
  m.ExpectOnce(m.segmentIntegration, "_sendRequest")
  m.segmentIntegration.alias(testObj)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It testing flush functionality
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure the flush executes correctly
function SA_SIT__flush() as void
  m.segmentIntegration.flush()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test successful handleRequestMessage call
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test handleRequestMessage with successful object
'@Params[200]
'@Params[403]
'@Params[404]
function SA_SIT__handleRequestMessage_success(responseCode) as void
  'Assigning responseCode as member variable to be accessed in own function definition for test
  successMessage = {
    responseCode: responseCode
    getResponseCode: function()
        return m.responseCode
      end function
    getSourceIdentity: function()
        return 0
      end function
    }
  handleMessage = sub(result as Object)
    end sub

  m.segmentIntegration._serverRequestsById.addReplace("0", {"retryCount": 0, "handleMessage": handleMessage})
  m.ExpectNone(m.segmentIntegration, "_setRequestAsRetry")
  m.segmentIntegration._handleRequestMessage(successMessage, 0)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test failed handleRequestMessage call
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test handleRequestMessage with failed object
'@Params[429]
'@Params[500]
'@Params[501]
function SA_SIT__handleRequestMessage_fail(responseCode as Integer) as void
  'Assigning responseCode as member variable to be accessed in own function definition for test
  failedMessage = {
    responseCode: responseCode
    getResponseCode: function() as Integer
       return m.responseCode
     end function
    getSourceIdentity: function()
        return 0
      end function
  }
  handleMessage = sub(result as Object)
       end sub
  m.segmentIntegration._serverRequestsById.addReplace("0", {retryCount:0, "handleMessage": handleMessage})
  m.ExpectOnce(m.segmentIntegration, "_setRequestAsRetry")
  m.segmentIntegration._handleRequestMessage(failedMessage, 0)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It testing checkRequestQueue retry functionality
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure the checkRequestQueue retries correctly
function SA_SIT__retryRequest_retry() as void
  m.segmentIntegration._checkRequestQueue(0)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It testing checkRequestQueue clean functionality
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure the checkRequestQueue executes correctly
function SA_SIT__retryRequest_clean() as void
  m.segmentIntegration._checkRequestQueue(0)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It testing processMessages invoking handleRequestMessage
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure the processMessages invokes handleRequestMessage with response
function SA_SIT__processMessages_handleRequestMessage() as void
  successMessage = {
    _type: "roUrlEvent"
    responseCode: 200
    getResponseCode: function()
        return m.responseCode
      end function
    getSourceIdentity: function()
        return 0
      end function
    }

  m.segmentIntegration._port.postMessage(successMessage)
  m.ExpectOnce(m.segmentIntegration, "_handleRequestMessage", [successMessage, 0])
  m.segmentIntegration.processMessages()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It testing processMessages invoking checkRequestQueue
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure the processMessages invokes checkRequestQueue when timer has not reached nextQueueFlush time
function SA_SIT__processMessages_checkRequestQueue() as void
  m.ExpectOnce(m.segmentIntegration, "_checkRequestQueue", [m.segmentIntegration._clock.totalSeconds()])
  m.segmentIntegration.processMessages()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It testing processMessages invoking flush
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure the processMessages invokes flush when timer has reached nextQueueFlush time
function SA_SIT__processMessages_flush() as void
  ' clock time is at 0
  m.segmentIntegration._nextQueueFlush = -1
  m.ExpectOnce(m.segmentIntegration, "flush")
  m.segmentIntegration.processMessages()

  ' check if nextQueueFlush was updated from -1 to queueFlushTime
  m.AssertEqual(m.segmentIntegration._nextQueueFlush, m.segmentIntegration._queueFlushTime)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests queueMessage with valid data (5)
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures we have the right number of items in the message queue and that we don't prematurely fire off a send request (5 in queue)
'@Params[{ type: "group", userId: "testGroupUserId", groupId: "testGroupId", traits: "testGroupTraits", options: "testGroupOptions"}]
function SA_SIT__addToMessageQueue5(data) as void
  settings = m.settings
  settings.queueSize = 5
  segmentIntegration = _SegmentAnalytics_SegmentIntegration(settings, m.bundledIntegrations, m.version, m.log)

  m.AssertEqual(segmentIntegration._queueSize, settings.queueSize)

  m.ExpectNone(segmentIntegration, "_sendRequest")

  segmentIntegration.group(data)
  m.AssertEqual(segmentIntegration._messageQueue.count(), 1)

  m.ExpectNone(segmentIntegration, "_sendRequest")
  segmentIntegration.group(data)
  m.AssertEqual(segmentIntegration._messageQueue.count(), 2)

  m.ExpectNone(segmentIntegration, "_sendRequest")
  segmentIntegration.group(data)
  m.AssertEqual(segmentIntegration._messageQueue.count(), 3)

  m.ExpectNone(segmentIntegration, "_sendRequest")
  segmentIntegration.group(data)
  m.AssertEqual(segmentIntegration._messageQueue.count(), 4)

  m.ExpectOnce(segmentIntegration, "_sendRequest")
  segmentIntegration.group(data)
  m.AssertEqual(segmentIntegration._messageQueue.count(), 0)

  m.ExpectNone(segmentIntegration, "_sendRequest")
  segmentIntegration.group(data)
  m.AssertEqual(segmentIntegration._messageQueue.count(), 1)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests queueMessage with valid data (3)
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures we have the right number of items in the message queue and that we don't prematurely fire off a send request (3 in queue)
'@Params[{ type: "group", userId: "testGroupUserId", groupId: "testGroupId", traits: "testGroupTraits", options: "testGroupOptions"}, {"writeKey": "test", "queueSize": 3}]
function SA_SIT__addToMessageQueue3(data, config) as void
  settings = m.settings
  settings.queueSize = 3
  segmentIntegration = _SegmentAnalytics_SegmentIntegration(settings, m.bundledIntegrations, m.version, m.log)

  m.AssertEqual(segmentIntegration._queueSize, settings.queueSize)

  m.ExpectNone(segmentIntegration, "_sendRequest")
  segmentIntegration.group(data)
  m.AssertEqual(segmentIntegration._messageQueue.count(), 1)

  m.ExpectNone(segmentIntegration, "_sendRequest")
  segmentIntegration.group(data)
  m.AssertEqual(segmentIntegration._messageQueue.count(), 2)

  m.ExpectOnce(segmentIntegration, "_sendRequest")
  segmentIntegration.group(data)
  m.AssertEqual(segmentIntegration._messageQueue.count(), 0)

  m.ExpectNone(segmentIntegration, "_sendRequest")
  segmentIntegration.group(data)
  m.AssertEqual(segmentIntegration._messageQueue.count(), 1)

  m.ExpectNone(segmentIntegration, "_sendRequest")
  segmentIntegration.group(data)
  m.AssertEqual(segmentIntegration._messageQueue.count(), 2)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests data too of a message to send (this test might take a long time to run)
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures we don't add in really big data body in request
'@Params[{type: "group", groupId: "testGroupId", "userId": "test" , traits: [], options: "testGroupOptions"}]
function SA_SIT__invalidTooBigMessageQueue(data) as void
  fillerObject = {"filler": "filler"}
  for i = 0 to 32000
    data.traits.push(fillerObject)
  end for

  m.ExpectNone(m.segmentIntegration, "_sendRequest")
  m.segmentIntegration.group(data)
  m.AssertEqual(m.segmentIntegration._messageQueue.count(), 0)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests creatingPostOptions singular requests
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test validate data request creation
'@Params[{type: "identify", userId: "testIdentifyId", traits: "testIdentifyTraits", options: "testIdentifyOptions"}]
'@Params[{type: "track", event: "eventTrack", properties: "testTrackProperties", options: "testTrackOptions"}]
'@Params[{type: "screen", name: "screenName", category: "screenCategory", properties: "testScreenProperties", options: "testScreenOptions"}]
'@Params[{type: "group", userId: "testGroupUserId", groupId: "testGroupId", traits: "testGroupTraits", options: "testGroupOptions"}]
'@Params[{type: "alias", userId: "newIdAlias", options: "testAliasOptions"}]
function SA_SIT__createRequest(data) as void
  requestOptions = m.segmentIntegration._createPostOptions(data)
  ba = createObject("roByteArray")
  ba.fromAsciiString(m.segmentIntegration._writeKey)

  m.AssertEqual(requestOptions.data.context.library.name, m.segmentIntegration._libraryName)
  m.AssertEqual(requestOptions.data.context.library.version, m.segmentIntegration._libraryVersion)
  m.AssertEqual(requestOptions.method, "POST")
  m.AssertEqual(requestOptions.url, "https://api.segment.io/v1/batch")
  m.AssertEqual(requestOptions.headers["Authorization"], "Basic: " + ba.toBase64String())
  m.AssertEqual(requestOptions.headers["Content-Type"], "application/json")
  m.AssertEqual(requestOptions.headers["Accept"], "application/json")

  request = m.segmentIntegration._createRequest(requestOptions)
  m.AssertNotEmpty(request)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test sendRequest (This test might take a while to perform)
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test sendRequest with back pressure logic
function SA_SIT__sendRequest() as void
  for i=0 to 1500
    m.segmentIntegration._sendRequest([])
  end for
  m.AssertEqual(m.segmentIntegration._serverRequestsById.count(), 1000)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It testing body data size check function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure the data check passes
'@Params[{"writeKey": "test"}, 95]
'@Params[{"writeKeyRunning": "testRun"}, 105]
function SA_SIT__getDataBodySizeValid(data, expectedSize) as void
  m.AssertEqual(m.segmentIntegration._getDataBodySize(data), expectedSize)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It testing min number function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure smalled number is returned
'@Params[{numberOne: 2, numberTwo:3}, 2]
'@Params[{numberOne: 0, numberTwo:1}, 0]
'@Params[{numberOne: -1, numberTwo:0}, -1]
'@Params[{numberOne: -2, numberTwo:-1}, -2]
'@Params[{numberOne: 3, numberTwo:2}, 2]
'@Params[{numberOne: 1, numberTwo:0}, 0]
'@Params[{numberOne: 0, numberTwo:-1}, -1]
'@Params[{numberOne: -1, numberTwo:-2}, -2]
function SA_SIT__minNumber(testObj, expected) as void
  m.AssertEqual(m.segmentIntegration._minNumber(testObj.numberOne, testObj.numberTwo), expected)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test getUrlTransfer returns new object when pool size is 0
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test pool size is 0
function SA_SIT__getUrlTransfer_poolSize_invalid() as void
  m.segmentIntegration._requestPoolSize = 0

  urlTransfer = m.segmentIntegration._getUrlTransfer()
  m.AssertEqual(type(urlTransfer), "roUrlTransfer")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test getUrlTransfer returns new object if pool is empty
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test pool contains no objects
function SA_SIT__getUrlTransfer_poolEmpty() as void
  m.segmentIntegration._requestPoolSize = 1

  urlTransfer = m.segmentIntegration._getUrlTransfer()
  m.AssertEqual(type(urlTransfer), "roUrlTransfer")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test getUrlTransfer returns object from pool when not empty
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test request pool contains an object
function SA_SIT__getUrlTransfer_poolNotEmpty() as void
  m.segmentIntegration._requestPoolSize = 1
  m.segmentIntegration._requestPool = [CreateObject("roUrlTransfer")]

  urlTransfer = m.segmentIntegration._getUrlTransfer()
  m.AssertEqual(type(urlTransfer), "roUrlTransfer")
  m.AssertEqual(m.segmentIntegration._requestPool.count(), 0)

  urlTransfer = m.segmentIntegration._getUrlTransfer()
  m.AssertEqual(type(urlTransfer), "roUrlTransfer")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test releaseUrlTransfer returns urlTransfers back to pool
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test request pool is not full
function SA_SIT__releaseUrlTransfer() as void
  urlTransfer1 = createObject("roUrlTransfer")
  urlTransfer2 = createObject("roUrlTransfer")

  urlTransfer1Id = urlTransfer1.getIdentity().ToStr()
  urlTransfer2Id = urlTransfer2.getIdentity().ToStr()

  request1 = {
    urlTransfer: urlTransfer1
  }
  request2 = {
    urlTransfer: urlTransfer2
  }

  m.segmentIntegration._requestPoolSize = 2

  m.segmentIntegration._releaseUrlTransfer(request1)
  m.AssertEqual(m.segmentIntegration._requestPool.count(), 1)
  m.AssertEqual(m.segmentIntegration._requestPool[0].getIdentity().ToStr(), urlTransfer1Id)

  m.segmentIntegration._releaseUrlTransfer(request2)
  m.AssertEqual(m.segmentIntegration._requestPool.count(), 2)
  m.AssertEqual(m.segmentIntegration._requestPool[1].getIdentity().ToStr(), urlTransfer2Id)

  m.segmentIntegration._requestPool = []
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test releaseUrlTransfer does not overfill pool
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test pool is maxed out (requestPoolSize)
function SA_SIT__releaseUrlTransfer_poolFull() as void
  urlTransfer1 = createObject("roUrlTransfer")
  urlTransfer2 = createObject("roUrlTransfer")

  urlTransfer1Id = urlTransfer1.getIdentity().ToStr()
  urlTransfer2Id = urlTransfer2.getIdentity().ToStr()

  request1 = {
    urlTransfer: urlTransfer1
  }
  request2 = {
    urlTransfer: urlTransfer2
  }

  m.segmentIntegration._requestPoolSize = 1
  m.segmentIntegration._requestPool = []

  m.segmentIntegration._releaseUrlTransfer(request1)
  m.AssertEqual(m.segmentIntegration._requestPool.count(), 1)
  m.AssertEqual(m.segmentIntegration._requestPool[0].getIdentity().ToStr(), urlTransfer1Id)

  m.segmentIntegration._releaseUrlTransfer(request2)
  m.AssertEqual(m.segmentIntegration._requestPool.count(), 1)
  m.AssertEqual(m.segmentIntegration._requestPool[0].getIdentity().ToStr(), urlTransfer1Id)

  m.segmentIntegration._requestPool = []
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test createMessageIntegrations call works as expected
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test set integrations object in data object
'@Params[{"Test": true}, ["Segment.io"], {"Test": true}]
'@Params[{"Test": true}, ["Segment.io", "Test"], {"Test": false}]
'@Params[null, ["Segment.io"], {}]
function SA_SIT__createMessageIntegrations(integrations, mockBundledIntegrations, expected) as void
  m.segmentIntegration._bundledIntegrations = mockBundledIntegrations
  output = m.segmentIntegration._createMessageIntegrations(integrations)

  m.AssertEqual(output, expected)
end function