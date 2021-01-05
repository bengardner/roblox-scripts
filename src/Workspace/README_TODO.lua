--[[

EXIT MINE
 - Set "in_mine" "ObjectValue" in player data that refers to the mine under Workspace.mines.largemine2
   Could also use the mine model name, but that may be less accurate if there is a name collision.
 - Check every few seconds to see if a player is in a mine, set the value
 - Client uses this value to decide whether to display the "exit mine" button.

MINE INFO:
 - Set "mine_level" IntValue under the mine_model
 - Set "mine_time" IntValue under the mine_model
 - Client displays this in the lower-right of screen [Level 1], [Level 2, 1:23 until reset]

ORE DROPS:
 - mini block icon, spin
 - auto-combine same ore type when near another drop (animate? onTouched?)
 - player pickup when close enough
 - ownership?

TOOLS:
 - Find a few more 'gun' models

BAGS:
 - Show bag capacity above coins
 - Show "Bag Full" message when full
 - Do bag contents like Azure mines in popup (list of materials and amount, option to discard some or all)
   + option to auto-discard, never pick up, drop all, drop some
 - Add sell area

Build landscape around the mine(s).

Add a new tool or two.

See about shooting beam(s) from eyes. (tacky)


BEAM tool flow:
 1. client equips tool
 2. client selects or points at a block
 3. client activates the tool
 4. if client has a valid


 1. Client equips tool
 2. Server notes the new tool info, records in PlayerData
 3.

Tool Shop:
 - determine how I want tools to work
   a. base tool has slots, add modules to customize
   b. generic tool, stronger are more expensive
 - bag stuff
 - drones to carry ore from backpack to drop-off location


DRONE CONTROL:
 - create a
]]
