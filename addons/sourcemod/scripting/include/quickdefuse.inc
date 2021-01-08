#if defined _quickdefuse_included_
	#endinput
#endif

#define _quickdefuse_included_
#define ONLY_HUMMANS true

#include <sdktools>
#include <multicolors>

stock bool IsValidHandler(Handle handle)
{
	return (handle != INVALID_HANDLE);
}

stock int GetClientFromEvent(Handle event)
{
	return GetClientOfUserId(GetEventInt(event, "userid"));
}

stock bool IsClient(int client)
{
	// +1 is a SourceTV
	return (client > 0 && client < MaxClients + 1);
}

stock bool IsValidClient(int client)
{
	return (IsClient(client) && IsClientConnected(client) && IsClientInGame(client));
}

stock bool IsValidPlayer(int client, bool only_human)
{
	if(only_human)
	{
		return (IsValidClient(client) && !IsClientSourceTV(client) && !IsFakeClient(client));
	}
	
	return (IsValidClient(client) && !IsClientSourceTV(client));
}

///////////////
/// Forwards

/// Called on player defuse c4
forward void OnPlayerDefuseC4(int client);
