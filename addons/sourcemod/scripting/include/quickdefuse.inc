#if defined _quickdefuse_included_
	#endinput
#endif

#define _quickdefuse_included_
#define ONLY_HUMMANS true

#include <sdktools>
#include <multicolors>

EngineVersion gameEngine = Engine_Unknown;

int bombent = 0;
int selectedWire = 0;

char wirecolours[4][16] = {"blue", "yellow", "red", "green"};

ConVar sm_quickdefuse = null;
ConVar sm_quickdefuse_debug = null;
ConVar sm_quickdefuse_terrorist_select = null;
ConVar sm_quickdefuse_select_notification = null;
ConVar sm_quickdefuse_panel_draw_time = null;

Handle forward_on_player_defuse = INVALID_HANDLE;
Handle forward_on_player_detonate = INVALID_HANDLE;

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

stock bool IsBot(int client)
{
	return (IsValidPlayer(client, !ONLY_HUMMANS) && IsFakeClient(client));
}

stock bool IsCSGO()
{
	return gameEngine == Engine_CSGO;
}

stock void DetonateC4()
{
	SetEntPropFloat(bombent, Prop_Send, "m_flC4Blow", 1.0);
}

stock void DefuseC4()
{
	SetEntPropFloat(bombent, Prop_Send, "m_flDefuseCountDown", 1.0);
}

stock bool IsInSelectableRange(int param)
{
	return (param > 0 && param < 5);
}

stock void ForwardPlayerDefuseC4(int client)
{
	if(!IsValidPlayer(client, ONLY_HUMMANS) || !IsValidHandler(forward_on_player_defuse))
		return;

	if(sm_quickdefuse_debug.BoolValue)
	{
		PrintToServer("[Quick Defuse] Debug | Player '%N' use wire for quick defuse!", client);
	}

	Call_StartForward(forward_on_player_defuse);

	Call_PushCell(client);

	Call_Finish();
}

stock void ForwardPlayerDetoneteC4(int client)
{
	if(!IsValidPlayer(client, ONLY_HUMMANS) || !IsValidHandler(forward_on_player_detonate))
		return;

	if(sm_quickdefuse_debug.BoolValue)
	{
		PrintToServer("[Quick Defuse] Debug | Player '%N' use wire for quick defuse and C4 detonate!", client);
	}

	Call_StartForward(forward_on_player_detonate);

	Call_PushCell(client);

	Call_Finish();
}

stock void OnBombActionInterupted(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientFromEvent(event);

	if(!IsValidPlayer(client, ONLY_HUMMANS))
		return;

	CancelClientMenu(client);
}

stock void NotifyPlayerSelection(int client, int wire)
{
	char color[16];
	TranslateColor(wirecolours[wire-1], color);

	CPrintToChat(client, "%t", "sm_qd_panel_plant", wirecolours[wire-1], color);
}

stock void TranslateColor(const char[] color, char translation[16])
{
	if(StrEqual(color, "blue", false))
	{
		Format(translation, sizeof(translation), "%t", "sm_qd_wire_blue");

		return;
	}

	if(StrEqual(color, "yellow", false))
	{
		Format(translation, sizeof(translation), "%t", "sm_qd_wire_yellow");

		return;
	}

	if(StrEqual(color, "red", false))
	{
		Format(translation, sizeof(translation), "%t", "sm_qd_wire_red");

		return;
	}

	if(StrEqual(color, "green", false))
	{
		Format(translation, sizeof(translation), "%t", "sm_qd_wire_green");

		return;
	}
}

///////////////
/// Forwards

/// Called on player defuse c4
forward void OnPlayerDefuseC4(int client);

/// Called on player try to defuse, but c4 detonated
forward void OnPlayerDetonateC4(int client);
