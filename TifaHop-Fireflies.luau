-- Standalone TifaHop Fireflies. No other farm workers or recovered VM.
local shared=(getgenv and getgenv()) or getfenv()
local options=... or shared.TifaHopFireflyConfig
if not game:IsLoaded() then game.Loaded:Wait() end
local players=game:GetService("Players")
while not players.LocalPlayer do task.wait() end
local player=players.LocalPlayer
local http=game:GetService("HttpService")
local configPath="TifaHop/fireflies_"..player.UserId..".json"
if options==nil and readfile and isfile and isfile(configPath) then
 local ok,saved=pcall(function() return http:JSONDecode(readfile(configPath)) end)
 if ok then options=saved end
end
options=options or {}
local config={WalkSpeedEnabled=options.WalkSpeedEnabled~=false,WalkSpeed=math.clamp(tonumber(options.WalkSpeed) or 50,1,100),UseRedCannon=options.UseRedCannon~=false,DontHop=options.DontHop==true,AutoStart=options.AutoStart==true,Movement=options.Movement=="Tween" and "Tween" or "Walk",TweenSpeed=math.clamp(tonumber(options.TweenSpeed) or 8,4,12)}
config.Group=type(options.Group)=="string" and options.Group:match("^%s*(.-)%s*$") or ""
config.MainAccount=type(options.MainAccount)=="string" and options.MainAccount:match("^%s*(.-)%s*$") or ""
config.RelayURL=type(options.RelayURL)=="string" and options.RelayURL or "https://ntfy.sh"
config.VisitedServers=type(options.VisitedServers)=="table" and options.VisitedServers or {}
local function saveConfig()
 shared.TifaHopFireflyConfig=config
 if writefile and makefolder and isfolder then pcall(function()
  if not isfolder("TifaHop") then makefolder("TifaHop") end
  writefile(configPath,http:JSONEncode(config))
 end) end
end
local generation,running=0,false
local farmingActive=false
local statusLabel,startButton,hopButton,groupLabel
local stop,start
local function setStatus(message) if statusLabel then statusLabel.Text=message end end
local UserConfig={tweenmovement=config.Movement=="Tween",tweenspeed=config.TweenSpeed}
local speedSettings=UserConfig
local useRedCannon=config.UseRedCannon
local speedHuman,oldSpeed,writtenSpeed
local function refreshWalkingSpeed()
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if humanoid and humanoid.Health>0 then
  if speedHuman~=humanoid then speedHuman=humanoid;oldSpeed=humanoid.WalkSpeed end
  if config.WalkSpeedEnabled then humanoid.WalkSpeed=config.WalkSpeed;writtenSpeed=config.WalkSpeed
  elseif writtenSpeed and humanoid.WalkSpeed==writtenSpeed then humanoid.WalkSpeed=oldSpeed;writtenSpeed=nil end
 end
end
local navigationInput={pressKey=function(key)
 local input=game:GetService("VirtualInputManager")
 input:SendKeyEvent(true,key,false,game);task.wait(0.05);input:SendKeyEvent(false,key,false,game)
end}

local function updateSpeedSetting(key,value)
 local number=tonumber(value)
 if not number or number~=number or number==math.huge or number==-math.huge then return false end
 if key=="WalkSpeed" then config.WalkSpeed=math.clamp(math.floor(number+0.5),1,100)
 elseif key=="TweenSpeed" then config.TweenSpeed=math.clamp(math.floor(number+0.5),4,12);UserConfig.tweenspeed=config.TweenSpeed
 else return false end
 if running then refreshWalkingSpeed() end
 saveConfig()
 return true
end

local routeNodes = {
  [70] = Vector3.new(141, 18, -22),
  [326] = Vector3.new(146, 2, 94),
  [361] = Vector3.new(237, 2, 94),
  [411] = Vector3.new(-372, 66, -71),
  [438] = Vector3.new(-333, 66, -188),
  [570] = Vector3.new(-190, 66, -188),
  [577] = Vector3.new(-190, 66, -97),
  [685] = Vector3.new(160, 31, 202),
  [777] = Vector3.new(291, 49, 198),
  [973] = Vector3.new(72, 174, -189),
  [1617] = Vector3.new(-383, 88, -219),
  [1737] = Vector3.new(262, 66, -169),
  [1792] = Vector3.new(195, 66, -126),
  [1876] = Vector3.new(-311, 18, 129),
  [2426] = Vector3.new(-42, 18, -35),
  [2489] = Vector3.new(103, 63, 285),
  [2524] = Vector3.new(-179, 18, -9),
  [2584] = Vector3.new(417, 94, -169),
  [2743] = Vector3.new(40, 33, 426),
  [3171] = Vector3.new(-103, 119, -81),
  [3362] = Vector3.new(-366, 116, 19),
}
local redCannonProfiles = {
  ["20BeeGate"]={Node=2743,Delay=0.6,Flight=5.0,Glide=true,OffsetZ=0},
  ["Badge Guild"]={Node=411,Delay=0.95,Flight=4.7,Glide=true,OffsetZ=0},
  ["Bamboo Field"]={Node=70,Delay=1.25,Flight=2.0,Glide=true,OffsetZ=0},
  ["Blue Flower Field"]={Node=326,Delay=0.7,Flight=3.3,Glide=true,OffsetZ=0},
  ["Blue HQ"]={Node=361,Delay=0.7,Flight=4.4,Glide=true,OffsetZ=0},
  ["Brown Bear"]={Node=777,Delay=1.4,Flight=6.0,Glide=true,OffsetZ=0},
  ["Cactus Field"]={Node=577,Delay=0.95,Flight=2.7,Glide=true,OffsetZ=0},
  ["Clover Field"]={Node=685,Delay=0.5,Flight=4.0,Glide=true,OffsetZ=0},
  ["Honey Bee"]={Node=1617,Delay=1.15,Flight=6.0,Glide=true,OffsetZ=0},
  ["Mountain Top Field"]={Node=973,Delay=2.25,Flight=0,Glide=false,OffsetZ=0},
  ["Mythic Meteor Shower"]={Node=3362,Delay=0.95,Flight=0,Glide=true,OffsetZ=0},
  ["Pine Tree Forest"]={Node=438,Delay=0.925,Flight=5.0,Glide=true,OffsetZ=0},
  ["Pineapple Patch"]={Node=1737,Delay=1.85,Flight=3.0,Glide=true,OffsetZ=20},
  ["Polar Bear"]={Node=3171,Delay=1.2,Flight=1.4,Glide=true,OffsetZ=0},
  ["Pumpkin Patch"]={Node=570,Delay=0.95,Flight=3.5,Glide=true,OffsetZ=0},
  ["Rose Field"]={Node=1876,Delay=0.55,Flight=3.0,Glide=true,OffsetZ=0},
  ["Spider Field"]={Node=2426,Delay=0.9,Flight=0.3,Glide=true,OffsetZ=0},
  ["Star Hall"]={Node=2489,Delay=0.75,Flight=4.15,Glide=true,OffsetZ=0},
  ["Strawberry Field"]={Node=2524,Delay=0.7,Flight=1.8,Glide=true,OffsetZ=0},
  ["Stump Field"]={Node=2584,Delay=1.85,Flight=5.4,Glide=true,OffsetZ=0},
  ["Treat Dispenser"]={Node=1792,Delay=1.6,Flight=2.3,Glide=true,OffsetZ=0},
}
-- Atlas-style map routing: authored inter-field routes and grounded final legs.
local redCannonReady, travelRedCannon, preferredCannonTravel
local fieldUnder
local function horizontalDistance(a,b)
  return Vector3.new(a.X-b.X,0,a.Z-b.Z).Magnitude
