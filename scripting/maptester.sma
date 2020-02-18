#include <amxmodx>
#include <amxmisc>

new const szPathGoodMaps[] = "mapcycle_good.txt"
new const szPathBadMaps[] = "mapcycle_bad.txt"

new const szPathInProgress[] = "mapcycle_testinprogress.txt" // Do not edit.
new const szPathMapCycle[] = "mapcycle.txt"

public plugin_init()
{
	// set_task(1.0, "runCheck")
	runCheck()
}

public runCheck()
{
	new szCurrentMap[32], szTestedMap[32]
	new fProgress

	get_mapname(szCurrentMap, charsmax(szCurrentMap))
	
	fProgress = fopen(szPathInProgress, "rt")
	if( !fProgress ) // We assume here that if the file exists (and is openable) we are already in progress
	{
		// First map has run successfully
		log_goodmap(szCurrentMap, false)
		copy(szTestedMap, charsmax(szTestedMap), szCurrentMap)
	}
	else
	{
		fgets(fProgress, szTestedMap, charsmax(szTestedMap))
		trim(szTestedMap)
		
		if( equal(szCurrentMap, szTestedMap) )
		{
			// Map has run successfully
			log_goodmap(szTestedMap)
		}
		else
		{
			// Tested map failed.
			log_badmap(szTestedMap, .szComment="Server Crashed")
		}
	}
	
	// Find nextmap to test.
	
	new fCycle = fopen(szPathMapCycle, "r")
	new data[32]
	
	if( fCycle )
	{
		new bool:bFoundEOF = true
		while( !feof(fCycle) )
		{
			fgets(fCycle, data, charsmax(data))
			trim(data)
			
			if( !data[0] || (data[0] == '/' && data[1] == '/') || data[0] == ';')
				continue
			
			if( equal(data, szTestedMap) )
			{
				while( !feof(fCycle) )
				{
					fgets(fCycle, data, charsmax(data))
					trim(data)
					
					if( !data[0] || (data[0] == '/' && data[1] == '/') || data[0] == ';')
						continue
					
					if( ValidMap(data) )
					{
						// map is valid
						fProgress = fopen(szPathInProgress, "w")
						fputs(fProgress, data)
						fclose(fProgress)
						bFoundEOF = false
						break
					}
					else
					{
						log_badmap(data, .szComment="Not Valid")
					}
				}
				break
			}
		}
		fclose(fCycle)
		
		if( bFoundEOF )
		{
			delete_file(szPathInProgress)
			new szFilepath[128]
			get_configsdir(szFilepath, charsmax(szFilepath))
			add(szFilepath, charsmax(szFilepath), "/plugins-maptester.ini")
			new fPlugin = fopen(szFilepath, "w")
			fputs(fPlugin, "maptester.amxx disabled")
			fclose(fPlugin)
			log_goodmap("// Finished")
			log_badmap("// Finished")
		}
		else
		{
			server_cmd("changelevel %s", data)
		}
	}
}

log_goodmap(szMapName[], bool:append=true)
{
	new fGood = fopen(szPathGoodMaps, append ? "a" : "w")
	if( fGood )
	{
		// new temp[32]; get_time("%m/%d/%Y - %H:%M:%S >>", temp, charsmax(temp));
		// fputs(fGood, temp)
		fputs(fGood, szMapName)
		fputs(fGood, "^n")
		fclose(fGood)
		server_print("/\/\/\/\/\/\/\^nGoodMap: %s^n/\/\/\/\/\/\/\", szMapName)
	}
	else
	{
		// Failed to open good map file.
		server_print("/\/\/\/\/\/\/\^nGoodMap: %s, but failed open %s^n/\/\/\/\/\/\/\", szMapName, szPathGoodMaps)
	}
}

log_badmap(szMapName[], bool:append=true, szComment[]="")
{
	new fBad = fopen(szPathBadMaps, append ? "a" : "w")
	if( fBad )
	{
		if( szComment[0] )
		{
			new szMapComment[64]
			format(szMapComment, charsmax(szMapComment), "%s ; %s", szMapName, szComment)
			fputs(fBad, szMapComment)
		}
		else
		{
			fputs(fBad, szMapName)
		}
		fputs(fBad, "^n")
		fclose(fBad)
		
		server_print("/\/\/\/\/\/\/\^nBadMap: %s^n%s^n/\/\/\/\/\/\/\", szMapName, szComment)
	}
	else
	{
		// Failed to open bad map file.
		server_print("/\/\/\/\/\/\/\^nBadMap: %s, but failed open %s^n/\/\/\/\/\/\/\", szMapName, szPathBadMaps)
	}
}

stock bool:ValidMap(mapname[])
{
	if ( is_map_valid(mapname) )
	{
		return true;
	}
	// If the is_map_valid check failed, check the end of the string
	new len = strlen(mapname) - 4;
	
	// The mapname was too short to possibly house the .bsp extension
	if (len < 0)
	{
		return false;
	}
	if ( equali(mapname[len], ".bsp") )
	{
		// If the ending was .bsp, then cut it off.
		// the string is byref'ed, so this copies back to the loaded text.
		mapname[len] = '^0';
		
		// recheck
		if ( is_map_valid(mapname) )
		{
			return true;
		}
	}
	
	return false;
}

	