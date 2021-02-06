---
--- Generated by Luanalysis
--- Created by Lyr.
--- DateTime: 2/3/2021 3:09 PM
---
---
require "/scripts/util/propstore.lua"
require "/scripts/status.lua"

function init()

  animator.setSoundVolume("raise", 0.5)
  animator.setSoundVolume("hit", 0.4)
  animator.setSoundVolume("break", 0.6)

  self.fadeTime = config.getParameter("fadeTime", 0.4)
  self.breakingPeriod = config.getParameter("breakingPeriod", 2)
  self.cooldownTime = config.getParameter("cooldownTime", 5)

  self.propStore = PropStore.new("blockade", self)
  self.propStore:
    recall("cooldownTimer", 0)
  self.fadeTimer = 0
  self.breakTimer = 0

  self.active = false
  self.hidden = false
  self.breaking = false

  self.statGid = nil


  self.damageListener = damageListener("damageTaken", function(notifications)

    for _,n in pairs(notifications) do
      if n.hitType == "Hit" then
        self.cooldownTimer = self.cooldownTime

        if self.statGid then animator.playSound("hit") end

        if self.active and not self.breaking then
          self.breaking = true
          self.hidden = false
          self.fadeTimer = self.fadeTime
          self.breakTimer = self.breakingPeriod
          animator.setAnimationState("shield", "breaking")
        end
      end
      return
    end
  end)
end

function update(dt)
  self.damageListener:update()

  self.cooldownTimer = math.max(self.cooldownTimer - dt, 0)
  if self.cooldownTimer == 0 then
    if not self.active then
      self.active = true
      animator.setAnimationState("shield", "raise")
      animator.playSound("raise")

      self.statGid = self.statGid or effect.addStatModifierGroup({{stat = "protection", amount = math.huge}, {stat = "grit", amount = 0.5}})
    end
    if not self.hidden and self.fadeTimer == 0 and animator.animationState("shield") == "raised" then
      self.fadeTimer = self.fadeTime
      self.hidden = true
    end
  end

  if self.breaking then
    self.breakTimer = math.max(self.breakTimer - dt, 0)
    if self.breakTimer == 0 then
      self.active = false
      self.breaking = false

      animator.setAnimationState("shield", "break")
      animator.playSound("break")
      effect.removeStatModifierGroup(self.statGid)
      self.statGid = nil
    end
  end

  if self.fadeTimer > 0 then
    self.fadeTimer = math.max(self.fadeTimer - dt, 0)
    local fadeVal = (self.fadeTimer / self.fadeTime)
    fadeVal = self.breaking and (1-fadeVal) or fadeVal
    animator.setGlobalTag("fadeDirectives", string.format("multiply=ffffff%02x", math.max(0, math.floor(fadeVal * 254.8))))

    if self.fadeTimer == 0 and not self.breaking then
      animator.setAnimationState("shield", "none")
    end
  end
end


function onExpire(aaa)

end

function uninit()
  self.propStore:uninit()
end