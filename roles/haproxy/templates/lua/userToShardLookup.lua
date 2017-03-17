package.cpath = package.cpath .. ";/usr/lib/lua/5.3/?.so;/usr/local/lib/lua/5.3/?.so";

local base64 = require("base64");
local lualdap = require "lualdap";
local redis = require 'redis';

local ldap_client;
local ldap_servers = { {% for host in groups['ldap'] %} "{{ hostvars[host].inventory_hostname }}", {% endfor %} }
local ldap_server_id = 0;

local redis_client;
local redis_servers = { {% for host in groups['redis'] %} "{{ hostvars[host].inventory_hostname }}", {% endfor %} }
local redis_server_id = 0;

domain_shard_map = Map.new("/etc/haproxy/domain_shard.map", Map.str);
user_shard_map = Map.new("/etc/haproxy/user_shard.map", Map.str);

------------------
-- utilities

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

------------------
-- redis

function redis_connect() 
   local tcp = core.tcp();
   tcp:settimeout(1);
   tcp:connect(redis_servers[redis_server_id+1], 6379);
   redis_client = redis.connect({socket=tcp});
   redis_client:ping();
end

function redis_search(user) 
    return redis_client:get("shard_by_user:" .. user);
end

function get_from_redis(user)
    local retry = 0;
    local status, shard;
    while not status and retry < 1 do
        if (not redis_client) then
            redis_server_id = (redis_server_id + 1) % #redis_servers;;
            redis_connect();
        end
        status, shard =  pcall(redis_search, user);
        if (not status) then
            redis_client = nil;
            rerty = retry + 1;
        end
    end
    return shard;
end

function put_to_redis(user, shard)
    pcall(function ()
       redis_client:set("shard_by_user:" .. user, shard);
    end);
end

------------------
-- ldap

function ldap_connect() 
    ldap_client = assert (lualdap.open_simple (
        ldap_servers[ldap_server_id+1],
        "cn=admin,dc=cloud,dc=switch,dc=ch",
        "{{ldap_password}}"))
end

function ldap_search(user) 
    local result = "not found";
    for dn, attribs in ldap_client:search {
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

function get_from_ldap(user)
    local retry = 0;
    local status, domain;
    while not status and retry < 1 do
        if (not ldap_client) then
            ldap_server_id = (ldap_server_id + 1) % #ldap_servers;
            ldap_connect();
        end
        
        status, domain =  pcall(ldap_search, user);
    
        if (not status) then
            ldap_client = nil;
        end
    end
    
    shard = domain_shard_map:lookup(domain);
    return shard
end

------------------
-- userToShardLookup

core.register_action("userToShardLookup", {"http-req"}, function(txn)
    local encoded_auth_string = txn.f:req_fhdr('Authorization'):after(' ');
    local auth_string = base64.decode(encoded_auth_string);
    local user = auth_string:before(':');
    
    -- try fetching cached value
    -- locally defined user ?
    local shard = user_shard_map:lookup(user);
    -- chached in redis?
    if (not shard) then
        shard = get_from_redis(user);
    end

    -- fetch from ldap if not found in cache
    if (not shard ) then
        shard = get_from_ldap(user);
        put_to_redis(user, shard);  
    end
    txn.http:req_set_header("Host", shard .. '.' .. "{{ service_name }}");
end)

