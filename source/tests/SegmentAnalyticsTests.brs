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
  m.remoteSettings = {
    integrations: {}
    plan: {
      track: {
        __default: {
          enabled: true
          integrations: {}
        }
      }
    }
  }
  m.mockFetchRemoteSettings = function(analytics, responseCode, settings)
      message = {
        _type: "roUrlEvent"
        urlTransfer: analytics._remoteSettingsRequest._urlTransfer
        responseCode: responseCode
        rawResponse: formatJson(settings)
        getSourceIdentity: function()
            return m.urlTransfer.getIdentity()
          end function
        getResponseCode: function()
            return m.responseCode
          end function
        getInt: function()
            return 1
          end function
        getString: function()
            return m.rawResponse
          end function
        getResponseHeaders: function()
            return {"content-type": "application/json"}
          end function
        getFailureReason: function()
          return m.responseCode
        end function
      }

      analytics._port.postMessage(message)
      analytics.processMessages()
    end function

  m.segmentAnalytics = SegmentAnalytics(m.config)
  m.mockFetchRemoteSettings(m.segmentAnalytics, 200, m.remoteSettings)
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
'@Params[{"writeKey":"test"}, {"writeKey":"test", "settings": {}, "queueSize":1, "retryLimit":1, "debug":false, "requestpoolSize":1, "apiHost":"https://api.segment.io", "settingsApiHost": "https://cdn-settings.segment.com", "defaultSettings": {"plan": {"track": {"__default": {"integrations": {}, "enabled": true}}}, "integrations": {"Segment.io": {}}}, "settings": {"plan": {"track": {"__default": {"integrations": {}, "enabled": true}}}, "integrations": {}}}]
'@Params[{"writeKey":"test1", "queueSize":2, "retryLimit":2, "debug":true, "requestpoolSize":2, "apiHost":"https://api2.segment.io", "integrations":{"testIntegration":{apiKey:}}}, {"writeKey":"test1", "queueSize":2, "retryLimit":2, "debug":true, "requestpoolSize":2, "apiHost":"https://api2.segment.io", "defaultSettings": {"plan": {"track": {"__default": {"integrations": {}, "enabled": true}}}, "settings": {"plan": {"track": {"__default": {"integrations": {}, "enabled": true}}}, "integrations": {}}, "integrations":{"testIntegration":{apiKey:}}}}]
function SAT__constructor_basic_success_otherValues(config, expectedConfig) as void
  segmentLibrary = SegmentAnalytics(m.config)
  m.mockFetchRemoteSettings(segmentLibrary, 200, m.remoteSettings)
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
  segmentLibrary = SegmentAnalytics(config)
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
  m.ExpectNone(m.segmentAnalytics._integrationManager, "identify")
  m.segmentAnalytics.identify(data.userId, data.traits, data.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests track call with invalid data
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures we don't pass invalid data to the integration manager
'@Params[{type: "track", userId:"", properties: "testTrackProps", options: "testTrackOptions"}]
function SAT__track_invalidData(data) as void
  m.ExpectNone(m.segmentAnalytics._integrationManager, "track")
  m.segmentAnalytics.track(data.userId, data.properties, data.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests screen call with invalid data
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures we don't pass invalid data to the integration manager
'@Params[{type: "screen", userId:"", category: "testScreenCategory", properties: "testScreenProps", options: "testScreenOptions"}]
function SAT__screen_invalidData(data) as void
  m.ExpectNone(m.segmentAnalytics._integrationManager, "screen")
  m.segmentAnalytics.screen(data.userId, data.category, data.properties, data.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests group call with invalid data
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures we don't pass invalid data to the integration manager
'@Params[{type: "group", userId:"", groupId: "testGroupId", traits: "testGroupTraits", options: "testGroupOptions"}]
function SAT__group_invalidData(data) as void
  m.ExpectNone(m.segmentAnalytics._integrationManager, "group")
  m.segmentAnalytics.group(data.userId, data.groupId, data.traits, data.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests alias call with invalid data
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures we don't pass invalid data to the integration manager
'@Params[{type: "alias", userId:"", options: "testAliasOptions"}]
function SAT__alias_invalidData(data) as void
  m.ExpectNone(m.segmentAnalytics._integrationManager, "alias")
  m.segmentAnalytics.alias(data.userId, data.options)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests flush call
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure flush call gets passed to integration manager
function SAT__flush() as void
  m.ExpectOnce(m.segmentAnalytics._integrationManager, "flush")
  m.segmentAnalytics.flush()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests identify call with invalid integration manager
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure identify call is queued while remote settings are fetched
'@Params[{type: "identify", userId:"testUserId", traits: "testIdentifyTraits", options: "testIdentifyOptions"}]
function SAT__identify_queueCallWhileSettingsFetched(data) as void
  segmentLibrary = SegmentAnalytics(m.config)
  m.AssertTrue(segmentLibrary._initialRequestQueue.count() = 0)
  m.AssertTrue(segmentLibrary._integrationManager = invalid)
  segmentLibrary.identify(data.userId, data.traits, data.options)
  m.AssertTrue(segmentLibrary._initialRequestQueue.count() = 1)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests track call with invalid integration manager
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure track call is queued while remote settings are fetched
'@Params[{type: "track", "event": "testEvent", properties: "testTrackProps", options: {"anonymousId": "testAnonId"}}]
function SAT__track_queueWhileSettingsFetched(data) as void
  segmentLibrary = SegmentAnalytics(m.config)
  m.AssertTrue(segmentLibrary._initialRequestQueue.count() = 0)
  m.AssertTrue(segmentLibrary._integrationManager = invalid)
  segmentLibrary.track(data.event, data.properties, data.options)
  m.AssertTrue(segmentLibrary._initialRequestQueue.count() = 1)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests screen call with invalid integration manager
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure screen call is queued while remote settings are fetched
'@Params[{type: "screen", name:"testScreenName", category: "testScreenCategory", properties: "testScreenProps", options: {"anonymousId": "testAnonId"}}]
function SAT__screen_queueWhileSettingsFetched(data) as void
  segmentLibrary = SegmentAnalytics(m.config)
  m.AssertTrue(segmentLibrary._initialRequestQueue.count() = 0)
  m.AssertTrue(segmentLibrary._integrationManager = invalid)
  segmentLibrary.screen(data.name, data.category, data.properties, data.options)
  m.AssertTrue(segmentLibrary._initialRequestQueue.count() = 1)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests group call with invalid integration manager
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure group call is queued while remote settings are fetched
'@Params[{type: "group", userId:"testUserId", groupId: "testGroupId", traits: "testGroupTraits", options: "testGroupOptions"}]
function SAT__group_queueWhileSettingsFetched(data) as void
  segmentLibrary = SegmentAnalytics(m.config)
  m.AssertTrue(segmentLibrary._initialRequestQueue.count() = 0)
  m.AssertTrue(segmentLibrary._integrationManager = invalid)
  segmentLibrary.group(data.userId, data.groupId, data.traits, data.options)
  m.AssertTrue(segmentLibrary._initialRequestQueue.count() = 1)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests alias call with invalid integration manager
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure alias call is queued while remote settings are fetched
'@Params[{type: "alias", userId:"testUserId", options: "testAliasOptions"}]
function SAT__alias_queueWhileSettingsFetched(data) as void
  segmentLibrary = SegmentAnalytics(m.config)
  m.AssertTrue(segmentLibrary._initialRequestQueue.count() = 0)
  m.AssertTrue(segmentLibrary._integrationManager = invalid)
  segmentLibrary.alias(data.userId, data.options)
  m.AssertTrue(segmentLibrary._initialRequestQueue.count() = 1)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests flush call with invalid integration manager
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures flush calls are ignored while remote settings are fetched
function SAT__flush_ignoreWhileSettingsFetched() as void
  segmentLibrary = SegmentAnalytics(m.config)
  m.AssertTrue(segmentLibrary._integrationManager = invalid)
  segmentLibrary.flush()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests processMessages call
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures processMessages call gets passed to integration manager
function SAT__processMessages() as void
  m.segmentAnalytics._integrationManager = _SegmentAnalytics_IntegrationsManager(m.segmentAnalytics.config, m.segmentAnalytics)
  m.ExpectOnce(m.segmentAnalytics._integrationManager, "processMessages")
  m.segmentAnalytics.processMessages()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests processMessages call when integrationManager has not been initialized
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures integrationManager's processMessages does not get called
function SAT__processMessages_whileSettingsFetched() as void
  segmentLibrary = SegmentAnalytics(m.config)
  m.AssertTrue(segmentLibrary._integrationManager = invalid)
  segmentLibrary.processMessages()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests processMessages call with valid remote settings
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures all methods are called in order to initialize the integration manager
function SAT__processMessages_initializeIntegrationManager_validRemoteSettings() as void
  segmentLibrary = SegmentAnalytics(m.config)
  remoteSettings = {
    plan: {
      track: {
        __default: {
          integrations: {
            "Adobe Analytics": true
          }, 
          enabled: false
        }
      }
    },
    integrations: {
      "Adobe Analytics": {
        ssl: true
      }
    }
  }
  segmentLibrary._initialRequestQueue = [{type: "test"}, {type: "test"}]

  m.ExpectOnce(segmentLibrary, "_createConfigSettingsWithRemoteSettings", [remoteSettings, segmentLibrary.config.defaultSettings], remoteSettings)
  m.ExpectOnce(segmentLibrary, "_configBundledIntegrations")
  m.mockFetchRemoteSettings(segmentLibrary, 200, remoteSettings)
  

  m.AssertTrue(segmentLibrary._integrationManager <> invalid)
  m.AssertTrue(segmentLibrary._initialRequestQueue.count() = 0)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests processMessages call with invalid remote settings
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures all methods are called in order to initialize the integration manager
function SAT__processMessages_initializeIntegrationManager_invalidRemoteSettings() as void
  segmentLibrary = SegmentAnalytics(m.config)
  remoteSettings = {}
  segmentLibrary._initialRequestQueue = [{type: "test"}, {type: "test"}]

  m.ExpectOnce(segmentLibrary, "_createConfigSettingsWithRemoteSettings", [invalid, segmentLibrary.config.defaultSettings], segmentLibrary.config.defaultSettings)
  m.ExpectOnce(segmentLibrary, "_configBundledIntegrations")
  m.mockFetchRemoteSettings(segmentLibrary, 404, remoteSettings)

  m.AssertTrue(segmentLibrary._integrationManager <> invalid)
  m.AssertTrue(segmentLibrary._initialRequestQueue.count() = 0)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests fetchRemoteSettings with successful remote settings fetch
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure fetched settings are saved to local storage
function SAT__fetchRemoteSettings_successfulRemoteSettingsFetchSavedToLocalStorage() as void
  segmentLibrary = SegmentAnalytics(m.config)
  remoteSettings = {
    plan: {
      track: {
        __default: {
          integrations: {
            "Test": true
          }, 
          enabled: false
        }
      }
    },
    integrations: {
      "Adobe Analytics": {
        ssl: false
      }
    }
  }

  m.mockFetchRemoteSettings(segmentLibrary, 200, remoteSettings)

  section = createObject("roRegistrySection", "__SegmentAnalytics_Settings")
  m.AssertEqual(parseJson(section.read("RemoteSettings")), remoteSettings) 
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests fetchRemoteSettings with successful remote settings fetch
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure fetched settings are used
function SAT__fetchRemoteSettings_successfulRemoteSettingsFetch() as void
  segmentLibrary = SegmentAnalytics(m.config)
  remoteSettings = {
    plan: {
      track: {
        __default: {
          integrations: {
            "testintegration": true
          }, 
          enabled: false
        }
      }
    },
    integrations: {
      "Adobe Analytics": {
        ssl: false
      }
    }
  }

  m.mockFetchRemoteSettings(segmentLibrary, 200, remoteSettings)
  m.AssertEqual(remoteSettings, segmentLibrary.config.settings)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests fetchRemoteSettings with failed remote settings fetch
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure cached settings are used as the first fallback
function SAT__fetchRemoteSettings_failedRemoteSettingsFetchWithLocalStorage() as void
  segmentLibrary = SegmentAnalytics(m.config)
  remoteSettings = {
    plan: {
      track: {
        __default: {
          integrations: {
            "integration": true
          }, 
          enabled: false
        }
      }
    },
    integrations: {
      "Adobe Analytics": {
        ssl: false
      }
    }
  }
  response = {
    error: true
  }

  section = createObject("roRegistrySection", "__SegmentAnalytics_Settings")
  section.write("RemoteSettings", formatJson(remoteSettings))
  section.flush()

  m.mockFetchRemoteSettings(segmentLibrary, 404, response)
  m.AssertEqual(remoteSettings, segmentLibrary.config.settings)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests fetchRemoteSettings with failed remote settings with no cache
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure default settings defined by client are used as a secondary fallback
function SAT__fetchRemoteSettings_failedRemoteSettingsFetchWithDefaultSettings() as void
  config = {
    writeKey: "test"
    defaultSettings: {
      integrations: {
        "Segment.io": { test: "test" }
      }
    }
  }
  segmentLibrary = SegmentAnalytics(config)
  response = {
    error: true
  }

  section = createObject("roRegistrySection", "__SegmentAnalytics_Settings")
  section.delete("RemoteSettings")

  m.mockFetchRemoteSettings(segmentLibrary, 404, response)
  m.AssertEqual(config.defaultSettings.integrations, segmentLibrary.config.settings.integrations)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests fetchRemoteSettings with failed remote settings with no cache or defined default settings
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure default settings are used as the final fallback
function SAT__fetchRemoteSettings_failedRemoteSettingsFetchWithNoDefaultSettings() as void
  segmentLibrary = SegmentAnalytics(m.config)
  response = {
    error: true
  }

  section = createObject("roRegistrySection", "__SegmentAnalytics_Settings")
  section.delete("RemoteSettings")

  m.mockFetchRemoteSettings(segmentLibrary, 404, response)
  m.AssertEqual(segmentLibrary.config.defaultSettings, segmentLibrary.config.settings)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests saveRemoteSettingsToLocalStorage
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures input is saved to registry section __SegmentAnalytics_Settings under RemoteSettings
'@Params[{test: "testValue"}]
'@Params[{test: "testValue2"}]
'@Params["testValue2"]
function SAT__saveRemoteSettingsToLocalStorage(data) as void
  m.segmentAnalytics._saveRemoteSettingsToLocalStorage(data)
  section = createObject("roRegistrySection", "__SegmentAnalytics_Settings")
  m.AssertEqual(parseJson(section.read("RemoteSettings")), data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests createConfigSettingsWithRemoteSettings with valid data
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures input is set in config.settings and saved to cache
function SAT__createConfigSettingsWithRemoteSettings_validRemoteSettings() as void
  remoteSettings = {
    plan: {
      track: {
        __default: {
          integrations: {
            "Adobe Analytics": true
          }, 
          enabled: false
        }
      }
    },
    integrations: {
      "Adobe Analytics": {
        ssl: true
      }
    }
  }
  m.ExpectOnce(m.segmentAnalytics, "_saveRemoteSettingsToLocalStorage", [remoteSettings])
  m.segmentAnalytics.config.settings = m.segmentAnalytics._createConfigSettingsWithRemoteSettings(remoteSettings, m.segmentAnalytics.config.defaultSettings)
  m.AssertEqual(remoteSettings, m.segmentAnalytics.config.settings)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests createConfigSettingsWithRemoteSettings with invalid data and cache
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures cached settings are used to set config.settings
function SAT__createConfigSettingsWithRemoteSettings_invalidRemoteSettings_withCache() as void
  remoteSettingsCache = {test: "testValue"}
  
  m.segmentAnalytics._saveRemoteSettingsToLocalStorage(remoteSettingsCache)

  m.segmentAnalytics.config.settings = m.segmentAnalytics._createConfigSettingsWithRemoteSettings(invalid, m.segmentAnalytics.config.defaultSettings)
  m.AssertEqual(remoteSettingsCache, m.segmentAnalytics.config.settings)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests createConfigSettingsWithRemoteSettings with invalid data and invalid cache
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures default settings are used to set config.settings
function SAT__createConfigSettingsWithRemoteSettings_invalidRemoteSettings_invalidCache() as void
  remoteSettingsCache = "invalid cache"
  
  m.segmentAnalytics._saveRemoteSettingsToLocalStorage(remoteSettingsCache)

  m.segmentAnalytics.config.settings = m.segmentAnalytics._createConfigSettingsWithRemoteSettings(invalid, m.segmentAnalytics.config.defaultSettings)
  m.AssertEqual(m.segmentAnalytics.config.defaultSettings, m.segmentAnalytics.config.settings)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests createConfigSettingsWithRemoteSettings with invalid data and no cache
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensures default settings are used to set config.settings 
function SAT__createConfigSettingsWithRemoteSettings_invalidRemoteSettings_emptyCache() as void
  remoteSettingsCache = {test: "testValue"}

  'Remove cached settings in order to use default settings
  section = createObject("roRegistrySection", "__SegmentAnalytics_Settings")
  section.delete("RemoteSettings")

  m.segmentAnalytics.config.settings = m.segmentAnalytics._createConfigSettingsWithRemoteSettings(invalid, m.segmentAnalytics.config.defaultSettings)
  m.AssertEqual(m.segmentAnalytics.config.defaultSettings, m.segmentAnalytics.config.settings)
end function