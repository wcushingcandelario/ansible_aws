use admin
db.createUser({user: "siteUserAdmin",pwd: "password",roles: [ { role: "userAdminAnyDatabase", db: "admin" } ]})
var schema = db.system.version.findOne({"_id" : "authSchema"})
schema.currentVersion = 3
db.system.version.save(schema)
use xdb
db.createUser({user: "root",pwd: "root",roles: [ { role: "dbOwner", db: "xdb" } ]})
db.auth("root","root")
