/*****************************/
//Pragma
#pragma semicolon 1
#pragma newdecls required

/*****************************/
//Defines
#define PLUGIN_NAME "[TF2] Interactive Mann vs Machine"
#define PLUGIN_DESCRIPTION "An interactive experience for Mann vs Machine which allows a player to control the AI and their spawns."
#define PLUGIN_VERSION "1.0.0"

#define HIDEHUD_WEAPONSELECTION ( 1<<0 ) // Hide ammo count & weapon selection
#define HIDEHUD_FLASHLIGHT ( 1<<1 )
#define HIDEHUD_ALL ( 1<<2 )
#define HIDEHUD_HEALTH ( 1<<3 ) // Hide health & armor / suit battery
#define HIDEHUD_PLAYERDEAD ( 1<<4 ) // Hide when local player's dead
#define HIDEHUD_NEEDSUIT ( 1<<5 ) // Hide when the local player doesn't have the HEV suit
#define HIDEHUD_MISCSTATUS ( 1<<6 ) // Hide miscellaneous status elements (trains, pickup history, death notices, etc)
#define HIDEHUD_CHAT ( 1<<7 ) // Hide all communication elements (saytext, voice icon, etc)
#define HIDEHUD_CROSSHAIR ( 1<<8 ) // Hide crosshairs
#define HIDEHUD_VEHICLE_CROSSHAIR ( 1<<9 ) // Hide vehicle crosshair
#define HIDEHUD_INVEHICLE ( 1<<10 )
#define HIDEHUD_BONUS_PROGRESS ( 1<<11 ) // Hide bonus progress display (for bonus map challenges)

#define EF_NODRAW 0x020

/*****************************/
//Includes
#include <sourcemod>
#include <tf2_stocks>

/*****************************/
//ConVars

/*****************************/
//Globals

int g_BeamSprite = -1;
int g_HaloSprite = -1;
int g_GlowSprite = -1;

enum struct Controller
{
	int client;

	void Init()
	{
		this.client = -1;
	}

	void SetController(int client, int admin = -1)
	{
		if (this.client != -1)
			this.ClearController();
		
		char sBy[128];
		if (admin != -1)
			FormatEx(sBy, sizeof(sBy), " by %N", admin);
		
		this.client = client;
		PrintToChatAll("%N is now the designated MvM controller%s.", client, sBy);

		SetEntityMoveType(client, MOVETYPE_NOCLIP);
		SetEntityRenderMode(client, RENDER_NONE);
		
		TF2_RemoveAllWeapons(client);
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);

		SetEntProp(client, Prop_Send, "m_iHideHUD", HIDEHUD_WEAPONSELECTION);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
	}

	bool ClearController()
	{
		if (this.client == -1)
			return false;
		
		SetEntityMoveType(this.client, MOVETYPE_ISOMETRIC);
		SetEntityRenderMode(this.client, RENDER_NORMAL);
		
		TF2_RespawnPlayer(this.client);
		SetEntProp(this.client, Prop_Data, "m_takedamage", 2, 1);

		SetEntProp(this.client, Prop_Send, "m_iHideHUD", 0);
		SetEntProp(this.client, Prop_Send, "m_bDrawViewmodel", 1);

		this.client = -1;
		return true;
	}

	bool IsController(int client)
	{
		return this.client == client;
	}

	bool IsActive()
	{
		return this.client != -1;
	}
}

Controller g_Controller;

enum struct Queue
{
	ArrayList waiting;

	void Init()
	{
		delete this.waiting;
		this.waiting = new ArrayList();
	}

	bool AddToQueue(int client)
	{
		if (this.waiting.FindValue(client) != -1)
			return false;
		
		this.waiting.Push(client);
		return true;
	}

	bool RemoveFromQueue(int client)
	{
		int index = this.waiting.FindValue(client);

		if (this.waiting.FindValue(client) == -1)
			return false;
		
		this.waiting.Erase(index);
		return true;
	}

	void ClearQueue()
	{
		this.waiting.Clear();
	}

	int GetCurrent(int client)
	{
		return this.waiting.FindValue(client);
	}

	int GetTotal()
	{
		return this.waiting.Length;
	}

	int GetLowest()
	{
		int client = this.waiting.Get(0);
		this.waiting.Erase(0);
		return client;
	}
}

Queue g_Queue;

/*****************************/
//Plugin Info
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = "Drixevel", 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	g_Controller.Init();
	g_Queue.Init();

	RegConsoleCmd("sm_control", Command_Control);
	RegConsoleCmd("sm_clear", Command_Clear);

	CreateTimer(1.0, Timer_QueueLogic, _, TIMER_REPEAT);
}

public void OnPluginEnd()
{
	if (g_Controller.IsActive())
		g_Controller.ClearController();
}

