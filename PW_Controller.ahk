#Requires AutoHotkey v2.0
#SingleInstance Force

#Include "Modules\Configuration.ahk"
#Include "Modules\Party.ahk"
#Include "Modules\PartyManagement.ahk"
#Include "Modules\MouseMirror.ahk"

CoordMode "Mouse", "Client"

; =========================================================
; CONFIGURAÇÃO GLOBAL
; =========================================================

global ConfigPath := A_ScriptDir "\Config\Characters.ini"

global LeaderHwnd := 0
global Mules := []

global NotificationX := 0
global NotificationY := 0
global InviteDelay := 150
global BeforeAcceptDelay := 300
global AcceptDelay := 150

; Atalhos carregados da seção [Hotkeys].
global ControllerHotkeys := false

; =========================================================
; INICIALIZAÇÃO
; =========================================================

settings := Configuration.Load(ConfigPath)

if !settings
    ExitApp

NotificationX := settings.NotificationX
NotificationY := settings.NotificationY
InviteDelay := settings.InviteDelay
BeforeAcceptDelay := settings.BeforeAcceptDelay
AcceptDelay := settings.AcceptDelay

ControllerHotkeys := Configuration.LoadHotkeys(ConfigPath)

if !ControllerHotkeys
    ExitApp

try
{
    RegisterControllerHotkeys()
}
catch Error as err
{
    MsgBox(
        "Não foi possível registrar os atalhos."
        . "`n`nMensagem: " err.Message
        . "`n`nVerifique a seção [Hotkeys] "
        . "do Characters.ini."
        . "`n`nO controller será fechado.",
        "Erro nos atalhos"
    )

    ExitApp
}

ShowStartupMessage()

/**
 * Registra todos os atalhos do controller.
 *
 * Os comandos reais ficam em funções separadas. Dessa forma,
 * nenhuma funcionalidade precisa conhecer a tecla física que
 * foi escolhida pelo usuário.
 */
RegisterControllerHotkeys()
{
    global ControllerHotkeys

    Hotkey(
        ControllerHotkeys.RegisterLeader,
        RegisterLeader
    )

    Hotkey(
        ControllerHotkeys.RegisterMule,
        RegisterMule
    )

    Hotkey(
        ControllerHotkeys.NextWindow,
        ActivateNextPWWindow
    )

    Hotkey(
        ControllerHotkeys.ShowStatus,
        ShowControllerStatus
    )

    Hotkey(
        ControllerHotkeys.BuildParty,
        BuildParty
    )

    Hotkey(
        ControllerHotkeys.RebuildParty,
        RebuildParty
    )

    Hotkey(
        ControllerHotkeys.ToggleMirror,
        ToggleMouseMirror
    )

    Hotkey(
        ControllerHotkeys.ClearRegistrations,
        ClearRegistrations
    )

    Hotkey(
        ControllerHotkeys.ExitController,
        ExitController
    )
}

; =========================================================
; F2 — CADASTRAR LÍDER
;
; Deixe a janela do personagem líder ativa
; e pressione F2.
; =========================================================

RegisterLeader(*)
{
    global LeaderHwnd
    global Mules

    hwnd := GetActivePWWindow()

    if !hwnd
    {
        MsgBox(
            "A janela ativa não é um cliente válido "
            . "do Perfect World.`n`n"
            . "Cadastre primeiro a janela do personagem principal.",
            "PW Controller"
        )
        return
    }

    ; Impede que uma janela cadastrada como mula
    ; também seja cadastrada como líder.
    for registeredMule in Mules
    {
        if registeredMule.Hwnd = hwnd
        {
            MsgBox(
                "Essa janela já está cadastrada como "
                . registeredMule.Name
                . ".`n`n"
                . "Use Ctrl + F3 para limpar os cadastros "
                . "e começar novamente.",
                "PW Controller"
            )
            return
        }
    }

    ; Se o mesmo líder for cadastrado novamente,
    ; apenas informa que ele já está cadastrado.
    if LeaderHwnd = hwnd
    {
        ToolTip(
            "Esse líder já está cadastrado."
            . "`nHWND: " hwnd
        )

        SetTimer(() => ToolTip(), -2200)
        return
    }

    LeaderHwnd := hwnd

    ToolTip(
        "LÍDER CADASTRADO"
        . "`nHWND: " LeaderHwnd
        . "`n`nAgora ative a primeira mula"
        . "`ne pressione F3."
    )

    SetTimer(() => ToolTip(), -3000)
}

