package.cpath = package.cpath .. ";/usr/lib/lua/5.3/?.so";

local lualdap = require "lualdap"
local ldap = nil;
local servers = {"86.119.30.169", "86.119.34.136"}
local server_id = 0;

function connect() 
    -- "{hostvars[groups['ldap'][0]].inventory_hostname}}",
    ldap = assert (lualdap.open_simple (
        servers[server_id+1],
        "cn=admin,dc=cloud,dc=switch,dc=ch",
        "{{ldap_password}}"))
end

core.register_init(function()
    --core.Warning("connecting to " .. servers[server_id+1]);
end)

core.register_task(function()
    if (ldap == nil) then
        server_id = (server_id + 1) % 2;
        connect();
    end
    core.Warning("connecting to " .. servers[server_id+1]);
end)

function search(user) 
    local result = "not found";
    for dn, attribs in ldap:search {
        base = "ou=Users,dc=cloud,dc=switch,dc=ch",
        scope = "subtree",
        filter = "(&(&(&(objectclass=inetOrgPerson)(objectclass=eduMember))(isMemberOf=ownCloud)(mail=" .. user .. ")))",
        sizelimit = 1,
        attrs = {"o", "isMemberOf"}
        } do
        for name, values in pairs (attribs) do
            -- result = result .. name;
            if (name == "o") then
                if type (values) == "string" then
                    result = values;
                elseif type (values) == "table" then
                   local n = table.getn(values)
                   for i = 1, (n-1) do
                        result = result .. "," .. values[i];
                   end
               end
            end
        end 
    end
    return result;
end


core.register_converters("ldapUserLookup", function(user)
    if (ldap == nil) then
        server_id = (server_id + 1) % 2;
        connect();
    end
    local status, result =  pcall(search, user);
    if (status == false) then
        ldap = nil;
    end
    return result;
end)