public void OnMapStart()
{
	g_BeamSprite = PrecacheModel("sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("sprites/halo01.vmt");
	g_GlowSprite = PrecacheModel("sprites/blueglow2.vmt");
}

public Action Command_Control(int client, int args)
{
	if (!CheckCommandAccess(client, "", ADMFLAG_GENERIC, true))
	{
		if (g_Queue.AddToQueue(client))
			PrintToChat(client, "You have been added to the controller queue! [%i/%i]", g_Queue.GetCurrent(client), g_Queue.GetTotal());
		else
			PrintToChat(client, "You are already queued to be a controller!");
		
		return Plugin_Handled;
	}

	if (g_Controller.IsActive())
	{
		PrintToChat(client, "A controller is already designated, please clear it.");
		return Plugin_Handled;
	}

	if (args == 0)
	{
		g_Controller.SetController(client);
		return Plugin_Handled;
	}

	char sTarget[MAX_TARGET_LENGTH];
	GetCmdArgString(sTarget, sizeof(sTarget));

	int target = FindTarget(client, sTarget, true, false);

	if (target == -1)
	{
		PrintToChat(client, "Target not found, please be more specific.");
		return Plugin_Handled;
	}

	g_Controller.SetController(target, client);

	return Plugin_Handled;
}

public Action Command_Clear(int client, int args)
{
	if (g_Controller.IsController(client))
	{
		g_Controller.ClearController();
		PrintToChatAll("%N has disbanded his control.", client);
		return Plugin_Handled;
	}

	if (!CheckCommandAccess(client, "", ADMFLAG_GENERIC, true))
	{
		PrintToChat(client, "You are not allowed to use this command.");
		return Plugin_Handled;
	}

	if (!g_Controller.IsActive())
	{
		PrintToChat(client, "No controller is currently active.");
		return Plugin_Handled;
	}

	PrintToChatAll("%N has cleared control from %N.", client, g_Controller.client);
	g_Controller.ClearController();

	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
	if (g_Controller.IsController(client))
	{
		PrintToChatAll("%N has disconnected as the controller, searching for a new one...", client);
		g_Controller.ClearController();
	}
}

public Action Timer_QueueLogic(Handle timer)
{
	if (g_Queue.GetTotal() < 1 || g_Controller.IsActive())
		return Plugin_Continue;
	
	int client = g_Queue.GetLowest();
	g_Controller.SetController(client);

	for (int i = 0; i < g_Queue.waiting.Length; i++)
	{
		client = g_Queue.waiting.Get(i);
		PrintToChat(client, "You are now %i out of %i in line!", g_Queue.GetCurrent(client), g_Queue.GetTotal());
	}

	return Plugin_Continue;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if (!g_Controller.IsController(client))
		return Plugin_Continue;
	
	float look[3];
	if (!GetClientLookOrigin(client, look, true, 35.0))
		return Plugin_Continue;
	
	CreatePointGlow(look);
	
	int entity = -1; float origin[3]; int color[4];
	while ((entity = FindEntityByClassname(entity, "prop_dynamic")) != -1)
	{
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
		
		char sModel[PLATFORM_MAX_PATH];
		GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));

		if (!StrEqual(sModel, "models/props_mvm/robot_hologram.mdl", false))
			continue;
		
		if (GetVectorDistance(look, origin) <= 250.0)
		{
			color[0] = 0;
			color[1] = 255;
			color[2] = 0;
			color[3] = 255;
		}
		else if (GetEntProp(entity, Prop_Send, "m_fEffects") & EF_NODRAW)
		{
			color[0] = 255;
			color[1] = 0;
			color[2] = 0;
			color[3] = 255;
		}
		else
		{
			color[0] = 255;
			color[1] = 255;
			color[2] = 255;
			color[3] = 255;
		}
		
		origin[2] += 50.0;
		TE_SetupBeamRingPoint(origin, 50.0, 80.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, color, 10, 0);
		TE_SendToAll();
	}
	
	return Plugin_Continue;
}

bool GetClientLookOrigin(int client, float pOrigin[3], bool filter_players = true, float distance = 35.0)
{
	if (client == 0 || client > MaxClients || !IsClientInGame(client))
		return false;

	float vOrigin[3];
	GetClientEyePosition(client,vOrigin);

	float vAngles[3];
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, filter_players ? TraceEntityFilterPlayer : TraceEntityFilterNone, client);
	bool bReturn = TR_DidHit(trace);

	if (bReturn)
	{
		float vStart[3];
		TR_GetEndPosition(vStart, trace);

		float vBuffer[3];
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);

		pOrigin[0] = vStart[0] + (vBuffer[0] * -distance);
		pOrigin[1] = vStart[1] + (vBuffer[1] * -distance);
		pOrigin[2] = vStart[2] + (vBuffer[2] * -distance);
	}

	delete trace;
	return bReturn;
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask, any data)
{
	return entity > MaxClients || !entity;
}

public bool TraceEntityFilterNone(int entity, int contentsMask, any data)
{
	return entity != data;
}

void CreatePointGlow(float origin[3])
{
	TE_SetupGlowSprite(origin, g_GlowSprite, 0.95, 1.5, 50);
	TE_SendToAll();
}