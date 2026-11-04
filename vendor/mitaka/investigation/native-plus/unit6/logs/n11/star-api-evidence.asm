
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  661f00: 57                           	push	edi
  661f01: 56                           	push	esi
  661f02: 83 ec 20                     	sub	esp, 0x20
  661f05: 8b 7c 24 2c                  	mov	edi, dword ptr [esp + 0x2c]
  661f09: 6a 00                        	push	0x0
  661f0b: 6a 01                        	push	0x1
  661f0d: 57                           	push	edi
  661f0e: e8 5d d5 22 00               	call	0x88f470 <.text+0x48e470>
  661f13: 83 c4 0c                     	add	esp, 0xc
  661f16: 8b f0                        	mov	esi, eax
  661f18: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  661f20: 89 3c 24                     	mov	dword ptr [esp], edi
  661f23: 66 0f ef c0                  	pxor	xmm0, xmm0
  661f27: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  661f2d: e8 be d4 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  661f32: dd 5c 24 18                  	fstp	qword ptr [esp + 0x18]
  661f36: c7 44 24 04 03 00 00 00      	mov	dword ptr [esp + 0x4], 0x3
  661f3e: 89 3c 24                     	mov	dword ptr [esp], edi
  661f41: 66 0f ef c0                  	pxor	xmm0, xmm0
  661f45: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  661f4b: e8 a0 d4 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  661f50: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  661f54: 6a 01                        	push	0x1
  661f56: 6a 04                        	push	0x4
  661f58: 57                           	push	edi
  661f59: e8 a2 d5 22 00               	call	0x88f500 <.text+0x48e500>
  661f5e: 83 c4 0c                     	add	esp, 0xc
  661f61: 83 c4 f0                     	add	esp, -0x10
  661f64: dd 44 24 28                  	fld	qword ptr [esp + 0x28]
  661f68: dd 44 24 20                  	fld	qword ptr [esp + 0x20]
  661f6c: d9 c9                        	fxch	st(1)
  661f6e: d9 1c 24                     	fstp	dword ptr [esp]
  661f71: dd 5c 24 04                  	fstp	qword ptr [esp + 0x4]
  661f75: ba 01 00 00 00               	mov	edx, 0x1
  661f7a: 85 c0                        	test	eax, eax
  661f7c: 0f 45 c2                     	cmovne	eax, edx
  661f7f: 88 44 24 0c                  	mov	byte ptr [esp + 0xc], al
  661f83: 8b ce                        	mov	ecx, esi
  661f85: e8 96 40 f8 ff               	call	0x5e6020 <.text+0x1e5020>
  661f8a: 33 c0                        	xor	eax, eax
  661f8c: 83 c4 20                     	add	esp, 0x20
  661f8f: 5e                           	pop	esi
  661f90: 5f                           	pop	edi
  661f91: c3                           	ret
  661f92: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  661f99: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  661fa0: 55                           	push	ebp
  661fa1: 53                           	push	ebx
  661fa2: 83 ec 2c                     	sub	esp, 0x2c
  661fa5: 8b 5c 24 38                  	mov	ebx, dword ptr [esp + 0x38]
  661fa9: 8d 6c 24 10                  	lea	ebp, [esp + 0x10]
  661fad: 55                           	push	ebp
  661fae: 6a 00                        	push	0x0
  661fb0: 68 68 9f ca 00               	push	0xca9f68
  661fb5: 6a 01                        	push	0x1
  661fb7: 53                           	push	ebx
  661fb8: e8 e3 f3 22 00               	call	0x8913a0 <.text+0x4903a0>
  661fbd: 83 c4 14                     	add	esp, 0x14
  661fc0: 85 c0                        	test	eax, eax
  661fc2: 74 2b                        	je	0x661fef <.text+0x260fef>
  661fc4: 55                           	push	ebp
  661fc5: 6a 00                        	push	0x0
  661fc7: 68 b8 a0 c3 00               	push	0xc3a0b8
  661fcc: 6a 02                        	push	0x2
  661fce: 53                           	push	ebx
  661fcf: e8 cc f3 22 00               	call	0x8913a0 <.text+0x4903a0>
  661fd4: 83 c4 14                     	add	esp, 0x14
  661fd7: 85 c0                        	test	eax, eax
  661fd9: 74 14                        	je	0x661fef <.text+0x260fef>
  661fdb: 55                           	push	ebp
  661fdc: 6a 03                        	push	0x3
  661fde: 53                           	push	ebx
  661fdf: e8 bc f0 22 00               	call	0x8910a0 <.text+0x4900a0>
  661fe4: 83 c4 0c                     	add	esp, 0xc
  661fe7: 85 c0                        	test	eax, eax
  661fe9: 0f 85 89 00 00 00            	jne	0x662078 <.text+0x261078>
  661fef: 6a 00                        	push	0x0
  661ff1: 6a 01                        	push	0x1
  661ff3: 53                           	push	ebx
  661ff4: e8 77 d4 22 00               	call	0x88f470 <.text+0x48e470>
  661ff9: 83 c4 0c                     	add	esp, 0xc
  661ffc: 8b e8                        	mov	ebp, eax
  661ffe: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  662006: 89 1c 24                     	mov	dword ptr [esp], ebx
  662009: 66 0f ef c0                  	pxor	xmm0, xmm0
  66200d: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  662013: e8 d8 d3 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  662018: dd 5c 24 24                  	fstp	qword ptr [esp + 0x24]
  66201c: c7 44 24 04 03 00 00 00      	mov	dword ptr [esp + 0x4], 0x3
  662024: 89 1c 24                     	mov	dword ptr [esp], ebx
  662027: 66 0f ef c0                  	pxor	xmm0, xmm0
  66202b: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  662031: e8 ba d3 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  662036: dd 5c 24 1c                  	fstp	qword ptr [esp + 0x1c]
  66203a: 6a 01                        	push	0x1
  66203c: 6a 04                        	push	0x4
  66203e: 53                           	push	ebx
  66203f: e8 bc d4 22 00               	call	0x88f500 <.text+0x48e500>
  662044: 83 c4 0c                     	add	esp, 0xc
  662047: 83 c4 f0                     	add	esp, -0x10
  66204a: dd 44 24 34                  	fld	qword ptr [esp + 0x34]
  66204e: dd 44 24 2c                  	fld	qword ptr [esp + 0x2c]
  662052: d9 c9                        	fxch	st(1)
  662054: d9 1c 24                     	fstp	dword ptr [esp]
  662057: dd 5c 24 04                  	fstp	qword ptr [esp + 0x4]
  66205b: ba 01 00 00 00               	mov	edx, 0x1
  662060: 85 c0                        	test	eax, eax
  662062: 0f 45 c2                     	cmovne	eax, edx
  662065: 88 44 24 0c                  	mov	byte ptr [esp + 0xc], al
  662069: 8b cd                        	mov	ecx, ebp
  66206b: e8 b0 3f f8 ff               	call	0x5e6020 <.text+0x1e5020>
  662070: 33 c0                        	xor	eax, eax
  662072: 83 c4 2c                     	add	esp, 0x2c
  662075: 5b                           	pop	ebx
  662076: 5d                           	pop	ebp
  662077: c3                           	ret
  662078: 6a 00                        	push	0x0
  66207a: 6a 01                        	push	0x1
  66207c: 53                           	push	ebx
  66207d: e8 ee d3 22 00               	call	0x88f470 <.text+0x48e470>
  662082: 8b e8                        	mov	ebp, eax
  662084: 6a 00                        	push	0x0
  662086: 6a 02                        	push	0x2
  662088: 53                           	push	ebx
  662089: e8 e2 d3 22 00               	call	0x88f470 <.text+0x48e470>
  66208e: 83 c4 18                     	add	esp, 0x18
  662091: 50                           	push	eax
  662092: 8b cd                        	mov	ecx, ebp
  662094: e8 77 41 f8 ff               	call	0x5e6210 <.text+0x1e5210>
  662099: 33 c0                        	xor	eax, eax
  66209b: 83 c4 2c                     	add	esp, 0x2c
  66209e: 5b                           	pop	ebx
  66209f: 5d                           	pop	ebp
  6620a0: c3                           	ret
  6620a1: 90                           	nop
  6620a2: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  6620a9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  6620b0: 6a 00                        	push	0x0
  6620b2: 6a 01                        	push	0x1
  6620b4: ff 74 24 0c                  	push	dword ptr [esp + 0xc]
  6620b8: e8 b3 d3 22 00               	call	0x88f470 <.text+0x48e470>
  6620bd: 83 c4 0c                     	add	esp, 0xc
  6620c0: 8b c8                        	mov	ecx, eax
  6620c2: e8 09 42 f8 ff               	call	0x5e62d0 <.text+0x1e52d0>
  6620c7: 33 c0                        	xor	eax, eax
  6620c9: c3                           	ret
  6620ca: 8d b6 00 00 00 00            	lea	esi, [esi]
  6620d0: 6a 00                        	push	0x0
  6620d2: 6a 01                        	push	0x1
  6620d4: ff 74 24 0c                  	push	dword ptr [esp + 0xc]
  6620d8: e8 93 d3 22 00               	call	0x88f470 <.text+0x48e470>
  6620dd: 83 c4 0c                     	add	esp, 0xc
  6620e0: 8b c8                        	mov	ecx, eax
  6620e2: e8 19 42 f8 ff               	call	0x5e6300 <.text+0x1e5300>
  6620e7: 33 c0                        	xor	eax, eax
  6620e9: c3                           	ret
  6620ea: 8d b6 00 00 00 00            	lea	esi, [esi]
  6620f0: 57                           	push	edi
  6620f1: 56                           	push	esi
  6620f2: 83 ec 10                     	sub	esp, 0x10
  6620f5: 8b 74 24 1c                  	mov	esi, dword ptr [esp + 0x1c]
  6620f9: 6a 00                        	push	0x0
  6620fb: 6a 01                        	push	0x1
  6620fd: 56                           	push	esi
  6620fe: e8 6d d3 22 00               	call	0x88f470 <.text+0x48e470>

