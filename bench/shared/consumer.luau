local Compat = require("./compat")

local Consumer = {}

local function valueAt(row, index)
	local values = row.values
	if values then
		return values[index]
	end
	return row[index + 1]
end

local function packedRowChecksum(row, width)
	if width == 1 then
		return valueAt(row, 1) * 0.02
	elseif width == 2 then
		return valueAt(row, 1) * 0.02 + valueAt(row, 2) * 0.03
	elseif width == 3 then
		return valueAt(row, 1) * 0.02 + valueAt(row, 2) * 0.03 + valueAt(row, 3) * 0.04
	else
		local sum = 0
		for i = 1, width do
			sum = sum + valueAt(row, i) * (0.01 * (i + 1))
		end
		return sum
	end
end

local function consumeArray(results, width)
	local checksum = 0
	for rowIndex = 1, #results do
		local row = results[rowIndex]
		if row and type(row) == "table" then
			if width == 1 then
				local a = valueAt(row, 1)
				if a then
					checksum = checksum + a * 0.02
				end
			elseif width == 2 then
				local a, b = valueAt(row, 1), valueAt(row, 2)
				if a then
					checksum = checksum + a * 0.02
				end
				if b then
					checksum = checksum + b * 0.03
				end
			elseif width == 3 then
				local a, b, c = valueAt(row, 1), valueAt(row, 2), valueAt(row, 3)
				if a then
					checksum = checksum + a * 0.02
				end
				if b then
					checksum = checksum + b * 0.03
				end
				if c then
					checksum = checksum + c * 0.04
				end
			else
				for componentIndex = 1, width do
					local value = valueAt(row, componentIndex)
					if value then
						checksum = checksum + value * (0.01 * (componentIndex + 1))
					end
				end
			end
		end
	end
	return checksum
end

local function consumeIterator(iterator, width)
	local checksum = 0
	if width == 1 then
		while true do
			local entity, a = iterator()
			if entity == nil then
				break
			end
			checksum = checksum + a * 0.02
		end
	elseif width == 2 then
		while true do
			local entity, a, b = iterator()
			if entity == nil then
				break
			end
			checksum = checksum + a * 0.02 + b * 0.03
		end
	elseif width == 3 then
		while true do
			local entity, a, b, c = iterator()
			if entity == nil then
				break
			end
			checksum = checksum + a * 0.02 + b * 0.03 + c * 0.04
		end
	else
		while true do
			local packed = Compat.pack(iterator())
			if packed[1] == nil then
				break
			end
			for i = 2, packed.n do
				checksum = checksum + packed[i] * (0.01 * i)
			end
		end
	end
	return checksum
end

function Consumer.detectConsumer(probeResult, width)
	local probeType = type(probeResult)
	if probeType == "function" then
		while probeResult() ~= nil do
		end
		return function(queryResult)
			local firstRow = Compat.pack(queryResult())
			if firstRow[1] == nil then
				return 0
			end
			return packedRowChecksum(firstRow, width) + consumeIterator(queryResult, width)
		end
	elseif probeType == "table" then
		if probeResult.entities and probeResult.get then
			return function(queryResult)
				local checksum = 0
				local entities = queryResult.entities
				local components = queryResult.components
				local get = queryResult.get
				for rowIndex = 1, queryResult.count or #entities do
					local entity = entities[rowIndex]
					for componentIndex = 1, width do
						local value = get(entity, components[componentIndex])
						if value then
							checksum = checksum + value * (0.01 * (componentIndex + 1))
						end
					end
				end
				return checksum
			end
		elseif probeResult.entities and probeResult.components then
			return function(queryResult)
				local checksum = 0
				local entities = queryResult.entities
				local components = queryResult.components
				for rowIndex = 1, queryResult.count or #entities do
					local entity = entities[rowIndex]
					for componentIndex = 1, width do
						local value = entity[components[componentIndex]]
						if value then
							checksum = checksum + value * (0.01 * (componentIndex + 1))
						end
					end
				end
				return checksum
			end
		elseif probeResult.rows and probeResult.components then
			return function(queryResult)
				local checksum = 0
				local rows = queryResult.rows
				local components = queryResult.components
				for rowIndex = 1, queryResult.count or #rows do
					local row = rows[rowIndex]
					for componentIndex = 1, width do
						local value = row[components[componentIndex]]
						if value then
							checksum = checksum + value * (0.01 * (componentIndex + 1))
						end
					end
				end
				return checksum
			end
		end
		return function(queryResult)
			return consumeArray(queryResult, width)
		end
	else
		error("Unsupported query result type: " .. probeType)
	end
end

return Consumer
