function init()
  m.top.setFocus(true)
  m.helloLabel = m.top.findNode("helloLabel")
  m.statusLabel = m.top.findNode("statusLabel")
  m.actionLabel = m.top.findNode("actionLabel")
  m.global.id = "new id"
  m.global.addFields({helloLabel: m.helloLabel, statusLabel: m.statusLabel
                      actionLabel: m.actionLabel})

  m.helloLabel.font.size=100
  m.helloLabel.color="0x49B882"

  m.actionLabel.color="0x72D7EE"
  m.actionLabel.font.size=20

  m.statusLabel.text = "Application Opened"
  m.statusLabel.color="0xFFFFFF"
  m.statusLabel.font.size=15

  m.appInfo = CreateObject("roAppInfo")
  writeKey = m.appInfo.GetValue("analytics_write_key")
  if writeKey = "" then
    print "********** ERROR: writeKey is not defined. Exiting. **********"
    ExitUserInterface()
  endif

  task = m.top.findNode("analyticsTask")
  m.analytics = SegmentAnalyticsConnector(task)

  config = {
    writeKey: writeKey
  }
  m.analytics.init(config)

  startUpEvents()

end function

function startUpEvents()
  userId = "sampleUser"
  m.analytics.identify(userId, {"email": "sampleuser@example.com"})
  m.options = {"userId": userId}

  m.analytics.track("Application Opened", {}, m.options)
  m.analytics.screen("Startup screen", invalid, invalid, m.options)
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  handled = false
  if press then
    if (key = "back") then
      handled = false
    else
      m.analytics.track(key + " key pressed", invalid, m.options)
      handled = true
    end if
  end if
  return handled
end function
