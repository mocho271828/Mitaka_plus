
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  4c8b30: c2 00 b8                     	ret	-0x4800
  4c8b33: 00 00                        	add	byte ptr [eax], al
  4c8b35: 80 bf 50 50 ff 15 f4         	cmp	byte ptr [edi + 0x15ff5050], -0xc
  4c8b3c: 59                           	pop	ecx
  4c8b3d: c2 00 68                     	ret	0x6800
  4c8b40: 37                           	aaa
  4c8b41: 80 00 00                     	add	byte ptr [eax], 0x0
  4c8b44: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  4c8b4a: 0f be 15 28 1e d7 00         	movsx	edx, byte ptr [0xd71e28]
  4c8b51: f6 c2 04                     	test	dl, 0x4
  4c8b54: 0f 85 bf 0a 00 00            	jne	0x4c9619 <.text+0xc8619>
  4c8b5a: f2 0f 10 5c 24 50            	movsd	xmm3, qword ptr [esp + 0x50]
  4c8b60: 8b 45 0c                     	mov	eax, dword ptr [ebp + 0xc]
  4c8b63: f2 0f 10 2b                  	movsd	xmm5, qword ptr [ebx]
  4c8b67: f2 0f 5c 2e                  	subsd	xmm5, qword ptr [esi]
  4c8b6b: 0f 28 d5                     	movaps	xmm2, xmm5
  4c8b6e: f2 0f 59 d5                  	mulsd	xmm2, xmm5
  4c8b72: f2 0f 10 4b 08               	movsd	xmm1, qword ptr [ebx + 0x8]
  4c8b77: f2 0f 5c 4e 08               	subsd	xmm1, qword ptr [esi + 0x8]
  4c8b7c: 0f 28 f9                     	movaps	xmm7, xmm1
  4c8b7f: f2 0f 59 f9                  	mulsd	xmm7, xmm1
  4c8b83: f2 0f 10 73 10               	movsd	xmm6, qword ptr [ebx + 0x10]
  4c8b88: f2 0f 5c 76 10               	subsd	xmm6, qword ptr [esi + 0x10]
  4c8b8d: f2 0f 10 27                  	movsd	xmm4, qword ptr [edi]


