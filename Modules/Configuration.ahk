#Requires AutoHotkey v2.0

class Configuration
{
    static Load(configPath)
    {
        if !FileExist(configPath)
        {
            MsgBox(
                "Arquivo de configuração não encontrado:`n`n"
                . configPath
                . "`n`nO controller será fechado.",
                "PW Controller"
            )

            return false
        }

        notificationX := IniRead(
            configPath,
            "General",
            "NotificationX",
            0
        )

        notificationY := IniRead(
            configPath,
            "General",
            "NotificationY",
            0
        )

        inviteDelay := this.ReadNonNegativeInteger(
            configPath,
            "General",
            "InviteDelay",
            150
        )

        beforeAcceptDelay := this.ReadNonNegativeInteger(
            configPath,
            "General",
            "BeforeAcceptDelay",
            300
        )

        acceptDelay := this.ReadNonNegativeInteger(
            configPath,
            "General",
            "AcceptDelay",
            150
        )

        if notificationX = 0 || notificationY = 0
        {
            MsgBox(
                "As coordenadas da notificação não estão "
                . "configuradas corretamente.`n`n"
                . "Verifique no Characters.ini:`n"
                . "[General]`n"
                . "NotificationX=...`n"
                . "NotificationY=...`n`n"
                . "O controller será fechado.",
                "PW Controller"
            )

            return false
        }

        return {
            NotificationX: notificationX,
            NotificationY: notificationY,
            InviteDelay: inviteDelay,
            BeforeAcceptDelay: beforeAcceptDelay,
            AcceptDelay: acceptDelay
        }
    }

    /**
     * Carrega os atalhos configurados no Characters.ini.
     *
     * Todos os atalhos possuem um valor padrão para manter
     * compatibilidade com instalações antigas que ainda não
     * possuem a seção [Hotkeys].
     */
    static LoadHotkeys(configPath)
    {
        hotkeys := {
            RegisterLeader: this.ReadHotkey(
                configPath,
                "RegisterLeader",
                "F2"
            ),

            RegisterMule: this.ReadHotkey(
                configPath,
                "RegisterMule",
                "F3"
            ),

            NextWindow: this.ReadHotkey(
                configPath,
                "NextWindow",
                "SC029"
            ),

            ShowStatus: this.ReadHotkey(
                configPath,
                "ShowStatus",
                "F7"
            ),

            BuildParty: this.ReadHotkey(
                configPath,
                "BuildParty",
                "XButton1"
            ),

            RebuildParty: this.ReadHotkey(
                configPath,
                "RebuildParty",
                "XButton2"
            ),

            ToggleMirror: this.ReadOptionalHotkey(
                configPath,
                "ToggleMirror"
            ),

            ClearRegistrations: this.ReadHotkey(
                configPath,
                "ClearRegistrations",
                "^F3"
            ),

            ExitController: this.ReadHotkey(
                configPath,
                "ExitController",
                "^!F12"
            )
        }

        if !this.ValidateHotkeys(hotkeys)
            return false

        return hotkeys
    }

    /**
     * Lê um atalho da seção [Hotkeys].
     *
     * Remove espaços no início e no fim. Caso o valor esteja
     * vazio, utiliza o atalho padrão informado.
     */
    static ReadHotkey(configPath, key, defaultValue)
    {
        value := IniRead(
            configPath,
            "Hotkeys",
            key,
            defaultValue
        )

        value := Trim(value)

        if value = ""
            return defaultValue

        return value
    }

    /**
     * Lê um atalho opcional. Quando a chave não existe ou está vazia,
     * nenhum atalho é registrado para o comando.
     */
    static ReadOptionalHotkey(configPath, key)
    {
        value := IniRead(
            configPath,
            "Hotkeys",
            key,
            ""
        )

        return Trim(value)
    }