end
local function routeFilter()
  local include={}
  for _,name in ipairs({"Map","Gates"}) do
    local object=workspace:FindFirstChild(name)
    if object then table.insert(include,object) end
  end
  if workspace:FindFirstChild("Terrain") then table.insert(include,workspace.Terrain) end
  local params=RaycastParams.new()
  params.FilterType=Enum.RaycastFilterType.Include
  params.FilterDescendantsInstances=include
  params.RespectCanCollide=true
  return params
end
local function connectorClear(from,to,params)
  return workspace:Raycast(from+Vector3.new(0,1,0),to-from,params)==nil
end
local function tweenMapTo(destination,isRunning,setStatus)
  local character=player.Character
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  local root=character and character:FindFirstChild("HumanoidRootPart")
  if not root or not humanoid or humanoid.Health<=0 then return false end
  local speed=math.clamp(tonumber((speedSettings or UserConfig).tweenspeed) or 8,4,12)
  local duration=(destination-root.Position).Magnitude/(speed*10) -- original scale: setting 8 = 80 studs/sec
  if duration<0.02 then return isRunning() end
  setStatus("Tweening to destination")
  humanoid:MoveTo(root.Position)
  local tween=game:GetService("TweenService"):Create(root,TweenInfo.new(duration,Enum.EasingStyle.Linear),{CFrame=CFrame.new(destination)*root.CFrame.Rotation})
  local done=false
  local connection=tween.Completed:Connect(function() done=true end)
  tween:Play()
  local deadline=os.clock()+duration+2
  while not done and os.clock()<deadline do
    if not isRunning() or player.Character~=character or not root.Parent or humanoid.Health<=0 or not (speedSettings or UserConfig).tweenmovement then
      tween:Cancel(); connection:Disconnect(); return false
    end
    game:GetService("RunService").Heartbeat:Wait()
  end
  tween:Cancel(); connection:Disconnect()
  return isRunning() and player.Character==character and humanoid.Health>0 and (root.Position-destination).Magnitude<=7
