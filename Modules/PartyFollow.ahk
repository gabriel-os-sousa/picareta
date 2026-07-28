#Requires AutoHotkey v2.0

#Include Windows.ahk

/**
 * Executa uma sequência configurável de ações nas mulas.
 */
class PartyFollow
{
    /**
     * Valida toda a sequência antes de enviar qualquer comando.
     * Isso evita uma execução parcial por configuração inválida.
     */
    static PrepareActions(actions, mules)
    {
        if mules.Length = 0
            throw Error("Nenhuma mula foi cadastrada.")

        enabledActions := []

        for index, action in actions
        {
            if !action.Enabled
                continue

            slot := Integer(action.MuleSlot)

            if slot < 1 || slot > mules.Length
            {
                throw Error(
                    "A ação " index " aponta para a Mula " slot
                    . ", mas ela não está cadastrada nesta sessão."
                )
            }

            mule := mules[slot]

            if !PWWindows.IsOpen(mule.Hwnd)
            {
                throw Error(
                    "A janela de " mule.Name " não está mais aberta."
                )
            }

            actionType := StrLower(Trim(action.Type))

            if actionType != "click" && actionType != "key"
                throw Error("Tipo inválido na ação " index ".")

            if actionType = "click"
            {
                button := StrLower(Trim(action.Button))

                if button != "left" && button != "right"
                    throw Error("Botão de mouse inválido na ação " index ".")

                if !IsNumber(action.X) || !IsNumber(action.Y)
                    throw Error("Coordenadas inválidas na ação " index ".")
            }
            else if Trim(action.Key) = ""
            {
                throw Error("A tecla da ação " index " está vazia.")
            }

            delay := IsNumber(action.Delay)
                ? Max(0, Integer(action.Delay))
                : 0

            enabledActions.Push({
                Index: index,
                MuleSlot: slot,
                MuleName: mule.Name,
                Hwnd: mule.Hwnd,
                Type: actionType,
                Button: StrLower(Trim(action.Button)),
                X: IsNumber(action.X) ? Integer(action.X) : 0,
                Y: IsNumber(action.Y) ? Integer(action.Y) : 0,
                Key: Trim(action.Key),
                Delay: delay
            })
        }

        if enabledActions.Length = 0
            throw Error("Nenhuma ação ativa foi configurada.")

        return enabledActions
    }

    static ExecuteAction(action)
    {
        if action.Type = "click"
        {
            if action.Button = "right"
            {
                PWWindows.BackgroundRightClick(
                    action.Hwnd,
                    action.X,
                    action.Y,
                    0
                )
            }
            else
            {
                PWWindows.BackgroundLeftClick(
                    action.Hwnd,
                    action.X,
                    action.Y,
                    0
                )
            }
        }
        else
        {
            PWWindows.SendKey(
                action.Hwnd,
                action.Key,
                0
            )
        }

        if action.Delay > 0
            Sleep(action.Delay)

        return true
    }

    /**
     * Compatibilidade com a configuração antiga de coordenadas fixas.
     */
    static BuildLegacyActions(mules, menuX, menuY, followX, followY, menuDelay, muleDelay)
    {
        actions := []

        for index, mule in mules
        {
            actions.Push({
                Enabled: true,
                MuleSlot: index,
                Type: "Click",
                Button: "Right",
                X: menuX,
                Y: menuY,
                Key: "",
                Delay: menuDelay
            })

            actions.Push({
                Enabled: true,
                MuleSlot: index,
                Type: "Click",
                Button: "Left",
                X: followX,
                Y: followY,
                Key: "",
                Delay: muleDelay
            })
        }

        return actions
    }
}
