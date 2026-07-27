#Requires AutoHotkey v2.0
#SingleInstance Force

#Include ..\Modules\Windows.ahk

global Mule1Hwnd := 0
global Mule2Hwnd := 0

; Coloque aqui as coordenadas da notificação
; que estão no Characters.ini.
global NotificationX := 913
global NotificationY := 143

F2::
{
    global Mule1Hwnd

    Mule1Hwnd := GetActivePWWindowTest()

    if !Mule1Hwnd
    {
        MsgBox "Nenhuma janela válida encontrada."
        return
    }

    ToolTip "Mula 1 cadastrada: " Mule1Hwnd
    SetTimer(() => ToolTip(), -2000)
}

F3::
{
    global Mule2Hwnd

    Mule2Hwnd := GetActivePWWindowTest()

    if !Mule2Hwnd
    {
        MsgBox "Nenhuma janela válida encontrada."
        return
    }

    ToolTip "Mula 2 cadastrada: " Mule2Hwnd
    SetTimer(() => ToolTip(), -2000)
}

; Testa somente a Mula 1.
F9::
{
    global Mule1Hwnd
    global NotificationX, NotificationY

    if !Mule1Hwnd
    {
        MsgBox "Cadastre a Mula 1 usando F2."
        return
    }

    PWWindows.BackgroundLeftClick(
        Mule1Hwnd,
        NotificationX,
        NotificationY,
        100
    )

    Sleep 100

    PWWindows.SendKey(
        Mule1Hwnd,
        "y",
        100
    )
}

; Testa somente a Mula 2.
F10::
{
    global Mule2Hwnd
    global NotificationX, NotificationY

    if !Mule2Hwnd
    {
        MsgBox "Cadastre a Mula 2 usando F3."
        return
    }

    PWWindows.BackgroundLeftClick(
        Mule2Hwnd,
        NotificationX,
        NotificationY,
        100
    )

    Sleep 100

    PWWindows.SendKey(
        Mule2Hwnd,
        "y",
        100
    )
}

Esc::ExitApp

GetActivePWWindowTest()
{
    activeHwnd := WinExist("A")

    if !activeHwnd
        return 0

    rootHwnd := DllCall(
        "GetAncestor",
        "Ptr",
        activeHwnd,
        "UInt",
        2,
        "Ptr"
    )

    if !rootHwnd
        rootHwnd := activeHwnd

    try className := WinGetClass("ahk_id " rootHwnd)
    catch
        return 0

    try processName := WinGetProcessName("ahk_id " rootHwnd)
    catch
        return 0

    if className != "ElementClient Window"
        return 0

    if processName != "ElementClient_64.exe"
        return 0

    return rootHwnd
}