end
local function walkMapTo(destination,isRunning,setStatus,allowCannon,forceWalk)
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not root or not humanoid then return false end
 local function active() return isRunning() and player.Character==character and root.Parent~=nil and humanoid.Health>0 end
 local zone=fieldUnder(destination)
 if zone and zone.Name=="Pepper Patch" then forceWalk=true;allowCannon=false end
 if not active() then return false end
 refreshWalkingSpeed()
 if (root.Position-destination).Magnitude<=3 then return true end
 if config.Movement=="Walk" and allowCannon~=false and useRedCannon and preferredCannonTravel then
  local handled,result=preferredCannonTravel(destination,active,setStatus)
  if handled then return result end
 end
 if not forceWalk and config.Movement=="Tween" then return tweenMapTo(destination,active,setStatus) end
 local heartbeat=game:GetService("RunService").Heartbeat
 local params=routeFilter()
 local function clearCorridor(position)
  if not connectorClear(root.Position,position,params) then return false end
  local dx,dz=position.X-root.Position.X,position.Z-root.Position.Z
  local length=math.sqrt(dx*dx+dz*dz)
  if length<1 then return true end
  for sample=1,math.max(1,math.ceil(length/8)) do
   local fraction=sample/math.max(1,math.ceil(length/8))
   local position=root.Position+(position-root.Position)*fraction
   if not workspace:Raycast(position+Vector3.new(0,3,0),Vector3.new(0,-12,0),params) then return false end
  end
  local side=Vector3.new(-dz/length*1.4,0,dx/length*1.4)
  return connectorClear(root.Position+side,position+side,params) and connectorClear(root.Position-side,position-side,params)
 end
 local function follow(points)
  local index,lastIssued,lastPosition=1,-math.huge,nil
  local best,lastProgress=math.huge,os.clock()
  local routeDeadline=os.clock()+90
  while active() and index<=#points and os.clock()<routeDeadline do
   local point=points[index]
   if point.Action==Enum.PathWaypointAction.Jump and not lastPosition then humanoid.Jump=true end
   local reach=index==#points and 2.5 or math.clamp(humanoid.WalkSpeed*0.10,3,6)
   if horizontalDistance(root.Position,point.Position)<=reach and math.abs(root.Position.Y-point.Position.Y)<=6 then
    index+=1;lastPosition=nil;best=math.huge;lastProgress=os.clock()
   else
    -- Merge clear, level walking sections. Never skip a jump or a blocked corner.
    if not lastPosition then
     if point.Action~=Enum.PathWaypointAction.Jump then
      for candidate=index+1,math.min(index+8,#points) do
       local nextPoint=points[candidate]
       if nextPoint.Action==Enum.PathWaypointAction.Jump or horizontalDistance(root.Position,nextPoint.Position)>45 or math.abs(root.Position.Y-nextPoint.Position.Y)>4 or not clearCorridor(nextPoint.Position) then break end
       index=candidate;point=nextPoint
      end
     end
     lastPosition=point.Position;best=(root.Position-lastPosition).Magnitude;lastProgress=os.clock()
     humanoid:MoveTo(lastPosition);lastIssued=os.clock()
     if point.Action==Enum.PathWaypointAction.Jump then humanoid.Jump=true end
    end
    local distance=(root.Position-lastPosition).Magnitude
    if distance<best-0.25 then best=distance;lastProgress=os.clock() end
    if os.clock()-lastProgress>3 then return false end
    if os.clock()-lastIssued>2 then humanoid:MoveTo(lastPosition);lastIssued=os.clock() end
    heartbeat:Wait()
   end
  end
  return active() and index>#points and horizontalDistance(root.Position,destination)<=3 and math.abs(root.Position.Y-destination.Y)<=7
 end
 if horizontalDistance(root.Position,destination)<=45 and math.abs(root.Position.Y-destination.Y)<5 and clearCorridor(destination) then
  if follow({{Position=destination,Action=Enum.PathWaypointAction.Walk}}) then return true end
 end
 for attempt=1,3 do
  if not active() then break end
  setStatus("Computing walking route "..attempt.."/3")
  local path=game:GetService("PathfindingService"):CreatePath({AgentRadius=attempt==2 and 1.5 or 2,AgentHeight=5,AgentCanJump=true,WaypointSpacing=8})
  local goal=attempt==3 and destination+Vector3.new(0,2,0) or destination
  local ok=pcall(function() path:ComputeAsync(root.Position,goal) end)
  if ok and path.Status==Enum.PathStatus.Success and follow(path:GetWaypoints()) then return true end
 end
 if root.Parent and humanoid.Health>0 then humanoid:MoveTo(root.Position) end
 return false
end
fieldUnder=function(position)
 local zones=workspace:FindFirstChild("FlowerZones")
 if not zones then return nil end
 local best,bestHeight=nil,math.huge
 for _,zone in ipairs(zones:GetChildren()) do
  if zone:IsA("BasePart") then
   local p=zone.CFrame:PointToObjectSpace(position)
   local height=position.Y-zone.Position.Y
   if math.abs(p.X)<=zone.Size.X/2 and math.abs(p.Z)<=zone.Size.Z/2 and height>=-6 and height<=45 and math.abs(height)<bestHeight then
    best,bestHeight=zone,math.abs(height)
   end
  end
 end
 return best
end

-- Only the game's visible activation prompt and normal E-key input are used.
-- This helper never invokes game remotes or changes the player's position.
local function visibleActivatePrompt()
  local gui=player:FindFirstChild("PlayerGui")
  local screen=gui and gui:FindFirstChild("ScreenGui")
  local button=screen and screen:FindFirstChild("ActivateButton")
  if not button or button.Visible==false then return nil end
  if button.Position and button.Position.Y.Offset<0 then return nil end
  local text=button:FindFirstChild("TextBox")
  return text and text.Text or nil
end
local function normalActivateAt(position,expected,isRunning)
  if not isRunning() then return false end
  local character=player.Character
  local root=character and character:FindFirstChild("HumanoidRootPart")
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  if not root or not humanoid or humanoid.Health<=0 then return false end
  if (root.Position-position).Magnitude>8 or math.abs(root.Position.Y-position.Y)>6 then return false end
  if visibleActivatePrompt()~=expected then return false end
  if not navigationInput or type(navigationInput.pressKey)~="function" then return false end
  -- Recheck proximity immediately before sending the key, after reading UI.
  if not isRunning() or player.Character~=character or (root.Position-position).Magnitude>8 then return false end
  navigationInput.pressKey(Enum.KeyCode.E)
  return true
end

-- Red Cannon timing profiles come from the supplied Atlas route handlers.
-- Walk to the actual platform, require the genuine activation prompt, and
-- use the existing input API. A failed launch disables shortcuts this session.
local cannonUnavailable=false
redCannonReady=function()
  if cannonUnavailable or not navigationInput or type(navigationInput.pressKey)~="function" then return false end
  local toys=workspace:FindFirstChild("Toys")
  local cannon=toys and toys:FindFirstChild("Red Cannon")
  return cannon and cannon:FindFirstChild("Platform")~=nil
end
travelRedCannon=function(point,isRunning,setStatus)
  local label=point.Label:sub(11)
  local profile=redCannonProfiles[label]
  if not profile or not redCannonReady() then return false end
  local character=player.Character
  local humanoid=character and character:FindFirstChildOfClass("Humanoid")
  local root=character and character:FindFirstChild("HumanoidRootPart")
  if not humanoid or not root then return false end
  local function active() return isRunning() and player.Character==character and humanoid.Health>0 end
  local heartbeat=game:GetService("RunService").Heartbeat
  local function waitFor(seconds)
    local untilTime=os.clock()+seconds
    while active() and os.clock()<untilTime do heartbeat:Wait() end
    return active()
  end
  local platform=workspace.Toys["Red Cannon"].Platform
  local approached=os.clock()
  while active() and (root.Position-platform.Position).Magnitude>7 and os.clock()-approached<4 do
    humanoid:MoveTo(platform.Position); heartbeat:Wait()
  end
  if not active() then return false end
  local activated=false; local promptDeadline=os.clock()+2
  while active() and os.clock()<promptDeadline do
    if normalActivateAt(platform.Position,"Fire the Red Cannon",active) then activated=true;break end
    heartbeat:Wait()
  end
  if not activated then
    cannonUnavailable=true
    setStatus("Red Cannon unavailable; using walking routes")
    return false
  end
  setStatus("Red Cannon to "..label)
  local launchPosition=root.Position
  if not waitFor(profile.Delay) then return false end
  if (root.Position-launchPosition).Magnitude<15 and (root.Position-point.Position).Magnitude>20 then
    cannonUnavailable=true
    setStatus("Red Cannon did not launch; replanning on foot")
    return false
  end
  if profile.Glide then
    if type(navigationInput.pressKey)~="function" then cannonUnavailable=true; return false end
    navigationInput.pressKey(Enum.KeyCode.Space)
    navigationInput.pressKey(Enum.KeyCode.Space)
    humanoid:MoveTo(point.Position+Vector3.new(0,0,profile.OffsetZ))
    local flightUntil=os.clock()+profile.Flight
    while active() and os.clock()<flightUntil do
      humanoid:MoveTo(point.Position+Vector3.new(0,0,profile.OffsetZ))
      heartbeat:Wait()
    end
    if not active() then
      pcall(navigationInput.pressKey,Enum.KeyCode.Space)
      return false
    end
    navigationInput.pressKey(Enum.KeyCode.Space)
    humanoid:MoveTo(root.Position)
  end
  local landingDeadline=os.clock()+12
  while active() and humanoid.FloorMaterial==Enum.Material.Air and os.clock()<landingDeadline do heartbeat:Wait() end
  if not active() then return false end
  if humanoid.FloorMaterial==Enum.Material.Air or horizontalDistance(root.Position,point.Position)>100
    or math.abs(root.Position.Y-point.Position.Y)>35 then
    cannonUnavailable=true
    setStatus("Red Cannon landing missed; replanning on foot")
    return false
  end
  return true
end

-- Select once for inter-field travel; do not let cost replanning discard the launch.
preferredCannonTravel=function(destination,isRunning,setStatus)
  local originalRunning=isRunning
  isRunning=function() return originalRunning() and config.Movement=="Walk" and config.UseRedCannon end
  local character=player.Character
  local root=character and character:FindFirstChild("HumanoidRootPart")
  if not root or not isRunning() then return true,false end
  local destinationField=fieldUnder(destination)
  local currentField=fieldUnder(root.Position)
  if destinationField and destinationField.Name=="Pepper Patch" then return false end
  -- Local positioning and collection should not return to the cannon.
  if (destination-root.Position).Magnitude<45 or (destinationField and destinationField==currentField) then return false end
  if not redCannonReady() then return false end
  local label,score=nil,math.huge
  for name,profile in pairs(redCannonProfiles) do
    local position=routeNodes[profile.Node]
    if position then
      local distance=(position-destination).Magnitude
      if destinationField and name==destinationField.Name then label=name; break end
      if distance<score then label=name; score=distance end
    end
  end
  if not label then return false end
  local platform=workspace.Toys["Red Cannon"].Platform
  setStatus("Walking to Red Cannon for "..(destinationField and destinationField.Name or label))
  if not walkMapTo(platform.Position+Vector3.new(0,3,0),isRunning,setStatus,false) then return true,false end
  if not isRunning() then return true,false end
  if not travelRedCannon({Label="RedCannon:"..label,Position=destination},isRunning,setStatus) then
    setStatus("Red Cannon route failed; travel stopped")
    return true,false
  end
  -- Finish the landing locally without scheduling another cannon trip.
  return true,walkMapTo(destination,isRunning,setStatus,false)
end

-- Walk to a vacant hive and press E only at its visible Claim Hive prompt.
local function confirmedHive()
  local honeycomb=player:FindFirstChild("Honeycomb")
  local owned=honeycomb and honeycomb.Value
  if owned and owned.Parent then
    local owner=owned:FindFirstChild("Owner")
    if owner and owner.Value~=player then owned=nil end
  end
  if not owned or not owned.Parent then
    owned=nil
    local platforms=workspace:FindFirstChild("HivePlatforms")
    if platforms then
      for _,platform in ipairs(platforms:GetChildren()) do
        local reference=platform:FindFirstChild("PlayerRef")
        if reference and reference.Value==player then owned=platform; break end
      end
    end
    if not owned then
      local hives=workspace:FindFirstChild("Honeycombs")
      if hives then
        for _,hive in ipairs(hives:GetChildren()) do
          local owner=hive:FindFirstChild("Owner")
          if owner and owner.Value==player then owned=hive; break end
        end
      end
    end
  end
  if not owned then return nil end
  -- The reference also waits for the player's spawn position to become valid.
  local spawn=player:FindFirstChild("SpawnPos")
  if spawn and spawn.Value and spawn.Value.Position.Y<0 then return nil end
  return owned
end
local function farmTargetPresent(target)
  if not target or not target.Parent then return false end
  local humanoid=target.FindFirstChildOfClass and target:FindFirstChildOfClass("Humanoid")
  return not humanoid or humanoid.Health>0
end
local function ensureHiveClaimed(isRunning,setStatus,hasTarget)
  local running=isRunning
  isRunning=function() return running() and type(hasTarget)=="function" and hasTarget() end
  if not isRunning() then return false end
  if confirmedHive() then return true end
  setStatus("Farm target found; claiming a hive")
  local hives=workspace:FindFirstChild("Honeycombs")
  if not hives then setStatus("Hive locations are not loaded"); return false end
  local character=player.Character
  local root=character and character:FindFirstChild("HumanoidRootPart")
  if not root then return false end
  local candidates={}
  for _,hive in ipairs(hives:GetChildren()) do
    local owner=hive:FindFirstChild("Owner")
    local arrow=hive:FindFirstChild("patharrow")
    local base=arrow and arrow:FindFirstChild("Base")
    if owner and owner.Value==nil and base then
      table.insert(candidates,{hive=hive,distance=(base.Position-root.Position).Magnitude})
    end
  end
  table.sort(candidates,function(a,b) return a.distance<b.distance end)
  for _,candidate in ipairs(candidates) do
    local hive=candidate.hive
    if not isRunning() then return false end
    if confirmedHive() then return true end
    local owner=hive:FindFirstChild("Owner")
    local arrow=hive:FindFirstChild("patharrow")
    local base=arrow and arrow:FindFirstChild("Base")
    if owner and owner.Value==nil and base then
      setStatus("Walking to an empty hive")
      if walkMapTo(base.Position,isRunning,setStatus,false,true) then -- hive claiming is walking-only
        for attempt=1,3 do
          if not isRunning() then return false end
          if confirmedHive() then return true end
          if owner.Value~=nil then break end
          setStatus("Claiming hive with E")
          if normalActivateAt(base.Position,"Claim Hive",isRunning) then
            local deadline=os.clock()+3
            repeat
              if not isRunning() then return false end
              if confirmedHive() then setStatus("Hive claimed"); return true end
              task.wait(0.1)
            until os.clock()>=deadline
          else task.wait(0.2) end
        end
      end
    end
  end
  setStatus("Cannot confirm hive ownership; farming is paused")
  warn("[TifaHop] Claim an available hive before starting; farming was not started")
  return false
end

-- Atlas firefly behavior: NPCBees/Firefly, stationary BodyVelocity, night
-- window 19:00..05:00, two-second revisit suppression, and token looting.
local function findStationaryFirefly(recent,blocked,preferredField)
  local folder=workspace:FindFirstChild("NPCBees")
  local character=player.Character
  local root=character and character:FindFirstChild("HumanoidRootPart")
  if not folder or not root then return nil end
  local best,bestDistance=nil,math.huge
  for _,fly in ipairs(folder:GetChildren()) do
    if fly.Name=="Firefly" and fly.Parent then
      local velocity=fly:FindFirstChild("BodyVelocity")
      if velocity and velocity.Velocity.Magnitude==0
        and (not recent[fly] or os.clock()-recent[fly]>=2)
        and (not blocked[fly] or os.clock()>=blocked[fly]) then
        local distance=(fly.Position-root.Position).Magnitude
        if distance<bestDistance and fieldUnder(fly.Position) and (not preferredField or fieldUnder(fly.Position)==preferredField) then best,bestDistance=fly,distance end
      end
    end
  end
  return best
end

local function nightTime()
 local time=game:GetService("Lighting").ClockTime
 return time>=19 or time<=5
end
local function dig()
 local character=player.Character
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if not humanoid or humanoid.Health<=0 then return end
 local tool=character:FindFirstChildOfClass("Tool")
 if not tool then
  local backpack=player:FindFirstChild("Backpack")
  tool=backpack and backpack:FindFirstChildOfClass("Tool")
  if tool then humanoid:EquipTool(tool) end
 end
 if tool and tool.Enabled then tool:Activate() end
end
local dropWindows={}
local freshTokens=setmetatable({},{__mode="k"})
local collectibles=workspace:FindFirstChild("Collectibles")
local dropAdded
if collectibles then dropAdded=collectibles.ChildAdded:Connect(function(token)
 if token:IsA("BasePart") then freshTokens[token]=os.clock() end
end) end
local function markFireflyDropWindow(position,field)
 local fresh={}
 for _,window in ipairs(dropWindows) do if os.clock()<=window.untilTime then table.insert(fresh,window) end end
 table.insert(fresh,{position=position,field=field,from=os.clock()-0.35,untilTime=os.clock()+10})
 dropWindows=fresh
end
local fireflyLootIcons={["2306224708"]=true,["1472135114"]=true,["2028574353"]=true}
local function isFireflyDrop(token)
 local born=freshTokens[token]
 if not born then return false end -- never sweep up pre-existing field tokens
 local source=token:GetAttribute("Source") or token:GetAttribute("SpawnSource")
 local explicit=type(source)=="string" and source:lower():find("firefly",1,true)~=nil
 if source and not explicit then return false end
 if not explicit then
  local decal=token:FindFirstChildWhichIsA("Decal")
  local id=decal and tostring(decal.Texture):match("(%d+)$")
  if not fireflyLootIcons[id] then return false end
 end
 for _,window in ipairs(dropWindows) do
  if born>=window.from and born<=window.untilTime and os.clock()<=window.untilTime+10 and
    horizontalDistance(token.Position,window.position)<=12 and math.abs(token.Position.Y-window.position.Y)<=8 and fieldUnder(token.Position)==window.field then return true end
 end
 return false
end
local function collectNearby(origin,isRunning,recentTokens)
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local folder=workspace:FindFirstChild("Collectibles")
 if not root or not folder then return false end
 local nearest,distance=nil,35
 for _,token in ipairs(folder:GetChildren()) do
  if token:IsA("BasePart") and token.Transparency<0.95 and isFireflyDrop(token) and (token.Position-origin).Magnitude<=35 and
   (not recentTokens[token] or os.clock()-recentTokens[token]>2) then
   local d=(token.Position-root.Position).Magnitude
   if d<distance then nearest,distance=token,d end
  end
 end
 if nearest then
  local field=fieldUnder(nearest.Position)
  if field then
   local goal=Vector3.new(nearest.Position.X,field.Position.Y+3,nearest.Position.Z)
   local arrived=walkMapTo(goal,function() return isRunning() and nearest.Parent~=nil end,setStatus,false,true)
   recentTokens[nearest]=os.clock()
   return arrived and horizontalDistance(root.Position,nearest.Position)<=8
  end
 end
end
local sparkleTargets={}
local touchedFields={}
local function recentlyTouched(field,position)
 for _,touch in ipairs(touchedFields[field] or {}) do
  if os.clock()-touch.time<=45 and horizontalDistance(touch.position,position)<=35 then return true end
 end
 return false
end
local function trackSparkle(marker)
 if marker.Name~="Sparkles" then return end
 local flower=marker.Parent
 while flower and not flower:IsA("BasePart") do flower=flower.Parent end
 if flower then sparkleTargets[marker]=flower end
end
local flowers=workspace:FindFirstChild("Flowers")
local sparkleAdded,sparkleRemoved
if flowers then
 for _,marker in ipairs(flowers:GetDescendants()) do trackSparkle(marker) end
 sparkleAdded=flowers.DescendantAdded:Connect(trackSparkle)
 sparkleRemoved=flowers.DescendantRemoving:Connect(function(marker) sparkleTargets[marker]=nil end)
end
local function farmSparkle(field,isRunning,recent)
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 if not root then return false end
 local nearest,nearestMarker,distance=nil,nil,math.huge
 for marker,flower in pairs(sparkleTargets) do
  if not marker.Parent or not flower.Parent then sparkleTargets[marker]=nil
  elseif marker.Enabled~=false and not recent[marker] and fieldUnder(flower.Position)==field and recentlyTouched(field,flower.Position) then
   local d=(flower.Position-root.Position).Magnitude
   if d<distance then nearest,nearestMarker,distance=flower,marker,d end
  end
 end
 if not nearest then return false end
 local goal=Vector3.new(nearest.Position.X,field.Position.Y+3,nearest.Position.Z)
 setStatus("Approaching active firefly sparkle in "..field.Name)
 farmingActive=true
 local arrived=walkMapTo(goal,function() return isRunning() and nearestMarker.Parent~=nil and nearestMarker.Enabled~=false end,setStatus,false,true)
 arrived=arrived and player.Character==character and horizontalDistance(root.Position,goal)<=6
 if arrived then
  markFireflyDropWindow(goal,field)
  setStatus("Farming firefly sparkles in "..field.Name.." | autodig on")
  local untilTime=os.clock()+1.2
  while isRunning() and nearestMarker.Parent and nearestMarker.Enabled~=false and os.clock()<untilTime do dig();task.wait(0.2) end
 end
 recent[nearestMarker]=true
 return arrived
end
local function runStandaloneFireflies(isRunning,hop)
 local recent,blocked,recentTokens,sparkleRecent,roundSeen={},{},{},{},{}
 local lastField=nil
 local idleSince=os.clock()
 while isRunning() do
  farmingActive=false
  if nightTime() then
   local function active() return isRunning() and nightTime() end
   -- Touch every settled firefly in this field before stopping for sparkles.
   local excluded={}
   for target,untilTime in pairs(blocked) do excluded[target]=untilTime end
   for target,untilTime in pairs(roundSeen) do excluded[target]=untilTime end
   local fly=findStationaryFirefly(recent,excluded,lastField)
   if fly then
    local field=fieldUnder(fly.Position)
    local selectedPosition=fly.Position
    local ok,reason=pcall(function()
     local function available()
      local velocity=fly.Parent and fly:FindFirstChild("BodyVelocity")
      return active() and velocity and velocity.Velocity.Magnitude==0 and fieldUnder(fly.Position)==field and (fly.Position-selectedPosition).Magnitude<6
     end
     if not ensureHiveClaimed(active,setStatus,available) then error("Cannot claim hive yet",0) end
     farmingActive=true
     local goal=Vector3.new(selectedPosition.X,field.Position.Y+3,selectedPosition.Z)
     local travelRoot=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
     if not travelRoot then error("Character not ready",0) end
     if fieldUnder(travelRoot.Position)~=field then
      local arrival=field.Position+Vector3.new(0,3,0)
      for _,offset in ipairs({Vector3.new(15,0,0),Vector3.new(-15,0,0),Vector3.new(0,0,15),Vector3.new(0,0,-15)}) do
       local candidate=goal+offset
       if fieldUnder(candidate)==field then arrival=candidate;break end
      end
      if not walkMapTo(arrival,available,setStatus) then error("Cannot reach firefly field",0) end
     end
     -- Finish by physically walking over the firefly, even after Tween travel.
     if not walkMapTo(goal,available,setStatus,false,true) then error("Cannot reach firefly yet",0) end
     local character=player.Character
     local root=character and character:FindFirstChild("HumanoidRootPart")
     if not root or not available() or horizontalDistance(root.Position,fly.Position)>6 or math.abs(root.Position.Y-goal.Y)>8 then error("Firefly moved before contact",0) end
     lastField=field
     local touches=touchedFields[field] or {}
     local fresh={}
     for _,touch in ipairs(touches) do if os.clock()-touch.time<=45 then table.insert(fresh,touch) end end
     table.insert(fresh,{position=goal,time=os.clock()});touchedFields[field]=fresh
     markFireflyDropWindow(goal,field)
     setStatus("Touched firefly in "..field.Name.."; checking next target")
     recent[fly]=os.clock();roundSeen[fly]=math.huge;idleSince=os.clock()
    end)
    if not ok then blocked[fly]=os.clock()+5;roundSeen[fly]=math.huge;setStatus("Firefly route retry: "..tostring(reason)) end
   elseif lastField then
    local worked=false
    local ok=pcall(function()
     local character=player.Character;local root=character and character:FindFirstChild("HumanoidRootPart")
     if root then worked=collectNearby(root.Position,active,recentTokens) end
     if not worked then worked=farmSparkle(lastField,active,sparkleRecent) end
    end)
    if worked and ok then idleSince=os.clock()
    elseif os.clock()-idleSince>=2 then lastField=nil;roundSeen={};sparkleRecent={};setStatus("No active firefly drops here; searching") end
   else setStatus("Night server: waiting for fireflies to settle");roundSeen={} end
   -- Keep the night server even when fireflies are moving or absent.
   for target in pairs(recent) do if not target.Parent then recent[target]=nil end end
   for target in pairs(blocked) do if not target.Parent then blocked[target]=nil end end
   for token in pairs(recentTokens) do if not token.Parent then recentTokens[token]=nil end end
   task.wait(0.1)
  else
   farmingActive=false;lastField=nil;roundSeen={};sparkleRecent={};touchedFields={}
   if config.DontHop then setStatus("Daytime: waiting here (DontHop)");task.wait(1)
   else setStatus("Night ended: searching for a night server");hop(isRunning);task.wait(3) end
  end
 end
end

-- Same POST text/plain + newline JSON polling protocol as the recovered relay.
local pendingGroupNight,lastGroupId=nil,nil
local function grouped() return config.Group~="" and config.MainAccount~="" end
local function isGroupAlt() return grouped() and player.Name:lower()~=config.MainAccount:lower() end
local function groupStatus(message) if groupLabel then groupLabel.Text=message end end
local function groupTopic()
 local a,b=5381,52711
 for i=1,#config.Group do local byte=config.Group:byte(i);a=(a*33+byte)%4294967296;b=(b*31+byte)%4294967296 end
 return string.format("th_ff_%08x%08x",a,b)
end
local function relayRequest(method,suffix,body)
 local fn=request or http_request or (syn and syn.request) or (getfenv().http and getfenv().http.request)
 if not fn then return nil,"Executor HTTP request unavailable" end
 local ok,response=pcall(fn,{Url=config.RelayURL:gsub("/+$","").."/"..groupTopic()..suffix,Method=method,Headers={["Content-Type"]="text/plain"},Body=body,Timeout=6})
 if not ok or not response or not response.StatusCode or response.StatusCode<200 or response.StatusCode>=300 then return nil,"Group relay unavailable" end
 return response.Body or ""
end
local function validNightReport(report)
 return type(report)=="table" and report.kind=="firefly-night-v1" and report.place==game.PlaceId and type(report.main)=="string" and report.main:lower()==config.MainAccount:lower() and report.room==groupTopic() and
  type(report.at)=="number" and os.time()-report.at>=-5 and os.time()-report.at<=25 and
  type(report.clock)=="number" and report.clock>=0 and report.clock<24 and (report.clock>=19 or report.clock<=5) and
  type(report.job)=="string" and #report.job<=64 and report.job:match("^[%w%-]+$") and report.job~=game.JobId
end
local function publishGroupNight()
 local result,reason=relayRequest("POST","",http:JSONEncode({kind="firefly-night-v1",place=game.PlaceId,job=game.JobId,at=os.time(),clock=game:GetService("Lighting").ClockTime,main=config.MainAccount,room=groupTopic(),by=player.Name}))
 groupStatus(result and "Alt: reported a night server with fireflies" or reason)
 return result~=nil
end
local function pollGroupNight()
 if not grouped() or isGroupAlt() then return end
 local body,reason=relayRequest("GET","/json?poll=1&since="..http:UrlEncode(lastGroupId or "30s"))
 if not body then groupStatus(reason);return end
 for line in body:gmatch("[^\r\n]+") do
  local ok,event=pcall(function() return http:JSONDecode(line) end)
  if ok and type(event)=="table" then
   if event.id then lastGroupId=event.id end
   if type(event.message)=="string" then
    local parsed,report=pcall(function() return http:JSONDecode(event.message) end)
    if parsed and validNightReport(report) then pendingGroupNight=report end
   end
  end
 end
 groupStatus(pendingGroupNight and "Main: fresh night server reported by alt" or "Main: listening for night-server reports")
end
local function takeGroupNight(visited)
 if isGroupAlt() or not pendingGroupNight then return nil end
 local report=pendingGroupNight;pendingGroupNight=nil
 if validNightReport(report) and not (visited and visited[report.job]) then return report.job end
end
local function groupPulse(isRunning)
 while isRunning() do
  if grouped() and not isGroupAlt() and not nightTime() then pollGroupNight() end
  task.wait(5)
 end
end
local function runFireflyScout(isRunning,hop)
 local lastReport=-math.huge
 while isRunning() do
  if nightTime() and findStationaryFirefly({},{}) then
   setStatus("Alt: night server with fireflies; reporting to main")
   if os.clock()-lastReport>=12 then publishGroupNight();lastReport=os.clock() end
   local mainPresent=false
   for _,other in ipairs(game:GetService("Players"):GetPlayers()) do if other.Name:lower()==config.MainAccount:lower() then mainPresent=true;break end end
   if mainPresent and not config.DontHop then hop(isRunning) else task.wait(1) end
  elseif config.DontHop then setStatus("Alt: searching here (DontHop)");task.wait(1)
  else setStatus("Alt: scouting for a night server with fireflies");hop(isRunning);task.wait(5) end
 end
end

local backendURL="https://raw.githubusercontent.com/DarkBotGen/tifahop-loader/fireflies-v3/TifaHop-Fireflies.luau"
local visited=config.VisitedServers
visited[game.JobId]=true
local function teleportToJob(job,isRunning)
 if not isRunning() then return end
 visited[job]=true;saveConfig()
 local resume=string.format("local c=game:GetService('HttpService'):JSONDecode(%q);loadstring(game:HttpGet(%q))(c)",http:JSONEncode(config),backendURL)
 local queue=queue_on_teleport or queueonteleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport)
 if queue then pcall(queue,resume) end
 local teleport=game:GetService("TeleportService")
 local failed=false
 local connection=teleport.TeleportInitFailed:Connect(function(who) if who==player then failed=true end end)
 local launched=pcall(function() teleport:TeleportToPlaceInstance(game.PlaceId,job,player) end)
 local deadline=os.clock()+12
 while launched and not failed and isRunning() and os.clock()<deadline do task.wait(0.25) end
 connection:Disconnect()
