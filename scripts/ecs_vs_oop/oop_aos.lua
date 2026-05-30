local COUNT = 10000
local STEPS = 300
local dt = 1 / 60

-- data
local actors = {}
for i = 1, COUNT do
	actors[i] = {
		x = 0,
		y = 0,
		vx = math.random(),
		vy = math.random(),
		health = 100,
		lifetime = math.random() * 10,
		stunned = (i % 5) == 0,
		projectile = (i % 7) == 0,
		alive = true,
	}
end

-- simulation
local start = os.clock()
for step = 1, STEPS do
	for i = 1, COUNT do
		local a = actors[i]

		if not a.alive then
			-- skip
		else
			-- movement
			if not a.stunned then
				a.x = a.x + a.vx * dt
				a.y = a.y + a.vy * dt
			end

			-- projectile lifetime
			if a.projectile then
				a.lifetime = a.lifetime - dt
				if a.lifetime <= 0 then
					a.alive = false
				end
			end

			-- combat
			if a.alive then
				a.health = a.health - 0.05
				if a.health <= 0 then
					a.alive = false
				end
			end

			-- random state flip
			if step % 30 == 0 then
				a.stunned = not a.stunned
			end
		end
	end
end

print(string.format("AoS (OOP) %.2f s", os.clock() - start))
