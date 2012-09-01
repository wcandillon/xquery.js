/*
Rule names
==========

All parser grammar rules are prefixed with 'px_' in order to comply with the
ANTLR naming scheme for grammar rules. The 'x' letter in the prefix is an
optional field to indicate the status of the grammar rule compared to the
original EBNF production. If missing, the rule is the same as in EBNF. Other
leters are:
m - The grammar rule is a modified version of the original EBNF production
g - The grammar rule is a helper rule needed to achieve different behaviour

The lexer rules were prefixed with 'L_'.

*/

parser grammar XQueryParser;

options {
superClass='XQDTParser';
output=AST;
TokenLabelType=CommonToken;
tokenVocab=XQueryLexer;
language=JavaScript;
}

tokens {
// define the tokens from side-lexers (String and XML)
// in order to avoid token ID overlapping
L_QuotStringLiteralChar;
L_AposStringLiteralChar;
L_AnyChar;
L_CDataSection;

// Imaginary AST tree nodes
LibraryModule;
MainModule;
VersionDecl;
VersionDeclEncoding;          // container
VersionDeclVersion;           // container
ModuleDecl;
Prolog;
DefaultNamespaceDecls;        // container
DefaultNamespaceDecl;
Setters;                      // container
Setter;
NamespaceDecls;               // container
NamespaceDecl;
Imports;                      // container
FTOptionDecls;                // container
SchemaImport;
SchemaPrefix;
NamespaceName;                // container
DefaultElementNamespace;
AtHints;                      // container
ModuleImport;
BaseURIDecl;
OrderedDecls;                 // container
VarDecl;
VarType;                      // container
VarValue;
VarDefaultValue;
VarVariableDecl;              // container
FunctionDecl;
ParamList;                    // container
ReturnType;                   // container
OptionDecl;
TypeDeclaration;
Param;
EnclosedExpr;
QueryBody;

UnaryExpr;

DirElemConstructor;
DirAttributeList;
DirAttributeValue;
DirElemContent;
CommonContent;

SequenceType;
EmptySequenceTest;
KindTest;
ItemTest;
FunctionTest;
//TODO: remove after Sausalito September release
AtomicType;
AtomicOrUnionType;

StringLiteral;
ElementContentChar;
AttributeValueChar;
QName;

BlockExpr;

}

@parser::header {
/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is Ajax.org Code Editor (ACE).
 *
 * The Initial Developer of the Original Code is
 * Ajax.org B.V.
 * Portions created by the Initial Developer are Copyright (C) 2010
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *      William Candillon <wcandillon AT gmail DOT com>
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL. *
 * ***** END LICENSE BLOCK ***** */
var org =  require("./antlr3-all").org;
var StringLexer   = require("./StringLexer").StringLexer;
var XMLLexer   = require("./XMLLexer").XMLLexer;
var XQueryLexer   = require("./XQueryLexer").XQueryLexer;
var XQDTParser = require("./XQDTParser").XQDTParser;
var Position = require("./Position").Position;
var Exception = function(){};

var XQS = true;
var XQU = true;
var ZORBA = true;

}

@parser::members {

this.isInAttr = false;

this.errors = [];

this.hasErrors = function(){
  return this.errors.length > 0;
};

this.addError = function(error){
  this.errors.push(error);
};

this.getErrors = function(){
  return this.errors;
};

this.source = null;
this.setSource = function(s){
  this.source = s;
  this.highlighter.setSource(s);
};

this.lexerStack = new Array();

this.lc = function(b){ return b; };
this.popLexer = function (){
  //console.log("popLexer");
  if(this.lexerStack.length == 0) return;
  this.getTokenStream().mark();
  var oldLexer = this.getTokenStream().getTokenSource();
  var newLexer = this.lexerStack.pop();
  if(oldLexer instanceof StringLexer && newLexer instanceof XQueryLexer) {
    newLexer.inStr = false;
  }
  this.getTokenStream().setTokenSource(newLexer);
};

this.pushXQueryLexer = function() {
  xqueryLexer = new XQueryLexer(this.source);
  this.pushLexer(xqueryLexer);
};

this.pushStringLexer = function(isAposStr){
  //console.log("pushStringLexer");
  var stringLexer = new StringLexer(this.source);
  stringLexer.inAposStr = isAposStr;
  stringLexer.inQuotStr = !isAposStr;
  stringLexer.setIsWsExplicit(true);
  this.pushLexer(stringLexer);
};

this.pushXMLLexer = function(){
  //console.log("pushXMLLexer");
  var xmlLexer = new XMLLexer(this.source);
  xmlLexer.setIsWsExplicit(true);
  this.pushLexer(xmlLexer);
};

this.pushLexer = function(lexer){
  var oldLexer = this.getTokenStream().getTokenSource();
  oldLexer.addToStack(this.lexerStack);
  this.getTokenStream().setTokenSource(lexer);
};

this.setWsExplicit = function(isExplicit){
  this.getTokenStream().setWsExplicit(isExplicit);
};

this.ap = function(token)
{
  this.addToken(token, "xml_pe");
};

this.ax = function(start, stop)
{
  this.highlighter.addToken(start.getStartIndex(), stop.getStopIndex(), "xml_pe");
};

this.at = function(start, stop)
{
  this.highlighter.addToken(start.getStartIndex(), stop.getStopIndex(), "meta.tag");
};

this.av = function(start, stop)
{
  this.highlighter.addToken(start.getStartIndex(), stop.getStopIndex(), "variable");
};

this.af = function(start, stop)
{
  this.highlighter.addToken(start.getStartIndex(), stop.getStopIndex(), "support.function");
};

this.ao = function(t)
{
  this.addToken(t, "keyword.operator");
};

this.ak = function(t)
{
  this.addToken(t, "keyword");
};

this.ad = function(t)
{
  this.addToken(t, "constant");
};

this.addString = function(start, stop)
{
 if(stop == undefined) {
   this.addToken(start, "string");
 } else {
   this.highlighter.addToken(start.getStartIndex(), stop.getStopIndex(), "string");
 }
};

this.ac = function(t)
{
  this.addToken(t, "comment");
};

this.addToken = function(k, type){
  if(org.antlr.lang.isArray(k)){
    for(i in k)
    {
      this.highlighter.addToken(k[i].getStartIndex(), k[i].getStopIndex(), type);
    }
  } else if(k != null ) {
    this.highlighter.addToken(k.getStartIndex(), k.getStopIndex(), type); 
  }
};

}

// ******************************
// XQuery 3.0 Productions
// http://www.w3.org/TR/xquery-30
// ******************************

//[1]
p_Module
        : vd=p_VersionDecl?
            (
              lm=p_LibraryModule[$vd.tree] -> {$lm.tree}
            | mm=p_MainModule[$vd.tree]    -> {$mm.tree}
            ) EOF
        ;

//[2]
p_VersionDecl
        : k=XQUERY {this.ak($k);} ((k=ENCODING {this.ak($k);} enc=p_StringLiteral) | 
        			 (k=VERSION {this.ak($k);} ver=p_StringLiteral (k=ENCODING {this.ak($k);} enc=p_StringLiteral)?)) SEMICOLON
                -> ^(VersionDecl ^(VersionDeclVersion $ver?) ^(VersionDeclEncoding $enc?))
        ;

//[3]
p_MainModule [vd]
        : pm_Prolog pm_QueryBody
                -> ^(MainModule {$vd} pm_Prolog ) //^(QueryBody pm_QueryBody))
        ;

//[4]
p_LibraryModule [vd]
        : p_ModuleDecl pm_Prolog
                -> ^(LibraryModule {$vd} p_ModuleDecl pm_Prolog)
        ;

//[5]
p_ModuleDecl
        : k+=MODULE k+=NAMESPACE {this.ak($k);} p_NCName EQUAL p_StringLiteral SEMICOLON
                ->  ^(ModuleDecl p_NCName p_StringLiteral)
        ;

//[6]
// The SEMICOLON was pushed back in all the Prolog declarations
// in order to be contained by the declaration trees.
pm_Prolog
        : ((dnd+=pm_DefaultNamespaceDecl | s+=p_Setter | nd+=pm_NamespaceDecl | i+=p_Import | fto+=pm_FTOptionDecl))* od+=pg_OrderedDecl*
                ->  ^(Prolog
                                ^(DefaultNamespaceDecls $dnd*)
                                ^(Setters $s*)
                                ^(NamespaceDecls $nd*)
                                ^(Imports $i*)
                                ^(FTOptionDecls $fto*)
                                ^(OrderedDecls $od*)
                     )
        ;

// *************************************************
// This is not in the EBNF grammar.
// A special node is needed to keep track of the prolog
// declarations for which the order is important.
pg_OrderedDecl
        : pm_ContextItemDecl
        | pm_AnnotatedDecl
        | pm_OptionDecl
        ;
// *************************************************

//[7] covered by the SEMICOLON lexer rule
//Separator ::= ";"

//[8]
p_Setter
        : pm_BoundarySpaceDecl
        | pm_DefaultCollationDecl
        | pm_BaseURIDecl
        | pm_ConstructionDecl
        | pm_OrderingModeDecl
        | pm_EmptyOrderDecl
        | {this.lc(XQU)}?=> pm_RevalidationDecl
        | pm_CopyNamespacesDecl
        | pm_DecimalFormatDecl
        ;

//[9]
pm_BoundarySpaceDecl    
        : k=DECLARE {this.ak($k);} k=BOUNDARY_SPACE {this.ak($k);} ( (k=PRESERVE {this.ak($k);}) | (k=STRIP {this.ak($k);}) ) SEMICOLON
        ;

//[10]
pm_DefaultCollationDecl
        : k=DECLARE {this.ak($k);} k=DEFAULT {this.ak($k);} k=COLLATION {this.ak($k);} p_StringLiteral SEMICOLON
        ;
        
//[11]
pm_BaseURIDecl
        : k=DECLARE {this.ak($k);} k=BASE_URI {this.ak($k);} sl=p_StringLiteral SEMICOLON
                -> ^(BaseURIDecl $sl)
        ;