end
local function hop(isRunning)
 if not isRunning() then return end
 if grouped() and not isGroupAlt() then
  pollGroupNight()
  local groupJob=takeGroupNight(visited)
  if groupJob then setStatus("Joining alt's night server");teleportToJob(groupJob,isRunning);return end
 end
 local cursor=nil
 for page=1,3 do
  if not isRunning() then return end
  local url="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
  if cursor then url..="&cursor="..http:UrlEncode(cursor) end
  local ok,result=pcall(function() return http:JSONDecode(game:HttpGet(url)) end)
  if not ok then setStatus("Server search failed; retrying");return end
  for _,server in ipairs(result.data or {}) do
   if not isRunning() then return end
   if server.id~=game.JobId and not visited[server.id] and server.playing<server.maxPlayers then teleportToJob(server.id,isRunning);return end
  end
  cursor=result.nextPageCursor
  if not cursor then break end
 end
 visited={[game.JobId]=true};config.VisitedServers=visited;saveConfig()
 setStatus("No available server yet; retrying")
end
if shared.TifaHopFireflyStop then pcall(shared.TifaHopFireflyStop) end
local gui=Instance.new("ScreenGui")
gui.Name="TifaHopFireflies";gui.ResetOnSpawn=false;gui.Parent=player:WaitForChild("PlayerGui")
local frame=Instance.new("Frame")
frame.Size=UDim2.fromOffset(340,490);frame.Position=UDim2.new(0,20,0.05,0);frame.BackgroundColor3=Color3.fromRGB(24,25,30);frame.Parent=gui
local scale=Instance.new("UIScale");scale.Scale=math.min(1,(workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 800)*0.9/490);scale.Parent=frame
local function label(text,y,height)
 local item=Instance.new("TextLabel");item.Size=UDim2.new(1,-20,0,height);item.Position=UDim2.fromOffset(10,y)
 item.BackgroundTransparency=1;item.TextColor3=Color3.new(1,1,1);item.TextSize=14;item.TextWrapped=true;item.Font=Enum.Font.Gotham;item.Text=text;item.Parent=frame;return item
