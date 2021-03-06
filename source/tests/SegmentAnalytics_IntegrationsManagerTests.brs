'@TestSuite [SA_IMT] SegmentAnalytics_IntegrationsManagerTests

'@Setup
function SA_IMT__SetUp() as void
  m.allowNonExistingMethodsOnMocks = false
end function

'@BeforeEach
function SA_IMT_BeforeEach()
  m.testFactory = function(settings, analytic) 
    return {
      key: "test"
      identify: function(data)
          return true
        end function
      track: function(data)
          return true
        end function
      screen: function(data)
          return true
        end function
      group: function(data)
          return true
        end function
      alias: function(data)
          return true
        end function
      flush: function()
          return true
        end function
      processMessages: function()
          return true
        end function
    }
  end function
  m.testEmptyFactory = function(settings, analytics) 
    return {
      key: "testEmpty"
    }
  end function
  m.testExceptionFactory = function(settings, analytics) 
    return {
      key: "testException"
      exception: function(arg1 = invalid, arg2 = invalid)
        throw "Throwing test exception"
      end function
      identify: m.exception
      track: m.exception
      screen: m.exception
      group: m.exception
      alias: m.exception
      flush: m.exception
      processMessages: m.exception
    }  
  end function

  config = {
    apiHost: ""
    writeKey: "test"
    factories: { 
      test: m.testFactory
      testEmpty: m.testEmptyFactory
      testException: m.testExceptionFactory 
    }
  }
  remoteSettings = {
    integrations: {
      test: {}
      testEmpty: {}
      testException: {}
      "Segment.io": {}
    }
    plan: {
      track: {
        __default: {
          enabled: true
          integrations: {}
        }
      }
    }
  }

  m.config = {}
  m.config.append(config)
  m.config.append({settings: remoteSettings})
  m.log = _SegmentAnalytics_Logger()

  m.segmentAnalytics = {
    log: m.log
    config: m.config
    version: "1"
  }
  m.integrationManager = _SegmentAnalytics_IntegrationsManager(m.config, m.segmentAnalytics)

  for each integration in m.integrationManager._integrations
    if integration.key = "test"
      m.testIntegration = integration
    else if integration.key = "Segment.io"
      m.segmentIntegration = integration
    end if
  end for
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test valid initial constructor
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test basic constructor values
function SA_IMT__constructor_basic_success_initial() as void
  m.AssertEqual(m.integrationManager._log, m.segmentAnalytics.log)
  m.AssertEqual(m.integrationManager._integrations.count(), 4)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test createIntegrations call works as expected
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure Segment.io integration is created by default plus other integrations 
'@Params[{"writeKey": "test", "defaultSettings": {"integrations":{}}},{"count":1, "integrations":["Segment.io"]}]
'@Params[{"writeKey": "test", "defaultSettings": {"integrations":{"test": {}}}},{"count":2, "integrations":["test", "Segment.io"]}]
function SA_IMT__createIntegrations(config, expected) as void
  tempConfig = {}
  tempConfig.append(m.config)
  tempConfig.settings.integrations = config.defaultSettings.integrations

  factory = function(settings, analytics) 
    return {
      key: "test"
    }
  end function

  if tempConfig.settings.integrations.doesExist("test") then
    tempConfig.factories = { test: factory }
  else
    tempConfig.factories = {}
  end if

  integrationManager = _SegmentAnalytics_IntegrationsManager(tempConfig, m.segmentAnalytics)
  
  m.AssertEqual(integrationManager._integrations.count(), expected.count)

  for each integration in integrationManager._integrations
    integrationExists = false
    for each name in expected.integrations
      if integration.key = name then
        integrationExists = true
      end if
    end for
    m.AssertTrue(integrationExists)
  end for
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test createIntegrations with invalid factories
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test invalid factory function
'@Params[{"writeKey": "test", "defaultSettings": {"integrations":{}}},{},1]
'@Params[{"writeKey": "test", "defaultSettings": {"integrations":{"test": {}}}},{"test": false},1]
'@Params[{"writeKey": "test", "defaultSettings": {"integrations":{"test": {}}}},{"test": true},2]
'@Params[{"writeKey": "test", "defaultSettings": {"integrations":{"test": {}, "test2": {}}}},{"test": false, "test2": false},1]
'@Params[{"writeKey": "test", "defaultSettings": {"integrations":{"test": {}, "test2": {}}}},{"test": true, "test2": false},2]
function SA_IMT__createIntegrations_invalidFactory(config, setValid, expected) as void
  tempConfig = parseJson(formatJson(config))
  baseConfig = {}
  baseConfig.append(m.config)

  factory = m.testFactory
  tempConfig.factories = {}
  for each integration in config.defaultSettings.integrations.keys()
    if setValid[integration] = false
      factory = "Test"
    end if
    tempConfig.factories[integration] = factory
  end for
 
  baseConfig.append(tempConfig)
  integrationManager = _SegmentAnalytics_IntegrationsManager(baseConfig, m.segmentAnalytics)
  
  m.AssertEqual(integrationManager._integrations.count(), expected)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test createIntegrations with invalid factory parameters
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test invalid factory function parameters
'@Params[{"integrations":{}, "plan": {"track": {"__default": {"enabled": true, "integrations": {}}}}},{},1]
'@Params[{"integrations":{"Test": {}}, "plan": {"track": {"__default": {"enabled": true, "integrations": {}}}}},{"Test": false},1]
'@Params[{"integrations":{"Test": {}}, "plan": {"track": {"__default": {"enabled": true, "integrations": {}}}}},{"Test": true},2]
'@Params[{"integrations":{"Test": {}, "Test2": {}}, "plan": {"track": {"__default": {"enabled": true, "integrations": {}}}}},{"Test": false, "Test2": false},1]
'@Params[{"integrations":{"Test": {}, "Test2": {}}, "plan": {"track": {"__default": {"enabled": true, "integrations": {}}}}},{"Test": true, "Test2": false},2]
function SA_IMT__createIntegrations_invalidFactoryParameters(remoteSettings, setValid, expected) as void
  factory = m.testFactory
  invalidFactory = function()
    end function
  tempConfig = m.config
  tempConfig.factories = {}

  for each integration in remoteSettings.integrations.keys()
    if setValid[integration] = false
      factory = invalidFactory
    end if
    tempConfig.factories[integration] = factory
  end for
  
  integrationManager = _SegmentAnalytics_IntegrationsManager(tempConfig, m.segmentAnalytics)
  
  m.AssertEqual(integrationManager._integrations.count(), expected)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test isIntegrationEnabled call works as expected
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test with Segment.io and Test factory
'@Params[{"name": "unknown", "data": null },{"segmentIntegration": false, "testIntegrations": false}]
'@Params[{"name": "unknown", "data": {}},{"segmentIntegration": false, "testIntegrations": false}]
'@Params[{"name": "unknown", "data": {"integrations": { "test": true }}},{"segmentIntegration": false, "testIntegrations": false}]
'@Params[{"name": "processMessages", "data": null},{"segmentIntegration": true, "testIntegrations": true}]
'@Params[{"name": "processMessages", "data": {"integrations": { "test": true }}},{"segmentIntegration": true, "testIntegrations": true}]
'@Params[{"name": "processMessages", "data": {"integrations": { "Segment.io": false }}},{"segmentIntegration": true, "testIntegrations": false}]
'@Params[{"name": "identify", "data": null},{"segmentIntegration": true, "testIntegrations": true}]
'@Params[{"name": "identify", "data": {}},{"segmentIntegration": true, "testIntegrations": false}]
'@Params[{"name": "identify", "data": {"integrations": {}}},{"segmentIntegration": true, "testIntegrations": false}]
'@Params[{"name": "identify", "data": {"integrations": { "test": true }}},{"segmentIntegration": true, "testIntegrations": true}]
'@Params[{"name": "identify", "data": {"integrations": { "test": false }}},{"segmentIntegration": true, "testIntegrations": false}]
'@Params[{"name": "identify", "data": {"integrations": { "Segment.io": false }}},{"segmentIntegration": true, "testIntegrations": false}]
'@Params[{"name": "identify", "data": {"integrations": { "all": true }}},{"segmentIntegration": true, "testIntegrations": true}]
'@Params[{"name": "identify", "data": {"integrations": { "All": true }}},{"segmentIntegration": true, "testIntegrations": true}]
'@Params[{"name": "screen", "data": null},{"segmentIntegration": true, "testIntegrations": true}]
'@Params[{"name": "screen", "data": {}},{"segmentIntegration": true, "testIntegrations": false}]
'@Params[{"name": "screen", "data": {"integrations": {}}},{"segmentIntegration": true, "testIntegrations": false}]
'@Params[{"name": "screen", "data": {"integrations": { "test": true }}},{"segmentIntegration": true, "testIntegrations": true}]
'@Params[{"name": "screen", "data": {"integrations": { "test": false }}},{"segmentIntegration": true, "testIntegrations": false}]
'@Params[{"name": "screen", "data": {"integrations": { "Segment.io": false }}},{"segmentIntegration": true, "testIntegrations": false}]
'@Params[{"name": "screen", "data": {"integrations": { "all": true }}},{"segmentIntegration": true, "testIntegrations": true}]
'@Params[{"name": "screen", "data": {"integrations": { "All": true }}},{"segmentIntegration": true, "testIntegrations": true}]
'@Params[{"name": "group", "data": null},{"segmentIntegration": true, "testIntegrations": true}]
'@Params[{"name": "group", "data": {}},{"segmentIntegration": true, "testIntegrations": false}]
'@Params[{"name": "group", "data": {"integrations": {}}},{"segmentIntegration": true, "testIntegrations": false}]
'@Params[{"name": "group", "data": {"integrations": { "test": true }}},{"segmentIntegration": true, "testIntegrations": true}]
'@Params[{"name": "group", "data": {"integrations": { "test": false }}},{"segmentIntegration": true, "testIntegrations": false}]
'@Params[{"name": "group", "data": {"integrations": { "Segment.io": false }}},{"segmentIntegration": true, "testIntegrations": false}]
'@Params[{"name": "group", "data": {"integrations": { "all": true }}},{"segmentIntegration": true, "testIntegrations": true}]
'@Params[{"name": "group", "data": {"integrations": { "All": true }}},{"segmentIntegration": true, "testIntegrations": true}]
'@Params[{"name": "alias", "data": null},{"segmentIntegration": true, "testIntegrations": true}]
'@Params[{"name": "alias", "data": {}},{"segmentIntegration": true, "testIntegrations": false}]
'@Params[{"name": "alias", "data": {"integrations": {}}},{"segmentIntegration": true, "testIntegrations": false}]
'@Params[{"name": "alias", "data": {"integrations": { "test": true }}},{"segmentIntegration": true, "testIntegrations": true}]
'@Params[{"name": "alias", "data": {"integrations": { "test": false }}},{"segmentIntegration": true, "testIntegrations": false}]
'@Params[{"name": "alias", "data": {"integrations": { "Segment.io": false }}},{"segmentIntegration": true, "testIntegrations": false}]
'@Params[{"name": "alias", "data": {"integrations": { "all": true }}},{"segmentIntegration": true, "testIntegrations": true}]
'@Params[{"name": "alias", "data": {"integrations": { "All": true }}},{"segmentIntegration": true, "testIntegrations": true}]
function SA_IMT__isIntegrationEnabled(testInput, expected) as void
  for each integration in m.integrationManager._integrations
    if integration.key = "Segment.io" then
      m.AssertEqual(m.integrationManager._isIntegrationEnabled(integration, testInput.name, testInput.data), expected.segmentIntegration)
    else if integration.key = "test"
      m.AssertEqual(m.integrationManager._isIntegrationEnabled(integration, testInput.name, testInput.data), expected.testIntegrations)
    end if
  end for
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test isIntegrationEnabled with enabled track event
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure test integration track events are enabled when event is enabled in track plan
'@Params[{"name": "track", "data": {"event": "enabledEvent"}}, false]
'@Params[{"name": "track", "data": {"event": "enabledEvent"}}, false]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": {}}}, false]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "test": true }}}, true]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "test": false }}}, false]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "Segment.io": false }}}, false]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "all": true }}}, true]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "All": true }}}, true]
function SA_IMT__isIntegrationEnabled_trackEventsIntegrationEnabled(testInput, testIntegrationEnabled) as void
  config = m.config
  config.settings.plan = {
    track: {
      __default: {
        enabled: true
        integrations: {}
      }
      enabledEvent: {
        enabled: true
        integrations: {
          test: true
        }
      }
    }
  }
  segmentLibrary = {
    log: m.log
    config: config
    version: "1"
  }
  integrationManager = _SegmentAnalytics_IntegrationsManager(config, segmentLibrary)

  for each integration in integrationManager._integrations
    if integration.key = "Segment.io" then
      m.AssertEqual(integrationManager._isIntegrationEnabled(integration, testInput.name, testInput.data), true)
    else if integration.key = "test"
      m.AssertEqual(integrationManager._isIntegrationEnabled(integration, testInput.name, testInput.data), testIntegrationEnabled)
    end if
  end for
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test isIntegrationEnabled with undefined track plan event and enabled default settings
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure test integration track events are always enabled if set by default and not defined in track plan
'@Params[{"name": "track", "data": {"event": "enabledEvent"}}, false]
'@Params[{"name": "track", "data": {"event": "enabledEvent"}}, false]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": {}}}, false]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "test": true }}}, true]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "test": false }}}, false]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "Segment.io": false }}}, false]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "all": true }}}, true]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "All": true }}}, true]
function SA_IMT__isIntegrationEnabled_trackEventsDefaultEnabledNotInTrackPlan(testInput, testIntegrationEnabled) as void
  config = m.config
  config.settings.plan = {
    track: {
      __default: {
        enabled: true
        integrations: {}
      }
    }
  }
  segmentLibrary = {
    log: m.log
    config: config
    version: "1"
  }
  integrationManager = _SegmentAnalytics_IntegrationsManager(config, segmentLibrary)

  for each integration in integrationManager._integrations
    if integration.key = "Segment.io" then
      m.AssertEqual(integrationManager._isIntegrationEnabled(integration, testInput.name, testInput.data), true)
    else if integration.key = "test"
      m.AssertEqual(integrationManager._isIntegrationEnabled(integration, testInput.name, testInput.data), testIntegrationEnabled)
    end if
  end for
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test isIntegrationEnabled with undefined track plan event and disabled default settings
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure test integration track events are always disabled if set by default and not defined in track plan
'@Params[{"name": "track", "data": {"event": "enabledEvent"}}]
'@Params[{"name": "track", "data": {"event": "enabledEvent"}}]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": {}}}]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "test": true }}}]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "test": false }}}]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "Segment.io": false }}}]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "all": true }}}]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "All": true }}}]
function SA_IMT__isIntegrationEnabled_trackEventsDefaultDisabled(testInput) as void
  config = m.config
  config.settings.plan = {
    track: {
      __default: {
        enabled: false
        integrations: {}
      }
    }
  }
  segmentLibrary = {
    log: m.log
    config: config
    version: "1"
  }
  integrationManager = _SegmentAnalytics_IntegrationsManager(config, segmentLibrary)

  for each integration in integrationManager._integrations
    if integration.key = "Segment.io" then
      m.AssertEqual(integrationManager._isIntegrationEnabled(integration, testInput.name, testInput.data), true)
    else if integration.key = "test"
      m.AssertEqual(integrationManager._isIntegrationEnabled(integration, testInput.name, testInput.data), false)
    end if
  end for
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test isIntegrationEnabled with disabled track event integration
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure test integration track events are always disabled if integration is disabled in track plan
'@Params[{"name": "track", "data": {"event": "enabledEvent"}}]
'@Params[{"name": "track", "data": {"event": "enabledEvent"}}]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": {}}}]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "test": true }}}]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "test": false }}}]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "Segment.io": false }}}]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "all": true }}}]
'@Params[{"name": "track", "data": {"event": "enabledEvent", "integrations": { "All": true }}}]
function SA_IMT__isIntegrationEnabled_trackEventsIntegrationDisabled(testInput) as void
  config = m.config
  config.settings.plan = {
    track: {
      __default: {
        enabled: true
        integrations: {}
      }
      enabledEvent: {
        enabled: true
        integrations: {
          test: false
        }
      }
    }
  }
  segmentLibrary = {
    log: m.log
    config: config
    version: "1"
  }
  integrationManager = _SegmentAnalytics_IntegrationsManager(config, segmentLibrary)

  for each integration in integrationManager._integrations
    if integration.key = "Segment.io" then
      m.AssertEqual(integrationManager._isIntegrationEnabled(integration, testInput.name, testInput.data), true)
    else if integration.key = "test"
      m.AssertEqual(integrationManager._isIntegrationEnabled(integration, testInput.name, testInput.data), false)
    end if
  end for
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test Segment.io integration identify function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that identify is always invoked for the Segment.io integration
'@Params[{"type": "identify", "userId": "testUserId", "traits": "testIdentifyTraits"}]
'@Params[{"type": "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "test": true }}]
'@Params[{"type": "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "test": false }}]
'@Params[{"type": "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "Segment.io": false }}]
'@Params[{"type": "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "Segment.io": true }}]
'@Params[{"type": "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "all": true }}]
'@Params[{"type": "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "All": true }}]
'@Params[{"type": "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "all": false }}]
'@Params[{"type": "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "All": false }}]
function SA_IMT__identify_segmentItegration(data) as void
  m.ExpectOnce(m.segmentIntegration, "identify", [data])
  m.integrationManager.identify(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test test integration identify function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that identify is only invoked for the test integration if enabled
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits"}, false]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "test": true }}, true]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "test": false }}, false]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "Segment.io": false }}, false]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "Segment.io": true }}, false]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "all": true }}, true]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "All": true }}, true]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "all": false }}, false]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "All": false }}, false]
function SA_IMT__identify_testIntegration(data, expected) as void
  if expected then
    m.ExpectOnce(m.testIntegration, "identify", [data])
  else
    m.ExpectNone(m.testIntegration, "identify")
  end if
  m.integrationManager.identify(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test testEmpty integration identify function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that a non-existent identify function gets handled gracefully
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits"}]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "testEmpty": true }}]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "testEmpty": false }}]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "Segment.io": false }}]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "Segment.io": true }}]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "all": true }}]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "All": true }}]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "all": false }}]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "All": false }}]
function SA_IMT__identify_testEmptyIntegration(data) as void
  m.integrationManager.identify(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test testException integration identify function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that an exception throwing identify function gets handled gracefully
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits"}]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "testException": true }}]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "testException": false }}]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "Segment.io": false }}]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "Segment.io": true }}]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "all": true }}]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "All": true }}]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "all": false }}]
'@Params[{type: "identify", "userId": "testUserId", "traits": "testIdentifyTraits", "integrations": { "All": false }}]
function SA_IMT__identify_testExceptionIntegration(data) as void
  m.integrationManager.identify(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test Segment.io integration track function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that track is always invoked for the Segment.io integration
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps"}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "test": true }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "test": false }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "Segment.io": false }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "Segment.io": true }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "all": true }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "All": true }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "all": false }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "All": false }}]
function SA_IMT__track_segmentIntegration(data) as void
  m.ExpectOnce(m.segmentIntegration, "track", [data])
  m.integrationManager.track(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test test integration track function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that track is only invoked for the test integration if enabled
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps"}, false]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "test": true }}, true]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "test": false }}, false]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "Segment.io": false }}, false]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "Segment.io": true }}, false]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "all": true }}, true]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "All": true }}, true]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "all": false }}, false]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "All": false }}, false]
function SA_IMT__track_testIntegration(data, expected) as void
  if expected then
    m.ExpectOnce(m.testIntegration, "track", [data])
  else
    m.ExpectNone(m.testIntegration, "track")
  end if
  m.integrationManager.track(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test testEmpty integration track function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that a non-existent track function gets handled gracefully
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps"}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "testEmpty": true }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "testEmpty": false }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "Segment.io": false }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "Segment.io": true }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "all": true }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "All": true }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "all": false }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "All": false }}]
function SA_IMT__track_testEmptyIntegration(data) as void
  m.integrationManager.track(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test testException integration track function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that an exception throwing track function gets handled gracefully
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps"}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "testException": true }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "testException": false }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "Segment.io": false }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "Segment.io": true }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "all": true }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "All": true }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "all": false }}]
'@Params[{type: "track", "event": "testEvent", "properties": "testTrackProps", "integrations": { "All": false }}]
function SA_IMT__track_testExceptionIntegration(data) as void
  m.integrationManager.track(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test Segment.io integration screen function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that screen is always invoked for the Segment.io integration
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps"}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "test": true }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "test": false }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "Segment.io": false }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "Segment.io": true }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "all": true }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "All": true }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "all": false }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "All": false }}]
function SA_IMT__screen_segmentIntegration(data) as void
  m.ExpectOnce(m.segmentIntegration, "screen", [data])
  m.integrationManager.screen(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test test integration screen function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that screen is only invoked for the test integration if enabled
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps"}, false]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "test": true }}, true]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "test": false }}, false]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "Segment.io": false }}, false]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "Segment.io": true }}, false]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "all": true }}, true]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "All": true }}, true]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "all": false }}, false]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "All": false }}, false]
function SA_IMT__screen_testIntegration(data, expected) as void
  if expected then
    m.ExpectOnce(m.testIntegration, "screen", [data])
  else
    m.ExpectNone(m.testIntegration, "screen")
  end if
  m.integrationManager.screen(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test testEmpty integration screen function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that a non-existent screen function gets handled gracefully
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps"}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "testEmpty": true }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "testEmpty": false }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "Segment.io": false }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "Segment.io": true }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "all": true }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "All": true }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "all": false }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "All": false }}]
function SA_IMT__screen_testEmptyIntegration(data) as void
  m.integrationManager.screen(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test testException integration screen function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that an exception throwing screen function gets handled gracefully
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps"}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "testException": true }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "testException": false }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "Segment.io": false }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "Segment.io": true }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "all": true }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "All": true }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "all": false }}]
'@Params[{type: "screen", name:"testScreenName", "category": "testScreenCategory", "properties": "testScreenProps", "integrations": { "All": false }}]
function SA_IMT__screen_testExceptionIntegration(data) as void
  m.integrationManager.screen(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test Segment.io integration group function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that group is always invoked for the Segment.io integration
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits"}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "test": true }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "test": false }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "Segment.io": false }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "Segment.io": true }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "all": true }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "All": true }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "all": false }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "All": false }}]
function SA_IMT__group_segmentIntegration(data) as void
  m.ExpectOnce(m.segmentIntegration, "group", [data])
  m.integrationManager.group(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test test integration group function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that group is only invoked for the test integration if enabled
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits"}, false]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "test": true }}, true]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "test": false }}, false]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "Segment.io": false }}, false]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "Segment.io": true }}, false]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "all": true }}, true]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "All": true }}, true]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "all": false }}, false]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "All": false }}, false]
function SA_IMT__group_testIntegration(data, expected) as void
  if expected then
    m.ExpectOnce(m.testIntegration, "group", [data])
  else
    m.ExpectNone(m.testIntegration, "group")
  end if
  m.integrationManager.group(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test testEmpty integration group function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that a non-existent group function gets handled gracefully
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits"}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "testEmpty": true }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "testEmpty": false }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "Segment.io": false }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "Segment.io": true }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "all": true }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "All": true }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "all": false }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "All": false }}]
function SA_IMT__group_testEmptyIntegration(data) as void
  m.integrationManager.group(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test testException integration group function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that a exception throwing group function gets handled gracefully
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits"}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "testException": true }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "testException": false }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "Segment.io": false }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "Segment.io": true }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "all": true }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "All": true }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "all": false }}]
'@Params[{type: "group", "userId": "testUserId", "groupId": "testGroupId", "traits": "testGroupTraits", "integrations": { "All": false }}]
function SA_IMT__group_testExceptionIntegration(data) as void
  m.integrationManager.group(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test Segment.io integration alias function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that alias is always invoked for the Segment.io integration
'@Params[{type: "alias", "userId": "testUserId"}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "test": true }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "test": false }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "Segment.io": false }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "Segment.io": true }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "all": true }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "All": true }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "all": false }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "All": false }}]
function SA_IMT__alias_segmentIntegration(data) as void
  m.ExpectOnce(m.segmentIntegration, "alias", [data])
  m.integrationManager.alias(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test test integration alias function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that alias is only invoked for the test integration if enabled
'@Params[{type: "alias", "userId":"testUserId"}, false]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "test": true }}, true]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "test": false }}, false]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "Segment.io": false }}, false]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "Segment.io": true }}, false]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "all": true }}, true]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "All": true }}, true]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "all": false }}, false]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "All": false }}, false]
function SA_IMT__alias_testIntegration(data, expected) as void
  if expected then
    m.ExpectOnce(m.testIntegration, "alias", [data])
  else
    m.ExpectNone(m.testIntegration, "alias")
  end if
  m.integrationManager.alias(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test testEmpty integration alias function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that a non-existent alias function gets handled gracefully
'@Params[{type: "alias", "userId": "testUserId"}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "testEmpty": true }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "testEmpty": false }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "Segment.io": false }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "Segment.io": true }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "all": true }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "All": true }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "all": false }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "All": false }}]
function SA_IMT__alias_testEmptyIntegration(data) as void
  m.integrationManager.alias(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test testException integration alias function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that an exception throwing alias function gets handled gracefully
'@Params[{type: "alias", "userId": "testUserId"}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "testException": true }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "testException": false }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "Segment.io": false }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "Segment.io": true }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "all": true }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "All": true }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "all": false }}]
'@Params[{type: "alias", "userId": "testUserId", "integrations": { "All": false }}]
function SA_IMT__alias_testExceptionIntegration(data) as void
  m.integrationManager.alias(data)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test Segment.io integration flush function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that flush is always invoked for the Segment.io integration
function SA_IMT__flush_segmentIntegrations() as void
  m.ExpectOnce(m.segmentIntegration, "flush")
  m.integrationManager.flush()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test test integration flush function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that flush is always invoked for the test integration, unless missing
function SA_IMT__flush_testIntegrations() as void
  m.ExpectOnce(m.testIntegration, "flush")
  m.integrationManager.flush()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test testEmpty integration flush function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that a non-existent flush function gets handled gracefully
function SA_IMT__flush_testEmptyIntegration() as void
  m.integrationManager.flush()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test testException integration flush function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that an exception throwing flush function gets handled gracefully
function SA_IMT__flush_testExceptionIntegration() as void
  m.integrationManager.flush()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test Segment.io integration processMessages function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that processMessages is always invoked for the Segment.io integration
function SA_IMT__processMessages_segmentIntegrations() as void
  m.ExpectOnce(m.segmentIntegration, "processMessages")
  m.integrationManager.processMessages()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test test integration processMessages function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that processMessages is always invoked for the test integration, unless missing
function SA_IMT__processMessages_testIntegrations() as void
  m.ExpectOnce(m.testIntegration, "processMessages")
  m.integrationManager.processMessages()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test testEmpty integration processMessages function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that a non-existent processMessages function gets handled gracefully
function SA_IMT__handleRequestMessage_testEmptyIntegration() as void
  m.integrationManager.processMessages()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test testException integration processMessages function
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure that an exception throwing processMessages function gets handled gracefully
function SA_IMT__processMessages_testExceptionIntegration() as void
  m.integrationManager.processMessages()
end function
