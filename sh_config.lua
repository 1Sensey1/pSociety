pSocietyCFG = {

    --[[ Script  ]]

    Language = "fr",

    ESX = "esx:getSharedObject",
    AddonAccount = "esx_addonaccount:getSharedAccount",
    BlackMoney = "black_money",

    --[[ Menu  ]]

    Title = "Society",

    SubTitle = "Boss Menu",

    ColorMenu = {10, 10, 10},

    Banner = {
        Display = true,
        Texture = nil,
        Name = nil,
    },

    Marker = {
        Type = 1,
        Scale = {0.5, 0.5, 0.5},
        Color = {0, 150, 200},
    },

    --[[ Zone ]]

    Zone = {

       --[[  EXEMPLE
        {
            pos = vector3(0.0, 0.0, 0.0),
            name = "jobname",
            label = "Label Of Job",
            salary_max = 1200,
            options = {
                money = true, 
                wash = false, 
                employees = true, 
                grades = true
            },
        }, 
        ]]

        {
            pos = vector3(449.38903808594,-973.76531982422,30.689599990845),
            name = "police",
            label = "Los Santos Police Departement",
            salary_max = 5000,
            options = {
                money = true, 
                wash = false, 
                employees = true, 
                grades = true
            },
            blip = {
                label = "Commissariat", 
                id = 137, 
                color = 38,
                scale = 0.7
            },
        },

        {
            pos = vector3(94.326438903809,-1292.9617919922,29.26876449585),
            name = "unicorn",
            label = "Vanilla Unicorn",
            percent = 50,
            salary_max = 2500,
            options = {
                money = true, 
                wash = true, 
                employees = true, 
                grades = true
            },
            blip = {
                label = "Vanilla Unicorn", 
                id = 121, 
                color = 8,
                scale = 0.7
            },
        },
        
    },
}