end
label("TifaHop Fireflies | standalone",8,25)
statusLabel=label("Stopped",38,45)
local function button(text,y)
 local item=Instance.new("TextButton");item.Size=UDim2.new(1,-20,0,32);item.Position=UDim2.fromOffset(10,y)
 item.BackgroundColor3=Color3.fromRGB(64,75,120);item.TextColor3=Color3.new(1,1,1);item.Font=Enum.Font.Gotham;item.TextSize=14;item.Text=text;item.Parent=frame;return item
end
startButton=button("Start Fireflies",90)
hopButton=button("DontHop: "..tostring(config.DontHop),130)
local movementButton=button("Movement: "..config.Movement,170)
movementButton.MouseButton1Click:Connect(function() config.Movement=config.Movement=="Walk" and "Tween" or "Walk";UserConfig.tweenmovement=config.Movement=="Tween";saveConfig();movementButton.Text="Movement: "..config.Movement end)
local cannonButton=button("Use Red Cannon: "..tostring(config.UseRedCannon),210)
cannonButton.MouseButton1Click:Connect(function()
 config.UseRedCannon=not config.UseRedCannon;useRedCannon=config.UseRedCannon;cannonUnavailable=false
 saveConfig();cannonButton.Text="Use Red Cannon: "..tostring(config.UseRedCannon)
end)
local speedButton=button("Walkspeed enabled: "..tostring(config.WalkSpeedEnabled),250)
speedButton.MouseButton1Click:Connect(function()
 config.WalkSpeedEnabled=not config.WalkSpeedEnabled;refreshWalkingSpeed();saveConfig()
 speedButton.Text="Walkspeed enabled: "..tostring(config.WalkSpeedEnabled)
end)
local function speedInput(key,title,y)
 local titleLabel=label(title,y,32);titleLabel.Size=UDim2.new(0.6,-10,0,32);titleLabel.TextXAlignment=Enum.TextXAlignment.Left
 local input=Instance.new("TextBox");input.Size=UDim2.new(0.4,-10,0,32);input.Position=UDim2.new(0.6,0,0,y)
 input.BackgroundColor3=Color3.fromRGB(40,42,52);input.TextColor3=Color3.new(1,1,1);input.Font=Enum.Font.Gotham;input.TextSize=15
 input.ClearTextOnFocus=false;input.Text=tostring(config[key]);input.Parent=frame
 input.FocusLost:Connect(function()
  updateSpeedSetting(key,input.Text);input.Text=tostring(config[key])
 end)
