#Requires AutoHotkey v2.0

/**
 * Painel principal do PW Controller.
 *
 * No modo compacto, mostra apenas os comandos de uso frequente.
 * No modo expandido, exibe as configurações do sistema.
 */
class FloatingPanel
{
    static Window := false
    static Expanded := false
    static ConfigPath := ""
    static Hotkeys := false

    static ToggleMirrorCallback := false
    static FollowLeaderCallback := false
    static GetMulesCallback := false
    static GetLeaderCallback := false
    static ApplyHotkeysCallback := false
    static ReloadSettingsCallback := false

    static MirrorStatusText := false
    static MirrorToggleButton := false
    static ExpandButton := false

    static ConfigTabs := false
    static ConfigStatusText := false

    static HotkeyEdits := Map()
    static HotkeySetupNotice := false
    static GeneralEdits := Map()

    static MuleSlotDDL := false
    static MuleNameEdit := false
    static MuleEdits := Map()
    static MuleConfigStatusText := false
    static LeaderRegistrationText := false
    static RegisteredMulesList := false

    static FollowActions := []
    static FollowList := false
    static EditingActionIndex := 0
    static ActionEnabledCheck := false
    static ActionMuleDDL := false
    static ActionTypeDDL := false
    static ActionButtonDDL := false
    static ActionXEdit := false
    static ActionYEdit := false
    static ActionKeyEdit := false
    static ActionDelayEdit := false
    static CaptureButton := false
    static FollowEditorStatus := false

    static Show(
        configPath,
        hotkeys,
        toggleMirrorCallback,
        followLeaderCallback,
        getMulesCallback,
        getLeaderCallback,
        applyHotkeysCallback,
        reloadSettingsCallback,
        mirrorEnabled := false
    )
    {
        this.ConfigPath := configPath
        this.Hotkeys := hotkeys
        this.ToggleMirrorCallback := toggleMirrorCallback
        this.FollowLeaderCallback := followLeaderCallback
        this.GetMulesCallback := getMulesCallback
        this.GetLeaderCallback := getLeaderCallback
        this.ApplyHotkeysCallback := applyHotkeysCallback
        this.ReloadSettingsCallback := reloadSettingsCallback

        if this.Window
        {
            this.UpdateMirrorStatus(mirrorEnabled)
            this.RefreshRegistrationStatus()
            this.Window.Show("NoActivate")
            return
        }

        panel := Gui(
            "+AlwaysOnTop +ToolWindow",
            "PW Controller"
        )

        ; Faz confirmações e avisos abertos pelos controles permanecerem
        ; na frente do painel, mesmo com o jogo aberto.
        panel.Opt("+OwnDialogs")
        panel.BackColor := "F3F7FC"
        panel.MarginX := 10
        panel.MarginY := 10
        panel.SetFont("s9", "Segoe UI")

        ; =====================================================
        ; ÁREA COMPACTA
        ; =====================================================

        panel.SetFont("s11 bold", "Segoe UI")
        panel.AddText(
            "x10 y10 w290 h34 Center 0x200 Background1F4E78 cFFFFFF",
            "PW CONTROLLER"
        )

        panel.SetFont("s9", "Segoe UI")

        this.ExpandButton := panel.AddButton(
            "x10 y52 w290 h30",
            "Abrir configurações  »"
        )
        this.ExpandButton.OnEvent(
            "Click",
            (*) => FloatingPanel.ToggleExpanded()
        )

        panel.AddText(
            "x10 y94 w290 Center c1F4E78",
            "ESPELHAMENTO DE CLIQUES"
        )

        this.MirrorStatusText := panel.AddText(
            "x10 y116 w290 Center",
            ""
        )

        ; Static com SS_NOTIFY funciona como botão e permite mudar a cor.
        this.MirrorToggleButton := panel.AddText(
            "x10 y138 w290 h34 Center 0x200 0x100 Border "
            . "BackgroundE2E8F0 c1F2937",
            ""
        )
        this.MirrorToggleButton.OnEvent(
            "Click",
            (*) => FloatingPanel.ToggleMirrorCallback.Call()
        )

        followButton := panel.AddButton(
            "x10 y182 w290 h40",
            "Fazer mulas seguirem o líder"
        )
        followButton.OnEvent(
            "Click",
            (*) => FloatingPanel.FollowLeaderCallback.Call()
        )

        panel.AddText(
            "x10 y231 w290 Center c64748B",
            "Arraste pela barra de título para mover"
        )

        ; =====================================================
        ; ÁREA EXPANDIDA
        ; =====================================================

        this.ConfigTabs := panel.AddTab3(
            "x320 y10 w660 h625",
            ["Seguir líder", "Atalhos", "Sistema", "Mulas"]
        )

        this.BuildFollowTab(panel)
        this.BuildHotkeysTab(panel)
        this.BuildSystemTab(panel)
        this.BuildMulesTab(panel)

        this.ConfigTabs.UseTab()

        panel.OnEvent(
            "Close",
            (guiObject, *) => guiObject.Hide()
        )

        this.Window := panel
        this.FollowActions := Configuration.LoadFollowActions(configPath)

        this.LoadHotkeyControls(hotkeys)
        this.LoadGeneralControls()
        this.LoadMuleControls(1)
        this.RefreshMuleChoices()
        this.RefreshActionList()
        this.RefreshRegistrationStatus()
        this.UpdateMirrorStatus(mirrorEnabled)

        if !Configuration.HasConfiguredHotkeys(configPath)
        {
            this.SetExpanded(true)
            this.ConfigTabs.Choose(2)
            this.HotkeySetupNotice.Text := "PRIMEIRA INICIALIZAÇÃO: configure pelo menos um atalho e salve."
            this.HotkeySetupNotice.Opt("BackgroundFFF4CC c8A5700")
        }
        else
        {
            this.SetExpanded(false)
        }
    }