; =========================================================
; F3 — CADASTRAR PRÓXIMA MULA
;
; As mulas devem ser cadastradas na mesma ordem
; em que aparecem na lista de amigos do líder.
; =========================================================

RegisterMule(*)
{
    global LeaderHwnd
    global Mules
    global ConfigPath

    if !LeaderHwnd
    {
        MsgBox(
            "O líder ainda não foi cadastrado.`n`n"
            . "Cadastre primeiro a janela do personagem principal.",
            "PW Controller"
        )
        return
    }

    hwnd := GetActivePWWindow()

    if !hwnd
    {
        MsgBox(
            "Nenhuma janela válida do Perfect World "
            . "foi encontrada.`n`n"
            . "Ative a janela da mula e pressione F3.",
            "PW Controller"
        )
        return
    }

    if hwnd = LeaderHwnd
    {
        MsgBox(
            "Essa janela está cadastrada como líder.`n`n"
            . "Ative a janela da mula e pressione F3 novamente.",
            "PW Controller"
        )
        return
    }

    ; Impede que a mesma janela seja cadastrada duas vezes.
    for registeredMule in Mules
    {
        if registeredMule.Hwnd = hwnd
        {
            MsgBox(
                "Essa janela já está cadastrada como "
                . registeredMule.Name
                . ".`n`n"
                . "HWND: " hwnd,
                "PW Controller"
            )
            return
        }
    }

    slot := Mules.Length + 1

    ; Líder + 9 mulas = grupo máximo configurado.
    if slot > 9
    {
        MsgBox(
            "As 9 mulas já foram cadastradas.",
            "PW Controller"
        )
        return
    }

    name := Configuration.GetMuleName(
        ConfigPath,
        slot
    )

    Mules.Push({
        Slot: slot,
        Name: name,
        Hwnd: hwnd
    })

    ToolTip(
        "MULA " slot " CADASTRADA"
        . "`nNome: " name
        . "`nHWND: " hwnd
        . "`n`nPróxima mula: ative a janela"
        . "`ne pressione F3 novamente."
    )

    SetTimer(() => ToolTip(), -3500)
}

; =========================================================
; SC029 — Alterar para proxima janela
; =========================================================
ActivateNextPWWindow(*)
{
    global LeaderHwnd
    global Mules

    registeredWindows := []

    ; Adiciona primeiro a janela principal.
    if LeaderHwnd && PWWindows.IsOpen(LeaderHwnd)
        registeredWindows.Push(LeaderHwnd)

    ; Adiciona as mulas na ordem em que foram cadastradas.
    for mule in Mules
    {
        if !mule.HasOwnProp("Hwnd")
            continue

        hwnd := mule.Hwnd

        if !hwnd
            continue

        if !PWWindows.IsOpen(hwnd)
            continue

        ; Impede HWND duplicado na lista.
        alreadyAdded := false

        for registeredHwnd in registeredWindows
        {
            if registeredHwnd = hwnd
            {
                alreadyAdded := true
                break
            }
        }

        if !alreadyAdded
            registeredWindows.Push(hwnd)
    }

    if registeredWindows.Length = 0
    {
        ToolTip "Nenhuma janela cadastrada está aberta."
        SetTimer () => ToolTip(), -1200
        return
    }

    activeHwnd := WinExist("A")
    currentIndex := 0

    ; Descobre se a janela ativa é uma das cadastradas.
    for index, hwnd in registeredWindows
    {
        if activeHwnd = hwnd
        {
            currentIndex := index
            break
        }
    }

    ; Se a janela ativa não for cadastrada, começa pelo principal.
    if currentIndex = 0
        nextIndex := 1
    else if currentIndex >= registeredWindows.Length
        nextIndex := 1
    else
        nextIndex := currentIndex + 1

    nextHwnd := registeredWindows[nextIndex]

    try
    {
        if WinGetMinMax("ahk_id " nextHwnd) = -1
            WinRestore "ahk_id " nextHwnd

        WinActivate "ahk_id " nextHwnd
    }
    catch
    {
        ToolTip "Não foi possível ativar a próxima janela."
        SetTimer () => ToolTip(), -1200
    }
}