    /**
     * Verifica se dois comandos foram configurados
     * com o mesmo atalho.
     */
    static ValidateHotkeys(hotkeys)
    {
        registered := Map()

        descriptions := Map(
            "RegisterLeader", "Cadastrar principal",
            "RegisterMule", "Cadastrar mula",
            "NextWindow", "Alternar janela",
            "ShowStatus", "Mostrar status",
            "BuildParty", "Montar PT",
            "RebuildParty", "Remontar PT",
            "ToggleMirror", "Alternar espelhamento",
            "ClearRegistrations", "Limpar cadastros",
            "ExitController", "Fechar controller"
        )

        for propertyName, description in descriptions
        {
            hotkeyValue := hotkeys.%propertyName%
            normalizedValue := StrLower(Trim(hotkeyValue))

            ; Atalhos opcionais vazios não participam da validação.
            if normalizedValue = ""
                continue

            if registered.Has(normalizedValue)
            {
                MsgBox(
                    "Existem dois comandos utilizando o mesmo atalho."
                    . "`n`nAtalho: " hotkeyValue
                    . "`nComando 1: " registered[normalizedValue]
                    . "`nComando 2: " description
                    . "`n`nCorrija a seção [Hotkeys] "
                    . "do Characters.ini."
                    . "`n`nO controller será fechado.",
                    "Erro nos atalhos"
                )

                return false
            }

            registered[normalizedValue] := description
        }

        return true
    }

    static GetMuleName(configPath, slot)
    {
        return IniRead(
            configPath,
            "Mule" slot,
            "Name",
            "Mula " slot
        )
    }

    static GetMuleCoordinates(configPath, slot)
    {
        section := "Mule" slot

        return {
            FriendX: IniRead(configPath, section, "FriendX", 0),
            FriendY: IniRead(configPath, section, "FriendY", 0),
            InviteX: IniRead(configPath, section, "InviteX", 0),
            InviteY: IniRead(configPath, section, "InviteY", 0),
            PartyX: IniRead(configPath, section, "PartyX", 0),
            PartyY: IniRead(configPath, section, "PartyY", 0)
        }
    }

    static ValidateParty(
        configPath,
        leaderHwnd,
        mules,
        notificationX,
        notificationY
    )
    {
        if !leaderHwnd
        {
            MsgBox(
                "O líder ainda não foi cadastrado.`n`n"
                . "Cadastre primeiro a janela do personagem principal.",
                "PW Controller"
            )
            return false
        }

        if !PWWindows.IsOpen(leaderHwnd)
        {
            MsgBox(
                "A janela cadastrada como líder foi fechada.`n`n"
                . "Limpe os cadastros e registre as janelas novamente.",
                "PW Controller"
            )
            return false
        }

        if mules.Length = 0
        {
            MsgBox(
                "Nenhuma mula foi cadastrada.`n`n"
                . "Cadastre pelo menos uma mula.",
                "PW Controller"
            )
            return false
        }

        if notificationX = 0 || notificationY = 0
        {
            MsgBox(
                "As coordenadas da notificação não estão "
                . "configuradas no Characters.ini.",
                "PW Controller"
            )
            return false
        }

        preparedMules := []
        registeredWindows := Map()
        registeredWindows[leaderHwnd] := "Líder"

        for index, mule in mules
        {
            section := "Mule" index

            if !PWWindows.IsOpen(mule.Hwnd)
            {
                MsgBox(
                    "A janela de " mule.Name
                    . " não está mais aberta.`n`n"
                    . "Limpe os cadastros e registre as janelas novamente.",
                    "PW Controller"
                )
                return false
            }

            if registeredWindows.Has(mule.Hwnd)
            {
                MsgBox(
                    "Existe uma janela cadastrada duas vezes.`n`n"
                    . "Janela: " mule.Hwnd
                    . "`nJá cadastrada como: "
                    . registeredWindows[mule.Hwnd]
                    . "`nTambém cadastrada como: "
                    . mule.Name
                    . "`n`nUse Ctrl + F3 e cadastre novamente.",
                    "PW Controller"
                )
                return false
            }

            registeredWindows[mule.Hwnd] := mule.Name
            coordinates := this.GetMuleCoordinates(configPath, index)

            if coordinates.FriendX = 0 || coordinates.FriendY = 0
            {
                MsgBox(
                    "A posição do amigo da " section
                    . " não está configurada.`n`n"
                    . "Verifique no Characters.ini:`n"
                    . "[" section "]`n"
                    . "FriendX=...`n"
                    . "FriendY=...",
                    "PW Controller"
                )
                return false
            }

            if coordinates.InviteX = 0 || coordinates.InviteY = 0
            {
                MsgBox(
                    "A posição do botão de convite da " section
                    . " não está configurada.`n`n"
                    . "Verifique no Characters.ini:`n"
                    . "[" section "]`n"
                    . "InviteX=...`n"
                    . "InviteY=...",
                    "PW Controller"
                )
                return false
            }

            preparedMules.Push({
                Slot: index,
                Name: mule.Name,
                Hwnd: mule.Hwnd,
                FriendX: coordinates.FriendX,
                FriendY: coordinates.FriendY,
                InviteX: coordinates.InviteX,
                InviteY: coordinates.InviteY
            })
        }

        return {
            NotificationX: notificationX,
            NotificationY: notificationY,
            Mules: preparedMules
        }
    }

