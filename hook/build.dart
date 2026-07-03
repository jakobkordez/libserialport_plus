import 'package:code_assets/code_assets.dart';
import 'package:hooks/hooks.dart';
import 'package:native_toolchain_c/native_toolchain_c.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    if (!input.config.buildCodeAssets) return;

    final packageName = input.packageName;
    final targetOS = input.config.code.targetOS;
    if (targetOS != OS.windows &&
        targetOS != OS.linux &&
        targetOS != OS.android &&
        targetOS != OS.macOS) {
      throw BuildError(message: 'Unsupported target OS: $targetOS');
    }
    final isWindows = targetOS == OS.windows;
    final isPosix = !isWindows;

    final cbuilder = CBuilder.library(
      name: packageName,
      assetName: '${packageName}_bindings.g.dart',
      includes: ['src/include'],
      frameworks: [
        if (targetOS == OS.macOS) ...['IOKit', 'CoreFoundation'],
      ],
      defines: {
        if (isWindows) ...{
          'LIBSERIALPORT_MSBUILD': null,
          'DART_SHARED_LIB': null,
        } else ...{
          'LIBSERIALPORT_ATBUILD': null,
        },
      },
      flags: [
        if (isPosix) ...[
          '-std=c99',
          '-Wall',
          '-Wextra',
          '-pedantic',
          '-Wmissing-prototypes',
          '-Wshadow',
        ],
      ],
      sources: [
        ...[
          'serialport.c',
          'timing.c',
          if (targetOS == OS.windows) 'windows.c',
          if (targetOS == OS.linux || targetOS == OS.android) ...[
            'linux.c',
            'linux_termios.c',
          ],
          if (targetOS == OS.macOS) 'macosx.c',
        ].map((e) => 'src/libserialport/$e'),
      ],
      libraries: [
        if (targetOS == OS.windows) ...['cfgmgr32', 'SetupAPI', 'Advapi32'],
      ],
      language: targetOS == OS.macOS ? Language.objectiveC : Language.c,
    );
    await cbuilder.run(input: input, output: output, logger: null);
  });
}
