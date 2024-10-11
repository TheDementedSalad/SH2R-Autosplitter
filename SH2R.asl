state("SHProto-Win64-Shipping"){}
state("SHProto-WinGDK-Shipping"){}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
	vars.Helper.Settings.CreateFromXml("Components/SH2R.Settings.xml");
	vars.Helper.GameName = "Silent Hill 2 Remake (2024)";
	
	vars.completedSplits = new HashSet<string>();
	vars.Inventory = new Dictionary<ulong, int>();
	vars.totalGameTime = 0;
}

init
{
	IntPtr gEngine = vars.Helper.ScanRel(3, "48 89 05 ???????? 48 85 c9 74 ?? e8 ???????? 48 8d 4d");
	IntPtr fNames = vars.Helper.ScanRel(3, "48 8d 05 ?? ?? ?? ?? eb ?? 85 d2");
	
	// gEngine.TransitionType
	vars.Helper["Pause"] = vars.Helper.Make<bool>(gEngine, 0xADA);
	
	// gEngine.TransitionDescription
	vars.Helper["Transition"] = vars.Helper.MakeString(gEngine, 0xAE0, 0x0);
	
	// gEngine.ViewPort.World.AuthorityGameMode.MenuController.StateWidgets[0].FName
	vars.Helper["PauseWidget"] = vars.Helper.Make<ulong>(gEngine, 0x9A0, 0x78, 0x150, 0x358, 0xE8, 0x40, 0x18);
	vars.Helper["PauseWidget"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	
	// gEngine.ViewPort.World.AuthorityGameMode.MenuController.StateWidgets[1].HintText_lbl.Visibility
	vars.Helper["LoadVisible"] = vars.Helper.Make<float>(gEngine, 0x9A0, 0x78, 0x150, 0x358, 0xE8, 0x90, 0x300, 0xE8);
	vars.Helper["LoadVisible"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	
	// gEngine.GameInstance.bDeathReload[1]
	vars.Helper["DeathLoad"] = vars.Helper.Make<bool>(gEngine, 0x1070, 0x2B0);
	
	// gEngine.GameInstance.LocalPlayers[0].PlayerController.FName
	vars.Helper["localPlayer"] = vars.Helper.Make<ulong>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x18);
	vars.Helper["localPlayer"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	
	// gEngine.GameInstance.LocalPlayers[0].PlayerController.AcknowledgedPawn.FName
	vars.Helper["AcknowledgedPawn"] = vars.Helper.Make<ulong>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x18);
	vars.Helper["AcknowledgedPawn"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	
	// gEngine.GameInstance.LocalPlayers[0].PlayerController.AcknowledgedPawn.Items.CollectedItems.NumElements 
	vars.Helper["Items"] = vars.Helper.Make<IntPtr>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x6C0, 0x110 + 0x0);
	
	// gEngine.GameInstance.LocalPlayers[0].PlayerController.AcknowledgedPawn.Items.CollectedItems.ArraySize
	vars.Helper["ItemCount"] = vars.Helper.Make<uint>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x6C0, 0x110 + 0x8);
	
	// gEngine.GameInstance.LocalPlayers[0].PlayerController.AcknowledgedPawn.UIComponent.GameplayMenuWidget.CurrentCastedWidget.FName
	vars.Helper["CurrentWidget"] = vars.Helper.Make<ulong>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x6F0, 0x100, 0x2D8, 0x18);
	
	// gEngine.GameInstance.LocalPlayers[0].PlayerController.AcknowledgedPawn.UIComponent.GameplaySaveMenuWidget.ActualSavePoint.FName
	vars.Helper["Saving"] = vars.Helper.Make<ulong>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x6F0, 0x128, 0x318, 0x18);
	vars.Helper["Saving"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	
	// gEngine.GameInstance.LocalPlayers[0].PlayerController.AcknowledgedPawn.UIComponent.GameplaySaveMenuWidget.ActualSavePoint.FName
	vars.Helper["GameOver"] = vars.Helper.Make<ulong>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x6F0, 0x118, 0x18);
	
	// gEngine.GameInstance.LocalPlayers[0].PlayerController.AcknowledgedPawn.UIComponent.GameplaySaveMenuWidget.ActualSavePoint.FName
	vars.Helper["End"] = vars.Helper.Make<ulong>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x6F0, 0x120, 0x18);
	vars.Helper["End"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	
	vars.Helper["Ending"] = vars.Helper.Make<byte>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x740, 0xC0);
	
	vars.Helper["CutsceneName"] = vars.Helper.Make<ulong>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x6F0, 0x140, 0x318, 0x18, 0x2B0, 0x2E0, 0x4C8);
	vars.Helper["CutsceneName"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	
	vars.Helper["CutscenePlaying"] = vars.Helper.Make<bool>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x6F0, 0x140, 0x318, 0x18, 0x2B0, 0x2E0, 0x280);
	vars.Helper["CutscenePlaying"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	
	vars.Helper["CutsceneDuration"] = vars.Helper.Make<int>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x6F0, 0x140, 0x318, 0x18, 0x2B0, 0x2E0, 0x294);
	vars.Helper["CutsceneDuration"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	
	vars.FNameToString = (Func<ulong, string>)(fName =>
	{
		var nameIdx  = (fName & 0x000000000000FFFF) >> 0x00;
		var chunkIdx = (fName & 0x00000000FFFF0000) >> 0x10;
		var number   = (fName & 0xFFFFFFFF00000000) >> 0x20;

		IntPtr chunk = vars.Helper.Read<IntPtr>(fNames + 0x10 + (int)chunkIdx * 0x8);
		IntPtr entry = chunk + (int)nameIdx * sizeof(short);

		int length = vars.Helper.Read<short>(entry) >> 6;
		string name = vars.Helper.ReadString(length, ReadStringType.UTF8, entry + sizeof(short));

		return number == 0 ? name : name + "_" + number;
	});
	
	vars.FNameToShortString = (Func<ulong, string>)(fName =>
	{
		string name = vars.FNameToString(fName);

		int dot = name.LastIndexOf('.');
		int slash = name.LastIndexOf('/');

		return name.Substring(Math.Max(dot, slash) + 1);
	});
	
	vars.FNameToShortString2 = (Func<ulong, string>)(fName =>
	{
		string name = vars.FNameToString(fName);

		int under = name.LastIndexOf('_');

		return name.Substring(0, under + 1);
	});
}