/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  662500: 53                           	push	ebx
  662501: 8b 5c 24 08                  	mov	ebx, dword ptr [esp + 0x8]
  662505: 6a 00                        	push	0x0
  662507: 6a 01                        	push	0x1
  662509: 53                           	push	ebx
  66250a: e8 61 cf 22 00               	call	0x88f470 <.text+0x48e470>
  66250f: 83 c4 0c                     	add	esp, 0xc
  662512: 8b c8                        	mov	ecx, eax
  662514: e8 57 24 f8 ff               	call	0x5e4970 <.text+0x1e3970>
  662519: 0f b6 c0                     	movzx	eax, al
  66251c: 50                           	push	eax
  66251d: 53                           	push	ebx
  66251e: e8 ed d2 22 00               	call	0x88f810 <.text+0x48e810>
  662523: 83 c4 08                     	add	esp, 0x8
  662526: b8 01 00 00 00               	mov	eax, 0x1
  66252b: 5b                           	pop	ebx
  66252c: c3                           	ret
  66252d: 8d 76 00                     	lea	esi, [esi]
  662530: 57                           	push	edi
  662531: 53                           	push	ebx
  662532: 8b 7c 24 0c                  	mov	edi, dword ptr [esp + 0xc]
  662536: 6a 00                        	push	0x0
  662538: 6a 01                        	push	0x1
  66253a: 57                           	push	edi
  66253b: e8 30 cf 22 00               	call	0x88f470 <.text+0x48e470>
  662540: 8b d8                        	mov	ebx, eax
  662542: 6a 00                        	push	0x0
  662544: 6a 02                        	push	0x2
  662546: 57                           	push	edi
  662547: e8 b4 cf 22 00               	call	0x88f500 <.text+0x48e500>
  66254c: 83 c4 18                     	add	esp, 0x18
  66254f: ba 01 00 00 00               	mov	edx, 0x1
  662554: 85 c0                        	test	eax, eax
  662556: 0f 45 c2                     	cmovne	eax, edx
  662559: 8b cb                        	mov	ecx, ebx
  66255b: 50                           	push	eax
  66255c: e8 ef 23 f8 ff               	call	0x5e4950 <.text+0x1e3950>
  662561: 33 c0                        	xor	eax, eax
  662563: 5b                           	pop	ebx
  662564: 5f                           	pop	edi
  662565: c3                           	ret
  662566: 8d 76 00                     	lea	esi, [esi]
  662569: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]