; =========================================================
; F7 — MOSTRAR SITUAÇÃO DO CADASTRO
; =========================================================
ShowControllerStatus(*)
{
    global LeaderHwnd
    global Mules
    global ConfigPath
    global NotificationX
    global NotificationY

    status := "STATUS DO PW CONTROLLER"
    status .= "`n============================"

    ; Situação do líder.
    if !LeaderHwnd
    {
        status .= "`nLíder: NÃO cadastrado"
    }
    else if PWWindows.IsOpen(LeaderHwnd)
    {
        status .= "`nLíder: cadastrado e aberto"
        status .= "`nHWND: " LeaderHwnd
    }
    else
    {
        status .= "`nLíder: janela fechada"
        status .= "`nHWND antigo: " LeaderHwnd
    }

    status .= "`n"
    status .= "`nMulas cadastradas: " Mules.Length

    ; Situação das mulas.
    for index, mule in Mules
    {
        coordinates := Configuration.GetMuleCoordinates(
            ConfigPath,
            index
        )

        friendX := coordinates.FriendX
        friendY := coordinates.FriendY
        inviteX := coordinates.InviteX
        inviteY := coordinates.InviteY

        if PWWindows.IsOpen(mule.Hwnd)
            windowStatus := "aberta"
        else
            windowStatus := "FECHADA"

        status .= "`n"
        status .= "`nMula " index ": " mule.Name
        status .= "`n  Janela: " windowStatus
        status .= "`n  HWND: " mule.Hwnd
        status .= "`n  Amigo: " friendX ", " friendY
        status .= "`n  Convite: " inviteX ", " inviteY
    }

    status .= "`n"
    status .= "`nNotificação: "
    status .= NotificationX ", " NotificationY

    if NotificationX = 0 || NotificationY = 0
        status .= " — NÃO CONFIGURADA"
    else
        status .= " — configurada"

    status .= "`n" ControllerHotkeys.RegisterLeader
    status .= " = cadastrar principal"

    status .= "`n" ControllerHotkeys.RegisterMule
    status .= " = cadastrar próxima mula"

    status .= "`n" ControllerHotkeys.NextWindow
    status .= " = alternar janela"

    status .= "`n" ControllerHotkeys.ShowStatus
    status .= " = mostrar situação"

    status .= "`n" ControllerHotkeys.BuildParty
    status .= " = montar PT"

    status .= "`n" ControllerHotkeys.RebuildParty
    status .= " = desmontar/remontar PT"

    status .= "`n" ControllerHotkeys.ToggleMirror
    status .= " = ativar/desativar espelhamento"

    status .= "`nEspelhamento: "
    status .= MouseMirror.IsEnabled()
        ? "ATIVADO"
        : "desativado"

    status .= "`n" ControllerHotkeys.ClearRegistrations
    status .= " = limpar cadastros"

    status .= "`n" ControllerHotkeys.ExitController
    status .= " = fechar controller"

    MsgBox status, "PW Controller"
}

; =========================================================
; MONTAR PT
;
; Primeiro valida todas as janelas e coordenadas.
; Somente depois inicia os convites.
; =========================================================