    static BuildFollowTab(panel)
    {
        this.ConfigTabs.UseTab("Seguir líder")

        panel.SetFont("s9", "Segoe UI")
        panel.AddText(
            "x340 y48 w610",
            "Configure a sequência executada pelo botão Seguir líder. "
            . "Cada item pertence a uma mula específica."
        )

        this.FollowList := panel.AddListView(
            "x340 y75 w620 h275 Grid -Multi",
            ["#", "Mula", "Tipo", "Ação", "X", "Y", "Tecla", "Delay", "Ativo"]
        )

        this.FollowList.ModifyCol(1, 32)
        this.FollowList.ModifyCol(2, 90)
        this.FollowList.ModifyCol(3, 58)
        this.FollowList.ModifyCol(4, 72)
        this.FollowList.ModifyCol(5, 45)
        this.FollowList.ModifyCol(6, 45)
        this.FollowList.ModifyCol(7, 85)
        this.FollowList.ModifyCol(8, 58)
        this.FollowList.ModifyCol(9, 50)

        this.FollowList.OnEvent(
            "ItemSelect",
            (ctrl, row, selected) => FloatingPanel.OnActionSelected(
                ctrl,
                row,
                selected
            )
        )

        newClickButton := panel.AddButton(
            "x340 y360 w105 h28",
            "Novo clique"
        )
        newClickButton.OnEvent(
            "Click",
            (*) => FloatingPanel.NewAction("Click")
        )

        newKeyButton := panel.AddButton(
            "x450 y360 w105 h28",
            "Nova tecla"
        )
        newKeyButton.OnEvent(
            "Click",
            (*) => FloatingPanel.NewAction("Key")
        )

        removeButton := panel.AddButton(
            "x560 y360 w90 h28",
            "Excluir"
        )
        removeButton.OnEvent(
            "Click",
            (*) => FloatingPanel.RemoveSelectedAction()
        )

        upButton := panel.AddButton(
            "x655 y360 w65 h28",
            "Subir"
        )
        upButton.OnEvent(
            "Click",
            (*) => FloatingPanel.MoveSelectedAction(-1)
        )

        downButton := panel.AddButton(
            "x725 y360 w65 h28",
            "Descer"
        )
        downButton.OnEvent(
            "Click",
            (*) => FloatingPanel.MoveSelectedAction(1)
        )

        generateButton := panel.AddButton(
            "x795 y360 w165 h28",
            "Gerar padrão das mulas"
        )
        generateButton.OnEvent(
            "Click",
            (*) => FloatingPanel.GenerateDefaultFollowActions()
        )

        panel.AddGroupBox(
            "x340 y400 w620 h170",
            "Editor do item"
        )

        this.ActionEnabledCheck := panel.AddCheckBox(
            "x355 y425 w80",
            "Ativo"
        )
        this.ActionEnabledCheck.Value := 1

        panel.AddText("x445 y428 w40", "Mula:")
        this.ActionMuleDDL := panel.AddDropDownList(
            "x485 y423 w135",
            Configuration.GetMuleChoices(this.ConfigPath)
        )
        this.ActionMuleDDL.Choose(1)

        panel.AddText("x630 y428 w35", "Tipo:")
        this.ActionTypeDDL := panel.AddDropDownList(
            "x668 y423 w95",
            ["Clique", "Tecla"]
        )
        this.ActionTypeDDL.Choose(1)
        this.ActionTypeDDL.OnEvent(
            "Change",
            (*) => FloatingPanel.UpdateActionTypeControls()
        )

        panel.AddText("x775 y428 w42", "Delay:")
        this.ActionDelayEdit := panel.AddEdit(
            "x820 y423 w70 Number",
            "150"
        )
        panel.AddText("x895 y428 w25", "ms")

        panel.AddText("x355 y468 w45", "Clique:")
        this.ActionButtonDDL := panel.AddDropDownList(
            "x402 y463 w105",
            ["Esquerdo", "Direito"]
        )
        this.ActionButtonDDL.Choose(1)

        panel.AddText("x520 y468 w15", "X:")
        this.ActionXEdit := panel.AddEdit(
            "x540 y463 w55 Number",
            "0"
        )

        panel.AddText("x605 y468 w15", "Y:")
        this.ActionYEdit := panel.AddEdit(
            "x625 y463 w55 Number",
            "0"
        )

        this.CaptureButton := panel.AddButton(
            "x690 y462 w125 h27",
            "Capturar posição"
        )
        this.CaptureButton.OnEvent(
            "Click",
            (*) => FloatingPanel.StartCoordinateCapture()
        )

        panel.AddText("x355 y510 w45", "Tecla:")
        this.ActionKeyEdit := panel.AddEdit(
            "x402 y505 w180",
            ""
        )
        panel.AddText(
            "x402 y535 w250 cGray",
            "Ex.: {F1}, 1, Tab ou Space"
        )

        saveItemButton := panel.AddButton(
            "x690 y503 w125 h30 Default",
            "Salvar item"
        )
        saveItemButton.OnEvent(
            "Click",
            (*) => FloatingPanel.SaveActionEditor()
        )

        this.FollowEditorStatus := panel.AddText(
            "x340 y582 w620 Center cGray",
            "Selecione um item para editar ou crie um novo."
        )
    }

