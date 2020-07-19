#if defined _tf2_items_included
  #endinput
#endif
#define _tf2_items_included

//Defines
#define MAX_ITEM_NAME_LENGTH 32
#define MAX_DESCRIPTION_LENGTH 64
#define MAX_ATTRIBUTE_NAME_LENGTH 64
#define MAX_ATTRIBUTE_DISPLAY_LENGTH 64

//Typedefs
typedef RegisterAttribute_OnAction = function void (int client, int item, const char[] attrib, const char[] action, StringMap attributedata);

//Natives
native bool TF2Items_AllowAttributeRegisters();
native bool TF2Items_RegisterAttribute(const char[] attrib, RegisterAttribute_OnAction onaction);

native int TF2Items_GiveItem(int client, const char[] name, bool message = false);
native bool TF2Items_IsItemCustom(int item);

native void TF2Items_RefillMag(int item);
native void TF2Items_RefillAmmo(int client, int item);

native int TF2Items_EquipWearable(int client, const char[] classname, int index, int level = 1, int quality = 1);
native int TF2Items_EquipViewmodel(int client, char[] model = "");

native int TF2Items_GetItemKeyInt(const char[] item, const char[] key);
native float TF2Items_GetItemKeyFloat(const char[] item, const char[] key);
native bool TF2Items_GetItemKeyString(const char[] item, const char[] key, char[] buffer, int size);

//Forwards
forward Action TF2Items_OnRegisterAttributes();
forward void TF2Items_OnRegisterAttributesPost();

forward Action TF2Items_OnRegisterItemConfig(const char[] name, const char[] file, KeyValues settings);
forward void TF2Items_OnRegisterItemConfigPost(const char[] name, const char[] file, KeyValues settings);

forward Action TF2Items_OnRegisterItemSetting(const char[] name, const char[] key, any value);
forward Action TF2Items_OnRegisterItemSettingStr(const char[] name, const char[] key, const char[] value);

#if !defined REQUIRE_PLUGIN
public void __pl_tf2_items_SetNTVOptional()
{
	MarkNativeAsOptional("TF2Items_AllowAttributeRegisters");
	MarkNativeAsOptional("TF2Items_RegisterAttribute");
	
	MarkNativeAsOptional("TF2Items_GiveItem");
	MarkNativeAsOptional("TF2Items_IsItemCustom");
	
	MarkNativeAsOptional("TF2Items_RefillMag");
	MarkNativeAsOptional("TF2Items_RefillAmmo");
	
	MarkNativeAsOptional("TF2Items_EquipWearable");
	MarkNativeAsOptional("TF2Items_EquipViewmodel");
	
	MarkNativeAsOptional("TF2Items_GetItemKeyInt");
	MarkNativeAsOptional("TF2Items_GetItemKeyFloat");
	MarkNativeAsOptional("TF2Items_GetItemKeyString");
}
#endif

public SharedPlugin __pl_tf2_items =
{
	name = "tf2-items",
	file = "tf2-items.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};
