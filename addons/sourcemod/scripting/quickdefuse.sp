/*
 *		QuickDefuse - by pRED*
 *
 *		CT's get a menu to select a selectedWire to cut when they defuse the bomb
 *			- Choose the right selectedWire - Instant Defuse
 *			- Choose the wrong selectedWire - Instant Explosion
 *
 *		T's also get the option to select the correct selectedWire, otherwise it's random
 *
 *		Ignoring the menu's or selecting exit will let the game continue normally
 *		
 *		Refactored by Nerus
 */

#include <quickdefuse>

#pragma newdecls required

#define PLUGIN_NAME				"Quick Defuse"
#define PLUGIN_VERSION			"v2.0"
#define PLUGIN_DESCRIPTION		"Let's CT's choose a selectedWire for quick defusion."

int selectedWire = 0;

char wirecolours[4][16] = {"blue", "yellow", "red", "green"};

ConVar sm_quickdefuse = null;
ConVar sm_quickdefuse_debug = null;
ConVar sm_quickdefuse_terrorist_select = null;
ConVar sm_quickdefuse_select_notification = null;
ConVar sm_quickdefuse_panel_draw_time = null;

Handle forward_on_player_defuse = INVALID_HANDLE;

public Plugin myinfo = {
	name = PLUGIN_NAME,
	author = "pRED*, refactored by Nerus ",
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/"
};

public void SetConVars()
{
	/// Plugin ConVar's
	sm_quickdefuse = CreateConVar("sm_quickdefuse", "1", "Enable or disable plugin: '0' - disabled, '1' - enabled.");

	sm_quickdefuse_debug = CreateConVar("sm_quickdefuse_debug", "0", "Debug plugin: '0' - disabled, '1' - enabled.");

	sm_quickdefuse_terrorist_select = CreateConVar("sm_quickdefuse_terrorist_select", "1", "Enable or disable the ability to select wire by the terrorist: '0' - plugin random select, '1' - player select.");

	sm_quickdefuse_select_notification = CreateConVar("sm_quickdefuse_select_notification", "1", "Enable or disable player notification of wire selection : '0' - disabled, '1' - enabled.");

	sm_quickdefuse_panel_draw_time = CreateConVar("sm_quickdefuse_panel_draw_time", "5", "Draw panel to player in N seconds.");

	AutoExecConfig(true, "quickdefuse");
}

public void SetHooks()
{
	HookEvent("bomb_begindefuse", OnBombDefuse, EventHookMode_Post);
	HookEvent("bomb_beginplant", OnBombPlant, EventHookMode_Post);
	HookEvent("bomb_planted", OnBombPlanted, EventHookMode_Post);
	
	HookEvent("bomb_abortdefuse", OnBombActionInterupted, EventHookMode_Post);
	HookEvent("bomb_abortplant", OnBombActionInterupted, EventHookMode_Post);
}

public void SetTranslation()
{
	LoadTranslations("quickdefuse.phrases");
}

public void RegisterForwards()
{
	forward_on_player_defuse = CreateGlobalForward("OnPlayerDefuseC4", ET_Ignore, Param_Cell);
}

public void OnPluginStart()
{
	SetTranslation();

	SetConVars();

	SetHooks();

	RegisterForwards();
}

public void OnBombPlant(Event event, const char[] name, bool dontBroadcast)
{
	if(!sm_quickdefuse.BoolValue)
		return;

	selectedWire = 0;

	int client = GetClientFromEvent(event);

	if(!IsValidPlayer(client, !ONLY_HUMMANS))
		return;

	if(sm_quickdefuse_terrorist_select.BoolValue && !IsBot(client))
	{
		CreatePlantPanel(client);
	}
}

public void OnBombPlanted(Event event, const char[] name, bool dontBroadcast)
{
	if(!sm_quickdefuse.BoolValue)
		return;

	if (selectedWire == 0)
	{
		selectedWire = GetRandomInt(1, 4);

		int client = GetClientFromEvent(event);

		if(sm_quickdefuse_select_notification.BoolValue && !IsBot(client))
		{
			NotifyPlayerSelection(client, selectedWire);
		}
	}
}

