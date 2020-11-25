'@TestSuite [SAT] SegmentAnalyticsTests

'@Setup
function SAT__SetUp() as void
  m.allowNonExistingMethodsOnMocks = false
end function

'@BeforeEach
function SAT_BeforeEach()
  m.config = {
    writeKey: "test"
  }
  m.port = {}
  m.segmentAnalytics = SegmentAnalytics(m.config, m.port)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test valid initial constructor
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test basic constructor values
function SAT__constructor_basic_success_initial() as void
  m.AssertEqual(m.segmentAnalytics.config.queueSize, 1)
  m.AssertEqual(m.segmentAnalytics.config.retryLimit, 1)
  m.AssertEqual(m.segmentAnalytics.config.writeKey, "test")
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test other valid constructor values
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test other valid constructor values
'@Params[{"writeKey":"test"}, {"writeKey":"test", "queueSize":1, "retryLimit":1, "debug":false, "requestpoolSize":1, "apiHost":"https://api.segment.io", "defaultSettings": {"integrations":{}}}]
'@Params[{"writeKey":"test1", "queueSize":2, "retryLimit":2, "debug":true, "requestpoolSize":2, "apiHost":"https://api2.segment.io", "integrations":{"testIntegration":{apiKey:}}}, {"writeKey":"test1", "queueSize":2, "retryLimit":2, "debug":true, "requestpoolSize":2, "apiHost":"https://api2.segment.io", "defaultSettings": {"integrations":{"testIntegration":{apiKey:}}}}]
function SAT__constructor_basic_success_otherValues(config, expectedConfig) as void
  segmentLibrary = SegmentAnalytics(config, {})
  'Segment.io integration factory should be set by default
  m.AssertEqual(segmentLibrary.config.factories["Segment.io"], _SegmentAnalytics_SegmentIntegrationFactory)
  segmentLibrary.config.delete("factories")
  m.AssertEqual(segmentLibrary.config, expectedConfig)
  m.AssertEqual(segmentLibrary.config.debug, segmentLibrary.log.debugEnabled)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test invalid constructor
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test missing write key value
'@Params[null]
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
'@It tests identify call with valid data
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures the data gets passed to the integration manager 
'@Params[{type: "identify", userId:"testUserId", traits: "testIdentifyTraits", options: "testIdentifyOptions"}]
function SAT__identify_validData(data) as void
  m.ExpectOnce(m.segmentAnalytics._integrationManager, "identify")
  m.segmentAnalytics.identify(data.userId, data.traits, data.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests track call with valid data
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures the data gets passed to the integration manager 
'@Params[{type: "track", "event": "testEvent", properties: "testTrackProps", options: {"anonymousId": "testAnonId"}}]
function SAT__track_validData(data) as void
  m.ExpectOnce(m.segmentAnalytics._integrationManager, "track")
  m.segmentAnalytics.track(data.event, data.properties, data.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests screen call with valid data
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures the data gets passed to the integration manager 
'@Params[{type: "screen", name:"testScreenName", category: "testScreenCategory", properties: "testScreenProps", options: {"anonymousId": "testAnonId"}}]
function SAT__screen_validData(data) as void
  m.ExpectOnce(m.segmentAnalytics._integrationManager, "screen")
  m.segmentAnalytics.screen(data.name, data.category, data.properties, data.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests group call with valid data
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures the data gets passed to the integration manager 
'@Params[{type: "group", userId:"testUserId", groupId: "testGroupId", traits: "testGroupTraits", options: "testGroupOptions"}]
function SAT__group_validData(data) as void
  m.ExpectOnce(m.segmentAnalytics._integrationManager, "group")
  m.segmentAnalytics.group(data.userId, data.groupId, data.traits, data.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests alias call with valid data
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures the data gets passed to the integration manager 
'@Params[{type: "alias", userId:"testUserId", options: "testAliasOptions"}]
function SAT__alias_validData(data) as void
  m.ExpectOnce(m.segmentAnalytics._integrationManager, "alias")
  m.segmentAnalytics.alias(data.userId, data.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests identify call with invalid data
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures we don't pass invalid data to the integration manager
'@Params[{type: "identify", userId:"", traits: "testIdentifyTraits", options: "testIdentifyOptions"}]
function SAT__identify_invalidData(data) as void
  m.ExpectNone(m.segmentAnalytics._integrationManager, "identify", true)
  m.segmentAnalytics.identify(data.userId, data.traits, data.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests track call with invalid data
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures we don't pass invalid data to the integration manager
'@Params[{type: "track", userId:"", properties: "testTrackProps", options: "testTrackOptions"}]
function SAT__track_invalidData(data) as void
  m.ExpectNone(m.segmentAnalytics._integrationManager, "track", true)
  m.segmentAnalytics.track(data.userId, data.properties, data.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests screen call with invalid data
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures we don't pass invalid data to the integration manager
'@Params[{type: "screen", userId:"", category: "testScreenCategory", properties: "testScreenProps", options: "testScreenOptions"}]
function SAT__screen_invalidData(data) as void
  m.ExpectNone(m.segmentAnalytics._integrationManager, "screen", true)
  m.segmentAnalytics.screen(data.userId, data.category, data.properties, data.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests group call with invalid data
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures we don't pass invalid data to the integration manager
'@Params[{type: "group", userId:"", groupId: "testGroupId", traits: "testGroupTraits", options: "testGroupOptions"}]
function SAT__group_invalidData(data) as void
  m.ExpectNone(m.segmentAnalytics._integrationManager, "group", true)
  m.segmentAnalytics.group(data.userId, data.groupId, data.traits, data.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests alias call with invalid data
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures we don't pass invalid data to the integration manager
'@Params[{type: "alias", userId:"", options: "testAliasOptions"}]
function SAT__alias_invalidData(data) as void
  m.ExpectNone(m.segmentAnalytics._integrationManager, "alias", true)
  m.segmentAnalytics.alias(data.userId, data.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests flush call
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures flush call gets passed to integration manager
function SAT__flush() as void
  m.ExpectOnce(m.segmentAnalytics._integrationManager, "flush")
  m.segmentAnalytics.flush()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests handleRequestMessage call
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures handleRequestMessage call gets passed to integration manager
function SAT__handleRequestMessage() as void
  successMessage = {
    responseCode: 200
    getResponseCode: function()
        return m.responseCode
      end function
    getSourceIdentity: function()
        return 0
      end function
    }
  m.ExpectOnce(m.segmentAnalytics._integrationManager, "handleRequestMessage", [successMessage, 0])
  m.segmentAnalytics.handleRequestMessage(successMessage, 0)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests checkRequestQueue call
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures checkRequestQueue call gets passed to integration manager
function SAT__checkRequestQueue() as void
  m.ExpectOnce(m.segmentAnalytics._integrationManager, "checkRequestQueue", [0])
  m.segmentAnalytics.checkRequestQueue(0)
end function