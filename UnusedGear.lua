UNUSEDGEAR_MSG_ADDONNAME = "UnusedGear"
UNUSEDGEAR_MSG_VERSION   = GetAddOnMetadata( UNUSEDGEAR_MSG_ADDONNAME,"Version" )
UNUSEDGEAR_MSG_AUTHOR    = "opussf"

-- Colours
COLOR_RED = "|cffff0000";
COLOR_GREEN = "|cff00ff00";
COLOR_BLUE = "|cff0000ff";
COLOR_PURPLE = "|cff700090";
COLOR_YELLOW = "|cffffff00";
COLOR_ORANGE = "|cffff6d00";
COLOR_GREY = "|cff808080";
COLOR_GOLD = "|cffcfb52b";
COLOR_NEON_BLUE = "|cff4d4dff";
COLOR_END = "|r";

UnusedGear = {}
UnusedGear_Options = {
	["targetBag"] = 0,
	["moveLimit"] = 20,
}
UnusedGear_savedata = {}
-- itemLog = { link = { log, movedCount, lastMoved } }
-- ignoreItems = { link = true }
--[[
INEED.bindTypes = {
	[ITEM_SOULBOUND] = "Bound",
	[ITEM_BIND_ON_PICKUP] = "Bound",
}
INEED.scanTip = CreateFrame( "GameTooltip", "INEEDTip", UIParent, "GameTooltipTemplate" )
INEED.scanTip2 = _G["INEEDTipTextLeft2"]
INEED.scanTip3 = _G["INEEDTipTextLeft3"]
INEED.scanTip4 = _G["INEEDTipTextLeft4"]

]]

UnusedGear.armorTypes = {
	["Miscellaneous"] = 0,
	["Cloth"] = 1,
	["Leather"] = 2,
	["Mail"] = 3,
	["Plate"] = 4
}
UnusedGear.maxArmorType = 0

UnusedGear.maxArmorTypeByClass = {
	["DEATH KNIGHt"] = "Plate",
	["DEMON HUNTER"] = "Leather",
	["DRUID"] = "Leather",
	["EVOKER"] = "Mail",
	["HUNTER"] = "Mail",
	["MAGE"] = "Cloth",
	["MONK"] = "Leather",
	["PALADIN"] = "Plate",
	["PRIEST"] = "Cloth",
	["ROGUE"] = "Leather",
	["SHAMAN"] = "Mail",
	["WARLOCK"] = "Cloth",
	["WARRIOR"] = "Plate"
}

function UnusedGear.Print( msg, showName)
	-- print to the chat frame
	-- set showName to false to suppress the addon name printing
	if (showName == nil) or (showName) then
		msg = COLOR_GREEN..UNUSEDGEAR_MSG_ADDONNAME.."> "..COLOR_END..msg
	end
	DEFAULT_CHAT_FRAME:AddMessage( msg )
end
function UnusedGear.OnLoad()
	UnusedGear_Frame:RegisterEvent( "MERCHANT_SHOW" )
	--UnusedGear_Frame:RegisterEvent( "SCRAPPING_MACHINE_SHOW" )
	UnusedGear_Frame:RegisterEvent( "EQUIPMENT_SETS_CHANGED" )
	UnusedGear_Frame:RegisterEvent( "AUCTION_HOUSE_SHOW" )
	UnusedGear_Frame:RegisterEvent( "BANKFRAME_OPENED" )
	UnusedGear_Frame:RegisterEvent( "ADDON_LOADED" )
	UnusedGear_Frame:RegisterEvent( "VARIABLES_LOADED" )
	UnusedGear_Frame:RegisterEvent( "PLAYER_LEAVING_WORLD" )
	local localizedClass, englishClass, classIndex = UnitClass( "player" )
	UnusedGear.maxArmorType = UnusedGear.armorTypes[ UnusedGear.maxArmorTypeByClass[ englishClass ] ]
	SLASH_UNUSEDGEAR1 = "/UG"
	SLASH_UNUSEDGEAR2 = "/UNUSEDGEAR"
	SlashCmdList["UNUSEDGEAR"] = function( msg ) UnusedGear.Command( msg ); end

	--AutoProfit:RegisterEvent("MERCHANT_CLOSED");
	--ap.ForAllJunk();
end

