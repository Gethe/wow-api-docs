local ADDON_NAME = ...

-- Lua Globals --
local next = _G.next

-- Libs --
local ACR = _G.LibStub("AceConfigRegistry-3.0")
local ACD = _G.LibStub("AceConfigDialog-3.0")

local app = "WoWAPIDocs"
local apiTable = {
    name = ADDON_NAME,
    type = "group",
    args = {}
}
do -- generate ace config table
    local fieldFormat = "%s: %s"
    local function CreateItemGroup(itemGroup)
        local itemArgs = {}
        if itemGroup then
            for index, field in next, itemGroup do
                _G.print(index, field:GetName(), field:GetFullName())
                local outputString = field:GetLuaType()
                if field:IsOptional() then
                    if field.Default ~= nil then
                        outputString = outputString .. (" (default:%s)"):format(_G.tostring(field.Default));
                    else
                        outputString = outputString .. " (optional)";
                    end
                end
                if field.Documentation then
                    outputString = ("%s - %s"):format(outputString, _G.table.concat(field.Documentation, " "));
                end
                itemArgs[field:GetLoweredName()] = {
                    name = fieldFormat:format(field:GenerateAPILink(), outputString),
                    type = "description",
                    order = index
                }
                --[[local strideIndex = field:GetStrideIndex()
                local docString
                if field.Documentation then
                    docString = _G.table.concat(field.Documentation, " ")
                end
                itemArgs[field:GetLoweredName()] = {
                    name = field:GetName(),
                    type = "group",
                    args = {
                        documentation = {
                            name = "documentation: " .. (docString or ""),
                            type = "description",
                            hidden = not docString,
                            order = 1,
                        },
                        default = {
                            name = "default: " .. _G.tostring(field.Default),
                            type = "description",
                            hidden = field.Default ~= nil,
                            order = 1,
                        },
                        luaType = {
                            name = "luaType: " .. _G.tostring(field:GetLuaType()),
                            type = "description",
                            order = 1,
                        },
                        strideIndex = {
                            name = "strideIndex: " .. (strideIndex or ""),
                            type = "description",
                            hidden = not strideIndex,
                            order = 2,
                        },
                        isOptional = {
                            name = "isOptional: " .. _G.tostring(field:IsOptional()),
                            type = "description",
                            order = 3,
                        },
                        output = {
                            name = "output: " .. field:GetSingleOutputLine(),
                            type = "description",
                            order = 4,
                        },
                    },
                }]]
            end
        end
        return itemArgs
    end

    local function CreateAPIGroup(apiType, apiGroup)
        local groupArgs = {}
        for index, item in next, apiGroup do
            _G.print(index, item:GetName(), item:GetFullName())
            groupArgs[item:GetLoweredName()] = {
                name = item:GetName(),
                type = "group",
                args = {
                    header = {
                        name = item:GetFullName(true, false),
                        type = "header",
                        order = 0
                    },
                    doc = {
                        name = function()
                            if item.Documentation then
                                return _G.table.concat(item.Documentation, " ")
                            else
                                return ""
                            end
                        end,
                        type = "description",
                        hidden = not item.Documentation,
                        order = 1
                    },
                    arguments = {
                        name = "Arguments",
                        type = "group",
                        inline = true,
                        hidden = not item.Arguments,
                        order = 2,
                        args = CreateItemGroup(item.Arguments)
                    },
                    returns = {
                        name = "Returns",
                        type = "group",
                        inline = true,
                        hidden = not item.Returns,
                        order = 3,
                        args = CreateItemGroup(item.Returns)
                    },
                    fields = {
                        name = "Fields",
                        type = "group",
                        inline = true,
                        hidden = not item.Fields,
                        order = 4,
                        args = CreateItemGroup(item.Fields)
                    },
                },
            }
        end
        return groupArgs
    end

    for index, system in next, _G.APIDocumentation.systems do
        _G.print(index, system:GetName(), system:GetFullName())
        apiTable.args[system:GetLoweredName()] = {
            name = system:GetName(),
            type = "group",
            args = {
                functions = {
                    name = "Functions",
                    type = "group",
                    hidden = not system.Functions or #system.Functions == 0,
                    args = CreateAPIGroup("Functions", system.Functions)
                },
                tables = {
                    name = "Tables",
                    type = "group",
                    hidden = not system.Tables or #system.Tables == 0,
                    args = CreateAPIGroup("Tables", system.Tables)
                }
            },
        }
    end


    do -- Explicitly add SharedTypes since they don't have a system
        local name = "SharedTypes"
        local table = {
            _G.APIDocumentation.tables[1],
            _G.APIDocumentation.tables[2],
            _G.APIDocumentation.tables[3],
            _G.APIDocumentation.tables[4]
        }
        apiTable.args[name:lower()] = {
            name = name,
            type = "group",
            args = {
                tables = {
                    name = "Tables",
                    type = "group",
                    args = CreateAPIGroup("Tables", table)
                }
            }
        }
    end
    ACR:RegisterOptionsTable(app, apiTable)
    ACD:SetDefaultSize(app, 800, 600)
end

local function OpenDocs(section, ...)
    _G.print("Open Docs", section, ...)
    if ACD.OpenFrames[app] and not section then
        ACD:Close(app)
    elseif section then
        ACD:SelectGroup(app, section, ...)
    else
        ACD:Open(app)
    end
end
local function ShowSystem(system)
    _G.print("Show system", system)
    for k, v in next, system do
        _G.print(k, v)
    end
    OpenDocs(system:GetLoweredName())
end
local function ShowSearch(matches)
    _G.print("Show search", matches)
    for k, v in next, matches do
        _G.print(k, v)
    end
    OpenDocs()
end

local API_HandleSlash = _G.APIDocumentation.HandleSlashCommand
function _G.APIDocumentation:HandleSlashCommand(command)
    _G.print("HandleSlashCommand", command)
    local commands = { (" "):split(command) };

    if commands[1] == "gui" or ACD.OpenFrames[app] then
        if commands[2] then
            local system = self:FindSystemByName(commands[2])
            if system then
                ShowSystem(system)
            else
                local matches = self:FindAllAPIMatches(commands[2])
                ShowSearch(matches)
            end
        else
            OpenDocs()
        end
    else
        API_HandleSlash(self, command)
    end
end

local API_HandleLink = _G.APIDocumentation.HandleAPILink
function _G.APIDocumentation:HandleAPILink(link, copyAPI)
    local _, type, name, parentName = (":"):split(link);
    local apiInfo = self:FindAPIByName(type, name, parentName);
    if (apiInfo and ACD.OpenFrames[app]) and not copyAPI then
        ShowSystem(apiInfo)
    else
        API_HandleLink(self, link, copyAPI)
    end
end

_G.StaticPopupDialogs["COPY_TO_CLIPBOARD"] = {
    text = _G.CALENDAR_COPY_EVENT,
    button1 = _G.OKAY,
    hasEditBox = 1,
    maxLetters = 31,
    editBoxWidth = 260,
    OnShow = function(self, data)
        self.editBox:SetText(data);
        self.editBox:SetFocus();
    end,
    timeout = 0,
    exclusive = 1,
    whileDead = 1,
    hideOnEscape = 1,
    enterClicksFirstButton = 1
};

function _G.CopyToClipboard(clipboardString)
    _G.StaticPopup_Show("COPY_TO_CLIPBOARD", nil, nil, clipboardString)
end