    static BuildHotkeysTab(panel)
    {
        this.ConfigTabs.UseTab("Atalhos")

        panel.AddText(
            "x340 y45 w620 h28 Center 0x200 BackgroundDCEBFA c1F4E78",
            "ATALHOS DO CONTROLLER"
        )

        this.HotkeySetupNotice := panel.AddText(
            "x350 y80 w600 h34 Center 0x200 BackgroundE8F1FB c1F4E78",
            "Configure pelo menos um atalho. Os demais campos podem ficar vazios."
        )

        fields := [
            ["RegisterLeader", "Cadastrar principal"],
            ["RegisterMule", "Cadastrar mula"],
            ["NextWindow", "Alternar janela"],
            ["ShowStatus", "Mostrar status"],
            ["BuildParty", "Montar PT"],
            ["RebuildParty", "Remontar PT"],
            ["ToggleMirror", "Alternar espelhamento"],
            ["ClearRegistrations", "Limpar cadastros"],
            ["ExitController", "Fechar controller"]
        ]

        for index, field in fields
        {
            column := index <= 5 ? 0 : 1
            row := column = 0 ? index - 1 : index - 6
            x := column = 0 ? 350 : 660
            fieldY := 125 + (row * 54)

            panel.AddText(
                "x" x " y" fieldY " w180 c334155",
                field[2]
            )

            edit := panel.AddEdit(
                "x" x " y" (fieldY + 19) " w250",
                ""
            )

            this.HotkeyEdits[field[1]] := edit
        }

        saveButton := panel.AddButton(
            "x700 y365 w210 h34 Default",
            "Salvar e aplicar atalhos"
        )
        saveButton.OnEvent(
            "Click",
            (*) => FloatingPanel.SaveHotkeys()
        )

        panel.AddText(
            "x350 y420 w590 c1F4E78",
            "GUIA PARA COPIAR E COLAR"
        )

        guide := "Tecla F1 = F1        | Ctrl + F1 = ^F1        | Alt + F1 = !F1`r`n"
            . "Shift + F1 = +F1   | Ctrl + Alt + F1 = ^!F1 | Tecla ' = SC029`r`n"
            . "Botão do meio = MButton | Lateral traseiro = XButton1`r`n"
            . "Lateral dianteiro = XButton2 | Escape = Esc | Espaço = Space`r`n"
            . "Deixe um campo vazio quando não quiser usar atalho nesse comando."

        panel.AddEdit(
            "x350 y445 w590 r7 ReadOnly",
            guide
        )
    }

    static BuildSystemTab(panel)
    {
        this.ConfigTabs.UseTab("Sistema")

        panel.AddText(
            "x340 y45 w620 h28 Center 0x200 BackgroundDCEBFA c1F4E78",
            "CONFIGURAÇÕES DO SISTEMA — CAPTURAS FEITAS NO PERSONAGEM PRINCIPAL"
        )

        panel.AddGroupBox(
            "x340 y82 w300 h475",
            "Montagem da PT"
        )

        this.AddGeneralCoordinatePair(
            panel,
            355,
            112,
            "Notificação para aceitar convite",
            "NotificationX",
            "NotificationY",
            "No personagem principal, clique na posição equivalente ao aviso "
            . "de convite que aparece na tela das mulas.",
            250
        )

        this.AddGeneralNumberField(
            panel,
            355,
            200,
            "Delay entre convites",
            "InviteDelay",
            "Tempo de espera entre convidar uma mula e a próxima.",
            "ms",
            250
        )

        this.AddGeneralNumberField(
            panel,
            355,
            275,
            "Espera antes dos aceites",
            "BeforeAcceptDelay",
            "Tempo após o último convite antes de começar a aceitar nas mulas.",
            "ms",
            250
        )

        this.AddGeneralNumberField(
            panel,
            355,
            350,
            "Delay entre aceites",
            "AcceptDelay",
            "Tempo entre aceitar o convite de uma mula e o da próxima.",
            "ms",
            250
        )

        panel.AddGroupBox(
            "x650 y82 w305 h475",
            "Remontagem da PT"
        )

        this.AddGeneralCoordinatePair(
            panel,
            665,
            112,
            "Botão Expulsar",
            "KickX",
            "KickY",
            "Selecione uma mula na lista da PT e capture o botão usado para expulsá-la.",
            260
        )

        this.AddGeneralCoordinatePair(
            panel,
            665,
            182,
            "Botão Transferir liderança",
            "TransferLeaderX",
            "TransferLeaderY",
            "Selecione um membro e capture o botão que transfere a liderança.",
            260
        )

        this.AddGeneralCoordinatePair(
            panel,
            665,
            252,
            "Botão Sair da PT",
            "LeavePartyX",
            "LeavePartyY",
            "Capture o botão usado pelo personagem principal para sair da PT.",
            260
        )

        this.AddGeneralNumberField(
            panel,
            665,
            330,
            "Selecionar membro",
            "PartySelectDelay",
            "Tempo entre selecionar a mula na PT e clicar no botão da ação.",
            "ms",
            125
        )

        this.AddGeneralNumberField(
            panel,
            815,
            330,
            "Depois de expulsar",
            "PartyKickDelay",
            "Tempo para o jogo processar a expulsão antes da próxima ação.",
            "ms",
            125
        )

        this.AddGeneralNumberField(
            panel,
            665,
            405,
            "Depois de transferir",
            "PartyTransferDelay",
            "Tempo após transferir a liderança.",
            "ms",
            125
        )

        this.AddGeneralNumberField(
            panel,
            815,
            405,
            "Antes de sair",
            "PartyBeforeLeaveDelay",
            "Espera adicional antes de o principal sair da PT.",
            "ms",
            125
        )

        this.AddGeneralNumberField(
            panel,
            665,
            480,
            "Depois de sair",
            "PartyLeaveDelay",
            "Tempo após clicar em Sair da PT.",
            "ms",
            125
        )

        saveButton := panel.AddButton(
            "x700 y570 w210 h32 Default",
            "Salvar configurações"
        )
        saveButton.OnEvent(
            "Click",
            (*) => FloatingPanel.SaveGeneralSettings()
        )

        this.ConfigStatusText := panel.AddText(
            "x340 y610 w620 Center c15803D",
            ""
        )
    }

