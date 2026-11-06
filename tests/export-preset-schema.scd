(
var root=thisProcess.argv[0],a=(catalog:IdentityDictionary.new),params,ports,mods;
(root+/+"lib/Catalog.scd").load.value(a);
params=File("/tmp/microms-params.csv","w"); ports=File("/tmp/microms-ports.csv","w"); mods=File("/tmp/microms-modules.csv","w");
a[\catalog].keysValuesDo { |id,s|
    mods.write(id.asString++","++s[\family]++"\n");
    s[\params].do { |p| params.write([id,p[\key],p[\min],p[\max],p[\default],p[\warp]].collect(_.asString).join(",")++"\n") };
    [[s[\inputs],"in"],[s[\outputs],"out"]].do { |row| row[0].do { |p| ports.write([id,row[1],p[\key],p[\channels],p[\type]].collect(_.asString).join(",")++"\n") } }
};
params.close; ports.close; mods.close; 0.exit
)