/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  662c30: 56                           	push	esi
  662c31: 83 ec 14                     	sub	esp, 0x14
  662c34: 8b 74 24 1c                  	mov	esi, dword ptr [esp + 0x1c]
  662c38: 6a 00                        	push	0x0
  662c3a: 6a 01                        	push	0x1
  662c3c: 56                           	push	esi
  662c3d: e8 2e c8 22 00               	call	0x88f470 <.text+0x48e470>
  662c42: 83 c4 0c                     	add	esp, 0xc
  662c45: 8b c8                        	mov	ecx, eax
  662c47: e8 a4 33 f8 ff               	call	0x5e5ff0 <.text+0x1e4ff0>
  662c4c: d9 5c 24 0c                  	fstp	dword ptr [esp + 0xc]
  662c50: f3 0f 10 44 24 0c            	movss	xmm0, dword ptr [esp + 0xc]
  662c56: f3 0f 5a c0                  	cvtss2sd	xmm0, xmm0
  662c5a: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  662c60: 89 34 24                     	mov	dword ptr [esp], esi
  662c63: e8 b8 cb 22 00               	call	0x88f820 <.text+0x48e820>
  662c68: b8 01 00 00 00               	mov	eax, 0x1
  662c6d: 83 c4 14                     	add	esp, 0x14
  662c70: 5e                           	pop	esi
  662c71: c3                           	ret
  662c72: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  662c79: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  662c80: 57                           	push	edi
  662c81: 56                           	push	esi
  662c82: 83 ec 10                     	sub	esp, 0x10
  662c85: 8b 74 24 1c                  	mov	esi, dword ptr [esp + 0x1c]
  662c89: 6a 00                        	push	0x0
  662c8b: 6a 01                        	push	0x1
  662c8d: 56                           	push	esi
  662c8e: e8 dd c7 22 00               	call	0x88f470 <.text+0x48e470>
  662c93: 83 c4 0c                     	add	esp, 0xc
  662c96: 8b f8                        	mov	edi, eax
  662c98: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  662ca0: 89 34 24                     	mov	dword ptr [esp], esi
  662ca3: 66 0f ef c0                  	pxor	xmm0, xmm0
  662ca7: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  662cad: e8 3e c7 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  662cb2: 50                           	push	eax
  662cb3: d9 1c 24                     	fstp	dword ptr [esp]
  662cb6: 8b cf                        	mov	ecx, edi
  662cb8: e8 83 32 f8 ff               	call	0x5e5f40 <.text+0x1e4f40>
  662cbd: 33 c0                        	xor	eax, eax
  662cbf: 83 c4 10                     	add	esp, 0x10
  662cc2: 5e                           	pop	esi
  662cc3: 5f                           	pop	edi
  662cc4: c3                           	ret
  662cc5: 8d 74 26 00                  	lea	esi, [esi + eiz]
  662cc9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  662cd0: 56                           	push	esi
  662cd1: 83 ec 14                     	sub	esp, 0x14
  662cd4: 8b 74 24 1c                  	mov	esi, dword ptr [esp + 0x1c]
  662cd8: 6a 00                        	push	0x0
  662cda: 6a 01                        	push	0x1
  662cdc: 56                           	push	esi
  662cdd: e8 8e c7 22 00               	call	0x88f470 <.text+0x48e470>
  662ce2: 83 c4 0c                     	add	esp, 0xc
  662ce5: 8b c8                        	mov	ecx, eax
  662ce7: e8 94 36 f8 ff               	call	0x5e6380 <.text+0x1e5380>
  662cec: d9 5c 24 0c                  	fstp	dword ptr [esp + 0xc]
  662cf0: f3 0f 10 44 24 0c            	movss	xmm0, dword ptr [esp + 0xc]
  662cf6: f3 0f 5a c0                  	cvtss2sd	xmm0, xmm0
  662cfa: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0

/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  6632c0: ec                           	in	al, dx
  6632c1: a1 ca 00 57 e8               	mov	eax, dword ptr [0xe85700ca]
  6632c6: 66 d3 22                     	shl	word ptr [edx], cl
  6632c9: 00 68 80                     	add	byte ptr [eax - 0x80], ch
  6632cc: 2c 66                        	sub	al, 0x66
  6632ce: 00 68 30                     	add	byte ptr [eax + 0x30], ch
  6632d1: 2c 66                        	sub	al, 0x66
  6632d3: 00 68 f8                     	add	byte ptr [eax - 0x8], ch
  6632d6: a1 ca 00 57 e8               	mov	eax, dword ptr [0xe85700ca]
  6632db: 51                           	push	ecx
  6632dc: d3 22                        	shl	dword ptr [edx], cl
  6632de: 00 68 20                     	add	byte ptr [eax + 0x20], ch
  6632e1: 2d 66 00 68 d0               	sub	eax, 0xd0680066
  6632e6: 2c 66                        	sub	al, 0x66
  6632e8: 00 68 04                     	add	byte ptr [eax + 0x4], ch
  6632eb: a2 ca 00 57 e8               	mov	byte ptr [0xe85700ca], al
  6632f0: 3c d3                        	cmp	al, -0x2d
  6632f2: 22 00                        	and	al, byte ptr [eax]
  6632f4: 68 c0 2d 66 00               	push	0x662dc0
  6632f9: 68 70 2d 66 00               	push	0x662d70
  6632fe: 68 14 a2 ca 00               	push	0xcaa214
  663303: 57                           	push	edi
  663304: e8 27 d3 22 00               	call	0x890630 <.text+0x48f630>
  663309: 57                           	push	edi
  66330a: e8 01 d0 22 00               	call	0x890310 <.text+0x48f310>
  66330f: 57                           	push	edi
  663310: e8 fb cf 22 00               	call	0x890310 <.text+0x48f310>
  663315: 57                           	push	edi
  663316: e8 f5 cf 22 00               	call	0x890310 <.text+0x48f310>
  66331b: 83 c4 5c                     	add	esp, 0x5c
  66331e: b8 01 00 00 00               	mov	eax, 0x1
  663323: 83 c4 10                     	add	esp, 0x10
  663326: 5f                           	pop	edi
  663327: c3                           	ret
  663328: 90                           	nop
  663329: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  663330: 6a 00                        	push	0x0
  663332: 6a 01                        	push	0x1
  663334: ff 74 24 0c                  	push	dword ptr [esp + 0xc]
  663338: e8 33 c1 22 00               	call	0x88f470 <.text+0x48e470>
  66333d: 83 c4 0c                     	add	esp, 0xc
  663340: 8b c8                        	mov	ecx, eax
  663342: e8 49 3b f8 ff               	call	0x5e6e90 <.text+0x1e5e90>
  663347: 33 c0                        	xor	eax, eax
  663349: c3                           	ret
  66334a: 8d b6 00 00 00 00            	lea	esi, [esi]
  663350: 56                           	push	esi
  663351: 8b f1                        	mov	esi, ecx
  663353: e8 78 3b f8 ff               	call	0x5e6ed0 <.text+0x1e5ed0>
  663358: f6 44 24 08 01               	test	byte ptr [esp + 0x8], 0x1
  66335d: 75 06                        	jne	0x663365 <.text+0x262365>
  66335f: 8b c6                        	mov	eax, esi
  663361: 5e                           	pop	esi
  663362: c2 04 00                     	ret	0x4
  663365: 56                           	push	esi
  663366: e8 27 bc 42 00               	call	0xa8ef92 <.text+0x68df92>
  66336b: 59                           	pop	ecx
  66336c: eb f1                        	jmp	0x66335f <.text+0x26235f>
  66336e: 8b f6                        	mov	esi, esi