//[12]
pm_ConstructionDecl
        : k=DECLARE {this.ak($k);} k=CONSTRUCTION {this.ak($k);} ( (k=STRIP | k=PRESERVE) {this.ak($k);} ) SEMICOLON
        ;

//[13]
pm_OrderingModeDecl
        : k=DECLARE {this.ak($k);} k=ORDERING {this.ak($k);} ( (k=ORDERED | k=UNORDERED) {this.ak($k);} ) SEMICOLON
        ;

//[14]
pm_EmptyOrderDecl
        : k=DECLARE {this.ak($k);} k=DEFAULT {this.ak($k);} k=ORDER {this.ak($k);} k=EMPTY {this.ak($k);} ( (k=GREATEST | k=LEAST) {this.ak($k);} ) SEMICOLON
        ;

//[15]
pm_CopyNamespacesDecl
        : k=DECLARE {this.ak($k);} k=COPY_NAMESPACES {this.ak($k);} p_PreserveMode COMMA p_InheritMode SEMICOLON
        ;

//[16]
p_PreserveMode
        : (k+=PRESERVE | k+=NO_PRESERVE) {this.ak($k);}
        ;

//[17]
p_InheritMode
        : (k+=INHERIT | k+=NO_INHERIT) {this.ak($k);}
        ;
        
//[18]
pm_DecimalFormatDecl
        : k=DECLARE {this.ak($k);} ((k=DECIMAL_FORMAT {this.ak($k);} p_EQName) | (k=DEFAULT {this.ak($k);} k=DECIMAL_FORMAT {this.ak($k);})) (p_DFPropertyName EQUAL p_StringLiteral)* SEMICOLON
        ;

//[19]
p_DFPropertyName
        : (k=DECIMAL_SEPARATOR | k=GROUPING_SEPARATOR | k=INFINITY | k=MINUS_SIGN | k=NAN | k=PERCENT | k=PER_MILLE | k=ZERO_DIGIT | k=DIGIT | k=PATTERN_SEPARATOR) {this.ak($k);}
        ;

//[20]
p_Import
        : pm_SchemaImport | pm_ModuleImport
        ;
        
//[21]
pm_SchemaImport
        : k=IMPORT {this.ak($k);} k=SCHEMA {this.ak($k);} sp=p_SchemaPrefix? us=p_StringLiteral (k=AT {this.ak($k);} ah+=p_StringLiteral (COMMA ah+=p_StringLiteral)*)? SEMICOLON
                -> ^(SchemaImport ^(SchemaPrefix $sp?) $us ^(AtHints $ah*))
        ;

//[22]
p_SchemaPrefix 
        : k=NAMESPACE {this.ak($k);} nn=p_NCName EQUAL
                -> ^(NamespaceName $nn)
        | k=DEFAULT {this.ak($k);} k=ELEMENT {this.ak($k);} k=NAMESPACE {this.ak($k);}
                -> DefaultElementNamespace
        ;

//[23]
pm_ModuleImport
        : k=IMPORT {this.ak($k);} k=MODULE {this.ak($k);} (k=NAMESPACE {this.ak($k);} nn=p_NCName EQUAL)? us=p_StringLiteral (k=AT {this.ak($k);} ah+=p_StringLiteral (COMMA ah+=p_StringLiteral)*)? SEMICOLON
                -> ^(ModuleImport ^(NamespaceName $nn?) $us ^(AtHints $ah*))
        ;

//[24]
pm_NamespaceDecl
        : k=DECLARE {this.ak($k);} k=NAMESPACE {this.ak($k);} nn=p_NCName EQUAL us=p_StringLiteral SEMICOLON 
                -> ^(NamespaceDecl $nn $us)
        ;

//[25]
pm_DefaultNamespaceDecl
        : k=DECLARE {this.ak($k);} k=DEFAULT {this.ak($k);} (k=ELEMENT | k=FUNCTION) {this.ak($k);} k=NAMESPACE {this.ak($k);} p_StringLiteral SEMICOLON
        ;

//[26]
pm_AnnotatedDecl
        : k=DECLARE {this.ak($k);} p_Annotation* pg_AnnotatedDecl SEMICOLON
        ;
pg_AnnotatedDecl
        : p_VarDecl
        | pm_FunctionDecl
        | {this.lc(ZORBA)}?=> p_CollectionDecl
        | {this.lc(ZORBA)}?=> p_IndexDecl
        | {this.lc(ZORBA)}?=> p_ICDecl
        ;

//[27]
p_Annotation
        : ANN_PERCENT p_EQName (LPAREN p_Literal (COMMA p_Literal)* RPAREN)?
        ;

//[28]
p_VarDecl
        : k=VARIABLE {this.ak($k);} d=DOLLAR qn=p_EQName { this.av($d, $qn.stop); } td=p_TypeDeclaration? ((BIND vv=p_VarValue) | (k=EXTERNAL {this.ak($k);} (BIND vdv=p_VarDefaultValue)?))
                -> ^(VarDecl $qn ^(VarType $td?) ^(VarValue $vv? ^(VarDefaultValue $vdv?)))
        ;

//[29]
p_VarValue
        : p_ExprSingle[true]
        ;

//[30]
p_VarDefaultValue
        : p_ExprSingle[true]
        ;

//[31]
pm_ContextItemDecl
        : k=DECLARE {this.ak($k);} k=CONTEXT {this.ak($k);} k=ITEM {this.ak($k);} (k=AS {this.ak($k);} p_ItemType)? ((BIND p_VarValue) | (k=EXTERNAL {this.ak($k);} (BIND p_VarDefaultValue)?)) SEMICOLON
        ;

//[32]
//[32] new XQuery Scripting proposal
pm_FunctionDecl
        : ({this.lc(XQU)}?=> k=UPDATING {this.ak($k);})? k=FUNCTION {this.ak($k);} qn=pg_FQName LPAREN pl=p_ParamList? RPAREN (k=AS {this.ak($k);} st=p_SequenceType)? (LBRACKET soe=p_StatementsAndOptionalExpr RBRACKET | k=EXTERNAL {this.ak($k);} )
                -> ^(FunctionDecl $qn ^(ParamList $pl?) ^(ReturnType $st?) $soe?)
        ;

//[33]
p_ParamList
        : p+=p_Param (COMMA p+=p_Param)*
                -> $p+
        ;
        
//[34]
p_Param
        : d=DOLLAR qn=p_EQName { this.av($d, $qn.stop); } td=p_TypeDeclaration?
                -> ^(Param $qn $td?)
        ;

//[35]
pm_FunctionBody
        : p_EnclosedExpr
        ;


//[36]
p_EnclosedExpr
        : LBRACKET p_Expr[true,true] RBRACKET
                -> ^(EnclosedExpr p_Expr)
        ;

//[37]
pm_OptionDecl
        : k=DECLARE {this.ak($k);} k=OPTION {this.ak($k);} p_EQName p_StringLiteral SEMICOLON
        ;

//[38]
pm_QueryBody
        : {this.lc(XQS)}?=> p_Program
        | p_Expr[true,true]
        ;

////[39]
//p_Expr[boolean strict, boolean allowConcat]
//        : es=p_ExprSingle[$strict]
//          (COMMA p_ExprSingle[$strict])*
//        ;

//[39]
p_Expr[strict, allowConcat]
        : es=p_ExprSingle[$strict] { if (!$allowConcat) throw new Exception(); }
          (COMMA p_ExprSingle[$strict])*
        ;
catch [e] {
  if(e instanceof org.antlr.runtime.RecognitionException) {
    //console.log("catch1");
    reportError(e);
    recover(this.input, e);
    retval.tree = this.adaptor.errorNode(this.input, retval.start, this.input.LT(-1), e);
  } else if(e instanceof Exception) {
    //console.log("catch2");
    root_0 = this.adaptor.nil();
    this.adaptor.addChild(root_0, es.getTree());
    retval.stop = this.input.LT(-1);
    retval.tree = this.adaptor.rulePostProcessing(root_0);
    this.adaptor.setTokenBoundaries(retval.tree, retval.start, retval.stop);
  } else {
    throw e;
  }
}

//[40]
//[22] new XQuery Scripting proposal
p_ExprSingle[strict]
        : (((FOR | LET) DOLLAR) | (FOR (TUMBLING | SLIDING))) => p_FLWORHybrid[$strict]
        | (IF LPAREN) =>          p_IfHybrid[$strict]
        | (SWITCH LPAREN) =>      p_SwitchHybrid[$strict]
        | (TYPESWITCH LPAREN) =>  p_TypeswitchHybrid[$strict]
        | (TRY LBRACKET) =>       p_TryCatchHybrid[$strict]
        | p_ExprSimple
        ;

//[41]
p_FLWORHybrid[strict]
        : p_InitialClause p_IntermediateClause* p_ReturnHybrid[$strict]
        ;

//[42]
p_InitialClause
        : p_ForClause | p_LetClause | p_WindowClause
        ;

//[43]
p_IntermediateClause
        : p_InitialClause | p_WhereClause | p_GroupByClause | p_OrderByClause | p_CountClause
        ;

//[44]
p_StringConcatExpr
   : p_RangeExpr ( o=CONCAT { this.ao($o); } p_RangeExpr )*
   ;


//[35] Full Text 1.0
p_ForClause
        : k=FOR {this.ak($k);} p_ForBinding (COMMA p_ForBinding)*
        ;

//[45]
p_ForBinding
        : s=DOLLAR v=p_VarName { this.av($s, $v.stop); } p_TypeDeclaration? p_AllowingEmpty? p_PositionalVar? p_FTScoreVar? k=IN {this.ak($k);} p_ExprSingle[true]
        ;

//[46]
p_AllowingEmpty
        : k=ALLOWING {this.ak($k);} k=EMPTY {this.ak($k);}
        ;

//[47]
p_PositionalVar
        : k=AT {this.ak($k);} d=DOLLAR v=p_VarName { this.av($d, $v.stop); }
        ;

