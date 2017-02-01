
package.cpath = package.cpath .. ";/usr/local/lib/lua/5.3/?.so";

local base64 = require("base64");

core.register_converters("base64decode", function(encodedString)
   return base64.decode(encodedString);
end)

