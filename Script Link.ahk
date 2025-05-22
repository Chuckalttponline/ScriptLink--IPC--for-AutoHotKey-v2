;@Ahk2Exe-Base C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe
;DetectHiddenWindows 1
#Requires AutoHotkey v2.0+
#SingleInstance Force

/*
USAGE EXAMPLE:

;Script1
ScriptLink.threadwait("SecondThread") ; Wait for the other script to be opened and initalized if its not already.
Mainthread := ScriptLink("SecondThread") ; Variable that the class instance is being assigned to is the name of this scripts thread. The one and only parameter is the name of the script to connect to.
Mainthread.Msgbox("Hello World!, Press escape to exit both of us!") ; Have the second script display a message box.


;Script2
SecondThread := ScriptLink("Mainthread") ; Same as above except in revers so we name this script the name that the other one is connecting to and we connect to the other script.

Esc:: {
	SecondThread.ExitApp ; Exit Script 1
	ExitApp ; Exit Script 2
}

*/


Class ScriptLink {
	__New(ID:=0) {
		Persistent 1
		This.InstanceID := ID
		err := Error(, -2)
        ; Get call stack from Error object.
        stack := StrSplit(err.stack, "`n", "`r")
        ; In the first line of call stack, find one or more word characters, followed by :=, followed by NameOfThisClass(. Whitespaces are ignored.
        RegExMatch(stack[1], "(\w+)\s*:=\s*" this.__Class "\(", &M)
        ; Capture group 1 contains the variable name used to create this instance.
		MyGui := Gui("-Caption -Border -Resize +ToolWindow", M[1])
		MyGui.Show("x0 y0 w0 h0 NoActivate")
		WinHide("ahk_id " MyGui.hwnd)
		OnMessage(0x004A, (wParam, lParam, msg, hwnd)=>ScriptLink.Receive_WM_COPYDATA(wParam, lParam, msg, hwnd), true)
	}
	
	__Call(Method, Params) {
		If(Params.Length)
			ScriptLink.SendInformation(ScriptLink.Object2Str([Method,Params]), This.InstanceID)
		Else
			ScriptLink.SendInformation(ScriptLink.Object2Str([Method]), This.InstanceID)
	}
	
	
	Static SendInformation(Info, recipientID) {
		Prev_DetectHiddenWindows := A_DetectHiddenWindows
		Prev_TitleMatchMode := A_TitleMatchMode
		DetectHiddenWindows True
		SetTitleMatchMode 3
		CopyDataStruct := Buffer(3*A_PtrSize)
		SizeInBytes := (StrLen(Info) + 1) * 2
		NumPut( "Ptr", SizeInBytes, "Ptr", StrPtr(Info), CopyDataStruct, A_PtrSize)
		SendMessage(0x004A, 0, CopyDataStruct,, recipientID,,,, 100)
		DetectHiddenWindows Prev_DetectHiddenWindows
		SetTitleMatchMode Prev_TitleMatchMode
	}
	
	
	Static Receive_WM_COPYDATA(wParam, lParam, msg, hwnd) {
		StringAddress := NumGet(lParam, 2*A_PtrSize, "Ptr")
		CopyOfData := StrGet(StringAddress)
		SetTimer((*)=> ScriptLink.Prepare(CopyOfData), -1)
		return
	}
	
	Static Prepare(Data) {
		Obj := ScriptLink.Str2Object(Data)
		If(Obj.Length = 2) {
			%Obj[1]%(Obj[2]*)
		} Else {
			%Obj[1]%()
		}
	}
	
	Static ThreadWait(ThreadName, Timeout:="") {
		Prev_DetectHiddenWindows := A_DetectHiddenWindows
		Prev_TitleMatchMode := A_TitleMatchMode
		DetectHiddenWindows True
		SetTitleMatchMode 3
		
		If(Timeout = "") {
			WinWait(ThreadName)
		} else {
			WinWait(ThreadName,, Timeout)
		}
		DetectHiddenWindows Prev_DetectHiddenWindows
		SetTitleMatchMode Prev_TitleMatchMode
	}
	
	;Thanks to 'Coco' and 'AHK_user' who made Object2Str and Str2Object from the AutoHotKey forms. > https://www.autohotkey.com/boards/viewtopic.php?t=111713
	
	Static Object2Str(Var) {
	Output := ""
	if !(Type(Var) ~="Map|Array|Object|String|Number|Integer|Float"){
		throw Error("Object type not supported.", -1, Format("<Object at 0x{:p}>", Type(Var)))
	}
	if (Type(Var)="Array"){
		Output .= "["
		For Index, Value in Var{
			Output .= ((Index=1) ? "" : ",") ScriptLink.Object2Str(Value)
		}
		Output .= "]"
	} else if (Type(Var)="Map"){
		Output .= "Map("
		For Key , Value in Var {
			Output .= ((A_index=1) ? "" : ",") Key "," ScriptLink.Object2Str(Value)
		}
		Output .= ")"
	} else if (Type(Var)="Object"){
		Output .= "{"
		For Key , Value in Var.Ownprops() {
			Output .= ((A_index=1) ? "" : ",") Key ":" ScriptLink.Object2Str(Value)
		}
		Output .= "}"
	} else if (Type(Var)="String"){

		; Quotes := InStr(Var,"'") ? '"' : "'"
		; MsgBox(Var "`n" Quotes )
		Output := IsNumber(Var) ? Var : InStr(Var,"'") ? '"' Var '"' : "'" StrReplace(Var,"'","``'") "'"
	} else {
		Output := Var
	}
	if (Type(Var) ~="Map|Array" and ObjOwnPropCount(Var)>0){
		Output .= "{"
		For Key , Value in Var.Ownprops() {
			Output .= ((A_index=1) ? "" : ",") Key ":" ScriptLink.Object2Str(Value)
		}
		Output .= "}"
	}

	Return Output
}

	Static Str2Object(Input) {
		Input := Trim(Input)
		Skipnext := 0
		aLevel := Array()
		Var :=""
	
		if Regexmatch(Input, "i)^(\[|array\().*"){
			EndArrayChar := "]"
			if Regexmatch(Input, "i)^array\(.*"){
				EndArrayChar := ")"
				Input := RegExReplace(Input,"i)^array\((.*)", "[$1")
			}
			aInput := StrSplit(Input)
			Output := Array()
	
			aLevel.Push(EndArrayChar)
	
			Loop aInput.Length {
				if (A_index=1 and aInput[A_index]="["){
					continue
				} else if (Skipnext=1){
					Skipnext := 0
				} else if (aInput[A_index] ~= "``"){
					Skipnext := 1
				} else if (aLevel.length >1 and aLevel[aLevel.length]=aInput[A_index]){
					aLevel.RemoveAt(aLevel.length)
				} else if (aLevel[aLevel.length]='"' or aLevel[aLevel.length]="'"){
					; skip
				} else if (aInput[A_index]='"'){
					aLevel.Push('"')
					; continue
				} else if (aInput[A_index]="'"){
					aLevel.Push("'")
					; continue
				} else if (aInput[A_index]='{'){
					aLevel.Push('}')
				} else if (aInput[A_index]='['){
					aLevel.Push(']')
				} else if (aInput[A_index]='('){
					aLevel.Push(')')
				} else if (aLevel.length =1 and aInput[A_index]=","){
					Output.Push(ScriptLink.Str2Object(Var))
					Var :=""
					continue
				} else if (aLevel.length =1 and aInput[A_index]=aLevel[aLevel.length]){
					Output.Push(ScriptLink.Str2Object(Var))
					Rest := Trim(Substr(Input,A_Index+1))
					if (Rest!=""){
						; Hack, if an object is defined afther the array, add them as properties
						Output := AddProperties(Output,Rest)
					}
					break
				}
				if (StrLen(Var)=0 and aInput[A_index]=" "){
					continue
				}
				Var .= aInput[A_index]
			}
		} else if Regexmatch(Input, "i)^(map\().*"){
			Output := Map()
			Input := RegExReplace(Input,"i)^map\((.*)", "$1")
			aInput := StrSplit(Input)
	
			Key :=""
	
			aLevel.Push(")")
			Loop aInput.Length {
				if (aLevel.length >1 and aLevel[aLevel.length]=aInput[A_index]){
					aLevel.RemoveAt(aLevel.length)
				} else if (Skipnext=1){
					Skipnext := 0
				} else if (aInput[A_index] ~= "``"){
					Skipnext := 1
				} else if (aLevel.length >1 and aLevel[aLevel.length]='"' or aLevel[aLevel.length]="'"){
					; skip
				} else if (aInput[A_index]='"'){
					aLevel.Push('"')
				} else if (aInput[A_index]="'"){
					aLevel.Push("'")
				} else if (aInput[A_index]='{'){
					aLevel.Push('}')
				} else if (aInput[A_index]='['){
					aLevel.Push(']')
				} else if (aInput[A_index]='('){
					aLevel.Push(')')
				} else if (aLevel.length =1 and aInput[A_index]=","){
					if (Key=""){
						Key := RegexReplace(Var, "`"|'")
					} else {
						Output[Key] := ScriptLink.Str2Object(Var)
						Key := ""
					}
					Var :=""
					continue
				} else if (aLevel.length =1 and aInput[A_index]=aLevel[aLevel.length]){
					if (Key=""){
						Key := RegexReplace(Var, "`"|'")
					} else {
						Output[Key] := ScriptLink.Str2Object(Var)
						Key := ""
					}
					Rest := Trim(Substr(Input,A_Index+1))
					if (Rest!=""){
						; Hack, if an object is defined afther the map, add them as properties
						Output := AddProperties(Output,Rest)
					}
					break
				}
				if (StrLen(Var)=0 and aInput[A_index]=" "){
					continue
				}
				Var .= aInput[A_index]
			}
		} else if Regexmatch(Input, "i)^({).*"){
			Output := Object()
			Input := RegExReplace(Input,"i)^{(.*)", "$1")
			aInput := StrSplit(Input)
	
			Key :=""
	
			aLevel.Push("}")
	
			Loop aInput.Length {
				if (aLevel.length >1 and aLevel[aLevel.length]=aInput[A_index]){
					aLevel.RemoveAt(aLevel.length)
				} else if (Skipnext=1){
					Skipnext := 0
				} else if (aInput[A_index] ~= "``"){
					Skipnext := 1
				} else if (aLevel.length >1 and aLevel[aLevel.length]='"' or aLevel[aLevel.length]="'"){
					; skip
				} else if (aInput[A_index]='"'){
					aLevel.Push('"')
				} else if (aInput[A_index]="'"){
					aLevel.Push("'")
				} else if (aInput[A_index]='{'){
					aLevel.Push('}')
				} else if (aInput[A_index]='['){
					aLevel.Push(']')
				} else if (aInput[A_index]='('){
					aLevel.Push(')')
				} else if (aLevel.length =1 and aInput[A_index]=":"){
					Key := Trim(Var)
					Var :=""
					continue
				} else if (aLevel.length =1 and aInput[A_index]=","){
					Output.%Key% := ScriptLink.Str2Object(Var)
					Var :=""
					continue
				} else if (aLevel.length =1 and aInput[A_index]=aLevel[aLevel.length]){
					Output.%Key% := ScriptLink.Str2Object(Var)
					Rest := Trim(Substr(Input,A_Index+1))
					if (Rest!=""){
						MsgBox(Rest)
					}
					break
				}
				if (StrLen(Var)=0 and aInput[A_index]=" "){
					continue
				}
				Var .= aInput[A_index]
			}
		} else{
			;
			Output := RegExReplace(Input, '^\"(.*)\"$' , "$1", &Count)
			if (Count=0){
				Output := RegExReplace(Input, "^\'(.*)\'$" , "$1", &Count)
			}
			OutputDebug(Output)
			Output := Output
		}
	
		return Output
	
		AddProperties(Output,PropString){
			if Regexmatch(PropString, "i)^({).*"){
				;Output := Object()
				PropString := RegExReplace(PropString,"i)^{(.*)", "$1")
				aInput := StrSplit(PropString)
	
				Key :=""
				Var := ""
	
				aLevel := Array()
				aLevel.Push("}")
	
				Loop aInput.Length {
					if (aLevel.length >1 and aLevel[aLevel.length]=aInput[A_index]){
						aLevel.RemoveAt(aLevel.length)
					} else if (aLevel.length >1 and aLevel[aLevel.length]='"' or aLevel[aLevel.length]="'"){
						; skip
					} else if (aInput[A_index]='"'){
						aLevel.Push('"')
					} else if (aInput[A_index]="'"){
						aLevel.Push("'")
					} else if (aInput[A_index]='{'){
						aLevel.Push('}')
					} else if (aInput[A_index]='['){
						aLevel.Push(']')
					} else if (aInput[A_index]='('){
						aLevel.Push(')')
					} else if (aLevel.length =1 and aInput[A_index]=":"){
						Key := Trim(Var)
						Var :=""
						continue
					} else if (aLevel.length =1 and aInput[A_index]=","){
						Output.%Key% := ScriptLink.Str2Object(Var)
						Var :=""
						continue
					} else if (aLevel.length =1 and aInput[A_index]=aLevel[aLevel.length]){
						Output.%Key% := ScriptLink.Str2Object(Var)
						Rest := Trim(Substr(PropString,A_Index+1))
						if (Rest!=""){
							MsgBox(Rest)
						}
						break
					}
					if (StrLen(Var)=0 and aInput[A_index]=" "){
						continue
					}
					Var .= aInput[A_index]
				}
			}
			return output
		}
	}
}