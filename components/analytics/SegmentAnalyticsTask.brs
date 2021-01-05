sub init()
  m.top.functionName = "execute"
end sub

sub execute()
  setup()
  startEventLoop()
  cleanup()
end sub

sub setup()
  m.port = createObject("roMessagePort")

  config = m.top.config
  'bs:disable-next-line
  config.factories = use()
  m.service = SegmentAnalytics(config)

  m.top.observeField("event", m.port)
  
  m.taskCheckInterval = 250 ' Represents the milliseconds the task should run it's event loop
end sub

sub startEventLoop()
  if m.service = invalid then
    return
  end if
  
  if m.top.event <> invalid then
    handleEvent(m.top.event)
  end if

  while (true)
    message = wait(m.taskCheckInterval, m.port)
    if message = invalid then
      m.service.processMessages()
    else
      messageType = type(message)
      if messageType = "roSGNodeEvent" then
        field = message.getField()
        if field = "event" then
          handleEvent(message.getData())
        end if
      end if
    end if 
  end while
end sub

sub cleanup()

end sub

sub handleEvent(data)
  name = data.name
  if name = invalid then
    return
  end if

  if name = "identify" then
    m.service.identify(data.payload.userId, data.payload.traits, data.payload.options)
  else if name = "track" then
    m.service.track(data.payload.event, data.payload.properties, data.payload.options)
  else if name = "screen" then
    m.service.screen(data.payload.name, data.payload.category, data.payload.properties, data.payload.options)
  else if name = "group" then
    m.service.group(data.payload.userId, data.payload.groupId, data.payload.traits, data.payload.options)
  else if name = "alias" then
    m.service.alias(data.payload.userId, data.payload.options)
  end if
end sub