    static BuildMulesTab(panel)
    {
        this.ConfigTabs.UseTab("Mulas")

        panel.AddText(
            "x340 y45 w620 h28 Center 0x200 BackgroundDCEBFA c1F4E78",
            "CONFIGURAÇÃO DAS MULAS — CAPTURAS FEITAS NO PERSONAGEM PRINCIPAL"
        )

        panel.AddText(
            "x340 y84 w110",
            "Mula configurada:"
        )

        this.MuleSlotDDL := panel.AddDropDownList(
            "x455 y79 w260",
            Configuration.GetMuleChoices(this.ConfigPath)
        )
        this.MuleSlotDDL.Choose(1)
        this.MuleSlotDDL.OnEvent(
            "Change",
            (*) => FloatingPanel.LoadMuleControls(
                FloatingPanel.MuleSlotDDL.Value
            )
        )

        this.MuleConfigStatusText := panel.AddText(
            "x735 y84 w210 Center",
            ""
        )

        panel.AddGroupBox(
            "x340 y115 w390 h430",
            "Dados e coordenadas"
        )

        panel.AddText("x365 y150 w80", "Nome:")
        this.MuleNameEdit := panel.AddEdit(
            "x450 y145 w220",
            ""
        )
        helpName := panel.AddButton("x685 y144 w28 h25", "?")
        helpName.OnEvent(
            "Click",
            (*) => FloatingPanel.ShowHelp(
                "Nome da mula",
                "Informe o nome do personagem correspondente a esta posição. "
                . "As mulas devem ser configuradas e cadastradas na mesma ordem."
            )
        )

        this.AddMuleCoordinatePair(
            panel,
            365,
            205,
            "Posição na lista de amigos",
            "FriendX",
            "FriendY",
            "Capture em cima do nome desta mula na lista de amigos do personagem principal."
        )

        this.AddMuleCoordinatePair(
            panel,
            365,
            295,
            "Opção Convidar do menu",
            "InviteX",
            "InviteY",
            "Abra o menu com o botão direito no nome da mula e capture a opção Convidar."
        )

        this.AddMuleCoordinatePair(
            panel,
            365,
            385,
            "Posição da mula na lista da PT",
            "PartyX",
            "PartyY",
            "Capture em cima da linha ocupada por esta mula na lista do grupo."
        )

        saveButton := panel.AddButton(
            "x455 y500 w210 h32 Default",
            "Salvar dados da mula"
        )
        saveButton.OnEvent(
            "Click",
            (*) => FloatingPanel.SaveMuleSettings()
        )

        panel.AddGroupBox(
            "x745 y115 w210 h430",
            "Cadastradas nesta sessão"
        )

        this.LeaderRegistrationText := panel.AddText(
            "x760 y145 w180 Center c64748B",
            "Principal: não cadastrado"
        )

        this.RegisteredMulesList := panel.AddListView(
            "x758 y180 w184 h285 Grid -Multi",
            ["#", "Nome", "Janela"]
        )
        this.RegisteredMulesList.ModifyCol(1, 28)
        this.RegisteredMulesList.ModifyCol(2, 90)
        this.RegisteredMulesList.ModifyCol(3, 60)

        refreshButton := panel.AddButton(
            "x775 y485 w150 h30",
            "Atualizar lista"
        )
        refreshButton.OnEvent(
            "Click",
            (*) => FloatingPanel.RefreshRegistrationStatus()
        )

        panel.AddText(
            "x340 y570 w610 c64748B",
            "A configuração fica salva no Characters.ini. O cadastro das janelas "
            . "vale somente durante a sessão atual do controller."
        )
    }

    static ToggleExpanded()
    {
        this.SetExpanded(!this.Expanded)
    }

    static SetExpanded(expanded)
    {
        this.Expanded := expanded

        if expanded
        {
            this.ExpandButton.Text := "Recolher configurações  «"
            this.Window.Show("w990 h650")
        }
        else
        {
            this.ExpandButton.Text := "Abrir configurações  »"
            this.Window.Show("w310 h262")
        }
    }

    static UpdateMirrorStatus(enabled)
    {
        if !this.MirrorStatusText || !this.MirrorToggleButton
            return

        if enabled
        {
            this.MirrorStatusText.Text := "Status: ATIVADO"
            this.MirrorStatusText.Opt("c15803D")
            this.MirrorToggleButton.Text := "Desativar espelhamento"
            this.MirrorToggleButton.Opt(
                "Background2563EB cFFFFFF"
            )
        }
        else
        {
            this.MirrorStatusText.Text := "Status: DESATIVADO"
            this.MirrorStatusText.Opt("c64748B")
            this.MirrorToggleButton.Text := "Ativar espelhamento"
            this.MirrorToggleButton.Opt(
                "BackgroundE2E8F0 c1F2937"
            )
        }
    }

