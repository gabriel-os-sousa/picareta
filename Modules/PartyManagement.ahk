class PartyManagement
{
    /**
     * Expulsa um integrante da PT.
     *
     * 1. Seleciona o integrante.
     * 2. Aguarda a seleção.
     * 3. Clica em Expulsar.
     * 4. Aguarda o jogo processar a expulsão.
     */
    static KickMember(
        leaderHwnd,
        memberX,
        memberY,
        kickX,
        kickY,
        selectDelay := 200,
        kickDelay := 300
    )
    {
        if !PWWindows.IsOpen(leaderHwnd)
            throw Error("A janela do líder não está aberta.")

        PWWindows.BackgroundLeftClick(
            leaderHwnd,
            memberX,
            memberY
        )

        if selectDelay > 0
            Sleep selectDelay

        PWWindows.BackgroundLeftClick(
            leaderHwnd,
            kickX,
            kickY
        )

        if kickDelay > 0
            Sleep kickDelay
    }

    /**
     * Transfere a liderança para outro integrante.
     *
     * 1. Seleciona o integrante.
     * 2. Aguarda a seleção.
     * 3. Clica em Transferir liderança.
     * 4. Aguarda o jogo processar a transferência.
     */
    static TransferLeader(
        leaderHwnd,
        memberX,
        memberY,
        transferX,
        transferY,
        selectDelay := 200,
        transferDelay := 500
    )
    {
        if !PWWindows.IsOpen(leaderHwnd)
            throw Error("A janela do líder não está aberta.")

        PWWindows.BackgroundLeftClick(
            leaderHwnd,
            memberX,
            memberY
        )

        if selectDelay > 0
            Sleep selectDelay

        PWWindows.BackgroundLeftClick(
            leaderHwnd,
            transferX,
            transferY
        )

        if transferDelay > 0
            Sleep transferDelay
    }

    /**
     * Faz o personagem principal sair da PT
     * e confirma a saída pressionando Y.
     */
    static LeaveParty(
        leaderHwnd,
        leaveX,
        leaveY,
        leaveDelay := 300
    )
    {
        if !PWWindows.IsOpen(leaderHwnd)
        {
            throw Error(
                "A janela do personagem principal não está aberta."
            )
        }

        BlockInput "MouseMove"

        try
        {
            PWWindows.BackgroundLeftClick(
                leaderHwnd,
                leaveX,
                leaveY
            )

            if leaveDelay > 0
                Sleep leaveDelay

            ;Descomentar para enviar aceite automatico para sair da PT
            ;PWWindows.SendKey(leaderHwnd, "{y}", 200)
        }
        finally
        {
            BlockInput "MouseMoveOff"
        }
    }
}