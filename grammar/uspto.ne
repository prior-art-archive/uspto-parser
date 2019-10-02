# We use a lexer to split the string into tokens
@{%
	const moo = require('moo')

	const lexer = moo.compile({
		comment: /#.*/,
		literal: /".*?"/, // Exact phrases can be included in double quotes
		whitespace: { match: /\s+/, lineBreaks: true },
		number: /\d+/,
		unpairedQuote: '"', // To be treated as whitespace
		orOperator: '|', // An alternative to "OR"
		andOperator: '&', // An alternative to "AND"
		fuzzyOperator: '~',
		boostOperator: '^',
		wildcard: /\$\d*/,
		lineNumber: /L\d*/,
		leftParen: '(',
		rightParen: ')',
		extensionOperator: '.',
		fieldOperator: '/',
		term: [
			{
				match: /[^\s"#\|&()\d\.\/~\^\$]+/,
				type: moo.keywords({
					booleanOperator: ['OR', 'AND', 'NOT', 'XOR'],
					proximityOperator: ['ADJ','NEAR','WITH','SAME'],
					field: [
						'ATT', 'AT', 'KD', 'PARN', 'SRC', 'PDID', 'PD', 'PRAN', 'PRN', 'PRCO', 'PRC', 'PRAD',
						'PRD', 'PRAY', 'PRY', 'RLAN', 'RLPN', 'ART', 'UNIT', 'ASCI', 'ASCO', 'ASCC', 'ASTX', 'ASST',
						'ASZP', 'CCLS', 'COR', 'CCOR', 'CXR', 'CCXR', 'CLAS', 'ICLS', 'IOR', 'CIOR', 'IXR', 'CIXR',
						'IPCC', 'IPCR', 'IPC', 'CICL', 'DD', 'FS', 'BI', 'XA', 'XP', 'GI', 'INCI', 'INCO',
						'INCC', 'INTX', 'INST', 'INSA', 'INZP', 'PN', 'DID', 'ISD', 'PY', 'ISY', 'AB', 'BSUM',
						'CLM', 'DETD', 'DRWD', 'TI', 'PTAN', 'PTAD', 'PT3D', 'PTPN', 'PTPD', 'FRPN', 'FRCO', 'FIPC',
						'FRGP', 'FRCL', 'OREF', 'UREF', 'URGP', 'URCL', 'READ', 'REFD', 'REAN', 'REPD', 'REPN', 'R47X',
						'CPC', 'URPN', 'INV', 'AD', 'FD', 'AY', 'FY', 'PPPD', 'ASGP', 'AS', 'INGP', 'IN',
						'APNR', 'APN', 'APP', 'AP',
					],
				}),
			},
		],
	})
%}

@lexer lexer

query -> _ clause comment:?

clause ->
	  terms
	| (terms conjunction __ clause)

conjunction ->
	booleanOperator

terms -> (
	  atomicTerm _
	| closedClause _
	| proximityClause _
	| fieldClause _
	| fuzzyClause _
	| boostClause _
	| lineClause _
):+

atomicTerm ->
	  %term
	| %literal
	| %number
	| wildcardClause

##############
## Comments ##
# Anything following ‘#’ will be completely removed from the search text.
comment -> %comment

####################
## Closed Clauses ##
# clauses contained in parentheses
# TODO: This parser assumes balanaced parentheses
closedClause -> %leftParen _ clause %rightParen

#######################
## Proximity Clauses ##
# clauses that identify pairs of nearby terms
proximityClause ->
	  atomicTerm _ proximityOperator __ atomicTerm

###################
## Field Clauses ##
# Users can search via specific field, either invoking
# - extension: `*.FIELD`
# - field flag: `FIELD/*`
fieldClause ->
	  extension
	| flag

extension -> atomicTerm %extensionOperator %field
flag -> %field %fieldOperator atomicTerm

##################
## Fuzzy Clause ##
# ‘~’ if used in search text will always have a number following ‘~’
# and  will be interpreted as ‘FUZZY’ of the preceding string with a
# similarity of the following number.
fuzzyClause -> atomicTerm %fuzzyOperator %number

##################
## Boost Clause ##
# ‘^’ if used in search text will always have a number following ‘^’
# and this number will be used as ‘BOOST’ value for the string preceding ‘^’.
boostClause -> atomicTerm %boostOperator %number

##################
## Wildcard Clause ##
# ‘$‘ will be interpreted as any number of characters
# ‘$n’ will be interpreted as n number of characters
wildcardClause -> atomicTerm %wildcard

#################
## Line Clause ##
# Line numbers used in search text will be of the form L followed by the line number
lineClause -> %lineNumber

#######################
## Boolean Operators ##
# These operators allow for combined clauses.
# - OR (or |)
# - AND (or &)
# - NOT
# - XOR
booleanOperator ->
	  %booleanOperator
	| %orOperator
	| %andOperator

#########################
## Proximity Operators ##
# Clauses that contain proximity operators.
#
# Proximity operators make it possible to compare distance between terms
# - ADJ: TermA next to TermB in the order specified in the same sentence.
# - NEAR: next to Terms in any order in the same sentence.
# - WITH: TermA in the same sentence with TermB.
# - SAME: TermA in the same paragraph with Terms
#
# You can also modify distances for some proximity clauses
# - ADJn: TermA within n terms of Bin the order specified in the same sentence.
# - NEARn: TermA within n terms of B in any order in the same sentence.
# - SAMEn: TermA within n paragraphs of TermB
# where "n" is a number
proximityOperator ->
	  %proximityOperator
	| %proximityOperator %number

################
## Whitespace ##
_ -> (whitespace:+):?
__ -> whitespace

whitespace ->
	  %whitespace
	| %unpairedQuote