/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  4c9aa0: 10 51 ff                     	adc	byte ptr [ecx - 0x1], dl
  4c9aa3: 15 f8 59 c2 00               	adc	eax, 0xc259f8
  4c9aa8: 4b                           	dec	ebx
  4c9aa9: 0f 8d db fc ff ff            	jge	0x4c978a <.text+0xc878a>
  4c9aaf: 8b 5d 14                     	mov	ebx, dword ptr [ebp + 0x14]
  4c9ab2: 8b 7d 18                     	mov	edi, dword ptr [ebp + 0x18]
  4c9ab5: 8b 75 1c                     	mov	esi, dword ptr [ebp + 0x1c]
  4c9ab8: ff 15 e4 58 c2 00            	call	dword ptr [0xc258e4]
  4c9abe: 0f be 15 28 1e d7 00         	movsx	edx, byte ptr [0xd71e28]
  4c9ac5: e9 90 f0 ff ff               	jmp	0x4c8b5a <.text+0xc7b5a>
  4c9aca: 83 c4 f0                     	add	esp, -0x10
  4c9acd: c7 04 24 00 00 80 3f         	mov	dword ptr [esp], 0x3f800000
  4c9ad4: 33 c0                        	xor	eax, eax
  4c9ad6: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  4c9ada: c7 44 24 0c 00 00 00 3f      	mov	dword ptr [esp + 0xc], 0x3f000000
  4c9ae2: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  4c9ae6: ff 15 70 59 c2 00            	call	dword ptr [0xc25970]
  4c9aec: 6a 06                        	push	0x6
  4c9aee: ff 15 d4 58 c2 00            	call	dword ptr [0xc258d4]
  4c9af4: 8b 45 0c                     	mov	eax, dword ptr [ebp + 0xc]
  4c9af7: f2 0f 10 ac 24 b0 00 00 00   	movsd	xmm5, qword ptr [esp + 0xb0]
  4c9b00: f2 0f 5c 28                  	subsd	xmm5, qword ptr [eax]
  4c9b04: f2 0f 10 94 24 a8 00 00 00   	movsd	xmm2, qword ptr [esp + 0xa8]
  4c9b0d: f2 0f 5c 50 08               	subsd	xmm2, qword ptr [eax + 0x8]
  4c9b12: f2 0f 10 9c 24 b8 00 00 00   	movsd	xmm3, qword ptr [esp + 0xb8]
  4c9b1b: f2 0f 5c 58 10               	subsd	xmm3, qword ptr [eax + 0x10]
  4c9b20: 8b 55 24                     	mov	edx, dword ptr [ebp + 0x24]
  4c9b23: 8b 4d 10                     	mov	ecx, dword ptr [ebp + 0x10]
  4c9b26: 8d 44 24 30                  	lea	eax, [esp + 0x30]
  4c9b2a: f2 0f 10 22                  	movsd	xmm4, qword ptr [edx]
  4c9b2e: f2 0f 59 e5                  	mulsd	xmm4, xmm5
  4c9b32: f2 0f 10 72 08               	movsd	xmm6, qword ptr [edx + 0x8]
  4c9b37: f2 0f 59 f2                  	mulsd	xmm6, xmm2
  4c9b3b: f2 0f 10 7a 10               	movsd	xmm7, qword ptr [edx + 0x10]
  4c9b40: f2 0f 59 fb                  	mulsd	xmm7, xmm3
  4c9b44: f2 0f 10 4a 18               	movsd	xmm1, qword ptr [edx + 0x18]
  4c9b49: f2 0f 59 cd                  	mulsd	xmm1, xmm5
  4c9b4d: f2 0f 10 42 20               	movsd	xmm0, qword ptr [edx + 0x20]
  4c9b52: f2 0f 59 c2                  	mulsd	xmm0, xmm2
  4c9b56: f2 0f 58 e6                  	addsd	xmm4, xmm6
  4c9b5a: f2 0f 10 72 28               	movsd	xmm6, qword ptr [edx + 0x28]
  4c9b5f: f2 0f 59 f3                  	mulsd	xmm6, xmm3


/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  4c9d80: 00 52 ff                     	add	byte ptr [edx - 0x1], dl
  4c9d83: 15 f8 59 c2 00               	adc	eax, 0xc259f8
  4c9d88: 4b                           	dec	ebx
  4c9d89: 0f 8d 5c fe ff ff            	jge	0x4c9beb <.text+0xc8beb>
  4c9d8f: 8b 5d 14                     	mov	ebx, dword ptr [ebp + 0x14]
  4c9d92: 8b 7d 18                     	mov	edi, dword ptr [ebp + 0x18]
  4c9d95: ff 15 e4 58 c2 00            	call	dword ptr [0xc258e4]
  4c9d9b: 0f be 15 28 1e d7 00         	movsx	edx, byte ptr [0xd71e28]
  4c9da2: e9 b3 ed ff ff               	jmp	0x4c8b5a <.text+0xc7b5a>
  4c9da7: 8b f6                        	mov	esi, esi
  4c9da9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  4c9db0: 53                           	push	ebx
  4c9db1: 8b dc                        	mov	ebx, esp
  4c9db3: 83 e4 f0                     	and	esp, -0x10
  4c9db6: 55                           	push	ebp
  4c9db7: 55                           	push	ebp
  4c9db8: 8b 6b 04                     	mov	ebp, dword ptr [ebx + 0x4]
  4c9dbb: 89 6c 24 04                  	mov	dword ptr [esp + 0x4], ebp
  4c9dbf: 8b ec                        	mov	ebp, esp
  4c9dc1: 6a ff                        	push	-0x1
  4c9dc3: 68 e0 b1 4c 00               	push	0x4cb1e0
  4c9dc8: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  4c9dce: 50                           	push	eax
  4c9dcf: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  4c9dd6: 81 ec 1c 03 00 00            	sub	esp, 0x31c
  4c9ddc: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  4c9ddf: 89 7d e0                     	mov	dword ptr [ebp - 0x20], edi
  4c9de2: 89 75 e4                     	mov	dword ptr [ebp - 0x1c], esi
  4c9de5: 0f b6 05 00 bb 02 01         	movzx	eax, byte ptr [0x102bb00]
  4c9dec: a8 01                        	test	al, 0x1
  4c9dee: 75 08                        	jne	0x4c9df8 <.text+0xc8df8>