//[48]
p_LetClause
        : k=LET {this.ak($k);} p_LetBinding (COMMA p_LetBinding)*
        ;

//[49]
//[38] Full Text 1.0
p_LetBinding
        : ( (d=DOLLAR v=p_VarName {this.av($d, $v.stop);} p_TypeDeclaration?) | p_FTScoreVar ) BIND p_ExprSingle[true]
        ;

//[50]
p_WindowClause
        : k=FOR {this.ak($k);} (p_TumblingWindowClause | p_SlidingWindowClause)
        ;
        
//[51]
p_TumblingWindowClause
        : k=TUMBLING {this.ak($k);} k=WINDOW {this.ak($k);} d=DOLLAR v=p_VarName {this.av($d, $v.stop);} p_TypeDeclaration? k=IN {this.ak($k);} p_ExprSingle[true] p_WindowStartCondition p_WindowEndCondition?
        ;

//[52]
p_SlidingWindowClause
        : k=SLIDING {this.ak($k);} k=WINDOW {this.ak($k);} d=DOLLAR v=p_VarName { this.av($d, $v.stop); } p_TypeDeclaration? k=IN {this.ak($k);} p_ExprSingle[true] p_WindowStartCondition p_WindowEndCondition?
        ;

//[53]
p_WindowStartCondition
        : k=START {this.ak($k);} p_WindowVars k=WHEN {this.ak($k);} p_ExprSingle[true]
        ;

//[54]
p_WindowEndCondition
        : (k=ONLY {this.ak($k);})? k=END {this.ak($k);} p_WindowVars k=WHEN {this.ak($k);} p_ExprSingle[true]
        ;

//[55]
p_WindowVars
        : (d=DOLLAR v=p_CurrentItem { this.av($d, $v.stop); })? p_PositionalVar? (k=PREVIOUS {this.ak($k);} DOLLAR p_PreviousItem)? (k=NEXT {this.ak($k);} DOLLAR p_NextItem)?
        ;

//[56]
p_CurrentItem
        : p_EQName
        ;

//[57]
p_PreviousItem
        : p_EQName
        ;

//[58]
p_NextItem
        : p_EQName
        ;

//[59]
p_CountClause
        : k=COUNT {this.ak($k);} d=DOLLAR v=p_VarName { this.av($d, $v.stop); }
        ;
        
//[60]
p_WhereClause
        : k=WHERE {this.ak($k);} p_ExprSingle[true]
        ;

//[61]
p_GroupByClause
        : k=GROUP {this.ak($k);} k=BY {this.ak($k);} p_GroupingSpecList
        ;

//[62]
p_GroupingSpecList
        : p_GroupingSpec (COMMA p_GroupingSpec)*
        ;

//[63]
p_GroupingSpec
        : p_GroupingVariable (p_TypeDeclaration? BIND p_ExprSingle[true])? (k=COLLATION {this.ak($k);} p_StringLiteral)?
        ;

p_GroupingVariable
        : d=DOLLAR v=p_VarName { this.av($d, $v.stop); }
        ;

//[64]
p_OrderByClause
        : ((k+=ORDER k+=BY) | (k+=STABLE k+=ORDER k+=BY)) {this.ak($k);} p_OrderSpecList
        ;

//[65]
p_OrderSpecList
        : p_OrderSpec (COMMA p_OrderSpec)*
        ;

//[66]
p_OrderSpec
        : p_ExprSingle[true] p_OrderModifier
        ;

//[67]
p_OrderModifier
        : (k+=ASCENDING | k+=DESCENDING)? (k+=EMPTY (k+=GREATEST | k+=LEAST))? (k+=COLLATION p_StringLiteral)? {this.ak($k);}
        ;

//[68]
p_ReturnHybrid[strict]
        : k=RETURN {this.ak($k);} p_Hybrid[$strict,false]
        ;

//[69]
p_QuantifiedExpr
        : (k=SOME | k=EVERY) {this.ak($k);} d=DOLLAR v=p_VarName { this.av($d, $v.stop); } p_TypeDeclaration? k=IN {this.ak($k);} p_ExprSingle[true] (COMMA e=DOLLAR w=p_EQName {this.av($e, $w.stop);} p_TypeDeclaration? k=IN {this.ak($k);} p_ExprSingle[true])* k=SATISFIES {this.ak($k);} p_ExprSingle[true]
        ;

//[70]
p_SwitchHybrid[strict]
        : k=SWITCH {this.ak($k);} LPAREN p_Expr[true,true] RPAREN p_SwitchCaseHybrid[$strict]+ k=DEFAULT {this.ak($k);} k=RETURN {this.ak($k);} p_Hybrid[$strict,false]
        ;

//[71]
p_SwitchCaseHybrid[strict]
        : (k=CASE {this.ak($k);} p_SwitchCaseOperand)+ k=RETURN {this.ak($k);} p_Hybrid[$strict,false]
        ;

//[72]
p_SwitchCaseOperand
        : p_ExprSingle[true]
        ;

//[73]
p_TypeswitchHybrid[strict]
        : k=TYPESWITCH {this.ak($k);} LPAREN p_Expr[true,true] RPAREN p_CaseHybrid[$strict]+ k=DEFAULT {this.ak($k);} (d=DOLLAR v=p_VarName { this.av($d, $v.stop); })? k=RETURN {this.ak($k);} p_Hybrid[$strict,false]
        ;

//[74]
p_CaseHybrid[strict]
        : k=CASE {this.ak($k);} (d=DOLLAR v=p_VarName { this.av($d, $v.stop); } k=AS {this.ak($k);})? p_SequenceTypeUnion k=RETURN {this.ak($k);} p_ExprSingle[false]
        ;

//[75]
p_SequenceTypeUnion
        : p_SequenceType (VBAR p_SequenceType)*
        ;

//[76]
p_IfHybrid[strict]
        : k=IF {this.ak($k);} LPAREN p_Expr[true,true] RPAREN k=THEN {this.ak($k);} p_Hybrid[$strict,false] k=ELSE {this.ak($k);} p_Hybrid[$strict,false]
        ;

//[77]
p_TryCatchExpr
        : p_TryClause p_CatchClause+
        ;

//[78]
p_TryClause
        : k=TRY {this.ak($k);} LBRACKET p_TryTargetExpr RBRACKET
        ;

//[79]
p_TryTargetExpr
        : p_Expr[false,false]
        ;

//[80]
p_CatchClause
        : k=CATCH {this.ak($k);} p_CatchErrorList LBRACKET p_Expr[false,false] RBRACKET
        ;

//[81]
p_CatchErrorList
        : p_NameTest (VBAR p_NameTest)*
        ;

//[82]
p_OrExpr
        : p_AndExpr ( k=OR {this.ak($k);} p_AndExpr )*
        ;

//[83]
p_AndExpr
        : p_ComparisonExpr ( k=AND {this.ak($k);} p_ComparisonExpr )*
        ;

//[84]
//[50] Full Text 1.0
p_ComparisonExpr
        : p_FTContainsExpr ( (p_ValueComp | p_GeneralComp | p_NodeComp) p_FTContainsExpr )?
        ;

//[85]
p_RangeExpr
        : p_AdditiveExpr ( k=TO {this.ak($k);} p_AdditiveExpr )?
        ;

//[86]
p_AdditiveExpr
        : p_MultiplicativeExpr ( (o=PLUS {this.ao($o);} | o=MINUS {this.ao($o);}) p_MultiplicativeExpr )*
        ;

//[87]
p_MultiplicativeExpr
        : p_UnionExpr ( (o=STAR {this.ao($o);} | (k=DIV | k=IDIV | k=MOD) {this.ak($k);}) p_UnionExpr )*
        ;

//[88]
p_UnionExpr
        : p_IntersectExceptExpr ( (k=UNION {this.ak($k);} | VBAR) p_IntersectExceptExpr )*
        ;

//[89]
p_IntersectExceptExpr
        : p_InstanceofExpr ( (k=INTERSECT | k=EXCEPT) {this.ak($k);} p_InstanceofExpr )*
        ;

//[90]
p_InstanceofExpr
        : p_TreatExpr ( k=INSTANCE {this.ak($k);} k=OF {this.ak($k);} p_SequenceType)?
        ;

//[91]
p_TreatExpr
        : p_CastableExpr ( k=TREAT {this.ak($k);} k=AS {this.ak($k);} p_SequenceType )?
        ;
        
//[92]
p_CastableExpr
        : p_CastExpr ( k=CASTABLE {this.ak($k);} k=AS {this.ak($k);} p_SingleType )?
        ;
        
//[93]
p_CastExpr
        : p_UnaryExpr ( k=CAST {this.ak($k);} k=AS {this.ak($k);} p_SingleType )?
        ;

//[94]
p_UnaryExpr
        : (o=PLUS {this.ao($o);} | o=MINUS{this.ao($o);})* p_ValueExpr
                -> ^(UnaryExpr PLUS* p_ValueExpr)
        ;

//[95]
p_ValueExpr
        : (VALIDATE ( p_ValidationMode | TYPE )?) => p_ValidateExpr
        | p_SimpleMapExpr
        | p_ExtensionExpr
        ;

p_SimpleMapExpr
        : p_PathExpr (BANG p_PathExpr)*
        ;

//[96]
p_GeneralComp
        : (o=EQUAL | o=NOTEQUAL | o=SMALLER | o=SMALLEREQ | o=GREATER | o=GREATEREQ) { this.ao($o); }
        ;

//[97]
p_ValueComp
        : (k=EQ | k=NE | k=LT | k=LE | k=GT | k=GE) {this.ak($k);}
        ;

//[98]
p_NodeComp
        : k=IS {this.ak($k);} | SMALLER_SMALLER | GREATER_GREATER
        ;

//[99]
p_ValidateExpr
        : k=VALIDATE {this.ak($k);} ( p_ValidationMode | k=TYPE {this.ak($k);} p_TypeName )? LBRACKET p_Expr[true,true] RBRACKET
        ;

