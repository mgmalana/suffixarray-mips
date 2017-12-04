; A = 41
; C = 43
; G = 47
; T = 54
; $ = 24
; Z = 5A

.data
DNA: .ascii "TGCAGGGGGATTTCATGGGGTAGGGATTCCAGTTTTGGAG$" ; given
ARR:   .space 41 ; final output

SUFF: .space 821 ; suffixes space. 821 = (40+41)/2 + 1

.code
; R1 starting index in DNA
; R2 offset from starting to curr index in DNA
; R3 curr index in SUFF
; R4 value of curr index in DNA, to store in SUFF

; R26 ARR index
; R29 DNA length
; R30 contains '$' value
; R25 contains 'Z' value

; -------------- init data
DADDIU R1, R0, 0x0000
DADDIU R3, R0, 0x0000

DADDIU R26, R0, 0x0000
DADDIU R29, R0, 0x0000
DADDIU R30, R0, 0x0024 ; init to '$'
DADDIU R25, R0, 0x005A ; init to 'Z'

; -------------- constructing suffixes
copySuff:
	DADDIU R2, R1, 0x0000 ; copy r1 to r2
	LB R4, DNA(R2) ; init curr index

copyByteInSuff:
	SB R4, SUFF(R3)
	DADDIU R2, R2, 0x0001 ; increment the dna index by 1
	DADDIU R3, R3, 0x0001 ; increment the suff index by 1
	
	LB R4, DNA(R2)
	SB R4, SUFF(R3)
	BNE R4, R30, copyByteInSuff

	; this part is called when a suffix is copied. next suffix will then be copied next
	DADDIU R1, R1, 0x0001 ; increment dna starting index by 1
	DADDIU R3, R3, 0x0001 ; increment the suff index by 1
	DADDIU R29, R29, 0x0001 ; increment the DNA len by 1

	BNE R1, R2, copySuff ; check if index r1 contains '$'

; appends '$' at the end
SB R30, SUFF(R3)

; adds +1 to dna length
DADDIU R29, R29, 0x0001

; -------------- start of sorting part
; R1 starting index of suffix 1
; R2 curr index of suffix 1
; R3 curr index value suffix 1
; R4 nth suffix 1
; R5 starting index of suffix 2
; R6 curr index of suffix 2
; R7 curr index value suffix 2
; R9 compare arrow
; R27 temp contains dna length
; R28 temp contains dna length - 1

 DADDIU R27, R29, 0x0001

; for loop. loops dna length times
suffixOuterCompareLoop:
	; position indexes
	DADDIU R1, R0, 0x0000
	DADDIU R5, R0, 0x0000
	DADDIU R28, R29, 0x0000

	DADDIU R27, R27, 0xFFFF ; decrement by 1
	BEQZ R27, doneLoop

; for loop. loops dna length - 1 times
suffixInnerCompareLoop:
	DADDIU R28, R28, 0xFFFF ; decrement by 1
	BEQZ R28, suffixEndInnerCompareLoop

DADDIU R2, R1, 0x0000
LB R3, SUFF(R2)

; iterate until next suffix starting index is found
findSuffix2:
	DADDIU R5, R5, 0x0001 ; increment starting index by 1
	LB R7, SUFF(R5)
	BEQZ R7, suffixEndInnerCompareLoop ; if zero
	BEQ R7, R25, findNextNonEmpty
	BNE R7, R30, findSuffix2

	B continue

findNextNonEmpty:
	DADDIU R5, R5, 0x0001 ; increment starting index by 1
	LB R7, SUFF(R5)
	BEQZ R7, suffixEndInnerCompareLoop ; if zero
	BEQ R7, R25, findNextNonEmpty

	DADDIU R5, R5, 0xFFFF
continue:

DADDIU R8, R8, 0x0001 ; increment nth suffix by 1
DADDIU R5,R5, 0x0001
DADDIU R6, R5, 0x0000
LB R7, SUFF(R6)

; compare the 2 suffixes here
compareSuffix1and2:
	SLTU R9, R3, R7

	BNEZ R9, suffix1LesserThan2 ; if curr index value suffix 1 less than suffix 2's
	BEQ R3, R7, suffix1And2NextIndex ; if values are equal

	B suffix1GreaterThan2 ; if curr index value suffix 1 greater than suffix 2's

suffix1LesserThan2:
	DADDIU R5, R6, 0x0000 ; init search for next suffix, start with the most recent index
	B suffixInnerCompareLoop

suffix1GreaterThan2:
	; reasssign suffix 2 to 1
	DADDIU R1, R5, 0x0000 ; starting index
	DADDIU R5, R6, 0xFFFF ; index before the stop sign
	B suffixInnerCompareLoop

suffix1And2NextIndex:
	DADDIU R2, R2, 0x0001 ; next index
	LB R3, SUFF(R2)
	DADDIU R6, R6, 0x0001 ; next index
	LB R7, SUFF(R6)
	B compareSuffix1and2

suffixEndInnerCompareLoop:
	DADDIU R2, R1, 0x0000 ; reset curr to starting index
	DADDIU R4, R0, 0x0000

countSuffixLen:
	LB R3, SUFF(R2)
	DADDIU R4, R4, 0x0001
	DADDIU R2, R2, 0x0001

	BNE R3, R30, countSuffixLen	

	DSUBU R4, R29, R4

	SB R4, ARR(R26)
	DADDIU R26, R26, 0x0001

	DADDIU R2, R1, 0x0000 ; reset curr to starting index

	; change the suffix characters to 'Z'
	removeSuffix:
		LB R3, SUFF(R2)
		SB R25, SUFF(R2)
		DADDIU R2, R2, 0x0001

		BEQZ R3, suffixOuterCompareLoop
		BEQ R3, R30, suffixOuterCompareLoop	

		B removeSuffix

doneLoop:
	NOP

