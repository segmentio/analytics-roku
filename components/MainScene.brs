sub init()
  task = m.top.findNode("libraryTask")
  m.library = SegmentAnalyticsConnector(task)

  config = {
    writeKey: "test"
    debug: true
    queueSize: 1
    retryLimit: 1
  }

  m.library.init(config)

  findViews()
  setContent()
  setupListeners()
  m.rowlist.setFocus(true)
end sub

sub findViews()
  m.rowlist = m.top.findNode("exampleRowList")
end sub

sub setContent()
  m.rowlist.content = CreateObject("roSGNode", "RowListContent")
end sub

sub setupListeners()
  m.rowList.observeField("rowItemSelected", "onItemSelected")
end sub

sub onItemSelected()
  if m.top.focusedChild.rowItemFocused[1] = 0 then
    m.library.identify("testUserId", invalid, invalid)
  else if m.top.focusedChild.rowItemFocused[1] = 1 then
    m.library.track("testTrackEvent", invalid, {"anonymousId": "testAnonId"})
  else if m.top.focusedChild.rowItemFocused[1] = 2 then
    m.library.screen("testScreenName", invalid, invalid, {"anonymousId": "testAnonId"})
  else if m.top.focusedChild.rowItemFocused[1] = 3 then
    m.library.group("testUserId", "testGroupId", invalid, {})
  else if m.top.focusedChild.rowItemFocused[1] = 4 then
    m.library.alias("testNewId", {"previousId": "testPrevId"})
  end if
end sub