    static LoadRebuild(configPath, mules)
    {
        if mules.Length < 1
        {
            MsgBox(
                "Nenhuma mula foi registrada.`n`n"
                . "Registre as mulas com F3 antes de remontar a PT.",
                "PW Controller"
            )
            return false
        }

        kickX := IniRead(configPath, "General", "KickX", 0)
        kickY := IniRead(configPath, "General", "KickY", 0)
        transferLeaderX := IniRead(configPath, "General", "TransferLeaderX", 0)
        transferLeaderY := IniRead(configPath, "General", "TransferLeaderY", 0)
        leavePartyX := IniRead(configPath, "General", "LeavePartyX", 0)
        leavePartyY := IniRead(configPath, "General", "LeavePartyY", 0)

        selectDelay := this.ReadNonNegativeInteger(
            configPath, "General", "PartySelectDelay", 200
        )
        kickDelay := this.ReadNonNegativeInteger(
            configPath, "General", "PartyKickDelay", 300
        )
        transferDelay := this.ReadNonNegativeInteger(
            configPath, "General", "PartyTransferDelay", 500
        )
        beforeLeaveDelay := this.ReadNonNegativeInteger(
            configPath, "General", "PartyBeforeLeaveDelay", 500
        )
        leaveDelay := this.ReadNonNegativeInteger(
            configPath, "General", "PartyLeaveDelay", 300
        )

        if kickX = 0 || kickY = 0
        {
            this.ShowCoordinateError(
                "botão Expulsar",
                "KickX",
                "KickY"
            )
            return false
        }

        if transferLeaderX = 0 || transferLeaderY = 0
        {
            this.ShowCoordinateError(
                "botão Transferir liderança",
                "TransferLeaderX",
                "TransferLeaderY"
            )
            return false
        }

        if leavePartyX = 0 || leavePartyY = 0
        {
            this.ShowCoordinateError(
                "botão Sair da PT",
                "LeavePartyX",
                "LeavePartyY"
            )
            return false
        }

        partyMembers := []

        for index, mule in mules
        {
            section := "Mule" index
            coordinates := this.GetMuleCoordinates(configPath, index)

            if coordinates.PartyX = 0 || coordinates.PartyY = 0
            {
                MsgBox(
                    "A posição na PT de " section
                    . " não está configurada.`n`n"
                    . "Configure no Characters.ini:`n"
                    . "[" section "]`n"
                    . "PartyX=...`n"
                    . "PartyY=...",
                    "PW Controller"
                )
                return false
            }

            partyMembers.Push({
                Slot: index,
                Name: mule.Name,
                Hwnd: mule.Hwnd,
                PartyX: coordinates.PartyX,
                PartyY: coordinates.PartyY
            })
        }

        return {
            KickX: kickX,
            KickY: kickY,
            TransferLeaderX: transferLeaderX,
            TransferLeaderY: transferLeaderY,
            LeavePartyX: leavePartyX,
            LeavePartyY: leavePartyY,
            SelectDelay: selectDelay,
            KickDelay: kickDelay,
            TransferDelay: transferDelay,
            BeforeLeaveDelay: beforeLeaveDelay,
            LeaveDelay: leaveDelay,
            Members: partyMembers
        }
    }

    static ReadNonNegativeInteger(
        configPath,
        section,
        key,
        defaultValue
    )
    {
        value := IniRead(
            configPath,
            section,
            key,
            defaultValue
        )

        if !IsNumber(value)
            return defaultValue

        value := Integer(value)

        if value < 0
            return 0

        return value
    }

    static ShowCoordinateError(description, xKey, yKey)
    {
        MsgBox(
            "As coordenadas do " description
            . " não estão configuradas.`n`n"
            . "Configure no Characters.ini:`n"
            . xKey "=...`n"
            . yKey "=...",
            "PW Controller"
        )
    }
}
