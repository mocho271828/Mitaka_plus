
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  587c60: e8 95 5d 51 00               	call	0xa9d9fa <.text+0x69c9fa>
  587c65: f2 0f 5a 85 40 fe ff ff      	cvtsd2ss	xmm0, qword ptr [ebp - 0x1c0]
  587c6d: 8b 53 08                     	mov	edx, dword ptr [ebx + 0x8]
  587c70: f2 0f 2a 8a 0c 02 00 00      	cvtsi2sd	xmm1, dword ptr [edx + 0x20c]
  587c78: f3 0f 2a 9a 0c 02 00 00      	cvtsi2ss	xmm3, dword ptr [edx + 0x20c]
  587c80: f2 0f 5c 8d 48 fe ff ff      	subsd	xmm1, qword ptr [ebp - 0x1b8]
  587c88: f2 0f 5a d1                  	cvtsd2ss	xmm2, xmm1
  587c8c: 8b 46 34                     	mov	eax, dword ptr [esi + 0x34]
  587c8f: f3 0f 10 66 40               	movss	xmm4, dword ptr [esi + 0x40]
  587c94: f3 0f 59 a5 ac fd ff ff      	mulss	xmm4, dword ptr [ebp - 0x254]
  587c9c: f3 0f 59 e3                  	mulss	xmm4, xmm3
  587ca0: f3 0f 5e 25 14 4c c3 00      	divss	xmm4, dword ptr [0xc34c14]
  587ca8: 83 c4 ec                     	add	esp, -0x14
  587cab: f3 0f 11 44 24 08            	movss	dword ptr [esp + 0x8], xmm0
  587cb1: f3 0f 11 54 24 0c            	movss	dword ptr [esp + 0xc], xmm2
  587cb7: f3 0f 11 64 24 10            	movss	dword ptr [esp + 0x10], xmm4
  587cbd: b9 60 75 10 01               	mov	ecx, 0x1107560
  587cc2: c6 04 24 08                  	mov	byte ptr [esp], 0x8
  587cc6: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  587cca: e8 21 9b fd ff               	call	0x5617f0 <.text+0x1607f0>
  587ccf: 8b 36                        	mov	esi, dword ptr [esi]
  587cd1: ff 45 a8                     	inc	dword ptr [ebp - 0x58]
  587cd4: 85 f6                        	test	esi, esi
  587cd6: 0f 85 14 f8 ff ff            	jne	0x5874f0 <.text+0x1864f0>
  587cdc: ff 15 34 59 c2 00            	call	dword ptr [0xc25934]
  587ce2: e9 63 e5 ff ff               	jmp	0x58624a <.text+0x18524a>
  587ce7: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  587cea: c3                           	ret
  587ceb: 90                           	nop
  587cec: 8d 74 26 00                  	lea	esi, [esi + eiz]
  587cf0: b8 08 82 2a 01               	mov	eax, 0x12a8208
  587cf5: e9 8c 72 50 00               	jmp	0xa8ef86 <.text+0x68df86>
  587cfa: 90                           	nop
  587cfb: 90                           	nop
  587cfc: 90                           	nop
  587cfd: 90                           	nop
  587cfe: 90                           	nop
  587cff: 90                           	nop
  587d00: 53                           	push	ebx
  587d01: 8b dc                        	mov	ebx, esp
  587d03: 83 e4 f8                     	and	esp, -0x8
  587d06: 55                           	push	ebp
  587d07: 55                           	push	ebp
  587d08: 8b 6b 04                     	mov	ebp, dword ptr [ebx + 0x4]
  587d0b: 89 6c 24 04                  	mov	dword ptr [esp + 0x4], ebp
  587d0f: 8b ec                        	mov	ebp, esp
  587d11: 6a ff                        	push	-0x1
  587d13: 68 60 87 58 00               	push	0x588760
  587d18: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  587d1e: 50                           	push	eax
  587d1f: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  587d26: 81 ec 4c 03 00 00            	sub	esp, 0x34c
  587d2c: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  587d2f: 89 7d d0                     	mov	dword ptr [ebp - 0x30], edi
  587d32: 89 75 d4                     	mov	dword ptr [ebp - 0x2c], esi
  587d35: 8b f1                        	mov	esi, ecx
  587d37: b9 58 79 10 01               	mov	ecx, 0x1107958
  587d3c: a1 10 53 d8 00               	mov	eax, dword ptr [0xd85310]
  587d41: 89 45 e4                     	mov	dword ptr [ebp - 0x1c], eax
  587d44: e8 c7 b5 1c 00               	call	0x753310 <.text+0x352310>
  587d49: 0f b6 c0                     	movzx	eax, al
  587d4c: 85 c0                        	test	eax, eax
  587d4e: 75 1e                        	jne	0x587d6e <.text+0x186d6e>
  587d50: 8b 4d e4                     	mov	ecx, dword ptr [ebp - 0x1c]
  587d53: e8 68 71 50 00               	call	0xa8eec0 <.text+0x68dec0>
  587d58: 8b 75 d4                     	mov	esi, dword ptr [ebp - 0x2c]
  587d5b: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  587d5e: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  587d65: 8b e5                        	mov	esp, ebp
  587d67: 5d                           	pop	ebp
  587d68: 8b e3                        	mov	esp, ebx
  587d6a: 5b                           	pop	ebx
  587d6b: c2 04 00                     	ret	0x4
  587d6e: 6a 00                        	push	0x0
  587d70: e8 5b 9d f1 ff               	call	0x4a1ad0 <.text+0xa0ad0>
  587d75: 6a 05                        	push	0x5
  587d77: 8b 10                        	mov	edx, dword ptr [eax]
  587d79: 89 95 60 ff ff ff            	mov	dword ptr [ebp - 0xa0], edx
  587d7f: 8b 48 04                     	mov	ecx, dword ptr [eax + 0x4]
  587d82: 89 8d 64 ff ff ff            	mov	dword ptr [ebp - 0x9c], ecx
  587d88: 8b 40 08                     	mov	eax, dword ptr [eax + 0x8]
  587d8b: 89 85 68 ff ff ff            	mov	dword ptr [ebp - 0x98], eax
  587d91: e8 3a 9d f1 ff               	call	0x4a1ad0 <.text+0xa0ad0>
  587d96: 83 c4 08                     	add	esp, 0x8
  587d99: 8b 53 08                     	mov	edx, dword ptr [ebx + 0x8]
  587d9c: 68 71 0b 00 00               	push	0xb71
  587da1: 8b 38                        	mov	edi, dword ptr [eax]
  587da3: f2 0f 10 42 68               	movsd	xmm0, qword ptr [edx + 0x68]
  587da8: f2 0f 11 45 c8               	movsd	qword ptr [ebp - 0x38], xmm0
  587dad: 89 bd 70 ff ff ff            	mov	dword ptr [ebp - 0x90], edi
  587db3: 8b 48 04                     	mov	ecx, dword ptr [eax + 0x4]
  587db6: 8b ba 38 01 00 00            	mov	edi, dword ptr [edx + 0x138]
  587dbc: 89 8d 74 ff ff ff            	mov	dword ptr [ebp - 0x8c], ecx
  587dc2: 8b 40 08                     	mov	eax, dword ptr [eax + 0x8]
  587dc5: 8b 8a 40 01 00 00            	mov	ecx, dword ptr [edx + 0x140]
  587dcb: 89 85 78 ff ff ff            	mov	dword ptr [ebp - 0x88], eax
  587dd1: 8b 82 3c 01 00 00            	mov	eax, dword ptr [edx + 0x13c]
  587dd7: 89 bd a8 fc ff ff            	mov	dword ptr [ebp - 0x358], edi
  587ddd: 8b ba 44 01 00 00            	mov	edi, dword ptr [edx + 0x144]
  587de3: 89 85 ac fc ff ff            	mov	dword ptr [ebp - 0x354], eax
  587de9: 8b 82 4c 01 00 00            	mov	eax, dword ptr [edx + 0x14c]
  587def: 89 8d b8 fc ff ff            	mov	dword ptr [ebp - 0x348], ecx
  587df5: 89 bd b0 fc ff ff            	mov	dword ptr [ebp - 0x350], edi
  587dfb: 8b ba 48 01 00 00            	mov	edi, dword ptr [edx + 0x148]
  587e01: 89 85 b4 fc ff ff            	mov	dword ptr [ebp - 0x34c], eax
  587e07: ff 15 18 59 c2 00            	call	dword ptr [0xc25918]
  587e0d: b9 58 79 10 01               	mov	ecx, 0x1107958
  587e12: e8 49 b5 1c 00               	call	0x753360 <.text+0x352360>
  587e17: d9 5d b8                     	fstp	dword ptr [ebp - 0x48]
  587e1a: f3 0f 10 45 b8               	movss	xmm0, dword ptr [ebp - 0x48]
  587e1f: f3 0f 5a c8                  	cvtss2sd	xmm1, xmm0
  587e23: f2 0f 11 4d c0               	movsd	qword ptr [ebp - 0x40], xmm1
  587e28: 8b 46 68                     	mov	eax, dword ptr [esi + 0x68]
  587e2b: 89 45 d8                     	mov	dword ptr [ebp - 0x28], eax
  587e2e: 85 c0                        	test	eax, eax
  587e30: 0f 84 f3 08 00 00            	je	0x588729 <.text+0x187729>
  587e36: 8b 85 b4 fc ff ff            	mov	eax, dword ptr [ebp - 0x34c]
  587e3c: 8b 95 b0 fc ff ff            	mov	edx, dword ptr [ebp - 0x350]
  587e42: 8b 8d b8 fc ff ff            	mov	ecx, dword ptr [ebp - 0x348]
  587e48: 8b b5 ac fc ff ff            	mov	esi, dword ptr [ebp - 0x354]
  587e4e: f2 0f 10 05 b8 49 c3 00      	movsd	xmm0, qword ptr [0xc349b8]
  587e56: 89 85 f4 fe ff ff            	mov	dword ptr [ebp - 0x10c], eax
  587e5c: 89 bd f0 fe ff ff            	mov	dword ptr [ebp - 0x110], edi
  587e62: 8b bd a8 fc ff ff            	mov	edi, dword ptr [ebp - 0x358]
  587e68: 89 95 ec fe ff ff            	mov	dword ptr [ebp - 0x114], edx
  587e6e: 89 8d e8 fe ff ff            	mov	dword ptr [ebp - 0x118], ecx
  587e74: 89 b5 e4 fe ff ff            	mov	dword ptr [ebp - 0x11c], esi
  587e7a: 89 bd e0 fe ff ff            	mov	dword ptr [ebp - 0x120], edi
  587e80: e8 8b 6f 50 00               	call	0xa8ee10 <.text+0x68de10>
  587e85: f2 0f 11 45 a8               	movsd	qword ptr [ebp - 0x58], xmm0
  587e8a: f2 0f 11 4d b0               	movsd	qword ptr [ebp - 0x50], xmm1
  587e8f: 8b 7d d8                     	mov	edi, dword ptr [ebp - 0x28]
  587e92: 8d 77 61                     	lea	esi, [edi + 0x61]
  587e95: 89 75 e0                     	mov	dword ptr [ebp - 0x20], esi
  587e98: 8d 47 7f                     	lea	eax, [edi + 0x7f]
  587e9b: 0f be 3e                     	movsx	edi, byte ptr [esi]
  587e9e: 0f be 30                     	movsx	esi, byte ptr [eax]
  587ea1: 89 45 dc                     	mov	dword ptr [ebp - 0x24], eax
  587ea4: ba 01 00 00 00               	mov	edx, 0x1
  587ea9: 85 ff                        	test	edi, edi
  587eab: 0f 45 fa                     	cmovne	edi, edx
  587eae: 85 f6                        	test	esi, esi
  587eb0: 0f 45 f2                     	cmovne	esi, edx
  587eb3: 85 ff                        	test	edi, edi
  587eb5: 75 08                        	jne	0x587ebf <.text+0x186ebf>
  587eb7: 85 f6                        	test	esi, esi
  587eb9: 0f 84 58 08 00 00            	je	0x588717 <.text+0x187717>
  587ebf: 0f b6 05 d4 79 10 01         	movzx	eax, byte ptr [0x11079d4]
  587ec6: 85 c0                        	test	eax, eax
  587ec8: 0f 84 80 00 00 00            	je	0x587f4e <.text+0x186f4e>
  587ece: 8b 45 d8                     	mov	eax, dword ptr [ebp - 0x28]
  587ed1: f2 0f 10 50 08               	movsd	xmm2, qword ptr [eax + 0x8]
  587ed6: f2 0f 5c 95 e0 fe ff ff      	subsd	xmm2, qword ptr [ebp - 0x120]
  587ede: f2 0f 10 40 10               	movsd	xmm0, qword ptr [eax + 0x10]
  587ee3: f2 0f 10 48 18               	movsd	xmm1, qword ptr [eax + 0x18]
  587ee8: f2 0f 11 95 f8 fe ff ff      	movsd	qword ptr [ebp - 0x108], xmm2
  587ef0: 0f 28 d8                     	movaps	xmm3, xmm0
  587ef3: 0f 28 e1                     	movaps	xmm4, xmm1
  587ef6: f2 0f 5c 9d e8 fe ff ff      	subsd	xmm3, qword ptr [ebp - 0x118]
  587efe: f2 0f 5c a5 f0 fe ff ff      	subsd	xmm4, qword ptr [ebp - 0x110]
  587f06: 8b 95 f8 fe ff ff            	mov	edx, dword ptr [ebp - 0x108]
  587f0c: 8b 8d fc fe ff ff            	mov	ecx, dword ptr [ebp - 0x104]
  587f12: f2 0f 11 9d 00 ff ff ff      	movsd	qword ptr [ebp - 0x100], xmm3
  587f1a: 8b 85 00 ff ff ff            	mov	eax, dword ptr [ebp - 0x100]
  587f20: f2 0f 11 a5 08 ff ff ff      	movsd	qword ptr [ebp - 0xf8], xmm4
  587f28: 89 55 80                     	mov	dword ptr [ebp - 0x80], edx
  587f2b: 8b 95 04 ff ff ff            	mov	edx, dword ptr [ebp - 0xfc]
  587f31: 89 4d 84                     	mov	dword ptr [ebp - 0x7c], ecx
  587f34: 8b 8d 08 ff ff ff            	mov	ecx, dword ptr [ebp - 0xf8]
  587f3a: 89 45 88                     	mov	dword ptr [ebp - 0x78], eax
  587f3d: 8b 85 0c ff ff ff            	mov	eax, dword ptr [ebp - 0xf4]
  587f43: 89 55 8c                     	mov	dword ptr [ebp - 0x74], edx
  587f46: 89 4d 90                     	mov	dword ptr [ebp - 0x70], ecx
  587f49: 89 45 94                     	mov	dword ptr [ebp - 0x6c], eax
  587f4c: eb 43                        	jmp	0x587f91 <.text+0x186f91>
  587f4e: 8b 45 d8                     	mov	eax, dword ptr [ebp - 0x28]
  587f51: 8b 90 98 00 00 00            	mov	edx, dword ptr [eax + 0x98]
  587f57: 8b 88 9c 00 00 00            	mov	ecx, dword ptr [eax + 0x9c]
  587f5d: f2 0f 10 40 10               	movsd	xmm0, qword ptr [eax + 0x10]
  587f62: f2 0f 10 48 18               	movsd	xmm1, qword ptr [eax + 0x18]
  587f67: 89 55 80                     	mov	dword ptr [ebp - 0x80], edx
  587f6a: 8b 90 a0 00 00 00            	mov	edx, dword ptr [eax + 0xa0]
  587f70: 89 4d 84                     	mov	dword ptr [ebp - 0x7c], ecx
  587f73: 8b 88 a4 00 00 00            	mov	ecx, dword ptr [eax + 0xa4]
  587f79: 89 55 88                     	mov	dword ptr [ebp - 0x78], edx
  587f7c: 8b 90 a8 00 00 00            	mov	edx, dword ptr [eax + 0xa8]
  587f82: 89 4d 8c                     	mov	dword ptr [ebp - 0x74], ecx
  587f85: 8b 88 ac 00 00 00            	mov	ecx, dword ptr [eax + 0xac]
  587f8b: 89 55 90                     	mov	dword ptr [ebp - 0x70], edx
  587f8e: 89 4d 94                     	mov	dword ptr [ebp - 0x6c], ecx
  587f91: f2 0f 59 c0                  	mulsd	xmm0, xmm0
  587f95: f2 0f 59 c9                  	mulsd	xmm1, xmm1
  587f99: f2 0f 10 65 80               	movsd	xmm4, qword ptr [ebp - 0x80]
  587f9e: f2 0f 59 e4                  	mulsd	xmm4, xmm4
  587fa2: f2 0f 10 55 88               	movsd	xmm2, qword ptr [ebp - 0x78]
  587fa7: f2 0f 59 d2                  	mulsd	xmm2, xmm2
  587fab: f2 0f 10 5d 90               	movsd	xmm3, qword ptr [ebp - 0x70]
  587fb0: f2 0f 59 db                  	mulsd	xmm3, xmm3
  587fb4: f2 0f 10 75 c8               	movsd	xmm6, qword ptr [ebp - 0x38]
  587fb9: f2 0f 58 e2                  	addsd	xmm4, xmm2
  587fbd: f2 0f 58 e3                  	addsd	xmm4, xmm3
  587fc1: 8b 45 d8                     	mov	eax, dword ptr [ebp - 0x28]
  587fc4: f2 0f 51 d4                  	sqrtsd	xmm2, xmm4
  587fc8: f2 0f 5e d6                  	divsd	xmm2, xmm6
  587fcc: f2 0f 10 68 08               	movsd	xmm5, qword ptr [eax + 0x8]
  587fd1: f2 0f 59 ed                  	mulsd	xmm5, xmm5
  587fd5: f2 0f 58 e8                  	addsd	xmm5, xmm0
  587fd9: f2 0f 58 e9                  	addsd	xmm5, xmm1
  587fdd: f2 0f 51 c5                  	sqrtsd	xmm0, xmm5
  587fe1: f2 0f 5e c6                  	divsd	xmm0, xmm6
  587fe5: f2 0f 5a c8                  	cvtsd2ss	xmm1, xmm0
  587fe9: 75 07                        	jne	0x587ff2 <.text+0x186ff2>
  587feb: f2 0f 10 45 c0               	movsd	xmm0, qword ptr [ebp - 0x40]
  587ff0: eb 52                        	jmp	0x588044 <.text+0x187044>
  587ff2: f2 0f 5a c2                  	cvtsd2ss	xmm0, xmm2
  587ff6: f3 0f 11 4d a4               	movss	dword ptr [ebp - 0x5c], xmm1
  587ffb: 83 c4 f0                     	add	esp, -0x10
  587ffe: f3 0f 11 44 24 08            	movss	dword ptr [esp + 0x8], xmm0
  588004: b8 8f c2 f5 3c               	mov	eax, 0x3cf5c28f
  588009: 89 04 24                     	mov	dword ptr [esp], eax
  58800c: ba 9a 99 99 3f               	mov	edx, 0x3f99999a
  588011: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  588015: b9 00 00 80 3f               	mov	ecx, 0x3f800000
  58801a: 89 4c 24 0c                  	mov	dword ptr [esp + 0xc], ecx
  58801e: e8 8d 5d ee ff               	call	0x46ddb0 <.text+0x6cdb0>
  588023: f3 0f 10 4d a4               	movss	xmm1, dword ptr [ebp - 0x5c]
  588028: d9 5d b8                     	fstp	dword ptr [ebp - 0x48]
  58802b: 83 c4 10                     	add	esp, 0x10
  58802e: f3 0f 10 45 b8               	movss	xmm0, dword ptr [ebp - 0x48]
  588033: f3 0f 5a c0                  	cvtss2sd	xmm0, xmm0
  588037: f2 0f 59 45 c0               	mulsd	xmm0, qword ptr [ebp - 0x40]
  58803c: f2 0f 5a c0                  	cvtsd2ss	xmm0, xmm0
  588040: f3 0f 5a c0                  	cvtss2sd	xmm0, xmm0
  588044: 66 0f ef d2                  	pxor	xmm2, xmm2
  588048: 66 0f 2f c2                  	comisd	xmm0, xmm2
  58804c: 76 71                        	jbe	0x5880bf <.text+0x1870bf>
  58804e: f3 0f 5a d9                  	cvtss2sd	xmm3, xmm1
  588052: f2 0f 10 15 c0 49 c3 00      	movsd	xmm2, qword ptr [0xc349c0]
  58805a: 66 0f 2f d3                  	comisd	xmm2, xmm3
  58805e: 76 5f                        	jbe	0x5880bf <.text+0x1870bf>
  588060: f2 0f 11 85 48 ff ff ff      	movsd	qword ptr [ebp - 0xb8], xmm0
  588068: b8 0a d7 23 3d               	mov	eax, 0x3d23d70a
  58806d: 83 c4 f0                     	add	esp, -0x10
  588070: f3 0f 11 4c 24 08            	movss	dword ptr [esp + 0x8], xmm1
  588076: ba 33 33 33 3f               	mov	edx, 0x3f333333
  58807b: 89 04 24                     	mov	dword ptr [esp], eax
  58807e: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  588082: b9 00 00 80 3f               	mov	ecx, 0x3f800000
  588087: 89 4c 24 0c                  	mov	dword ptr [esp + 0xc], ecx
  58808b: e8 20 5d ee ff               	call	0x46ddb0 <.text+0x6cdb0>
  588090: f2 0f 10 85 48 ff ff ff      	movsd	xmm0, qword ptr [ebp - 0xb8]
  588098: d9 5d b8                     	fstp	dword ptr [ebp - 0x48]
  58809b: 83 c4 10                     	add	esp, 0x10
  58809e: f3 0f 10 4d b8               	movss	xmm1, dword ptr [ebp - 0x48]
  5880a3: f3 0f 5a d1                  	cvtss2sd	xmm2, xmm1
  5880a7: f2 0f 10 0d c8 49 c3 00      	movsd	xmm1, qword ptr [0xc349c8]
  5880af: f2 0f 5e d1                  	divsd	xmm2, xmm1
  5880b3: f2 0f 59 c2                  	mulsd	xmm0, xmm2
  5880b7: f2 0f 5a c0                  	cvtsd2ss	xmm0, xmm0
  5880bb: f3 0f 5a c0                  	cvtss2sd	xmm0, xmm0
  5880bf: 66 0f ef c9                  	pxor	xmm1, xmm1
  5880c3: 66 0f 2f c8                  	comisd	xmm1, xmm0
  5880c7: 0f 83 4a 06 00 00            	jae	0x588717 <.text+0x187717>
  5880cd: f2 0f 11 85 48 ff ff ff      	movsd	qword ptr [ebp - 0xb8], xmm0
  5880d5: ff 15 04 59 c2 00            	call	dword ptr [0xc25904]
  5880db: f2 0f 5a 4d 80               	cvtsd2ss	xmm1, qword ptr [ebp - 0x80]
  5880e0: f2 0f 5a 55 88               	cvtsd2ss	xmm2, qword ptr [ebp - 0x78]
  5880e5: f2 0f 5a 5d 90               	cvtsd2ss	xmm3, qword ptr [ebp - 0x70]
  5880ea: 83 c4 f4                     	add	esp, -0xc
  5880ed: f3 0f 11 0c 24               	movss	dword ptr [esp], xmm1
  5880f2: f3 0f 11 54 24 04            	movss	dword ptr [esp + 0x4], xmm2
  5880f8: f3 0f 11 5c 24 08            	movss	dword ptr [esp + 0x8], xmm3
  5880fe: ff 15 4c 59 c2 00            	call	dword ptr [0xc2594c]
  588104: f2 0f 10 85 48 ff ff ff      	movsd	xmm0, qword ptr [ebp - 0xb8]
  58810c: f2 0f 5a c8                  	cvtsd2ss	xmm1, xmm0
  588110: 8b 45 d8                     	mov	eax, dword ptr [ebp - 0x28]
  588113: f3 0f 11 8d 6c ff ff ff      	movss	dword ptr [ebp - 0x94], xmm1
  58811b: ff 70 34                     	push	dword ptr [eax + 0x34]
  58811e: b9 60 75 10 01               	mov	ecx, 0x1107560
  588123: 6a 08                        	push	0x8
  588125: e8 16 bb fd ff               	call	0x563c40 <.text+0x162c40>
  58812a: f2 0f 10 85 48 ff ff ff      	movsd	xmm0, qword ptr [ebp - 0xb8]
  588132: 0f b6 c0                     	movzx	eax, al
  588135: 85 c0                        	test	eax, eax
  588137: 75 0f                        	jne	0x588148 <.text+0x187148>
  588139: 8d 85 60 ff ff ff            	lea	eax, [ebp - 0xa0]
  58813f: 50                           	push	eax
  588140: ff 15 58 59 c2 00            	call	dword ptr [0xc25958]
  588146: eb 19                        	jmp	0x588161 <.text+0x187161>
  588148: f2 0f 5a c0                  	cvtsd2ss	xmm0, xmm0
  58814c: f3 0f 11 85 7c ff ff ff      	movss	dword ptr [ebp - 0x84], xmm0
  588154: 8d 85 70 ff ff ff            	lea	eax, [ebp - 0x90]
  58815a: 50                           	push	eax
  58815b: ff 15 58 59 c2 00            	call	dword ptr [0xc25958]
  588161: 8b 45 d8                     	mov	eax, dword ptr [ebp - 0x28]
  588164: f3 0f 5a 40 40               	cvtss2sd	xmm0, dword ptr [eax + 0x40]
  588169: f2 0f 59 05 b0 49 c3 00      	mulsd	xmm0, qword ptr [0xc349b0]
  588171: f2 0f 5a c8                  	cvtsd2ss	xmm1, xmm0
  588175: f3 0f 10 25 40 73 10 01      	movss	xmm4, dword ptr [0x1107340]
  58817d: f3 0f 5a d1                  	cvtss2sd	xmm2, xmm1
