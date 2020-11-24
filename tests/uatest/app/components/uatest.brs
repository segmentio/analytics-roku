function init()
  m.top.setFocus(true)
  m.statusLabel = m.top.findNode("statusLabel")
	m.uatestLabel = m.top.findNode("uatestLabel")
	m.inputInfoLabel = m.top.findNode("inputInfoLabel")
  m.global.id = "new id"
  m.global.addFields({statusLabel: m.statusLabel})
  m.global.addFields({inputInfoLabel: m.inputInfoLabel})

  m.inputInfoLabel.color = "0xFFFFFF"
  m.inputInfoLabel.font.size = 10
	m.inputInfoLabel.text = "Waiting for input..."

  m.uatestLabel.color = "0x49B882"
	m.uatestLabel.font.size = 20

  m.appInfo = CreateObject("roAppInfo")
  writeKey = m.appInfo.GetValue("analytics_write_key")
  if writeKey = "" then
    print "********** ERROR: writeKey is not defined. Exiting. **********"
    ExitUserInterface = ExitUserInterface
    ExitUserInterface()
  endif
  apiHost = m.appInfo.GetValue("analytics_server")

  task = m.top.findNode("analyticsTask")
  m.analytics = SegmentAnalyticsConnector(task)

  config = {
    writeKey: writeKey
  }
  m.analytics.init(config)

end function

function makeEventOptions(event) as object
  ' make an associative array to be passed in as 'options' in the analytics functions.
  options = {}

  ' todo: extract common logic into helper functions.

  if event.DoesExist("userId") then
    options["userId"] = event["userId"]
  endif

  if event.DoesExist("anonymousId") then
    options["anonymousId"] = event["anonymousId"]
  end if

  if event.DoesExist("context") and len(event["context"]) > 0 then
    options["context"] = ParseJson(event["context"].Unescape())
  end if

  if event.DoesExist("integrations") and len(event["integrations"]) > 0 then
    options["integrations"] = ParseJson(event["integrations"].Unescape())
  end if

  return options
end function

function processEvents(eventList as object, regenerateMsgId=true as boolean) as boolean
    ? "DEBUG processEvents() called"
		for each event in eventList:
			if event.DoesExist("type") then

        if regenerateMsgId then
          msgId = invalid
        else
          msgId = event.Lookup("messageId")
        endif

        if event.type = "track" then
          event.options["messageId"] = msgId
				  m.analytics.track(event["event"], event.Lookup("properties"), event.options)

        elseif event.type = "identify" then
          event.options["messageId"] = msgId
				  m.analytics.identify(event.Lookup("userId"), event.Lookup("traits"), event.options)

        elseif event.type = "group" then
          event.options["messageId"] = msgId
				  m.analytics.group(event.Lookup("userId"), event.Lookup("groupId"), event.Lookup("traits"), event.options)

        elseif event.type = "screen" then
          event.options["messageId"] = msgId
				  m.analytics.screen(event.Lookup("name"), event.Lookup("category"), event.Lookup("properties"), event.options)

        elseif event.type = "page" then
          event.options["messageId"] = msgId
				  m.analytics.page(event.Lookup("name"), event.Lookup("category"), event.Lookup("properties"), event.options)

        elseif event.type = "alias" then
          event.options["previousId"] = event.Lookup("previousId")
          event.options["messageId"] = msgId
				  m.analytics.alias(event.Lookup("userId"), event.options)

        endif
			else ' not event.DoesExist("type")
        print "ERROR: message does not contain 'type'"
				return false
			endif
		end for
    return true
end function

function processEventFromECP(ecpInputArray) as boolean
  res = false
  ' expected ECP format (as required by library-e2e-tester):
  '   type=<type>
  '   writeKey=<writeKey>
  '   userId=<userId>
  '   [event=<event> properties=<properties>] # Track
  '   [name=<name> properties=<properties>] # Page/Screen
  '   [traits=<traits>] # Identify
  '   [groupId=<groupId> traits=<traits>] # Group
  m.global.inputInfoLabel.text = "Got ECP command: type=" + ecpInputArray.type
  msg = {"userId": ecpInputArray.userId, "type": ecpInputArray.type}
  msg["options"] = makeEventOptions(ecpInputArray)

  if ecpInputArray.DoesExist("writeKey") then
    'm.analytics.AnalyticsTask.writeKey = ecpInputArray.writeKey
    ' TODO: fix this once there's a function in library to change writeKey
  endif

  if msg.type = "identify" then
    if ecpInputArray.DoesExist("traits") then
      msg["traits"] = ParseJson(ecpInputArray.traits)
    endif

  elseif msg.type = "track" then
    msg["event"] = ecpInputArray.Lookup("event")
    if msg.event = invalid then
      ? "[ERROR] track: undefined 'event'"
      return false
    endif
    if ecpInputArray.DoesExist("properties") then
      msg["properties"] = ParseJson(ecpInputArray.properties)
    endif

  elseif msg.type = "screen" or msg.type = "page" then
    msg["name"] = ecpInputArray.Lookup("name")
    if msg["name"] = invalid then
      ? "[ERROR] screen: undefined 'name'"
      return false
    endif
    if ecpInputArray.DoesExist("properties") then
      msg["properties"] = ParseJson(ecpInputArray.properties)
    endif

  elseif msg.type = "group" then
    msg["groupId"] = ecpInputArray.Lookup("groupId")
    if msg["groupId"] = invalid then
      ? "[ERROR] screen: undefined 'groupId'"
      return false
    endif
    if ecpInputArray.DoesExist("traits") then
      msg["traits"] = ParseJson(ecpInputArray.traits)
    endif

  elseif msg.type = "alias" then
    msg["previousId"] = ecpInputArray.Lookup("previousId")
    if msg.previousId = invalid then
      ? "[ERROR] screen: undefined 'previousId'"
      return false
    endif
  endif

  return processEvents([msg])
end function

function processECPInput(ecpInputArray) as boolean
	? "-- processECPInput called"
  ? "DEBUG ecpInputArray: "; ecpInputArray
	res = true

  if ecpInputArray.DoesExist("type") and ecpInputArray.DoesExist("userId") then
    res = processEventFromECP(ecpInputArray)
  else
		? "unknown command or missing parameters"
    m.global.inputInfoLabel.text = "Invalid ECP input"
    return false
  endif
	return res
end function