//[100]
p_ValidationMode
        : (k=LAX | k=STRICT) {this.ak($k);}
        ;

//[101]
p_ExtensionExpr
        : L_Pragma+ LBRACKET p_Expr[true,true]? RBRACKET
        ;

//[102] /* ws: explicit */
//Pragma ::= "(#" S? EQName (S PragmaContents)? "#)"
//L_Pragma

//[103]
//PragmaContents	   ::=   	(Char* - (Char* '#)' Char*))
//L_Pragma

//[104] /* xgc: leading-lone-slash */
p_PathExpr
        : (SLASH p_RelativePathExpr) => (SLASH p_RelativePathExpr)
        | SLASH
        | SLASH_SLASH p_RelativePathExpr
        | p_RelativePathExpr
        ;

//[105]
p_RelativePathExpr  
        : p_StepExpr ((SLASH | SLASH_SLASH) p_StepExpr)*
        ;

//[106]
p_StepExpr
        : (LBRACKET | LPAREN | SMALLER | QUOT | APOS | DOLLAR) => p_PostfixExpr
        | (
            ((ELEMENT | ATTRIBUTE) p_EQName? LBRACKET) |
            ((NAMESPACE | PROCESSING_INSTRUCTION) p_NCName? LBRACKET) |
            ((DOCUMENT | TEXT | COMMENT) LBRACKET)
          ) => p_PostfixExpr
        | (p_KindTest) => p_AxisStep 
        | (p_EQName LPAREN) => p_PostfixExpr
        | (p_PrimaryExpr) => p_PostfixExpr
        | p_AxisStep
        ;

//[107]
p_AxisStep
        : (p_ReverseStep | p_ForwardStep) p_PredicateList
        ;

//[108]
p_ForwardStep
        : p_ForwardAxis p_NodeTest
        | p_AbbrevForwardStep
        ;

//[109]
p_ForwardAxis
        : CHILD COLON_COLON
        | DESCENDANT COLON_COLON
        | ATTRIBUTE COLON_COLON
        | SELF COLON_COLON
        | DESCENDANT_OR_SELF COLON_COLON
        | FOLLOWING_SIBLING COLON_COLON
        | FOLLOWING COLON_COLON
        ;

//[110]
p_AbbrevForwardStep
        : ATTR_SIGN? p_NodeTest
        ;

//[111]
p_ReverseStep
        : p_ReverseAxis p_NodeTest
        | p_AbbrevReverseStep
        ;

//[112]
p_ReverseAxis
        : PARENT COLON_COLON
        | ANCESTOR COLON_COLON
        | PRECEDING_SIBLING COLON_COLON
        | PRECEDING COLON_COLON
        | ANCESTOR_OR_SELF COLON_COLON
        ;

//[113]
p_AbbrevReverseStep
        : DOT_DOT
        ;

//[114]
p_NodeTest
        : p_KindTest | p_NameTest
        ;

//[115]
p_NameTest
        : p_EQName | p_Wildcard
//        : (p_Wildcard) => p_Wildcard 
//        | (p_NCName COLON) => p_EQName
//        | (p_NCName) => p_EQName
        ;

//[116] /* ws: explicit */
p_Wildcard @init{this.setWsExplicit(true);}
        : STAR (COLON p_NCName)?
        | p_NCName COLON STAR
        | p_BracedURILiteral STAR
        ;
        finally {this.setWsExplicit(false);}

//[117]
p_PostfixExpr
        : p_PrimaryExpr (p_Predicate | p_ArgumentList)*
        ;

//[118]
p_ArgumentList
        : LPAREN (p_Argument (COMMA p_Argument)*)? RPAREN
        ;

//[119]
p_PredicateList
        : p_Predicate*
        ;

//[120]
p_Predicate
        : LSQUARE p_Expr[true,true] RSQUARE
        ;

//[121]
//[30] new XQuery Scripting proposal
p_PrimaryExpr
        : (LPAREN) => p_ParenthesizedExpr
        | p_Literal
        | p_VarRef
        | p_ContextItemExpr
        | p_FunctionCall //5
        | p_OrderedExpr
        | p_UnorderedExpr
        | p_Constructor //8
        | p_BlockExpr
        | p_FunctionItemExpr //10
        | p_ArrayConstructor
        ;

//p_ObjectConstructor
//        : LBRACKET (p_JSONPair (COMMA p_JSONPair)*) RBRACKET
//        ;
//
//p_JSONPair
//        : p_ExprSingle[true] COLON p_ExprSingle[true]
//        ;

p_ArrayConstructor
        :  LSQUARE p_Expr[true, true] RSQUARE
        ;

//[122]
p_Literal
        : p_NumericLiteral | p_StringLiteral
        ;

//[123]
p_NumericLiteral
        : d+=L_IntegerLiteral {this.ad($d);} | d+=L_DecimalLiteral {this.ad($d);} | d+=L_DoubleLiteral {this.ad($d);}
        ;
        
//[124]
p_VarRef
        : d=DOLLAR v=p_VarName { this.av($d, $v.stop); }
        ;

//[125]
p_VarName
        : p_EQName
        ;

//[126]
p_ParenthesizedExpr
        : LPAREN p_Expr[true,true]? RPAREN
        ;

//[127]
p_ContextItemExpr
        : DOT
        ;

//[128]
p_OrderedExpr
        : k=ORDERED {this.ak($k);} LBRACKET p_Expr[true,true] RBRACKET
        ;

//[129]
p_UnorderedExpr
        : k=UNORDERED {this.ak($k);} LBRACKET p_Expr[true,true] RBRACKET
        ;

//[130] /* xgs: reserved-function-names */ - resolved through pg_FQName production
//      /* gn: parens */
p_FunctionCall
        : f=pg_FQName {this.af($f.start, $f.stop);}  p_ArgumentList
        ;

//[131]
p_Argument
        : p_ExprSingle[true] | p_ArgumentPlaceholder
        ;

//[132]
p_ArgumentPlaceholder
        : QUESTION
        ;

//[133]
p_Constructor
        : p_DirectConstructor
        | p_ComputedConstructor
        ;

//[134]
p_DirectConstructor
        : p_DirElemConstructor
        | p_DirCommentConstructor
        | p_DirPIConstructor
        ;

//[135] /* ws: explicit */ - resolved through the XMLLexer
p_DirElemConstructor //@init {setWsExplicit(true);}
        : SMALLER {this.pushXMLLexer();}
          ts=p_QName {this.at($ts.start, $ts.stop);}  p_DirAttributeList 
          (EMPTY_CLOSE_TAG | (GREATER pm_DirElemContent* CLOSE_TAG te=p_QName {this.at($te.start, $te.stop);} S? GREATER))
                -> ^(DirElemConstructor ^(DirAttributeList p_DirAttributeList*) ^(DirElemContent pm_DirElemContent*))
        ;
        finally {this.popLexer(); }

//[136] /* ws: explicit */ - resolved through the XMLLexer
p_DirAttributeList
        : (S (t=p_QName {this.at($t.start, $t.stop);} S? EQUAL S? v=p_DirAttributeValue )?)*
        ;

//[137] /* ws: explicit */ - resolved through the XMLLexer
p_DirAttributeValue
        : (s+=QUOT {this.isInAttr = true; } (s+=ESCAPE_QUOT | s+=APOS | p_QuotAttrValueContent)* s+=QUOT { this.isInAttr = false; }) { this.addToken($s, "string"); }
                -> ^(DirAttributeValue p_QuotAttrValueContent*)
        | (s+=APOS { this.isInAttr = true; } (s+=ESCAPE_APOS | s+=QUOT | p_AposAttrValueContent)* s+=APOS { this.isInAttr = false; }) { this.addToken($s, "string"); }
                -> ^(DirAttributeValue p_AposAttrValueContent*)
        ;

//[138]
p_QuotAttrValueContent
        : s=p_QuotAttrContentChar { this.addString($s.start, $s.stop); } | pm_CommonContent
        ;

//[139]
p_AposAttrValueContent
        : s=p_AposAttrContentChar { this.addString($s.start, $s.stop); } | pm_CommonContent
        ;

//[140]
pm_DirElemContent
        : p_DirectConstructor
        | p_CDataSection
        | pm_CommonContent
        | p_ElementContentChar
        ;


//[141]
//[24] new XQuery Scripting proposal
pm_CommonContent
        : L_PredefinedEntityRef
        | L_CharRef
        | s=ESCAPE_LBRACKET { if(this.isInAttr) { this.addToken(s, "string");  } }
        | s=ESCAPE_RBRACKET { if(this.isInAttr) { this.addToken(s, "string");  } }
        | pg_EnclosedExprXml
        ;

// *************************************************
// This is not in the EBNF grammar.
// This is needed in order to switch the lexer from
// XML back to XQuery
//[24] new XQuery Scripting proposal
pg_EnclosedExprXml
        :   LBRACKET {this.pushXQueryLexer();}
            p_StatementsAndOptionalExpr
            RBRACKET {this.popLexer();}
        ;
// *************************************************

//[142] /* ws: explicit */
p_DirCommentConstructor
        : c=L_DirCommentConstructor {this.ac($c);}
        ;   

//[143] /* ws: explicit */
//L_DirCommentContents

//[144] /* ws: explicit */
p_DirPIConstructor
        : p=L_DirPIConstructor { this.ap($p);  }
        ;    

//[145] /* ws: explicit */
//L_DirPIContents

//[146] /* ws: explicit */
p_CDataSection
        : c=L_CDataSection { this.ac($c); }
        ;

//[147] /* ws: explicit */
//L_CDataSectionContents

//[148]
p_ComputedConstructor   
        : pm_CompDocConstructor
        | pm_CompElemConstructor
        | pm_CompAttrConstructor
        | p_CompNamespaceConstructor
        | p_CompTextConstructor
        | pm_CompCommentConstructor
        | pm_CompPIConstructor
        ;