end
speedInput("WalkSpeed","Walk speed (1-100)",290)
speedInput("TweenSpeed","Tween speed (4-12 x10)",330)
local function groupInput(key,title,y)
 local titleLabel=label(title,y,32);titleLabel.Size=UDim2.new(0.4,-10,0,32);titleLabel.TextXAlignment=Enum.TextXAlignment.Left
 local input=Instance.new("TextBox");input.Size=UDim2.new(0.6,-10,0,32);input.Position=UDim2.new(0.4,0,0,y);input.ClearTextOnFocus=false
 input.BackgroundColor3=Color3.fromRGB(40,42,52);input.TextColor3=Color3.new(1,1,1);input.TextSize=14;input.Text=config[key];input.Parent=frame
 input.FocusLost:Connect(function()
  if running then stop() end
  config[key]=input.Text:match("^%s*(.-)%s*$");pendingGroupNight=nil;lastGroupId=nil;saveConfig()
  groupStatus(grouped() and "Group configured; press Start" or "Solo: set Group and Main username to coordinate")
 end)
end
groupInput("Group","Group room",370);groupInput("MainAccount","Main username",410)
groupLabel=label(grouped() and (isGroupAlt() and "Alt scout" or "Main farmer") or "Solo",450,30)
stop=function()
 running=false;farmingActive=false;generation+=1;config.AutoStart=false;saveConfig()
 if speedHuman and speedHuman.Parent and speedHuman.WalkSpeed==writtenSpeed then speedHuman.WalkSpeed=oldSpeed end
 local character=player.Character
 local root=character and character:FindFirstChild("HumanoidRootPart")
 local humanoid=character and character:FindFirstChildOfClass("Humanoid")
 if root and humanoid then humanoid:MoveTo(root.Position) end
 startButton.Text="Start Fireflies";setStatus("Stopped")
