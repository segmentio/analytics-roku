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
  m.service = SegmentAnalytics(m.top.config, m.port)
  m.top.observeField("event", m.port)
  m.queueFlushTime = 30 ' This value represents seconds default to 30 seconds
  m.taskCheckInterval = 500 ' Represents the milliseconds the task should run it's event loop
end sub

sub startEventLoop()
  if m.service = invalid then
    return
  end if

  clock = CreateObject("roTimespan")
  clock.mark()
  nextQueueFlush = clock.totalSeconds() + m.queueFlushTime

  if m.top.event <> invalid then
    handleEvent(m.top.event)
  end if

  while (true)
    message = wait(m.taskCheckInterval, m.port)
    messageType = type(message)

    if messageType = "roSGNodeEvent" then
      field = message.getField()

      if field = "event" then
        handleEvent(message.getData())
        nextQueueFlush = clock.totalSeconds() + m.queueFlushTime
      end if
    else if messageType = "roUrlEvent" then
      m.service.handleRequestMessage(message, clock.totalSeconds())
      nextQueueFlush = clock.totalSeconds() + m.queueFlushTime
    end if

    if clock.totalSeconds() > nextQueueFlush then
      m.service.flush()
      nextQueueFlush = clock.TotalMilliseconds() + m.queueFlushTime
    else if m.service._inProgressId = invalid
      m.service.checkRequestQueue(clock.totalSeconds())
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