//[149]
//[26] new XQuery Scripting proposal
pm_CompDocConstructor
        : k=DOCUMENT {this.ak($k);} LBRACKET p_StatementsAndOptionalExpr RBRACKET
        ;
        
//[150]
pm_CompElemConstructor
        : k=ELEMENT {this.ak($k);} (p_EQName | (LBRACKET p_Expr[true,true] RBRACKET)) LBRACKET pm_ContentExpr RBRACKET
        ;

//[151]
//[25] new XQuery Scripting proposal
pm_ContentExpr
        : p_StatementsAndOptionalExpr
        ;

//[152]
//[27] new XQuery Scripting proposal
pm_CompAttrConstructor
        : k=ATTRIBUTE {this.ak($k);} (p_EQName | (LBRACKET p_Expr[true,true] RBRACKET)) LBRACKET p_StatementsAndOptionalExpr RBRACKET
        ;

//[153]
p_CompNamespaceConstructor
        : k=NAMESPACE {this.ak($k);} (p_Prefix | (LBRACKET p_PrefixExpr RBRACKET)) LBRACKET p_URIExpr? RBRACKET
        ;

//[154]
p_Prefix
        : p_NCName
        ;

//[155]
p_PrefixExpr
        : p_Expr[true,true]
        ;

//[156]
p_URIExpr
        : p_Expr[true,true]
        ;

//[157]
p_CompTextConstructor
        : k=TEXT {this.ak($k);} LBRACKET p_Expr[true,true] RBRACKET
        ;

//[158]
//[29] new XQuery Scripting proposal
pm_CompCommentConstructor
        : k=COMMENT {this.ak($k);} LBRACKET p_StatementsAndOptionalExpr RBRACKET
        ;

//[159]
//[28] new XQuery Scripting proposal
pm_CompPIConstructor
        : k=PROCESSING_INSTRUCTION {this.ak($k);} (p_NCName | (LBRACKET p_Expr[true,true] RBRACKET)) LBRACKET p_StatementsAndOptionalExpr RBRACKET
        ;

//[160]
p_FunctionItemExpr
        : p_LiteralFunctionItem
//        | p_InlineFunction
        ;

//[161] /* xgc: reserved-function-names */
p_LiteralFunctionItem
        : p_EQName HASH L_IntegerLiteral
        ;

//[162]
p_InlineFunction
        //: p_Annotation* FUNCTION LPAREN p_ParamList? RPAREN (k=AS {this.ak($k);} p_SequenceType)? pm_FunctionBody
        : p_Annotation* k=FUNCTION { this.ak($k); } LPAREN p_ParamList? RPAREN (k=AS {this.ak($k);} p_SequenceType)? LBRACKET p_StatementsAndOptionalExpr RBRACKET
        ;

//[163]
p_SingleType
        : p_AtomicOrUnionType QUESTION?
        ;

//[164]
p_TypeDeclaration
        : k=AS {this.ak($k);} st=p_SequenceType
                -> ^(TypeDeclaration $st)
        ;

//[165]
p_SequenceType
        : k=EMPTY_SEQUENCE {this.ak($k);} l=LPAREN r=RPAREN
                -> ^(SequenceType ^(EmptySequenceTest $k $l $r))
        | it=p_ItemType ((p_OccurrenceIndicator) => oi=p_OccurrenceIndicator)?
                -> ^(SequenceType $it $oi?)
        ;

//[166] /* xgs: occurrence-indicators */ - resolved in the p_SequenceType production
p_OccurrenceIndicator   
        : QUESTION | STAR | PLUS
        ;
        
//[167]
p_ItemType
        : p_KindTest
                -> ^(KindTest p_KindTest)
        | (ITEM LPAREN RPAREN)
                -> ^(ItemTest ITEM LPAREN RPAREN)
        | p_FunctionTest
                -> ^(FunctionTest p_FunctionTest)
        | p_AtomicOrUnionType
        | p_ParenthesizedItemType
        //| p_JSONTest
        //| p_StructuredItemTest
        ;

p_JSONTest
        : p_JSONItemTest
        | p_JSONObjectTest
        | p_JSONArrayTest
        ;

p_StructuredItemTest
        : STRUCTURED_ITEM LPAREN RPAREN
        ;

p_JSONItemTest
        : JSON_ITEM LPAREN RPAREN
        ;

p_JSONObjectTest
        : OBJECT LPAREN RPAREN
        ;

p_JSONArrayTest
        : ARRAY LPAREN RPAREN
        ;

//[168]
p_AtomicOrUnionType
        : p_EQName
                -> ^(AtomicOrUnionType p_EQName)
        ;

//[169]
p_KindTest
        : p_DocumentTest
        | p_ElementTest
        | p_AttributeTest
        | p_SchemaElementTest
        | p_SchemaAttributeTest
        | p_PITest
        | p_CommentTest
        | p_TextTest
        | p_NamespaceNodeTest
        | p_AnyKindTest
        ;

//[170]
p_AnyKindTest
        : NODE LPAREN RPAREN
        ;

//[171]
p_DocumentTest
        : DOCUMENT_NODE LPAREN (p_ElementTest | p_SchemaElementTest)? RPAREN
        ;

//[172]
p_TextTest
        : TEXT LPAREN RPAREN
        ;

//[173]
p_CommentTest
        : COMMENT LPAREN RPAREN
        ;

//[174]
p_NamespaceNodeTest
        : NAMESPACE_NODE LPAREN RPAREN
        ;

//[175]
p_PITest
        : PROCESSING_INSTRUCTION LPAREN (p_NCName | p_StringLiteral)? RPAREN
        ;

//[176]
p_AttributeTest
        : ATTRIBUTE LPAREN (p_AttribNameOrWildcard (COMMA p_TypeName)?)? RPAREN
        ;

//[177]
p_AttribNameOrWildcard  
        : p_AttributeName | STAR
        ;

//[178]
p_SchemaAttributeTest
        : SCHEMA_ATTRIBUTE LPAREN p_AttributeDeclaration RPAREN
        ;

//[179]
p_AttributeDeclaration
        : p_AttributeName
        ;

//[180]
p_ElementTest
        : ELEMENT LPAREN (p_ElementNameOrWildcard (COMMA p_TypeName QUESTION?)?)? RPAREN
        ;

//[181]
p_ElementNameOrWildcard
        : p_EQName | STAR ;

//[182]
p_SchemaElementTest
        : SCHEMA_ELEMENT LPAREN p_ElementDeclaration RPAREN
        ;

//[183]
p_ElementDeclaration
        : p_ElementName
        ;

//[184]
p_AttributeName
        : p_EQName
        ;

//[185]
p_ElementName
        : p_EQName
        ;

//[186]
p_TypeName
        : p_EQName
        ;

//[187]
p_FunctionTest
        : p_Annotation* (p_AnyFunctionTest | p_TypedFunctionTest)
        ;

//[188]
p_AnyFunctionTest
        : FUNCTION LPAREN STAR RPAREN
        ;

//[189]
p_TypedFunctionTest
        : FUNCTION LPAREN (p_SequenceType (COMMA p_SequenceType)*)? RPAREN AS p_SequenceType
        ;

//[190]
p_ParenthesizedItemType
        : LPAREN p_ItemType RPAREN
        ;

//[191]
//URILiteral ::= StringLiteral

//[192]
//TODO
//EQName ::= QName | URIQualifiedName

//[193] /* ws: explicit */
//TODO
//URIQualifiedName ::= URILiteral ":" NCName


// ****************
// Terminal Symbols
// ****************

//[194]
//L_IntegerLiteral

//[195] /* ws: explicit */
//L_DecimalLiteral

//[196] /* ws: explicit */
//L_DoubleLiteral

//[197] /* ws: explicit */
p_StringLiteral
        : QUOT { this.pushStringLexer(false);} pg_QuotStringLiteralContent QUOT { this.popLexer(); }
                -> ^(StringLiteral pg_QuotStringLiteralContent*)
        | APOS {this.pushStringLexer(true);} pg_AposStringLiteralContent APOS { this.popLexer(); }
                -> ^(StringLiteral pg_AposStringLiteralContent*)
        ;
        finally { this.addString(retval.start, retval.stop); }
// *************************************************
// This is not in the EBNF grammar.
// A special node is needed to keep track of different fragments in this string
pg_QuotStringLiteralContent
        : (ESCAPE_QUOT | L_CharRef | L_PredefinedEntityRef | ~(QUOT | AMP))*
        ;
// *************************************************

// *************************************************
// This is not in the EBNF grammar.
// A special node is needed to keep track of different fragments in this string
pg_AposStringLiteralContent
        : (ESCAPE_APOS | L_CharRef | L_PredefinedEntityRef | ~(APOS | AMP))*
        ;
// *************************************************

//[198] /* ws: explicit */
//L_PredefinedEntityRef

//[199]
//ESCAPE_QUOT

//[200]
//ESCAPE_APOS

//[201]
p_ElementContentChar
        : L_ElementContentChar
        ;

//[202]
p_QuotAttrContentChar
        : L_QuotAttrContentChar
                -> ^(AttributeValueChar L_QuotAttrContentChar)
        ;

//[203]
p_AposAttrContentChar
        : L_AposAttrContentChar
                -> ^(AttributeValueChar L_AposAttrContentChar)
        ;


//[204] /* ws: explicit */
//      /* gn: comments */
//L_Comment
        
//TODO
//[205] /* xgs: xml-version */
//PITarget ::= [http://www.w3.org/TR/REC-xml#NT-PITarget]

//[206]
//L_CharRef

p_EQName
        : p_QName
        | p_URIQualifiedName
        ;

p_URIQualifiedName
        : p_BracedURILiteral p_NCName
        ;

p_BracedURILiteral
        : Q LBRACKET (L_PredefinedEntityRef | L_CharRef | ~(AMP | LBRACKET | RBRACKET))* RBRACKET  
        ;

//[207] /* xgc: xml-version */
p_QName 
        @init {this.setWsExplicit(true);}
        : pg_QName
        | p_NCName
                -> ^(QName p_NCName)
        ;
        finally {this.setWsExplicit(false);}