end
shared.TifaHopFireflyStop=function() stop();if sparkleAdded then sparkleAdded:Disconnect() end;if sparkleRemoved then sparkleRemoved:Disconnect() end;if dropAdded then dropAdded:Disconnect() end;gui:Destroy() end
start=function()
 if running then return end
 running=true;generation+=1;local token=generation
 config.AutoStart=true;saveConfig();startButton.Text="Stop Fireflies"
 local function active() return running and token==generation end
 task.spawn(function()
  while active() do
   if farmingActive and nightTime() and confirmedHive() then pcall(function() refreshWalkingSpeed();dig() end) end
   task.wait(0.35)
  end
 end)
 task.spawn(function() groupPulse(active) end)
 task.spawn(function()
  local ok,reason=pcall(isGroupAlt() and runFireflyScout or runStandaloneFireflies,active,hop)
  if active() then stop();if not ok then setStatus("Fireflies stopped: "..tostring(reason)) end end
 end)
end
startButton.MouseButton1Click:Connect(function() if running then stop() else start() end end)
hopButton.MouseButton1Click:Connect(function() config.DontHop=not config.DontHop;saveConfig();hopButton.Text="DontHop: "..tostring(config.DontHop) end)
if config.AutoStart then start() else saveConfig() end
return {Start=start,Stop=stop}
