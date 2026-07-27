#Requires AutoHotkey v2.0
#SingleInstance Force

; As coordenadas serão relativas à área interna
; da janela ativa, igual ao PW_Controller.
CoordMode "Mouse", "Client"

global FieldName := "Position"
global TooltipEnabled := true

SetTimer ShowMousePosition, 50

; =========================================================
; F2 — Copiar somente X e Y
;
; Exemplo copiado:
; X=450
; Y=320
; =========================================================

F2::
{
    MouseGetPos &mouseX, &mouseY

    text := "X=" mouseX "`nY=" mouseY

    A_Clipboard := text

    ToolTip(
        "COORDENADAS COPIADAS"
        . "`nX: " mouseX
        . "`nY: " mouseY
        . "`n`nCole com Ctrl + V."
    )

    SetTimer RestorePositionTooltip, -1800
}

; =========================================================
; F3 — Escolher o nome do campo
;
; Exemplos:
; Notification
; Friend
; Invite
; =========================================================

F3::
{
    global FieldName

    result := InputBox(
        "Digite o nome do campo que será copiado.`n`n"
        . "Exemplos:`n"
        . "Notification`n"
        . "Friend`n"
        . "Invite",
        "Nome da coordenada",
        "w360 h210",
        FieldName
    )

    if result.Result != "OK"
        return

    newName := Trim(result.Value)

    if newName = ""
    {
        MsgBox(
            "Digite um nome válido.",
            "Capturar coordenadas"
        )
        return
    }

    FieldName := newName

    ToolTip(
        "Campo selecionado: " FieldName
        . "`n`nPressione F4 para copiar."
    )

    SetTimer RestorePositionTooltip, -1800
}

; =========================================================
; F4 — Copiar no formato do Characters.ini
;
; Exemplo:
; FriendX=450
; FriendY=320
; =========================================================

F4::
{
    global FieldName

    MouseGetPos &mouseX, &mouseY

    text := FieldName "X=" mouseX
    text .= "`n"
    text .= FieldName "Y=" mouseY

    A_Clipboard := text

    ToolTip(
        "COPIADO PARA O INI"
        . "`n`n" text
        . "`n`nCole com Ctrl + V."
    )

    SetTimer RestorePositionTooltip, -2200
}

; =========================================================
; F5 — Copiar apenas os números
;
; Exemplo:
; 450, 320
; =========================================================

F5::
{
    MouseGetPos &mouseX, &mouseY

    text := mouseX ", " mouseY

    A_Clipboard := text

    ToolTip(
        "COPIADO"
        . "`n" text
    )

    SetTimer RestorePositionTooltip, -1600
}

; =========================================================
; F6 — Ativar ou desativar coordenadas em tempo real
; =========================================================

F6::
{
    global TooltipEnabled

    TooltipEnabled := !TooltipEnabled

    if TooltipEnabled
    {
        ToolTip "Visualização ativada."
        SetTimer RestorePositionTooltip, -1000
    }
    else
    {
        ToolTip()
    }
}

; =========================================================
; Ctrl + Alt + F12 — Fechar utilitário
; =========================================================

^!F12::ExitApp

; =========================================================
; Mostrar posição atual do mouse
; =========================================================

ShowMousePosition()
{
    global FieldName
    global TooltipEnabled

    if !TooltipEnabled
        return

    MouseGetPos &mouseX, &mouseY, &windowHwnd

    windowTitle := ""

    if windowHwnd
    {
        try windowTitle := WinGetTitle("ahk_id " windowHwnd)
    }

    ToolTip(
        "CAPTURAR COORDENADAS"
        . "`nCampo: " FieldName
        . "`nX: " mouseX
        . " | Y: " mouseY
        . "`n`nF2 = copiar X/Y"
        . "`nF3 = mudar campo"
        . "`nF4 = copiar para INI"
        . "`nF5 = copiar números"
        . "`nF6 = ocultar"
        . "`nCtrl + Alt + F12 = fechar"
    )
}

RestorePositionTooltip()
{
    global TooltipEnabled

    if TooltipEnabled
        ShowMousePosition()
    else
        ToolTip()
}