// additional production used to resolve the function name exceptions
pg_FQName
        : pg_QName
        | p_FNCName
                -> ^(QName p_FNCName)
		;
pg_QName
        : nn=p_NCName COLON nl=p_NCName
                -> ^(QName $nn $nl)
        ;


////[207] /* ws: explicit */ - resolved through the additional productions
//p_QName @init {setWsExplicit(true);}
//        : p_NCName pg_LocalNCName
//                -> ^(QName p_NCName pg_LocalNCName?)
//        ;
//// rule needed in order to catch the missing
//// COLON and restore to non-explicit mode
//pg_LocalNCName
//        : (COLON p_NCName)?
//        ;
//        finally {setWsExplicit(false);}
//// additional production used to resolve the function name exceptions
//pg_FQName @init {setWsExplicit(true);}
//        : p_FNCName pg_LocalFNCName
//        ;
//// rule needed in order to catch the missing
//// COLON and restore to non-explicit mode
//pg_LocalFNCName
//        : (COLON p_NCName)?
//        ;
//        finally {setWsExplicit(false);}




//[208] /* xgc: xml-version */
p_NCName
        : L_NCName
        // XQuery 1.0 keywords
        | ANCESTOR | ANCESTOR_OR_SELF | AND | AS | ASCENDING | AT | ATTRIBUTE | BASE_URI | BOUNDARY_SPACE | BY | CASE | CAST | CASTABLE | CHILD | COLLATION | COMMENT | CONSTRUCTION | COPY_NAMESPACES | DECLARE | DEFAULT | DESCENDANT | DESCENDANT_OR_SELF | DESCENDING | DIV | DOCUMENT | DOCUMENT_NODE | ELEMENT | ELSE | EMPTY | EMPTY_SEQUENCE | ENCODING | EQ | EVERY | EXCEPT | EXTERNAL | FOLLOWING | FOLLOWING_SIBLING | FOR | FUNCTION | GE | GREATEST | GT | IDIV | IF | IMPORT | IN | INHERIT | INSTANCE | INTERSECT | IS | ITEM | LAX | LE | LEAST | LET | LT | MOD | MODULE | NAMESPACE | NE | NO_INHERIT | NO_PRESERVE | NODE | OF | OPTION | OR | ORDER | ORDERED | ORDERING | PARENT | PRECEDING | PRECEDING_SIBLING | PRESERVE | PROCESSING_INSTRUCTION | RETURN | SATISFIES | SCHEMA | SCHEMA_ATTRIBUTE | SCHEMA_ELEMENT | SELF | SOME | STABLE | STRICT | STRIP | SWITCH | TEXT | THEN | TO | TREAT | TYPESWITCH | UNION | UNORDERED | VALIDATE | VARIABLE | VERSION | WHERE | XQUERY
        // XQuery 3.0 keywords
        | ALLOWING | CATCH | CONTEXT | COUNT | DECIMAL_FORMAT | DECIMAL_SEPARATOR | DIGIT | END | GROUP | GROUPING_SEPARATOR | INFINITY | MINUS_SIGN | NAMESPACE_NODE | NAN | NEXT | ONLY | PATTERN_SEPARATOR | PERCENT | PER_MILLE | PREVIOUS | SLIDING | START | TRY | TUMBLING | TYPE | WHEN | WINDOW | ZERO_DIGIT
        // XQuery Update 1.0 keywords
        | AFTER | BEFORE | COPY | DELETE | FIRST | INSERT | INTO | LAST | MODIFY | NODES | RENAME | REPLACE | REVALIDATION | SKIP | VALUE | WITH
        | APPEND | JSON | POSITION | STRUCTURED_ITEM | JSON_ITEM | OBJECT | ARRAY
        // XQuery Full Text 1.0 keywords
        | ALL | ANY | CONTAINS | CONTENT | DIACRITICS | DIFFERENT | DISTANCE | ENTIRE | EXACTLY | FROM | FT_OPTION | FTAND | FTNOT | FTOR | INSENSITIVE | LANGUAGE | LEVELS | LOWERCASE | MOST | NO | NOT | OCCURS | PARAGRAPH | PARAGRAPHS | PHRASE | RELATIONSHIP | SAME | SCORE | SENSITIVE | SENTENCE | SENTENCES | STEMMING | STOP | THESAURUS | TIMES | UPPERCASE | USING | WEIGHT | WILDCARDS | WITHOUT | WORD | WORDS
        // new XQuery Scripting proposal keywords
        | BREAK | CONTINUE | EXIT | LOOP | RETURNING | WHILE
        // Zorba DDL keywords
        | CHECK | COLLECTION | CONSTRAINT | FOREACH | FOREIGN | INDEX | INTEGRITY | KEY | ON | UNIQUE
        // entity references
        | AMP_ER | APOS_ER | QUOT_ER
        ;
p_FNCName
        : L_NCName
        // XQuery 1.0 keywords
        | ANCESTOR | ANCESTOR_OR_SELF | AND | AS | ASCENDING | AT | BASE_URI | BOUNDARY_SPACE | BY | CASE | CAST | CASTABLE | CHILD | COLLATION | CONSTRUCTION | COPY_NAMESPACES | DECLARE | DEFAULT | DESCENDANT | DESCENDANT_OR_SELF | DESCENDING | DIV | DOCUMENT | ELSE | EMPTY | ENCODING | EQ | EVERY | EXCEPT | EXTERNAL | FOLLOWING | FOLLOWING_SIBLING | FOR | FUNCTION | GE | GREATEST | GT | IDIV | IMPORT | IN | INHERIT | INSTANCE | INTERSECT | IS | LAX | LE | LEAST | LET | LT | MOD | MODULE | NAMESPACE | NE | NO_INHERIT | NO_PRESERVE | OF | OPTION | OR | ORDER | ORDERED | ORDERING | PARENT | PRECEDING | PRECEDING_SIBLING | PRESERVE | RETURN | SATISFIES | SCHEMA | SELF | SOME | STABLE | STRICT | STRIP | THEN | TO | TREAT | UNION | UNORDERED | VALIDATE | VARIABLE | VERSION | WHERE | XQUERY
        // XQuery 3.0 keywords
        | ALLOWING | CATCH | CONTEXT | COUNT | DECIMAL_FORMAT | DECIMAL_SEPARATOR | DIGIT | END | GROUP | GROUPING_SEPARATOR | INFINITY | MINUS_SIGN | NAN | NEXT | ONLY | PATTERN_SEPARATOR | PERCENT | PER_MILLE | PREVIOUS | SLIDING | START | TRY | TUMBLING | TYPE | WHEN | WINDOW | ZERO_DIGIT
        // XQuery Update 1.0 keywords
        | AFTER | BEFORE | COPY | DELETE | FIRST | INSERT | INTO | LAST | MODIFY | NODES | RENAME | REPLACE | REVALIDATION | SKIP | UPDATING | VALUE | WITH
        | APPEND | JSON | POSITION
        // XQuery Full Text 1.0 keywords
        | ALL | ANY | CONTAINS | CONTENT | DIACRITICS | DIFFERENT | DISTANCE | ENTIRE | EXACTLY | FROM | FT_OPTION | FTAND | FTNOT | FTOR | INSENSITIVE | LANGUAGE | LEVELS | LOWERCASE | MOST | NO | NOT | OCCURS | PARAGRAPH | PARAGRAPHS | PHRASE | RELATIONSHIP | SAME | SCORE | SENSITIVE | SENTENCE | SENTENCES | STEMMING | STOP | THESAURUS | TIMES | UPPERCASE | USING | WEIGHT | WILDCARDS | WITHOUT | WORD | WORDS
        // new XQuery Scripting proposal keywords
        | BREAK | CONTINUE | EXIT | LOOP | RETURNING
        // Zorba DDL keywords
        | CHECK | COLLECTION | CONSTRAINT | FOREACH | FOREIGN | INDEX | INTEGRITY | KEY | ON | UNIQUE
        // entity references
        | AMP_ER | APOS_ER | QUOT_ER
        ;

//[209] /* xgc: xml-version */
//S

//[210] /* xgc: xml-version */
//Char

//[211]
//Digits ::= [0-9]+

//[212]
//CommentContents ::= (Char+ - (Char* ('(:' | ':)') Char*))


// **************************************
// XQuery Update 1.0 Productions
// http://www.w3.org/TR/xquery-update-10/
// **************************************

pg_UpdateExpr
        : p_InsertExpr
        | p_DeleteExpr
        | p_RenameExpr
        | p_ReplaceExpr
        | p_TransformExpr
       // | p_JSONDeleteExpr
       // | p_JSONInsertExpr
       // | p_JSONRenameExpr
       // | p_JSONReplaceExpr
       // | p_JSONAppendExpr
        ;

//p_JSONDeleteExpr
//        : DELETE JSON p_TargetExpr
//        ;
//
//p_JSONInsertExpr
//        : INSERT JSON (
//               ( LBRACKET p_PairConstructor (COMA p_PairConstructor) RBRACKET INTO p_ExprSingle[true] )
//            |  (LSQUARE RSQUARE INTO p_ExprSingle[true] AT POSITION p_ExprSingle[true])
//          )
//        ;
//
//p_JSONRenameExpr
//        : RENAME JSON p_TargetExpr (LPAREN p_ExprSingle[true]  RPAREN)+ AS p_ExprSingle[true] 
//        ;
//
//p_JSONReplaceExpr
//        :  k+=REPLACE k+=JSON k+=VALUE k+=OF p_TargetExpr (LPAREN p_ExprSingle[true] RPAREN)+ k+=WITH p_ExprSingle[true] {this.ak($k);}
//        ;
//
//p_JSONAppendExpr
//        :  APPEND JSON LSQUARE p_ExprSingle[true] RSQUARE TO p_ExprSingle[true]
//        ;

