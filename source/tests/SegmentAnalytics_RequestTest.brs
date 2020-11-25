'@TestSuite [SA_RT] SegmentAnalytics_RequestTests

'@Setup
function SA_RT__SetUp() as void
  m.allowNonExistingMethodsOnMocks = false
end function

'@BeforeEach
function SA_RT_BeforeEach()
  m.log = _SegmentAnalytics_Logger()
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test successful handleMessage call
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test handleMessage with successful object
'@Params[200, {"success": true}]
function SA_RT__handleMessage_success(responseCode, rawResponse) as void
  urlTransfer = createObject("roUrlTransfer")

  options = {
    urlTransfer: urlTransfer
    method: "POST"
    url: ""
  }

  request = _SegmentAnalytics_Request(options, m.log, {})
  request.handled = function(requestId)
      return true
    end function
  handler = function(response, request)
      request.handled(request.id)
    end function

  request.success(handler)
  
  message = {
    _type: "roUrlEvent"
    urlTransfer: urlTransfer
    responseCode: responseCode
    rawResponse: formatJson(rawResponse)
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

  m.ExpectOnce(request, "handled", [message.urlTransfer.getIdentity()])
  request.handleMessage(message)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test unsuccessful handleMessage call
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test handleMessage with unsuccessful object
'@Params[403, {"success": true}]
'@Params[404, {"success": true}]
'@Params[429, {"success": true}]
'@Params[500, {"success": true}]
'@Params[501, {"success": true}]
function SA_RT__handleMessage_fail(responseCode, rawResponse) as void
  urlTransfer = createObject("roUrlTransfer")

  options = {
    urlTransfer: urlTransfer
    method: "POST"
    url: ""
  }

  request = _SegmentAnalytics_Request(options, m.log, {})
  request.handled = function(requestId)
      return true
    end function
  handler = function(response, request)
      request.handled(request.id)
    end function

  request.error(handler)
  
  message = {
    _type: "roUrlEvent"
    urlTransfer: urlTransfer
    responseCode: responseCode
    rawResponse: formatJson(rawResponse)
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

  m.ExpectOnce(request, "handled", [message.urlTransfer.getIdentity()])
  request.handleMessage(message)
end function

'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
'@It test handleMessage exception
'+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

'@Test ensure handleMessage handles invalid JSON objects gracefully
'@Params[200, "'success': true"]
function SA_RT__handleMessage_invalid(responseCode, rawResponse) as void
  urlTransfer = createObject("roUrlTransfer")

  options = {
    urlTransfer: urlTransfer
    method: "POST"
    url: ""
  }

  request = _SegmentAnalytics_Request(options, m.log, {})
  request.handled = function(requestId)
      return true
    end function
  handler = function(response, request)
      request.handled(request.id)
    end function

  request.error(handler)
  
  message = {
    _type: "roUrlEvent"
    urlTransfer: urlTransfer
    responseCode: responseCode
    rawResponse: rawResponse
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

  m.ExpectOnce(request, "handled", [message.urlTransfer.getIdentity()])
  request.handleMessage(message)
end function