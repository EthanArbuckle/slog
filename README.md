# slog

An iOS crash log symbolication tool for jailbroken devices.

## Usage

Run `slog` to view the latest crash report:

```
iPad:~ root# slog
```

The tool will automatically:
1. Find the most recent .ips crash log in `/var/mobile/Library/Logs/CrashReporter`
2. Symbolicate the crash log
3. Display pretty output with:
   - Incident and device information
   - Exception type and details
   - Crashed thread stack trace


```
Usage: slog [options] [crash_file]
  Running without options will display the most recent crash log

Actions:
  -i, --ips <file>      Display a specific crash log
  -l, --list            List recent crash logs. (default: 15)
      --show            Print the crash log directory path
      --clear           Clear all crash logs
  -h, --help            Show this help message
  -v, --version         Show version information
Options:
  -a, --all             Display full contents of crash log
  -n  --limit <num>     Limit the number of crash logs to list/symbolicate
  -f, --filter <app>    Filter crashes by process name. Can be used with -l
  -d  --delete          Delete the crash log after displaying it
  -p  --path <path>      Specify the path to the crash log directory
```

## Output

![screenshot img](imgs/slog.png)

```
iPad:~ root# slog -a
Crash log: /var/mobile/Library/Logs/CrashReporter/Apollo-2024-12-15-0000.ips

Incident Identifier: 0000-0000-0000-0000-0000
CrashReporter Key:   00000000-0000-0000-0000-000000000000
Hardware Model:      iPad7,11
Process:             Apollo [47438]
Path:                /private/var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Apollo
Identifier:          com.christianselig.Apollo
Version:             1.15.11 (285)
AppStoreTools:       14E221
Code Type:           ARM-64 (Native)
Role:                Foreground
Parent Process:      launchd [1]
Coalition:           com.christianselig.Apollo [2877]
Date/Time:           2024-12-15 02:12:22.0000
Launch Time:         2024-12-15 02:12:22.0000
OS Version:          iPhone OS 17.6.1 (21G101)
Release Type:        User
Report Version:      104
Exception Type:  EXC_BAD_ACCESS (SIGSEGV)
Exception Subtype: KERN_INVALID_ADDRESS at 0x0000000000000000
Exception Codes: 0x0000000000000001, 0x0000000000000000
VM Region Info: 0 is not in any region.  Bytes before following region: 4296015000
      REGION TYPE                 START - END      [ VSIZE] PRT/MAX SHRMOD  REGION DETAIL
      UNUSED SPACE AT START
--->
      __TEXT                   100100000-100cb0000 [ 11.7M] r-x/r-x SM=COW  /var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Apollo
Termination Reason: SIGNAL 11 Segmentation fault: 11
Terminating Process: exc handler [47438]
Triggered by Thread:  0

Thread 0 name:   Dispatch queue: com.apple.main-thread

Thread 0 Crashed:
0   libobjsee.dylib                0x100f31f84          loader_init + 60
1   dyld                           0x1010fa218          invocation function for block in dyld4::Loader::findAndRunAllInitializers(dyld4::RuntimeState&) const::$_0::operator()() const + 152
2   dyld                           0x1010e78c8          invocation function for block in dyld3::MachOAnalyzer::forEachInitializer(Diagnostics&, dyld3::MachOAnalyzer::VMAddrConverter const&, void (unsigned int) block_pointer, void const*) const + 332
3   dyld                           0x1010e6a6c          invocation function for block in dyld3::MachOFile::forEachSection(void (dyld3::MachOFile::SectionInfo const&, bool, bool&) block_pointer) const + 488
4   dyld                           0x1010e5cc4          dyld3::MachOFile::forEachLoadCommand(Diagnostics&, void (load_command const*, bool&) block_pointer) const + 284
5   dyld                           0x1010fb928          dyld3::MachOFile::forEachSection(void (dyld3::MachOFile::SectionInfo const&, bool, bool&) block_pointer) const + 164
6   dyld                           0x1010f0594          dyld3::MachOAnalyzer::forEachInitializer(Diagnostics&, dyld3::MachOAnalyzer::VMAddrConverter const&, void (unsigned int) block_pointer, void const*) const + 376
7   dyld                           0x1010f01f0          dyld4::Loader::findAndRunAllInitializers(dyld4::RuntimeState&) const + 212
8   dyld                           0x1010f16a8          dyld4::JustInTimeLoader::runInitializers(dyld4::RuntimeState&) const + 32
9   dyld                           0x1010ef9bc          dyld4::Loader::runInitializersBottomUp(dyld4::RuntimeState&, dyld3::Array<dyld4::Loader const*>&) const + 216
10  dyld                           0x1010f5298          dyld4::Loader::runInitializersBottomUpPlusUpwardLinks(dyld4::RuntimeState&) const::$_1::operator()() const + 108
11  dyld                           0x1010f51ec          dyld4::Loader::runInitializersBottomUpPlusUpwardLinks(dyld4::RuntimeState&) const + 84
12  dyld                           0x1010e5240          dyld4::APIs::runAllInitializersForMain() + 268
13  dyld                           0x1010f9c38          dyld4::prepare(dyld4::APIs&, dyld3::MachOAnalyzer const*) + 2820
14  dyld                           0x10111b1d8          start + 1440

Thread 0 crashed with ARM Thread State (64-bit):
   x0: 0x000000016fcffaf5	x1: 0x0000000000000103	x2: 0x0000000000000103	x3: 0x0000000000000103
   x4: 0x00000001f8f89f98	x5: 0x0000000000000000	x6: 0x0000000000000000	x7: 0x0000000000000df0
   x8: 0x0000000000000000	x9: 0x0000000000000005	x10:0x00000000fffffff3	x11:0x00000003024e4028
   x12:0x000000000000000c	x13:0x000000000000003d	x14:0x0000000000000000	x15:0x0000000100f3a526
   x16:0x00000001e1d4dbec	x17:0x0000000000000047	x18:0x0000000000000000	x19:0x000000016fcf80e8
   x20:0x0000000100ed1d00	x21:0x0000000100f31f48	x22:0x0000000100f399d8	x23:0x0000000100f28248
   x24:0x0000000100f28158	x25:0x0000000100f287c0	x26:0x0000000100f28248	x27:0x000000016fcff268
   x28:0x000000001f070004	fp: 0x000000016fcf7bb0	lr: 0x0000000100f31f60
   sp: 0x000000016fcf7b30	pc: 0x0000000100f31f84	cpsr:0x20000000
   far:0x0000000000000000	esr:0x92000046        	(Data Abort) byte write Translation fault

Binary Images:
       0x1010e4000 -        0x101163fff dyld arm64  <3f97036d30e130f08817ade7de64868c> /cores/usr/lib/dyld
       0x1021e8000 -        0x1021f3fff 0Cr4shed.dylib arm64  <2e14898dc79837fbafc08d31686cab8b> /private/preboot/C4C12A04D85FF72667E87729BDDDAE3CB222158632EFC65A343DB240B8A82A0871143A7D4611CB0FB398A3E9F5F4D850/jb-XqdYf2hT/procursus/usr/lib/TweakInject/0Cr4shed.dylib
       0x102204000 -        0x102217fff Cephei arm64  <9a32fd2a1d0c3de6ac49d0897d66d86a> /private/preboot/C4C12A04D85FF72667E87729BDDDAE3CB222158632EFC65A343DB240B8A82A0871143A7D4611CB0FB398A3E9F5F4D850/jb-XqdYf2hT/procursus/Library/Frameworks/Cephei.framework/Cephei
       0x102228000 -        0x10224ffff libellekit.dylib arm64  <5e4752c3e4b130ec80176720a34ad2db> /private/preboot/C4C12A04D85FF72667E87729BDDDAE3CB222158632EFC65A343DB240B8A82A0871143A7D4611CB0FB398A3E9F5F4D850/jb-XqdYf2hT/procursus/usr/lib/libellekit.dylib
       0x100f4c000 -        0x100f7bfff AFNetworking arm64  <74cd85ceb9a73ad5b1781899284530c5> /private/var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Frameworks/AFNetworking.framework/AFNetworking
       0x1015d0000 -        0x10170ffff AsyncDisplayKit arm64  <99e7085f15a836448ce0b54f3395e506> /private/var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Frameworks/AsyncDisplayKit.framework/AsyncDisplayKit
       0x101900000 -        0x1019dffff Charts arm64  <c680ce753b1939d1a8b4640314ba1252> /private/var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Frameworks/Charts.framework/Charts
       0x100fdc000 -        0x100ffffff CocoaLumberjack arm64  <6340f4f187763b799aad15de7889c857> /private/var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Frameworks/CocoaLumberjack.framework/CocoaLumberjack
       0x101c80000 -        0x101d47fff Eureka arm64  <00f5ad36b5e83e768ff1cc79a4ee73f4> /private/var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Frameworks/Eureka.framework/Eureka
       0x101044000 -        0x10104ffff FLAnimatedImage arm64  <0d5a126841e83cac9d33c1601da68dfa> /private/var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Frameworks/FLAnimatedImage.framework/FLAnimatedImage
       0x101068000 -        0x101073fff IGListDiffKit arm64  <5ddd14edb8803bec87b9bb5f472b069b> /private/var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Frameworks/IGListDiffKit.framework/IGListDiffKit
       0x101f58000 -        0x101f7ffff IGListKit arm64  <decde502d6233521b66159b0cec03212> /private/var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Frameworks/IGListKit.framework/IGListKit
       0x101088000 -        0x10108ffff Lockbox arm64  <9771e2001078302ca5404e2cbf8e8fce> /private/var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Frameworks/Lockbox.framework/Lockbox
       0x1010a0000 -        0x1010b3fff Mantle arm64  <2c8c2c115e6b38b5b063692643a9de0c> /private/var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Frameworks/Mantle.framework/Mantle
       0x101fc4000 -        0x101fdbfff PINCache arm64  <50e2b68891ef390387520746c4786e55> /private/var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Frameworks/PINCache.framework/PINCache
       0x102008000 -        0x10200ffff PINOperation arm64  <199433df649233d88bf3648a826f590d> /private/var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Frameworks/PINOperation.framework/PINOperation
       0x102020000 -        0x102047fff PINRemoteImage arm64  <7edeba9784ef31b4ab68639c231888b1> /private/var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Frameworks/PINRemoteImage.framework/PINRemoteImage
       0x1020a0000 -        0x1020b7fff Unbox arm64  <9cfd65318d3932e9bf75727fc475139d> /private/var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Frameworks/Unbox.framework/Unbox
       0x1020ec000 -        0x102113fff Valet arm64  <c430ab434b633cbba3d97abc37b4f0f7> /private/var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Frameworks/Valet.framework/Valet
       0x100f28000 -        0x100f3bfff libobjsee.dylib arm64  <5518a67ca3373688bc90b77185a4e7e3> /private/preboot/C4C12A04D85FF72667E87729BDDDAE3CB222158632EFC65A343DB240B8A82A0871143A7D4611CB0FB398A3E9F5F4D850/jb-XqdYf2hT/procursus/usr/lib/libobjsee.dylib
       0x100f18000 -        0x100f1ffff systemhook.dylib arm64  <b14375b3e14134dcaaaeb9a3a380e862> /cores/binpack/usr/lib/systemhook.dylib
       0x100100000 -        0x100caffff Apollo arm64  <9e4ec7ac92b83a03856cce3664d76b97> /private/var/containers/Bundle/Application/0000-0000-0000-0000-0000/Apollo.app/Apollo
       0x1e1d47000 -        0x1e1d52ff7 libsystem_platform.dylib arm64  <215a128ef97e37edb518a264388b108e> /usr/lib/system/libsystem_platform.dylib
```
