lexer grammar XMLLexer;

options {
tokenVocab=XQueryLexer;
superClass='XQDTLexer';
language=JavaScript;
}

tokens {
// Imported tokens
L_QuotAttrContentChar;
L_AposAttrContentChar;
L_ElementContentChar;
L_PredefinedEntityRef;
L_CharRef;
ESCAPE_LBRACKET;
ESCAPE_RBRACKET;
ESCAPE_APOS;
ESCAPE_QUOT;
CDATA_START;
CDATA_END;
}

@header {
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
var XQDTLexer   = require("./XQDTLexer").XQDTLexer;
} // @header

@lexer::members {

this.inElem = true;
this.inAposAttr = false;
this.inQuotAttr = false;

this.isInElement = function()
{
   return this.inElem;
}

this.isInAposAttribute = function()
{
   return this.inAposAttr;
}

this.isInQuotAttr = function()
{
   return this.inQuotAttr;
}
    
this.addToStack = function(stack) {
	if (!this.inAposAttr && !this.inQuotAttr)
		this.inElem = false;
	stack.push(this);
} 


// dummy list for warning elimination
//List<Stack<Object>> dummy = new ArrayList<Stack<Object>>();

// when we start, the '<' has already been eaten by the other lexer
//boolean inElem = true;
//boolean inAposAttr = false;
//boolean inQuotAttr = false;
//
//public boolean isInElement()
//{
//   return inElem;
//}
//
//public boolean isInAposAttribute()
//{
//   return inAposAttr;
//}
//
//public boolean isInQuotAttr()
//{
//   return inQuotAttr;
//}
//    
//@Override
//public void addToStack(List<XQDTLexer> stack) {
//	if (!inAposAttr && !inQuotAttr)
//		inElem = false;
//	stack.add(this);
//} 
//
//private boolean log() {
//	System.out.println("inApos:\t" + inAposAttr);
//	System.out.println("inQuot:\t" + inQuotAttr);
//	System.out.println("inElem:\t" + inElem);
//	System.out.println("---------------------");
//	return false;
//}

} // @lexer::members

QUOT	:	{ this.inElem || this.inQuotAttr }? => '"' { if (!this.inAposAttr) this.inQuotAttr = (!this.inQuotAttr); };
APOS	:	{ this.inElem || this.inAposAttr }? => '\'' { if (!this.inQuotAttr) this.inAposAttr = !this.inAposAttr; };

L_QuotAttrContentChar
	:	{ this.inQuotAttr }? =>
		('\u0009' | '\u000A' | '\u000D' | '\u0020' | '\u0021' | '\u0023'..'\u0025' 
		| '\u0028'..'\u003B' | '\u003D'..'\u007A' | '\u007C'..'\u007C' | '\u007E'..'\uD7FF' |
		'\uE000'..'\uFFFD')+
	;

L_AposAttrContentChar
	:	{ this.inAposAttr }? =>
		('\u0009' | '\u000A' | '\u000D' | '\u0020' | '\u0021' | '\u0023'..'\u0025' 
		| '\u0028'..'\u003B' | '\u003D'..'\u007A' | '\u007C'..'\u007C' | '\u007E'..'\uD7FF' |
		'\uE000'..'\uFFFD')+
	;

L_ElementContentChar
//	:	 '\UFF02';
	:	{ !this.inElem }? =>
		('\u0009' | '\u000A' | '\u000D' | '\u0020'..'\u0025' | '\u0027'..'\u003B' 
		| '\u003D'..'\u007A' | '\u007C' | '\u007E'..'\uD7FF' | '\uE000'..'\uFFFD')+
	;


GREATER
	:	{ this.inElem }? => '>' { this.inElem = false; }
	;

EMPTY_CLOSE_TAG
	:	{ this.inElem }? => '/>' { this.inElem = false; }
	;

S
	:	{ this.inElem }? => (' ' | '\t' | '\r' | '\n')+
	;

//QName	:	{ this.inElem  }? => NCName (':' NCName)?;

L_NCName
	:	{ this.inElem }? => NCNameUnprotected
	;

fragment NCNameUnprotected
	:	NCNameStartChar NCNameChar*
	;

fragment NCNameStartChar
	:	Letter | '_'
	;

fragment NCNameChar
	:	Letter | XMLDigit | '.' | '-' | '_'
	; //| CombiningChar | Extender;

fragment Letter
	:	'a'..'z' | 'A'..'Z'
	;

fragment XMLDigit
	:	'0'..'9'
	;

//fragment Letter	:	{ CharHelper.isLetter(LA(1) }? =>  .;
//fragment BaseChar
//		:	{ CharHelper.isBaseChar(LA(1) }? =>  .;
//fragment Ideographic	
//		:	{ CharHelper.isIdeographic(LA(1)) }? =>  .;
//fragment XMLDigit
//		:	{ CharHelper.isXMLDigit(LA(1)) }? =>  .;
//fragment CombiningChar
//		:	{ CharHelper.isCombiningChar(LA(1)) }? =>  .;
//fragment Extender
//		:	{ CharHelper.isExtender(LA(1)) }? =>  .;

EQUAL	:	{ this.inElem  }? => '=';
ESCAPE_APOS	:	{ this.inAposAttr }? => '\'\'';
ESCAPE_QUOT	:	{ this.inQuotAttr }? => '""';

ESCAPE_LBRACKET
	:	{ !this.inElem || this.inAposAttr || this.inQuotAttr }? => '{{'
	;

ESCAPE_RBRACKET
	:	{ !this.inElem || this.inAposAttr || this.inQuotAttr }? => '}}'
	;

LBRACKET	:	{ !this.inElem || this.inAposAttr || this.inQuotAttr }? => '{';
RBRACKET	:	{ !this.inElem || this.inAposAttr || this.inQuotAttr }? => '}';
SMALLER :	'<';
CLOSE_TAG	:	{ !this.inElem }? => '</' { this.inElem = true; };

CDATA_START	: '<![CDATA[';
CDATA_END		: ']]>';

//[107]	/* ws: explicit */
L_CDataSection
		:	{ !this.inElem }? => CDATA_START (options {greedy=false;} : .*) CDATA_END
		;

//[108]	/* ws: explicit */ - resolved in the previous production
//CDataSectionContents

// [145]
L_PredefinedEntityRef
	:	{ !this.inElem || this.inAposAttr || this.inQuotAttr }? => '&' ('lt' | 'gt' | 'apos' | 'quot' | 'amp' ) ';'
	;

//[153]
L_CharRef
	:	{ !this.inElem || this.inAposAttr || this.inQuotAttr }? => '&#' ('0'..'9')+ ';' | '&#x' ('0'..'9'|'a'..'f'|'A'..'F')+ ';'
	;

L_DirCommentConstructor	
	:	{ !this.inElem }? => '<!--' (options {greedy=false;} : .* ) '-->'	/* ws: explicit */ ;

L_DirPIConstructor	
	:	{ !this.inElem }? => 
		'<?' SU? NCNameUnprotected (SU (options {greedy=false;} : .*))? '?>'	/* ws: explicit */ 
	;

fragment SU
	:	(' ' | '\t' | '\n' | '\r')+
	;
	
COLON	: ':';
