ESX = nil
TriggerEvent(pSocietyCFG.ESX, function(obj) ESX = obj end)
pSociety = {}
pSociety.Trad = pSocietyTranslation[pSocietyCFG.Language]

AddEventHandler('onResourceStart', function(resourceName) if (GetCurrentResourceName() ~= resourceName) then return end                                                                                                                                                                                   RconPrint("^2["..GetCurrentResourceName().."] ^0: Society ^3Initialized ^5By POGO#0644^0\n") end)  

local RegisteredSocieties = {}

pSociety.GetSociety = function(name)
	for i=1, #RegisteredSocieties, 1 do
		if RegisteredSocieties[i].name == name then
			return RegisteredSocieties[i]
		end
	end
end

pSociety.getMaximumGrade = function(jobname)
	local queryDone, queryResult = false, nil

	MySQL.Async.fetchAll('SELECT * FROM job_grades WHERE job_name = @jobname ORDER BY `grade` DESC ;', {
		['@jobname'] = jobname
	}, function(result)
		queryDone, queryResult = true, result
	end)

	while not queryDone do
		Citizen.Wait(10)
	end

	if queryResult[1] then
		return queryResult[1].grade
	end

	return nil
end

AddEventHandler('pSociety:getSocieties', function(cb)
	cb(RegisteredSocieties)
end)

AddEventHandler('pSociety:getSociety', function(name, cb)
	cb(pSociety.GetSociety(name))
end)

RegisterServerEvent('pSociety:registerSociety')
AddEventHandler('pSociety:registerSociety', function(name, label, account, datastore, inventory, data)
	local found = false

	local society = {
		name      = name,
		label     = label,
		account   = account,
		datastore = datastore,
		inventory = inventory,
		data      = data
	}

	for i=1, #RegisteredSocieties, 1 do
		if RegisteredSocieties[i].name == name then
			found = true
			RegisteredSocieties[i] = society
			break
		end
	end

	if not found then
		table.insert(RegisteredSocieties, society)
	end

    RconPrint("^3["..GetCurrentResourceName().."] ^0: "..label.." ^2has been registered^0\n")
end)

ESX.RegisterServerCallback('pSociety:getSocietyMoney', function(source, cb, societyName)
	local society = pSociety.GetSociety(societyName)

	if society then
		TriggerEvent(pSocietyCFG.AddonAccount, society.account, function(account)
			cb(account.money)
		end)
	else
		cb(0)
	end
end)

