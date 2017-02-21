package.cpath = package.cpath .. ";/usr/lib/lua/5.3/?.so;/usr/local/lib/lua/5.3/?.so";

local base64 = require("base64");
local lualdap = require "lualdap"

local ldap = nil;
local servers = { {% for host in groups['ldap'] %} "{{ hostvars[host].inventory_hostname }}", {% endfor %} }
local server_id = 0;

user_shard_map = Map.new("/etc/haproxy/user_shard.map", Map.str);
domain_shard_map = Map.new("/etc/haproxy/domain_shard.map", Map.str);

function string:split(sep)
        local sep, fields = sep or ":", {}
        local pattern = string.format("([^%s]+)", sep)
        self:gsub(pattern, function(c) fields[#fields+1] = c end)
        return fields
end
function string:before(sep)
        local sep = sep or ":"
        local pos = string.find( self, sep, 1  )
        return string.sub( self, 1 , pos-1 )
end
function string:after(sep)
        local sep = sep or ":"
        local pos = string.find( self, sep, 1  )
        return string.sub( self, pos+1 )
end

function connect() 
    ldap = assert (lualdap.open_simple (
        servers[server_id+1],
        "cn=admin,dc=cloud,dc=switch,dc=ch",
        "{{ldap_password}}"))
end

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

core.register_fetches("userToShardLookup", function(txn)
    local encoded_auth_string = txn.f:req_fhdr('Authorization'):after(' ');
    local shard = user_shard_map:lookup(encoded_auth_string);
    if (not shard) then
        local auth_string = base64.decode(encoded_auth_string);
        local user = auth_string:before(':');
        
        if (ldap == nil) then
            server_id = (server_id + 1) % 2;
            connect();
        end
        
        local status, domain =  pcall(search, user);
    
        if (status == false) then
            ldap = nil;
        end
    
        shard = domain_shard_map:lookup(domain);
        core.set_map('/etc/haproxy/user_shard.map', encoded_auth_string, shard);
    end
    return shard;
end)

