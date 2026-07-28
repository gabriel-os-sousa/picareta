#Requires AutoHotkey v2.0

#Include Windows.ahk

/**
 * Comandos relacionados a fazer as mulas seguirem o líder.
 */
class PartyFollow
{
    /**
     * Abre o menu de contexto na janela da mula e seleciona
     * a opção responsável por seguir o líder.
     */
    static FollowLeader(
        muleHwnd,
        menuX,
        menuY,
        followX,
        followY,
        menuDelay := 150
    )
    {
        if !PWWindows.IsOpen(muleHwnd)
            throw Error("A janela da mula não está aberta.")

        PWWindows.BackgroundRightClick(
            muleHwnd,
            menuX,
            menuY,
            0
        )

        if menuDelay > 0
            Sleep menuDelay

        PWWindows.BackgroundLeftClick(
            muleHwnd,
            followX,
            followY,
            0
        )

        return true
    }
}
