import 'dart:io';

import 'package:ffigen/ffigen.dart';

void main() {
  final packageRoot = Platform.script.resolve('../');
  FfiGenerator(
    output: Output(
      dartFile: packageRoot.resolve('lib/src/libserialport_bindings.g.dart'),
      sort: false,
      style: NativeExternalBindings(
        assetId:
            'package:libserialport_plus/libserialport_plus_bindings.g.dart',
      ),
      commentType: CommentType(CommentStyle.any, CommentLength.full),
    ),
    headers: Headers(
      entryPoints: [packageRoot.resolve('src/libserialport/libserialport.h')],
      compilerOptions: [if (Platform.isWindows) '-DLIBSERIALPORT_MSBUILD'],
    ),
    functions: Functions(
      include: _includeDecl,
      includeSymbolAddress: (decl) => decl.originalName == 'sp_close',
      rename: _stripSp(false),
    ),
    structs: Structs(include: _includeDecl, rename: _stripSp(true)),
    enums: Enums(
      include: _includeDecl,
      rename: _stripSp(true),
      renameMember: _enumRename,
      style: (decl, suggestedStyle) =>
          {'sp_return', 'sp_event', 'sp_signal'}.contains(decl.originalName)
          ? EnumStyle.intConstants
          : suggestedStyle ?? EnumStyle.dartEnum,
    ),
    macros: Macros(include: _includeDecl, rename: _stripSp(false)),
  ).generate();
}

bool _includeDecl(Declaration decl) =>
    decl.originalName.toLowerCase().startsWith('sp_');

String _enumRename(Declaration decl, String member) {
  if (decl.originalName == 'sp_return') {
    return member.replaceAll(RegExp(r'^SP_'), '');
  }
  if (decl.originalName == 'sp_xonxoff') {
    return switch (member) {
      'SP_XONXOFF_IN' => 'input',
      'SP_XONXOFF_OUT' => 'output',
      'SP_XONXOFF_INOUT' => 'inputOutput',
      'SP_XONXOFF_INVALID' => 'invalid',
      'SP_XONXOFF_DISABLED' => 'disabled',
      _ => throw ArgumentError(member),
    };
  }
  if (decl.originalName == 'sp_flowcontrol') {
    return switch (member) {
      'SP_FLOWCONTROL_NONE' => 'none',
      'SP_FLOWCONTROL_XONXOFF' => 'xonXoff',
      'SP_FLOWCONTROL_RTSCTS' => 'rtsCts',
      'SP_FLOWCONTROL_DTRDSR' => 'dtrDsr',
      _ => throw ArgumentError(member),
    };
  }
  return _toSnakeCase(member.replaceAll(RegExp(r'^SP_[A-Z]+_'), ''));
}

String Function(Declaration) _stripSp(bool capitalize) => (Declaration decl) {
  String name = decl.originalName.replaceAll(
    RegExp(r'^sp_', caseSensitive: false),
    '',
  );
  name = _toSnakeCase(name);
  return capitalize ? name[0].toUpperCase() + name.substring(1) : name;
};

String _toSnakeCase(String member) {
  if (member.isEmpty) return member;
  member = member
      .split('_')
      .where((e) => e.isNotEmpty)
      .map((e) => e[0].toUpperCase() + e.substring(1).toLowerCase())
      .join();
  return member[0].toLowerCase() + member.substring(1);
}
