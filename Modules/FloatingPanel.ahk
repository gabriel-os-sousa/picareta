#Requires AutoHotkey v2.0

/**
 * Janela flutuante do PW Controller.
 *
 * A janela pertence ao próprio controller, e não a um cliente do jogo.
 * Por isso, continua visível ao alternar entre os personagens.
 */
class FloatingPanel
{
    static Window := false
    static MirrorStatusText := false
    static MirrorToggleButton := false

    /**
     * Cria e exibe a janela flutuante.
     *
     * O callback recebido utiliza a mesma função responsável pelo atalho,
     * mantendo em um único lugar a alteração do estado e do ícone da bandeja.
     */
    static Show(
        hotkeys,
        toggleMirrorCallback,
        followLeaderCallback,
        mirrorEnabled := false
    )
    {
        if this.Window
        {
            this.UpdateMirrorStatus(mirrorEnabled)
            this.Window.Show("NoActivate")
            return
        }

        panel := Gui(
            "+AlwaysOnTop +ToolWindow",
            "PW Controller"
        )

        panel.MarginX := 12
        panel.MarginY := 10
        panel.SetFont("s10", "Segoe UI")

        panel.AddText(
            "xm w270 Center",
            "ATALHOS CONFIGURADOS"
        )

        panel.SetFont("s9", "Segoe UI")

        panel.AddText(
            "xm y+10 w270",
            this.BuildHotkeyText(hotkeys)
        )

        panel.AddText(
            "xm y+12 w270 0x10"
        )

        panel.SetFont("s10 bold", "Segoe UI")
        panel.AddText(
            "xm y+10 w270 Center",
            "ESPELHAMENTO DE CLIQUES"
        )

        panel.SetFont("s9", "Segoe UI")

        this.MirrorStatusText := panel.AddText(
            "xm y+8 w270 Center",
            ""
        )

        this.MirrorToggleButton := panel.AddButton(
            "xm y+8 w270 h32",
            ""
        )

        this.MirrorToggleButton.OnEvent(
            "Click",
            toggleMirrorCallback
        )

        panel.AddText(
            "xm y+12 w270 0x10"
        )

        panel.SetFont("s10 bold", "Segoe UI")

        panel.AddText(
            "xm y+10 w270 Center",
            "COMANDOS DAS MULAS"
        )

        panel.SetFont("s9", "Segoe UI")

        followButton := panel.AddButton(
            "xm y+8 w270 h32",
            "Fazer mulas seguirem o líder"
        )

        followButton.OnEvent(
            "Click",
            followLeaderCallback
        )

        panel.AddText(
            "xm y+12 w270 Center cGray",
            "Arraste pela barra de título para mover"
        )

        ; Ao clicar no X, apenas oculta a janela.
        ; O controller continua funcionando.
        panel.OnEvent("Close", (guiObject, *) => guiObject.Hide())

        this.Window := panel
        this.UpdateMirrorStatus(mirrorEnabled)

        panel.Show("AutoSize NoActivate")
    }

    /**
     * Atualiza o aviso e o texto do botão sem recriar a janela.
     */
    static UpdateMirrorStatus(enabled)
    {
        if !this.MirrorStatusText || !this.MirrorToggleButton
            return

        if enabled
        {
            this.MirrorStatusText.Text := "Status: ATIVADO"
            this.MirrorToggleButton.Text := "Desativar espelhamento"
        }
        else
        {
            this.MirrorStatusText.Text := "Status: DESATIVADO"
            this.MirrorToggleButton.Text := "Ativar espelhamento"
        }
    }

    /**
     * Monta o conteúdo inicial da janela.
     */
    static BuildHotkeyText(hotkeys)
    {
        text := "Cadastrar principal: " this.FormatHotkey(hotkeys.RegisterLeader)
        text .= "`nCadastrar mula: " this.FormatHotkey(hotkeys.RegisterMule)
        text .= "`nAlternar janela: " this.FormatHotkey(hotkeys.NextWindow)
        text .= "`nMostrar status: " this.FormatHotkey(hotkeys.ShowStatus)
        text .= "`nMontar PT: " this.FormatHotkey(hotkeys.BuildParty)
        text .= "`nRemontar PT: " this.FormatHotkey(hotkeys.RebuildParty)
        text .= "`nEspelhamento: " this.FormatHotkey(hotkeys.ToggleMirror)
        text .= "`nLimpar cadastros: " this.FormatHotkey(hotkeys.ClearRegistrations)
        text .= "`nFechar controller: " this.FormatHotkey(hotkeys.ExitController)

        return text
    }

    static FormatHotkey(hotkey)
    {
        hk := Trim(hotkey)

        if hk = ""
            return "Não configurado"

        ; Modificadores
        hk := StrReplace(hk, "^", "Ctrl + ")
        hk := StrReplace(hk, "!", "Alt + ")
        hk := StrReplace(hk, "+", "Shift + ")
        hk := StrReplace(hk, "#", "Win + ")

        ; Mouse
        hk := StrReplace(hk, "XButton1", "Botão lateral traseiro")
        hk := StrReplace(hk, "XButton2", "Botão lateral dianteiro")
        hk := StrReplace(hk, "MButton", "Botão do meio")
        hk := StrReplace(hk, "LButton", "Botão esquerdo")
        hk := StrReplace(hk, "RButton", "Botão direito")
        hk := StrReplace(hk, "WheelUp", "Roda ↑")
        hk := StrReplace(hk, "WheelDown", "Roda ↓")

        ; Teclas especiais
        hk := StrReplace(hk, "SC029", "'")
        hk := StrReplace(hk, "Esc", "Escape")
        hk := StrReplace(hk, "Del", "Delete")
        hk := StrReplace(hk, "PgUp", "Page Up")
        hk := StrReplace(hk, "PgDn", "Page Down")

        return hk
    }
}