    static LoadHotkeyControls(hotkeys)
    {
        for propertyName, edit in this.HotkeyEdits
            edit.Value := hotkeys.%propertyName%
    }

    static SaveHotkeys()
    {
        hotkeys := {
            RegisterLeader: Trim(this.HotkeyEdits["RegisterLeader"].Value),
            RegisterMule: Trim(this.HotkeyEdits["RegisterMule"].Value),
            NextWindow: Trim(this.HotkeyEdits["NextWindow"].Value),
            ShowStatus: Trim(this.HotkeyEdits["ShowStatus"].Value),
            BuildParty: Trim(this.HotkeyEdits["BuildParty"].Value),
            RebuildParty: Trim(this.HotkeyEdits["RebuildParty"].Value),
            ToggleMirror: Trim(this.HotkeyEdits["ToggleMirror"].Value),
            ClearRegistrations: Trim(this.HotkeyEdits["ClearRegistrations"].Value),
            ExitController: Trim(this.HotkeyEdits["ExitController"].Value)
        }

        if !Configuration.SaveHotkeys(this.ConfigPath, hotkeys)
            return

        if this.ApplyHotkeysCallback
        {
            if !this.ApplyHotkeysCallback.Call(hotkeys)
                return
        }

        this.Hotkeys := hotkeys
        this.HotkeySetupNotice.Text := "Atalhos salvos e aplicados nesta sessão."
        this.HotkeySetupNotice.Opt("BackgroundDCFCE7 c15803D")
        this.ShowConfigStatus("Atalhos salvos e aplicados.")
    }

    static LoadGeneralControls()
    {
        values := Configuration.LoadGeneralEditor(this.ConfigPath)

        for propertyName, edit in this.GeneralEdits
            edit.Value := values.%propertyName%
    }

    static SaveGeneralSettings()
    {
        values := {}

        for propertyName, edit in this.GeneralEdits
            values.%propertyName% := Trim(edit.Value)

        if !Configuration.SaveGeneralEditor(this.ConfigPath, values)
            return

        if this.ReloadSettingsCallback
            this.ReloadSettingsCallback.Call()

        this.ShowConfigStatus("Configurações do sistema salvas e aplicadas.")
    }

    static LoadMuleControls(slot)
    {
        if slot < 1
            slot := 1

        values := Configuration.LoadMuleEditor(
            this.ConfigPath,
            slot
        )

        this.MuleNameEdit.Value := values.Name

        for propertyName, edit in this.MuleEdits
            edit.Value := values.%propertyName%

        if this.MuleConfigStatusText
        {
            if Configuration.IsMuleConfigured(this.ConfigPath, slot)
            {
                this.MuleConfigStatusText.Text := "Configuração completa"
                this.MuleConfigStatusText.Opt("c15803D")
            }
            else
            {
                this.MuleConfigStatusText.Text := "Configuração pendente"
                this.MuleConfigStatusText.Opt("cB45309")
            }
        }
    }

    static SaveMuleSettings()
    {
        slot := this.MuleSlotDDL.Value
        values := {Name: Trim(this.MuleNameEdit.Value)}

        for propertyName, edit in this.MuleEdits
            values.%propertyName% := Trim(edit.Value)

        if !Configuration.SaveMuleEditor(
            this.ConfigPath,
            slot,
            values
        )
        {
            return
        }

        this.RefreshMuleChoices(slot)
        this.LoadMuleControls(slot)
        this.RefreshActionList()
        this.RefreshRegistrationStatus()
        this.ShowConfigStatus(
            "Dados da Mula " slot " salvos."
        )
    }

    static RefreshMuleChoices(selectedSlot := 1)
    {
        choices := Configuration.GetMuleChoices(this.ConfigPath)

        if this.MuleSlotDDL
        {
            this.MuleSlotDDL.Delete()
            this.MuleSlotDDL.Add(choices)
            this.MuleSlotDDL.Choose(selectedSlot)
        }

        if this.ActionMuleDDL
        {
            actionSlot := this.ActionMuleDDL.Value

            if actionSlot < 1
                actionSlot := 1

            this.ActionMuleDDL.Delete()
            this.ActionMuleDDL.Add(choices)
            this.ActionMuleDDL.Choose(actionSlot)
        }
    }

    static NewAction(type)
    {
        this.EditingActionIndex := 0
        this.ActionEnabledCheck.Value := 1
        this.ActionTypeDDL.Choose(type = "Key" ? 2 : 1)
        this.ActionButtonDDL.Choose(type = "Click" ? 1 : 1)
        this.ActionXEdit.Value := 0
        this.ActionYEdit.Value := 0
        this.ActionKeyEdit.Value := ""
        this.ActionDelayEdit.Value := 150
        this.UpdateActionTypeControls()
        this.FollowEditorStatus.Text := "Novo item: preencha os campos e clique em Salvar item."
    }

    static OnActionSelected(ctrl, row, selected)
    {
        if !selected || row < 1 || row > this.FollowActions.Length
            return

        this.LoadActionIntoEditor(row)
    }

    static LoadActionIntoEditor(index)
    {
        action := this.FollowActions[index]
        this.EditingActionIndex := index
        this.ActionEnabledCheck.Value := action.Enabled ? 1 : 0
        this.ActionMuleDDL.Choose(action.MuleSlot)
        this.ActionTypeDDL.Choose(
            StrLower(action.Type) = "key" ? 2 : 1
        )
        this.ActionButtonDDL.Choose(
            StrLower(action.Button) = "right" ? 2 : 1
        )
        this.ActionXEdit.Value := action.X
        this.ActionYEdit.Value := action.Y
        this.ActionKeyEdit.Value := action.Key
        this.ActionDelayEdit.Value := action.Delay
        this.UpdateActionTypeControls()
        this.FollowEditorStatus.Text := "Editando o item " index "."
    }