/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  518fe0: 59                           	pop	ecx
  518fe1: 54                           	push	esp
  518fe2: 24 48                        	and	al, 0x48
  518fe4: f2 0f 59 d0                  	mulsd	xmm2, xmm0
  518fe8: eb 18                        	jmp	0x519002 <.text+0x118002>
  518fea: f3 0f 10 0d 24 1c 08 01      	movss	xmm1, dword ptr [0x1081c24]
  518ff2: f3 0f 10 05 a8 12 c3 00      	movss	xmm0, dword ptr [0xc312a8]
  518ffa: f3 0f 59 c8                  	mulss	xmm1, xmm0
  518ffe: f3 0f 5a d1                  	cvtss2sd	xmm2, xmm1
  519002: f6 05 28 1e d7 00 0c         	test	byte ptr [0xd71e28], 0xc
  519009: 74 09                        	je	0x519014 <.text+0x118014>
  51900b: 83 3b 02                     	cmp	dword ptr [ebx], 0x2
  51900e: 0f 84 68 02 00 00            	je	0x51927c <.text+0x11827c>
  519014: f2 0f 59 94 24 50 01 00 00   	mulsd	xmm2, qword ptr [esp + 0x150]
  51901d: 8b 94 24 60 01 00 00         	mov	edx, dword ptr [esp + 0x160]
  519024: f2 0f 10 5a 08               	movsd	xmm3, qword ptr [edx + 0x8]
  519029: f2 0f 59 9c 24 38 01 00 00   	mulsd	xmm3, qword ptr [esp + 0x138]
  519032: f2 0f 10 4a 10               	movsd	xmm1, qword ptr [edx + 0x10]
  519037: f2 0f 59 8c 24 40 01 00 00   	mulsd	xmm1, qword ptr [esp + 0x140]


/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  542e60: 01 e8                        	add	eax, ebp
  542e62: ea b7 ff ff 8b c8 e8         	ljmp	-0x1738, 0x8bffffb7
  542e69: 23 99 ff ff dd 9c            	and	ebx, dword ptr [ecx - 0x63220001]
  542e6f: 24 90                        	and	al, -0x70
  542e71: 01 00                        	add	dword ptr [eax], eax
  542e73: 00 f2                        	add	dl, dh
  542e75: 0f 5a 84 24 90 01 00 00      	cvtps2pd	xmm0, qword ptr [esp + 0x190]
  542e7d: 0f b6 05 28 1e d7 00         	movzx	eax, byte ptr [0xd71e28]
  542e84: f3 0f 10 8c 24 a0 01 00 00   	movss	xmm1, dword ptr [esp + 0x1a0]
  542e8d: f3 0f 11 44 24 10            	movss	dword ptr [esp + 0x10], xmm0
  542e93: f3 0f 11 4c 24 2c            	movss	dword ptr [esp + 0x2c], xmm1
  542e99: 89 34 24                     	mov	dword ptr [esp], esi
  542e9c: 8d b4 24 e8 00 00 00         	lea	esi, [esp + 0xe8]
  542ea3: 89 74 24 04                  	mov	dword ptr [esp + 0x4], esi
  542ea7: 8d 94 24 78 01 00 00         	lea	edx, [esp + 0x178]
  542eae: 89 54 24 08                  	mov	dword ptr [esp + 0x8], edx