//[141]
pm_RevalidationDecl
        : k+=DECLARE k+=REVALIDATION (k+=STRICT | k+=LAX | k+=SKIP) {this.ak($k);} SEMICOLON
        ;

//[142]
p_InsertExprTargetChoice
        : ((k+=AS (k+=FIRST | k+=LAST))? k+=INTO) {this.ak($k);}
        | ka=AFTER {this.ak($ka);}
        | kb=BEFORE {this.ak($kb);}
        ;

//[143]
p_InsertExpr
        : k+=INSERT (k+=NODE | k+=NODES) p_SourceExpr p_InsertExprTargetChoice p_TargetExpr {this.ak($k);}
        ;

//[144]
p_DeleteExpr
        : k+=DELETE (k+=NODE | k+=NODES) p_TargetExpr {this.ak($k);}
        ;

//[145]
p_ReplaceExpr
        : k+=REPLACE (k+=VALUE k+=OF)? k+=NODE p_ExprSingle[true] k+=WITH p_ExprSingle[true] {this.ak($k);}
        ;

//[146]
p_RenameExpr
        : k+=RENAME k+=NODE p_TargetExpr k+=AS p_NewNameExpr {this.ak($k);}
        ;

//[147]
p_SourceExpr
        : p_ExprSingle[true]
        ;

//[148]
p_TargetExpr
        : p_ExprSingle[true]
        ;

//[149]
p_NewNameExpr
        : p_ExprSingle[true]
        ;

//[150]
p_TransformExpr
        : k+=COPY d=DOLLAR v=p_VarName { this.av($d, $v.stop); } BIND p_ExprSingle[true] (COMMA e=DOLLAR w=p_VarName { this.av($e, $w.stop); } BIND p_ExprSingle[true])* k+=MODIFY p_ExprSingle[true] k+=RETURN p_ExprSingle[true] {this.ak($k);} 
        ;


// **************************************
// XQuery Full Text 1.0 Productions
// http://www.w3.org/TR/xpath-full-text-10/
// **************************************

//[24] Full Text 1.0
pm_FTOptionDecl
        : k+=DECLARE k+=FT_OPTION p_FTMatchOptions SEMICOLON {this.ak($k);}
        ;

//[37] Full Text 1.0
p_FTScoreVar
        : ks=SCORE {this.ak($ks);} d=DOLLAR v=p_VarName { this.av($d, $v.stop); }
        ;

//[51] Full Text 1.0
p_FTContainsExpr
        : p_StringConcatExpr ( k+=CONTAINS k+=TEXT {this.ak($k);} p_FTSelection p_FTIgnoreOption? )?
        ;

//[144] Full Text 1.0
p_FTSelection
        : p_FTOr p_FTPosFilter*
        ;

//[145] Full Text 1.0
p_FTWeight
        : kw=WEIGHT {this.ak($kw);} LBRACKET p_Expr[true,true] RBRACKET
        ;

//[146] Full Text 1.0
p_FTOr
        : p_FTAnd ( ko=FTOR {this.ak($ko);} p_FTAnd )*
        ;

//[147] Full Text 1.0
p_FTAnd
        : p_FTMildNot ( ka=FTAND {this.ak($ka);} p_FTMildNot )*
        ;

//[148] Full Text 1.0
p_FTMildNot
        : p_FTUnaryNot ( k+=NOT k+=IN {this.ak($k);} p_FTUnaryNot )*
        ;

//[149] Full Text 1.0
p_FTUnaryNot
        : ( kn=FTNOT {this.ak($kn);} )? p_FTPrimaryWithOptions
        ;

//[150] Full Text 1.0
p_FTPrimaryWithOptions
        : p_FTPrimary p_FTMatchOptions? p_FTWeight?
        ;

//[168] Full Text 1.0
//Prefix       ::=      NCName

//[151] Full Text 1.0
p_FTPrimary
        : (p_FTWords p_FTTimes?)
        | (LPAREN p_FTSelection RPAREN)
        | p_FTExtensionSelection
        ;

//[152] Full Text 1.0
p_FTWords
        : p_FTWordsValue p_FTAnyallOption?
        ;

//[153] Full Text 1.0
p_FTWordsValue
        : p_StringLiteral
        | (LBRACKET p_Expr[true,true] RBRACKET)
        ;

//[154] Full Text 1.0
p_FTExtensionSelection
        : L_Pragma+ LBRACKET p_FTSelection? RBRACKET
        ;

//[155] Full Text 1.0
p_FTAnyallOption
        : ( (k+=ANY k+=WORD?) | (k+=ALL WORDS?) | k+=PHRASE ) {this.ak($k);}
        ;

//[156] Full Text 1.0
p_FTTimes
        : k+=OCCURS p_FTRange k+=TIMES {this.ak($k);}
        ;

//[157] Full Text 1.0
p_FTRange
        : ( (k+=EXACTLY p_AdditiveExpr)
        |   (k+=AT k+=LEAST p_AdditiveExpr)
        |   (k+=AT k+=MOST p_AdditiveExpr)
        |   (k+=FROM p_AdditiveExpr k+=TO p_AdditiveExpr) ) {this.ak($k);}
        ;

//[158] Full Text 1.0
p_FTPosFilter
        : p_FTOrder | p_FTWindow | p_FTDistance | p_FTScope | p_FTContent
        ;

//[159] Full Text 1.0
p_FTOrder
        : ko=ORDERED {this.ak($ko);}
        ;

//[160] Full Text 1.0
p_FTWindow
        : kw=WINDOW {this.ak($kw);} p_AdditiveExpr p_FTUnit
        ;

//[161] Full Text 1.0
p_FTDistance
        : kd=DISTANCE {this.ak($kd);} p_FTRange p_FTUnit
        ;

//[162] Full Text 1.0
p_FTUnit
        : ( k+=WORDS | k+=SENTENCES | k+=PARAGRAPHS ) {this.ak($k);}
        ;

//[163] Full Text 1.0
p_FTScope
        : (k+=SAME | k+=DIFFERENT) {this.ak($k);} p_FTBigUnit
        ;

//[164] Full Text 1.0
p_FTBigUnit
        : ( k+=SENTENCE | k+=PARAGRAPH ) {this.ak($k);}
        ;

//[165] Full Text 1.0
p_FTContent
        : ( (k+=AT k+=START) | (k+=AT k+=END) | (k+=ENTIRE k+=CONTENT) ) {this.ak($k);}
        ;

//[166] Full Text 1.0
p_FTMatchOptions
        : (ku=USING {this.ak($ku);} p_FTMatchOption)+
        ;

//[167] Full Text 1.0
p_FTMatchOption
        : p_FTLanguageOption
        | p_FTWildCardOption
        | p_FTThesaurusOption
        | p_FTStemOption
        | p_FTCaseOption
        | p_FTDiacriticsOption
        | p_FTStopWordOption
        | p_FTExtensionOption
        ;

//[168] Full Text 1.0
p_FTCaseOption
        : ( (k+=CASE k+=INSENSITIVE)
        |   (k+=CASE k+=SENSITIVE)
        |   k+=LOWERCASE
        |   k+=UPPERCASE ) {this.ak($k);}
        ;

//[169] Full Text 1.0
p_FTDiacriticsOption
        : ( (k+=DIACRITICS k+=INSENSITIVE)
        |   (k+=DIACRITICS k+=SENSITIVE) ) {this.ak($k);}
        ;

//[170] Full Text 1.0
p_FTStemOption
        : ( k+=STEMMING | (k+=NO k+=STEMMING) ) {this.ak($k);}
        ;

//[171] Full Text 1.0
p_FTThesaurusOption
        : ( (k+=THESAURUS (p_FTThesaurusID | k+=DEFAULT))
        |   (k+=THESAURUS LPAREN (p_FTThesaurusID | k+=DEFAULT) (COMMA p_FTThesaurusID)* RPAREN)
        |   (k+=NO k+=THESAURUS) ) {this.ak($k);}
        ;

//[172] Full Text 1.0
p_FTThesaurusID
        : k+=AT p_StringLiteral (k+=RELATIONSHIP p_StringLiteral)? (p_FTLiteralRange k+=LEVELS)? {this.ak($k);}
        ;

//[173] Full Text 1.0
p_FTLiteralRange
        : ( (k+=EXACTLY L_IntegerLiteral)
        |   (k+=AT k+=LEAST L_IntegerLiteral)
        |   (k+=AT k+=MOST L_IntegerLiteral)
        |   (k+=FROM L_IntegerLiteral TO L_IntegerLiteral) ) {this.ak($k);}
        ;

//[174] Full Text 1.0
p_FTStopWordOption
        : ( (k+=STOP k+=WORDS p_FTStopWords p_FTStopWordsInclExcl*)
        |   (k+=STOP k+=WORDS k+=DEFAULT p_FTStopWordsInclExcl*)
        |   (k+=NO k+=STOP k+=WORDS) ) {this.ak($k);}
        ;

//[175] Full Text 1.0
p_FTStopWords
        : (ka=AT {this.ak(ka);} p_StringLiteral)
        | (LPAREN p_StringLiteral (COMMA p_StringLiteral)* RPAREN)
        ;

//[176] Full Text 1.0
p_FTStopWordsInclExcl
        : ( (k+=UNION | k+=EXCEPT) p_FTStopWords ) {this.ak($k);}
        ;

//[177] Full Text 1.0
p_FTLanguageOption
        : kl=LANGUAGE {this.ak(kl);} p_StringLiteral
        ;

//[178] Full Text 1.0
p_FTWildCardOption
        : ( k+=WILDCARDS | (k+=NO k+=WILDCARDS) ) {this.ak($k);}
        ;

//[179] Full Text 1.0
p_FTExtensionOption
        : ko=OPTION {this.ak(ko);} p_QName p_StringLiteral
        ;

//[180] Full Text 1.0
p_FTIgnoreOption
        : k+=WITHOUT k+=CONTENT {this.ak($k);} p_UnionExpr
        ;


// **************************************
// XQuery Scripting proposal Productions
// http://xquery-scripting.ethz.ch/spec.html
// **************************************

