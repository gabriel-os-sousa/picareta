#Requires AutoHotkey v2.0
#SingleInstance Force

#Include ..\Modules\Party.ahk

CoordMode "Mouse", "Client"

global MuleHwnd := 0
global NotificationX := 0
global NotificationY := 0

; F2:
; Com a janela da mula ativa, posicione o mouse sobre
; a notificação do convite e pressione F2.
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
        . "HWND: " hwnd "`n"
        . "Notificação: X " x " | Y " y
    )

    SetTimer(() => ToolTip(), -2500)
}

; F4:
; Testa o módulo Party.
F4::
{
    global MuleHwnd
    global NotificationX, NotificationY

    if !MuleHwnd
    {
        MsgBox "Cadastre a mula primeiro usando F2."
        return
    }

    try
    {
        Party.AcceptInvite(
            MuleHwnd,
            NotificationX,
            NotificationY
        )

        ToolTip "Convite aceito pelo módulo Party."
        SetTimer(() => ToolTip(), -1800)
    }
    catch Error as err
    {
        MsgBox(
            "Erro ao aceitar o convite:`n`n"
            . err.Message
        )
    }
}

; F6:
; Teste simples de envio de tecla em segundo plano.
; Envia a tecla B para a janela cadastrada.
F6::
{
    global MuleHwnd

    if !MuleHwnd
    {
        MsgBox "Cadastre a mula primeiro usando F2."
        return
    }

    try
    {
        PWWindows.SendKey(MuleHwnd, "b")

        ToolTip "Tecla B enviada para a mula."
        SetTimer(() => ToolTip(), -1500)
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