function UnusedGear.ADDON_LOADED()
	-- Unregister the event for this method.
	UnusedGear_Frame:UnregisterEvent("ADDON_LOADED")

	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, UnusedGear.onTooltipSetItem)
	UnusedGear.name = UnitName("player")
	UnusedGear.realm = GetRealmName()
end

function UnusedGear.VARIABLES_LOADED()
	-- Unregister the event for this method.
	UnusedGear_Frame:UnregisterEvent( "VARIABLES_LOADED" )

	UnusedGear_savedata[UnusedGear.realm] = UnusedGear_savedata[UnusedGear.realm] or {}
	UnusedGear_savedata[UnusedGear.realm][UnusedGear.name] = UnusedGear_savedata[UnusedGear.realm][UnusedGear.name] or {}

	UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].itemLog = UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].itemLog or {}
	UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].ignoreItems = UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].ignoreItems or {}

	UnusedGear.myItemLog = UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].itemLog
	UnusedGear.myIgnoreItems = UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].ignoreItems
	UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].problemItems = UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].problemItems or {}
end
function UnusedGear.PLAYER_LEAVING_WORLD()
	local lastMerchantShow = ( UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].lastMerchantShow and
			UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].lastMerchantShow-1 or time() - 3600 )
	for link, item in pairs( UnusedGear.myItemLog ) do
		if( ( item.lastSeen and item.lastSeen < lastMerchantShow ) or not item.lastSeen ) then
			UnusedGear.myItemLog[link] = nil
		end
	end
end
function UnusedGear.MERCHANT_SHOW()
	local highestBagNumber = 0
	for bag = 0, NUM_BAG_SLOTS do
		if C_Container.GetContainerNumSlots( bag ) > 0 then
			highestBagNumber = max( highestBagNumber, bag )
		end
	end

	-- GetSortBagsRightToLeft is normally false
	UnusedGear_Options.targetBag = C_Container.GetSortBagsRightToLeft() and highestBagNumber or 0

	UnusedGear.BuildGearSets()
	UnusedGear.ExtractItems()
	UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].lastMerchantShow = time()
end
--UnusedGear.SCRAPPING_MACHINE_SHOW = UnusedGear.MERCHANT_SHOW
UnusedGear.AUCTION_HOUSE_SHOW = UnusedGear.MERCHANT_SHOW
UnusedGear.BANKFRAME_OPENED = UnusedGear.MERCHANT_SHOW

function UnusedGear.EQUIPMENT_SETS_CHANGED()
	--UnusedGear.Print( "EQUIPMENT_SETS_CHANGED" )
end
function UnusedGear.BuildGearSets()
	UnusedGear.itemsInSets = {}
	for setNum = 0, C_EquipmentSet.GetNumEquipmentSets(), 1 do
		equipmentSetName = C_EquipmentSet.GetEquipmentSetInfo( setNum )
		if( equipmentSetName ) then
			local setItemArray = C_EquipmentSet.GetItemIDs( setNum )
			for i, itemID in pairs( setItemArray ) do
				if( not UnusedGear.itemsInSets[ itemID ] ) then
					UnusedGear.itemsInSets[ itemID ] = {}
				end
				table.insert( UnusedGear.itemsInSets[ itemID ], equipmentSetName )
			end
		end
	end
end
function UnusedGear.Reset()
	UnusedGear.Print( string.format( "Performing reset for %s:%s", UnusedGear.name, UnusedGear.realm ) )
	UnusedGear.myIgnoreItems = {}
	UnusedGear.myItemLog = {}
end
-- Command code
function UnusedGear.PrintHelp()
	UnusedGear.Print( UNUSEDGEAR_MSG_ADDONNAME.." version: "..UNUSEDGEAR_MSG_VERSION )
	UnusedGear.Print( "Use: /UG or /UNUSEDGEAR for these commands: ")

	for cmd, info in pairs( UnusedGear.commandList ) do
		UnusedGear.Print( string.format( "-- %s %s -> %s",
				cmd, info.help[1], info.help[2] ) )
	end
end
UnusedGear.commandList = {
	["help"] = {
		["func"] = UnusedGear.PrintHelp,
		["help"] = { "", "Print this help" },
	},
	["reset"] = {
		["func"] = UnusedGear.Reset,
		["help"] = { "", "Reset "..UNUSEDGEAR_MSG_ADDONNAME.." for this char." },
	},
	["<ItemLink>"] = {
		["help"] = { "", "Toggle ignoring <ItemLink>" },
	},
}
function UnusedGear.ParseCmd( msg )
	if msg then
		local a,b,c = strfind(msg, "(%S+)")  --contiguous string of non-space characters
		if a then
			return c, strsub(msg, b+2)
		else
			return ""
		end
	end
