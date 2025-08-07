Class ScriptLink { ; It takes 8-18ms for a call between scripts to come through.
	__New(Peer, Origin, Persist:=1) {
		ScriptLink.DefineProp(Peer, {Value:This}) ; Adds This instance to the static ScriptLink class for alternative ways to access an instance.
		This.GUID := ComObject("Scriptlet.TypeLib").GUID
		This.Package := Map()
		This.InstanceID := Peer
		This.Obj := False
		ScriptLink.ObjRegisterActive(This.Package, This.GUID)
		Persistent(Persist)
		This.MsgNet := Gui("-Caption -Border -Resize +ToolWindow", Origin)
		This.MsgNet.Show("x0 y0 w0 h0 NoActivate")
		WinHide("ahk_id " This.MsgNet.hwnd)
		OnMessage(0x004A, InterScriptCallback(wParam, lParam, msg, hwnd)=>This.Receive_WM_COPYDATA(wParam, lParam, msg, hwnd), 1)
		ScriptLink.ThreadWait(Peer)
		This.SendInformation(This.GUID, This.InstanceID)
	}
	
	Static __Item[Name] {
		Get => ScriptLink.%Name% ; Allows for Map style calling of an instance instead of property only.
	}
	
	__Call(Method, Params) {
	 ; Tooltip Method '`n' Params.Length ; Dev test
		CallID := Random(0,9) Random(0,9) Random(0,9) Random(0,9) Random(0,9) Random(0,9) Random(0,9) Random(0,9)
			If(Params.Length) {
				This.Package[CallID] := [Method, Params]
			} Else {
				This.Package[CallID] := [Method]
			}
		This.SendInformation(CallID, This.InstanceID)
		
	
		If(Method = "ExitApp") { ; The object shared by the recipient script maybe dead if this one closes first in the event that ExitApp is the very next command after sending ExitApp to this script. 
			Prev_DetectHiddenWindows := A_DetectHiddenWindows
			Prev_TitleMatchMode := A_TitleMatchMode
			DetectHiddenWindows True
			SetTitleMatchMode 3
			WinWaitClose(This.InstanceID)
			DetectHiddenWindows Prev_DetectHiddenWindows
			SetTitleMatchMode Prev_TitleMatchMode
		}
	}
	
	Execute(Data) {
			If(Not This.Obj) {
				This.Obj := ComObjActive(Data)
				Return
			}
		Try	If(This.Obj[Data].Length = 2) {
				%This.Obj[Data][1]%(This.Obj[Data][2]*)
			} Else {
				%This.Obj[Data][1]%()
			}
			
			;Tooltip This.Obj[Data][1] '`n' Data '`n' This.Obj.Count ; Dev Test
			Try This.Obj.Delete(Data)
	}
	
	__Delete() {
		OnMessage(0x004A, InterScriptCallback(wParam, lParam, msg, hwnd)=>This.Receive_WM_COPYDATA(wParam, lParam, msg, hwnd), 0)
	}
	
	Static ObjGUIDRef := []
	Static CleanUpSet := True OnExit((*)=>ScriptLink.DeleteObjRefs())
	
	Static DeleteObjRefs() {
		Loop(ScriptLink.ObjGUIDRef.Length) {
			Try RegDelete("HKEY_CURRENT_USER\Software\AutoHotKey.ScriptLink", ScriptLink.ObjGUIDRef[A_Index])
		}
	}
	
	Static Global(Data) {
			If(IsObject(Data)) {
			GUID := ComObject("Scriptlet.TypeLib").GUID
			ScriptLink.ObjRegisterActive(Data, GUID)		
			Info := Error(, -2)
			Name :=	StrSplit(StrSplit(Info.stack, "`n", "`r")[1], ".Global(")[2]
			Name := Trim(SubStr(Name, 1, InStr(Name, ")",, -1, -1) -1))
			RegWrite(GUID, "REG_EXPAND_SZ", "HKEY_CURRENT_USER\Software\AutoHotKey.ScriptLink", Name)
			ScriptLink.ObjGUIDRef.Push(Name)
		} else {
			Temp := RegRead("HKEY_CURRENT_USER\Software\AutoHotKey.ScriptLink", Data, False)
			Return Temp ? ComObjActive(Temp) : 0
		}
	}
	
	SendInformation(Info, recipientID) {
		Prev_DetectHiddenWindows := A_DetectHiddenWindows
		Prev_TitleMatchMode := A_TitleMatchMode
		DetectHiddenWindows True
		SetTitleMatchMode 3
		Info := String(Info)
		CopyDataStruct := Buffer(3*A_PtrSize)
		SizeInBytes := (StrLen(Info) + 1) * 2
		NumPut( "Ptr", SizeInBytes, "Ptr", StrPtr(Info), CopyDataStruct, A_PtrSize)
		SendMessage(0x004A, 0, CopyDataStruct,, recipientID)
		DetectHiddenWindows Prev_DetectHiddenWindows
		SetTitleMatchMode Prev_TitleMatchMode
	}
	
	
	Receive_WM_COPYDATA(wParam, lParam, msg, hwnd) {
		StringAddress := NumGet(lParam, 2*A_PtrSize, "Ptr")
		CopyOfData := StrGet(StringAddress)
		SetTimer((*)=> This.Execute(CopyOfData), -1)
	}
	
	
	Static ThreadWait(Win, Timeout:="") {
		Prev_DetectHiddenWindows := A_DetectHiddenWindows
		Prev_TitleMatchMode := A_TitleMatchMode
		DetectHiddenWindows True
		SetTitleMatchMode 3
		
		If(Timeout = "") {
			WinWait(Win)
		} else {
			WinWait(Win,, Timeout)
		}
		DetectHiddenWindows Prev_DetectHiddenWindows
		SetTitleMatchMode Prev_TitleMatchMode
	}
	
	Static ThreadExist(Win) {
		Prev_DetectHiddenWindows := A_DetectHiddenWindows
		Prev_TitleMatchMode := A_TitleMatchMode
		DetectHiddenWindows True
		SetTitleMatchMode 3
		Temp := WinExist(Win)
		DetectHiddenWindows Prev_DetectHiddenWindows
		SetTitleMatchMode Prev_TitleMatchMode
		Return Temp ? 1 : 0
	}
	
	; Thanks to Lexikos > https://www.autohotkey.com/boards/viewtopic.php?t=115333
	Static ObjRegisterActive(Object, CLSID, Flags := 0) {
		static cookieJar := Map()
		cookie := 0
		if (!CLSID) {
			if !(cookie := cookieJar.Has(Object)) || (cookie := cookieJar.Delete(Object)) != ""
				DllCall("oleaut32\RevokeActiveObject", "uint", cookie, "ptr", 0)
			return
		}
		if cookieJar.Has(Object)
			throw Error("Object is already registered", -1)
		_clsid := Buffer(16, 0)
		if (hr := DllCall("ole32\CLSIDFromString", "wstr", CLSID, "ptr", _clsid)) < 0
			throw Error("Invalid CLSID", -1, CLSID)
	
		hr := DllCall("oleaut32\RegisterActiveObject", "ptr", ObjPtr(Object), "ptr", _clsid, "uint", Flags, "uint*", &cookie, "uint")
		if (hr < 0)
			throw Error(format("Error 0x{:x}", hr), -1)
		cookieJar[Object] := cookie
	}
}

