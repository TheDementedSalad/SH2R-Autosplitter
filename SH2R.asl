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
	
	vars.Helper["Pause"] = vars.Helper.Make<bool>(gEngine, 0xADA);
	
	vars.Helper["Transition"] = vars.Helper.MakeString(gEngine, 0xAE0, 0x0);
	
	vars.Helper["Cutscene"] = vars.Helper.Make<bool>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x1B0, 0x198);
	
	vars.Helper["DeathLoad"] = vars.Helper.Make<bool>(gEngine, 0x1070, 0x2B0);
	
	vars.Helper["Items"] = vars.Helper.Make<IntPtr>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x6C0, 0x110 + 0x0);
	
	vars.Helper["ItemCount"] = vars.Helper.Make<int>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x6C0, 0x110 + 0x8);
	
	vars.Helper["GameplayMenu"] = vars.Helper.Make<long>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x6F0, 0x100, 0x2D8);
	
	vars.Helper["Saving"] = vars.Helper.Make<long>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x6F0, 0x128, 0x318);
	vars.Helper["GameOver"] = vars.Helper.Make<long>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x6F0, 0x118);
	
	vars.Helper["End"] = vars.Helper.Make<byte>(gEngine, 0x1070, 0x38, 0x0, 0x30, 0x358, 0x740, 0xC0);
	
	vars.Helper["localPlayer"] = vars.Helper.Make<long>(gEngine, 0x1070, 0x38, 0x0, 0x30);
	vars.Helper["localPlayer"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	
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
}

update
{
	//print(modules.First().ModuleMemorySize.ToString());
	
	vars.Helper.Update();
	vars.Helper.MapPointers();
}

onStart
{
	vars.completedSplits.Clear();
	vars.totalGameTime = 0;
	vars.Inventory.Clear();
}

start
{
}

split
{  
	const string ItemFormat = "[{0}] {1} ({2})";
	string setting = "";
	
	// Item splits.
	for (int i = 0; i < old.ItemCount; i++)
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
		if (!string.IsNullOrEmpty(setting))
		vars.Log(setting);

		if (settings.ContainsKey(setting) && settings[setting]
			&& vars.completedSplits.Add(setting))
		{
			return true;
		}
	}
	
	if(current.End != 0 && old.End == 0){
		return true;
	}
}

isLoading
{
	return current.Saving != 0 || current.GameOver != 0 || current.Transition == "/Game/Game/Maps/Main_Mennu/Main_Menu" || current.localPlayer == null || current.DeathLoad || current.Cutscene || current.Pause && current.GameplayMenu == 0;
	//return true;
}

gameTime
{
	/*
	if(current.IGT > old.IGT){
		return TimeSpan.FromSeconds(vars.totalGameTime + current.IGT);
	}
	if(current.IGT == 0 && old.IGT > 0){
		vars.totalGameTime = vars.totalGameTime + old.IGT;
		return TimeSpan.FromSeconds(vars.totalGameTime + current.IGT);
	}
	*/
}

exit
{
	 //pauses timer if the game crashes
	timer.IsGameTimePaused = true;
}