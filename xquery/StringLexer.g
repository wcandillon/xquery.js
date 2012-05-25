lexer grammar StringLexer;

options {
superClass='XQDTLexer';
tokenVocab=XQueryLexer;
language=JavaScript;
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
  var XQDTLexer = require("./XQDTLexer").XQDTLexer;
}

@lexer::members {

this.inQuotStr = false;
this.inAposStr = false;

//boolean inQuotStr = false;
//boolean inAposStr = false;

//public StringLexer(CharStream input, boolean isAposStr) {
//	this(input, new RecognizerSharedState());
//	this.inAposStr = isAposStr;
//	this.inQuotStr = !isAposStr;
//	setIsWsExplicit(true);
//}
}

QUOT	:	{ this.inQuotStr }? => '"' { this.inQuotStr = !this.inQuotStr; };
APOS	:	{ this.inAposStr }? => '\'' { this.inAposStr = !this.inAposStr; };
ESCAPE_QUOT	:	{ this.inQuotStr }? => '""';
ESCAPE_APOS	:	{ this.inAposStr }? => '\'\'';

// [145]
L_PredefinedEntityRef
	:	{ this.inQuotStr | this.inAposStr }? =>	'&' ('lt' | 'gt' | 'apos' | 'quot' | 'amp' ) ';'
	;

//[153]
L_CharRef
	:	{ this.inQuotStr | this.inAposStr }? => '&#' '0'..'9'+ ';' | '&#x' ('0'..'9'|'a'..'f'|'A'..'F')+ ';'
	;

L_QuotStringLiteralChar
	:	{ this.inQuotStr }? =>
		('\u0009' | '\u000A' | '\u000D' | '\u0020'..'\u0021' | '\u0023'..'\u0025' 
		| '\u0027'..'\uD7FF' |	'\uE000'..'\uFFFD')+
	;

L_AposStringLiteralChar
	:	{ this.inAposStr }? =>
		('\u0009' | '\u000A' | '\u000D' | '\u0020'..'\u0025'
		| '\u0028'..'\uD7FF' | '\uE000'..'\uFFFD')+
	;

//L_AnyChar 
//	:	{!this.inQuotStr && !this.inAposStr}? => .;

L_AnyChar
//  :    '\UFF02';
    :   { !this.inQuotStr && !this.inAposStr }? =>
        ('\u0009' | '\u000A' | '\u000D' | '\u0020'..'\u0025' | '\u0027'..'\u003B' 
        | '\u003D'..'\u007A' | '\u007C' | '\u007E'..'\uD7FF' | '\uE000'..'\uFFFD')+
    ;
	
