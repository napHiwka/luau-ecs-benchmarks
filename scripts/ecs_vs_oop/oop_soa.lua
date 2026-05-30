local COUNT = 10000
local STEPS = 300
local dt = 1 / 60

-- data
local x = {}
local y = {}
local vx = {}
local vy = {}
local health = {}
local lifetime = {}
local stunned = {}
local projectile = {}
local alive = {}

for i = 1, COUNT do
	x[i] = 0
	y[i] = 0
	vx[i] = math.random()
	vy[i] = math.random()
	health[i] = 100
	lifetime[i] = math.random() * 10
	stunned[i] = (i % 5) == 0
	projectile[i] = (i % 7) == 0
	alive[i] = true
end

-- simulation
local start = os.clock()
for step = 1, STEPS do
	for i = 1, COUNT do
		if not alive[i] then
			-- skip
		else
			-- movement
			if not stunned[i] then
				x[i] = x[i] + vx[i] * dt
				y[i] = y[i] + vy[i] * dt
			end

			-- projectile lifetime
			if projectile[i] then
				lifetime[i] = lifetime[i] - dt
				if lifetime[i] <= 0 then
					alive[i] = false
				end
			end

			-- combat
			if alive[i] then
				health[i] = health[i] - 0.05
				if health[i] <= 0 then
					alive[i] = false
				end
			end

			-- random state flip
			if step % 30 == 0 then
				stunned[i] = not stunned[i]
			end
		end
	end
end

print(string.format("SoA %.2f s", os.clock() - start))
