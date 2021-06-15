pSociety.OpenRageUIMenu = function(_society, _options)
    if ESX.PlayerData.job ~= nil and ESX.PlayerData.job.name == _society.name and ESX.PlayerData.job.grade_name == "boss" then
        if pSociety.Menu then
            pSociety.Menu = false
        else
            pSociety.InitRageUIMenu(pSocietyCFG.Title, pSocietyCFG.SubTitle, pSocietyCFG.Banner.Texture, pSocietyCFG.Banner.Name, pSocietyCFG.ColorMenu, pSocietyCFG.Banner.Display)
            pSociety.Menu = true
            local options = {money = true, wash = false,employees = true,grades = true}
            for k,v in pairs(options) do if _options[k] == nil then _options[k] = v end  end
            pSociety.RefreshMoney(_society.name)
            RageUI.Visible(RMenu:Get('bossmenu', 'main'), true)

            Citizen.CreateThread(function()
                local closestPlayer, closestDistance = ESX.Game.GetClosestPlayer()
                while pSociety.Menu do
                    RageUI.IsVisible(RMenu:Get('bossmenu', 'main'), pSocietyCFG.Banner.Display, true, true, function()
                        RageUI.Separator(pSociety.Trad["society"].." :~y~ " .._society.label)

                        if closestPlayer ~= -1  and closestDistance <= 5.0 then
                            RageUI.Button(pSociety.Trad["recruit"], pSociety.Trad["recruit_desc"], {}, true, function(Hovered, Active, Selected)
                                if Active then
                                    local pCoords = GetEntityCoords(GetPlayerPed(closestPlayer))
                                    DrawMarker(2, pCoords.x, pCoords.y, pCoords.z+1.1, 0, 0, 0, 180.0, nil, nil, 0.2, 0.2, 0.2, 255, 255, 255, 170, 0, 1, 0, 0, nil, nil, 0)
                                    if Selected then
                                        TriggerServerEvent("pSociety:RequestSetRecruit", GetPlayerServerId(closestPlayer), _society.name)
                                    end
                                end
                            end)
                        end

                        if _options.money then
                            if pSociety.societyMoney ~= nil then
                                RageUI.Separator(pSociety.Trad["society_money"].." :~b~" ..pSociety.societyMoney.." "..pSociety.Trad["money_symbol"])
                            end
                            RageUI.Button(pSociety.Trad["withdraw_money"], false, {}, true, function(Hovered, Active, Selected)
                                if Selected then
                                    result = pSociety.KeyboardInput("pick", pSociety.Trad["how_much"], "", 8)
                                    if result ~= nil and result ~= "" then
                                        result = ESX.Math.Round(tonumber(result))
                                        if result > 0 then
                                            TriggerServerEvent('pSociety:withdrawMoney', _society.name, result)
                                            SetTimeout(100, function()
                                                pSociety.RefreshMoney(_society.name)
                                            end)
                                        else
                                            RageUI.Popup({message = pSociety.Trad["impossible_action"]})
                                        end
                                    end
                                end
                            end)
    
                            RageUI.Button(pSociety.Trad["deposit_money"], false, {}, true, function(Hovered, Active, Selected)
                                if Selected then
                                    result = pSociety.KeyboardInput("deposit", pSociety.Trad["how_much"], "", 8)
                                    if result ~= nil and result ~= "" then
                                        result = ESX.Math.Round(tonumber(result))
                                        if result > 0 then
                                            TriggerServerEvent('pSociety:depositMoney', _society.name, result)
                                            SetTimeout(100, function()
                                                pSociety.RefreshMoney(_society.name)
                                            end)
                                        else
                                            RageUI.Popup({message = pSociety.Trad["impossible_action"]})
                                        end
                                    end
                                end
                            end)
                        end

                        if _options.wash and _society.percent then
                            RageUI.Button(pSociety.Trad["wash_money"], pSociety.Trad["wash_money_desc"].." (".._society.percent.."%).", {}, true, function(Hovered, Active, Selected)
                                if Selected then
                                    local tax = tonumber("0.".._society.percent)
                                    result = pSociety.KeyboardInput("wash", pSociety.Trad["how_much"], "", 8)
                                    result = tonumber(result)
                                    if result ~= nil and result ~= "" then
                                        if result >= 2 then
                                            result = ESX.Math.Round(tonumber(result*tax))
                                            TriggerServerEvent('pSociety:washMoney', _society.name, result)
                                            SetTimeout(100, function()
                                                pSociety.RefreshMoney(_society.name)
                                            end)
                                        else
                                            RageUI.Popup({message = "~b~Action impossible"})
                                        end
                                    end
                                end
                            end)
                        end

                        if _options.employees then
                            RageUI.Button(pSociety.Trad["manage_employees"], false, {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                                if Selected then
                                    pSociety.RefeshEmployeesList(_society.name)
                                    filterstring = ""
                                end
                            end, RMenu:Get('bossmenu', 'manage_employees'))
                        end
    
                        if _options.grades then
                            RageUI.Button(pSociety.Trad["manage_salary"], pSociety.Trad["manage_salary_desc"], {RightLabel = "→→→"}, true, function(Hovered, Active, Selected)
                                if Selected then
                                    pSociety.RefeshjobInfos(_society.name)
                                end
                            end, RMenu:Get('bossmenu', 'manage_salary'))
                        end
                    end)

                    RageUI.IsVisible(RMenu:Get('bossmenu', 'manage_employees'), pSocietyCFG.Banner.Display, true, true, function()
                        RageUI.Button(pSociety.Trad["search"], false, {RightLabel = filterstring}, true, function(Hovered, Active, Selected)
                            if Selected then
                                filterstring = pSociety.KeyboardInput("entysearch", "~b~"..pSociety.Trad["search"], "", 50)
                            end
                        end)
                        RageUI.Separator("↓↓ ~b~"..pSociety.Trad["list"].."~s~ ↓↓")
    
                        for i=1, #pSociety.EmployeesList do
                            local ply = pSociety.EmployeesList[i]
    
                            if filterstring == nil or string.find(ply.name, filterstring) or string.find(ply.job.grade_label, filterstring) then
                                RageUI.Button(ply.name, false, {RightLabel = "~b~"..ply.job.grade_label.."~s~ →"}, true, function(Hovered, Active, Selected)
                                    if Selected then
                                        pSociety.RefeshjobInfos(_society.name)
                                        SelectedEmployee = ply
                                    end
                                end, RMenu:Get('bossmenu', 'update_employee'))
                            end
                        end
                    end)

                    RageUI.IsVisible(RMenu:Get('bossmenu', 'update_employee'), pSocietyCFG.Banner.Display, true, true, function()

                        RageUI.Separator("↓↓ ~b~"..SelectedEmployee.name.."~s~ ↓↓")
    
                        for i=1, #pSociety.JobList, 1 do
                            local jb = pSociety.JobList[i]
    
                            if SelectedEmployee.job.grade ~= jb.grade then
                                RageUI.Button(jb.label, false, {RightLabel = pSociety.Trad["choose"]}, true, function(Hovered, Active, Selected)
                                    if Selected then
                                        ESX.TriggerServerCallback('pSociety:setJob', function(data)
                                            if data ~= false then
                                                SelectedEmployee.job.grade = jb.grade
                                            end
                                        end, SelectedEmployee.license, _society.name, jb.grade)
                                    end
                                end)
                            else
                                RageUI.Button(jb.label, false, {RightLabel = pSociety.Trad["current"]}, true, function(Hovered, Active, Selected)
                                end)
                            end
                        end
    
                        RageUI.Button(pSociety.Trad["kick_society"], false, {RightBadge = RageUI.BadgeStyle.Alert}, true, function(Hovered, Active, Selected)
                            if Selected then
                                result = pSociety.KeyboardInput("valid", pSociety.Trad["sure"].." ("..pSociety.Trad["yes"]..")", "", 8)
                                if result == pSociety.Trad["yes"] then
                                    ESX.TriggerServerCallback('pSociety:setJob', function()
                                        RageUI.GoBack()
                                    end, SelectedEmployee.license, 'unemployed', 0)
                                end
                            end
                        end)
                    end)

                    RageUI.IsVisible(RMenu:Get('bossmenu', 'manage_salary'), pSocietyCFG.Banner.Display, true, true, function()
                        RageUI.Separator("↓↓ ~b~".._society.label.."~s~ ↓↓")
    
                        for i=1, #pSociety.JobList, 1 do
                            local jb = pSociety.JobList[i]
    
                            RageUI.Button(jb.grade..". "..jb.label, false, {RightLabel = "~g~"..jb.salary.." "..pSociety.Trad["money_symbol"]}, true, function(Hovered, Active, Selected)
                                if Selected then
                                    result = pSociety.KeyboardInput("pick", pSociety.Trad["how_much"], "", 4)
                                    result = ESX.Math.Round(tonumber(result))
                                    if result >= 0 and result <= _society.salary_max then
                                        ESX.TriggerServerCallback('pSociety:setJobSalary', function()
                                            SetTimeout(100, function()
                                                pSociety.RefeshjobInfos(_society.name)
                                            end)
                                        end, _society.name, jb.grade, result)
                                        print(_society.name, jb.grade, result)
                                    else
                                        RageUI.Popup({message = pSociety.Trad["impossible_action"]})
                                    end
                                end
                            end)
                        end
                    end)

                    Citizen.Wait(0)
                end
            end)
        end
    end
end