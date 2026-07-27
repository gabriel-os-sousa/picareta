#Requires AutoHotkey v2.0
#SingleInstance Force

CoordMode "Mouse", "Client"

global FriendX := 0
global FriendY := 0
global InviteOffsetX := 0
global InviteOffsetY := 0
global CalibrationHwnd := 0

; F2: salva a posição do primeiro amigo
F2::
{
    global FriendX, FriendY, CalibrationHwnd

    hwnd := WinExist("A")

    if WinGetClass("ahk_id " hwnd) != "ElementClient Window"
    {
        MsgBox "Deixe a janela principal do Perfect World ativa."
        return
    }

    MouseGetPos &x, &y

    FriendX := x
    FriendY := y
    CalibrationHwnd := hwnd

    ToolTip "Posição do amigo salva:`nX: " x " | Y: " y
    SetTimer () => ToolTip(), -1800
}

; F3: salva a posição da opção "Convidar para grupo"
F3::
{
    global FriendX, FriendY
    global InviteOffsetX, InviteOffsetY

    if FriendX = 0 && FriendY = 0
    {
        MsgBox "Primeiro salve a posição do amigo usando F2."
        return
    }

    MouseGetPos &menuX, &menuY

    InviteOffsetX := menuX - FriendX
    InviteOffsetY := menuY - FriendY

    ToolTip(
        "Posição do convite salva.`n"
        . "Deslocamento X: " InviteOffsetX "`n"
        . "Deslocamento Y: " InviteOffsetY
    )

    SetTimer () => ToolTip(), -2000
}

; F4: testa o convite no primeiro amigo
F4::
{
    global FriendX, FriendY
    global InviteOffsetX, InviteOffsetY
    global CalibrationHwnd

    if !CalibrationHwnd
    {
        MsgBox "A calibração ainda não foi feita."
        return
    }

    if !WinExist("ahk_id " CalibrationHwnd)
    {
        MsgBox "A janela usada na calibração não está mais aberta."
        return
    }

    WinActivate "ahk_id " CalibrationHwnd
    WinWaitActive "ahk_id " CalibrationHwnd, , 2

    MouseMove FriendX, FriendY, 0
    Sleep 100

    Click "Right"
    Sleep 350

    MouseMove(
        FriendX + InviteOffsetX,
        FriendY + InviteOffsetY,
        0
    )

    Sleep 100
    Click "Left"
}