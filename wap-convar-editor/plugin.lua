-- God this turned into such a bowl of spaghet but eh here we are
local PAGE_NAME = "convar-editor"
local PAGE_TITLE = "Settings"
local PAGE_ICON = "wrench"

local CV_BOOL, CV_INT, CV_STRING, CV_SLIDER, CV_MULTI, CV_COMBI = 1, 2, 3, 4, 5, 6
-- List of convars
local CONVARS = {
    -- CAT: name, [desc]
    -- BOOL: name, convar, type, default, [label]
    -- INT: name, convar, type, default, [min], [max]
    -- STRING: name, convar, type, default
    -- SLIDER: name, convar, type, default, min, max
    -- COMBI: name, convar, type, default, min, max
    -- MULTI: name, convar, type, items[{name, value}] (first is default)

    {"Server Settings", ""},
    {"Server Name",         "sv_hostname",          CV_STRING,  "My new FXServer!"},
    {"Player Limit",        "sv_maxclients",        CV_COMBI,   32, 1, 128},
    {"Enable OneSync",      "onesync_enabled",      CV_BOOL,    false},

    {"Server Listing"},
    {"Show on server list", "sv_master1",           CV_MULTI,   {
        {"Yes",             "live-internal.fivem.net:30110"},
        {"No",              ""},
    }},
    {"Map Name",            "mapname",              CV_STRING,  "San Andreas"},
    {"Game Mode",           "gametype",             CV_STRING,  "Freeroam"},
    {"Locale",              "locale",               CV_STRING,  "en-us"},
    {"Tags",                "tags",                 CV_STRING,  "freeroam,fivem"},

    {"Scripthook"},
    {"Enable Scripthook",   "sv_scriptHookAllowed", CV_BOOL,    false,  "Allows players to run custom game modifications"},

    {"Authencation", "Control requirements for joining the server"},
    {"Maximum Variance",    "sv_authMaxVariance",   CV_SLIDER,  1, 1, 5},
    {"Minimum Trust",       "sv_authMinTrust",      CV_SLIDER,  5, 1, 5},
}

-- Verify if a convar can be changed (input sanitization)
local function IsConvarSafe(convar)
    for _, data in next, CONVARS do
        if data[3] and data[2] == convar then
            return true, data
        end
    end
    return false, {}
end

-- Input group builder
local function GenerateInputGroup(FAQ, input, left, right)
    return FAQ.Node("div", {class = "input-group mb-3"}, {
        left and FAQ.Node("div", {class = "input-group-prepend"}, left) or "",
        input,
        right and FAQ.Node("div", {class = "input-group-append"}, right) or "",
    })
end

-- Input group select field builder
local function GenerateCustomSelect(FAQ, name, list)
    local options = {}
    for _, entry in next, list do
        table.insert(options, FAQ.Node("option", {value = entry[2]}, entry[1]))
    end
    return FAQ.Node("select", {class = "custom-select", name = name}, options)
end

-- Input group checkbox field builder
local function FormInputCheckbox(FAQ, name, checked, label, inline)
    return FAQ.Node("div", {class = "form-check" .. (inline and " form-check-inline" or "")}, {
        FAQ.Node("input", {class = "form-check-input", name = name, type = "checkbox", value = (checked and "true" or "false"), checked = (checked and "true" or nil)}, ""),
        label and FAQ.Node("label", {class = "form-check-label"}, label) or "",
    })
end

