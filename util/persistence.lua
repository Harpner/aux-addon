aux.module 'persistence'

_g.aux_datasets = {}

do
    local realm, faction

    function LOAD()
        control.thread(control.when, function() faction = UnitFactionGroup 'player' return faction end, function() end)
        realm = GetCVar 'realmName'
    end

    private.dataset_key{get=function() return realm..'|'..faction end}
end

function public.load_dataset()
    local dataset_key = dataset_key
    _g.aux_datasets[dataset_key] = _g.aux_datasets[dataset_key] or {}
    return _g.aux_datasets[dataset_key]
end

function public.read(schema, str)
    if schema == 'string' then
        return str
    elseif schema == 'boolean' then
        return str == '1'
    elseif schema == 'number' then
        return tonumber(str)
    elseif type(schema) == 'table' and schema[1] == 'list' then
        return read_list(schema, str)
    elseif type(schema) == 'table' and schema[1] == 'record' then
        return read_record(schema, str)
    else
        error 'Invalid schema.'
    end
end

function public.write(schema, obj)
    if schema == 'string' then
        return obj or ''
    elseif schema == 'boolean' then
        return obj and '1' or '0'
    elseif schema == 'number' then
        return obj and tostring(obj) or ''
    elseif type(schema) == 'table' and schema[1] == 'list' then
        return write_list(schema, obj)
    elseif type(schema) == 'table' and schema[1] == 'record' then
        return write_record(schema, obj)
    else
        error 'Invalid schema.'
    end
end

function public.read_list(schema, str)
    if str == '' then return {} end

    local separator = schema[2]
    local element_type = schema[3]
    local parts = split(str, separator)
    return map(parts, function(part)
        return read(element_type, part)
    end)
end

function public.write_list(schema, list)
    local separator = schema[2]
    local element_type = schema[3]
    local parts = map(list, function(element)
        return write(element_type, element)
    end)
    return join(parts, separator)
end

function public.read_record(schema, str)
    local separator = schema[2]
    local record = {}
    local parts = split(str, separator)
    for i=3,getn(schema) do
        local key, type = next(schema[i])
        record[key] = read(type, parts[i - 2])
    end
    return record
end

function public.write_record(schema, record)
    local separator = schema[2]
    local parts = {}
    for i=3,getn(schema) do
        local key, type = next(schema[i])
        tinsert(parts, write(type, record[key]))
    end
    return join(parts, separator)
end