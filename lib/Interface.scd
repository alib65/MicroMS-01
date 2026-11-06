{
    |a|
    var bg=Color.fromHexString("080a0d"),panel=Color.fromHexString("15191e"),line=Color.fromHexString("30353c");
    var white=Color.fromHexString("eef0ed"),muted=Color.fromHexString("82909c"),lime=Color.fromHexString("d3ed77");
    var colors=(source:Color.fromHexString("eea35e"),control:Color.fromHexString("d3ed77"),modulation:Color.fromHexString("b5a1ea"),
        filter:Color.fromHexString("e78ca8"),mixing:Color.fromHexString("71c5ba"),effect:Color.fromHexString("83a8f0"),
        utility:Color.fromHexString("b4bdc7"),spatial:Color.fromHexString("64d9e4"),interface:Color.fromHexString("a6b6c2"));
    var text,rect,knobNorm,fromNorm,drawCable,button,label,setup,help,scope,refreshBrowser;
    var w,header,scroll,rack,search,list,category,description,edo,root,channels,mode,preset,power,play,rec,vol;
    var bankFiles=[],bankLabels=[],browserIDs=[],hits=List.new,drag=nil,pending=nil,cursor=0@0,zoom=1,rackWidth=1180,rackHeight=800,showCables=true;
    var font=Font("Helvetica Neue",11),mono=Font("Menlo",10),title=Font("Helvetica Neue",17,true);
    text={ |s,x,y,size=10,color,fontName="Helvetica Neue",bold=false|
        Pen.stringAtPoint(s.asString,x@y,Font(fontName,size,bold),color ? white)
    };
    rect={ |r,color| Pen.fillColor=color; Pen.fillRect(r) };
    knobNorm={ |p,v| if(p[\warp]==\exp) { v.explin(p[\min],p[\max],0,1) } { v.linlin(p[\min],p[\max],0,1) } };
    fromNorm={ |p,v| if(p[\warp]==\exp) { v.linexp(0,1,p[\min],p[\max]) } { v.linlin(0,1,p[\min],p[\max]) } };
    drawCable={ |start,end,color|
        var sag=(start.dist(end)*0.22).clip(35,115);
        Pen.moveTo(start); Pen.curveTo(end,start+(0@sag),end+(0@sag));
        Pen.strokeColor=Color.black.alpha_(0.65); Pen.width=6; Pen.stroke;
        Pen.moveTo(start); Pen.curveTo(end,start+(0@sag),end+(0@sag));
        Pen.strokeColor=color.copy.alpha_(0.84); Pen.width=2.6; Pen.stroke
    };
    button={ |parent,r,s,action,color|
        Button(parent,r).states_([[s,color ? white,Color.fromHexString("242a31")]])
            .font_(Font("Helvetica Neue",10,true)).action_(action)
    };
    label={ |parent,r,s,size=10,color|
        StaticText(parent,r).string_(s).font_(Font("Helvetica Neue",size)).stringColor_(color ? muted)
    };
    help={
        var hw=Window("MicroMS-01 / Getting started",Rect(150,130,740,620)).background_(bg);
        TextView(hw,Rect(22,20,696,576)).editable_(false).background_(bg).stringColor_(white).font_(Font("Helvetica Neue",14)).string_(
"MicroMS-01\nA modular instrument by Ali Balighi\n\n1. Press POWER, then PLAY. The initial patch is ready to hear.\n2. Drag an output jack to an input, or click the two jacks in turn.\n3. Right-click a jack to remove its cables. Inputs take one cable; outputs can feed several inputs. Mono audio, CV and gates can patch into each other. Stereo, ring and AmbiX cables have matching widths.\n4. Drag a knob vertically. Hold Shift for fine changes. Double-click to reset. Click the EDO field to choose any integer from 7 to 120. PITCH signals use octaves; sequencer faders use EDO degrees.\n5. Drag sequence faders to change notes; right-click them to enable/disable gates. Click the gate sequencer cells to edit rhythms. Drag the vector pad to change X and Y.\n6. Search or filter the library, select a module and press ADD. Click a module header to select it. REMOVE deletes the selected module and its cables.\n7. SAVE/OPEN use safe JSON .microms files. SAMPLE loads audio into the selected grain sampler. SCOPE opens the selected module's first output. REC writes floating-point WAV files in recordings/. REC: SELECTED OUT records the selected module's first output directly, including AmbiX or a speaker ring, with a two-output interface.\n\nSpatial audio\nORBIT creates a horizontal 4/8/16/24/32 speaker ring. FIELD encodes ring feeds or a positioned mono source into first-order AmbiX: ACN channel order W,Y,Z,X with SN3D normalization. The decoder creates virtual speaker feeds; EAR renders them for headphones using analytic time and head-shadow cues. Stereo cannot reproduce a surrounding soundfield.\n\nUse headphones for the headphone preview. This is an approximate analytic renderer, not a measured/personalized HRTF. Physical speaker mode needs at least as many configured hardware outputs as active speakers. Set device and channel count in AUDIO SETUP before POWER. Raw AmbiX mode writes W,Y,Z,X to four hardware outputs and recordings; it is not a loudspeaker decoder.\n\nFeedback loops must pass through FEEDBACK / DELAY. PANIC silences the output. Cmd+Period shuts down the engine; POWER restarts it. Closing this window quits its own server.\n\nHardware-inspired digital designs\nThe library covers musical functions from the supplied catalogs using original stock SuperCollider DSP. Named variations share digital engines. Product firmware, exact circuits, proprietary algorithms, USB power, case hardware and physical expanders are not reproduced. See docs/MODULES.md for scope and differences.\n\nAli Balighi © 2026 - Alibalighi.com"); hw.front
    };
    setup={
        var sw,devices,outputs,inputs,op,ip,oc,ic;
        if(a[\running] or: { a[\booting] ? false }) { a[\status].value("Turn POWER off before changing audio hardware.") } {
            devices=["System default"]++ServerOptions.outDevices;
            inputs=["System default"]++ServerOptions.inDevices;
            sw=Window("MicroMS-01 / Audio setup",Rect(200,180,510,330)).background_(bg);
            label.value(sw,Rect(24,18,450,26),"AUDIO ENGINE",18,white);
            label.value(sw,Rect(24,58,150,22),"OUTPUT DEVICE");
            op=PopUpMenu(sw,Rect(180,58,300,26)).items_(devices);
            if(a[\device].notNil) { op.value=devices.indexOfEqual(a[\device]) ? 0 };
            label.value(sw,Rect(24,100,150,22),"HARDWARE OUTPUTS");
            outputs=[2,4,8,16,24,32]; oc=PopUpMenu(sw,Rect(180,100,120,26)).items_(outputs.collect(_.asString));
            oc.value=outputs.indexOf(a[\hardware]);
            label.value(sw,Rect(24,144,150,22),"INPUT DEVICE");
            ip=PopUpMenu(sw,Rect(180,144,300,26)).items_(inputs);
            if(a[\inputDevice].notNil) { ip.value=inputs.indexOfEqual(a[\inputDevice]) ? 0 };
            label.value(sw,Rect(24,186,150,22),"INPUT CHANNELS");
            ic=PopUpMenu(sw,Rect(180,186,120,26)).items_(["Disabled","2","4","8","16","32"]);
            ic.value=[0,2,4,8,16,32].indexOf(a[\inputs] ? 0);
            label.value(sw,Rect(24,228,450,28),"Choose channel counts supported by your audio interface.");
            button.value(sw,Rect(330,274,150,30),"APPLY",{
                a[\device]=if(op.value==0){nil}{devices[op.value]};
                a[\inputDevice]=if(ip.value==0){nil}{inputs[ip.value]};
                a[\hardware]=outputs[oc.value]; a[\inputs]=[0,2,4,8,16,32][ic.value];
                a[\syncGlobals].value; sw.close; a[\status].value("Audio configuration saved. Press POWER.")
            },lime); sw.front
        }
    };
    scope={
        var m=a[\selected],port,buf,sv,win,node;
        if(a[\running] and: { m.notNil }) {
            port=a[\spec].value(m)[\outputs].first;
            if(port.notNil) {
                a[\scopeWindow] !? _.close;
                win=Window("MicroMS-01 / "++a[\spec].value(m)[\name],Rect(160,200,680,280)).background_(bg);
                buf=Buffer.alloc(a[\server],4096,1);
                sv=ScopeView(win,Rect(12,12,656,250)).server_(a[\server]).bufnum_(buf.bufnum).background_(bg).waveColors_([lime]).yZoom_(m[\params][\gain] ? 1);
                node=SynthDef(\mms_scope,{ |bus=0,buf=0| ScopeOut2.ar(In.ar(bus,1),buf,4096,2048) }).play(a[\server].defaultGroup,[\bus,m[\buses][port[\key]].index,\buf,buf.bufnum],\addToTail);
                node.register(true);
                sv.start; win.onClose={
                    if(node.isPlaying and: { a[\server].serverRunning }) { node.free; buf.free };
                    sv.stop; a[\scopeWindow]=nil
                }; a[\scopeWindow]=win; win.front
            } { a[\status].value("Select a module with an output to inspect.") }
        } { a[\status].value("Start POWER and select a module to scope.") }
    };
    a[\gui]={
        var bounds=Window.screenBounds,width,height;
        width=1550.min(bounds.width-60); height=1000.min(bounds.height-80);
        w=Window("MicroMS-01 · Ali Balighi",Rect(25,40,width,height)).background_(bg);
        a[\window]=w;
        w.view.minSize=1280@680;
        header=UserView(w,Rect(0,0,width,71)).background_(bg);
        header.drawFunc={
            text.value("µ",22,8,37,lime,"Helvetica Neue",true);
            text.value("MicroMS-01",64,14,26,white,"Helvetica Neue",true);
            text.value("MICROTONAL MODULAR SYSTEM",66,45,8,muted,"Menlo");
            text.value("01",330,19,26,Color.grey(0.3),"Menlo");
            if(w.bounds.width>1280) {
                text.value(if(a[\running]){"ENGINE ONLINE"}{"ENGINE OFFLINE"},1090,24,8,muted,"Menlo");
                [0,1].do { |j|
                    var xx=1230+(j*96),level=a[\meters][j].ampdb.linlin(-60,0,0,1).clip(0,1);
                    rect.value(Rect(xx,29,80,5),line); rect.value(Rect(xx,29,80*level,5),lime)
                }
            };
            rect.value(Rect(0,70,w.bounds.width,1),line)
        };
        power=button.value(w,Rect(400,20,80,30),"POWER",{ if(a[\running]){a[\shutdown].value}{a[\boot].value} },lime);
        play=button.value(w,Rect(488,20,74,30),"PLAY",{ if(a[\running]){a[\play].value(a[\playing].not)}{a[\status].value("Press POWER to start audio.")} },lime);
        rec=button.value(w,Rect(570,20,64,30),"REC",{ a[\record].value });
        button.value(w,Rect(642,20,68,30),"PANIC",{ a[\play].value(false) },Color.fromHexString("ed9e9e"));
        button.value(w,Rect(728,20,65,30),"OPEN",{ Dialog.openPanel({ |p| a[\load].value(p) }) });
        button.value(w,Rect(801,20,65,30),"SAVE",{ Dialog.savePanel({ |p| a[\save].value(p) }) });
        button.value(w,Rect(874,20,100,30),"AUDIO SETUP",{ setup.value });
        button.value(w,Rect(982,20,60,30),"HELP",{ help.value });
        label.value(w,Rect(22,86,66,17),"TUNING",9);
        edo=NumberBox(w,Rect(87,82,52,26)).clipLo_(7).clipHi_(120).decimals_(0).step_(1).value_(a[\edo]).action_({ |v| a[\edo]=v.value.round(1).asInteger; a[\syncGlobals].value });
        label.value(w,Rect(146,86,32,17),"EDO",10,lime);
        root=NumberBox(w,Rect(189,82,76,26)).clipLo_(20).clipHi_(2000).decimals_(2).value_(a[\rootHz]).action_({ |v| a[\rootHz]=v.value; a[\syncGlobals].value });
        label.value(w,Rect(271,86,42,17),"Hz root",9);
        label.value(w,Rect(330,86,64,17),"SPEAKERS",9);
        channels=PopUpMenu(w,Rect(397,82,65,26)).items_(["4","8","16","24","32"]).value_(1).action_({ |v|
            if(a[\recording] ? false) { a[\status].value("Stop recording before changing the speaker ring.") }
            { a[\channels]=[4,8,16,24,32][v.value]; a[\syncGlobals].value }
        });
        mode=PopUpMenu(w,Rect(475,82,166,26)).items_(["STEREO DOWNMIX","HEADPHONE PREVIEW","PHYSICAL SPEAKERS","RAW AMBIX / 4CH"]).value_(1).action_({ |v|
            if(a[\recording] ? false) { a[\status].value("Stop recording before changing output format.") }
            { a[\mode]=v.value; a[\syncGlobals].value }
        });
        bankFiles=PathName(a[\root]+/+"presets").files.select { |p|
            (p.extension=="microms") and: { ["Orbital-19.microms","Glass-Garden-31.microms"].includesEqual(p.fileName).not }
        }.sort { |x,y| x.fileName<y.fileName };
        bankLabels=bankFiles.collect { |p| p.fileNameWithoutExtension.replace("-"," ") };
        a[\factoryPresetFiles]=bankFiles;
        preset=PopUpMenu(w,Rect(656,82,182,26)).items_(["19 EDO / Orbital Sequence","31 EDO / Glass Garden","Empty rack"]++bankLabels).action_({ |v|
            if(v.value<3) { a[\preset].value([\orbit,\glass,\empty][v.value]) }
            { a[\load].value(bankFiles[v.value-3].fullPath) }
        });
        label.value(w,Rect(856,86,45,17),"LEVEL",9);
        vol=Slider(w,Rect(906,87,92,16)).value_(a[\volume]).action_({ |v| a[\volume]=v.value; a[\syncGlobals].value });
        label.value(w,Rect(22,128,160,18),"MODULE LIBRARY",10,white);
        search=TextField(w,Rect(22,157,192,29)).background_(panel).stringColor_(white).string_("").toolTip_("Search module names or hardware references; press Return to filter").action_({ refreshBrowser.value });
        category=PopUpMenu(w,Rect(22,196,192,26)).items_(a[\categories].collect { |c| c.asString.toUpper }).action_({ refreshBrowser.value });
        list=ListView(w,Rect(22,232,192,height-480)).background_(bg).stringColor_(white).hiliteColor_(Color.fromHexString("303b29")).font_(Font("Helvetica Neue",11));
        list.action={ |v|
            var spec=a[\catalog][browserIDs[v.value]];
            if(spec.notNil) { description.string=spec[\description]++"\n\nReference: "++spec[\reference]; description.stringColor=muted }
        };
        list.mouseDownAction={ |v,x,y,mod,btn,count| if(count==2) { var id=browserIDs[list.value]; if(id.notNil) { a[\add].value(id) } } };
        button.value(w,Rect(22,height-238,192,32),"+ ADD MODULE",{ var id=browserIDs[list.value]; if(id.notNil) { a[\add].value(id) } },lime);
        description=TextView(w,Rect(18,height-195,202,125)).editable_(false).background_(bg).stringColor_(muted).font_(Font("Helvetica Neue",10));
        label.value(w,Rect(236,128,350,18),"RACK 01   /   SYNTHESIS + SPATIAL AUDIO",10,white);
        button.value(w,Rect(660,122,74,24),"CABLES",{ showCables=showCables.not; rack.refresh });
        button.value(w,Rect(742,122,68,24),"SAMPLE",{
            if(a[\selected].notNil and: { a[\spec].value(a[\selected])[\family]==\sampler }) {
                Dialog.openPanel({ |p| a[\loadSample].value(a[\selected],p) })
            } { a[\status].value("Select a GRAIN / SAMPLER module first.") }
        });
        button.value(w,Rect(818,122,64,24),"SCOPE",{ scope.value });
        button.value(w,Rect(890,122,96,24),"MIDI CONNECT",{ a[\midi].value });
        button.value(w,Rect(994,122,72,24),"REMOVE",{ a[\remove].value(a[\selected]) });
        PopUpMenu(w,Rect(1082,122,164,24)).items_(["REC: MONITOR","REC: SELECTED OUT"]).action_({ |v| a[\recordSource]=v.value });
        scroll=ScrollView(w,Rect(234,156,width-252,height-226)).hasHorizontalScroller_(true).hasVerticalScroller_(true).background_(bg);
        rack=UserView(scroll,Rect(0,0,rackWidth,rackHeight)).background_(bg).canFocus_(true);
        a[\rack]=rack;
        a[\statusView]=label.value(w,Rect(24,height-51,width-410,20),"Ready. POWER starts the engine; PLAY starts the sequence.",10);
        label.value(w,Rect(width-355,height-51,335,20),"Ali Balighi © 2026 - Alibalighi.com",11,white).resize_(3);
        a[\layout]={
            var x=12,y=28,row=0;
            rackWidth=((w.bounds.width-270).max(1000)/2).floor*2;
            a[\modules].do { |m|
                var spec=a[\spec].value(m),mw=spec[\width];
                if((x+mw)>(rackWidth-12)) { x=12; y=y+382; row=row+1 };
                m[\rect]=Rect(x,y,mw,354); x=x+mw+8
            };
            rackHeight=(y+386).max(scroll.bounds.height-20);
            rack.bounds=Rect(0,0,rackWidth,rackHeight); rack.refresh
        };
        refreshBrowser={
            var needle=search.string.toLower,cat=a[\categories][category.value];
            browserIDs=a[\catalog].keys.asArray.select { |id|
                var spec=a[\catalog][id];
                ((cat==\all) or: { spec[\category]==cat }) and: {
                    (spec[\name]++" "++spec[\reference]++" "++spec[\category]).toLower.find(needle).notNil or: { needle.isEmpty }
                }
            }.sort { |x,y| a[\catalog][x][\name]<a[\catalog][y][\name] };
            list.items=browserIDs.collect { |id| a[\catalog][id][\name] }; if(browserIDs.notEmpty) { list.value=0; list.doAction }
        };
        a[\refreshUI]={
            power.states=[[if(a[\running]){"POWER ON"}{"POWER"},if(a[\running]){bg}{lime},if(a[\running]){lime}{panel}]];
            play.states=[[if(a[\playing]){"STOP"}{"PLAY"},lime,if(a[\playing]){Color.fromHexString("303c25")}{panel}]];
            rec.states=[[if(a[\recording] ? false){"REC ●"}{"REC"},if(a[\recording] ? false){Color.red}{white},panel]];
            edo.value=a[\edo]; root.value=a[\rootHz]; channels.value=[4,8,16,24,32].indexOf(a[\channels]); mode.value=a[\mode];
            header.refresh
        };
        rack.drawFunc={
            var jackPoints=Dictionary.new;
            hits=List.new;
            (rackHeight/382).ceil.asInteger.do { |row|
                var y=(row*382)+12;
                rect.value(Rect(4,y,rackWidth-8,7),Color.fromHexString("22272d"));
                text.value("R"++(row+1).asString.padLeft(2,"0"),10,y-12,8,muted,"Menlo")
            };
            a[\modules].do { |m|
                var spec=a[\spec].value(m),r=m[\rect],accent=colors[spec[\category]],h=354,knobCols=2;
                var outs=spec[\outputs],ins=spec[\inputs],slots=if(r.width<160){2}{4},outRows,inRows,outY,inY;
                var selected=a[\selected]===m;
                outRows=(outs.size/slots).ceil.asInteger; inRows=(ins.size/slots).ceil.asInteger;
                outY=h-35-((outRows-1).max(0)*34);
                inY=outY-22-(inRows*34);
                Pen.use {
                    Pen.translate(r.left,r.top);
                    rect.value(Rect(0,0,r.width,h),panel);
                    rect.value(Rect(0,0,r.width,3),accent);
                    rect.value(Rect(0,3,r.width,47),accent.copy.alpha_(0.055));
                    Pen.strokeColor=if(selected){accent.copy.alpha_(0.8)}{line}; Pen.width=1; Pen.strokeRect(Rect(0,0,r.width,h));
                    [10,r.width-10].do { |x| [11,h-11].do { |y|
                        Pen.fillColor=Color.fromHexString("383e44"); Pen.fillOval(Rect.aboutPoint(x@y,3,3));
                        Pen.strokeColor=bg; Pen.line((x-2)@y,(x+2)@y); Pen.stroke
                    } };
                    text.value(spec[\category].asString.toUpper,20,12,7,accent,"Menlo");
                    text.value(spec[\name],14,27,if(r.width<180){12}{14},white,"Helvetica Neue",true);
                    text.value(m[\id].asString.padLeft(2,"0"),r.width-28,14,7,muted,"Menlo");
                    hits.add((kind:\header,module:m,rect:Rect(r.left,r.top,r.width,51)));
                    spec[\params].do { |p,j|
                        var x=(r.width/4)+((j%2)*(r.width/2)),y=78+((j/2).floor*58);
                        var val=m[\params][p[\key]],norm=knobNorm.value(p,val),angle=(0.75pi)+(norm*1.5pi),value;
                        text.value(p[\label],x-30,y-17,7,muted,"Menlo");
                        Pen.strokeColor=Color.fromHexString("3d444b"); Pen.width=2.5; Pen.addArc(x@y,15,0.75pi,1.5pi); Pen.stroke;
                        Pen.strokeColor=accent; Pen.addArc(x@y,15,0.75pi,(norm*1.5pi).max(0.001)); Pen.stroke;
                        Pen.fillColor=Color.fromHexString("090c10"); Pen.fillOval(Rect.aboutPoint(x@y,11,11));
                        Pen.strokeColor=Color.fromHexString("454b53"); Pen.width=1; Pen.strokeOval(Rect.aboutPoint(x@y,11,11));
                        Pen.strokeColor=white; Pen.width=1.7; Pen.line((x+(angle.cos*4))@(y+(angle.sin*4)),(x+(angle.cos*9))@(y+(angle.sin*9))); Pen.stroke;
                        value=if(p[\choices].notNil){p[\choices][val.asInteger.clip(0,p[\choices].size-1)]}{if(val.abs>=100){val.round(1).asInteger.asString}{val.round(0.01).asString}++p[\unit]};
                        text.value(value,x-23,y+20,8,accent,"Menlo");
                        hits.add((kind:\knob,module:m,param:p,rect:Rect(r.left+x-23,r.top+y-19,46,53)))
                    };
                    if(spec[\family]==\sequencer) {
                        8.do { |j|
                            var x=18+(j*((r.width-36)/8)),value=m[\steps][j],y=143;
                            rect.value(Rect(x,y,19,69),bg); rect.value(Rect(x+7,y+3,3,64),line);
                            rect.value(Rect(x+2,y+64-value.clip(a[\edo].neg,a[\edo]*2).linlin(a[\edo].neg,a[\edo]*2,0,64),15,5),if(m[\gates][j]==1){accent}{muted});
                            text.value(value.asInteger,x,222,8,accent,"Menlo");
                            Pen.fillColor=if(a[\playing] and: { m[\step]==j }){accent}{line}; Pen.fillOval(Rect(x+6,132,5,5));
                            hits.add((kind:\step,module:m,index:j,rect:Rect(r.left+x,r.top+y,22,87)))
                        }
                    };
                    if(spec[\family]==\gates) {
                        4.do { |lane| 16.do { |j|
                            var x=14+(j*((r.width-28)/16)),y=132+(lane*24),bw=((r.width-28)/16)-3;
                            rect.value(Rect(x,y,bw,17),if(m[\patterns][lane][j]==1){accent.copy.alpha_(0.8)}{line});
                            if(a[\playing] and: { m[\step]==j }) { Pen.strokeColor=white; Pen.strokeRect(Rect(x,y,bw,17)) };
                            hits.add((kind:\cell,module:m,lane:lane,index:j,rect:Rect(r.left+x,r.top+y,bw,17)))
                        } }
                    };
                    if(spec[\family]==\xy) {
                        var box=Rect(22,179,r.width-44,47),x,y;
                        rect.value(box,bg); Pen.strokeColor=line; Pen.strokeRect(box);
                        x=m[\params][\x].linlin(-1,1,box.left,box.right); y=m[\params][\y].linlin(-1,1,box.bottom,box.top);
                        Pen.strokeColor=accent.copy.alpha_(0.5); Pen.line(x@box.top,x@box.bottom); Pen.line(box.left@y,box.right@y); Pen.stroke;
                        Pen.fillColor=accent; Pen.fillOval(Rect.aboutPoint(x@y,4,4));
                        hits.add((kind:\xy,module:m,rect:Rect(r.left+box.left,r.top+box.top,box.width,box.height)))
                    };
                    if(spec[\family]==\spatial) {
                        var center=(r.width/2)@220,angle=if(a[\playing]){(m[\phase] ? 0)*2pi}{m[\params][\azimuth]*pi/180};
                        Pen.strokeColor=line; Pen.width=1; Pen.strokeOval(Rect.aboutPoint(center,36,36));
                        a[\channels].do { |j| var theta=(j*2pi/a[\channels])-0.5pi; Pen.fillColor=accent; Pen.fillOval(Rect.aboutPoint(center+((theta.cos*36)@(theta.sin*36)),2,2)) };
                        Pen.fillColor=white; Pen.fillOval(Rect.aboutPoint(center+((angle.sin.neg*23)@(angle.cos.neg*23)),4,4));
                        text.value(a[\channels].asString++" CH",center.x-15,216,8,accent,"Menlo")
                    };
                    if(spec[\family]==\scope) {
                        text.value((m[\frequency] ? 0).round(0.1).asString++" Hz",24,153,21,accent,"Menlo");
                        text.value("ESTIMATED FUNDAMENTAL",24,184,7,muted,"Menlo");
                        rect.value(Rect(24,216,r.width-48,6),bg);
                        rect.value(Rect(24,216,(r.width-48)*((m[\peak] ? 0).clip(0,1)),6),accent)
                    };
                    if(spec[\family]==\monitor) {
                        [0,1].do { |j|
                            var x=30+(j*100),peak=a[\meters][j],level=peak.ampdb.linlin(-60,0,0,1).clip(0,1);
                            rect.value(Rect(x,88,52,104),bg);
                            20.do { |k| rect.value(Rect(x+5,184-(k*4.6),42,3),if((k/20)<level){if(k>17){Color.fromHexString("ee8e7d")}{lime}}{Color.fromHexString("222a24")}) };
                            text.value(["L","R"][j],x+21,202,9,muted,"Menlo")
                        };
                        text.value(["STEREO","HEADPHONES","SPEAKER RING","AMBIX / FOA"][a[\mode]],29,231,12,lime,"Menlo");
                        text.value("ACN / SN3D  ·  LIMIT -0.5dB",23,251,8,muted,"Menlo")
                    };
                    if(spec[\params].isEmpty and: { [\monitor].includes(spec[\family]).not }) { text.value("SIGNAL UTILITY",15,90,9,muted,"Menlo") };
                    [[ins,\in,inY],[outs,\out,outY]].do { |row|
                        var ports=row[0],direction=row[1],base=row[2];
                        if(ports.notEmpty) {
                            Pen.strokeColor=line; Pen.width=1; Pen.line(12@(base-13),(r.width-12)@(base-13)); Pen.stroke;
                            text.value(if(direction==\in){"IN"}{"OUT"},12,base-25,7,muted,"Menlo");
                            ports.do { |p,j|
                                var x=((j%slots)+0.5)*(r.width/slots),y=base+((j/slots).floor*34);
                                var color=if(direction==\out){accent}{muted},connected;
                                connected=a[\cables].any { |c| if(direction==\out){c[\from]==m[\id] and: { c[\output]==p[\key] }}{c[\to]==m[\id] and: { c[\input]==p[\key] }} };
                                Pen.fillColor=Color.fromHexString("030506"); Pen.fillOval(Rect.aboutPoint(x@y,7,7));
                                Pen.strokeColor=if(connected){accent}{color}; Pen.width=2; Pen.strokeOval(Rect.aboutPoint(x@y,7,7));
                                if(connected) { Pen.fillColor=accent; Pen.fillOval(Rect.aboutPoint(x@y,3,3)) };
                                if(p[\channels]>1) { text.value(if(p[\type]==\ring){"32"}{p[\channels]},x-4,y-4,6,color,"Menlo") };
                                text.value(p[\label],x-((p[\label].size*4.0)/2),y+10,7,color,"Menlo");
                                jackPoints[[m[\id],direction,p[\key]].asString]=r.origin+(x@y);
                                hits.add((kind:\jack,module:m,port:p,direction:direction,point:r.origin+(x@y),rect:Rect.aboutPoint(r.origin+(x@y),11,11)))
                            }
                        }
                    }
                }
            };
            if(showCables) {
                a[\cables].do { |c|
                    var src=jackPoints[[c[\from],\out,c[\output]].asString],dst=jackPoints[[c[\to],\in,c[\input]].asString];
                    var m=a[\find].value(c[\from]);
                    if(src.notNil and: { dst.notNil }) { drawCable.value(src,dst,colors[a[\spec].value(m)[\category]]) }
                }
            };
            a[\hitRegions]=hits;
            if(pending.notNil) { drawCable.value(pending[\point],cursor,white) };
            if(a[\modules].isEmpty) { text.value("Your next instrument starts here.",50,90,26,white); text.value("Choose a module from the library, then + ADD MODULE.",52,137,14,muted) }
        };
        rack.mouseDownAction={ |v,x,y,mod,btn,clicks|
            var point=x@y,hit=hits.reverse.detect { |h| h[\rect].contains(point) };
            cursor=point;
            if(hit.notNil) {
                a[\selected]=hit[\module];
                case
                { hit[\kind]==\jack } {
                    if(btn==1 or: { mod.isCtrl }) { a[\disconnect].value(hit[\module][\id],hit[\port][\key],hit[\direction]); pending=nil }
                    {
                        if(pending.notNil and: { pending[\direction]!=hit[\direction] }) {
                            var out=if(hit[\direction]==\out){hit}{pending},in=if(hit[\direction]==\in){hit}{pending};
                            a[\connect].value(out[\module][\id],out[\port][\key],in[\module][\id],in[\port][\key]); pending=nil
                        } { pending=hit; drag=(kind:\cable,start:point) }
                    }
                }
                { hit[\kind]==\knob } {
                    if(clicks==2) { a[\set].value(hit[\module],hit[\param][\key],hit[\param][\default]) }
                    { drag=hit.copy.put(\start,point).put(\initial,knobNorm.value(hit[\param],hit[\module][\params][hit[\param][\key]])) }
                }
                { hit[\kind]==\step } {
                    if(btn==1) {
                        var m=hit[\module]; m[\gates][hit[\index]]=1-m[\gates][hit[\index]];
                        if(a[\running]) { m[\node].setn(\gates,m[\gates]) }
                    } { drag=hit }
                }
                { hit[\kind]==\cell } {
                    var m=hit[\module],lane=hit[\lane],j=hit[\index];
                    m[\patterns][lane][j]=1-m[\patterns][lane][j];
                    if(a[\running]) { m[\node].setn(("lane"++lane).asSymbol,m[\patterns][lane]) }; a[\dirty]=true
                }
                { hit[\kind]==\xy } { drag=hit }
                { true } { pending=nil };
                description.string=a[\spec].value(hit[\module])[\description]; description.stringColor=muted
            } { pending=nil; a[\selected]=nil };
            rack.refresh
        };
        rack.mouseMoveAction={ |v,x,y,mod|
            cursor=x@y;
            if(drag.notNil) {
                case
                { drag[\kind]==\knob } {
                    var delta=(drag[\start].y-y)/if(mod.isShift){1800}{180};
                    a[\set].value(drag[\module],drag[\param][\key],fromNorm.value(drag[\param],(drag[\initial]+delta).clip(0,1)))
                }
                { drag[\kind]==\step } {
                    var m=drag[\module],value=(drag[\rect].top+64-y).linlin(0,64,a[\edo].neg,a[\edo]*2).round(1).clip(a[\edo].neg,a[\edo]*2);
                    m[\steps][drag[\index]]=value;
                    if(a[\running]) { m[\node].setn(\steps,m[\steps]) }; a[\dirty]=true
                }
                { drag[\kind]==\xy } {
                    var r=drag[\rect];
                    a[\set].value(drag[\module],\x,x.linlin(r.left,r.right,-1,1).clip(-1,1));
                    a[\set].value(drag[\module],\y,y.linlin(r.top,r.bottom,1,-1).clip(-1,1))
                }
            }; rack.refresh
        };
        rack.mouseOverAction={ |v,x,y| if(pending.notNil) { cursor=x@y; rack.refresh } };
        rack.mouseUpAction={ |v,x,y|
            if(drag.notNil and: { drag[\kind]==\cable } and: { drag[\start].dist(x@y)>5 }) {
                var hit=hits.reverse.detect { |h| (h[\kind]==\jack) and: { h[\rect].contains(x@y) } };
                if(hit.notNil and: { pending.notNil } and: { pending[\direction]!=hit[\direction] }) {
                    var out=if(hit[\direction]==\out){hit}{pending},in=if(hit[\direction]==\in){hit}{pending};
                    a[\connect].value(out[\module][\id],out[\port][\key],in[\module][\id],in[\port][\key])
                }; pending=nil
            }; drag=nil; rack.refresh
        };
        rack.keyDownAction={ |v,char,mod,unicode,keycode| if(unicode==27) { pending=nil; drag=nil; rack.refresh } };
        w.view.onResize={
            if(w.isClosed.not) {
            var ww=w.bounds.width,hh=w.bounds.height;
            header.bounds=Rect(0,0,ww,71); scroll.bounds=Rect(234,156,ww-252,hh-226);
            list.bounds=Rect(22,232,192,hh-480);
            // The lower library controls follow the window height.
            w.view.children.select { |v| v.isKindOf(Button) and: { v.states[0][0]=="+ ADD MODULE" } }.do { |v| v.bounds=Rect(22,hh-238,192,32) };
            description.bounds=Rect(18,hh-195,202,125);
            a[\statusView].bounds=Rect(24,hh-51,ww-410,20);
            a[\layout].value
            }
        };
        w.onClose={ w.view.onResize=nil; a[\window]=nil; a[\close].value };
        refreshBrowser.value; a[\layout].value; a[\refreshUI].value; w.front;
    }
}
