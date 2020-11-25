sub init()
  m.itemmask = m.top.findNode("itemMask")
  m.itemlabel = m.top.findNode("itemLabel")
end sub

sub showContent()
  itemcontent = m.top.itemContent
  m.itemlabel.text = itemcontent.title
end sub

sub showFocus()
  if m.top.focusPercent = 1 then
    m.itemlabel.opacity = 1
    m.itemmask.opacity = 1
  else
    m.itemlabel.opacity = .5
    m.itemmask.opacity = .5
  end if
end sub