    static UpdateActionTypeControls()
    {
        isClick := this.ActionTypeDDL.Value = 1

        this.ActionButtonDDL.Enabled := isClick
        this.ActionXEdit.Enabled := isClick
        this.ActionYEdit.Enabled := isClick
        this.CaptureButton.Enabled := isClick
        this.ActionKeyEdit.Enabled := !isClick
    }

    static SaveActionEditor()
    {
        muleSlot := this.ActionMuleDDL.Value
        actionType := this.ActionTypeDDL.Value = 2
            ? "Key"
            : "Click"
        button := this.ActionButtonDDL.Value = 2
            ? "Right"
            : "Left"
        delay := Trim(this.ActionDelayEdit.Value)

        if muleSlot < 1 || muleSlot > 9
        {
            MsgBox("Selecione uma mula válida.", "PW Controller")
            return
        }

        if !IsNumber(delay) || Integer(delay) < 0
        {
            MsgBox(
                "O delay deve ser um número inteiro maior ou igual a zero.",
                "PW Controller"
            )
            return
        }

        x := Trim(this.ActionXEdit.Value)
        y := Trim(this.ActionYEdit.Value)
        key := Trim(this.ActionKeyEdit.Value)

        if actionType = "Click"
        {
            if !IsNumber(x) || !IsNumber(y)
            {
                MsgBox(
                    "As coordenadas X e Y devem ser números inteiros.",
                    "PW Controller"
                )
                return
            }
        }
        else if key = ""
        {
            MsgBox(
                "Informe a tecla que será enviada.",
                "PW Controller"
            )
            return
        }

        action := {
            Enabled: this.ActionEnabledCheck.Value = 1,
            MuleSlot: muleSlot,
            Type: actionType,
            Button: button,
            X: IsNumber(x) ? Integer(x) : 0,
            Y: IsNumber(y) ? Integer(y) : 0,
            Key: key,
            Delay: Integer(delay)
        }

        if this.EditingActionIndex > 0
        {
            savedIndex := this.EditingActionIndex
            this.FollowActions[savedIndex] := action
        }
        else
        {
            this.FollowActions.Push(action)
            savedIndex := this.FollowActions.Length
        }

        Configuration.SaveFollowActions(
            this.ConfigPath,
            this.FollowActions
        )

        this.RefreshActionList(savedIndex)
        this.LoadActionIntoEditor(savedIndex)
        this.FollowEditorStatus.Text := "Item salvo e aplicado à sequência."
    }

    static RemoveSelectedAction()
    {
        row := this.FollowList.GetNext(0)

        if row = 0
        {
            MsgBox(
                "Selecione um item para excluir.",
                "PW Controller"
            )
            return
        }

        this.FollowActions.RemoveAt(row)
        Configuration.SaveFollowActions(
            this.ConfigPath,
            this.FollowActions
        )

        this.EditingActionIndex := 0
        this.RefreshActionList()
        this.NewAction("Click")
        this.FollowEditorStatus.Text := "Item excluído da sequência."
    }

    static MoveSelectedAction(direction)
    {
        row := this.FollowList.GetNext(0)

        if row = 0
            return

        target := row + direction

        if target < 1 || target > this.FollowActions.Length
            return

        temporary := this.FollowActions[row]
        this.FollowActions[row] := this.FollowActions[target]
        this.FollowActions[target] := temporary

        Configuration.SaveFollowActions(
            this.ConfigPath,
            this.FollowActions
        )

        this.RefreshActionList(target)
        this.LoadActionIntoEditor(target)
    }

    static RefreshActionList(selectedIndex := 0)
    {
        if !this.FollowList
            return

        this.FollowList.Delete()
        muleChoices := Configuration.GetMuleChoices(this.ConfigPath)

        for index, action in this.FollowActions
        {
            muleName := action.MuleSlot >= 1
                && action.MuleSlot <= muleChoices.Length
                ? muleChoices[action.MuleSlot]
                : "Mula " action.MuleSlot

            typeText := StrLower(action.Type) = "key"
                ? "Tecla"
                : "Clique"

            actionText := ""

            if typeText = "Clique"
            {
                actionText := StrLower(action.Button) = "right"
                    ? "Direito"
                    : "Esquerdo"
            }

            this.FollowList.Add(
                "",
                index,
                muleName,
                typeText,
                actionText,
                action.X,
                action.Y,
                action.Key,
                action.Delay,
                action.Enabled ? "Sim" : "Não"
            )
        }

        if selectedIndex > 0
            this.FollowList.Modify(
                selectedIndex,
                "Select Focus Vis"
            )
    }

    static StartCoordinateCapture()
    {
        if this.ActionTypeDDL.Value != 1
        {
            MsgBox(
                "A captura de posição está disponível apenas para cliques.",
                "PW Controller"
            )
            return
        }

        muleSlot := this.ActionMuleDDL.Value
        mules := this.GetMulesCallback.Call()

        if muleSlot < 1 || muleSlot > mules.Length
        {
            MsgBox(
                "A Mula " muleSlot " ainda não está cadastrada nesta sessão.`n`n"
                . "Cadastre a mula antes de capturar a coordenada.",
                "PW Controller"
            )
            return
        }

        targetHwnd := mules[muleSlot].Hwnd
        this.Window.Hide()

        started := CoordinateCapture.Start(
            targetHwnd,
            (x, y) => FloatingPanel.ApplyCapturedCoordinates(x, y),
            (*) => FloatingPanel.RestoreAfterCapture()
        )

        if !started
            this.RestoreAfterCapture()
    }

