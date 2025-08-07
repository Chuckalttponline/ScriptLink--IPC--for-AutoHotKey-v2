
##ScriptLink VERSION 2.0-beta

# AutoHotkey ScriptLinking

This Class 'ScriptLink' will allow you to call any function from a seperate script and pass any amount of vairables and objects as parameters to the given function.
the script will not return a "Return" any kind of value becuase we are mostly going for speed via multiple processes but you can have it call back a function in the script that called it.

# What to expect for future updates
1. The ability to call classes and there methods instead of just functions and there parameters.
2. Possibly an option for returning values.
3. I honestly just for got so I'll update this when I remember 🤣🤣🤣.


## Usage

The way this works is there are 3 Parameters when you initalize an instance:
Param 1. `Peer` Peer is the script to connect to.
Param 2. `Oigin` Origin is this script.
Param 3. `Persist` This is by default True its the same as calling `Persistent(Boolean)`

There are 3 ways to use an instance of ScriptLink! Keep in mind these are all interchangeable and all work any time.
1. `VarInstaceWasAssignedTo.FunctionToCall("Param1", "Param2", "Param3")` Recomended for one on one.
2. `ScriptLink.PeerName.FunctionToCall("Param1", "Param2", "Param3")` Recomended for having multiple instances and calling to multiple scripts.
3. `ScriptLink["PeerName"].FunctionToCall("Param1", "Param2", "Param3")` Recomended for other things such as storing several peernames in an array and then looping through it to call each instance.
use which ever you prefer.

## A demonstraion of basic Funcion Calling includes all 3 ways of doing it.

### Script 1
```ahk
ScriptLink("Chuck", "Deslin")

SomeFunc(Value) {
    Msgbox Value
}

3:: {
    TrayTip("Hello Script 1 This is Script 2 calling because Script one told me to.")
    ToolTip("Hello Script 2 This is Script 1")
}

Esc:: {
    ScriptLink["Chuck"].ExitApp()
    ExitApp()
}
```

### Script 2
```ahk
Var := ScriptLink("Deslin", "Chuck")

1::ScriptLink.Deslin.Msgbox(InputBox("Title", "Prompt").Value)
2::Var.SomeFunc("A Value")
```

## A Demonstarion of making an object global and then using it! Run Script 1 first.

### Script 1
```ahk
AnObject := Map()
AnObject["Test"] := "Hello World!"
ScriptLink.Global AnObject
Msgbox "Run Script 2"
```

### Script 2
```ahk
TheObject := ScriptLink.Global("AnObject")
Msgbox TheObject["Test"]
```

## Or

### Script 1
```ahk
AnObject := Gui()
AnObject.Show("w200 h100")
ScriptLink.Global AnObject
Msgbox "Run Script 2"
Sleep(5000)
ExitApp()
```

### Script 2
```ahk
TheObject := ScriptLink.Global("AnObject")
TheObject.Add("Text",,"Hello World!")
Sleep(1000)
TheObject.Show("AutoSize")
Sleep(5000)
ExitApp()
```




### Script Synchronization
If you need to check if a script has intialized an instance of ScriptLink use:

```ahk
ScriptLink.ThreadExist("PeerName")
```

## Rules\Limits
1. You may Call ANY function.
2. Any kind of parameters Except for `&VarRef` and its counter part `%VarRef%`, Things that can be passed are [Objects, Integers, Strings] (Global Objects are interduced sence v2.0-beta)
3. You **cannot directly call a method inside a class**, but you can wrap the call in a function that gets executed by another script using ScriptLink.
4. When Using `ScriptLink.Global` One must make sure that the object is declard global before it is retreivable by another script...

## Q&A

### Q: Why don't functions return a value when called from another script?
**A:** Because that defeats the purpose—forcing the script to wait, negating the advantage of using another process to do stuff while the caller continues on doing what ever it needs.

### Q: Can I pass a GUI to another script?
**A:** Yes you can!, as far as my testing goes it works seamlessly, both scripts see the changes.


VERSION 3.0 comming ~~soon~~* Someday.

Enjoy, If you choose to test it I'd appreciate it if you let me know if there's something you find thats feels like its missing, or if there's some bug.
