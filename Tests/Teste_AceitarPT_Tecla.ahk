#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Mouse", "Client"

global MuleHwnd := 0
global NotificationX := 0
global NotificationY := 0

; F2:
; Com a janela da mula ativa, coloque o mouse sobre a notificação
; e pressione F2 para cadastrar a janela e a coordenada.
F2::
{
    global MuleHwnd
    global NotificationX, NotificationY

    hwnd := GetMainPWWindow()

    if !hwnd
    {
        MsgBox "Não foi possível identificar a janela da mula."
        return
    }

    MouseGetPos &x, &y

    MuleHwnd := hwnd
    NotificationX := x
    NotificationY := y

    ToolTip(
        "Mula cadastrada.`n"
        . "Notificação: X " x " | Y " y
    )

    SetTimer(() => ToolTip(), -2000)
}

; F4:
; Clica na notificação e envia Y em segundo plano.
F4::
{
    global MuleHwnd
    global NotificationX, NotificationY

    if !MuleHwnd
    {
        MsgBox "Cadastre a mula primeiro usando F2."
        return
    }

    if !WinExist("ahk_id " MuleHwnd)
    {
        MsgBox "A janela cadastrada foi fechada."
        return
    }

    target := "ahk_id " MuleHwnd

    try
    {
        ControlClick(
            "x" NotificationX " y" NotificationY,
            target,
            ,
            "Left",
            1,
            "NA Pos"
        )

        Sleep 500

        ControlSend "y", , target

        ToolTip "Clique e tecla Y enviados em segundo plano."
        SetTimer(() => ToolTip(), -1800)
    }
    catch Error as err
    {
        MsgBox "Erro:`n`n" err.Message
    }
}

Esc::ExitApp

GetMainPWWindow()
{
    activeHwnd := WinExist("A")

    if !activeHwnd
        return 0

    try processName := WinGetProcessName(
        "ahk_id " activeHwnd
    )
    catch
        return 0

    if processName != "ElementClient_64.exe"
        return 0

    rootHwnd := DllCall(
        "GetAncestor",
        "Ptr", activeHwnd,
        "UInt", 2,
        "Ptr"
    )

    if !rootHwnd
        rootHwnd := activeHwnd

    try windowClass := WinGetClass(
        "ahk_id " rootHwnd
    )
    catch
        return 0

    if windowClass = "ElementClient Window"
        return rootHwnd

    pid := WinGetPID("ahk_id " rootHwnd)

    gameWindows := WinGetList(
        "ahk_class ElementClient Window ahk_pid " pid
    )

    if gameWindows.Length = 0
        return 0

    return gameWindows[1]
}