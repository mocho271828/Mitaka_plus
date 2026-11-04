
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  7c18e0: 57                           	push	edi
  7c18e1: 8b f9                        	mov	edi, ecx
  7c18e3: ff 77 1c                     	push	dword ptr [edi + 0x1c]
  7c18e6: c7 07 68 09 38 01            	mov	dword ptr [edi], 0x1380968
  7c18ec: e8 a1 d6 2c 00               	call	0xa8ef92 <.text+0x68df92>
  7c18f1: 59                           	pop	ecx
  7c18f2: f6 44 24 08 01               	test	byte ptr [esp + 0x8], 0x1
  7c18f7: 75 06                        	jne	0x7c18ff <.text+0x3c08ff>
  7c18f9: 8b c7                        	mov	eax, edi
  7c18fb: 5f                           	pop	edi
  7c18fc: c2 04 00                     	ret	0x4
  7c18ff: 57                           	push	edi
  7c1900: e8 8d d6 2c 00               	call	0xa8ef92 <.text+0x68df92>
  7c1905: 59                           	pop	ecx
  7c1906: eb f1                        	jmp	0x7c18f9 <.text+0x3c08f9>
  7c1908: 90                           	nop
  7c1909: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  7c1910: f2 0f 10 05 60 c7 cb 00      	movsd	xmm0, qword ptr [0xcbc760]
  7c1918: f2 0f 11 41 08               	movsd	qword ptr [ecx + 0x8], xmm0
  7c191d: 33 d2                        	xor	edx, edx
  7c191f: 89 51 18                     	mov	dword ptr [ecx + 0x18], edx
  7c1922: c7 01 68 09 38 01            	mov	dword ptr [ecx], 0x1380968
  7c1928: 89 51 1c                     	mov	dword ptr [ecx + 0x1c], edx
  7c192b: 88 51 20                     	mov	byte ptr [ecx + 0x20], dl
  7c192e: 8b c1                        	mov	eax, ecx
  7c1930: c3                           	ret
  7c1931: 90                           	nop
  7c1932: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  7c1939: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7c1940: ff 71 1c                     	push	dword ptr [ecx + 0x1c]
  7c1943: c7 01 68 09 38 01            	mov	dword ptr [ecx], 0x1380968
  7c1949: e8 44 d6 2c 00               	call	0xa8ef92 <.text+0x68df92>
  7c194e: 59                           	pop	ecx
  7c194f: c3                           	ret
  7c1950: c2 08 00                     	ret	0x8
  7c1953: 8d b6 00 00 00 00            	lea	esi, [esi]
  7c1959: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7c1960: c6 41 20 01                  	mov	byte ptr [ecx + 0x20], 0x1
  7c1964: c3                           	ret
  7c1965: 8d 74 26 00                  	lea	esi, [esi + eiz]
  7c1969: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7c1970: 8b 44 24 04                  	mov	eax, dword ptr [esp + 0x4]
  7c1974: 89 41 18                     	mov	dword ptr [ecx + 0x18], eax
  7c1977: c2 04 00                     	ret	0x4
  7c197a: 8d b6 00 00 00 00            	lea	esi, [esi]
  7c1980: 8b 41 18                     	mov	eax, dword ptr [ecx + 0x18]
  7c1983: c3                           	ret
  7c1984: 8d b6 00 00 00 00            	lea	esi, [esi]
  7c198a: 8d bf 00 00 00 00            	lea	edi, [edi]
  7c1990: 55                           	push	ebp
  7c1991: 8b ec                        	mov	ebp, esp
  7c1993: 83 e4 f8                     	and	esp, -0x8
  7c1996: 56                           	push	esi
  7c1997: 83 ec 0c                     	sub	esp, 0xc
  7c199a: 8b f1                        	mov	esi, ecx
  7c199c: d9 ee                        	fldz
  7c199e: dd 46 08                     	fld	qword ptr [esi + 0x8]
  7c19a1: dd e1                        	fucom	st(1)
  7c19a3: df e0                        	fnstsw	ax
  7c19a5: dd 1c 24                     	fstp	qword ptr [esp]
  7c19a8: 9e                           	sahf
  7c19a9: 7a 06                        	jp	0x7c19b1 <.text+0x3c09b1>
  7c19ab: 0f 84 bd 00 00 00            	je	0x7c1a6e <.text+0x3c0a6e>
  7c19b1: dd 45 08                     	fld	qword ptr [ebp + 0x8]
  7c19b4: dc 66 10                     	fsub	qword ptr [esi + 0x10]
  7c19b7: 8b 46 18                     	mov	eax, dword ptr [esi + 0x18]
  7c19ba: 85 c0                        	test	eax, eax
  7c19bc: 74 61                        	je	0x7c1a1f <.text+0x3c0a1f>
  7c19be: dd d9                        	fstp	st(1)
  7c19c0: 83 f8 01                     	cmp	eax, 0x1
  7c19c3: 75 1b                        	jne	0x7c19e0 <.text+0x3c09e0>
  7c19c5: dd 04 24                     	fld	qword ptr [esp]
  7c19c8: d9 c9                        	fxch	st(1)
  7c19ca: d9 f8                        	fprem
  7c19cc: df e0                        	fnstsw	ax
  7c19ce: 9e                           	sahf
  7c19cf: 7a f9                        	jp	0x7c19ca <.text+0x3c09ca>
  7c19d1: dd d9                        	fstp	st(1)
  7c19d3: dc 34 24                     	fdiv	qword ptr [esp]
  7c19d6: 83 c4 0c                     	add	esp, 0xc
  7c19d9: 5e                           	pop	esi
  7c19da: 8b e5                        	mov	esp, ebp
  7c19dc: 5d                           	pop	ebp
  7c19dd: c2 08 00                     	ret	0x8
  7c19e0: 83 f8 02                     	cmp	eax, 0x2
  7c19e3: 75 20                        	jne	0x7c1a05 <.text+0x3c0a05>
  7c19e5: dd 04 24                     	fld	qword ptr [esp]
  7c19e8: dc 0d 68 c7 cb 00            	fmul	qword ptr [0xcbc768]
  7c19ee: d9 c9                        	fxch	st(1)
  7c19f0: d9 f8                        	fprem
  7c19f2: df e0                        	fnstsw	ax
  7c19f4: 9e                           	sahf
  7c19f5: 7a f9                        	jp	0x7c19f0 <.text+0x3c09f0>
  7c19f7: dd d9                        	fstp	st(1)
  7c19f9: dc 34 24                     	fdiv	qword ptr [esp]
  7c19fc: d9 e8                        	fld1
  7c19fe: d8 d9                        	fcomp	st(1)
  7c1a00: df e0                        	fnstsw	ax
  7c1a02: 9e                           	sahf
  7c1a03: 76 0a                        	jbe	0x7c1a0f <.text+0x3c0a0f>
  7c1a05: 83 c4 0c                     	add	esp, 0xc
  7c1a08: 5e                           	pop	esi
  7c1a09: 8b e5                        	mov	esp, ebp
  7c1a0b: 5d                           	pop	ebp
  7c1a0c: c2 08 00                     	ret	0x8
  7c1a0f: dc 2d 68 c7 cb 00            	fsubr	qword ptr [0xcbc768]
  7c1a15: 83 c4 0c                     	add	esp, 0xc
  7c1a18: 5e                           	pop	esi
  7c1a19: 8b e5                        	mov	esp, ebp
  7c1a1b: 5d                           	pop	ebp
  7c1a1c: c2 08 00                     	ret	0x8
  7c1a1f: d8 d1                        	fcom	st(1)
  7c1a21: df e0                        	fnstsw	ax
  7c1a23: 9e                           	sahf
  7c1a24: 7a 02                        	jp	0x7c1a28 <.text+0x3c0a28>
  7c1a26: 72 3a                        	jb	0x7c1a62 <.text+0x3c0a62>
  7c1a28: dd d9                        	fstp	st(1)
  7c1a2a: dc 14 24                     	fcom	qword ptr [esp]
  7c1a2d: df e0                        	fnstsw	ax
  7c1a2f: 9e                           	sahf
  7c1a30: 76 23                        	jbe	0x7c1a55 <.text+0x3c0a55>
  7c1a32: dd d8                        	fstp	st(0)
  7c1a34: e8 c7 bd ff ff               	call	0x7bd800 <.text+0x3bc800>
  7c1a39: 6a 00                        	push	0x0
  7c1a3b: ff 76 1c                     	push	dword ptr [esi + 0x1c]
  7c1a3e: 8b c8                        	mov	ecx, eax
  7c1a40: e8 2b cb ff ff               	call	0x7be570 <.text+0x3bd570>
  7c1a45: d9 05 70 c7 cb 00            	fld	dword ptr [0xcbc770]
  7c1a4b: 83 c4 0c                     	add	esp, 0xc
  7c1a4e: 5e                           	pop	esi
  7c1a4f: 8b e5                        	mov	esp, ebp
  7c1a51: 5d                           	pop	ebp
  7c1a52: c2 08 00                     	ret	0x8
  7c1a55: dc 34 24                     	fdiv	qword ptr [esp]
  7c1a58: 83 c4 0c                     	add	esp, 0xc
  7c1a5b: 5e                           	pop	esi
  7c1a5c: 8b e5                        	mov	esp, ebp
  7c1a5e: 5d                           	pop	ebp
  7c1a5f: c2 08 00                     	ret	0x8
  7c1a62: dd d8                        	fstp	st(0)
  7c1a64: 83 c4 0c                     	add	esp, 0xc
  7c1a67: 5e                           	pop	esi
  7c1a68: 8b e5                        	mov	esp, ebp
  7c1a6a: 5d                           	pop	ebp
  7c1a6b: c2 08 00                     	ret	0x8
  7c1a6e: dd d8                        	fstp	st(0)
  7c1a70: d9 05 70 c7 cb 00            	fld	dword ptr [0xcbc770]
  7c1a76: 83 c4 0c                     	add	esp, 0xc
  7c1a79: 5e                           	pop	esi
  7c1a7a: 8b e5                        	mov	esp, ebp
  7c1a7c: 5d                           	pop	ebp
  7c1a7d: c2 08 00                     	ret	0x8
  7c1a80: 55                           	push	ebp
  7c1a81: 8b e9                        	mov	ebp, ecx
  7c1a83: 8b 44 24 08                  	mov	eax, dword ptr [esp + 0x8]
  7c1a87: 89 45 1c                     	mov	dword ptr [ebp + 0x1c], eax
  7c1a8a: e8 71 bd ff ff               	call	0x7bd800 <.text+0x3bc800>
  7c1a8f: 8b c8                        	mov	ecx, eax
  7c1a91: e8 8a ce ff ff               	call	0x7be920 <.text+0x3bd920>
  7c1a96: dd 5d 10                     	fstp	qword ptr [ebp + 0x10]
  7c1a99: c6 45 20 00                  	mov	byte ptr [ebp + 0x20], 0x0
  7c1a9d: e8 5e bd ff ff               	call	0x7bd800 <.text+0x3bc800>
  7c1aa2: 55                           	push	ebp
  7c1aa3: 8b c8                        	mov	ecx, eax
  7c1aa5: e8 26 bf ff ff               	call	0x7bd9d0 <.text+0x3bc9d0>
  7c1aaa: 5d                           	pop	ebp
  7c1aab: c2 04 00                     	ret	0x4
  7c1aae: 8b f6                        	mov	esi, esi
  7c1ab0: 55                           	push	ebp
  7c1ab1: 8b ec                        	mov	ebp, esp
  7c1ab3: 83 e4 c0                     	and	esp, -0x40
  7c1ab6: 83 ec 40                     	sub	esp, 0x40
  7c1ab9: 8b 41 04                     	mov	eax, dword ptr [ecx + 0x4]
  7c1abc: 85 c0                        	test	eax, eax
  7c1abe: 74 43                        	je	0x7c1b03 <.text+0x3c0b03>
  7c1ac0: f2 0f 10 45 08               	movsd	xmm0, qword ptr [ebp + 0x8]
  7c1ac5: f2 0f 5a c8                  	cvtsd2ss	xmm1, xmm0
  7c1ac9: f2 0f 10 55 10               	movsd	xmm2, qword ptr [ebp + 0x10]
  7c1ace: f2 0f 10 65 18               	movsd	xmm4, qword ptr [ebp + 0x18]
  7c1ad3: f2 0f 10 75 20               	movsd	xmm6, qword ptr [ebp + 0x20]
  7c1ad8: f2 0f 5a da                  	cvtsd2ss	xmm3, xmm2
  7c1adc: f2 0f 5a ec                  	cvtsd2ss	xmm5, xmm4
  7c1ae0: f2 0f 5a fe                  	cvtsd2ss	xmm7, xmm6
  7c1ae4: f3 0f 11 0c 24               	movss	dword ptr [esp], xmm1
  7c1ae9: f3 0f 11 5c 24 04            	movss	dword ptr [esp + 0x4], xmm3
  7c1aef: f3 0f 11 6c 24 08            	movss	dword ptr [esp + 0x8], xmm5
  7c1af5: f3 0f 11 7c 24 0c            	movss	dword ptr [esp + 0xc], xmm7
  7c1afb: ff d0                        	call	eax
  7c1afd: 8b e5                        	mov	esp, ebp
  7c1aff: 5d                           	pop	ebp
  7c1b00: c2 20 00                     	ret	0x20
  7c1b03: 8b 41 08                     	mov	eax, dword ptr [ecx + 0x8]
  7c1b06: 85 c0                        	test	eax, eax
  7c1b08: 74 2d                        	je	0x7c1b37 <.text+0x3c0b37>
  7c1b0a: f2 0f 10 45 08               	movsd	xmm0, qword ptr [ebp + 0x8]
  7c1b0f: f2 0f 10 4d 10               	movsd	xmm1, qword ptr [ebp + 0x10]
  7c1b14: f2 0f 10 55 18               	movsd	xmm2, qword ptr [ebp + 0x18]
  7c1b19: f2 0f 10 5d 20               	movsd	xmm3, qword ptr [ebp + 0x20]
  7c1b1e: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  7c1b23: f2 0f 11 4c 24 08            	movsd	qword ptr [esp + 0x8], xmm1
  7c1b29: f2 0f 11 54 24 10            	movsd	qword ptr [esp + 0x10], xmm2
  7c1b2f: f2 0f 11 5c 24 18            	movsd	qword ptr [esp + 0x18], xmm3
  7c1b35: ff d0                        	call	eax
  7c1b37: 8b e5                        	mov	esp, ebp
  7c1b39: 5d                           	pop	ebp
  7c1b3a: c2 20 00                     	ret	0x20
  7c1b3d: 8d 76 00                     	lea	esi, [esi]
