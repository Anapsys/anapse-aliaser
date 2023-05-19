lua: 
- https://devhints.io/lua
- instance.member(self, arg1, arg2)
- instance:member(arg1, arg2)
	
Aseprite API:
- https://www.aseprite.org/api
- https://www.aseprite.org/api/plugin#plugin

app.activeSprite
local newImage = app.activeImage:clone()

function init(plugin)
  print("Initializing anti-aliaser")

  -- we can use "plugin.preferences" as a table with fields for
  -- our plugin (these fields are saved between sessions)
  --[[
  if plugin.preferences.count == nil then
    plugin.preferences.count = 0
  end
  ]]--

  --
  -- commands, which will be added to the menu
  plugin:newCommand{
    id="AAAlias",
    title="My First Command",
    group="auto_alias_group",
    onclick=function()
      aa();
    end
  }
  --
  -- menu group; add to edit->fx!
  plugin:newMenuGroup{
    id="auto_alias_group",
    title="Antialias",
    group="edit_menu"
  }
  plugin:newMenuSeparator{
    group="aaalias_group"
  }
end

function exit(plugin)
  print("Aseprite is closing my plugin, MyFirstCommand was called "
        .. plugin.preferences.count .. " times")
end