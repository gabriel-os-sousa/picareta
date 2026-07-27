#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Mouse", "Client"

global MuleHwnd := 0

global NotificationX := 0
global NotificationY := 0

global AcceptX := 0
global AcceptY := 0

; F2:
; Cadastra a janela da mula e salva a posição da notificação.
F2::
{
    global MuleHwnd
    global NotificationX, NotificationY

    hwnd := GetMainPWWindow()

    if !hwnd
    {
        MsgBox "Não foi possível identificar a janela do Perfect World."
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

; F3:
; Salva a posição do botão Aceitar.
F3::
{
    global MuleHwnd
    global AcceptX, AcceptY

    if !MuleHwnd
    {
        MsgBox "Primeiro cadastre a mula usando F2."
        return
    }

    MouseGetPos &x, &y

    AcceptX := x
    AcceptY := y

    ToolTip(
        "Botão Aceitar salvo.`n"
        . "X " x " | Y " y
    )

    SetTimer(() => ToolTip(), -2000)
}

; F4:
; Teste usando ControlClick.
; A janela da mula não será ativada.
F4::
{
    global MuleHwnd
    global NotificationX, NotificationY
    global AcceptX, AcceptY

    if !ValidateConfiguration()
        return

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

        Sleep 600

        ControlClick(
            "x" AcceptX " y" AcceptY,
            target,
            ,
            "Left",
            1,
            "NA Pos"
        )

        ToolTip "ControlClick enviado sem ativar a mula."
        SetTimer(() => ToolTip(), -1800)
    }
    catch Error as err
    {
        MsgBox(
            "Erro no ControlClick:`n`n"
            . err.Message
        )
    }
}

; F5:
; Segundo método: mensagens diretas do Windows.
; Use somente se o teste com F4 não funcionar.
F5::
{
    global MuleHwnd
    global NotificationX, NotificationY
    global AcceptX, AcceptY

    if !ValidateConfiguration()
        return

    try
    {
        BackgroundClick(
            MuleHwnd,
            NotificationX,
            NotificationY
        )

        Sleep 600

        BackgroundClick(
            MuleHwnd,
            AcceptX,
            AcceptY
        )

        ToolTip "Mensagens de clique enviadas sem ativar a mula."
        SetTimer(() => ToolTip(), -1800)
    }
    catch Error as err
    {
        MsgBox(
            "Erro ao enviar mensagens:`n`n"
            . err.Message
        )
    }
}

; Mostra informações para verificar se a janela continua cadastrada.
F6::
{
    global MuleHwnd

    if !MuleHwnd
    {
        MsgBox "Nenhuma mula cadastrada."
        return
    }

    if !WinExist("ahk_id " MuleHwnd)
    {
        MsgBox "A janela cadastrada não existe mais."
        return
    }

    title := WinGetTitle("ahk_id " MuleHwnd)

    MsgBox(
        "Janela cadastrada:`n`n"
        . title "`n"
        . "HWND: " MuleHwnd
    )
}

Esc::ExitApp

ValidateConfiguration()
{
    global MuleHwnd
    global NotificationX, NotificationY
    global AcceptX, AcceptY

    if !MuleHwnd
    {
        MsgBox "A mula ainda não foi cadastrada."
        return false
    }

    if !WinExist("ahk_id " MuleHwnd)
    {
        MsgBox "A janela da mula foi fechada."
        return false
    }

    if NotificationX = 0 && NotificationY = 0
    {
        MsgBox "A posição da notificação não foi salva."
        return false
    }

    if AcceptX = 0 && AcceptY = 0
    {
        MsgBox "A posição do botão Aceitar não foi salva."
        return false
    }

    return true
}

BackgroundClick(hwnd, x, y)
{
    ; Converte X e Y no formato usado pelas mensagens do Windows.
    lParam := (y << 16) | (x & 0xFFFF)

    ; WM_MOUSEMOVE
    PostMessage(
        0x0200,
        0,
        lParam,
        ,
        "ahk_id " hwnd
    )

    Sleep 50

    ; WM_LBUTTONDOWN
    PostMessage(
        0x0201,
        1,
        lParam,
        ,
        "ahk_id " hwnd
    )

    Sleep 50

    ; WM_LBUTTONUP
    PostMessage(
        0x0202,
        0,
        lParam,
        ,
        "ahk_id " hwnd
    )
}

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