end
function UnusedGear.Command( msg )
	local cmd, param = UnusedGear.ParseCmd( msg )
	cmd = string.lower( cmd )
	local cmdFunc = UnusedGear.commandList[cmd]
	if cmdFunc then
		cmdFunc.func( param )
	else
		local itemID = UnusedGear.GetItemIdFromLink( msg )
		if( itemID ) then
			itemID = tonumber( itemID )
			UnusedGear.myIgnoreItems[itemID] = not UnusedGear.myIgnoreItems[itemID]
			UnusedGear.Print( string.format( "%s is %sbeing ignored.", msg, ( UnusedGear.myIgnoreItems[itemID] and "" or "not " ) ) )
		else
			UnusedGear.PrintHelp()
		end
	end
end
-- moveTests { testfunction, truthmessage, falsemessage }
moveTests = {
	{ function( itemStruct ) return not UnusedGear.myIgnoreItems[itemStruct.itemID]; end, nil, "Ignored" },
	{ function( itemStruct ) return( itemStruct.quality < 6 ); end, nil, "Rarity is too high" },
	{ function( itemStruct )
	 		_, _, _, _, _, iType, iSubType = GetItemInfo( itemStruct.hyperlink )
	 		iArmorType = UnusedGear.armorTypes[ iSubType ]
	 		return( ( iType == "Armor" and iArmorType ) or iType == "Weapon" or iSubType == "Shields" )
	 	end, "Armor, weapon, or shield", nil }, --"non equipable item" },
	{ function( itemStruct ) _, _, _, _, itemMinLevel = GetItemInfo( itemStruct.hyperlink ); return( itemMinLevel <= UnitLevel( "player" ) ); end,
	 		"item can be used", "item too high to use" },
	{ function( itemStruct ) return not UnusedGear.itemsInSets[ itemStruct.itemID ]; end,
			"not in itemsets", "in an itemset" },
	{ function( itemStruct ) iName = GetItemInfo( itemStruct.hyperlink ); return not string.find( iName, "Tabard" ); end, nil, nil }, --"not a Tabard", "is a Tabard" },
	-- { function( itemStruct ) return true; end, "Set True", "Set False" }
}
function UnusedGear.ForAllGear( action, message )
	-- work through all the times
	moveCount = 0
	for bag = 0, NUM_BAG_SLOTS do
		-- if C_Container.GetContainerNumFreeSlots( bag ) > 0 then  -- This slot has a bag
			--if not GetBagSlotFlag( bag, LE_BAG_FILTER_FLAG_IGNORE_CLEANUP ) then  -- this bag is not ignored
		for slot = 0, C_Container.GetContainerNumSlots( bag ) do -- work through this bag
			itemLog = {}
			toMove, moved = true, false  -- assume to moved
			local itemStruct = C_Container.GetContainerItemInfo( bag, slot )
			-- itemStruct{ itemID, quality, isBound }
			-- local itemID, link
			-- if( itemStruct ) then
			-- 	itemID = itemStruct.itemID
			-- 	link = itemStruct.hyperlink
			-- end

			if( itemStruct ) then  -- only do work with slots that have items
				--print( itemStruct.hyperlink.." is in ("..bag..", "..slot..") "..itemStruct.quality )
				test = 1
				while( toMove and test <= #moveTests ) do
					testStruct = moveTests[test]
					testResult = testStruct[1]( itemStruct )
					--print( "  is "..(testResult and "true" or "false") )
					toMove = toMove and testResult  -- any failure will set this to false
					testLog = testStruct[ testResult and 2 or 3 ]
					if testLog then table.insert( itemLog, testLog ) end
					--print( table.concat( itemLog, "-"))
					test = test + 1
				end
			end
			if toMove then
				targetBagID, targetSlot = UnusedGear.GetLastFreeSlotInBag( UnusedGear_Options.targetBag )
				if( targetBagID ) then
					ClearCursor()
					C_Container.PickupContainerItem( bag,  slot )
					if( targetBagID == 0 ) then
						PutItemInBackpack()
						table.insert( itemLog, "Moved to Backpack" )
					else
						PutItemInBag( targetBagID + 30 )
						table.insert( itemLog, "Moved to bag:"..targetBagID )
					end
					moveCount = moveCount + 1
					moved = true
				end
			end
			if( itemStruct ) then
				UnusedGear.myItemLog[itemStruct.itemID] = UnusedGear.myItemLog[itemStruct.itemID] or { ["countMoved"] = 0 }

				if( UnusedGear.myItemLog[itemStruct.itemID].countMoved >= UnusedGear_Options.moveLimit ) then
					table.insert( itemLog,
							string.format( "moved many times.\nI'm ignoring this item in the future.\nUse %s %s to toggle ignoring of this item",
								SLASH_UNUSEDGEAR1, itemStruct.hyperlink ) )
					UnusedGear.myIgnoreItems[tonumber( itemStruct.itemID )] = time()
				end
				UnusedGear.myItemLog[itemStruct.itemID]["log"] = table.concat( itemLog, "; " )
				UnusedGear.myItemLog[itemStruct.itemID]["lastSeen"] = time()
				UnusedGear.myItemLog[itemStruct.itemID]["link"] = itemStruct.hyperlink
				if moved then
					UnusedGear.myItemLog[itemStruct.itemID]["lastMoved"] = time()
					UnusedGear.myItemLog[itemStruct.itemID]["countMoved"] = UnusedGear.myItemLog[itemStruct.itemID].countMoved + 1
				end
			end
		end
			--end
		--end
	end
end
function UnusedGear.ExtractItems()
	UnusedGear.ForAllGear( "", "" )
end
function UnusedGear.GetItemIdFromLink( itemLink )
	-- returns just the integer itemID
	-- itemLink can be a full link, or just "item:999999999"
	if itemLink then
		return tonumber(strmatch( itemLink, "item:(%d*)" ))
	end
end
function UnusedGear.GetLastFreeSlotInBag( bagID )
	freeSlots, typeid = C_Container.GetContainerNumFreeSlots( bagID )
	if( freeSlots > 0 ) then
		for slot = C_Container.GetContainerNumSlots( bagID ), 0, -1 do
			local texture = C_Container.GetContainerItemInfo( bagID, slot )
			if not texture then
				return bagID, slot
			end
		end
	end
end
function UnusedGear.onTooltipSetItem( tooltip, tooltipdata ) -- is passed the tooltip frame as a table
	link = select( 2, GetItemInfo( tooltipdata.id ) )

	if( UnusedGear.myItemLog[tooltipdata.id] and UnusedGear.myItemLog[tooltipdata.id].log ) then
		UnusedGear.lineData = {
			["leftText"] = UnusedGear.myItemLog[tooltipdata.id].log,
			["rightText"] = ( UnusedGear.myItemLog[tooltipdata.id].countMoved > 0 and "Moved:"..UnusedGear.myItemLog[tooltipdata.id].countMoved or "" )
		}
		--print( link..":"..UnusedGear.myItemLog[tooltipdata.id].log )
		tooltip:AddLineDataText( UnusedGear.lineData )
	-- else
	-- 	UnusedGear_savedata[UnusedGear.realm][UnusedGear.name].problemItems[tooltipdata.id] = true
	-- 	for k in pairs(UnusedGear.myItemLog) do
	-- 		if UnusedGear.GetItemIdFromLink(k) == UnusedGear.GetItemIdFromLink(link) then
	-- 			print( k.." matches")
	-- 		end
	-- 	end
	end
	-- itemID = tostring(tooltipdata.id)

	-- if itemID and INEED_data[itemID] then
	-- 	for realm in pairs(INEED_data[itemID]) do
	-- 		if realm == INEED.realm then
	-- 			for name, data in pairs(INEED_data[itemID][realm]) do
	-- 				INEED.lineData = {
	-- 					["leftText"] = name,
	-- 					["rightText"] = string.format("Needs: %i / %i", data.total + (data.inMail or 0), data.needed)
	-- 				}
	-- 				tooltip:AddLineDataText(INEED.lineData)
	-- 			end
	-- 		end
	-- 	end
	-- end



	-- local item, link = tooltip:GetItem()  -- name, link
	-- if( UnusedGear.myItemLog[link] and UnusedGear.myItemLog[link].log ) then
	-- 	tooltip:AddDoubleLine( UnusedGear.myItemLog[link].log,
	-- 			( UnusedGear.myItemLog[link].countMoved > 0 and "Moved:"..UnusedGear.myItemLog[link].countMoved or "" ) )
	-- end
end