/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5e4950: 0f b6 44 24 04               	movzx	eax, byte ptr [esp + 0x4]
  5e4955: 50                           	push	eax
  5e4956: b9 40 79 10 01               	mov	ecx, 0x1107940
  5e495b: e8 f0 54 fa ff               	call	0x589e50 <.text+0x188e50>
  5e4960: e8 0b 3b ff ff               	call	0x5d8470 <.text+0x1d7470>
  5e4965: 8b c8                        	mov	ecx, eax
  5e4967: e8 74 42 ff ff               	call	0x5d8be0 <.text+0x1d7be0>
  5e496c: c2 04 00                     	ret	0x4
  5e496f: 90                           	nop
  5e4970: b9 40 79 10 01               	mov	ecx, 0x1107940
  5e4975: e8 e6 54 fa ff               	call	0x589e60 <.text+0x188e60>
  5e497a: c3                           	ret
  5e497b: 90                           	nop
  5e497c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  5e4980: b9 40 79 10 01               	mov	ecx, 0x1107940
  5e4985: e8 d6 54 fa ff               	call	0x589e60 <.text+0x188e60>
  5e498a: 0f b6 c0                     	movzx	eax, al
  5e498d: ba 01 00 00 00               	mov	edx, 0x1
  5e4992: 33 c9                        	xor	ecx, ecx
  5e4994: 85 c0                        	test	eax, eax
  5e4996: 0f 44 ca                     	cmove	ecx, edx
  5e4999: 51                           	push	ecx
  5e499a: b9 40 79 10 01               	mov	ecx, 0x1107940
  5e499f: e8 ac 54 fa ff               	call	0x589e50 <.text+0x188e50>
  5e49a4: e8 c7 3a ff ff               	call	0x5d8470 <.text+0x1d7470>
  5e49a9: 8b c8                        	mov	ecx, eax
  5e49ab: e8 30 42 ff ff               	call	0x5d8be0 <.text+0x1d7be0>

