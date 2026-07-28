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

        ; As coordenadas podem permanecer zeradas na primeira execução.
        ; A validação é feita somente quando a funcionalidade correspondente
        ; for utilizada, permitindo que o usuário configure tudo pela janela.
        return {
            NotificationX: this.ReadNonNegativeInteger(
                configPath,
                "General",
                "NotificationX",
                0
            ),
            NotificationY: this.ReadNonNegativeInteger(
                configPath,
                "General",
                "NotificationY",
                0
            ),
            InviteDelay: this.ReadNonNegativeInteger(
                configPath,
                "General",
                "InviteDelay",
                150
            ),
            BeforeAcceptDelay: this.ReadNonNegativeInteger(
                configPath,
                "General",
                "BeforeAcceptDelay",
                300
            ),
            AcceptDelay: this.ReadNonNegativeInteger(
                configPath,
                "General",
                "AcceptDelay",
                150
            )
        }
    }

    static LoadHotkeys(configPath)
    {
        ; Nenhum comando possui atalho padrão. Na primeira execução,
        ; a janela abre diretamente na aba Atalhos para o usuário escolher.
        hotkeys := {
            RegisterLeader: this.ReadOptionalHotkey(
                configPath,
                "RegisterLeader"
            ),
            RegisterMule: this.ReadOptionalHotkey(
                configPath,
                "RegisterMule"
            ),
            NextWindow: this.ReadOptionalHotkey(
                configPath,
                "NextWindow"
            ),
            ShowStatus: this.ReadOptionalHotkey(
                configPath,
                "ShowStatus"
            ),
            BuildParty: this.ReadOptionalHotkey(
                configPath,
                "BuildParty"
            ),
            RebuildParty: this.ReadOptionalHotkey(
                configPath,
                "RebuildParty"
            ),
            ToggleMirror: this.ReadOptionalHotkey(
                configPath,
                "ToggleMirror"
            ),
            ClearRegistrations: this.ReadOptionalHotkey(
                configPath,
                "ClearRegistrations"
            ),
            ExitController: this.ReadOptionalHotkey(
                configPath,
                "ExitController"
            )
        }

        if !this.ValidateHotkeys(hotkeys)
            return false

        return hotkeys
    }

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
                    . "`n`nUse atalhos diferentes para cada comando.",
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
        return Trim(IniRead(
            configPath,
            "Mule" slot,
            "Name",
            ""
        ))
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
                    . "`n`nLimpe os cadastros e registre novamente.",
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
                . "Registre as mulas antes de remontar a PT.",
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


    /**
     * Carrega e valida as configurações utilizadas para fazer
     * todas as mulas cadastradas seguirem o líder.
     */
    static LoadFollowLeader(configPath, mules)
    {
        if mules.Length = 0
        {
            MsgBox(
                "Nenhuma mula foi cadastrada.`n`n"
                . "Cadastre pelo menos uma mula antes de usar "
                . "o comando Seguir líder.",
                "PW Controller"
            )

            return false
        }

        menuX := IniRead(configPath, "General", "FollowMenuX", 0)
        menuY := IniRead(configPath, "General", "FollowMenuY", 0)
        followX := IniRead(configPath, "General", "FollowOptionX", 0)
        followY := IniRead(configPath, "General", "FollowOptionY", 0)

        menuDelay := this.ReadNonNegativeInteger(
            configPath,
            "General",
            "FollowMenuDelay",
            150
        )

        muleDelay := this.ReadNonNegativeInteger(
            configPath,
            "General",
            "FollowMuleDelay",
            100
        )

        if menuX = 0 || menuY = 0
        {
            this.ShowCoordinateError(
                "local para abrir o menu Seguir",
                "FollowMenuX",
                "FollowMenuY"
            )

            return false
        }

        if followX = 0 || followY = 0
        {
            this.ShowCoordinateError(
                "item Seguir do menu",
                "FollowOptionX",
                "FollowOptionY"
            )

            return false
        }

        preparedMules := []

        for mule in mules
        {
            if !PWWindows.IsOpen(mule.Hwnd)
            {
                MsgBox(
                    "A janela de " mule.Name
                    . " não está mais aberta.`n`n"
                    . "Limpe os cadastros e registre "
                    . "as janelas novamente.",
                    "PW Controller"
                )

                return false
            }

            preparedMules.Push({
                Name: mule.Name,
                Hwnd: mule.Hwnd
            })
        }

        return {
            MenuX: menuX,
            MenuY: menuY,
            FollowX: followX,
            FollowY: followY,
            MenuDelay: menuDelay,
            MuleDelay: muleDelay,
            Mules: preparedMules
        }
    }

    /**
     * Carrega a sequência personalizada do comando Seguir líder.
     */
    static LoadFollowActions(configPath)
    {
        count := this.ReadNonNegativeInteger(
            configPath,
            "FollowSequence",
            "Count",
            0
        )

        actions := []

        Loop count
        {
            section := "FollowAction" A_Index

            enabledValue := IniRead(
                configPath,
                section,
                "Enabled",
                1
            )

            actions.Push({
                Enabled: enabledValue != 0,
                MuleSlot: this.ReadNonNegativeInteger(
                    configPath,
                    section,
                    "MuleSlot",
                    1
                ),
                Type: Trim(IniRead(
                    configPath,
                    section,
                    "Type",
                    "Click"
                )),
                Button: Trim(IniRead(
                    configPath,
                    section,
                    "Button",
                    "Left"
                )),
                X: this.ReadNonNegativeInteger(
                    configPath,
                    section,
                    "X",
                    0
                ),
                Y: this.ReadNonNegativeInteger(
                    configPath,
                    section,
                    "Y",
                    0
                ),
                Key: Trim(IniRead(
                    configPath,
                    section,
                    "Key",
                    ""
                )),
                Delay: this.ReadNonNegativeInteger(
                    configPath,
                    section,
                    "Delay",
                    100
                )
            })
        }

        return actions
    }

    /**
     * Salva a sequência completa e remove seções antigas que sobraram.
     */
    static SaveFollowActions(configPath, actions)
    {
        oldCount := this.ReadNonNegativeInteger(
            configPath,
            "FollowSequence",
            "Count",
            0
        )

        maxCount := Max(oldCount, actions.Length)

        Loop maxCount
        {
            section := "FollowAction" A_Index
            try IniDelete(configPath, section)
        }

        IniWrite(
            actions.Length,
            configPath,
            "FollowSequence",
            "Count"
        )

        for index, action in actions
        {
            section := "FollowAction" index

            IniWrite(
                action.Enabled ? 1 : 0,
                configPath,
                section,
                "Enabled"
            )
            IniWrite(action.MuleSlot, configPath, section, "MuleSlot")
            IniWrite(action.Type, configPath, section, "Type")
            IniWrite(action.Button, configPath, section, "Button")
            IniWrite(action.X, configPath, section, "X")
            IniWrite(action.Y, configPath, section, "Y")
            IniWrite(action.Key, configPath, section, "Key")
            IniWrite(action.Delay, configPath, section, "Delay")
        }

        return true
    }

    /**
     * Salva os atalhos editados pela interface.
     */
    static SaveHotkeys(configPath, hotkeys, allowEmpty := false)
    {
        properties := [
            "RegisterLeader",
            "RegisterMule",
            "NextWindow",
            "ShowStatus",
            "BuildParty",
            "RebuildParty",
            "ToggleMirror",
            "ClearRegistrations",
            "ExitController"
        ]

        configuredCount := 0

        for propertyName in properties
        {
            if Trim(hotkeys.%propertyName%) != ""
                configuredCount += 1
        }

        if configuredCount = 0 && !allowEmpty
        {
            MsgBox(
                "Configure pelo menos um atalho antes de salvar.`n`n"
                . "Nenhuma tecla é preenchida automaticamente.",
                "PW Controller"
            )
            return false
        }

        if !this.ValidateHotkeys(hotkeys)
            return false

        for propertyName in properties
        {
            IniWrite(
                Trim(hotkeys.%propertyName%),
                configPath,
                "Hotkeys",
                propertyName
            )
        }

        IniWrite(
            configuredCount > 0 ? 1 : 0,
            configPath,
            "Setup",
            "HotkeysConfigured"
        )
        return true
    }

    static LoadGeneralEditor(configPath)
    {
        return {
            NotificationX: IniRead(configPath, "General", "NotificationX", 0),
            NotificationY: IniRead(configPath, "General", "NotificationY", 0),
            InviteDelay: IniRead(configPath, "General", "InviteDelay", 150),
            BeforeAcceptDelay: IniRead(configPath, "General", "BeforeAcceptDelay", 300),
            AcceptDelay: IniRead(configPath, "General", "AcceptDelay", 150),
            KickX: IniRead(configPath, "General", "KickX", 0),
            KickY: IniRead(configPath, "General", "KickY", 0),
            TransferLeaderX: IniRead(configPath, "General", "TransferLeaderX", 0),
            TransferLeaderY: IniRead(configPath, "General", "TransferLeaderY", 0),
            LeavePartyX: IniRead(configPath, "General", "LeavePartyX", 0),
            LeavePartyY: IniRead(configPath, "General", "LeavePartyY", 0),
            PartySelectDelay: IniRead(configPath, "General", "PartySelectDelay", 100),
            PartyKickDelay: IniRead(configPath, "General", "PartyKickDelay", 50),
            PartyTransferDelay: IniRead(configPath, "General", "PartyTransferDelay", 300),
            PartyBeforeLeaveDelay: IniRead(configPath, "General", "PartyBeforeLeaveDelay", 400),
            PartyLeaveDelay: IniRead(configPath, "General", "PartyLeaveDelay", 300)
        }
    }

    static SaveGeneralEditor(configPath, values)
    {
        keys := [
            "NotificationX",
            "NotificationY",
            "InviteDelay",
            "BeforeAcceptDelay",
            "AcceptDelay",
            "KickX",
            "KickY",
            "TransferLeaderX",
            "TransferLeaderY",
            "LeavePartyX",
            "LeavePartyY",
            "PartySelectDelay",
            "PartyKickDelay",
            "PartyTransferDelay",
            "PartyBeforeLeaveDelay",
            "PartyLeaveDelay"
        ]

        for key in keys
        {
            value := Trim(values.%key%)

            if !IsNumber(value) || Integer(value) < 0
            {
                MsgBox(
                    "O campo " key " deve ser um número inteiro maior ou igual a zero.",
                    "PW Controller"
                )
                return false
            }
        }

        for key in keys
            IniWrite(Integer(values.%key%), configPath, "General", key)

        return true
    }

    static LoadMuleEditor(configPath, slot)
    {
        coordinates := this.GetMuleCoordinates(configPath, slot)

        return {
            Name: this.GetMuleName(configPath, slot),
            FriendX: coordinates.FriendX,
            FriendY: coordinates.FriendY,
            InviteX: coordinates.InviteX,
            InviteY: coordinates.InviteY,
            PartyX: coordinates.PartyX,
            PartyY: coordinates.PartyY
        }
    }

    static SaveMuleEditor(configPath, slot, values)
    {
        if slot < 1 || slot > 9
            return false

        name := Trim(values.Name)

        if name = ""
        {
            MsgBox(
                "Informe o nome da mula.",
                "PW Controller"
            )
            return false
        }

        labels := Map(
            "FriendX", "posição do nome na lista de amigos (X)",
            "FriendY", "posição do nome na lista de amigos (Y)",
            "InviteX", "botão Convidar do menu (X)",
            "InviteY", "botão Convidar do menu (Y)",
            "PartyX", "posição da mula na lista da PT (X)",
            "PartyY", "posição da mula na lista da PT (Y)"
        )

        for key, description in labels
        {
            value := Trim(values.%key%)

            if !IsNumber(value) || Integer(value) <= 0
            {
                MsgBox(
                    "Configure a " description ".`n`n"
                    . "Use o botão Capturar para preencher as coordenadas.",
                    "PW Controller"
                )
                return false
            }
        }

        section := "Mule" slot
        IniWrite(name, configPath, section, "Name")

        for key, description in labels
            IniWrite(Integer(values.%key%), configPath, section, key)

        return true
    }

    static GetMuleChoices(configPath)
    {
        choices := []

        Loop 9
        {
            slot := A_Index
            name := this.GetMuleName(configPath, slot)

            if name = ""
                choices.Push("Mula " slot " — não configurada")
            else
                choices.Push("Mula " slot " — " name)
        }

        return choices
    }

    static HasConfiguredHotkeys(configPath)
    {
        if IniRead(
            configPath,
            "Setup",
            "HotkeysConfigured",
            0
        ) != 0
        {
            return true
        }

        properties := [
            "RegisterLeader",
            "RegisterMule",
            "NextWindow",
            "ShowStatus",
            "BuildParty",
            "RebuildParty",
            "ToggleMirror",
            "ClearRegistrations",
            "ExitController"
        ]

        for propertyName in properties
        {
            if Trim(IniRead(
                configPath,
                "Hotkeys",
                propertyName,
                ""
            )) != ""
            {
                return true
            }
        }

        return false
    }

    static IsMuleConfigured(configPath, slot)
    {
        if slot < 1 || slot > 9
            return false

        if this.GetMuleName(configPath, slot) = ""
            return false

        coordinates := this.GetMuleCoordinates(configPath, slot)

        return coordinates.FriendX > 0
            && coordinates.FriendY > 0
            && coordinates.InviteX > 0
            && coordinates.InviteY > 0
            && coordinates.PartyX > 0
            && coordinates.PartyY > 0
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
