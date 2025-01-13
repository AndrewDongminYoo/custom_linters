// ignore_for_file: directives_ordering, depend_on_referenced_packages

// 📦 Package imports:
import 'package:_fe_analyzer_shared/src/scanner/token.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:test/test.dart';

// 🌎 Project imports:
import 'package:flutter_best_practices_lints/src/extensions/class_declaration_extension.dart';

ClassDeclarationImpl generateClassDeclarationImpl({
  required StringToken name,
  required Token classKeyword,
  required Token leftBracket,
  required Token rightBracket,
  List<ClassMemberImpl> members = const <ClassMemberImpl>[],
  Token? augmentKeyword,
  Token? abstractKeyword,
  Token? macroKeyword,
  Token? sealedKeyword,
  Token? baseKeyword,
  Token? interfaceKeyword,
  Token? finalKeyword,
  Token? mixinKeyword,
  TypeParameterListImpl? typeParameters,
  ExtendsClauseImpl? extendsClause,
  WithClauseImpl? withClause,
  ImplementsClauseImpl? implementsClause,
  NativeClauseImpl? nativeClause,
}) {
  return ClassDeclarationImpl(
    comment: null,
    metadata: null,
    name: name,
    augmentKeyword: augmentKeyword,
    abstractKeyword: abstractKeyword,
    macroKeyword: macroKeyword,
    sealedKeyword: sealedKeyword,
    baseKeyword: baseKeyword,
    interfaceKeyword: interfaceKeyword,
    finalKeyword: finalKeyword,
    mixinKeyword: mixinKeyword,
    classKeyword: classKeyword,
    typeParameters: typeParameters,
    extendsClause: extendsClause,
    withClause: withClause,
    implementsClause: implementsClause,
    nativeClause: nativeClause,
    leftBracket: leftBracket,
    members: members,
    rightBracket: rightBracket,
  );
}

void main() {
  group('ClassDeclarationExtension', () {
    group('isStateClass', () {
      test(
        'returns true for private State class',
        () {
          final mockStateClass = generateClassDeclarationImpl(
            name: StringToken(TokenType.STRING, '_AwesomeWidgetState', 0),
            extendsClause: parseString(content: 'extends') as ExtendsClauseImpl,
            leftBracket: Token(TokenType.OPEN_CURLY_BRACKET, 0),
            rightBracket: Token(TokenType.CLOSE_CURLY_BRACKET, 0),
            classKeyword: Token(Keyword.CLASS, 0),
            members: [],
          );
          expect(mockStateClass.isStateClass, isTrue);
        },
        skip: "I don't know how to create an ExtendsClause for testing.",
      );

      test('returns false for non-State class', () {
        final mockNonStateClass = generateClassDeclarationImpl(
          name: StringToken(TokenType.STRING, 'AuthenticationState', 0),
          leftBracket: Token(TokenType.OPEN_CURLY_BRACKET, 0),
          rightBracket: Token(TokenType.CLOSE_CURLY_BRACKET, 0),
          classKeyword: Token(Keyword.CLASS, 0),
          members: [],
        );
        expect(mockNonStateClass.isStateClass, isFalse);
      });

      test('returns false for class with State in middle', () {
        final middleStateClass = generateClassDeclarationImpl(
          name: StringToken(TokenType.STRING, 'MidleStateClass', 0),
          leftBracket: Token(TokenType.OPEN_CURLY_BRACKET, 0),
          rightBracket: Token(TokenType.CLOSE_CURLY_BRACKET, 0),
          classKeyword: Token(Keyword.CLASS, 0),
          members: [],
        );
        expect(middleStateClass.isStateClass, isFalse);
      });

      test('returns false for public State class', () {
        final publicStateClass = generateClassDeclarationImpl(
          name: StringToken(TokenType.STRING, 'PublicStateClass', 0),
          leftBracket: Token(TokenType.OPEN_CURLY_BRACKET, 0),
          rightBracket: Token(TokenType.CLOSE_CURLY_BRACKET, 0),
          classKeyword: Token(Keyword.CLASS, 0),
          members: [],
        );
        expect(publicStateClass.isStateClass, isFalse);
      });
    });

    group('isAbstract', () {
      test('returns true for abstract class', () {
        final mockAbstractClass = generateClassDeclarationImpl(
          name: StringToken(TokenType.STRING, 'MockAbstractClass', 0),
          abstractKeyword: Token(Keyword.ABSTRACT, 82),
          leftBracket: Token(TokenType.OPEN_CURLY_BRACKET, 0),
          rightBracket: Token(TokenType.CLOSE_CURLY_BRACKET, 0),
          classKeyword: Token(Keyword.CLASS, 0),
          members: [],
        );
        expect(mockAbstractClass.isAbstract, isTrue);
      });

      test('returns false for non-abstract class', () {
        final mockRegularClass = generateClassDeclarationImpl(
          name: StringToken(TokenType.STRING, 'MockRegularClass', 0),
          leftBracket: Token(TokenType.OPEN_CURLY_BRACKET, 0),
          rightBracket: Token(TokenType.CLOSE_CURLY_BRACKET, 0),
          classKeyword: Token(Keyword.CLASS, 0),
          members: [],
        );
        expect(mockRegularClass.isAbstract, isFalse);
      });

      test('returns false for private State class without abstract keyword',
          () {
        final mockStateClass = generateClassDeclarationImpl(
          name: StringToken(TokenType.STRING, '_AwesomeWidgetState', 0),
          leftBracket: Token(TokenType.OPEN_CURLY_BRACKET, 0),
          rightBracket: Token(TokenType.CLOSE_CURLY_BRACKET, 0),
          classKeyword: Token(Keyword.CLASS, 0),
          members: [],
        );
        expect(mockStateClass.isAbstract, isFalse);
      });
    });
  });
}