BuildParty(*)
{
    global ConfigPath
    global LeaderHwnd
    global Mules
    global NotificationX
    global NotificationY
    global InviteDelay
    global BeforeAcceptDelay
    global AcceptDelay

    partyData := Configuration.ValidateParty(
        ConfigPath,
        LeaderHwnd,
        Mules,
        NotificationX,
        NotificationY
    )

    if !partyData
        return

    notificationX := partyData.NotificationX
    notificationY := partyData.NotificationY
    preparedMules := partyData.Mules

    ; =====================================================
    ; ETAPA 1 — ENVIAR TODOS OS CONVITES
    ; =====================================================

    ToolTip(
        "ETAPA 1 DE 2"
        . "`nEnviando convites..."
        . "`nIntervalo: " InviteDelay " ms"
    )

    for index, muleData in preparedMules
    {
        if !PWWindows.IsOpen(LeaderHwnd)
        {
            ToolTip()

            MsgBox(
                "A janela do líder foi fechada "
                . "durante o envio dos convites.",
                "PW Controller"
            )
            return
        }

        if !PWWindows.IsOpen(muleData.Hwnd)
        {
            ToolTip()

            MsgBox(
                "A janela de " muleData.Name
                . " foi fechada antes do convite.",
                "PW Controller"
            )
            return
        }

        ToolTip(
            "ENVIANDO CONVITES"
            . "`n" muleData.Name
            . "`n" index " de " preparedMules.Length
            . "`nIntervalo: " InviteDelay " ms"
        )

        try
        {
            Party.InviteMember(
                LeaderHwnd,
                muleData.FriendX,
                muleData.FriendY,
                muleData.InviteX,
                muleData.InviteY
            )
        }
        catch Error as err
        {
            ToolTip()

            MsgBox(
                "Erro ao convidar "
                . muleData.Name
                . ".`n`n"
                . "Mensagem: " err.Message,
                "Erro no PW Controller"
            )
            return
        }

        if InviteDelay > 0
            Sleep InviteDelay
    }

    ; Pausa configurável antes dos aceites.
    if BeforeAcceptDelay > 0
    {
        ToolTip(
            "CONVITES ENVIADOS"
            . "`nAguardando " BeforeAcceptDelay
            . " ms antes dos aceites..."
        )

        Sleep BeforeAcceptDelay
    }

    ; =====================================================
    ; ETAPA 2 — ACEITAR EM TODAS AS MULAS
    ; =====================================================

    ToolTip(
        "ETAPA 2 DE 2"
        . "`nAceitando convites..."
        . "`nIntervalo: " AcceptDelay " ms"
    )

    for index, muleData in preparedMules
    {
        if !PWWindows.IsOpen(muleData.Hwnd)
        {
            ToolTip()

            MsgBox(
                "A janela de " muleData.Name
                . " foi fechada antes do aceite.",
                "PW Controller"
            )
            return
        }

        ToolTip(
            "ACEITANDO CONVITES"
            . "`n" muleData.Name
            . "`n" index " de " preparedMules.Length
            . "`nIntervalo: " AcceptDelay " ms"
        )

        try
        {
            Party.AcceptInvite(
                muleData.Hwnd,
                notificationX,
                notificationY
            )
        }
        catch Error as err
        {
            ToolTip()

            MsgBox(
                "Erro ao aceitar o convite em "
                . muleData.Name
                . ".`n`n"
                . "Mensagem: " err.Message,
                "Erro no PW Controller"
            )
            return
        }

        if AcceptDelay > 0
            Sleep AcceptDelay
    }

    ToolTip(
        "PT MONTADA COM SUCESSO"
        . "`n" preparedMules.Length
        . " mula(s) processada(s)."
        . "`n`nConvites: " InviteDelay " ms"
        . "`nAntes dos aceites: " BeforeAcceptDelay " ms"
        . "`nAceites: " AcceptDelay " ms"
    )

    SetTimer(() => ToolTip(), -4000)
}

; =========================================================
; XButton2 — REMONTAR PT
; =========================================================

