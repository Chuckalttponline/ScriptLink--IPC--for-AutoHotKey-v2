
# AutoHotkey ScriptLinking

Thanks to **'Coco'** and **'AHK_user'** who made Object2Str and Str2Object from the AutoHotKey forums.  
> [Source](https://www.autohotkey.com/boards/viewtopic.php?t=111713)  
I didn't have to do that part myself 😆.

## Usage

### Script 1
```ahk
ScriptLink.threadwait("SecondThread") ; Wait for the other script to be opened and initialized if it's not already.
Mainthread := ScriptLink("SecondThread") ; The class instance is assigned to the script’s thread name.
Mainthread.Msgbox("Hello World!, Press escape to exit both of us!") ; Have the second script display a message box.
```

### Script 2
```ahk
SecondThread := ScriptLink("Mainthread") ; Same as above, but in reverse—connecting to the other script.

Esc:: {
    SecondThread.ExitApp ; Exit Script 1
    ExitApp ; Exit Script 2
}
```

### Thread Synchronization
If you need to wait for a thread to be opened because your scripts need to work together without errors when started in any order, use:

```ahk
ScriptLink.threadwait("Name of the thread to wait for", Timeout in seconds)
```

## Rules
1. You can pass as many parameters as the function you are calling can accept.
2. **You can't pass GUI objects.**
3. Regular objects can be passed, but their usage changes:
   - From: `SomeObj["Key1"]`
   - To: `SomeObj.Key1`
4. You can pass **arrays, strings, and integers** without issues.
5. You **cannot directly call a method inside a class**, but you can wrap it in a function that gets executed by ScriptLink.

## Q&A

### Q: Why don't functions return a value when called from another script?
**A:** Because that defeats the purpose—forcing the script to wait, negating the advantage of using another process.

### Q: Why can't I pass a GUI to another script?
**A:** That just doesn’t work...


An example is included in the class file.
```

This README will now look clean, structured, and easy to read when uploaded to GitHub. Let me know if you’d like any modifications! 🚀
