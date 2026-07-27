#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Mouse", "Client"

global MuleHwnd := 0

global NotificationX := 0
global NotificationY := 0

global AcceptX := 0
global AcceptY := 0

; F2: cadastra a janela da mula e salva a posição da notificação.
F2::
{
    global MuleHwnd
    global NotificationX, NotificationY

    hwnd := GetMainPWWindow()

    if !hwnd
    {
        MsgBox "Não foi possível identificar a janela principal do Perfect World."
        return
    }

    MouseGetPos &x, &y

    MuleHwnd := hwnd
    NotificationX := x
    NotificationY := y

    ToolTip(
        "Mula cadastrada.`n"
        . "Posição da notificação:`n"
        . "X: " x " | Y: " y
    )

    SetTimer(() => ToolTip(), -2000)
}

; F3: salva a posição do botão Aceitar.
F3::
{
    global MuleHwnd
    global AcceptX, AcceptY

    if !MuleHwnd
    {
        MsgBox "Primeiro use F2 sobre a notificação."
        return
    }

    MouseGetPos &x, &y

    AcceptX := x
    AcceptY := y

    ToolTip(
        "Botão Aceitar salvo.`n"
        . "X: " x " | Y: " y
    )

    SetTimer(() => ToolTip(), -2000)
}

; F4: testa o aceite automático do convite de PT.
F4::
{
    global MuleHwnd
    global NotificationX, NotificationY
    global AcceptX, AcceptY

    if !MuleHwnd
    {
        MsgBox "A janela da mula ainda não foi cadastrada."
        return
    }

    if NotificationX = 0 && NotificationY = 0
    {
        MsgBox "A posição da notificação ainda não foi salva."
        return
    }

    if AcceptX = 0 && AcceptY = 0
    {
        MsgBox "A posição do botão Aceitar ainda não foi salva."
        return
    }

    if !WinExist("ahk_id " MuleHwnd)
    {
        MsgBox "A janela cadastrada não está mais aberta."
        return
    }

    ; Coloca a mula na frente.
    if WinGetMinMax("ahk_id " MuleHwnd) = -1
        WinRestore "ahk_id " MuleHwnd

    WinActivate "ahk_id " MuleHwnd

    if !WinWaitActive("ahk_id " MuleHwnd, , 2)
    {
        MsgBox "Não foi possível ativar a janela da mula."
        return
    }

    Sleep 250

    ; Clica na notificação do convite.
    MouseMove NotificationX, NotificationY, 0
    Sleep 150
    Click "Left"

    ; Aguarda a janela com o botão Aceitar abrir.
    Sleep 500

    ; Clica no botão Aceitar.
    MouseMove AcceptX, AcceptY, 0
    Sleep 150
    Click "Left"

    ToolTip "Comando de aceite executado."
    SetTimer(() => ToolTip(), -1500)
}

; ESC encerra somente este script de teste.
Esc::ExitApp

GetMainPWWindow()
{
    activeHwnd := WinExist("A")

    if !activeHwnd
        return 0

    try processName := WinGetProcessName("ahk_id " activeHwnd)
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

    try windowClass := WinGetClass("ahk_id " rootHwnd)
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