public void OnBombDefuse(Event event, const char[] name, bool dontBroadcast)
{
	if(!sm_quickdefuse.BoolValue)
		return;

	CreateDefusePanel(GetClientFromEvent(event), GetEventBool(event, "haskit"));
}

public int PanelPlant(Menu menu, MenuAction action, int param1, int param2)
{
	if(!IsValidPlayer(param1, ONLY_HUMMANS) || action != MenuAction_Select || !IsInSelectableRange(param2))
		return 0;

	selectedWire = param2;

	if(sm_quickdefuse_select_notification.BoolValue && !IsBot(param1))
	{
		NotifyPlayerSelection(param1, param2);
	}

	return 0;
}

public int PanelDefuseKit(Menu menu, MenuAction action, int param1, int param2)
{
	if(!IsValidPlayer(param1, ONLY_HUMMANS) || action != MenuAction_Select || !IsInSelectableRange(param2))
		return 0;
	
	int bombent = FindEntityByClassname(-1, "planted_c4");
	
	if(!IsValidEntity(bombent))
		return 0;

	if (param2 == selectedWire)
	{
		ForwardPlayerDefuseC4(param1);
		
		SetEntPropFloat(bombent, Prop_Send, "m_flDefuseCountDown", 1.0);

		char color[16];
		TranslateColor(wirecolours[param2-1], color);

		CPrintToChatAll("%t", "sm_qd_panel_defuse", param1, wirecolours[param2-1], color);
	}
	else
	{
		SetEntPropFloat(bombent, Prop_Send, "m_flC4Blow", 1.0);

		char color[16];
		TranslateColor(wirecolours[param2-1], color);

		char color2[16];
		TranslateColor(wirecolours[selectedWire-1], color2);
		
		CPrintToChatAll("%t", "sm_qd_panel_defuse_incorrected", param1, wirecolours[param2-1], color, wirecolours[selectedWire-1], color2);
	}

	return 0;
}

public int PanelDefuseNoKit(Menu menu, MenuAction action, int param1, int param2)
{
	if (!IsValidPlayer(param1, ONLY_HUMMANS) || action != MenuAction_Select || !IsInSelectableRange(param2))
		return 0;

	int bombent = FindEntityByClassname(-1, "planted_c4");
	
	if(!IsValidEntity(bombent))
		return 0;

	if (param2 == selectedWire && GetRandomInt(0,1))
	{
		ForwardPlayerDefuseC4(param1);

		SetEntPropFloat(bombent, Prop_Send, "m_flDefuseCountDown", 1.0);

		char color[16];
		TranslateColor(wirecolours[param2-1], color);
		CPrintToChatAll("%t", "sm_qd_panel_defuse_nokit", param1, wirecolours[param2-1], color);
	}
	else
	{
		SetEntPropFloat(bombent, Prop_Send, "m_flC4Blow", 1.0);

		if (param2 != selectedWire)
		{
			char color[16];
			TranslateColor(wirecolours[param2-1], color);

			char color2[16];
			TranslateColor(wirecolours[selectedWire-1], color2);

			CPrintToChatAll("%t", "sm_qd_panel_defuse_nokit_incorrected", param1, wirecolours[param2-1], color, wirecolours[selectedWire-1], color2);
		}
		else
		{
			char color[16];
			TranslateColor(wirecolours[param2-1], color);
			CPrintToChatAll("%t", "sm_qd_panel_defuse_nokit_correct", param1, wirecolours[param2-1], color);
		}
	}

	return 0;
}

public void OnBombActionInterupted(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientFromEvent(event);

	if(!IsValidPlayer(client, ONLY_HUMMANS))
		return;

	CancelClientMenu(client);
}

