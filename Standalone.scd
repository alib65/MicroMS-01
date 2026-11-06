/* Standalone launcher wrapper: the IDE entry point remains MicroMS-01.scd. */
(
var root=thisProcess.nowExecutingPath.dirname;
(root+/+"MicroMS-01.scd").load;
~microMS[\window].onClose={
    ~microMS[\window].view.onResize=nil;
    ~microMS[\window]=nil;
    ~microMS[\close].value;
    // Let asynchronous file closure/server shutdown finish before the language exits.
    Routine {
        while { ~microMS[\server].serverRunning or: { ~microMS[\server].serverBooting } } { 0.1.wait };
        0.exit
    }.play(AppClock)
};
)
