-- Requires: tiny lib in the `bench/libraries` directory
local tiny = require("../../bench/libraries/tiny-ecs")

local COUNT = 10000
local STEPS = 300
local dt = 1 / 60

-- world & systems
local world = tiny.world()

-- movement system (entities that are alive and not stunned)
local movementSystem = tiny.processingSystem()
movementSystem.filter = tiny.requireAll("x", "y", "vx", "vy", "alive", "stunned")
function movementSystem:process(e, delta)
    if e.alive and not e.stunned then
        e.x = e.x + e.vx * delta
        e.y = e.y + e.vy * delta
    end
end

-- projectile lifetime system
local projectileSystem = tiny.processingSystem()
projectileSystem.filter = tiny.requireAll("projectile", "lifetime", "alive")
function projectileSystem:process(e, delta)
    if e.alive and e.projectile then
        e.lifetime = e.lifetime - delta
        if e.lifetime <= 0 then
            e.alive = false
        end
    end
end

-- combat / health drain system
local combatSystem = tiny.processingSystem()
combatSystem.filter = tiny.requireAll("health", "alive")
function combatSystem:process(e, delta)
    if e.alive then
        e.health = e.health - 0.05
        if e.health <= 0 then
            e.alive = false
        end
    end
end

tiny.add(world, movementSystem, projectileSystem, combatSystem)

-- entities
for i = 1, COUNT do
    tiny.addEntity(world, {
        x = 0,
        y = 0,
        vx = math.random(),
        vy = math.random(),
        health = 100,
        lifetime = math.random() * 10,
        stunned = (i % 5) == 0,
        projectile = (i % 7) == 0,
        alive = true,
    })
end

tiny.refresh(world)

-- simulation
local start = os.clock()
for step = 1, STEPS do
    -- random state flip (mirrors the SoA/AoS benchmarks)
    if step % 30 == 0 then
        for _, e in ipairs(movementSystem.entities) do
            e.stunned = not e.stunned
        end
    end

    tiny.update(world, dt)
end

print(string.format("tiny-ecs %.2f s", os.clock() - start))
