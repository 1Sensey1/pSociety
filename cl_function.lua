Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent(pSocietyCFG.ESX, function(obj) ESX = obj end)
		Citizen.Wait(0)
	end
	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end
	ESX.PlayerData = ESX.GetPlayerData()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
	ESX.PlayerData.job = job
end)

pSociety = {}
pSociety.Zone = {}
pSociety.Trad = pSocietyTranslation[pSocietyCFG.Language]

pSociety.InitRageUIMenu = function(_title, _subtitle, _texturedict, _texturename, _rgb, _banner)
    if _banner then
	    RMenu.Add('bossmenu', 'main', RageUI.CreateMenu(_title, _subtitle, nil, nil, _texturedict, _texturename))
    else
        RMenu.Add('bossmenu', 'main', RageUI.CreateMenu(_title, _subtitle, 10, 200))
    end
	if _rgb ~= nil then
		RMenu:Get('bossmenu', 'main'):SetRectangleBanner(_rgb[1], _rgb[2], _rgb[3], 500)
	end
    RMenu.Add('bossmenu', 'manage_employees', RageUI.CreateSubMenu(RMenu:Get('bossmenu', 'main'), _title, _subtitle))
    RMenu.Add('bossmenu', 'update_employee', RageUI.CreateSubMenu(RMenu:Get('bossmenu', 'manage_employees'), _title, _subtitle))
    RMenu.Add('bossmenu', 'manage_salary', RageUI.CreateSubMenu(RMenu:Get('bossmenu', 'main'), _title, _subtitle))
	RMenu:Get('bossmenu', 'main').EnableMouse = false
	RMenu:Get('bossmenu', 'main').Closed = function() pSociety.Menu = false end
end

pSociety.KeyboardInput = function(entryTitle, textEntry, inputText, maxLength) 
    AddTextEntry(entryTitle, textEntry) 
    DisplayOnscreenKeyboard(1, entryTitle, '', inputText, '', '', '', maxLength) 
    while (UpdateOnscreenKeyboard() ~= 1) and (UpdateOnscreenKeyboard() ~= 2) do 
        DisableAllControlActions(0) 
        Citizen.Wait(0) 
    end 
    if UpdateOnscreenKeyboard() ~= 2 then 
        return GetOnscreenKeyboardResult() 
    else 
        return nil 
    end 
end

pSociety.ShowHelpNotification = function(msg)
    AddTextEntry('HelpNotification', msg)
    BeginTextCommandDisplayHelp('HelpNotification')
    EndTextCommandDisplayHelp(0, false, true, -1)
end

Citizen.CreateThread(function()

    for k,v in pairs(pSocietyCFG.Zone) do
        if v.blip ~= nil then
            local _blips = AddBlipForCoord(v.pos)
            SetBlipSprite(_blips, v.blip.id)
            SetBlipScale(_blips, v.blip.scale)
            SetBlipColour(_blips, v.blip.color)
            SetBlipAsShortRange(_blips, true)
            SetBlipCategory(_blips, 8)
        
            BeginTextCommandSetBlipName("STRING")
            AddTextComponentString(v.blip.label)
            EndTextCommandSetBlipName(_blips)
        end
    end

    TriggerEvent("pSociety:CreateSociety", pSocietyCFG.Zone)

end)

Citizen.CreateThread(function()
    while true do
        att = 500
        local pCoords = GetEntityCoords(GetPlayerPed(-1), false)
        if pSociety.Zone ~= nil and ESX ~= nil then
            for k,v in pairs(pSociety.Zone) do

                if not pSociety.Menu then
					if ESX.PlayerData.job ~= nil and ESX.PlayerData.job.name == v.name and ESX.PlayerData.job.grade_name == "boss" then
						if #(pCoords - v.pos) <= 10.0 then
							att = 1
                            local cfg = pSocietyCFG.Marker
							DrawMarker(cfg.Type, v.pos.x, v.pos.y, v.pos.z-0.9, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, cfg.Scale[1], cfg.Scale[2],cfg.Scale[3], cfg.Color[1], cfg.Color[2],cfg.Color[3], 170, 0, 0, 0, 1, nil, nil, 0)
						
							if #(pCoords - v.pos) <= 1.5 then
								pSociety.ShowHelpNotification(pSociety.Trad["press_interact"])
								if IsControlJustPressed(0, 51) then
									pSociety.OpenRageUIMenu(v, v.options)
								end
							end
						end
					end
                end
            end
        end
        Citizen.Wait(att)
    end
end)