/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  543360: 8c 24 78                     	mov	word ptr [eax + 2*edi], fs
  543363: 01 00                        	add	dword ptr [eax], eax
  543365: 00 8b 55 08 d9 9c            	add	byte ptr [ebx - 0x6326f7ab], cl
  54336b: 24 98                        	and	al, -0x68
  54336d: 01 00                        	add	dword ptr [eax], eax
  54336f: 00 f3                        	add	bl, dh
  543371: 0f 10 84 24 98 01 00 00      	movups	xmm0, xmmword ptr [esp + 0x198]
  543379: f3 0f 5e c8                  	divss	xmm1, xmm0
  54337d: 0f b6 05 28 1e d7 00         	movzx	eax, byte ptr [0xd71e28]
  543384: f3 0f 11 4c 24 2c            	movss	dword ptr [esp + 0x2c], xmm1
  54338a: 89 14 24                     	mov	dword ptr [esp], edx
  54338d: 8d 94 24 e8 00 00 00         	lea	edx, [esp + 0xe8]
  543394: c7 44 24 10 00 00 00 00      	mov	dword ptr [esp + 0x10], 0x0
  54339c: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  5433a0: 8d 8c 24 80 01 00 00         	lea	ecx, [esp + 0x180]
  5433a7: 89 4c 24 08                  	mov	dword ptr [esp + 0x8], ecx
  5433ab: 89 7c 24 0c                  	mov	dword ptr [esp + 0xc], edi
  5433af: 8d bc 24 00 01 00 00         	lea	edi, [esp + 0x100]
  5433b6: 89 7c 24 14                  	mov	dword ptr [esp + 0x14], edi
  5433ba: 8d bc 24 88 01 00 00         	lea	edi, [esp + 0x188]


/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  549950: 58                           	pop	eax
  549951: c2 00 43                     	ret	0x4300
  549954: 83 fb 08                     	cmp	ebx, 0x8
  549957: 0f 8e 2e ff ff ff            	jle	0x54988b <.text+0x14888b>
  54995d: 8b 5c 24 08                  	mov	ebx, dword ptr [esp + 0x8]
  549961: ff 15 34 59 c2 00            	call	dword ptr [0xc25934]
  549967: 8b e5                        	mov	esp, ebp
  549969: 5d                           	pop	ebp
  54996a: c3                           	ret
  54996b: 90                           	nop
  54996c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  549970: 83 ec 18                     	sub	esp, 0x18
  549973: f6 05 28 1e d7 00 03         	test	byte ptr [0xd71e28], 0x3
  54997a: 75 04                        	jne	0x549980 <.text+0x148980>
  54997c: 83 c4 18                     	add	esp, 0x18
  54997f: c3                           	ret
  549980: 68 48 30 c3 00               	push	0xc33048
  549985: b9 60 74 10 01               	mov	ecx, 0x1107460
  54998a: e8 51 1d 01 00               	call	0x55b6e0 <.text+0x15a6e0>
  54998f: 89 04 24                     	mov	dword ptr [esp], eax
  549992: 68 4c 30 c3 00               	push	0xc3304c
  549997: b9 60 74 10 01               	mov	ecx, 0x1107460
  54999c: e8 3f 1d 01 00               	call	0x55b6e0 <.text+0x15a6e0>
  5499a1: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  5499a5: 68 54 30 c3 00               	push	0xc33054
  5499aa: b9 60 74 10 01               	mov	ecx, 0x1107460
  5499af: e8 2c 1d 01 00               	call	0x55b6e0 <.text+0x15a6e0>


