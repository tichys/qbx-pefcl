local function addCash(src, amount)
	local Player = exports.qbx_core:GetPlayer(src)
	if Config.ox_inventory then
		exports.ox_inventory:addCash(src,amount)
	else
		Player.Functions.AddMoney('cash', amount)
	end
end

local function removeCash(src, amount)
	local Player = exports.qbx_core:GetPlayer(src)
	if Config.ox_inventory then
		exports.ox_inventory:removeCash(src,amount)
	else
		Player.Functions.RemoveMoney('cash', amount)
	end
end

local function getCash(src)
	local Player = QBCore.Functions.GetPlayer(src)
	if Config.ox_inventory then
		return exports.ox_inventory:getCash(src) or 0
	else
		return Player.PlayerData.money['cash'] or 0
	end
end

local function loadPlayer(src, citizenid, name)
	exports.pefcl:loadPlayer(src, {
		source = src,
		identifier = citizenid,
		name = name
	})
end

local function UniqueAccounts(player)
	local citizenid = player.PlayerData.citizenid
	local playerSrc = player.PlayerData.source
	local PlayerJob = player.PlayerData.job
	if Config.BusinessAccounts[PlayerJob.name] then
		if not exports.pefcl:getUniqueAccount(playerSrc, PlayerJob.name).data then
			local data = {
				name = tostring(Config.BusinessAccounts[PlayerJob.name].AccountName), 
				type = 'shared', 
				identifier = PlayerJob.name
			}
			exports.pefcl:createUniqueAccount(playerSrc, data)
		end

		local role = false
		if PlayerJob.grade.level >= Config.BusinessAccounts[PlayerJob.name].AdminRole then
			role = 'admin'
		elseif PlayerJob.grade.level >= Config.BusinessAccounts[PlayerJob.name].ContributorRole then
			role = 'contributor'
		end

		if role then
			local data = {
				role = role,
				accountIdentifier = PlayerJob.name,
				userIdentifier = citizenid,
				source = playerSrc
			}
			exports.pefcl:addUserToUniqueAccount(playerSrc, data)
		end
	end
end

local function getCards(src)
    local retval = {}
    local cards = exports.ox_inventory:Search(src, 'slots', 'visa')

    for _, v in pairs(cards) do
        retval[#retval + 1] = {
            id = v.metadata.id,
            holder = v.metadata.holder,
            number = v.metadata.number
        }
    end

    return retval
end

local function giveCard(src, card)
    exports.ox_inventory:AddItem(src, 'visa', 1, {
        id = card.id,
        holder = card.holder,
        number = card.number,
        description = ('Card Number: %s'):format(card.number)
    })
end

local function getBank(source)
	local Player = exports.qbx_core:GetPlayer(source)
	return Player.PlayerData.money['bank'] or 0
end

exports('getBank', getBank)
exports('addCash', addCash)
exports('removeCash', removeCash)
exports('getCash', getCash)
exports('giveCard', giveCard)
exports('getCards', getCards)

AddEventHandler('QBCore:Server:OnMoneyChange', function(playerSrc, moneyType, amount, action, reason)
	if moneyType ~= 'bank' then return end
	if action == 'add' then
		exports.pefcl:addBankBalance(playerSrc, { amount = amount, message = reason })	
	end

	if action == 'remove' then
		exports.pefcl:removeBankBalance(playerSrc, { amount = amount, message = reason })	
	end

	if action == 'set' then
		exports.pefcl:setBankBalance(playerSrc, { amount = amount, message = reason })	
	end	
end)

AddEventHandler('QBCore:Server:PlayerLoaded', function(player)
	if not player then
		return
	end
	local citizenid = player.PlayerData.citizenid
	local charInfo = player.PlayerData.charinfo
	local playerSrc = player.PlayerData.source
	loadPlayer(playerSrc, citizenid, charInfo.firstname .. ' ' .. charInfo.lastname)
	UniqueAccounts(player)				
	player.Functions.SyncMoney()
end)

RegisterNetEvent('qbx_pefcl:server:UnloadPlayer', function()
	exports.pefcl:unloadPlayer(source)
end)

RegisterNetEvent('qbx_pefcl:server:SyncMoney', function()
	local player = exports.qbx_core:GetPlayer(source)
	player.Functions.SyncMoney()
end)

RegisterNetEvent('qbx_pefcl:server:OnJobUpdate', function(oldJob)
	local player = exports.qbx_core:GetPlayer(source)
	UniqueAccounts(player)
end)

local currentResName = GetCurrentResourceName()

AddEventHandler('onServerResourceStart', function(resName)
	if resName ~= currentResName then return end
	local players = exports.qbx_core:GetQBPlayers()
	if not players or players == nil then
		print('Error loading players, if no players on the server ignore this')
		return
	end
	for _, v in pairs(players) do
		loadPlayer(v.PlayerData.source, v.PlayerData.citizenid, v.PlayerData.charinfo.firstname .. ' ' .. v.PlayerData.charinfo.lastname)
		UniqueAccounts(v)
		v.Functions.SyncMoney()
	end
end)