/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5e5f40: 55                           	push	ebp
  5e5f41: 8b ec                        	mov	ebp, esp
  5e5f43: 6a ff                        	push	-0x1
  5e5f45: 68 c0 d4 bf 00               	push	0xbfd4c0
  5e5f4a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  5e5f50: 50                           	push	eax
  5e5f51: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  5e5f58: 83 ec 18                     	sub	esp, 0x18
  5e5f5b: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  5e5f5e: 89 7d e4                     	mov	dword ptr [ebp - 0x1c], edi
  5e5f61: 89 75 e8                     	mov	dword ptr [ebp - 0x18], esi
  5e5f64: 8b f1                        	mov	esi, ecx
  5e5f66: e8 95 78 1d 00               	call	0x7bd800 <.text+0x3bc800>
  5e5f6b: 8b d8                        	mov	ebx, eax
  5e5f6d: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  5e5f74: c7 45 dc 00 00 00 00         	mov	dword ptr [ebp - 0x24], 0x0
  5e5f7b: 50                           	push	eax
  5e5f7c: c7 04 24 18 00 00 00         	mov	dword ptr [esp], 0x18
  5e5f83: e8 82 90 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5e5f88: 59                           	pop	ecx
  5e5f89: 89 45 e0                     	mov	dword ptr [ebp - 0x20], eax
  5e5f8c: 85 c0                        	test	eax, eax
  5e5f8e: 74 20                        	je	0x5e5fb0 <.text+0x1e4fb0>
  5e5f90: c7 00 20 fb 2c 01            	mov	dword ptr [eax], 0x12cfb20
  5e5f96: 89 70 04                     	mov	dword ptr [eax + 0x4], esi
  5e5f99: 33 d2                        	xor	edx, edx
  5e5f9b: 89 50 08                     	mov	dword ptr [eax + 0x8], edx
  5e5f9e: c7 40 10 40 5f 5e 00         	mov	dword ptr [eax + 0x10], 0x5e5f40
  5e5fa5: 89 55 dc                     	mov	dword ptr [ebp - 0x24], edx
  5e5fa8: 89 50 0c                     	mov	dword ptr [eax + 0xc], edx
  5e5fab: 89 50 14                     	mov	dword ptr [eax + 0x14], edx
  5e5fae: eb 02                        	jmp	0x5e5fb2 <.text+0x1e4fb2>
  5e5fb0: 33 c0                        	xor	eax, eax
  5e5fb2: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5e5fb9: 6a 01                        	push	0x1
  5e5fbb: 50                           	push	eax
  5e5fbc: 8b cb                        	mov	ecx, ebx
  5e5fbe: e8 0d 85 1d 00               	call	0x7be4d0 <.text+0x3bd4d0>
  5e5fc3: ff 75 08                     	push	dword ptr [ebp + 0x8]
  5e5fc6: e8 b5 0d ea ff               	call	0x486d80 <.text+0x85d80>
  5e5fcb: 59                           	pop	ecx
  5e5fcc: e8 9f 24 ff ff               	call	0x5d8470 <.text+0x1d7470>
  5e5fd1: 8b c8                        	mov	ecx, eax
  5e5fd3: e8 08 2c ff ff               	call	0x5d8be0 <.text+0x1d7be0>
  5e5fd8: 8b 75 e8                     	mov	esi, dword ptr [ebp - 0x18]
  5e5fdb: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5e5fde: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  5e5fe1: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  5e5fe8: 8b e5                        	mov	esp, ebp
  5e5fea: 5d                           	pop	ebp
  5e5feb: c2 04 00                     	ret	0x4
  5e5fee: 90                           	nop
  5e5fef: 90                           	nop
  5e5ff0: 83 ec 08                     	sub	esp, 0x8
  5e5ff3: b9 40 79 10 01               	mov	ecx, 0x1107940
  5e5ff8: e8 33 3c fa ff               	call	0x589c30 <.text+0x188c30>
  5e5ffd: d9 1c 24                     	fstp	dword ptr [esp]
  5e6000: f3 0f 10 04 24               	movss	xmm0, dword ptr [esp]
  5e6005: f3 0f 11 04 24               	movss	dword ptr [esp], xmm0
  5e600a: d9 04 24                     	fld	dword ptr [esp]
  5e600d: 83 c4 08                     	add	esp, 0x8
  5e6010: c3                           	ret
  5e6011: 90                           	nop
  5e6012: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  5e6019: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  5e6020: 53                           	push	ebx
  5e6021: 8b dc                        	mov	ebx, esp
  5e6023: 83 e4 c0                     	and	esp, -0x40
  5e6026: 55                           	push	ebp
  5e6027: 55                           	push	ebp
  5e6028: 8b 6b 04                     	mov	ebp, dword ptr [ebx + 0x4]
  5e602b: 89 6c 24 04                  	mov	dword ptr [esp + 0x4], ebp
  5e602f: 8b ec                        	mov	ebp, esp
  5e6031: 6a ff                        	push	-0x1
  5e6033: 68 f0 d4 bf 00               	push	0xbfd4f0
  5e6038: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  5e603e: 50                           	push	eax
  5e603f: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  5e6046: 83 ec 2c                     	sub	esp, 0x2c
  5e6049: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  5e604c: 89 7d d8                     	mov	dword ptr [ebp - 0x28], edi
  5e604f: 89 75 dc                     	mov	dword ptr [ebp - 0x24], esi
  5e6052: 89 4d e0                     	mov	dword ptr [ebp - 0x20], ecx
  5e6055: b9 40 79 10 01               	mov	ecx, 0x1107940
  5e605a: e8 d1 3b fa ff               	call	0x589c30 <.text+0x188c30>
  5e605f: d9 5d d0                     	fstp	dword ptr [ebp - 0x30]
  5e6062: f3 0f 10 4d d0               	movss	xmm1, dword ptr [ebp - 0x30]
  5e6067: f3 0f 10 43 08               	movss	xmm0, dword ptr [ebx + 0x8]
  5e606c: 0f 2e c1                     	ucomiss	xmm0, xmm1
  5e606f: 7a 06                        	jp	0x5e6077 <.text+0x1e5077>
  5e6071: 0f 84 47 01 00 00            	je	0x5e61be <.text+0x1e51be>
  5e6077: 0f b6 43 14                  	movzx	eax, byte ptr [ebx + 0x14]
  5e607b: 85 c0                        	test	eax, eax
  5e607d: 74 60                        	je	0x5e60df <.text+0x1e50df>
  5e607f: c7 45 fc 02 00 00 00         	mov	dword ptr [ebp - 0x4], 0x2
  5e6086: c7 45 c8 00 00 00 00         	mov	dword ptr [ebp - 0x38], 0x0
  5e608d: 50                           	push	eax
  5e608e: c7 04 24 40 00 00 00         	mov	dword ptr [esp], 0x40
  5e6095: e8 70 8f 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5e609a: 59                           	pop	ecx
  5e609b: 8b f8                        	mov	edi, eax
  5e609d: 89 7d cc                     	mov	dword ptr [ebp - 0x34], edi
  5e60a0: 85 ff                        	test	edi, edi
  5e60a2: 74 37                        	je	0x5e60db <.text+0x1e50db>
  5e60a4: f3 0f 5a 43 08               	cvtss2sd	xmm0, dword ptr [ebx + 0x8]
  5e60a9: f2 0f 10 4b 0c               	movsd	xmm1, qword ptr [ebx + 0xc]
  5e60ae: 83 c4 ec                     	add	esp, -0x14
  5e60b1: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  5e60b6: f2 0f 11 4c 24 08            	movsd	qword ptr [esp + 0x8], xmm1
  5e60bc: c7 45 c8 01 00 00 00         	mov	dword ptr [ebp - 0x38], 0x1
  5e60c3: 8b cf                        	mov	ecx, edi
  5e60c5: c7 44 24 10 00 00 00 00      	mov	dword ptr [esp + 0x10], 0x0
  5e60cd: e8 be 99 1d 00               	call	0x7bfa90 <.text+0x3bea90>
  5e60d2: c7 45 c8 00 00 00 00         	mov	dword ptr [ebp - 0x38], 0x0
  5e60d9: eb 62                        	jmp	0x5e613d <.text+0x1e513d>
  5e60db: 33 ff                        	xor	edi, edi
  5e60dd: eb 5e                        	jmp	0x5e613d <.text+0x1e513d>
  5e60df: c7 45 fc 01 00 00 00         	mov	dword ptr [ebp - 0x4], 0x1
  5e60e6: c7 45 c8 00 00 00 00         	mov	dword ptr [ebp - 0x38], 0x0
  5e60ed: 50                           	push	eax
  5e60ee: c7 04 24 40 00 00 00         	mov	dword ptr [esp], 0x40
  5e60f5: e8 10 8f 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5e60fa: 59                           	pop	ecx
  5e60fb: 8b f8                        	mov	edi, eax
  5e60fd: 89 7d cc                     	mov	dword ptr [ebp - 0x34], edi
  5e6100: 85 ff                        	test	edi, edi
  5e6102: 74 37                        	je	0x5e613b <.text+0x1e513b>
  5e6104: f3 0f 5a 43 08               	cvtss2sd	xmm0, dword ptr [ebx + 0x8]
  5e6109: f2 0f 10 4b 0c               	movsd	xmm1, qword ptr [ebx + 0xc]
  5e610e: 83 c4 ec                     	add	esp, -0x14
  5e6111: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  5e6116: f2 0f 11 4c 24 08            	movsd	qword ptr [esp + 0x8], xmm1
  5e611c: c7 45 c8 01 00 00 00         	mov	dword ptr [ebp - 0x38], 0x1
  5e6123: 8b cf                        	mov	ecx, edi
  5e6125: c7 44 24 10 00 00 00 00      	mov	dword ptr [esp + 0x10], 0x0
  5e612d: e8 1e 9b 1d 00               	call	0x7bfc50 <.text+0x3bec50>
  5e6132: c7 45 c8 00 00 00 00         	mov	dword ptr [ebp - 0x38], 0x0
  5e6139: eb 02                        	jmp	0x5e613d <.text+0x1e513d>
  5e613b: 33 ff                        	xor	edi, edi
  5e613d: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5e6144: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  5e614b: c7 45 c8 00 00 00 00         	mov	dword ptr [ebp - 0x38], 0x0
  5e6152: 50                           	push	eax
  5e6153: c7 04 24 18 00 00 00         	mov	dword ptr [esp], 0x18
  5e615a: e8 ab 8e 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5e615f: 59                           	pop	ecx
  5e6160: 8b f0                        	mov	esi, eax
  5e6162: 89 75 cc                     	mov	dword ptr [ebp - 0x34], esi
  5e6165: 85 f6                        	test	esi, esi
  5e6167: 74 23                        	je	0x5e618c <.text+0x1e518c>
  5e6169: 8b 45 e0                     	mov	eax, dword ptr [ebp - 0x20]
  5e616c: c7 06 20 fb 2c 01            	mov	dword ptr [esi], 0x12cfb20
  5e6172: 89 46 04                     	mov	dword ptr [esi + 0x4], eax
  5e6175: 33 d2                        	xor	edx, edx
  5e6177: c7 46 10 40 5f 5e 00         	mov	dword ptr [esi + 0x10], 0x5e5f40
  5e617e: 89 55 c8                     	mov	dword ptr [ebp - 0x38], edx
  5e6181: 89 56 08                     	mov	dword ptr [esi + 0x8], edx
  5e6184: 89 56 0c                     	mov	dword ptr [esi + 0xc], edx
  5e6187: 89 56 14                     	mov	dword ptr [esi + 0x14], edx
  5e618a: eb 02                        	jmp	0x5e618e <.text+0x1e518e>
  5e618c: 33 f6                        	xor	esi, esi
  5e618e: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5e6195: b9 40 79 10 01               	mov	ecx, 0x1107940
  5e619a: e8 91 3a fa ff               	call	0x589c30 <.text+0x188c30>
  5e619f: d9 5d d0                     	fstp	dword ptr [ebp - 0x30]
  5e61a2: f3 0f 10 45 d0               	movss	xmm0, dword ptr [ebp - 0x30]
  5e61a7: f3 0f 5a c0                  	cvtss2sd	xmm0, xmm0
  5e61ab: 8b 07                        	mov	eax, dword ptr [edi]
  5e61ad: 83 c4 f4                     	add	esp, -0xc
  5e61b0: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  5e61b6: 89 34 24                     	mov	dword ptr [esp], esi
  5e61b9: 8b cf                        	mov	ecx, edi
  5e61bb: ff 50 0c                     	call	dword ptr [eax + 0xc]
  5e61be: 8b 7d d8                     	mov	edi, dword ptr [ebp - 0x28]
  5e61c1: 8b 75 dc                     	mov	esi, dword ptr [ebp - 0x24]
  5e61c4: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  5e61c7: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  5e61ce: 8b e5                        	mov	esp, ebp
  5e61d0: 5d                           	pop	ebp
  5e61d1: 8b e3                        	mov	esp, ebx
  5e61d3: 5b                           	pop	ebx
  5e61d4: c2 10 00                     	ret	0x10
  5e61d7: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5e61da: 83 7d c8 00                  	cmp	dword ptr [ebp - 0x38], 0x0
  5e61de: 0f 84 fe 72 61 00            	je	0xbfd4e2
  5e61e4: ff 75 cc                     	push	dword ptr [ebp - 0x34]
  5e61e7: e8 a6 8d 4a 00               	call	0xa8ef92 <.text+0x68df92>
  5e61ec: 59                           	pop	ecx
  5e61ed: e9 f0 72 61 00               	jmp	0xbfd4e2
  5e61f2: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5e61f5: 83 7d c8 00                  	cmp	dword ptr [ebp - 0x38], 0x0
  5e61f9: 0f 84 e3 72 61 00            	je	0xbfd4e2
  5e61ff: ff 75 cc                     	push	dword ptr [ebp - 0x34]
  5e6202: e8 8b 8d 4a 00               	call	0xa8ef92 <.text+0x68df92>
  5e6207: 59                           	pop	ecx
  5e6208: e9 d5 72 61 00               	jmp	0xbfd4e2
  5e620d: 90                           	nop
  5e620e: 90                           	nop
  5e620f: 90                           	nop
  5e6210: 55                           	push	ebp
  5e6211: 8b ec                        	mov	ebp, esp
  5e6213: 6a ff                        	push	-0x1
  5e6215: 68 10 d5 bf 00               	push	0xbfd510
  5e621a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  5e6220: 50                           	push	eax
  5e6221: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  5e6228: 83 ec 18                     	sub	esp, 0x18
  5e622b: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  5e622e: 89 7d e4                     	mov	dword ptr [ebp - 0x1c], edi
  5e6231: 89 75 e8                     	mov	dword ptr [ebp - 0x18], esi
  5e6234: 8b f9                        	mov	edi, ecx
  5e6236: 8b 75 08                     	mov	esi, dword ptr [ebp + 0x8]
  5e6239: 85 f6                        	test	esi, esi
  5e623b: 74 77                        	je	0x5e62b4 <.text+0x1e52b4>
  5e623d: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  5e6244: c7 45 dc 00 00 00 00         	mov	dword ptr [ebp - 0x24], 0x0
  5e624b: 50                           	push	eax
  5e624c: c7 04 24 18 00 00 00         	mov	dword ptr [esp], 0x18
  5e6253: e8 b2 8d 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5e6258: 59                           	pop	ecx
  5e6259: 8b d8                        	mov	ebx, eax
  5e625b: 89 5d e0                     	mov	dword ptr [ebp - 0x20], ebx
  5e625e: 85 db                        	test	ebx, ebx
  5e6260: 74 20                        	je	0x5e6282 <.text+0x1e5282>
  5e6262: c7 03 20 fb 2c 01            	mov	dword ptr [ebx], 0x12cfb20
  5e6268: 89 7b 04                     	mov	dword ptr [ebx + 0x4], edi
  5e626b: 33 c0                        	xor	eax, eax
  5e626d: 89 43 08                     	mov	dword ptr [ebx + 0x8], eax
  5e6270: c7 43 10 40 5f 5e 00         	mov	dword ptr [ebx + 0x10], 0x5e5f40
  5e6277: 89 45 dc                     	mov	dword ptr [ebp - 0x24], eax
  5e627a: 89 43 0c                     	mov	dword ptr [ebx + 0xc], eax
  5e627d: 89 43 14                     	mov	dword ptr [ebx + 0x14], eax
  5e6280: eb 02                        	jmp	0x5e6284 <.text+0x1e5284>
  5e6282: 33 db                        	xor	ebx, ebx
  5e6284: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5e628b: b9 40 79 10 01               	mov	ecx, 0x1107940
  5e6290: e8 9b 39 fa ff               	call	0x589c30 <.text+0x188c30>
  5e6295: d9 5d dc                     	fstp	dword ptr [ebp - 0x24]
  5e6298: f3 0f 10 45 dc               	movss	xmm0, dword ptr [ebp - 0x24]
  5e629d: f3 0f 5a c0                  	cvtss2sd	xmm0, xmm0
  5e62a1: 8b 06                        	mov	eax, dword ptr [esi]
  5e62a3: 83 c4 f4                     	add	esp, -0xc
  5e62a6: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  5e62ac: 89 1c 24                     	mov	dword ptr [esp], ebx
  5e62af: 8b ce                        	mov	ecx, esi
  5e62b1: ff 50 0c                     	call	dword ptr [eax + 0xc]
  5e62b4: 8b 7d e4                     	mov	edi, dword ptr [ebp - 0x1c]
  5e62b7: 8b 75 e8                     	mov	esi, dword ptr [ebp - 0x18]
  5e62ba: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5e62bd: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  5e62c0: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  5e62c7: 8b e5                        	mov	esp, ebp
  5e62c9: 5d                           	pop	ebp
  5e62ca: c2 04 00                     	ret	0x4
  5e62cd: 90                           	nop
  5e62ce: 90                           	nop
  5e62cf: 90                           	nop
  5e62d0: 56                           	push	esi
  5e62d1: f3 0f 10 05 0c 73 c3 00      	movss	xmm0, dword ptr [0xc3730c]
  5e62d9: f3 0f 10 0d 08 73 c3 00      	movss	xmm1, dword ptr [0xc37308]
  5e62e1: e8 72 8b 4a 00               	call	0xa8ee58 <.text+0x68de58>
  5e62e6: f3 0f 11 04 24               	movss	dword ptr [esp], xmm0
  5e62eb: e8 a0 0a ea ff               	call	0x486d90 <.text+0x85d90>
  5e62f0: e8 7b 21 ff ff               	call	0x5d8470 <.text+0x1d7470>
  5e62f5: 8b c8                        	mov	ecx, eax
  5e62f7: e8 e4 28 ff ff               	call	0x5d8be0 <.text+0x1d7be0>
  5e62fc: 59                           	pop	ecx
  5e62fd: c3                           	ret
  5e62fe: 8b f6                        	mov	esi, esi
  5e6300: 56                           	push	esi
  5e6301: f3 0f 10 05 14 73 c3 00      	movss	xmm0, dword ptr [0xc37314]
  5e6309: f3 0f 10 0d 10 73 c3 00      	movss	xmm1, dword ptr [0xc37310]
  5e6311: e8 42 8b 4a 00               	call	0xa8ee58 <.text+0x68de58>
  5e6316: f3 0f 11 04 24               	movss	dword ptr [esp], xmm0
  5e631b: e8 70 0a ea ff               	call	0x486d90 <.text+0x85d90>
  5e6320: e8 4b 21 ff ff               	call	0x5d8470 <.text+0x1d7470>
  5e6325: 8b c8                        	mov	ecx, eax
  5e6327: e8 b4 28 ff ff               	call	0x5d8be0 <.text+0x1d7be0>
  5e632c: 59                           	pop	ecx
  5e632d: c3                           	ret
  5e632e: 8b f6                        	mov	esi, esi
  5e6330: 83 ec 08                     	sub	esp, 0x8
  5e6333: b9 40 79 10 01               	mov	ecx, 0x1107940
  5e6338: e8 23 39 fa ff               	call	0x589c60 <.text+0x188c60>
  5e633d: d9 1c 24                     	fstp	dword ptr [esp]
  5e6340: f3 0f 10 0c 24               	movss	xmm1, dword ptr [esp]
  5e6345: f3 0f 10 44 24 0c            	movss	xmm0, dword ptr [esp + 0xc]
  5e634b: 0f 2e c1                     	ucomiss	xmm0, xmm1
  5e634e: 7a 02                        	jp	0x5e6352 <.text+0x1e5352>
  5e6350: 74 1a                        	je	0x5e636c <.text+0x1e536c>
  5e6352: ff 74 24 0c                  	push	dword ptr [esp + 0xc]
  5e6356: b9 40 79 10 01               	mov	ecx, 0x1107940
  5e635b: e8 f0 38 fa ff               	call	0x589c50 <.text+0x188c50>
  5e6360: e8 0b 21 ff ff               	call	0x5d8470 <.text+0x1d7470>
  5e6365: 8b c8                        	mov	ecx, eax
  5e6367: e8 74 28 ff ff               	call	0x5d8be0 <.text+0x1d7be0>
  5e636c: 83 c4 08                     	add	esp, 0x8
  5e636f: c2 04 00                     	ret	0x4

