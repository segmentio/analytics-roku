'@TestSuite [SAT] SegmentAnalyticsTests

'@BeforeEach
function SAT_BeforeEach()
  m.config = {
    writeKey: "0HOweca54NlEfFRen2jwJ4DmopPS9oLi"
  }
  m.port = {}
  m.segmentAnalytics = SegmentAnalytics(m.config, m.port)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test valid initial constructor
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test basic constructor values
function SAT__constructor_basic_success_initial() as void
  m.AssertEqual(m.segmentAnalytics._config.queueSize, 1)
  m.AssertEqual(m.segmentAnalytics._config.retryLimit, 1)
  m.AssertEqual(m.segmentAnalytics._config.writeKey, "0HOweca54NlEfFRen2jwJ4DmopPS9oLi")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test other valid constructor values
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test other valid constructor values
'@Params[{"writeKey":"test", "queueSize":2}, {"writeKey":"test", "queueSize":2, "retryLimit":1}]
'@Params[{"writeKey":"test1", "retryLimit":2}, {"writeKey":"test1", "queueSize":1, "retryLimit":2}]
'@Params[{"writeKey":"test2", "queueSize":2, "retryLimit":2} , {"writeKey":"test2", "queueSize":2, "retryLimit":2}]
function SAT__constructor_basic_success_otherValues(config, expectedConfig) as void
  segmentLibrary = SegmentAnalytics(config, {})
  m.AssertEqual(segmentLibrary._config, expectedConfig)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test invalid constructor
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test missing write key value
'@Params[invalid]
'@Params["test"]
'@Params[{"writeKey":""}]
'@Params[{"writeKey":invalid}]
'@Params[{"writeKey":1}]
'@Params[{"queueSize":1}]
'@Params[{"retryLimit":1}]
'@Params[{"queueSize":1, "retryLimit":1}]
function SAT__constructor_fail(config) as void
  segmentLibrary = SegmentAnalytics(config, {})
  m.AssertInvalid(segmentLibrary)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test identify call works as expected
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test identify
'@Params[{"userId": "testUserId", "traits": invalid, "options": invalid}]
'@Params[{"userId": "testUserId", "traits": "test", "options": {"test": "test"}]
'@Params[{"userId": "testUserId", "traits": {}, "options": {}]
function SAT__identify(testObj) as void
  m.ExpectOnce(m.segmentAnalytics, "_queueMessage", invalid, invalid, true)
  m.segmentAnalytics.identify(testObj.userId, testObj.traits, testObj.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test track call works as expected
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test track
'@Params[{"event": "testEvent", "properties": invalid, "options": {"userId": "testUserId"}}]
'@Params[{"event": "testEvent", "properties": {}, "options": {"userId": "testUserId"}}]
'@Params[{"event": "testEvent", "properties": "testProperties", "options": {"userId": "testUserId"}}]
function SAT__track(testObj) as void
  m.ExpectOnce(m.segmentAnalytics, "_queueMessage", invalid, invalid, true)
  m.segmentAnalytics.track(testObj.event, testObj.properties, testObj.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test screen call works as expected
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test screen
'@Params[{"name": "testName", "category": invalid, "properties": invalid, "options": {"userId": "testUserId"}}]
'@Params[{"name": "valid, "category": "testCategory", "properties": {}, "options": {"userId": "testUserId"}}]
'@Params[{"name": "testName", "category": "testCategory", "properties": "test", "options": {"userId": "testUserId"}}]
function SAT__screen(testObj) as void
  m.ExpectOnce(m.segmentAnalytics, "_queueMessage", invalid, invalid, true)
  m.segmentAnalytics.screen(testObj.name, testObj.category, testObj.properties, testObj.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test group call works as expected
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test group
'@Params[{"userId": "testUserId", "groupId": "testGroupId", "traits": invalid, "options": invalid}]
'@Params[{"userId": "testUserId", "groupId": "testGroupId", "traits": "testTraits", "options": "testOptions"}]
'@Params[{"userId": "testUserId", "groupId": "testGroupId", "traits": {}, "options": {}}]
function SAT__group(testObj) as void
  m.ExpectOnce(m.segmentAnalytics, "_queueMessage", invalid, invalid, true)
  m.segmentAnalytics.group(testObj.userId, testObj.groupId, testObj.traits, testObj.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test alias call works as expected
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test alias
'@Params[{"userId": "testUserId", "options": invalid}]
'@Params[{"userId": "testUserId", "options": {}}]
'@Params[{"userId": "testUserId", "options": {"test": "test"}]
function SAT__alias(testObj) as void
   m.ExpectOnce(m.segmentAnalytics, "_queueMessage", invalid, invalid, true)
   m.segmentAnalytics.alias(testObj.userId, testObj.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test successful handleRequestMessage call
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test handleRequestMessage with successful object
'@Params[200]
'@Params[403]
'@Params[404]
function SAT__handleRequestMessage_success(responseCode) as void

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
   m.segmentAnalytics._serverRequestsById.addReplace("0", {"retryCount": 0, "handleMessage": handleMessage})
   m.ExpectNone(m.segmentAnalytics, "_setRequestAsRetry", true)
   m.segmentAnalytics.handleRequestMessage(successMessage, 0)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test failed handleRequestMessage call
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test handleRequestMessage with failed object
'@Params[429]
'@Params[500]
'@Params[501]
function SAT__handleRequestMessage_fail(responseCode as Integer) as void

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
  m.segmentAnalytics._serverRequestsById.addReplace("0", {retryCount:0, "handleMessage": handleMessage})
  m.ExpectOnce(m.segmentAnalytics, "_setRequestAsRetry", invalid, invalid, true)
  m.segmentAnalytics.handleRequestMessage(failedMessage, 0)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test sendRequest (This test might take a while to perform)
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test sendRequest with back pressure logic
function SAT__sendRequest() as void
  for i=0 to 1500
    m.segmentAnalytics._sendRequest([])
  end for
  m.AssertEqual(m.segmentAnalytics._serverRequestsById.count(), 1000)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test sending method invocation
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensuring send works
'@Params[{ "type": "identify", "userId": "testIdentifyId", "traits": "testIdentifyTraits", "options": {"userId": "testUserId"}}]
function SAT__send(data) as void
  requestOptions = m.segmentAnalytics._createPostOptions(data)
  request = m.segmentAnalytics._createRequest(requestOptions)
  'm.ExpectOnce(request, "handleMessage", invalid, invalid, true)
  request.send()
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
function SAT__createRequest(data) as void
  requestOptions = m.segmentAnalytics._createPostOptions(data)

  m.AssertEqual(requestOptions.data.context.library.name, m.segmentAnalytics._libraryName)
  m.AssertEqual(requestOptions.data.context.library.version, m.segmentAnalytics._libraryVersion)
  m.AssertEqual(requestOptions.method, "POST")
  m.AssertEqual(requestOptions.url, "https://api.segment.io/v1/batch")
  m.AssertEqual(requestOptions.headers["Authorization"], "Basic: MEhPd2VjYTU0TmxFZkZSZW4yandKNERtb3BQUzlvTGk=")
  m.AssertEqual(requestOptions.headers["Content-Type"], "application/json")
  m.AssertEqual(requestOptions.headers["Accept"], "application/json")

  request = m.segmentAnalytics._createRequest(requestOptions)
  m.AssertNotEmpty(request)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It testing logging function runs as expected
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensuring log works with correct use cases
'@Params[{"writeKey": "test", debug: true}]
function SAT__log_successful(config) as void
  segmentLibrary = SegmentAnalytics(config, invalid)
  'm.ExpectOnce(m, "print", invalid, invalid, true)
  segmentLibrary._log("TestDebug", "DEBUG")
  'm.ExpectOnce(m, "print", invalid, invalid, true)
  segmentLibrary._log("TestError", "ERROR")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It testing logging function does not get invoked
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure we don't call print inadvertently with debug on
'@Params[{"writeKey": "test"}]
'@Params[{"writeKey": "test", debug: false}]
function SAT__log_fail(config) as void
  segmentLibrary = SegmentAnalytics(config, invalid)
  'm.ExpectNone(m, "print", true)
  segmentLibrary._log("TestDebug", "DEBUG")
  'm.ExpectOnce(m, "print", invalid, invalid, true)
  segmentLibrary._log("TestError", "ERROR")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test _checkValidId successful method
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensuring true is returned
'@Params[{"userId": "test", "anonymousId": "test"}]
'@Params[{"userId": "test", "anonymousId": invalid}]
'@Params[{"userId": invalid, "anonymousId": "test"}]
'@Params[{"userId": "test"}]
'@Params[{anonymousId": "test"}]
function SAT__checkValidId_successful(data) as void
    m.AssertTrue(m.segmentAnalytics._checkValidId(data))
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test _checkValidId fail method
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensuring false is returned
'@Params[{"userId": invalid, "anonymousId": invalid}]
'@Params[{"userId": "", "anonymousId": ""}]
'@Params[{"userId": "", "anonymousId": invalid}]
'@Params[{"userId": invalid, "anonymousId": ""}]
'@Params[{"userId": invalid}]
'@Params[{"anonymousId": invalid}]
'@Params[{"userId": ""}]
'@Params[{"anonymousId": ""}]
function SAT__checkValidId_fail(data) as void
    m.AssertFalse(m.segmentAnalytics._checkValidId(data))
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test _addValidFieldsToAA successful method
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensuring having multiple fields works correctly
'@Params[["test", "test1"], {"test": "test", "test1": "test1"}]
'@Params[["test2", "test3"], {"tes2": "test2", "test3": "test3"}]
function SAT__addValidFieldsToAA_Success(fields, input) as void
  result = {}
  m.segmentAnalytics._addValidFieldsToAA(result, fields, input)

  for each field in fields
    m.AssertEqual(result[field], input[field])
  end for
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test _addValidFieldsToAA failed method
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensuring having multiple fields works correctly
'@Params[{}, invalid, {"test": "test", "test1": "test1"}]
'@Params[{}, ["test", "test1"], invalid]
'@Params[{}, {"test": "test", "test1": "test1"}, ["test", "test1"]]
'@Params["", invalid, invalid]
'@Params[invalid, "", invalid]
'@Params[invalid, invalid, ""]
'@Params[{}, invalid, invalid]
'@Params[invalid, {}, invalid]
'@Params[invalid, invalid, {}]
'@Params[{}, {}, {}]
'@Params["", "", ""]
'@Params[invalid, invalid, invalid]
function SAT__addValidFieldsToAA_Fail(result, fields, input) as void
  result = {}
  m.segmentAnalytics._addValidFieldsToAA(result, fields, input)
  m.AssertEmpty(result)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test _addValidFieldToAA success method
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensuring having single field works correctly
'@Params["test", "test"]
function SAT__addValidFieldToAA_success(field, input) as void
  result = {}
  m.segmentAnalytics._addValidFieldToAA(result, field, input)
  m.AssertEqual(result[field], input)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test _addValidFieldToAA fail method
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensuring having single field fails
'@Params[{}, "test", invalid]
'@Params[{}, "" {"test": "test", "test1": "test1"}]
'@Params[{}, "", ["test", "test1"]]
'@Params[{}, "", ""]
'@Params[{}, "", {}]
'@Params[{}, "", invalid]
function SAT__addValidFieldToAA_fail(result, field, input) as void
  result = {}
  m.segmentAnalytics._addValidFieldToAA(result, field, input)
  m.AssertEmpty(result)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests queueMessage with valid data (5)
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures we have the right number of items in the message queue and that we don't prematurely fire off a send request (5 in queue)
'@Params[{ type: "group", userId: "testGroupUserId", groupId: "testGroupId", traits: "testGroupTraits", options: "testGroupOptions"}, {"writeKey": "test", "queueSize": 5}]
function SAT__addToMessageQueue5(data, config) as void
  segmentLibrary = SegmentAnalytics(config, {})

  m.AssertEqual(segmentLibrary._queueSize, config.queueSize)

  m.ExpectNone(segmentLibrary, "_sendRequest", true)
  segmentLibrary._queueMessage(data)
  m.AssertEqual(segmentLibrary._messageQueue.count(), 1)

  m.ExpectNone(segmentLibrary, "_sendRequest", true)
  segmentLibrary._queueMessage(data)
  m.AssertEqual(segmentLibrary._messageQueue.count(), 2)

  m.ExpectNone(segmentLibrary, "_sendRequest", true)
  segmentLibrary._queueMessage(data)
  m.AssertEqual(segmentLibrary._messageQueue.count(), 3)

  m.ExpectNone(segmentLibrary, "_sendRequest", true)
  segmentLibrary._queueMessage(data)
  m.AssertEqual(segmentLibrary._messageQueue.count(), 4)

  m.ExpectOnce(segmentLibrary, "_sendRequest", invalid, invalid, true)
  segmentLibrary._queueMessage(data)
  m.AssertEqual(segmentLibrary._messageQueue.count(), 0)

  m.ExpectNone(segmentLibrary, "_sendRequest", true)
  segmentLibrary._queueMessage(data)
  m.AssertEqual(segmentLibrary._messageQueue.count(), 1)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests queueMessage with valid data (3)
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures we have the right number of items in the message queue and that we don't prematurely fire off a send request (3 in queue)
'@Params[{ type: "group", userId: "testGroupUserId", groupId: "testGroupId", traits: "testGroupTraits", options: "testGroupOptions"}, {"writeKey": "test", "queueSize": 3}]
function SAT__addToMessageQueue3(data, config) as void
  segmentLibrary = SegmentAnalytics(config, {})

  m.AssertEqual(segmentLibrary._queueSize, config.queueSize)

  m.ExpectNone(segmentLibrary, "_sendRequest", true)
  segmentLibrary._queueMessage(data)
  m.AssertEqual(segmentLibrary._messageQueue.count(), 1)

  m.ExpectNone(segmentLibrary, "_sendRequest", true)
  segmentLibrary._queueMessage(data)
  m.AssertEqual(segmentLibrary._messageQueue.count(), 2)

  m.ExpectOnce(segmentLibrary, "_sendRequest", invalid, invalid, true)
  segmentLibrary._queueMessage(data)
  m.AssertEqual(segmentLibrary._messageQueue.count(), 0)

  m.ExpectNone(segmentLibrary, "_sendRequest", true)
  segmentLibrary._queueMessage(data)
  m.AssertEqual(segmentLibrary._messageQueue.count(), 1)

  m.ExpectNone(segmentLibrary, "_sendRequest", true)
  segmentLibrary._queueMessage(data)
  m.AssertEqual(segmentLibrary._messageQueue.count(), 2)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests queueMessage with invalid data
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures we don't add in invalid items in the queue
'@Params[{type: "group", groupId: "testGroupId", traits: "testGroupTraits", options: "testGroupOptions"}]
function SAT__invalidMessageQueue(data) as void
  m.ExpectNone(m.segmentAnalytics, "_sendRequest", true)
  m.segmentAnalytics._queueMessage(data)
  m.AssertEqual(m.segmentAnalytics._messageQueue.count(), 0)

  m.ExpectNone(m.segmentAnalytics, "_sendRequest", true)
  m.segmentAnalytics._queueMessage(data)
  m.AssertEqual(m.segmentAnalytics._messageQueue.count(), 0)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests data too of a message to send (this test might take a long time to run)
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures we don't add in really big data body in request
'@Params[{type: "group", groupId: "testGroupId", "userId": "test" , traits: "testGroupTraits", options: "testGroupOptions", "filler":[]}]
function SAT__invalidTooBigMessageQueue(data) as void
  fillerObject = {"filler": "filler"}
  for i = 0 to 32000
    data.filler.push(fillerObject)
  end for

  m.ExpectNone(m.segmentAnalytics, "_sendRequest", true)
  m.segmentAnalytics._queueMessage(data)
  m.AssertEqual(m.segmentAnalytics._messageQueue.count(), 0)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It testing body data size check function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure the data check passes
'@Params[{"writeKey": "test"}, 95]
'@Params[{"writeKeyRunning": "testRun"}, 105]
function SAT__getDataBodySizeValid(data, expectedSize) as void
  m.AssertEqual(m.segmentAnalytics._getDataBodySize(data), expectedSize)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It testing flush functionality
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure the flush executes correctly
function SAT__flush() as void
  m.segmentAnalytics.flush()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It testing checkRequestQueue retry functionality
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure the checkRequestQueue retries correctly
function SAT__retryRequest_retry() as void
  m.segmentAnalytics.checkRequestQueue(0)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It testing checkRequestQueue clean functionality
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure the checkRequestQueue executes correctly
function SAT__retryRequest_clean() as void
  m.segmentAnalytics.checkRequestQueue(0)
end function