RebuildParty(*)
{
    global ConfigPath
    global LeaderHwnd
    global Mules
    global ControllerHotkeys

    if !LeaderHwnd
    {
        MsgBox(
            "O personagem principal não foi registrado.`n`n"
            . "Ative a janela do personagem principal "
            . "e pressione F2.",
            "PW Controller"
        )

        return
    }

    if !PWWindows.IsOpen(LeaderHwnd)
    {
        MsgBox(
            "A janela do personagem principal "
            . "não está mais aberta.",
            "PW Controller"
        )

        return
    }

    rebuildData := Configuration.LoadRebuild(
        ConfigPath,
        Mules
    )

    if !rebuildData
        return

    members := rebuildData.Members
    memberCount := members.Length

    if memberCount < 1
    {
        MsgBox(
            "Nenhuma mula foi encontrada para remontar a PT.",
            "PW Controller"
        )

        return
    }

    ; Evita apertar XButton2 novamente durante o processo.
    Hotkey ControllerHotkeys.RebuildParty, "Off"

    try
    {
        ; =================================================
        ; ETAPA 1 — EXPULSAR DE BAIXO PARA CIMA
        ;
        ; Mule1 nunca é expulsa.
        ;
        ; Exemplo com 5 mulas:
        ; Mule5
        ; Mule4
        ; Mule3
        ; Mule2
        ;
        ; Depois restam:
        ; Principal + Mule1
        ; =================================================

        if memberCount > 1
        {
            currentIndex := memberCount
            totalKicks := memberCount - 1
            kickNumber := 1

            while currentIndex >= 2
            {
                memberData := members[currentIndex]

                if !PWWindows.IsOpen(LeaderHwnd)
                {
                    throw Error(
                        "A janela do personagem principal foi fechada."
                    )
                }

                ToolTip(
                    "REMONTANDO PT"
                    . "`nExpulsando: " memberData.Name
                    . "`n" kickNumber " de " totalKicks
                    . "`nPosição: Mule" currentIndex
                )

                PartyManagement.KickMember(
                    LeaderHwnd,
                    memberData.PartyX,
                    memberData.PartyY,
                    rebuildData.KickX,
                    rebuildData.KickY,
                    rebuildData.SelectDelay,
                    rebuildData.KickDelay
                )

                currentIndex -= 1
                kickNumber += 1
            }
        }

        ; =================================================
        ; ETAPA 2 — TRANSFERIR LIDERANÇA PARA MULE1
        ; =================================================

        newLeader := members[1]

        if !PWWindows.IsOpen(LeaderHwnd)
        {
            throw Error(
                "A janela do personagem principal foi fechada "
                . "antes da transferência de liderança."
            )
        }

        ToolTip(
            "REMONTANDO PT"
            . "`nTransferindo liderança para:"
            . "`n" newLeader.Name
        )

        PartyManagement.TransferLeader(
            LeaderHwnd,
            newLeader.PartyX,
            newLeader.PartyY,
            rebuildData.TransferLeaderX,
            rebuildData.TransferLeaderY,
            rebuildData.SelectDelay,
            rebuildData.TransferDelay
        )

        ; =================================================
        ; ETAPA 3 — AGUARDAR ANTES DE SAIR
        ; =================================================

        if rebuildData.BeforeLeaveDelay > 0
        {
            ToolTip(
                "LIDERANÇA TRANSFERIDA"
                . "`nNova líder: " newLeader.Name
                . "`nAguardando "
                . rebuildData.BeforeLeaveDelay
                . " ms para sair..."
            )

            Sleep rebuildData.BeforeLeaveDelay
        }

        ; =================================================
        ; ETAPA 4 — PERSONAGEM PRINCIPAL SAI DA PT
        ; =================================================

        if !PWWindows.IsOpen(LeaderHwnd)
        {
            throw Error(
                "A janela do personagem principal foi fechada "
                . "antes de sair da PT."
            )
        }

        ToolTip(
            "REMONTANDO PT"
            . "`nPersonagem principal saindo da PT..."
        )

        PartyManagement.LeaveParty(
            LeaderHwnd,
            rebuildData.LeavePartyX,
            rebuildData.LeavePartyY,
            rebuildData.LeaveDelay
        )

        ToolTip(
            "PROCESSO CONCLUÍDO"
            . "`nNova líder: " newLeader.Name
            . "`nPersonagem principal saiu da PT."
        )

        SetTimer(() => ToolTip(), -4000)
    }
    catch Error as err
    {
        ToolTip()

        MsgBox(
            "Erro ao remontar a PT.`n`n"
            . "Mensagem: " err.Message,
            "Erro no PW Controller"
        )
    }
    finally
    {
        Hotkey ControllerHotkeys.RebuildParty, "On"
    }
}

; =========================================================
; MButton — ATIVAR/DESATIVAR ESPELHAMENTO DE CLIQUES
;
; Quando ativado, cliques físicos feitos no líder ou em uma
; mula cadastrada são repetidos nas demais janelas abertas.
; =========================================================

ToggleMouseMirror(*)
{
    enabled := MouseMirror.Toggle()

    if enabled
    {
        ToolTip(
            "ESPELHAMENTO ATIVADO"
            . "`nCliques esquerdo e direito"
            . "`nserão enviados às outras janelas."
        )
    }
    else
    {
        ToolTip(
            "ESPELHAMENTO DESATIVADO"
            . "`nOs cliques voltaram ao modo normal."
        )
    }

    SetTimer(() => ToolTip(), -2500)
}

; O prefixo ~ preserva o clique original na janela ativa.
; O prefixo * permite o funcionamento mesmo com modificadores pressionados.
~*LButton::MirrorCurrentClick()
;~*RButton::MirrorCurrentClick("Right")

; =========================================================
; CTRL + F3 — LIMPAR CADASTROS DA SESSÃO
;
; Não apaga ou modifica o Characters.ini.
; =========================================================