    static ApplyCapturedCoordinates(x, y)
    {
        this.ActionXEdit.Value := x
        this.ActionYEdit.Value := y
        this.RestoreAfterCapture()
        this.FollowEditorStatus.Text := "Coordenada capturada: X=" x " Y=" y "."
    }

    static RestoreAfterCapture()
    {
        this.Expanded := true
        this.ExpandButton.Text := "Recolher configurações  «"
        this.Window.Show("w990 h650")
    }

    static GenerateDefaultFollowActions()
    {
        if this.Window
            this.Window.Opt("+OwnDialogs")

        mules := this.GetMulesCallback.Call()

        if mules.Length = 0
        {
            MsgBox(
                "Cadastre as mulas antes de gerar a sequência padrão.",
                "PW Controller"
            )
            return
        }

        if !this.Confirm(
            "Isso substituirá a sequência atual por dois cliques para cada "
            . "mula cadastrada.`n`nDeseja continuar?",
            "Gerar sequência padrão"
        )
        {
            return
        }

        menuX := IniRead(this.ConfigPath, "General", "FollowMenuX", 20)
        menuY := IniRead(this.ConfigPath, "General", "FollowMenuY", 205)
        optionX := IniRead(this.ConfigPath, "General", "FollowOptionX", 60)
        optionY := IniRead(this.ConfigPath, "General", "FollowOptionY", 245)
        menuDelay := IniRead(this.ConfigPath, "General", "FollowMenuDelay", 150)
        muleDelay := IniRead(this.ConfigPath, "General", "FollowMuleDelay", 150)

        this.FollowActions := PartyFollow.BuildLegacyActions(
            mules,
            menuX,
            menuY,
            optionX,
            optionY,
            menuDelay,
            muleDelay
        )

        Configuration.SaveFollowActions(
            this.ConfigPath,
            this.FollowActions
        )

        this.RefreshActionList(1)
        this.LoadActionIntoEditor(1)
        this.FollowEditorStatus.Text := "Sequência padrão criada para " mules.Length " mula(s)."
    }

    static AddGeneralCoordinatePair(
        panel,
        x,
        y,
        title,
        xKey,
        yKey,
        helpText,
        width
    )
    {
        panel.AddText(
            "x" x " y" y " w" (width - 35) " c334155",
            title
        )

        helpButton := panel.AddButton(
            "x" (x + width - 28) " y" (y - 3) " w26 h24",
            "?"
        )
        helpButton.OnEvent(
            "Click",
            (*) => FloatingPanel.ShowHelp(title, helpText)
        )

        panel.AddText("x" x " y" (y + 31) " w15", "X:")
        xEdit := panel.AddEdit(
            "x" (x + 20) " y" (y + 26) " w55 Number",
            "0"
        )
        this.GeneralEdits[xKey] := xEdit

        panel.AddText("x" (x + 82) " y" (y + 31) " w15", "Y:")
        yEdit := panel.AddEdit(
            "x" (x + 102) " y" (y + 26) " w55 Number",
            "0"
        )
        this.GeneralEdits[yKey] := yEdit

        captureButton := panel.AddButton(
            "x" (x + 165) " y" (y + 25) " w" (width - 165) " h27",
            "Capturar"
        )
        captureButton.OnEvent(
            "Click",
            (*) => FloatingPanel.StartLeaderCoordinateCapture(
                xEdit,
                yEdit,
                title
            )
        )
    }

    static AddGeneralNumberField(
        panel,
        x,
        y,
        title,
        key,
        helpText,
        unit,
        width
    )
    {
        panel.AddText(
            "x" x " y" y " w" (width - 35) " c334155",
            title
        )

        helpButton := panel.AddButton(
            "x" (x + width - 28) " y" (y - 3) " w26 h24",
            "?"
        )
        helpButton.OnEvent(
            "Click",
            (*) => FloatingPanel.ShowHelp(title, helpText)
        )

        edit := panel.AddEdit(
            "x" x " y" (y + 23) " w80 Number",
            "0"
        )
        this.GeneralEdits[key] := edit
        panel.AddText(
            "x" (x + 87) " y" (y + 28) " w35",
            unit
        )
    }

    static AddMuleCoordinatePair(
        panel,
        x,
        y,
        title,
        xKey,
        yKey,
        helpText
    )
    {
        panel.AddText(
            "x" x " y" y " w285 c334155",
            title
        )

        helpButton := panel.AddButton(
            "x685 y" (y - 3) " w28 h25",
            "?"
        )
        helpButton.OnEvent(
            "Click",
            (*) => FloatingPanel.ShowHelp(title, helpText)
        )

        panel.AddText("x" x " y" (y + 34) " w15", "X:")
        xEdit := panel.AddEdit(
            "x" (x + 20) " y" (y + 29) " w65 Number",
            "0"
        )
        this.MuleEdits[xKey] := xEdit

        panel.AddText("x" (x + 98) " y" (y + 34) " w15", "Y:")
        yEdit := panel.AddEdit(
            "x" (x + 118) " y" (y + 29) " w65 Number",
            "0"
        )
        this.MuleEdits[yKey] := yEdit

        captureButton := panel.AddButton(
            "x" (x + 195) " y" (y + 28) " w125 h28",
            "Capturar no principal"
        )
        captureButton.OnEvent(
            "Click",
            (*) => FloatingPanel.StartLeaderCoordinateCapture(
                xEdit,
                yEdit,
                title
            )
        )
    }