/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5e6e90: 56                           	push	esi
  5e6e91: c7 04 24 00 00 80 3f         	mov	dword ptr [esp], 0x3f800000
  5e6e98: e8 e3 fe e9 ff               	call	0x486d80 <.text+0x85d80>
  5e6e9d: e8 ce 15 ff ff               	call	0x5d8470 <.text+0x1d7470>
  5e6ea2: 8b c8                        	mov	ecx, eax
  5e6ea4: e8 37 1d ff ff               	call	0x5d8be0 <.text+0x1d7be0>
  5e6ea9: 59                           	pop	ecx
  5e6eaa: c3                           	ret
  5e6eab: 90                           	nop
  5e6eac: 8d 74 26 00                  	lea	esi, [esi + eiz]
  5e6eb0: 55                           	push	ebp
  5e6eb1: 8b e9                        	mov	ebp, ecx
  5e6eb3: e8 18 f6 47 00               	call	0xa664d0 <.text+0x6654d0>
  5e6eb8: c7 45 00 f4 04 2d 01         	mov	dword ptr [ebp], 0x12d04f4
  5e6ebf: 89 2d d0 4d 19 01            	mov	dword ptr [0x1194dd0], ebp

/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  589c20: 8b 44 24 04                  	mov	eax, dword ptr [esp + 0x4]
  589c24: 89 41 6c                     	mov	dword ptr [ecx + 0x6c], eax
  589c27: c2 04 00                     	ret	0x4
  589c2a: 8d b6 00 00 00 00            	lea	esi, [esi]
  589c30: d9 41 6c                     	fld	dword ptr [ecx + 0x6c]
  589c33: c3                           	ret
  589c34: 8d b6 00 00 00 00            	lea	esi, [esi]
  589c3a: 8d bf 00 00 00 00            	lea	edi, [edi]
  589c40: d9 41 70                     	fld	dword ptr [ecx + 0x70]
  589c43: c3                           	ret
  589c44: 8d b6 00 00 00 00            	lea	esi, [esi]
  589c4a: 8d bf 00 00 00 00            	lea	edi, [edi]

