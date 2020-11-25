'@TestSuite [SA_LT] SegmentAnalytics_LoggerTests

'@BeforeEach
function SA_LT_BeforeEach()
  m.Logger = _SegmentAnalytics_Logger()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It testing logging function runs as expected
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensuring log works with correct use cases
'@Params[{"writeKey": "test", "debug": true}]
function SA_LT__log_successful(config) as void
  m.Logger.debugEnabled = true
  isDebugLogged = m.Logger.debug("TestDebug")
  m.AssertEqual(isDebugLogged, true)
  isErrorLogged = m.Logger.error("TestError")
  m.AssertEqual(isErrorLogged, true)
end function
  
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It testing logging function does not get invoked
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure we don't call print inadvertently with debug on
function SA_LT__log_fail() as void
  m.Logger.debugEnabled = false
  isDebugLogged = m.Logger.debug("TestDebug")
  m.AssertEqual(isDebugLogged, false)
  isErrorLogged = m.Logger.error("TestError")
  m.AssertEqual(isErrorLogged, true)
end function