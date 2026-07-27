#Requires AutoHotkey v2.0
#SingleInstance Force

#Include ..\Modules\Party.ahk

CoordMode "Mouse", "Client"

global LeaderHwnd := 0
global MuleHwnd := 0

global FriendX := 0
global FriendY := 0

global InviteX := 0
global InviteY := 0

global NotificationX := 0
global NotificationY := 0

; =========================================================
; F2
; Cadastra o líder e salva a posição do amigo na lista.
;
; Deixe a janela do líder ativa.
; Coloque o mouse em cima do nome da mula na lista de amigos.
; Pressione F2.
; =========================================================

F2::
{
    global LeaderHwnd
    global FriendX, FriendY

    hwnd := GetMainPWWindow()

    if !hwnd
    {
        MsgBox "Não foi possível identificar a janela do líder."
        return
    }

    MouseGetPos &x, &y

    LeaderHwnd := hwnd
    FriendX := x
    FriendY := y

    ToolTip(
        "Líder cadastrado.`n"
        . "Amigo: X " x " | Y " y
    )

    SetTimer(() => ToolTip(), -2200)
}

; =========================================================
; F3
; Salva a posição da opção "Convidar para grupo".
;
; Clique com o botão direito no amigo manualmente.
; Coloque o mouse sobre a opção de convite.
; Pressione F3.
; =========================================================

F3::
{
    global LeaderHwnd
    global InviteX, InviteY

    if !LeaderHwnd
    {
        MsgBox "Primeiro cadastre o líder usando F2."
        return
    }

    MouseGetPos &x, &y

    InviteX := x
    InviteY := y

    ToolTip(
        "Opção de convite salva.`n"
        . "X " x " | Y " y
    )

    SetTimer(() => ToolTip(), -2200)
}

; =========================================================
; F4
; Cadastra a mula e salva a posição da notificação.
;
; Deixe a janela da mula ativa.
; Coloque o mouse sobre a notificação de convite.
; Pressione F4.
; =========================================================

F4::
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

    SetTimer(() => ToolTip(), -2200)
}

; =========================================================
; F6
; Executa o fluxo completo:
;
; 1. Líder clica com botão direito no amigo.
; 2. Líder clica em convidar.
; 3. Mula abre a notificação em segundo plano.
; 4. Mula aceita usando Y.
;
; Nenhuma janela deve ser ativada pelo script.
; =========================================================

F6::
{
    global LeaderHwnd, MuleHwnd
    global FriendX, FriendY
    global InviteX, InviteY
    global NotificationX, NotificationY

    if !ValidateConfiguration()
        return

    try
    {
        ; Abre o menu de contexto sobre o amigo.
        PWWindows.RightClick(
            LeaderHwnd,
            FriendX,
            FriendY,
            300
        )

        ; Seleciona a opção de convidar para o grupo.
        PWWindows.LeftClick(
            LeaderHwnd,
            InviteX,
            InviteY,
            700
        )

        ; Aguarda a notificação chegar na mula.
        Sleep 700

        ; Mula abre a notificação e aceita com Y.
        Party.AcceptInvite(
            MuleHwnd,
            NotificationX,
            NotificationY,
            500
        )

        ToolTip "Fluxo completo de PT executado."
        SetTimer(() => ToolTip(), -2200)
    }
    catch Error as err
    {
        MsgBox(
            "Erro ao montar a PT:`n`n"
            . err.Message
        )
    }
}

; Mostra os dados cadastrados.
F7::
{
    global LeaderHwnd, MuleHwnd
    global FriendX, FriendY
    global InviteX, InviteY
    global NotificationX, NotificationY

    text :=
    (
        "Líder HWND: " LeaderHwnd "
        Amigo: X " FriendX " | Y " FriendY "

        Mula HWND: " MuleHwnd "
        Notificação: X " NotificationX " | Y " NotificationY "

        Opção convidar:
        X " InviteX " | Y " InviteY
    )

    MsgBox text
}

Esc::ExitApp

ValidateConfiguration()
{
    global LeaderHwnd, MuleHwnd
    global FriendX, FriendY
    global InviteX, InviteY
    global NotificationX, NotificationY

    if !LeaderHwnd
    {
        MsgBox "O líder ainda não foi cadastrado. Use F2."
        return false
    }

    if !PWWindows.IsOpen(LeaderHwnd)
    {
        MsgBox "A janela cadastrada como líder foi fechada."
        return false
    }

    if !MuleHwnd
    {
        MsgBox "A mula ainda não foi cadastrada. Use F4."
        return false
    }

    if !PWWindows.IsOpen(MuleHwnd)
    {
        MsgBox "A janela cadastrada como mula foi fechada."
        return false
    }

    if LeaderHwnd = MuleHwnd
    {
        MsgBox "O líder e a mula estão cadastrados como a mesma janela."
        return false
    }

    if FriendX = 0 && FriendY = 0
    {
        MsgBox "A posição do amigo não foi salva."
        return false
    }

    if InviteX = 0 && InviteY = 0
    {
        MsgBox "A posição da opção de convite não foi salva."
        return false
    }

    if NotificationX = 0 && NotificationY = 0
    {
        MsgBox "A posição da notificação não foi salva."
        return false
    }

    return true
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