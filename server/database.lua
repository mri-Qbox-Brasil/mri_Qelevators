local oxmysql = exports['oxmysql']

if not oxmysql then
    print('^1[ERROR] oxmysql não encontrado! Certifique-se de que oxmysql está iniciado.')
    return
end

local function createElevatorTable()
    local result = oxmysql:querySync("SHOW TABLES LIKE 'mri_qelevators'", {})
    if result and #result > 0 then
        local columns = oxmysql:querySync("SHOW COLUMNS FROM mri_qelevators LIKE 'password'", {})
        if not columns or #columns == 0 then
            print('^2[INFO] Adicionando coluna password à tabela mri_qelevators')
            oxmysql:query('ALTER TABLE mri_qelevators ADD COLUMN password VARCHAR(64) DEFAULT ""')
            print('^2[SUCCESS] Coluna password adicionada com sucesso!')
        end
        print('^3[INFO] Tabela mri_qelevators verificada')
        return
    end
    
    print('^2[INFO] Criando tabela mri_qelevators')
    oxmysql:query([[CREATE TABLE IF NOT EXISTS mri_qelevators (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(64) NOT NULL,
        label VARCHAR(64) NOT NULL,
        x DOUBLE NOT NULL,
        y DOUBLE NOT NULL,
        z DOUBLE NOT NULL,
        size_x DOUBLE NOT NULL,
        size_y DOUBLE NOT NULL,
        size_z DOUBLE NOT NULL,
        rot DOUBLE NOT NULL,
        car BOOLEAN NOT NULL,
        job VARCHAR(64),
        gang VARCHAR(64),
        password VARCHAR(64) DEFAULT ""
    )]])
    print('^2[SUCCESS] Tabela mri_qelevators criada com sucesso!')
end

local function importLiftLuaToDB()
    if not Config.Data or next(Config.Data) == nil then
        return
    end
    
    local result = oxmysql:querySync('SELECT COUNT(*) as count FROM mri_qelevators', {})
    if result and result[1] and result[1].count > 0 then
        print('^3[INFO] Tabela já possui dados, pulando importação do data/lift.lua')
        return
    end
    
    print('^2[INFO] Importando dados do lift.lua para o banco de dados')
    for name, floors in pairs(Config.Data) do
        for _, floor in ipairs(floors) do
            oxmysql:insert('INSERT INTO mri_qelevators (name, label, x, y, z, size_x, size_y, size_z, rot, car, job, gang, password) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
                name, floor.label, floor.coords.x, floor.coords.y, floor.coords.z, floor.size.x, floor.size.y, floor.size.z, floor.rot or 0, floor.car or false, floor.job or '', floor.gang or '', floor.password or ''
            })
        end
    end
    print('^2[SUCCESS] Dados importados com sucesso!')
end

local function fetchAllElevators()
    local result = oxmysql:querySync('SELECT * FROM mri_qelevators', {})
    local data = {}
    
    if result then
        for _, row in ipairs(result) do
            if row and row.name and row.name ~= '' then
                if not data[row.name] then 
                    data[row.name] = {} 
                end
                
                data[row.name][#data[row.name] + 1] = {
                    label = tostring(row.label or ''),
                    coords = {
                        x = tonumber(row.x) or 0,
                        y = tonumber(row.y) or 0,
                        z = tonumber(row.z) or 0
                    },
                    size = {
                        x = tonumber(row.size_x) or 2,
                        y = tonumber(row.size_y) or 2,
                        z = tonumber(row.size_z) or 2
                    },
                    rot = tonumber(row.rot) or 0,
                    car = row.car == 1,
                    job = tostring(row.job or ''),
                    gang = tostring(row.gang or ''),
                    password = tostring(row.password or '')
                }
            end
        end
    else
        print('^3[WARNING] Nenhum resultado encontrado na tabela mri_qelevators')
    end
    
    return data
end

local function insertElevator(elevatorName, floorData)
    return oxmysql:insert('INSERT INTO mri_qelevators (name, label, x, y, z, size_x, size_y, size_z, rot, car, job, gang, password) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        elevatorName, floorData.label, floorData.coords.x, floorData.coords.y, floorData.coords.z, floorData.size.x, floorData.size.y, floorData.size.z, floorData.rot or 0, floorData.car or false, floorData.job or '', floorData.gang or '', floorData.password or ''
    })
end

local function updateElevatorName(oldName, newName)
    return oxmysql:query('UPDATE mri_qelevators SET name = ? WHERE name = ?', {newName, oldName})
end

local function updateFloor(elevatorName, oldFloorLabel, newFloorData)
    return oxmysql:query('UPDATE mri_qelevators SET label = ?, x = ?, y = ?, z = ?, size_x = ?, size_y = ?, size_z = ?, rot = ?, car = ?, job = ?, gang = ?, password = ? WHERE name = ? AND label = ?', {
        newFloorData.label, newFloorData.coords.x, newFloorData.coords.y, newFloorData.coords.z, newFloorData.size.x, newFloorData.size.y, newFloorData.size.z, newFloorData.rot, newFloorData.car, newFloorData.job, newFloorData.gang, newFloorData.password or '', elevatorName, oldFloorLabel
    })
end

local function updateFloorPassword(elevatorName, floorLabel, password)
    return oxmysql:query('UPDATE mri_qelevators SET password = ? WHERE name = ? AND label = ?', {password, elevatorName, floorLabel})
end

local function deleteElevator(elevatorName)
    return oxmysql:query('DELETE FROM mri_qelevators WHERE name = ?', {elevatorName})
end

local function deleteFloor(elevatorName, floorLabel)
    return oxmysql:query('DELETE FROM mri_qelevators WHERE name = ? AND label = ?', {elevatorName, floorLabel})
end

return {
    createElevatorTable = createElevatorTable,
    importLiftLuaToDB = importLiftLuaToDB,
    fetchAllElevators = fetchAllElevators,
    insertElevator = insertElevator,
    updateElevatorName = updateElevatorName,
    updateFloor = updateFloor,
    updateFloorPassword = updateFloorPassword,
    deleteElevator = deleteElevator,
    deleteFloor = deleteFloor
} 