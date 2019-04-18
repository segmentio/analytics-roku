'@TestSuite [SACT] SegmentAnalyticsConnectorTests

'@BeforeEach
function SACT_BeforeEach()
  m.segmentConnector = SegmentAnalyticsConnector({})
  m.config = {
    writeKey: "test"
  }
  m.segmentConnector.init(m.config)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests constructor
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test basic constructor values
function SACT__constructor_basic_success_initial() as void
  m.AssertEqual(m.segmentConnector._task.config, m.config)
end function


'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test other valid constructor values
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test other valid constructor values
'@Params[{"writeKey":"test", "queueSize":2}]
'@Params[{"writeKey":"test1", "retryLimit":2}]
'@Params[{"writeKey":"test2", "queueSize":2, "retryLimit":2}]
function SACT__constructor_basic_success_otherValues(config) as void
  segmentConnector = SegmentAnalyticsConnector({})
  segmentConnector.init(config)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It tests someEvent
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test basic test
function SACT__someEvent_basic() as void

end function