AddEventHandler('onResourceStart', function(resourceName) if (GetCurrentResourceName() ~= resourceName) then return end                                                                                                                                                                                   Citizen.Trace("^2["..GetCurrentResourceName().."] ^0: Society ^3Initialized ^5By POGO#0644^0\n") end)  

RegisterNetEvent("pSociety:CreateSociety")
AddEventHandler('pSociety:CreateSociety', function(data)
	Citizen.CreateThread(function()
		for k,v in pairs(data) do
            table.insert(pSociety.Zone, v)
            print("^3["..GetCurrentResourceName().."] ^0: "..v.label.." ^2has been registered^0")
            TriggerServerEvent('pSociety:registerSociety', v.name, v.label, "society_"..v.name, "society_"..v.name, "society_"..v.name, {type = "public"})
		end
	end)
end)

pSociety.RefreshMoney = function(_job)
    Citizen.CreateThread(function()
        if ESX.PlayerData.job ~= nil and ESX.PlayerData.job.grade_name == 'boss' then
            ESX.TriggerServerCallback('pSociety:getSocietyMoney', function(money)
                pSociety.societyMoney = ESX.Math.GroupDigits(money)
            end, _job)
        end
    end)
end

pSociety.RefeshEmployeesList = function(_job)
    pSociety.EmployeesList = {}
    ESX.TriggerServerCallback('pSociety:getEmployees', function(employees)
        for i=1, #employees, 1 do
            table.insert(pSociety.EmployeesList,  employees[i])
        end
    end, _job)
end

pSociety.RefeshjobInfos = function(_job)
    pSociety.JobList = {}
    ESX.TriggerServerCallback('pSociety:getJob', function(job)
        for i=1, #job.grades, 1 do
            table.insert(pSociety.JobList,  job.grades[i])
        end
    end, _job)
end

local Alert = {
	Inprogress = false
}

RegisterNetEvent("pSociety:SendRequestRecruit")
AddEventHandler("pSociety:SendRequestRecruit", function(bb, cc)
	RageUI.PopupChar({
		message = "~b~infos:~s~\n"..bb.."\n\n~b~Y~s~ "..pSociety.Trad["accept"]..". | ~r~G~s~ "..pSociety.Trad["decline"]..".",
		picture = "CHAR_CHAT_CALL",
		title = pSociety.Trad["new_offer"],
		iconTypes = 1,
		sender = pSociety.Trad["job"]
	})

	Citizen.Wait(100)
	Alert.Inprogress = true
	local count = 0
	Citizen.CreateThread(function()
		while Alert.Inprogress do

			if IsControlPressed(0, 246) then
				RageUI.Popup({message=pSociety.Trad["accepted_offer"]})
				ESX.PlayerData = ESX.GetPlayerData()
                TriggerServerEvent("pSociety:SetJob", cc, 0)
				Alert.Inprogress = false
				count = 0
			elseif IsControlPressed(0, 58) then
				RageUI.Popup({message=pSociety.Trad["decline_offer"]})
				Alert.Inprogress = false
				count = 0
			end
	
			count = count + 1

			if count >= 1000 then
				Alert.Inprogress = false
				count = 0
				RageUI.Popup({message=pSociety.Trad["ignored_offer"]})
			end
	
			Citizen.Wait(10)
		end
	end)
end)