update
{
	//print(modules.First().ModuleMemorySize.ToString());
	
	vars.Helper.Update();
	vars.Helper.MapPointers();
	
	//print(vars.FNameToShortString2(current.LoadWidget));
}

onStart
{
	vars.completedSplits.Clear();
	vars.totalGameTime = 0;
	vars.Inventory.Clear();
	
	// This makes sure the timer always starts at 0.00
	timer.IsGameTimePaused = true;
}

start
{
	if(vars.FNameToShortString(old.CutsceneName) == "Lv_ObservationDeck_01_Cine" && vars.FNameToShortString(current.CutsceneName) != "Lv_ObservationDeck_01_Cine"){
		return true;
	}
}

split
{  
	const string ItemFormat = "[{0}] {1} ({2})";
	string setting = "";
	
	// Item splits.
	if(vars.FNameToShortString2(current.AcknowledgedPawn) == "SHCharacterPlay_BP_C_"){ 
		for (int i = 0; i < current.ItemCount; i++)
		{

			ulong item = vars.Helper.Read<ulong>(current.Items + 0xC * i);
			int amount = vars.Helper.Read<int>(current.Items + 0x8 + 0xC * i);

			int oldAmount;
			if (vars.Inventory.TryGetValue(item, out oldAmount))
			{
				if (oldAmount < amount)
				{
					setting = string.Format(ItemFormat, '+', vars.FNameToShortString(item), amount);
				}
				else if (oldAmount > amount)
				{
					setting = string.Format(ItemFormat, '-', vars.FNameToShortString(item), amount);
				}
			}
			else
			{
				setting = string.Format(ItemFormat, '+', vars.FNameToShortString(item), '!');
			}

			vars.Inventory[item] = amount;
			
			// Debug. Comment out before release.
			//if (!string.IsNullOrEmpty(setting))
			//vars.Log(setting);
		}
	}
	
	if(current.CutsceneName != 0 && old.CutsceneName == 0){
		setting = vars.FNameToShortString(current.CutsceneName) + "_" + current.CutsceneDuration;
	}
	
	if(vars.FNameToShortString2(current.End) == "GameplayEndGame_WidgetBP_C_" && vars.FNameToShortString2(old.End) != "GameplayEndGame_WidgetBP_C_"){
		return true;
	}
	
	// Debug. Comment out before release.
	if (!string.IsNullOrEmpty(setting))
	vars.Log(setting);

	if (settings.ContainsKey(setting) && settings[setting]
		&& vars.completedSplits.Add(setting))
	{
		return true;
	}
}

isLoading
{
	return vars.FNameToShortString2(current.Saving) == "SavePoint_Wall_BP_C_" || vars.FNameToShortString2(current.GameOver) == "GameplayGameOver_Widget_C_" || 
			current.Transition == "/Game/Game/Maps/Main_Mennu/Main_Menu" || current.DeathLoad || current.CutscenePlaying || current.LoadVisible == 1 ||
			vars.FNameToShortString2(current.PauseWidget) == "InGameMenuWidget_BP_C_" ||vars.FNameToShortString2(current.localPlayer) != "SHPlayerControllerPlay_BP_C_";
	//return true;
}

reset
{
	if(vars.FNameToShortString(current.CutsceneName) == "Lv_ObservationDeck_01_Cine" && vars.FNameToShortString(old.CutsceneName) != "Lv_ObservationDeck_01_Cine"){
		return true;
	}
}

exit
{
	//pauses timer if the game crashes
	timer.IsGameTimePaused = true;
}