-- Main page creator
function CreatePage(FAQ, data, add)
    if data.convar then
        local safe, convar = IsConvarSafe(data.convar)
        if not safe then
            add(FAQ.Alert("danger", "Invalid convar name"))
        else
            local oldvar = GetConvar(data.convar)
            oldvar = (oldvar == "" and "[nothing]" or oldvar)
            if convar[3] == CV_BOOL then
                if data.value then data.value = "true" end
                if not data.value then data.value = "false" end
            end
            local newvar = (data.value == "" and "[nothing]" or data.value)
            if tostring(oldvar) == tostring(data.value) then
                add(FAQ.Alert("warning", FAQ.Nodes({"The value of ", FAQ.Node("strong", {}, convar[2]), " is already set to ", FAQ.Node("code", {}, oldvar)})))
            else
                SetConvar(data.convar, data.value)
                add(FAQ.Alert("info", FAQ.Nodes({"Updated ", FAQ.Node("strong", {}, convar[2]), " from ", FAQ.Node("code", {}, oldvar), " to ", FAQ.Node("code", {}, newvar)})))
            end
        end
    end
    for _, convar in next, CONVARS do
        local cvtype, cvname = convar[3], convar[2]
        if not cvtype then
            -- Header
            local title, subtitle = convar[1], convar[2]
            local header = FAQ.Node("h2", {}, title)
            if subtitle then
                header = FAQ.Nodes({
                    header,
                    FAQ.Node("h5", {class = "text-muted"}, subtitle)
                })
            end
            add(header)
            add(FAQ.Node("hr", {}, ""))
        elseif cvtype == CV_BOOL then
            -- Toggle switch
            local title, name, default, label = convar[1], convar[2], convar[4], convar[5]
            local cvval = tostring(GetConvar(name) or default)
            local checked = (cvval == "true" or cvval == "1")
            local form = FAQ.Form(PAGE_NAME, {convar = name}, GenerateInputGroup(FAQ, {
                FAQ.Node("span", {class = "input-group-text form-control"}, {
                    FormInputCheckbox(FAQ, "value", checked, label or "Yes / No", true)
                }),
            }, {
                FAQ.Node("span", {class = "input-group-text", style = "min-width: 148px;"}, title),
            }, FAQ.Button("primary", {
                "Update ", FAQ.Icon("sync-alt")
            }, {type = "submit"})))
            add(form)
        elseif cvtype == CV_INT then
            -- Number input
            local title, name, default, min, max = convar[1], convar[2], convar[4], convar[5], convar[6]
            local cvval = tostring(GetConvar(name) or default)
            local form = FAQ.Form(PAGE_NAME, {convar = name}, GenerateInputGroup(FAQ, FAQ.Node("input", {
                type = "number",
                class = "form-control",
                name = "value",
                value = cvval,
                min = min,
                max = max,
                placeholder = default or "",
            }, ""), FAQ.Node("span", {class = "input-group-text", style = "min-width: 148px;"}, title), FAQ.Button("primary", {
                "Update ", FAQ.Icon("sync-alt")
            }, {type = "submit"})))
            add(form)
        elseif cvtype == CV_COMBI then
            -- Combined number slider input
            local title, name, default, min, max = convar[1], convar[2], convar[4], convar[5], convar[6]
            local cvval = tostring(GetConvar(name) or default)
            local form = FAQ.Form(PAGE_NAME, {convar = name}, {
                FAQ.Node("input", {
                    type = "hidden",
                    name = "value",
                    id = name,
                    value = cvval,
                }, ""),
                GenerateInputGroup(FAQ, {
                    FAQ.Node("span", {class = "input-group-text form-control"}, FAQ.Node("input", {
                        type = "range",
                        id = name .. "_range",
                        class = "custom-range",
                        value = cvval,
                        min = min,
                        max = max,
                        step = "1",
                        placeholder = default or "",
                        oninput = [[document.getElementById(']]..name..[[').value = this.value; document.getElementById(']]..name..[[_number').value = this.value]],
                        onchange = [[document.getElementById(']]..name..[[').value = this.value; document.getElementById(']]..name..[[_number').value = this.value]],
                    }, "")),
                }, FAQ.Node("span", {class = "input-group-text", style = "min-width: 148px;"}, title), {
                    FAQ.Node("input", {
                        type = "number",
                        id = name .. "_number",
                        class = "form-control",
                        value = cvval,
                        min = min,
                        max = max,
                        placeholder = default or "",
                        oninput = [[document.getElementById(']]..name..[[').value = this.value; document.getElementById(']]..name..[[_range').value = this.value]],
                        onchange = [[document.getElementById(']]..name..[[').value = this.value; document.getElementById(']]..name..[[_range').value = this.value]],
                    }, ""),
                    FAQ.Button("primary", {
                        "Update ", FAQ.Icon("sync-alt")
                    }, {type = "submit"}),
                })
            })
            add(form)
        elseif cvtype == CV_STRING then
            -- Text input
            local title, name, default = convar[1], convar[2], convar[4]
            local cvval = tostring(GetConvar(name) or default)
            local form = FAQ.Form(PAGE_NAME, {convar = name}, GenerateInputGroup(FAQ, FAQ.Node("input", {
                type = "text",
                class = "form-control",
                name = "value",
                value = cvval,
                placeholder = default or "",
            }, ""), FAQ.Node("span", {class = "input-group-text", style = "min-width: 148px;"}, title), FAQ.Button("primary", {
                "Update ", FAQ.Icon("sync-alt")
            }, {type = "submit"})))
            add(form)
        elseif cvtype == CV_SLIDER then
            -- Slider
            local title, name, default, min, max = convar[1], convar[2], convar[4], convar[5], convar[6]
            local cvval = GetConvarInt(name) or default
            local form = FAQ.Form(PAGE_NAME, {convar = name}, GenerateInputGroup(FAQ, {
                FAQ.Node("span", {class = "input-group-text form-control"}, FAQ.Node("input", {
                    type = "range",
                    class = "custom-range",
                    name = "value",
                    value = cvval,
                    min = min,
                    max = max,
                    step = "1",
                    placeholder = default or "",
                    oninput = [[document.getElementById(']]..name..[[').innerHTML = this.value]],
                    onchange = [[document.getElementById(']]..name..[[').innerHTML = this.value]],
                }, "")),
            }, {
                FAQ.Node("span", {class = "input-group-text", style = "min-width: 148px;"}, title),
            }, {
                FAQ.Node("span", {class = "input-group-text"}, {
                    FAQ.Node("span", {id = name}, cvval),
                    FAQ.Node("span", {style = "margin-left: 5px; margin-right: 5px;"}, "/"),
                    FAQ.Node("span", {}, max),
                }),
                FAQ.Button("primary", {
                    "Update ", FAQ.Icon("sync-alt")
                }, {type = "submit"}),
            }))
            add(form)
        elseif cvtype == CV_MULTI then
            -- Dropdown
            local title, name, list = convar[1], convar[2], convar[4]
            local dropdown = {}
            local cvval = tostring(GetConvar(name) or default)
            local current = nil
            for _, entry in next, list do
                if cvval == entry[2] then
                    current = {entry[1], entry[2]}
                else
                    table.insert(dropdown, {entry[1], entry[2]})
                end
            end
            if current then
                table.insert(dropdown, 1, current)
            end
            local form = FAQ.Form(PAGE_NAME, {convar = name}, GenerateInputGroup(FAQ, GenerateCustomSelect(FAQ, "value", dropdown), FAQ.Node("span", {class = "input-group-text", style = "min-width: 148px;"}, title), FAQ.Button("primary", {
                "Update ", FAQ.Icon("sync-alt")
            }, {type = "submit"})))
            add(form)
        end
    end
    return true, "OK"
end

-- Automatically sets up a page and sidebar option based on the above configurations
Citizen.CreateThread(function()
    local FAQ = exports['webadmin-lua']:getFactory()
    exports['webadmin']:registerPluginOutlet("nav/sideList", function(data) --[[R]]--
        if not exports['webadmin']:isInRole("webadmin."..PAGE_NAME..".view") then return "" end
        return FAQ.SidebarOption(PAGE_NAME, PAGE_ICON, PAGE_TITLE) --[[R]]--
    end)
    exports['webadmin']:registerPluginPage(PAGE_NAME, function(data) --[[E]]--
        if not exports['webadmin']:isInRole("webadmin."..PAGE_NAME..".view") then return "" end
        return FAQ.Nodes({ --[[R]]--
            FAQ.PageTitle(PAGE_TITLE),
            FAQ.BuildPage(CreatePage, data), --[[R]]--
        })
    end)
end)