/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  589e50: 0f b6 44 24 04               	movzx	eax, byte ptr [esp + 0x4]
  589e55: 88 81 94 00 00 00            	mov	byte ptr [ecx + 0x94], al
  589e5b: c2 04 00                     	ret	0x4
  589e5e: 8b f6                        	mov	esi, esi
  589e60: 0f b6 81 94 00 00 00         	movzx	eax, byte ptr [ecx + 0x94]
  589e67: c3                           	ret
  589e68: 90                           	nop
  589e69: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]

/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  486d80: ff 74 24 04                  	push	dword ptr [esp + 0x4]
  486d84: b9 40 79 10 01               	mov	ecx, 0x1107940
  486d89: e8 92 2e 10 00               	call	0x589c20 <.text+0x188c20>
  486d8e: c3                           	ret
  486d8f: 90                           	nop
  486d90: 83 ec 08                     	sub	esp, 0x8
  486d93: b9 40 79 10 01               	mov	ecx, 0x1107940
  486d98: e8 93 2e 10 00               	call	0x589c30 <.text+0x188c30>
  486d9d: d9 1c 24                     	fstp	dword ptr [esp]
  486da0: f3 0f 10 0c 24               	movss	xmm1, dword ptr [esp]
  486da5: 50                           	push	eax
  486da6: f3 0f 10 44 24 10            	movss	xmm0, dword ptr [esp + 0x10]
  486dac: f3 0f 59 c8                  	mulss	xmm1, xmm0
  486db0: f3 0f 11 0c 24               	movss	dword ptr [esp], xmm1
  486db5: b9 40 79 10 01               	mov	ecx, 0x1107940
  486dba: e8 61 2e 10 00               	call	0x589c20 <.text+0x188c20>
  486dbf: 83 c4 08                     	add	esp, 0x8