ClearRegistrations(*)
{
    global LeaderHwnd
    global Mules
    global ControllerHotkeys

    LeaderHwnd := 0
    Mules := []

    ToolTip(
        "CADASTROS APAGADOS"
        . "`n`nCadastre novamente:"
        . "`n" ControllerHotkeys.RegisterLeader
        . " = principal"
        . "`n" ControllerHotkeys.RegisterMule
        . " = mulas"
    )

    SetTimer(() => ToolTip(), -3000)
}

; =========================================================
; CTRL + ALT + F12 — FECHAR CONTROLLER
; =========================================================
ExitController(*)
{
    ExitApp
}

; =========================================================
; ESPELHAR CLIQUE DA JANELA ATIVA
; =========================================================

MirrorCurrentClick()
{
    global LeaderHwnd
    global Mules

    if !MouseMirror.IsEnabled()
        return

    ; Captura a posição real na tela e a janela diretamente sob o mouse.
    CoordMode "Mouse", "Screen"
    MouseGetPos &screenX, &screenY, &hoveredHwnd
    CoordMode "Mouse", "Client"
    SetControlDelay -1

    if !hoveredHwnd
        return

    ; Recupera a janela principal do cliente do PW.
    sourceHwnd := DllCall(
        "GetAncestor",
        "Ptr", hoveredHwnd,
        "UInt", 2,
        "Ptr"
    )

    if !sourceHwnd
        sourceHwnd := hoveredHwnd

    try
    {
        processName := WinGetProcessName(
            "ahk_id " sourceHwnd
        )

        windowClass := WinGetClass(
            "ahk_id " sourceHwnd
        )
    }
    catch
    {
        return
    }

    if processName != "ElementClient_64.exe"
        return

    if windowClass != "ElementClient Window"
        return

    ; Converte coordenadas da tela para a área cliente
    ; da janela onde o clique realmente aconteceu.
    point := Buffer(8, 0)

    NumPut("Int", screenX, point, 0)
    NumPut("Int", screenY, point, 4)

    if !DllCall(
        "ScreenToClient",
        "Ptr", sourceHwnd,
        "Ptr", point
    )
    {
        return
    }

    clientX := NumGet(point, 0, "Int")
    clientY := NumGet(point, 4, "Int")

    sentCount := MouseMirror.MirrorClick(
        sourceHwnd,
        LeaderHwnd,
        Mules,
        clientX,
        clientY
    )

    ; Pode deixar este trecho durante o teste.
    ; ToolTip "Clique enviado para " sentCount " janela(s)."
    ; SetTimer(() => ToolTip(), -500)
}

; =========================================================
; OBTER JANELA REAL DO PERFECT WORLD
; =========================================================

GetActivePWWindow()
{
    activeHwnd := WinExist("A")

    if !activeHwnd
        return 0

    try
    {
        processName := WinGetProcessName(
            "ahk_id " activeHwnd
        )
    }
    catch
    {
        return 0
    }

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

    try
    {
        windowClass := WinGetClass(
            "ahk_id " rootHwnd
        )
    }
    catch
    {
        return 0
    }

    if windowClass = "ElementClient Window"
        return rootHwnd

    try
    {
        pid := WinGetPID(
            "ahk_id " rootHwnd
        )
    }
    catch
    {
        return 0
    }

    gameWindows := WinGetList(
        "ahk_class ElementClient Window ahk_pid " pid
    )

    if gameWindows.Length = 0
        return 0

    return gameWindows[1]
}

; =========================================================
; MENSAGEM INICIAL
; =========================================================
ShowStartupMessage()
{
    global ControllerHotkeys

    ToolTip(
        "PW CONTROLLER INICIADO"
        . "`n`n" ControllerHotkeys.RegisterLeader
        . " = cadastrar principal"
        . "`n" ControllerHotkeys.RegisterMule
        . " = cadastrar mulas"
        . "`n" ControllerHotkeys.NextWindow
        . " = alternar janela"
        . "`n" ControllerHotkeys.ShowStatus
        . " = conferir cadastro"
        . "`n" ControllerHotkeys.BuildParty
        . " = montar PT"
        . "`n" ControllerHotkeys.RebuildParty
        . " = remontar PT"
        . "`n" ControllerHotkeys.ToggleMirror
        . " = espelhamento"
        . "`n" ControllerHotkeys.ClearRegistrations
        . " = limpar cadastros"
        . "`n" ControllerHotkeys.ExitController
        . " = fechar"
    )

    SetTimer(() => ToolTip(), -5500)
}