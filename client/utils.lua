local function DrawText3D(x, y, z, text)
    local onScreen, _x, _y = World3dToScreen2d(x, y, z)
    local px, py, pz = table.unpack(GetGameplayCamCoords())
    local scale = 0.35
    
    if onScreen then
        SetTextScale(scale, scale)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextColour(255, 255, 255, 215)
        SetTextDropshadow(0, 0, 0, 0, 255)
        SetTextEdge(2, 0, 0, 0, 150)
        SetTextDropShadow()
        SetTextOutline()
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(_x, _y)
    end
end

local function DrawBox3D(x, y, z, size, heading)
    local rad = math.rad(heading)
    local cos = math.cos(rad)
    local sin = math.sin(rad)
    
    local points = {
        {x - size/2, y - size/2, z - size/2},
        {x + size/2, y - size/2, z - size/2},
        {x + size/2, y + size/2, z - size/2},
        {x - size/2, y + size/2, z - size/2},
        {x - size/2, y - size/2, z + size/2},
        {x + size/2, y - size/2, z + size/2},
        {x + size/2, y + size/2, z + size/2},
        {x - size/2, y + size/2, z + size/2}
    }
    
    for i, point in ipairs(points) do
        local px, py, pz = point[1] - x, point[2] - y, point[3] - z
        local rx = px * cos - py * sin
        local ry = px * sin + py * cos
        points[i] = {x + rx, y + ry, point[3]}
    end
    
    local color = {255, 255, 0, 255} -- Amarelo
    
    DrawLine(points[1][1], points[1][2], points[1][3], points[2][1], points[2][2], points[2][3], color[1], color[2], color[3], color[4])
    DrawLine(points[2][1], points[2][2], points[2][3], points[3][1], points[3][2], points[3][3], color[1], color[2], color[3], color[4])
    DrawLine(points[3][1], points[3][2], points[3][3], points[4][1], points[4][2], points[4][3], color[1], color[2], color[3], color[4])
    DrawLine(points[4][1], points[4][2], points[4][3], points[1][1], points[1][2], points[1][3], color[1], color[2], color[3], color[4])
    
    DrawLine(points[5][1], points[5][2], points[5][3], points[6][1], points[6][2], points[6][3], color[1], color[2], color[3], color[4])
    DrawLine(points[6][1], points[6][2], points[6][3], points[7][1], points[7][2], points[7][3], color[1], color[2], color[3], color[4])
    DrawLine(points[7][1], points[7][2], points[7][3], points[8][1], points[8][2], points[8][3], color[1], color[2], color[3], color[4])
    DrawLine(points[8][1], points[8][2], points[8][3], points[5][1], points[5][2], points[5][3], color[1], color[2], color[3], color[4])
    
    DrawLine(points[1][1], points[1][2], points[1][3], points[5][1], points[5][2], points[5][3], color[1], color[2], color[3], color[4])
    DrawLine(points[2][1], points[2][2], points[2][3], points[6][1], points[6][2], points[6][3], color[1], color[2], color[3], color[4])
    DrawLine(points[3][1], points[3][2], points[3][3], points[7][1], points[7][2], points[7][3], color[1], color[2], color[3], color[4])
    DrawLine(points[4][1], points[4][2], points[4][3], points[8][1], points[8][2], points[8][3], color[1], color[2], color[3], color[4])
end

local function DrawArrow3D(x, y, z, heading)
    local arrowLength = 2.0
    local arrowHeight = 0.5
    
    local rad = math.rad(heading)
    local endX = x + (math.sin(-rad) * arrowLength)
    local endY = y + (math.cos(-rad) * arrowLength)
    local endZ = z + arrowHeight
    
    DrawLine(x, y, z + arrowHeight, endX, endY, endZ, 255, 255, 0, 255)
    
    local arrowTipSize = 0.3
    local tip1X = endX + (math.sin(-rad + math.rad(150)) * arrowTipSize)
    local tip1Y = endY + (math.cos(-rad + math.rad(150)) * arrowTipSize)
    local tip2X = endX + (math.sin(-rad - math.rad(150)) * arrowTipSize)
    local tip2Y = endY + (math.cos(-rad - math.rad(150)) * arrowTipSize)
    
    DrawLine(endX, endY, endZ, tip1X, tip1Y, endZ, 255, 255, 0, 255)
    DrawLine(endX, endY, endZ, tip2X, tip2Y, endZ, 255, 255, 0, 255)
    DrawLine(tip1X, tip1Y, endZ, tip2X, tip2Y, endZ, 255, 255, 0, 255)
end

return {
    DrawText3D = DrawText3D,
    DrawBox3D = DrawBox3D,
    DrawArrow3D = DrawArrow3D
} 