/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  47ce50: 57                           	push	edi
  47ce51: ff 15 4c 59 c2 00            	call	dword ptr [0xc2594c]
  47ce57: b9 40 79 10 01               	mov	ecx, 0x1107940
  47ce5c: e8 cf cd 10 00               	call	0x589c30 <.text+0x188c30>
  47ce61: d9 9d 78 ff ff ff            	fstp	dword ptr [ebp - 0x88]
  47ce67: f3 0f 10 85 78 ff ff ff      	movss	xmm0, dword ptr [ebp - 0x88]
  47ce6f: f3 0f 5a c0                  	cvtss2sd	xmm0, xmm0
  47ce73: 8d bd 08 fc ff ff            	lea	edi, [ebp - 0x3f8]
  47ce79: 83 c4 f0                     	add	esp, -0x10
  47ce7c: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  47ce82: c7 44 24 04 98 ca c2 00      	mov	dword ptr [esp + 0x4], 0xc2ca98
  47ce8a: 89 3c 24                     	mov	dword ptr [esp], edi
  47ce8d: ff 15 30 56 c2 00            	call	dword ptr [0xc25630]

/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  46ddb0: 83 ec 08                     	sub	esp, 0x8
  46ddb3: f3 0f 10 44 24 0c            	movss	xmm0, dword ptr [esp + 0xc]
  46ddb9: f3 0f 10 64 24 14            	movss	xmm4, dword ptr [esp + 0x14]
  46ddbf: 0f 2f c4                     	comiss	xmm0, xmm4
  46ddc2: 0f 87 83 00 00 00            	ja	0x46de4b <.text+0x6ce4b>
  46ddc8: f3 0f 10 5c 24 10            	movss	xmm3, dword ptr [esp + 0x10]
  46ddce: 0f 2f e3                     	comiss	xmm4, xmm3
  46ddd1: 77 78                        	ja	0x46de4b <.text+0x6ce4b>
  46ddd3: 0f 28 f0                     	movaps	xmm6, xmm0
  46ddd6: f3 0f 10 54 24 18            	movss	xmm2, dword ptr [esp + 0x18]
  46dddc: f3 0f 10 0d 90 be c2 00      	movss	xmm1, dword ptr [0xc2be90]
  46dde4: f3 0f 59 ca                  	mulss	xmm1, xmm2
  46dde8: f3 0f 58 f1                  	addss	xmm6, xmm1
  46ddec: 0f 2f f4                     	comiss	xmm6, xmm4
  46ddef: f3 0f 10 2d 94 be c2 00      	movss	xmm5, dword ptr [0xc2be94]
  46ddf7: f3 0f 59 d5                  	mulss	xmm2, xmm5
  46ddfb: 77 0a                        	ja	0x46de07 <.text+0x6ce07>
  46ddfd: f3 0f 10 2d 9c be c2 00      	movss	xmm5, dword ptr [0xc2be9c]
  46de05: eb 12                        	jmp	0x46de19 <.text+0x6ce19>
  46de07: 0f 28 ec                     	movaps	xmm5, xmm4
  46de0a: f3 0f 5c e8                  	subss	xmm5, xmm0
  46de0e: 0f 54 2d 60 b7 c2 00         	andps	xmm5, xmmword ptr [0xc2b760]
  46de15: f3 0f 5e e9                  	divss	xmm5, xmm1
  46de19: 0f 28 c3                     	movaps	xmm0, xmm3
  46de1c: f3 0f 5c c2                  	subss	xmm0, xmm2
  46de20: 0f 2f e0                     	comiss	xmm4, xmm0
  46de23: 76 12                        	jbe	0x46de37 <.text+0x6ce37>
  46de25: 0f 28 ec                     	movaps	xmm5, xmm4
  46de28: f3 0f 5c eb                  	subss	xmm5, xmm3
  46de2c: 0f 54 2d 60 b7 c2 00         	andps	xmm5, xmmword ptr [0xc2b760]
  46de33: f3 0f 5e ea                  	divss	xmm5, xmm2
  46de37: f3 0f 59 2d 98 be c2 00      	mulss	xmm5, dword ptr [0xc2be98]
  46de3f: f3 0f 11 2c 24               	movss	dword ptr [esp], xmm5
  46de44: d9 04 24                     	fld	dword ptr [esp]
  46de47: 83 c4 08                     	add	esp, 0x8
  46de4a: c3                           	ret
  46de4b: 66 0f ef c0                  	pxor	xmm0, xmm0
  46de4f: f3 0f 11 04 24               	movss	dword ptr [esp], xmm0
  46de54: d9 04 24                     	fld	dword ptr [esp]
  46de57: 83 c4 08                     	add	esp, 0x8
  46de5a: c3                           	ret
  46de5b: 90                           	nop
  46de5c: 8d 74 26 00                  	lea	esi, [esi + eiz]

/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  a8ee50: c2 00 ff                     	ret	-0x100
  a8ee53: 25 84 7e c2 00               	and	eax, 0xc27e84
  a8ee58: ff 25 80 7e c2 00            	jmp	dword ptr [0xc27e80]
  a8ee5e: ff 25 7c 7e c2 00            	jmp	dword ptr [0xc27e7c]
  a8ee64: ff 25 74 7e c2 00            	jmp	dword ptr [0xc27e74]
  a8ee6a: ff 25 44 7e c2 00            	jmp	dword ptr [0xc27e44]
  a8ee70: ff 25 48 7e c2 00            	jmp	dword ptr [0xc27e48]
  a8ee76: ff 25 4c 7e c2 00            	jmp	dword ptr [0xc27e4c]
  a8ee7c: ff 25 50 7e c2 00            	jmp	dword ptr [0xc27e50]
Artifact: /Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe
SHA-256: 48961f09019e0e43f23f2537752978dc16c563c807f5b048ba5b0448c0d2b457

Range 0x661f00..0x662100

Range 0x662500..0x662570

Range 0x662c30..0x662d00

Range 0x6632c0..0x663370

Range 0x5e4950..0x5e49b0

Range 0x5e5f40..0x5e6370

Range 0x5e6e90..0x5e6ec0

Range 0x589c20..0x589c50

Range 0x589e50..0x589e70

Range 0x486d80..0x486dc0

Range 0x47ce50..0x47ce90

Range 0x46ddb0..0x46de60

Range 0xa8ee50..0xa8ee80