public void CreatePlantPanel(int client)
{
	if(!IsValidPlayer(client, ONLY_HUMMANS))
		return;

	Panel panel = CreatePanel();

	char title[32];
	Format(title, sizeof(title), "%t", "sm_qd_plant_panel_title");
	panel.SetTitle(title);
	
	panel.DrawText(" ");
	
	char text[256];
	Format(text, sizeof(text), "%t", "sm_qd_plant_panel_info");
	panel.DrawText(text);

	Format(text, sizeof(text), "%t", "sm_qd_plant_panel_ignore");
	panel.DrawText(text);

	panel.DrawText(" ");

	char color[16];
	Format(color, sizeof(color), "%t", "sm_qd_wire_blue");
	panel.DrawItem(color);

	Format(color, sizeof(color), "%t", "sm_qd_wire_yellow");
	panel.DrawItem(color);

	Format(color, sizeof(color), "%t", "sm_qd_wire_red");
	panel.DrawItem(color);

	Format(color, sizeof(color), "%t", "sm_qd_wire_green");
	panel.DrawItem(color);

	panel.DrawText(" ");

	char exit_panel[16];
	Format(exit_panel, sizeof(exit_panel), "%t", "sm_qd_panel_exit");
	panel.DrawItem(exit_panel);

	SendPanelToClient(panel, client, PanelPlant, sm_quickdefuse_panel_draw_time.IntValue);

	CloseHandle(panel);
}

public void CreateDefusePanel(int client, bool haskit)
{
	if(!IsValidPlayer(client, ONLY_HUMMANS))
		return;

	Panel panel = CreatePanel();

	char title[32];
	Format(title, sizeof(title), "%t", "sm_qd_defuse_panel_title");
	panel.SetTitle(title);

	char text[256];
	Format(text, sizeof(text), "%t", "sm_qd_defuse_panel_ignore");
	panel.DrawText(text);

	panel.DrawText(" ");

	Format(text, sizeof(text), "%t", "sm_qd_defuse_panel_info");
	panel.DrawText(text);

	Format(text, sizeof(text), "%t", "sm_qd_defuse_panel_info2");
	panel.DrawText(text);

	if (!haskit)
	{
		Format(text, sizeof(text), "%t", "sm_qd_defuse_panel_nokit_info");
		panel.DrawText(text);
		
		Format(text, sizeof(text), "%t", "sm_qd_defuse_panel_nokit_info2");
		panel.DrawText(text);
	}

	panel.DrawText(" ");

	char color[16];
	Format(color, sizeof(color), "%t", "sm_qd_wire_blue");
	panel.DrawItem(color);

	Format(color, sizeof(color), "%t", "sm_qd_wire_yellow");
	panel.DrawItem(color);

	Format(color, sizeof(color), "%t", "sm_qd_wire_red");
	panel.DrawItem(color);

	Format(color, sizeof(color), "%t", "sm_qd_wire_green");
	panel.DrawItem(color);
	
	panel.DrawText(" ");
	
	char exit_panel[16];
	Format(exit_panel, sizeof(exit_panel), "%t", "sm_qd_panel_exit");
	panel.DrawItem(exit_panel);

	if (haskit)
		SendPanelToClient(panel, client, PanelDefuseKit, sm_quickdefuse_panel_draw_time.IntValue);
	else
		SendPanelToClient(panel, client, PanelDefuseNoKit, sm_quickdefuse_panel_draw_time.IntValue);

	CloseHandle(panel);
}

public bool IsInSelectableRange(int param)
{
	return (param > 0 && param < 5);
}

public void ForwardPlayerDefuseC4(int client)
{
	if(!IsValidPlayer(client, ONLY_HUMMANS) || !IsValidHandler(forward_on_player_defuse))
		return;

	if(sm_quickdefuse_debug.BoolValue)
		PrintToServer("[Quick Defuse] Debug | Player '%N' use wire for quick defuse!", client);

	Call_StartForward(forward_on_player_defuse);

	Call_PushCell(client);

	Call_Finish();
}

public void NotifyPlayerSelection(int client, int wire)
{
	char color[16];
	TranslateColor(wirecolours[wire-1], color);

	CPrintToChat(client, "%t", "sm_qd_panel_plant", wirecolours[wire-1], color);
}

public void TranslateColor(const char[] color, char translation[16])
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