    static StartLeaderCoordinateCapture(
        xEdit,
        yEdit,
        description,
        *
    )
    {
        if !this.GetLeaderCallback
        {
            MsgBox(
                "O acesso ao personagem principal não está disponível.",
                "PW Controller"
            )
            return
        }

        leaderHwnd := this.GetLeaderCallback.Call()

        if !leaderHwnd || !PWWindows.IsOpen(leaderHwnd)
        {
            MsgBox(
                "Cadastre e mantenha aberta a janela do personagem principal "
                . "antes de capturar coordenadas.",
                "PW Controller"
            )
            return
        }

        this.Window.Hide()

        captureCallback := (capturedX, capturedY) => FloatingPanel.ApplyLeaderCapturedCoordinates(
            xEdit,
            yEdit,
            description,
            capturedX,
            capturedY
        )

        started := CoordinateCapture.Start(
            leaderHwnd,
            captureCallback,
            (*) => FloatingPanel.RestoreAfterCapture()
        )

        if !started
            this.RestoreAfterCapture()
    }

    static ApplyLeaderCapturedCoordinates(
        xEdit,
        yEdit,
        description,
        x,
        y
    )
    {
        xEdit.Value := x
        yEdit.Value := y
        this.RestoreAfterCapture()
        this.ShowConfigStatus(
            description ": X=" x " Y=" y "."
        )
    }

    static RefreshRegistrationStatus()
    {
        if this.LeaderRegistrationText && this.GetLeaderCallback
        {
            leaderHwnd := this.GetLeaderCallback.Call()

            if leaderHwnd && PWWindows.IsOpen(leaderHwnd)
            {
                this.LeaderRegistrationText.Text := "Principal: cadastrado"
                this.LeaderRegistrationText.Opt("c15803D")
            }
            else if leaderHwnd
            {
                this.LeaderRegistrationText.Text := "Principal: janela fechada"
                this.LeaderRegistrationText.Opt("cB91C1C")
            }
            else
            {
                this.LeaderRegistrationText.Text := "Principal: não cadastrado"
                this.LeaderRegistrationText.Opt("c64748B")
            }
        }

        if !this.RegisteredMulesList || !this.GetMulesCallback
            return

        this.RegisteredMulesList.Delete()
        mules := this.GetMulesCallback.Call()

        if mules.Length = 0
        {
            this.RegisteredMulesList.Add("", "-", "Nenhuma", "-")
            return
        }

        for index, mule in mules
        {
            status := PWWindows.IsOpen(mule.Hwnd)
                ? "Aberta"
                : "Fechada"

            this.RegisteredMulesList.Add(
                "",
                mule.HasOwnProp("Slot") ? mule.Slot : index,
                mule.Name,
                status
            )
        }
    }

    static OpenMulesTab(slot := 1)
    {
        if !this.Window
            return

        if slot < 1 || slot > 9
            slot := 1

        this.SetExpanded(true)
        this.ConfigTabs.Choose(4)
        this.MuleSlotDDL.Choose(slot)
        this.LoadMuleControls(slot)
        this.RefreshRegistrationStatus()
        this.Window.Show()
    }

    static OpenHotkeysTab()
    {
        if !this.Window
            return

        this.SetExpanded(true)
        this.ConfigTabs.Choose(2)
        this.Window.Show()
    }

    static ShowDialog(message, title := "PW Controller", options := "")
    {
        if this.Window
        {
            this.Window.Opt("+OwnDialogs")
            this.Window.Show("NoActivate")
        }

        return MsgBox(message, title, options)
    }

    static ShowHelp(title, message)
    {
        return this.ShowDialog(message, title)
    }

    static Confirm(message, title)
    {
        if this.Window
        {
            this.Window.Opt("+OwnDialogs")
            this.Window.Show()
        }

        return MsgBox(
            message,
            title,
            "YesNo Icon?"
        ) = "Yes"
    }

    static ShowConfigStatus(message)
    {
        if this.ConfigStatusText
            this.ConfigStatusText.Text := message

        ToolTip(message)
        SetTimer(() => ToolTip(), -2200)
    }

    static FormatHotkey(hotkey)
    {
        hk := Trim(hotkey)

        if hk = ""
            return "Não configurado"

        hk := StrReplace(hk, "^", "Ctrl + ")
        hk := StrReplace(hk, "!", "Alt + ")
        hk := StrReplace(hk, "+", "Shift + ")
        hk := StrReplace(hk, "#", "Win + ")
        hk := StrReplace(hk, "XButton1", "Botão lateral traseiro")
        hk := StrReplace(hk, "XButton2", "Botão lateral dianteiro")
        hk := StrReplace(hk, "MButton", "Botão do meio")
        hk := StrReplace(hk, "LButton", "Botão esquerdo")
        hk := StrReplace(hk, "RButton", "Botão direito")
        hk := StrReplace(hk, "WheelUp", "Roda ↑")
        hk := StrReplace(hk, "WheelDown", "Roda ↓")
        hk := StrReplace(hk, "SC029", "'")
        hk := StrReplace(hk, "Esc", "Escape")
        hk := StrReplace(hk, "Del", "Delete")
        hk := StrReplace(hk, "PgUp", "Page Up")
        hk := StrReplace(hk, "PgDn", "Page Down")

        return hk
    }
}
