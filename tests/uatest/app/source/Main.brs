sub RunUserInterface(args)
  'Indicate this is a Roku SceneGraph application'
  screen = CreateObject("roSGScreen")
  m.msgPort = CreateObject("roMessagePort")

  scene = screen.CreateScene("UATest")
	m.global = screen.getGlobalNode()
	m.global.id = "GlobalNode"
    m.global.addFields({screen: screen})

    screen.show()

    APPInfo = createObject("roAPPInfo")
    if APPInfo.IsDev() and args.RunTests = "true" and TF_Utils__IsFunction(TestRunner) then
      print "RUNNING TEST"
      Runner = TestRunner()
      Runner.logger.SetVerbosity(2)
      Runner.RUN()
    end if

    m.input = CreateObject("roInput")
    m.input.setMessagePort(m.msgPort)

    while(true)
      print "Waiting for input..."
      msg = wait(0, m.msgPort)
      if type(msg) = "roInputEvent"
        if msg.isInput()
          result = scene.callFunc("processECPInput", msg.GetInfo())
          m.global.statusLabel.text = "Processed input via ECP, result="+ result.toStr()
        end if
      end if
    end while
end sub

