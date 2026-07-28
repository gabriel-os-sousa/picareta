#Requires AutoHotkey v2.0

#Include Windows.ahk

/**
 * Captura uma coordenada da área cliente de uma janela cadastrada.
 *
 * O clique continua chegando ao jogo, mas não é espelhado enquanto
 * a captura estiver ativa. Escape cancela a operação.
 */
class CoordinateCapture
{
    static Active := false
    static TargetHwnd := 0
    static CaptureCallback := false
    static CancelCallback := false
    static PollCallback := false
    static WasLeftDown := false
    static WasEscapeDown := false

    static Start(targetHwnd, captureCallback, cancelCallback := false)
    {
        if this.Active
        {
            MsgBox(
                "Já existe uma captura de coordenadas em andamento.",
                "PW Controller"
            )
            return false
        }

        if !PWWindows.IsOpen(targetHwnd)
        {
            MsgBox(
                "A janela selecionada não está mais aberta.",
                "PW Controller"
            )
            return false
        }

        this.Active := true
        this.TargetHwnd := targetHwnd
        this.CaptureCallback := captureCallback
        this.CancelCallback := cancelCallback
        this.WasLeftDown := GetKeyState("LButton", "P")
        this.WasEscapeDown := GetKeyState("Esc", "P")
        this.PollCallback := (*) => CoordinateCapture.Poll()

        try
        {
            WinActivate("ahk_id " targetHwnd)
            WinWaitActive("ahk_id " targetHwnd, , 2)
        }
        catch
        {
            this.Stop()

            MsgBox(
                "Não foi possível ativar a janela selecionada.",
                "PW Controller"
            )
            return false
        }

        ToolTip(
            "CAPTURA DE COORDENADAS"
            . "`nClique no ponto desejado."
            . "`nPressione Esc para cancelar."
        )

        SetTimer(this.PollCallback, 20)
        return true
    }

    static Poll()
    {
        if !this.Active
            return

        escapeDown := GetKeyState("Esc", "P")

        if escapeDown && !this.WasEscapeDown
        {
            this.Cancel()
            return
        }

        this.WasEscapeDown := escapeDown
        leftDown := GetKeyState("LButton", "P")

        if leftDown && !this.WasLeftDown
        {
            this.CaptureCurrentPosition()
            return
        }

        this.WasLeftDown := leftDown
    }

    static CaptureCurrentPosition()
    {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&screenX, &screenY, &hoveredHwnd)
        CoordMode("Mouse", "Client")

        rootHwnd := hoveredHwnd

        if hoveredHwnd
        {
            candidate := DllCall(
                "GetAncestor",
                "Ptr", hoveredHwnd,
                "UInt", 2,
                "Ptr"
            )

            if candidate
                rootHwnd := candidate
        }

        if rootHwnd != this.TargetHwnd
        {
            ToolTip(
                "Clique dentro da janela selecionada."
                . "`nPressione Esc para cancelar."
            )
            return
        }

        point := Buffer(8, 0)
        NumPut("Int", screenX, point, 0)
        NumPut("Int", screenY, point, 4)

        if !DllCall(
            "ScreenToClient",
            "Ptr", this.TargetHwnd,
            "Ptr", point
        )
        {
            this.Cancel()
            return
        }

        clientX := NumGet(point, 0, "Int")
        clientY := NumGet(point, 4, "Int")
        callback := this.CaptureCallback

        this.Stop()

        if callback
            callback.Call(clientX, clientY)
    }

    static Cancel()
    {
        if !this.Active
            return

        callback := this.CancelCallback
        this.Stop()

        if callback
            callback.Call()
    }

    static Stop()
    {
        ToolTip()

        if this.PollCallback
            SetTimer(this.PollCallback, 0)

        this.Active := false
        this.TargetHwnd := 0
        this.CaptureCallback := false
        this.CancelCallback := false
        this.PollCallback := false
        this.WasLeftDown := false
        this.WasEscapeDown := false
    }

    static IsActive()
    {
        return this.Active
    }
}
