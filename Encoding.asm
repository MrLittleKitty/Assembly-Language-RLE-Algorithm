;************************************************************
; Eric Wolfe
;
; CS M30
;
; Programming Assignment 4
;
; The goal of this project is to write an assembly language
; procedure that compresses a file using a specific implementation
; of the Run Length Encoding algorithm. The procedure that uses this
; algorithm is then called from C++.
;
;************************************************************

        .586
        
        .MODEL flat						

        _RLE_Encode PROTO				                ;Prototype for the procedure

		.DATA

            ZeroState           EQU     0t
            Var1Offset          EQU     8t     
            Var2Offset          EQU     12t     
            Var3Offset          EQU     16t
            InitialRepeatCount  EQU     1t  
            OnlyBits6And7       EQU     0C0h
            MaxNumberIn6Bits    EQU     63t

        .CODE

_RLE_Encode PROC PUBLIC USES esi ecx ebx edi edx		;Start of the encoding precedure

			Local	BytesWritten:Dword  ;Variable that holds the number of bytes this procedure rights to the output buffer
			Local	CurrentByte:Byte    ;The current byte being checked for repeats by the encoding algorithm

			mov		BytesWritten, ZeroState		;Initialize our variable to 0

			mov		esi, [ebp + Var1Offset]		;Get the input buffer address from the stack

			mov		ecx, [ebp + Var2Offset]		;Get the input buffer length from the stack
			dec		ecx					        ;Decrement because we are 0 based

			mov		eax, ecx		            ;Move the loop upper bound into eax for later

			xor		ecx,ecx				        ;We are using ecx as our index into the input buffer so zero it out

			mov		edi, [ebp + Var3Offset]		;Get the output buffer address from the stack


			;Start scanning the input buffer and compressing
	
	LoopStart:
			mov		bl, [esi + ecx]				;Move the next byte (at address esi + ecx) into the variable
			mov		CurrentByte, bl				;^^^^
			inc		ecx						    ;Move the index to the next byte
	
			mov		edx, InitialRepeatCount		;edx is our repeat counter so we start it at 1 because we have atleast 1 of this byte
	ContLoop:
			cmp		ecx, eax				    ;Compare our index (ecx) to the upper bound of the loop (eax)
			jg		BeginEncoding				;If we are past the last possible index then we jump to encoding

			mov		bl, [esi + ecx]				;Move the next byte to compare to into ebx
			cmp		CurrentByte, bl				;Compare the current byte to the next byte to see if the current byte repeats
			jne		BeginEncoding				;If this byte isnt a repeat of the last byte then we jump to the encoding

			inc		edx							;This byte is a repeat of the last byte so increase the repeat count
			inc		ecx;						;Increase the index into the input buffer
			jmp		ContLoop					;Jump to continue scanning for repeats

	BeginEncoding:
			;Current byte is going to have the byte and edx is going to have the repeat count

			cmp		edx, InitialRepeatCount		;Check the repeat count
			jg		ComplicatedEncoding			;If the repeat count is greater than one then we need to do the complicated encoding
		
			;At this point the repeat count (edx) has to be 1

            mov     bl, CurrentByte             ;Move the byte that will be repeated once into bl for testing
            and     bl, OnlyBits6And7           ;Zero out all bits except for 6-7
            cmp     bl, OnlyBits6And7           ;Now that the only remaining bits are 6-7, check to see if the are both set
            je      ComplicatedEncoding         ;If they are set then this byte cant be encoded in a single byte

	SimpleEncoding:
            mov     bl, CurrentByte             ;Move the byte to be put into the output buffer into bl
            mov     [edi], bl                   ;Put the byte into the output buffer
            inc     edi                         ;Increment our index into the output buffer
            inc     BytesWritten                ;Increment the number of bytes written to output buffer

			jmp		DoneEncoding

	ComplicatedEncoding:
			mov		ebx, edx					;Move the repeat count into ebx for formatting
            
            cmp     ebx, MaxNumberIn6Bits       ;Compare our repeat count to the max that can be represented in 6 bits
            jle     SkipSet63

            mov     ebx, MaxNumberIn6Bits       ;If our repeat count is greater than max representable (63) then only represent 63

SkipSet63:
			sub		edx, ebx					;Subtract what we are representing in 6 bits from the total to be represented
			or		bl,	 OnlyBits6And7			;Set the 6th and 7th bit so we know bits 0-5 represent a repeat count

			mov		[edi], bl					;Move into the output buffer our repeat count
			inc		edi							;Increment index into the output buffer
            inc     BytesWritten                ;Increment the number of bytes written

			mov		bl, CurrentByte				;Move the current byte into a register
			mov		[edi], bl					;Move the actual byte value into the output buffer
			inc		edi							;Increment the index into the output buffer
            inc     BytesWritten                ;Increment the number of bytes written

            cmp     edx, ZeroState              ;Check to see if we have represented all the bytes
            jg      ComplicatedEncoding         ;If there are more bytes to represent, represent them
			
	DoneEncoding:
			cmp		ecx, eax				    ;Compare our index (ecx) to the upper bound of our loop (eax)
			jle		LoopStart					;If our index is at or before the upper bound, then we repeat the scanning

            mov     eax, BytesWritten           ;Move the number of bytes written into the output register (eax)

            ret
_RLE_Encode EndP						;End of the encoding procedure


        END