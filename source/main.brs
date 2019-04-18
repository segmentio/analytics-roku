sub main(args)
  if args.RunTests <> invalid
    if (type(Rooibos__Init) = "Function") then
      Rooibos__Init()
    end if
  end if

  initScreen()
end sub

function initScreen() as void
  screen = createObject("roSGScreen")
  m.port = createObject("roMessagePort")
  screen.setMessagePort(m.port)
  
  rootScene = screen.createScene("MainScene")
  rootScene.id = "ROOT"

  screen.show()
  
  while(true)
    msg = wait(0, m.port)
    msgType = type(msg)
  
    if msgType = "roSGScreenEvent"
      if msg.isScreenClosed() 
        return
      end if
    end if
  end while
end function