//[1]
p_Program
        : p_StatementsAndOptionalExpr
        ;

//[2]
p_Statements[strict]
        : p_Hybrid[$strict,true]*
        ;

//[3]
p_StatementsAndExpr
        : p_Statements[false]
        ;

//[4]
p_StatementsAndOptionalExpr
        : p_Statements[false]
        ;

p_Hybrid[strict, allowConcat]
        : p_HybridExprSingle[$strict,$allowConcat]
        | p_Statement
        ;
catch [re] {
  if(re instanceof org.antlr.runtime.RecognitionException) {
    //console.log("catch3");
    var v = this.p_StepExpr();
    root_0 = this.adaptor.nil();
    this.adaptor.addChild(root_0, v.getTree());
    retval.stop = this.input.LT(-1);
    retval.tree = this.adaptor.rulePostProcessing(root_0);
    this.adaptor.setTokenBoundaries(retval.tree, retval.start, retval.stop);
  } else {
    throw re;
  }
}

p_Statement
        : p_AssignStatement
        | p_BreakStatement
        | p_ContinueStatement
        | p_ExitStatement
        | p_VarDeclStatement
        | p_WhileStatement
        ;
p_HybridExprSingle[strict, allowConcat]
        : e=p_Expr[$strict,$allowConcat] { if ($strict || this.input.LT(1).getType() != SEMICOLON) throw new org.antlr.runtime.RecognitionException(this.input); }
          SEMICOLON
        ;
catch [re] {
    if(re instanceof org.antlr.runtime.RecognitionException) {
      //console.log("catch4");
      root_0 = this.adaptor.nil();
      this.adaptor.addChild(root_0, e.getTree());
      retval.stop = this.input.LT(-1);
      retval.tree = this.adaptor.rulePostProcessing(root_0);
      this.adaptor.setTokenBoundaries(retval.tree, retval.start, retval.stop);
    } else {
      throw re;
    }
}

//[5]
//p_Statement
//        : p_AssignStatement
//        | p_BlockStatement
//        | p_BreakStatement
//        | p_ContinueStatement
//        | p_ExitStatement
//        | p_VarDeclStatement
//        | p_WhileStatement

//        | p_ApplyStatement
//        | p_FLWORStatement
//        | p_IfStatement
//        | p_SwitchStatement
//        | p_TryCatchStatement
//        | p_TypeswitchStatement
//        ;

//[6]
p_ApplyStatement
        : p_ExprSimple SEMICOLON
        ;

//[7]
p_AssignStatement
        : d=DOLLAR v=p_VarName { this.av($d, $v.stop); } BIND p_ExprSingle[true] SEMICOLON
        ;

//[8]
p_BlockStatement
        : LBRACKET p_Statements[false] RBRACKET
        ;

p_BlockHybrid[strict]
        : LBRACKET p_Statements[$strict] RBRACKET
        ;

//[9]
p_BreakStatement
        : k=BREAK {this.ak($k);} k=LOOP {this.ak($k);} SEMICOLON
        ;

//[10]
p_ContinueStatement
        : k=CONTINUE {this.ak($k);} k=LOOP {this.ak($k);} SEMICOLON
        ;

//[11]
p_ExitStatement
        : k=EXIT {this.ak($k);} k=RETURNING {this.ak($k);} p_ExprSingle[true] SEMICOLON
        ;

//[12]
p_FLWORStatement
        : p_InitialClause p_IntermediateClause* p_ReturnStatement
        ;    

//[13]
p_ReturnStatement
        : k=RETURN {this.ak($k);} p_Hybrid[false,false]
        ;

//[14]
p_IfStatement
        : k=IF {this.ak($k);} LPAREN p_Expr[true,true] RPAREN k=THEN {this.ak($k);} p_Hybrid[false,false] k=ELSE {this.ak($k);} p_Hybrid[false,false]
        ;

//[15]
p_SwitchStatement
        : k=SWITCH {this.ak($k);} LPAREN p_Expr[true,true] RPAREN p_SwitchCaseStatement+ k=DEFAULT {this.ak($k);} k=RETURN {this.ak($k);} p_Hybrid[false,false]
        ;

//[16]
p_SwitchCaseStatement
        : (k=CASE {this.ak($k);} p_SwitchCaseOperand)+ k=RETURN {this.ak($k);} p_Hybrid[false,false]
        ;

//[17]
p_TryCatchStatement
        : k=TRY {this.ak($k);} p_BlockStatement (k=CATCH {this.ak($k);} p_CatchErrorList p_BlockStatement)+ {this.ak($k);}
        ;

p_TryCatchHybrid[strict]
        : k=TRY {this.ak($k);} p_BlockHybrid[$strict] (k=CATCH {this.ak($k);} p_CatchErrorList p_BlockHybrid[$strict])+ {this.ak($k);}
        ;

//[18]
p_TypeswitchStatement
        : k=TYPESWITCH {this.ak($k);} LPAREN p_Expr[true,true] RPAREN p_CaseStatement+ k=DEFAULT {this.ak($k);} (d=DOLLAR v=p_VarName { this.av($d, $v.stop); })? k=RETURN {this.ak($k);} p_Hybrid[false,false]
        ;

//[19]
p_CaseStatement
        : k=CASE {this.ak($k);} (d=DOLLAR v=p_VarName { this.av($d, $v.stop); } AS)? p_SequenceType k=RETURN {this.ak($k);} p_Hybrid[false,false]
        ;

//[20]
p_VarDeclStatement
        : p_Annotation* k=VARIABLE {this.ak($k);} d=DOLLAR v=p_VarName { this.av($d, $v.stop); } p_TypeDeclaration? (BIND p_ExprSingle[true])?
          (COMMA e=DOLLAR w=p_VarName { this.av($e, $w.stop); } p_TypeDeclaration? (BIND p_ExprSingle[true])?)*
          SEMICOLON
        ;

//[21]
p_WhileStatement
        : k=WHILE {this.ak($k);} LPAREN p_Expr[true,true] RPAREN p_Hybrid[false,false]
        ;

//[23]
p_ExprSimple
        : p_QuantifiedExpr
        | p_OrExpr
        | {this.lc(XQU)}?=> pg_UpdateExpr
        ;

//[31]
p_BlockExpr
        : LBRACKET p_StatementsAndExpr RBRACKET
        ;

// *************************************************
// XQDDL
// http://www.zorba-xquery.com/site2/doc/latest/zorba/html/xqddf.html
// *************************************************
p_CollectionDecl
        : k=COLLECTION {this.ak($k);} p_QName p_CollectionTypeDecl?
        ;

p_CollectionTypeDecl
        : (k=AS {this.ak($k);} p_KindTest ((p_OccurrenceIndicator) => p_OccurrenceIndicator)?)
        ;

p_IndexDecl
        : k=INDEX {this.ak($k);} p_IndexName k=ON {this.ak($k);} k=NODES {this.ak($k);} p_IndexDomainExpr k=BY {this.ak($k);} p_IndexKeySpec (COMMA p_IndexKeySpec)*
        ;

p_IndexName
        : p_QName
        ;

p_IndexDomainExpr
        : p_PathExpr
        ;

p_IndexKeySpec
        : p_IndexKeyExpr p_IndexKeyTypeDecl? p_IndexKeyCollation?
        ;

p_IndexKeyExpr
        : p_PathExpr
        ;

p_IndexKeyTypeDecl
        : k=AS {this.ak($k);} p_AtomicType p_OccurrenceIndicator?
        ;

p_AtomicType
        : p_QName
        ;

p_IndexKeyCollation
        : k=COLLATION {this.ak($k);} p_StringLiteral
        ;

p_ICDecl
        : k=INTEGRITY {this.ak($k);} k=CONSTRAINT {this.ak($k);} p_QName (p_ICCollection | p_ICForeignKey)
        ;

p_ICCollection
        : k=ON {this.ak($k);} k=COLLECTION {this.ak($k);} p_QName (p_ICCollSequence | p_ICCollSequenceUnique | p_ICCollNode)
        ;

p_ICCollSequence
        : d=DOLLAR v=p_QName { this.av($d, $v.stop); } k=CHECK {this.ak($k);} p_ExprSingle[true]
        ;

p_ICCollSequenceUnique
        : k=NODE {this.ak($k);} d=DOLLAR v=p_QName { this.av($d, $v.stop); } k=CHECK {this.ak($k);} k=UNIQUE {this.ak($k);} k=KEY {this.ak($k);} p_PathExpr
        ;

p_ICCollNode
        : k=FOREACH {this.ak($k);} k=NODE {this.ak($k);} d=DOLLAR v=p_QName { this.av($d, $v.stop); } k=CHECK {this.ak($k);} p_ExprSingle[true]
        ;

p_ICForeignKey
        : k=FOREIGN {this.ak($k);} k=KEY {this.ak($k);} p_ICForeignKeySource p_ICForeignKeyTarget
        ;

p_ICForeignKeySource
        : k=FROM {this.ak($k);} p_ICForeignKeyValues
        ;

p_ICForeignKeyTarget
        : k=TO {this.ak($k);} p_ICForeignKeyValues
        ;

p_ICForeignKeyValues
        : k=COLLECTION {this.ak($k);} p_QName k=NODE {this.ak($k);} d=DOLLAR v=p_QName { this.av($d, $v.stop); } k=KEY {this.ak($k);} p_PathExpr
        ;
// *************************************************



//TODO
// VarDecl changes structure of the tree: less children: this will break something in the variable type reading in XQDT
// Enabling p_FunctionItemExpr in p_PrimaryExpr will break the grammar and generate an error stating the p_OrderedExpr, p_UnorderedExpr, and p_FunctionItemExpr can never be matched
// Also when p_PostfixExpr accepts p_ArgumentList a recursion appears that ANTLR does not like: rule p_PostfixExpr has non-LL(*) decision due to recursive rule invocations reachable from alts 1,2.  Resolve by left-factoring or using syntactic predicates or using backtrack=true option.
