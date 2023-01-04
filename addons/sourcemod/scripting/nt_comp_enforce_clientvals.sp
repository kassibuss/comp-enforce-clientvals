#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

char g_sPluginTag[] = "[COMP CVARS]";

public Plugin myinfo = {
    name        = "NT Enforce Comp Values",
    author      = "Rain",
    description = "Enforce some client cvar values for competitive play.",
    version     = "0.1.0",
    url         = "https://github.com/Rainyan/sourcemod-nt-comp-enforce-clientvals"
};

// Names of the cvars, followed by the value that is enforced for them.
char g_enforcedVals[][][] = {
    { "r_shadowrendertotexture", "1" },  // Non-default values give possibly unfair forward-facing blob-shaped shadows.
};

public void OnPluginStart()
{
    CreateTimer(1.0, Timer_CheckEnforcedVals, _, TIMER_REPEAT);
}

public Action Timer_CheckEnforcedVals(Handle timer)
{
    for (int client = 1; client <= MaxClients; ++client)
    {
        if (!IsClientInGame(client))
        {
            continue;
        }

        for (int i = 0; i < sizeof(g_enforcedVals); ++i)
        {
            if (QueryClientConVar(client, g_enforcedVals[i][0], OnCvarQueryFinished, i) == QUERYCOOKIE_FAILED)
            {
                LogError("QueryClientConVar %s for client %d (%N) failed", g_enforcedVals[i][0], client, client);
            }
        }
    }

    return Plugin_Continue;
}

public void OnCvarQueryFinished(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue, int index)
{
    if (result != ConVarQuery_Okay || !IsClientInGame(client))
    {
        return;
    }

    if (!StrEqual(cvarValue, g_enforcedVals[index][1], false))
    {
        // Notify the server of why the player's getting kicked, and how to fix it.
        PrintToConsoleAll(
            "%s Player \"%N\" must reset their cvar \"%s\" value (\"%s\") to its default value: \"%s\"",
            g_sPluginTag,
            client,
            cvarName,
            cvarValue,
            g_enforcedVals[index][1]
        );

        // Kick & instruct the kickee to make the required change,
        // because we don't have a standard way of enforcing this value in client's stead.
        KickClient(
            client,
            "%s Please reset your cvar %s value (\"%s\") to its default value: %s",
            g_sPluginTag,
            cvarName,
            cvarValue,
            g_enforcedVals[index][1]
        );
    }
}

// Backported from SourceMod/SourcePawn SDK for SM < 1.9 compatibility.
// Used here under GPLv3 license: https://www.sourcemod.net/license.php
// SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
#if SOURCEMOD_V_MAJOR <= 1 && SOURCEMOD_V_MINOR < 9
/**
 * Sends a message to every client's console.
 *
 * @param format        Formatting rules.
 * @param ...           Variable number of format parameters.
 */
stock void PrintToConsoleAll(const char[] format, any ...)
{
    char buffer[254];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            PrintToConsole(i, "%s", buffer);
        }
    }
}
#endif