/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  54a730: c1 f3                        	<unknown>
  54a732: 0f 11 4c 24 64               	movups	xmmword ptr [esp + 0x64], xmm1
  54a737: 73 8b                        	jae	0x54a6c4 <.text+0x1496c4>
  54a739: ff 15 e4 58 c2 00            	call	dword ptr [0xc258e4]
  54a73f: 47                           	inc	edi
  54a740: 83 ff 08                     	cmp	edi, 0x8
  54a743: 0f 8e 24 ff ff ff            	jle	0x54a66d <.text+0x14966d>
  54a749: 8b 7c 24 60                  	mov	edi, dword ptr [esp + 0x60]
  54a74d: ff 15 34 59 c2 00            	call	dword ptr [0xc25934]
  54a753: f6 05 28 1e d7 00 03         	test	byte ptr [0xd71e28], 0x3
  54a75a: 74 72                        	je	0x54a7ce <.text+0x1497ce>
  54a75c: 68 f0 e1 c2 00               	push	0xc2e1f0
  54a761: b9 60 74 10 01               	mov	ecx, 0x1107460
  54a766: e8 75 0f 01 00               	call	0x55b6e0 <.text+0x15a6e0>
  54a76b: 3b f0                        	cmp	esi, eax
  54a76d: 75 5f                        	jne	0x54a7ce <.text+0x1497ce>
  54a76f: ff 15 04 59 c2 00            	call	dword ptr [0xc25904]
  54a775: 83 c4 f4                     	add	esp, -0xc
  54a778: f3 0f 10 84 24 ec 00 00 00   	movss	xmm0, dword ptr [esp + 0xec]
  54a781: f3 0f 11 04 24               	movss	dword ptr [esp], xmm0
  54a786: f3 0f 11 44 24 04            	movss	dword ptr [esp + 0x4], xmm0
  54a78c: f3 0f 11 44 24 08            	movss	dword ptr [esp + 0x8], xmm0
  54a792: ff 15 50 59 c2 00            	call	dword ptr [0xc25950]
  54a798: 68 f0 e1 c2 00               	push	0xc2e1f0
  54a79d: b9 60 74 10 01               	mov	ecx, 0x1107460


/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  54cc00: 04 e8                        	add	al, -0x18
  54cc02: 2a 03                        	sub	al, byte ptr [ebx]
  54cc04: ef                           	out	dx, eax
  54cc05: ff 83 c4 08 ff 15            	inc	dword ptr [ebx + 0x15ff08c4]
  54cc0b: 08 59 c2                     	or	byte ptr [ecx - 0x3e], bl
  54cc0e: 00 68 68                     	add	byte ptr [eax + 0x68], ch
  54cc11: 30 c3                        	xor	bl, al
  54cc13: 00 b9 e0 70 10 01            	add	byte ptr [ecx + 0x11070e0], bh
  54cc19: e8 02 0f ff ff               	call	0x53db20 <.text+0x13cb20>
  54cc1e: 3b 43 0c                     	cmp	eax, dword ptr [ebx + 0xc]
  54cc21: 0f 85 9b 00 00 00            	jne	0x54ccc2 <.text+0x14bcc2>
  54cc27: f6 05 28 1e d7 00 03         	test	byte ptr [0xd71e28], 0x3
  54cc2e: 0f 84 8e 00 00 00            	je	0x54ccc2 <.text+0x14bcc2>
  54cc34: 68 48 30 c3 00               	push	0xc33048
  54cc39: b9 60 74 10 01               	mov	ecx, 0x1107460
  54cc3e: e8 9d ea 00 00               	call	0x55b6e0 <.text+0x15a6e0>
  54cc43: 68 4c 30 c3 00               	push	0xc3304c
  54cc48: 89 45 88                     	mov	dword ptr [ebp - 0x78], eax
  54cc4b: b9 60 74 10 01               	mov	ecx, 0x1107460
  54cc50: e8 8b ea 00 00               	call	0x55b6e0 <.text+0x15a6e0>
  54cc55: 68 54 30 c3 00               	push	0xc33054
  54cc5a: 89 45 8c                     	mov	dword ptr [ebp - 0x74], eax
  54cc5d: b9 60 74 10 01               	mov	ecx, 0x1107460
  54cc62: e8 79 ea 00 00               	call	0x55b6e0 <.text+0x15a6e0>
  54cc67: 68 60 30 c3 00               	push	0xc33060
  54cc6c: 89 45 90                     	mov	dword ptr [ebp - 0x70], eax
  54cc6f: b9 60 74 10 01               	mov	ecx, 0x1107460