RegisterServerEvent('pSociety:withdrawMoney')
AddEventHandler('pSociety:withdrawMoney', function(society, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	local society = pSociety.GetSociety(society)
	amount = ESX.Math.Round(tonumber(amount))
	money = ESX.Math.GroupDigits(amount)..""..pSociety.Trad["money_symbol"]

	if xPlayer.job.name == society.name then
		TriggerEvent(pSocietyCFG.AddonAccount, society.account, function(account)
			if amount > 0 and account.money >= amount then
				account.removeMoney(amount)
				xPlayer.addMoney(amount)

				TriggerClientEvent("RageUI:Popup", source, {message= pSociety.Trad["withdrew"].." "..money})
				TriggerEvent("pSociety:SendLogs", source, pSociety.Trad["log_action"], pSociety.Trad["log_withdrew"].." "..money.." \n"..pSociety.Trad["log_company"].." "..society.label) 
			else
				TriggerClientEvent("RageUI:Popup", source, {message= pSociety.Trad["impossible_action"]})
			end
		end)
	else
		print(('pSociety: %s attempted to call withdrawMoney!'):format(xPlayer.license))
	end
end)

RegisterServerEvent('pSociety:depositMoney')
AddEventHandler('pSociety:depositMoney', function(society, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	local society = pSociety.GetSociety(society)
	amount = ESX.Math.Round(tonumber(amount))
	money = ESX.Math.GroupDigits(amount)..""..pSociety.Trad["money_symbol"]

	if xPlayer.job.name == society.name then
		if amount > 0 and xPlayer.getMoney() >= amount then
			TriggerEvent(pSocietyCFG.AddonAccount, society.account, function(account)
				xPlayer.removeMoney(amount)
				account.addMoney(amount)
			end)

			TriggerClientEvent("RageUI:Popup", source, {message= pSociety.Trad["deposed"].." "..money})
			TriggerEvent("pSociety:SendLogs", source, pSociety.Trad["log_action"], pSociety.Trad["log_deposed"].." "..money.." \n"..pSociety.Trad["log_company"].." "..society.label) 
		else
			TriggerClientEvent("RageUI:Popup", source, {message= pSociety.Trad["impossible_action"]})
		end
	else
		print(('pSociety: %s attempted to call depositMoney!'):format(xPlayer.license))
	end
end)

RegisterServerEvent('pSociety:washMoney')
AddEventHandler('pSociety:washMoney', function(society, amount)
	local xPlayer = ESX.GetPlayerFromId(source)
	local societyy = pSociety.GetSociety(society)
	local account = xPlayer.getAccount(pSocietyCFG.BlackMoney)
	amount = ESX.Math.Round(tonumber(amount))
	money = ESX.Math.GroupDigits(amount)..""..pSociety.Trad["money_symbol"]

	if xPlayer.job.name == society then
		if amount and xPlayer.getAccount(pSocietyCFG.BlackMoney).money >= amount then
			TriggerEvent(pSocietyCFG.AddonAccount, societyy.account, function(sctyacc)
				xPlayer.removeAccountMoney(pSocietyCFG.BlackMoney, amount)
				sctyacc.addMoney(amount)
				TriggerClientEvent("RageUI:Popup", source, {message= pSociety.Trad["washed"].." "..money})
				TriggerEvent("pSociety:SendLogs", source, pSociety.Trad["log_action"], pSociety.Trad["log_washed"].." "..money.." \n"..pSociety.Trad["log_company"].." "..societyy.label) 
			end)
		else
			TriggerClientEvent("RageUI:Popup", source, {message= pSociety.Trad["impossible_action"]})
		end
	else
		print(('pSociety: %s attempted to call washMoney!'):format(xPlayer.license))
	end
end)

local Jobs = {}

MySQL.ready(function()
	local result = MySQL.Sync.fetchAll('SELECT * FROM jobs', {})

	for i=1, #result, 1 do
		Jobs[result[i].name]        = result[i]
		Jobs[result[i].name].grades = {}
	end

	local result2 = MySQL.Sync.fetchAll('SELECT * FROM job_grades', {})

	for i=1, #result2, 1 do
		Jobs[result2[i].job_name].grades[tostring(result2[i].grade)] = result2[i]
	end
end)

ESX.RegisterServerCallback('pSociety:getEmployees', function(source, cb, society)

	MySQL.Async.fetchAll('SELECT firstname, lastname, license, job, job_grade FROM users WHERE job = @job ORDER BY job_grade DESC', {
		['@job'] = society
	}, function (results)
		local employees = {}
		local lbl = nil

		for i=1, #results, 1 do
			if results[i].firstname == nil or results[i].lastname == nil then lbl = results[i].name else lbl = results[i].firstname .. ' ' .. results[i].lastname end
			table.insert(employees, {
				name       = lbl,
				license = results[i].license,
				job = {
					name        = results[i].job,
					label       = Jobs[results[i].job].label,
					grade       = results[i].job_grade,
					grade_name  = Jobs[results[i].job].grades[tostring(results[i].job_grade)].name,
					grade_label = Jobs[results[i].job].grades[tostring(results[i].job_grade)].label
				}
			})
		end

		cb(employees)
	end)
end)

ESX.RegisterServerCallback('pSociety:getJob', function(source, cb, society)
	local job    = json.decode(json.encode(Jobs[society]))
	local grades = {}

	for k,v in pairs(job.grades) do
		table.insert(grades, v)
	end

	table.sort(grades, function(a, b)
		return a.grade < b.grade
	end)

	job.grades = grades

	cb(job)
end)

ESX.RegisterServerCallback('pSociety:setJob', function(source, cb, license, job, grade)
	local xPlayer = ESX.GetPlayerFromId(source)
	local isBoss = xPlayer.job.grade_name == 'boss'

	if isBoss then
		local xTarget = ESX.GetPlayerFromLicense(license)

		if grade ~= tonumber(pSociety.getMaximumGrade(job)) or job == "unemployed" then
			if xTarget then
				xTarget.setJob(job, grade)

				TriggerClientEvent("RageUI:Popup", xTarget, {message=pSociety.Trad["profession_evolved"]})
				TriggerClientEvent("RageUI:Popup", source, {message=pSociety.Trad["modified_profession"]})

				TriggerEvent("pSociety:SendLogs", source, pSociety.Trad["log_action"], pSociety.Trad["log_setjob"].." "..license.." --> "..job.." "..grade) 
				cb()
			else
				MySQL.Async.execute('UPDATE users SET job = @job, job_grade = @job_grade WHERE license = @license', {
					['@job']        = job,
					['@job_grade']  = grade,
					['@license'] = license
				}, function(rowsChanged)
					TriggerClientEvent("RageUI:Popup", source, {message= pSociety.Trad["modified_profession"]})
					TriggerEvent("pSociety:SendLogs", source, pSociety.Trad["log_action"], pSociety.Trad["log_setjob"].." "..license.."  -->  "..job.." "..grade) 
					cb()
				end)
			end
		else
			TriggerClientEvent("RageUI:Popup", source, {message=pSociety.Trad["cannot_assign_profession"]})
			cb(false)
		end
	else
		print(('pSociety: %s attempted to setJob'):format(xPlayer.license))
		cb()
	end
end)

ESX.RegisterServerCallback('pSociety:setJobSalary', function(source, cb, job, grade, salary)
	local isBoss = pSociety.isPlayerBoss(source, job)
	local license = ESX.GetPlayerFromId(source).license

	if isBoss then
        MySQL.Async.execute('UPDATE job_grades SET salary = @salary WHERE job_name = @job_name AND grade = @grade', {
            ['@salary']   = salary,
            ['@job_name'] = job,
            ['@grade']    = grade
        }, function(rowsChanged)
            Jobs[job].grades[tostring(grade)].salary = salary
            local xPlayers = ESX.GetPlayers()

            for i=1, #xPlayers, 1 do
                local xPlayer = ESX.GetPlayerFromId(xPlayers[i])

                if xPlayer.job.name == job and xPlayer.job.grade == grade then
                    xPlayer.setJob(job, grade)
                end
            end

            cb()
        end)
	else
		print(('pSociety: %s attempted to setJobSalary'):format(license))
		cb()
	end
end)

ESX.RegisterServerCallback('pSociety:isBoss', function(source, cb, job)
	cb(pSociety.isPlayerBoss(source, job))
end)

pSociety.isPlayerBoss = function(playerId, job)
	local xPlayer = ESX.GetPlayerFromId(playerId)

	if xPlayer.job.name == job and xPlayer.job.grade_name == 'boss' then
		return true
	else
		print(('pSociety: %s attempted open a society boss menu!'):format(xPlayer.license))
		return false
	end
end

RegisterServerEvent("pSociety:RequestSetRecruit")
AddEventHandler("pSociety:RequestSetRecruit", function(target, job)
	local xPlayer = ESX.GetPlayerFromId(source)
	local Player = ESX.GetPlayerFromId(ply)
	local society = pSociety.GetSociety(job)

	if xPlayer.job.grade_name == 'boss' then
		TriggerClientEvent("pSociety:SendRequestRecruit", target, society.label, job)
		TriggerClientEvent("RageUI:Popup", source, {message=pSociety.Trad["request_sent"]})
	end
end)

RegisterServerEvent("pSociety:SendLogs")
AddEventHandler("pSociety:SendLogs", function(player, title, message)
	local idd = pSociety.GetPlayerDetails(player)

	local _embed = {
		{
			["color"] = pSocietyLOG.Color,
			["title"] = title,
			["description"] = message,
			["footer"] = {
				["text"] = pSocietyLOG.Footer,
				["icon_url"] = pSocietyLOG.Footer_URL,
			},
			["fields"] = {
				{
					["name"] = "**Player:** "..GetPlayerName(player),
					["value"] = idd,
					["inline"] = true
				},
			},
		}
	}

	PerformHttpRequest(pSocietyLOG.Webhooks, function(err, text, headers) end, 'POST', json.encode({
		username = "pSociety", 
		embeds = _embed,
		avatar_url = pSocietyLOG.Avatar
	}), { ['Content-Type'] = 'application/json' })
end)

pSociety.GetPlayerDetails = function(src)
	local player_id = src
	local ids = pSociety.ExtractIdentifiers(player_id)
	if pSocietyLOG.Discord then if ids.discord ~= "" then _discordID ="**Discord:** "..ids.discord.." <@" ..ids.discord:gsub("discord:", "")..">" else _discordID = "**Discord:** N/A" end else _discordID = "" end
	if pSocietyLOG.Steam then  if ids.steam ~= "" then _steamID = "**SteamID:** ["..ids.steam.."](https://steamcommunity.com/profiles/" ..tonumber(ids.steam:gsub("steam:", ""),16)..")" else _steamID = "**SteamID:** N/A" end else _steamID = "" end
	if pSocietyLOG.License then if ids.license ~= "" then _license ="**License:** " ..ids.license else _license = "**License :** N/A" end else _license = "" end
	if pSocietyLOG.Ip then if ids.ip ~= "" then _ip = "**IP:** [||"..ids.ip:gsub("ip:", "").."||](https://www.ip-tracker.org/locator/ip-lookup.php?ip=" ..ids.ip:gsub("ip:", "")..")" else _ip = "**IP :** N/A" end else _ip = "" end
	return _steamID..' \n'.. _discordID..' \n'.._license..' \n'.._ip
end
pSociety.ExtractIdentifiers = function(src)
    local identifiers = {
        steam = "",
        ip = "",
        discord = "",
        license = "",
        xbl = "",
        live = ""
    }

    for i = 0, GetNumPlayerIdentifiers(src) - 1 do
        local id = GetPlayerIdentifier(src, i)

        if string.find(id, "steam") then
            identifiers.steam = id
        elseif string.find(id, "ip") then
            identifiers.ip = id
        elseif string.find(id, "discord") then
            identifiers.discord = id
        elseif string.find(id, "license") then
            identifiers.license = id
        elseif string.find(id, "xbl") then
            identifiers.xbl = id
        elseif string.find(id, "live") then
            identifiers.live = id
        end
    end

    return identifiers
end

RegisterServerEvent("pSociety:SetJob")
AddEventHandler("pSociety:SetJob", function(job, grade)
	local xPlayer = ESX.GetPlayerFromId(source)

	xPlayer.setJob(job, grade)
	TriggerClientEvent("RageUI:Popup", source, {message=pSociety.Trad["profession_evolved"]})
	TriggerClientEvent("RageUI:Popup", source, {message= pSociety.Trad["log_recruit"].." "..job})
end)