/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  54dfb0: c2 00 68                     	ret	0x6800
  54dfb3: 03 03                        	add	eax, dword ptr [ebx]
  54dfb5: 00 00                        	add	byte ptr [eax], al
  54dfb7: 68 02 03 00 00               	push	0x302
  54dfbc: ff 15 78 59 c2 00            	call	dword ptr [0xc25978]
  54dfc2: 6a 01                        	push	0x1
  54dfc4: ff 15 c8 59 c2 00            	call	dword ptr [0xc259c8]
  54dfca: 0f be 05 28 1e d7 00         	movsx	eax, byte ptr [0xd71e28]
  54dfd1: a8 03                        	test	al, 0x3
  54dfd3: 74 47                        	je	0x54e01c <.text+0x14d01c>
  54dfd5: 68 c0 d5 c2 00               	push	0xc2d5c0
  54dfda: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  54dfdf: e8 3c fb fe ff               	call	0x53db20 <.text+0x13cb20>
  54dfe4: 89 85 ec fe ff ff            	mov	dword ptr [ebp - 0x114], eax
  54dfea: 68 f0 e1 c2 00               	push	0xc2e1f0
  54dfef: b9 60 74 10 01               	mov	ecx, 0x1107460
  54dff4: e8 e7 d6 00 00               	call	0x55b6e0 <.text+0x15a6e0>
  54dff9: 8b 95 ec fe ff ff            	mov	edx, dword ptr [ebp - 0x114]
  54dfff: 83 c4 f4                     	add	esp, -0xc
  54e002: 89 3c 24                     	mov	dword ptr [esp], edi
  54e005: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  54e009: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  54e00d: e8 ae 4b ff ff               	call	0x542bc0 <.text+0x141bc0>
  54e012: 83 c4 0c                     	add	esp, 0xc
  54e015: 0f be 05 28 1e d7 00         	movsx	eax, byte ptr [0xd71e28]
  54e01c: a8 0c                        	test	al, 0xc
  54e01e: 74 40                        	je	0x54e060 <.text+0x14d060>
  54e020: 68 c0 d5 c2 00               	push	0xc2d5c0
  54e025: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  54e02a: e8 f1 fa fe ff               	call	0x53db20 <.text+0x13cb20>
  54e02f: 89 85 ec fe ff ff            	mov	dword ptr [ebp - 0x114], eax
  54e035: 68 f0 e1 c2 00               	push	0xc2e1f0
  54e03a: b9 60 74 10 01               	mov	ecx, 0x1107460
  54e03f: e8 9c d6 00 00               	call	0x55b6e0 <.text+0x15a6e0>
  54e044: 8b 95 ec fe ff ff            	mov	edx, dword ptr [ebp - 0x114]
  54e04a: 83 c4 f4                     	add	esp, -0xc
  54e04d: 89 3c 24                     	mov	dword ptr [esp], edi
  54e050: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  54e054: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  54e058: e8 d3 4e ff ff               	call	0x542f30 <.text+0x141f30>
  54e05d: 83 c4 0c                     	add	esp, 0xc


/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5511c0: 59                           	pop	ecx
  5511c1: c2 00 68                     	ret	0x6800
  5511c4: e1 0d                        	loope	0x5511d3 <.text+0x1501d3>
  5511c6: 00 00                        	add	byte ptr [eax], al
  5511c8: ff 15 18 59 c2 00            	call	dword ptr [0xc25918]
  5511ce: 68 e2 0b 00 00               	push	0xbe2
  5511d3: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  5511d9: f6 05 28 1e d7 00 03         	test	byte ptr [0xd71e28], 0x3
  5511e0: 74 45                        	je	0x551227 <.text+0x150227>
  5511e2: ff 15 04 59 c2 00            	call	dword ptr [0xc25904]
  5511e8: 68 f0 e1 c2 00               	push	0xc2e1f0
  5511ed: b9 60 74 10 01               	mov	ecx, 0x1107460
  5511f2: e8 e9 a4 00 00               	call	0x55b6e0 <.text+0x15a6e0>
  5511f7: 8b f0                        	mov	esi, eax
  5511f9: 68 c0 d5 c2 00               	push	0xc2d5c0
  5511fe: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  551203: e8 18 c9 fe ff               	call	0x53db20 <.text+0x13cb20>
  551208: 8b 53 08                     	mov	edx, dword ptr [ebx + 0x8]
  55120b: 83 c4 f4                     	add	esp, -0xc
  55120e: 89 14 24                     	mov	dword ptr [esp], edx
