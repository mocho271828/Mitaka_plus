
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  582ce0: 53                           	push	ebx
  582ce1: 8b dc                        	mov	ebx, esp
  582ce3: 83 e4 f8                     	and	esp, -0x8
  582ce6: 55                           	push	ebp
  582ce7: 55                           	push	ebp
  582ce8: 8b 6b 04                     	mov	ebp, dword ptr [ebx + 0x4]
  582ceb: 89 6c 24 04                  	mov	dword ptr [esp + 0x4], ebp
  582cef: 8b ec                        	mov	ebp, esp
  582cf1: 6a ff                        	push	-0x1
  582cf3: 68 e0 a2 bf 00               	push	0xbfa2e0
  582cf8: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  582cfe: 50                           	push	eax
  582cff: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  582d06: 81 ec 84 00 00 00            	sub	esp, 0x84
  582d0c: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  582d0f: 89 7d 9c                     	mov	dword ptr [ebp - 0x64], edi
  582d12: 89 75 b8                     	mov	dword ptr [ebp - 0x48], esi
  582d15: 8b 7b 08                     	mov	edi, dword ptr [ebx + 0x8]
  582d18: f2 0f 5a 47 68               	cvtsd2ss	xmm0, qword ptr [edi + 0x68]
  582d1d: 0f 2f 05 a0 4b c3 00         	comiss	xmm0, dword ptr [0xc34ba0]
  582d24: 89 4d e4                     	mov	dword ptr [ebp - 0x1c], ecx
  582d27: 77 0f                        	ja	0x582d38 <.text+0x181d38>
  582d29: f3 0f 10 05 bc 4b c3 00      	movss	xmm0, dword ptr [0xc34bbc]
  582d31: f3 0f 11 45 c4               	movss	dword ptr [ebp - 0x3c], xmm0
  582d36: eb 26                        	jmp	0x582d5e <.text+0x181d5e>
  582d38: f3 0f 5e 05 a0 4b c3 00      	divss	xmm0, dword ptr [0xc34ba0]
  582d40: e8 2b c1 50 00               	call	0xa8ee70 <.text+0x68de70>
  582d45: f3 0f 59 05 a4 4b c3 00      	mulss	xmm0, dword ptr [0xc34ba4]
  582d4d: f3 0f 59 c0                  	mulss	xmm0, xmm0
  582d51: f3 0f 58 05 bc 4b c3 00      	addss	xmm0, dword ptr [0xc34bbc]
  582d59: f3 0f 11 45 c4               	movss	dword ptr [ebp - 0x3c], xmm0
  582d5e: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  582d65: f3 0f 10 45 c4               	movss	xmm0, dword ptr [ebp - 0x3c]
  582d6a: f3 0f 59 05 a8 4b c3 00      	mulss	xmm0, dword ptr [0xc34ba8]
  582d72: f3 0f 5e 05 ac 79 10 01      	divss	xmm0, dword ptr [0x11079ac]
  582d7a: f3 0f 5e 43 0c               	divss	xmm0, dword ptr [ebx + 0xc]
  582d7f: 8b 87 38 01 00 00            	mov	eax, dword ptr [edi + 0x138]
  582d85: 8b 97 3c 01 00 00            	mov	edx, dword ptr [edi + 0x13c]
  582d8b: 8b 8f 40 01 00 00            	mov	ecx, dword ptr [edi + 0x140]
  582d91: 8b b7 44 01 00 00            	mov	esi, dword ptr [edi + 0x144]
  582d97: f3 0f 10 8f 10 02 00 00      	movss	xmm1, dword ptr [edi + 0x210]
  582d9f: f3 0f 10 97 14 02 00 00      	movss	xmm2, dword ptr [edi + 0x214]
  582da7: f3 0f 10 9f 18 02 00 00      	movss	xmm3, dword ptr [edi + 0x218]
  582daf: f3 0f 10 a7 1c 02 00 00      	movss	xmm4, dword ptr [edi + 0x21c]
  582db7: f3 0f 10 af 20 02 00 00      	movss	xmm5, dword ptr [edi + 0x220]
  582dbf: f3 0f 10 b7 24 02 00 00      	movss	xmm6, dword ptr [edi + 0x224]
  582dc7: f3 0f 11 45 c4               	movss	dword ptr [ebp - 0x3c], xmm0
  582dcc: f3 0f 11 4d d8               	movss	dword ptr [ebp - 0x28], xmm1
  582dd1: f3 0f 11 55 d4               	movss	dword ptr [ebp - 0x2c], xmm2
  582dd6: f3 0f 11 5d d0               	movss	dword ptr [ebp - 0x30], xmm3
  582ddb: f3 0f 11 65 cc               	movss	dword ptr [ebp - 0x34], xmm4
  582de0: f3 0f 11 6d dc               	movss	dword ptr [ebp - 0x24], xmm5
  582de5: f3 0f 11 75 c8               	movss	dword ptr [ebp - 0x38], xmm6
  582dea: 89 85 70 ff ff ff            	mov	dword ptr [ebp - 0x90], eax
  582df0: 8b 87 48 01 00 00            	mov	eax, dword ptr [edi + 0x148]
  582df6: 89 95 74 ff ff ff            	mov	dword ptr [ebp - 0x8c], edx
  582dfc: 8b 97 4c 01 00 00            	mov	edx, dword ptr [edi + 0x14c]
  582e02: 89 8d 78 ff ff ff            	mov	dword ptr [ebp - 0x88], ecx
  582e08: 89 b5 7c ff ff ff            	mov	dword ptr [ebp - 0x84], esi
  582e0e: 89 45 80                     	mov	dword ptr [ebp - 0x80], eax
  582e11: 89 55 84                     	mov	dword ptr [ebp - 0x7c], edx
  582e14: e8 97 d8 fd ff               	call	0x5606b0 <.text+0x15f6b0>
  582e19: d9 5d 88                     	fstp	dword ptr [ebp - 0x78]
  582e1c: f3 0f 10 55 88               	movss	xmm2, dword ptr [ebp - 0x78]
  582e21: f3 0f 59 d2                  	mulss	xmm2, xmm2
  582e25: 0f b6 05 1c 79 10 01         	movzx	eax, byte ptr [0x110791c]
  582e2c: a8 01                        	test	al, 0x1
  582e2e: 75 08                        	jne	0x582e38 <.text+0x181e38>
  582e30: 83 c8 01                     	or	eax, 0x1
  582e33: a2 1c 79 10 01               	mov	byte ptr [0x110791c], al
  582e38: 0f b6 05 68 0e d7 00         	movzx	eax, byte ptr [0xd70e68]
  582e3f: f2 0f 10 8d 70 ff ff ff      	movsd	xmm1, qword ptr [ebp - 0x90]
  582e47: f2 0f 10 05 00 79 10 01      	movsd	xmm0, qword ptr [0x1107900]
  582e4f: f2 0f 11 4d a0               	movsd	qword ptr [ebp - 0x60], xmm1
  582e54: 66 0f 2e c1                  	ucomisd	xmm0, xmm1
  582e58: 89 45 e8                     	mov	dword ptr [ebp - 0x18], eax
  582e5b: 7a 06                        	jp	0x582e63 <.text+0x181e63>
  582e5d: 0f 84 fa 06 00 00            	je	0x58355d <.text+0x18255d>
  582e63: c7 45 e8 01 00 00 00         	mov	dword ptr [ebp - 0x18], 0x1
  582e6a: 8b 85 70 ff ff ff            	mov	eax, dword ptr [ebp - 0x90]
  582e70: 8b 95 74 ff ff ff            	mov	edx, dword ptr [ebp - 0x8c]
  582e76: 8b 8d 78 ff ff ff            	mov	ecx, dword ptr [ebp - 0x88]
  582e7c: 8b b5 7c ff ff ff            	mov	esi, dword ptr [ebp - 0x84]
  582e82: f3 0f 10 45 c4               	movss	xmm0, dword ptr [ebp - 0x3c]
  582e87: f3 0f 11 05 18 79 10 01      	movss	dword ptr [0x1107918], xmm0
  582e8f: a3 00 79 10 01               	mov	dword ptr [0x1107900], eax
  582e94: 8b 45 80                     	mov	eax, dword ptr [ebp - 0x80]
  582e97: 89 15 04 79 10 01            	mov	dword ptr [0x1107904], edx
  582e9d: 8b 55 84                     	mov	edx, dword ptr [ebp - 0x7c]
  582ea0: 89 0d 08 79 10 01            	mov	dword ptr [0x1107908], ecx
  582ea6: 8b 4d e4                     	mov	ecx, dword ptr [ebp - 0x1c]
  582ea9: 89 35 0c 79 10 01            	mov	dword ptr [0x110790c], esi
  582eaf: 8b 71 68                     	mov	esi, dword ptr [ecx + 0x68]
  582eb2: 85 f6                        	test	esi, esi
  582eb4: a3 10 79 10 01               	mov	dword ptr [0x1107910], eax
  582eb9: 89 15 14 79 10 01            	mov	dword ptr [0x1107914], edx
  582ebf: 0f 84 71 06 00 00            	je	0x583536 <.text+0x182536>
  582ec5: f2 0f 10 85 78 ff ff ff      	movsd	xmm0, qword ptr [ebp - 0x88]
  582ecd: f2 0f 10 4d 80               	movsd	xmm1, qword ptr [ebp - 0x80]
  582ed2: f2 0f 11 45 b0               	movsd	qword ptr [ebp - 0x50], xmm0
  582ed7: f2 0f 11 4d a8               	movsd	qword ptr [ebp - 0x58], xmm1
  582edc: 66 0f ef db                  	pxor	xmm3, xmm3
  582ee0: f3 0f 11 5d bc               	movss	dword ptr [ebp - 0x44], xmm3
  582ee5: 66 0f ef e4                  	pxor	xmm4, xmm4
  582ee9: f3 0f 11 65 c0               	movss	dword ptr [ebp - 0x40], xmm4
  582eee: 83 7d e8 00                  	cmp	dword ptr [ebp - 0x18], 0x0
  582ef2: 8b 45 e4                     	mov	eax, dword ptr [ebp - 0x1c]
  582ef5: f3 0f 10 48 74               	movss	xmm1, dword ptr [eax + 0x74]
  582efa: 0f 84 db 04 00 00            	je	0x5833db <.text+0x1823db>
  582f00: f2 0f 10 46 08               	movsd	xmm0, qword ptr [esi + 0x8]
  582f05: f2 0f 5c 45 a0               	subsd	xmm0, qword ptr [ebp - 0x60]
  582f0a: f2 0f 10 5e 10               	movsd	xmm3, qword ptr [esi + 0x10]
  582f0f: f2 0f 5c 5d b0               	subsd	xmm3, qword ptr [ebp - 0x50]
  582f14: f2 0f 10 66 18               	movsd	xmm4, qword ptr [esi + 0x18]
  582f19: f2 0f 5c 65 a8               	subsd	xmm4, qword ptr [ebp - 0x58]
  582f1e: f2 0f 11 85 70 ff ff ff      	movsd	qword ptr [ebp - 0x90], xmm0
  582f26: 8b 85 70 ff ff ff            	mov	eax, dword ptr [ebp - 0x90]
  582f2c: 8b 95 74 ff ff ff            	mov	edx, dword ptr [ebp - 0x8c]
  582f32: f2 0f 11 9d 78 ff ff ff      	movsd	qword ptr [ebp - 0x88], xmm3
  582f3a: 8b 8d 78 ff ff ff            	mov	ecx, dword ptr [ebp - 0x88]
  582f40: f2 0f 11 65 80               	movsd	qword ptr [ebp - 0x80], xmm4
  582f45: 89 86 98 00 00 00            	mov	dword ptr [esi + 0x98], eax
  582f4b: 8b 85 7c ff ff ff            	mov	eax, dword ptr [ebp - 0x84]
  582f51: 89 96 9c 00 00 00            	mov	dword ptr [esi + 0x9c], edx
  582f57: 8b 55 80                     	mov	edx, dword ptr [ebp - 0x80]
  582f5a: f2 0f 10 be 98 00 00 00      	movsd	xmm7, qword ptr [esi + 0x98]
  582f62: f2 0f 59 ff                  	mulsd	xmm7, xmm7
  582f66: 89 8e a0 00 00 00            	mov	dword ptr [esi + 0xa0], ecx
  582f6c: 8b 4d 84                     	mov	ecx, dword ptr [ebp - 0x7c]
  582f6f: 89 86 a4 00 00 00            	mov	dword ptr [esi + 0xa4], eax
  582f75: f2 0f 10 ae a0 00 00 00      	movsd	xmm5, qword ptr [esi + 0xa0]
  582f7d: f2 0f 59 ed                  	mulsd	xmm5, xmm5
  582f81: 89 96 a8 00 00 00            	mov	dword ptr [esi + 0xa8], edx
  582f87: 89 8e ac 00 00 00            	mov	dword ptr [esi + 0xac], ecx
  582f8d: f2 0f 10 b6 a8 00 00 00      	movsd	xmm6, qword ptr [esi + 0xa8]
  582f95: f2 0f 59 f6                  	mulsd	xmm6, xmm6
  582f99: f2 0f 58 fd                  	addsd	xmm7, xmm5
  582f9d: f2 0f 58 fe                  	addsd	xmm7, xmm6
  582fa1: f2 0f 5a c7                  	cvtsd2ss	xmm0, xmm7
  582fa5: f3 0f 11 86 b0 00 00 00      	movss	dword ptr [esi + 0xb0], xmm0
  582fad: 0f 2f c2                     	comiss	xmm0, xmm2
  582fb0: 76 4b                        	jbe	0x582ffd <.text+0x181ffd>
  582fb2: 0f 28 da                     	movaps	xmm3, xmm2
  582fb5: f3 0f 5e d8                  	divss	xmm3, xmm0
  582fb9: f3 0f 51 c3                  	sqrtss	xmm0, xmm3
  582fbd: f3 0f 5a f0                  	cvtss2sd	xmm6, xmm0
  582fc1: f2 0f 10 a6 98 00 00 00      	movsd	xmm4, qword ptr [esi + 0x98]
  582fc9: f2 0f 59 e6                  	mulsd	xmm4, xmm6
  582fcd: f2 0f 10 ae a0 00 00 00      	movsd	xmm5, qword ptr [esi + 0xa0]
  582fd5: f2 0f 10 be a8 00 00 00      	movsd	xmm7, qword ptr [esi + 0xa8]
  582fdd: f2 0f 11 a6 98 00 00 00      	movsd	qword ptr [esi + 0x98], xmm4
  582fe5: f2 0f 59 ee                  	mulsd	xmm5, xmm6
  582fe9: f2 0f 11 ae a0 00 00 00      	movsd	qword ptr [esi + 0xa0], xmm5
  582ff1: f2 0f 59 fe                  	mulsd	xmm7, xmm6
  582ff5: f2 0f 11 be a8 00 00 00      	movsd	qword ptr [esi + 0xa8], xmm7
  582ffd: 83 3d a8 99 10 01 00         	cmp	dword ptr [0x11099a8], 0x0
  583004: 75 47                        	jne	0x58304d <.text+0x18204d>
  583006: f3 0f 10 46 2c               	movss	xmm0, dword ptr [esi + 0x2c]
  58300b: f3 0f 59 45 c4               	mulss	xmm0, dword ptr [ebp - 0x3c]
  583010: f3 0f 5e 86 b0 00 00 00      	divss	xmm0, dword ptr [esi + 0xb0]
  583018: 0f 2f 05 bc 4b c3 00         	comiss	xmm0, dword ptr [0xc34bbc]
  58301f: f3 0f 11 46 3c               	movss	dword ptr [esi + 0x3c], xmm0
  583024: 76 19                        	jbe	0x58303f <.text+0x18203f>
  583026: f3 0f 11 55 98               	movss	dword ptr [ebp - 0x68], xmm2
  58302b: e8 28 be 50 00               	call	0xa8ee58 <.text+0x68de58>
  583030: f3 0f 10 55 98               	movss	xmm2, dword ptr [ebp - 0x68]
  583035: f3 0f 11 46 40               	movss	dword ptr [esi + 0x40], xmm0
  58303a: e9 9c 03 00 00               	jmp	0x5833db <.text+0x1823db>
  58303f: f3 0f 51 c0                  	sqrtss	xmm0, xmm0
  583043: f3 0f 11 46 40               	movss	dword ptr [esi + 0x40], xmm0
  583048: e9 8e 03 00 00               	jmp	0x5833db <.text+0x1823db>
  58304d: f3 0f 10 46 44               	movss	xmm0, dword ptr [esi + 0x44]
  583052: f3 0f 10 5e 28               	movss	xmm3, dword ptr [esi + 0x28]
  583057: f3 0f 11 45 88               	movss	dword ptr [ebp - 0x78], xmm0
  58305c: f3 0f 10 05 ac 79 10 01      	movss	xmm0, dword ptr [0x11079ac]
  583064: 66 0f ef c9                  	pxor	xmm1, xmm1
  583068: 0f 2e c1                     	ucomiss	xmm0, xmm1
  58306b: 7a 02                        	jp	0x58306f <.text+0x18206f>
  58306d: 74 2f                        	je	0x58309e <.text+0x18209e>
  58306f: f3 0f 5a eb                  	cvtss2sd	xmm5, xmm3
  583073: f3 0f 5a e0                  	cvtss2sd	xmm4, xmm0
  583077: f2 0f 10 05 e8 48 c3 00      	movsd	xmm0, qword ptr [0xc348e8]
  58307f: 0f 28 d8                     	movaps	xmm3, xmm0
  583082: f2 0f 10 0d e0 48 c3 00      	movsd	xmm1, qword ptr [0xc348e0]
  58308a: f2 0f 5c e0                  	subsd	xmm4, xmm0
  58308e: f2 0f 5e e1                  	divsd	xmm4, xmm1
  583092: f2 0f 58 e3                  	addsd	xmm4, xmm3
  583096: f2 0f 59 ec                  	mulsd	xmm5, xmm4
  58309a: f2 0f 5a dd                  	cvtsd2ss	xmm3, xmm5
  58309e: f3 0f 10 05 ac 4b c3 00      	movss	xmm0, dword ptr [0xc34bac]
  5830a6: f3 0f 11 55 98               	movss	dword ptr [ebp - 0x68], xmm2
  5830ab: 66 0f ef c9                  	pxor	xmm1, xmm1
  5830af: f3 0f 5c cb                  	subss	xmm1, xmm3
  5830b3: f3 0f 10 1d b0 4b c3 00      	movss	xmm3, dword ptr [0xc34bb0]
  5830bb: f3 0f 5e cb                  	divss	xmm1, xmm3
  5830bf: e8 94 bd 50 00               	call	0xa8ee58 <.text+0x68de58>
  5830c4: f3 0f 10 1d 20 1e d7 00      	movss	xmm3, dword ptr [0xd71e20]
  5830cc: f3 0f 59 db                  	mulss	xmm3, xmm3
  5830d0: f3 0f 11 5d 8c               	movss	dword ptr [ebp - 0x74], xmm3
  5830d5: f3 0f 59 c3                  	mulss	xmm0, xmm3
  5830d9: f3 0f 11 45 90               	movss	dword ptr [ebp - 0x70], xmm0
  5830de: f3 0f 10 05 ac 4b c3 00      	movss	xmm0, dword ptr [0xc34bac]
  5830e6: 66 0f ef c9                  	pxor	xmm1, xmm1
  5830ea: f3 0f 5c 0d 1c 1e d7 00      	subss	xmm1, dword ptr [0xd71e1c]
  5830f2: f3 0f 5e 0d b0 4b c3 00      	divss	xmm1, dword ptr [0xc34bb0]
  5830fa: e8 59 bd 50 00               	call	0xa8ee58 <.text+0x68de58>
  5830ff: f3 0f 10 55 98               	movss	xmm2, dword ptr [ebp - 0x68]
  583104: f3 0f 10 4d 8c               	movss	xmm1, dword ptr [ebp - 0x74]
  583109: f3 0f 59 c8                  	mulss	xmm1, xmm0
  58310d: f3 0f 10 6d 90               	movss	xmm5, dword ptr [ebp - 0x70]
  583112: 0f 2f cd                     	comiss	xmm1, xmm5
  583115: f3 0f 10 1d b8 4b c3 00      	movss	xmm3, dword ptr [0xc34bb8]
  58311d: f3 0f 10 65 88               	movss	xmm4, dword ptr [ebp - 0x78]
  583122: 76 03                        	jbe	0x583127 <.text+0x182127>
  583124: 0f 28 e3                     	movaps	xmm4, xmm3
  583127: f3 0f 5c 25 a0 4b c3 00      	subss	xmm4, dword ptr [0xc34ba0]
  58312f: f3 0f 5e 25 ac 4b c3 00      	divss	xmm4, dword ptr [0xc34bac]
  583137: f3 0f 2c c4                  	cvttss2si	eax, xmm4
  58313b: 3d cd 00 00 00               	cmp	eax, 0xcd
  583140: 7c 05                        	jl	0x583147 <.text+0x182147>
  583142: b8 cd 00 00 00               	mov	eax, 0xcd
  583147: f3 0f 5e 2c 85 a0 83 10 01   	divss	xmm5, dword ptr [4*eax + 0x11083a0]
  583150: 0f 2f 2d bc 4b c3 00         	comiss	xmm5, dword ptr [0xc34bbc]
  583157: 89 45 94                     	mov	dword ptr [ebp - 0x6c], eax
  58315a: 0f 86 21 01 00 00            	jbe	0x583281 <.text+0x182281>
  583160: f3 0f 51 c5                  	sqrtss	xmm0, xmm5
  583164: f3 0f 11 46 40               	movss	dword ptr [esi + 0x40], xmm0
  583169: 66 0f ef c9                  	pxor	xmm1, xmm1
  58316d: f3 0f 10 04 85 a0 83 10 01   	movss	xmm0, dword ptr [4*eax + 0x11083a0]
  583176: 0f 2f c8                     	comiss	xmm1, xmm0
  583179: 76 0e                        	jbe	0x583189 <.text+0x182189>
  58317b: 66 0f ef c0                  	pxor	xmm0, xmm0
  58317f: f3 0f 11 45 bc               	movss	dword ptr [ebp - 0x44], xmm0
  583184: e9 a7 00 00 00               	jmp	0x583230 <.text+0x182230>
  583189: f3 0f 5a d8                  	cvtss2sd	xmm3, xmm0
  58318d: f2 0f 10 0d b8 48 c3 00      	movsd	xmm1, qword ptr [0xc348b8]
  583195: 66 0f 2f cb                  	comisd	xmm1, xmm3
  583199: 72 16                        	jb	0x5831b1 <.text+0x1821b1>
  58319b: f2 0f 59 1d d8 48 c3 00      	mulsd	xmm3, qword ptr [0xc348d8]
  5831a3: f2 0f 5a c3                  	cvtsd2ss	xmm0, xmm3
  5831a7: f3 0f 11 45 bc               	movss	dword ptr [ebp - 0x44], xmm0
  5831ac: e9 7f 00 00 00               	jmp	0x583230 <.text+0x182230>
  5831b1: f2 0f 10 0d b8 48 c3 00      	movsd	xmm1, qword ptr [0xc348b8]
  5831b9: 66 0f 2f d9                  	comisd	xmm3, xmm1
  5831bd: 76 71                        	jbe	0x583230 <.text+0x182230>
  5831bf: f3 0f 10 0d b0 4b c3 00      	movss	xmm1, dword ptr [0xc34bb0]
  5831c7: 0f 2f c8                     	comiss	xmm1, xmm0
  5831ca: 76 30                        	jbe	0x5831fc <.text+0x1821fc>
  5831cc: f2 0f 5e 1d d0 48 c3 00      	divsd	xmm3, qword ptr [0xc348d0]
  5831d4: f2 0f 2c c3                  	cvttsd2si	eax, xmm3
  5831d8: f3 0f 5a 04 85 e0 86 10 01   	cvtss2sd	xmm0, dword ptr [4*eax + 0x11086e0]
  5831e1: f2 0f 59 05 c0 48 c3 00      	mulsd	xmm0, qword ptr [0xc348c0]
  5831e9: f2 0f 5c 05 c8 48 c3 00      	subsd	xmm0, qword ptr [0xc348c8]
  5831f1: f2 0f 5a c8                  	cvtsd2ss	xmm1, xmm0
  5831f5: f3 0f 11 4d bc               	movss	dword ptr [ebp - 0x44], xmm1
  5831fa: eb 34                        	jmp	0x583230 <.text+0x182230>
  5831fc: f3 0f 10 0d b4 4b c3 00      	movss	xmm1, dword ptr [0xc34bb4]
  583204: f3 0f 11 55 98               	movss	dword ptr [ebp - 0x68], xmm2
  583209: e8 4a bc 50 00               	call	0xa8ee58 <.text+0x68de58>
  58320e: f3 0f 5a c8                  	cvtss2sd	xmm1, xmm0
  583212: f2 0f 59 0d c0 48 c3 00      	mulsd	xmm1, qword ptr [0xc348c0]
  58321a: f2 0f 5c 0d c8 48 c3 00      	subsd	xmm1, qword ptr [0xc348c8]
  583222: f2 0f 5a d9                  	cvtsd2ss	xmm3, xmm1
  583226: f3 0f 10 55 98               	movss	xmm2, dword ptr [ebp - 0x68]
  58322b: f3 0f 11 5d bc               	movss	dword ptr [ebp - 0x44], xmm3
  583230: 8b 55 94                     	mov	edx, dword ptr [ebp - 0x6c]
  583233: f3 0f 10 5d bc               	movss	xmm3, dword ptr [ebp - 0x44]
  583238: 8d 04 d5 00 00 00 00         	lea	eax, [8*edx]
  58323f: f3 0f 10 84 90 e0 79 10 01   	movss	xmm0, dword ptr [eax + 4*edx + 0x11079e0]
  583248: f3 0f 59 c3                  	mulss	xmm0, xmm3
  58324c: f3 0f 11 46 48               	movss	dword ptr [esi + 0x48], xmm0
  583251: f3 0f 10 8c 90 e4 79 10 01   	movss	xmm1, dword ptr [eax + 4*edx + 0x11079e4]
  58325a: f3 0f 59 cb                  	mulss	xmm1, xmm3
  58325e: f3 0f 11 4e 4c               	movss	dword ptr [esi + 0x4c], xmm1
  583263: f3 0f 10 a4 90 e8 79 10 01   	movss	xmm4, dword ptr [eax + 4*edx + 0x11079e8]
  58326c: f3 0f 59 e3                  	mulss	xmm4, xmm3
  583270: c7 46 54 00 00 80 3f         	mov	dword ptr [esi + 0x54], 0x3f800000
  583277: f3 0f 11 66 50               	movss	dword ptr [esi + 0x50], xmm4
  58327c: e9 19 01 00 00               	jmp	0x58339a <.text+0x18239a>
  583281: c7 46 40 00 00 80 3f         	mov	dword ptr [esi + 0x40], 0x3f800000
  583288: 66 0f ef c0                  	pxor	xmm0, xmm0
  58328c: 0f 2f 45 90                  	comiss	xmm0, dword ptr [ebp - 0x70]
  583290: 76 0e                        	jbe	0x5832a0 <.text+0x1822a0>
  583292: 66 0f ef c0                  	pxor	xmm0, xmm0
  583296: f3 0f 11 45 c0               	movss	dword ptr [ebp - 0x40], xmm0
  58329b: e9 ae 00 00 00               	jmp	0x58334e <.text+0x18234e>
  5832a0: f3 0f 5a 4d 90               	cvtss2sd	xmm1, dword ptr [ebp - 0x70]
  5832a5: f2 0f 10 05 b8 48 c3 00      	movsd	xmm0, qword ptr [0xc348b8]
  5832ad: 66 0f 2f c1                  	comisd	xmm0, xmm1
  5832b1: 72 16                        	jb	0x5832c9 <.text+0x1822c9>
  5832b3: f2 0f 59 0d d8 48 c3 00      	mulsd	xmm1, qword ptr [0xc348d8]
  5832bb: f2 0f 5a c1                  	cvtsd2ss	xmm0, xmm1
  5832bf: f3 0f 11 45 c0               	movss	dword ptr [ebp - 0x40], xmm0
  5832c4: e9 85 00 00 00               	jmp	0x58334e <.text+0x18234e>
  5832c9: f2 0f 10 05 b8 48 c3 00      	movsd	xmm0, qword ptr [0xc348b8]
  5832d1: 66 0f 2f c8                  	comisd	xmm1, xmm0
  5832d5: 76 77                        	jbe	0x58334e <.text+0x18234e>
  5832d7: f3 0f 10 05 b0 4b c3 00      	movss	xmm0, dword ptr [0xc34bb0]
  5832df: 0f 2f 45 90                  	comiss	xmm0, dword ptr [ebp - 0x70]
  5832e3: 76 30                        	jbe	0x583315 <.text+0x182315>
  5832e5: f2 0f 5e 0d d0 48 c3 00      	divsd	xmm1, qword ptr [0xc348d0]
  5832ed: f2 0f 2c c1                  	cvttsd2si	eax, xmm1
  5832f1: f3 0f 5a 04 85 e0 86 10 01   	cvtss2sd	xmm0, dword ptr [4*eax + 0x11086e0]
  5832fa: f2 0f 59 05 c0 48 c3 00      	mulsd	xmm0, qword ptr [0xc348c0]
  583302: f2 0f 5c 05 c8 48 c3 00      	subsd	xmm0, qword ptr [0xc348c8]
  58330a: f2 0f 5a c8                  	cvtsd2ss	xmm1, xmm0
  58330e: f3 0f 11 4d c0               	movss	dword ptr [ebp - 0x40], xmm1
  583313: eb 39                        	jmp	0x58334e <.text+0x18234e>
  583315: f3 0f 10 45 90               	movss	xmm0, dword ptr [ebp - 0x70]
  58331a: f3 0f 10 0d b4 4b c3 00      	movss	xmm1, dword ptr [0xc34bb4]
  583322: f3 0f 11 55 98               	movss	dword ptr [ebp - 0x68], xmm2
  583327: e8 2c bb 50 00               	call	0xa8ee58 <.text+0x68de58>
  58332c: f3 0f 5a c8                  	cvtss2sd	xmm1, xmm0
  583330: f2 0f 59 0d c0 48 c3 00      	mulsd	xmm1, qword ptr [0xc348c0]
  583338: f2 0f 5c 0d c8 48 c3 00      	subsd	xmm1, qword ptr [0xc348c8]
  583340: f2 0f 5a d9                  	cvtsd2ss	xmm3, xmm1
  583344: f3 0f 10 55 98               	movss	xmm2, dword ptr [ebp - 0x68]
  583349: f3 0f 11 5d c0               	movss	dword ptr [ebp - 0x40], xmm3
  58334e: 8b 55 94                     	mov	edx, dword ptr [ebp - 0x6c]
  583351: f3 0f 10 5d c0               	movss	xmm3, dword ptr [ebp - 0x40]
  583356: 8d 04 d5 00 00 00 00         	lea	eax, [8*edx]
  58335d: f3 0f 10 84 90 e0 79 10 01   	movss	xmm0, dword ptr [eax + 4*edx + 0x11079e0]
  583366: f3 0f 59 c3                  	mulss	xmm0, xmm3
  58336a: f3 0f 11 46 48               	movss	dword ptr [esi + 0x48], xmm0
  58336f: f3 0f 10 8c 90 e4 79 10 01   	movss	xmm1, dword ptr [eax + 4*edx + 0x11079e4]
  583378: f3 0f 59 cb                  	mulss	xmm1, xmm3
  58337c: f3 0f 11 4e 4c               	movss	dword ptr [esi + 0x4c], xmm1
  583381: f3 0f 10 a4 90 e8 79 10 01   	movss	xmm4, dword ptr [eax + 4*edx + 0x11079e8]
  58338a: f3 0f 59 e3                  	mulss	xmm4, xmm3
  58338e: c7 46 54 00 00 80 3f         	mov	dword ptr [esi + 0x54], 0x3f800000
  583395: f3 0f 11 66 50               	movss	dword ptr [esi + 0x50], xmm4
  58339a: f3 0f 5a 9e b0 00 00 00      	cvtss2sd	xmm3, dword ptr [esi + 0xb0]
  5833a2: f2 0f 10 46 10               	movsd	xmm0, qword ptr [esi + 0x10]
  5833a7: f2 0f 59 c0                  	mulsd	xmm0, xmm0
  5833ab: f2 0f 10 4e 18               	movsd	xmm1, qword ptr [esi + 0x18]
  5833b0: f2 0f 59 c9                  	mulsd	xmm1, xmm1
  5833b4: f2 0f 10 66 08               	movsd	xmm4, qword ptr [esi + 0x8]
  5833b9: f2 0f 59 e4                  	mulsd	xmm4, xmm4
  5833bd: f2 0f 58 e0                  	addsd	xmm4, xmm0
  5833c1: f2 0f 58 e1                  	addsd	xmm4, xmm1
  5833c5: f2 0f 5e e3                  	divsd	xmm4, xmm3
  5833c9: f2 0f 5a ec                  	cvtsd2ss	xmm5, xmm4
  5833cd: f3 0f 51 f5                  	sqrtss	xmm6, xmm5
  5833d1: f3 0f 59 76 40               	mulss	xmm6, dword ptr [esi + 0x40]
  5833d6: f3 0f 11 76 40               	movss	dword ptr [esi + 0x40], xmm6
  5833db: f2 0f 10 4f 08               	movsd	xmm1, qword ptr [edi + 0x8]
  5833e0: f2 0f 59 4e 08               	mulsd	xmm1, qword ptr [esi + 0x8]
  5833e5: f2 0f 10 47 10               	movsd	xmm0, qword ptr [edi + 0x10]
  5833ea: f2 0f 59 46 10               	mulsd	xmm0, qword ptr [esi + 0x10]
  5833ef: f2 0f 10 67 18               	movsd	xmm4, qword ptr [edi + 0x18]
  5833f4: f2 0f 59 66 18               	mulsd	xmm4, qword ptr [esi + 0x18]
  5833f9: f2 0f 10 5f 28               	movsd	xmm3, qword ptr [edi + 0x28]
  5833fe: f2 0f 59 5e 10               	mulsd	xmm3, qword ptr [esi + 0x10]
  583403: f2 0f 10 6f 30               	movsd	xmm5, qword ptr [edi + 0x30]
  583408: f2 0f 59 6e 18               	mulsd	xmm5, qword ptr [esi + 0x18]
  58340d: f2 0f 10 77 40               	movsd	xmm6, qword ptr [edi + 0x40]
  583412: f2 0f 59 76 10               	mulsd	xmm6, qword ptr [esi + 0x10]
  583417: f2 0f 10 7f 48               	movsd	xmm7, qword ptr [edi + 0x48]
  58341c: f2 0f 59 7e 18               	mulsd	xmm7, qword ptr [esi + 0x18]
  583421: f2 0f 58 c8                  	addsd	xmm1, xmm0
  583425: f2 0f 10 47 20               	movsd	xmm0, qword ptr [edi + 0x20]
  58342a: f2 0f 59 46 08               	mulsd	xmm0, qword ptr [esi + 0x8]
  58342f: f2 0f 58 cc                  	addsd	xmm1, xmm4
  583433: f2 0f 58 4f 50               	addsd	xmm1, qword ptr [edi + 0x50]
  583438: f2 0f 10 67 38               	movsd	xmm4, qword ptr [edi + 0x38]
  58343d: f2 0f 59 66 08               	mulsd	xmm4, qword ptr [esi + 0x8]
  583442: f2 0f 58 c3                  	addsd	xmm0, xmm3
  583446: f2 0f 58 c5                  	addsd	xmm0, xmm5
  58344a: f2 0f 58 47 58               	addsd	xmm0, qword ptr [edi + 0x58]
  58344f: f3 0f 10 2d 30 75 10 01      	movss	xmm5, dword ptr [0x1107530]
  583457: f2 0f 58 e6                  	addsd	xmm4, xmm6
  58345b: f2 0f 58 e7                  	addsd	xmm4, xmm7
  58345f: f2 0f 58 67 60               	addsd	xmm4, qword ptr [edi + 0x60]
  583464: 66 0f ef db                  	pxor	xmm3, xmm3
  583468: f2 0f 5c dc                  	subsd	xmm3, xmm4
  58346c: f2 0f 5a e3                  	cvtsd2ss	xmm4, xmm3
  583470: 0f 2f ec                     	comiss	xmm5, xmm4
  583473: 0f 87 a1 00 00 00            	ja	0x58351a <.text+0x18251a>
  583479: f2 0f 5a d9                  	cvtsd2ss	xmm3, xmm1
  58347d: f2 0f 5a c8                  	cvtsd2ss	xmm1, xmm0
  583481: 0f 28 ec                     	movaps	xmm5, xmm4
  583484: f3 0f c2 2d 34 75 10 01 01   	cmpltss	xmm5, dword ptr [0x1107534]
  58348d: f3 0f 10 45 dc               	movss	xmm0, dword ptr [ebp - 0x24]
  583492: f3 0f 59 d8                  	mulss	xmm3, xmm0
  583496: f3 0f 59 c8                  	mulss	xmm1, xmm0
  58349a: 0f 28 fb                     	movaps	xmm7, xmm3
  58349d: f3 0f 10 75 d8               	movss	xmm6, dword ptr [ebp - 0x28]
  5834a2: f3 0f 59 f4                  	mulss	xmm6, xmm4
  5834a6: b9 02 00 00 00               	mov	ecx, 0x2
  5834ab: 66 0f 7e ea                  	movd	edx, xmm5
  5834af: 0f 28 ec                     	movaps	xmm5, xmm4
  5834b2: f3 0f 59 6d d0               	mulss	xmm5, dword ptr [ebp - 0x30]
  5834b7: 03 d1                        	add	edx, ecx
  5834b9: 89 55 e0                     	mov	dword ptr [ebp - 0x20], edx
  5834bc: f3 0f c2 fe 01               	cmpltss	xmm7, xmm6
  5834c1: 0f 28 f4                     	movaps	xmm6, xmm4
  5834c4: f3 0f 59 75 cc               	mulss	xmm6, dword ptr [ebp - 0x34]
  5834c9: 66 0f 7e fa                  	movd	edx, xmm7
  5834cd: f7 da                        	neg	edx
  5834cf: f3 0f c2 eb 01               	cmpltss	xmm5, xmm3
  5834d4: 0f 28 dc                     	movaps	xmm3, xmm4
  5834d7: f3 0f 59 5d d4               	mulss	xmm3, dword ptr [ebp - 0x2c]
  5834dc: 66 0f 7e e8                  	movd	eax, xmm5
  5834e0: 23 c1                        	and	eax, ecx
  5834e2: 0b d0                        	or	edx, eax
  5834e4: 8b ca                        	mov	ecx, edx
  5834e6: 83 c9 04                     	or	ecx, 0x4
  5834e9: 0f 2f d9                     	comiss	xmm3, xmm1
  5834ec: 0f 47 d1                     	cmova	edx, ecx
  5834ef: f3 0f c2 f1 01               	cmpltss	xmm6, xmm1
  5834f4: 66 0f 7e f0                  	movd	eax, xmm6
  5834f8: 83 e0 08                     	and	eax, 0x8
  5834fb: 0b d0                        	or	edx, eax
  5834fd: 8b c2                        	mov	eax, edx
  5834ff: 83 c8 10                     	or	eax, 0x10
  583502: 0f 2f c4                     	comiss	xmm0, xmm4
  583505: 77 02                        	ja	0x583509 <.text+0x182509>
  583507: 8b c2                        	mov	eax, edx
  583509: 0f be d0                     	movsx	edx, al
  58350c: 83 ca 20                     	or	edx, 0x20
  58350f: 0f 2f 65 c8                  	comiss	xmm4, dword ptr [ebp - 0x38]
  583513: 0f 47 c2                     	cmova	eax, edx
  583516: a8 0f                        	test	al, 0xf
  583518: 74 09                        	je	0x583523 <.text+0x182523>
  58351a: c6 86 b4 00 00 00 00         	mov	byte ptr [esi + 0xb4], 0x0
  583521: eb 09                        	jmp	0x58352c <.text+0x18252c>
  583523: 8b 45 e0                     	mov	eax, dword ptr [ebp - 0x20]
  583526: 88 86 b4 00 00 00            	mov	byte ptr [esi + 0xb4], al
  58352c: 8b 36                        	mov	esi, dword ptr [esi]
  58352e: 85 f6                        	test	esi, esi
  583530: 0f 85 b8 f9 ff ff            	jne	0x582eee <.text+0x181eee>
  583536: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  58353d: 8b 7d 9c                     	mov	edi, dword ptr [ebp - 0x64]
  583540: 8b 75 b8                     	mov	esi, dword ptr [ebp - 0x48]
  583543: c6 05 68 0e d7 00 00         	mov	byte ptr [0xd70e68], 0x0
  58354a: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  58354d: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  583554: 8b e5                        	mov	esp, ebp
  583556: 5d                           	pop	ebp
  583557: 8b e3                        	mov	esp, ebx
  583559: 5b                           	pop	ebx
  58355a: c2 08 00                     	ret	0x8
  58355d: f2 0f 10 05 08 79 10 01      	movsd	xmm0, qword ptr [0x1107908]
  583565: 66 0f 2e 85 78 ff ff ff      	ucomisd	xmm0, qword ptr [ebp - 0x88]
  58356d: 0f 85 f0 f8 ff ff            	jne	0x582e63 <.text+0x181e63>
  583573: 0f 8a ea f8 ff ff            	jp	0x582e63 <.text+0x181e63>
  583579: f2 0f 10 05 10 79 10 01      	movsd	xmm0, qword ptr [0x1107910]
  583581: 66 0f 2e 45 80               	ucomisd	xmm0, qword ptr [ebp - 0x80]
  583586: 0f 85 d7 f8 ff ff            	jne	0x582e63 <.text+0x181e63>
  58358c: 0f 8a d1 f8 ff ff            	jp	0x582e63 <.text+0x181e63>
  583592: f3 0f 10 05 18 79 10 01      	movss	xmm0, dword ptr [0x1107918]
  58359a: 0f 2e 45 c4                  	ucomiss	xmm0, dword ptr [ebp - 0x3c]
  58359e: 0f 85 bf f8 ff ff            	jne	0x582e63 <.text+0x181e63>
  5835a4: 0f 8a b9 f8 ff ff            	jp	0x582e63 <.text+0x181e63>
  5835aa: e9 bb f8 ff ff               	jmp	0x582e6a <.text+0x181e6a>
  5835af: 90                           	nop
  5835b0: 53                           	push	ebx
  5835b1: 8b dc                        	mov	ebx, esp
  5835b3: 83 e4 f8                     	and	esp, -0x8
  5835b6: 55                           	push	ebp
  5835b7: 55                           	push	ebp
  5835b8: 8b 6b 04                     	mov	ebp, dword ptr [ebx + 0x4]
  5835bb: 89 6c 24 04                  	mov	dword ptr [esp + 0x4], ebp
  5835bf: 8b ec                        	mov	ebp, esp
  5835c1: 6a ff                        	push	-0x1
  5835c3: 68 30 a3 bf 00               	push	0xbfa330
  5835c8: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  5835ce: 50                           	push	eax
  5835cf: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  5835d6: 81 ec b4 00 00 00            	sub	esp, 0xb4
  5835dc: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
  5835df: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  5835e2: 89 7d e0                     	mov	dword ptr [ebp - 0x20], edi
  5835e5: 89 75 e4                     	mov	dword ptr [ebp - 0x1c], esi
  5835e8: 8b 15 10 53 d8 00            	mov	edx, dword ptr [0xd85310]
  5835ee: 89 8d 74 ff ff ff            	mov	dword ptr [ebp - 0x8c], ecx
  5835f4: 89 55 e8                     	mov	dword ptr [ebp - 0x18], edx
  5835f7: f3 0f 10 05 c0 4b c3 00      	movss	xmm0, dword ptr [0xc34bc0]
  5835ff: f3 0f 5e 05 ac 79 10 01      	divss	xmm0, dword ptr [0x11079ac]
  583607: 8b 43 08                     	mov	eax, dword ptr [ebx + 0x8]
  58360a: 8b 90 38 01 00 00            	mov	edx, dword ptr [eax + 0x138]
  583610: 8b 88 3c 01 00 00            	mov	ecx, dword ptr [eax + 0x13c]
  583616: 8b b0 40 01 00 00            	mov	esi, dword ptr [eax + 0x140]
  58361c: 8b b8 44 01 00 00            	mov	edi, dword ptr [eax + 0x144]
  583622: f3 0f 11 45 84               	movss	dword ptr [ebp - 0x7c], xmm0
  583627: 89 55 88                     	mov	dword ptr [ebp - 0x78], edx
  58362a: 8b 90 48 01 00 00            	mov	edx, dword ptr [eax + 0x148]
  583630: 89 4d 8c                     	mov	dword ptr [ebp - 0x74], ecx
  583633: 8b 88 4c 01 00 00            	mov	ecx, dword ptr [eax + 0x14c]
  583639: 89 75 90                     	mov	dword ptr [ebp - 0x70], esi
  58363c: 8b b0 10 02 00 00            	mov	esi, dword ptr [eax + 0x210]
  583642: 89 7d 94                     	mov	dword ptr [ebp - 0x6c], edi
  583645: 8b b8 14 02 00 00            	mov	edi, dword ptr [eax + 0x214]
  58364b: 89 55 98                     	mov	dword ptr [ebp - 0x68], edx
  58364e: 8b 90 18 02 00 00            	mov	edx, dword ptr [eax + 0x218]
  583654: 89 4d 9c                     	mov	dword ptr [ebp - 0x64], ecx
  583657: 8b 88 1c 02 00 00            	mov	ecx, dword ptr [eax + 0x21c]
  58365d: 89 75 c8                     	mov	dword ptr [ebp - 0x38], esi
  583660: 8b b0 20 02 00 00            	mov	esi, dword ptr [eax + 0x220]
  583666: 8b 80 24 02 00 00            	mov	eax, dword ptr [eax + 0x224]
  58366c: 89 7d cc                     	mov	dword ptr [ebp - 0x34], edi
  58366f: 89 55 d0                     	mov	dword ptr [ebp - 0x30], edx
  583672: 89 4d d4                     	mov	dword ptr [ebp - 0x2c], ecx
  583675: 89 75 d8                     	mov	dword ptr [ebp - 0x28], esi
  583678: 89 45 dc                     	mov	dword ptr [ebp - 0x24], eax
  58367b: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  583682: 0f b6 05 20 79 10 01         	movzx	eax, byte ptr [0x1107920]
  583689: a8 01                        	test	al, 0x1
  58368b: 75 29                        	jne	0x5836b6 <.text+0x1826b6>
  58368d: c7 05 a0 99 10 01 0f 00 00 00	mov	dword ptr [0x11099a0], 0xf
  583697: 83 c8 01                     	or	eax, 0x1
  58369a: a2 20 79 10 01               	mov	byte ptr [0x1107920], al
  58369f: 68 b0 c9 57 00               	push	0x57c9b0
  5836a4: 33 c0                        	xor	eax, eax
  5836a6: a3 9c 99 10 01               	mov	dword ptr [0x110999c], eax
  5836ab: a2 8c 99 10 01               	mov	byte ptr [0x110998c], al
  5836b0: e8 bf b8 50 00               	call	0xa8ef74 <.text+0x68df74>
  5836b5: 59                           	pop	ecx
  5836b6: 0f b6 05 68 0e d7 00         	movzx	eax, byte ptr [0xd70e68]
  5836bd: 88 45 a4                     	mov	byte ptr [ebp - 0x5c], al
  5836c0: e8 9b 15 02 00               	call	0x5a4c60 <.text+0x1a3c60>
  5836c5: 8d 95 40 ff ff ff            	lea	edx, [ebp - 0xc0]
  5836cb: 52                           	push	edx
  5836cc: 8b c8                        	mov	ecx, eax
  5836ce: e8 4d 6e 02 00               	call	0x5aa520 <.text+0x1a9520>
  5836d3: c7 45 fc 0c 00 00 00         	mov	dword ptr [ebp - 0x4], 0xc
  5836da: 8d 85 40 ff ff ff            	lea	eax, [ebp - 0xc0]
  5836e0: 83 c4 f8                     	add	esp, -0x8
  5836e3: c7 04 24 88 99 10 01         	mov	dword ptr [esp], 0x1109988
  5836ea: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  5836ee: ff 15 10 54 c2 00            	call	dword ptr [0xc25410]
  5836f4: 83 c4 08                     	add	esp, 0x8
  5836f7: 0f b6 c0                     	movzx	eax, al
  5836fa: 85 c0                        	test	eax, eax
  5836fc: 75 10                        	jne	0x58370e <.text+0x18270e>
  5836fe: f3 0f 10 05 a4 99 10 01      	movss	xmm0, dword ptr [0x11099a4]
  583706: 0f 2e 45 84                  	ucomiss	xmm0, dword ptr [ebp - 0x7c]
  58370a: 7a 02                        	jp	0x58370e <.text+0x18270e>
  58370c: 74 07                        	je	0x583715 <.text+0x182715>
  58370e: be 01 00 00 00               	mov	esi, 0x1
  583713: eb 02                        	jmp	0x583717 <.text+0x182717>
  583715: 33 f6                        	xor	esi, esi
  583717: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  58371e: 83 bd 58 ff ff ff 10         	cmp	dword ptr [ebp - 0xa8], 0x10
  583725: 0f 83 20 0c 00 00            	jae	0x58434b <.text+0x18334b>
  58372b: c7 85 58 ff ff ff 0f 00 00 00	mov	dword ptr [ebp - 0xa8], 0xf
  583735: 33 c0                        	xor	eax, eax
  583737: 85 f6                        	test	esi, esi
  583739: 89 85 54 ff ff ff            	mov	dword ptr [ebp - 0xac], eax
  58373f: 88 85 44 ff ff ff            	mov	byte ptr [ebp - 0xbc], al
  583745: 74 04                        	je	0x58374b <.text+0x18274b>
  583747: c6 45 a4 01                  	mov	byte ptr [ebp - 0x5c], 0x1
  58374b: e8 10 15 02 00               	call	0x5a4c60 <.text+0x1a3c60>
  583750: 8d 95 40 ff ff ff            	lea	edx, [ebp - 0xc0]
  583756: 52                           	push	edx
  583757: 8b c8                        	mov	ecx, eax
  583759: e8 c2 6d 02 00               	call	0x5aa520 <.text+0x1a9520>
  58375e: c7 45 fc 07 00 00 00         	mov	dword ptr [ebp - 0x4], 0x7
  583765: 8b 35 d0 53 c2 00            	mov	esi, dword ptr [0xc253d0]
  58376b: 8d 95 40 ff ff ff            	lea	edx, [ebp - 0xc0]
  583771: 8b 3e                        	mov	edi, dword ptr [esi]
  583773: 8b b5 54 ff ff ff            	mov	esi, dword ptr [ebp - 0xac]
  583779: 89 55 b0                     	mov	dword ptr [ebp - 0x50], edx
  58377c: b8 88 99 10 01               	mov	eax, 0x1109988
  583781: 89 45 a8                     	mov	dword ptr [ebp - 0x58], eax
  583784: 3b fe                        	cmp	edi, esi
  583786: 0f 42 f7                     	cmovb	esi, edi
  583789: 89 b5 7c ff ff ff            	mov	dword ptr [ebp - 0x84], esi
  58378f: 3b c2                        	cmp	eax, edx
  583791: 0f 84 1f 0b 00 00            	je	0x5842b6 <.text+0x1832b6>
  583797: 89 75 a0                     	mov	dword ptr [ebp - 0x60], esi
  58379a: 83 fe fe                     	cmp	esi, -0x2
  58379d: 76 09                        	jbe	0x5837a8 <.text+0x1827a8>
  58379f: ff 15 d4 53 c2 00            	call	dword ptr [0xc253d4]
  5837a5: 8b 75 a0                     	mov	esi, dword ptr [ebp - 0x60]
  5837a8: 8b 3d a0 99 10 01            	mov	edi, dword ptr [0x11099a0]
  5837ae: 3b fe                        	cmp	edi, esi
  5837b0: 0f 82 6a 09 00 00            	jb	0x584120 <.text+0x183120>
  5837b6: 85 f6                        	test	esi, esi
  5837b8: 0f 84 41 09 00 00            	je	0x5840ff <.text+0x1830ff>
  5837be: 85 f6                        	test	esi, esi
  5837c0: 0f 87 e5 08 00 00            	ja	0x5840ab <.text+0x1830ab>
  5837c6: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  5837cd: 83 bd 58 ff ff ff 10         	cmp	dword ptr [ebp - 0xa8], 0x10
  5837d4: 0f 83 c0 08 00 00            	jae	0x58409a <.text+0x18309a>
  5837da: 8b 55 84                     	mov	edx, dword ptr [ebp - 0x7c]
  5837dd: 0f b6 4d a4                  	movzx	ecx, byte ptr [ebp - 0x5c]
  5837e1: 89 15 a4 99 10 01            	mov	dword ptr [0x11099a4], edx
  5837e7: 33 c0                        	xor	eax, eax
  5837e9: 85 c9                        	test	ecx, ecx
  5837eb: c7 85 58 ff ff ff 0f 00 00 00	mov	dword ptr [ebp - 0xa8], 0xf
  5837f5: 89 85 54 ff ff ff            	mov	dword ptr [ebp - 0xac], eax
  5837fb: 88 85 44 ff ff ff            	mov	byte ptr [ebp - 0xbc], al
  583801: 0f 84 de 01 00 00            	je	0x5839e5 <.text+0x1829e5>
  583807: c7 45 fc 04 00 00 00         	mov	dword ptr [ebp - 0x4], 0x4
  58380e: c7 85 6c ff ff ff 00 00 00 00	mov	dword ptr [ebp - 0x94], 0x0
  583818: 50                           	push	eax
  583819: c7 04 24 18 00 00 00         	mov	dword ptr [esp], 0x18
  583820: e8 e5 b7 50 00               	call	0xa8f00a <.text+0x68e00a>
  583825: 59                           	pop	ecx
  583826: 89 85 70 ff ff ff            	mov	dword ptr [ebp - 0x90], eax
  58382c: 85 c0                        	test	eax, eax
  58382e: 74 4c                        	je	0x58387c <.text+0x18287c>
  583830: c7 85 6c ff ff ff 01 00 00 00	mov	dword ptr [ebp - 0x94], 0x1
  58383a: 6a 02                        	push	0x2
  58383c: 8d 70 08                     	lea	esi, [eax + 0x8]
  58383f: 56                           	push	esi
  583840: 8b c8                        	mov	ecx, eax
  583842: ff 15 78 60 c2 00            	call	dword ptr [0xc26078]
  583848: 8b 15 10 61 c2 00            	mov	edx, dword ptr [0xc26110]
  58384e: 89 16                        	mov	dword ptr [esi], edx
  583850: b8 01 00 00 00               	mov	eax, 0x1
  583855: f0                           	lock
  583856: 0f c1 02                     	xadd	dword ptr [edx], eax
  583859: 8b 95 70 ff ff ff            	mov	edx, dword ptr [ebp - 0x90]
  58385f: c7 42 0c 01 00 00 00         	mov	dword ptr [edx + 0xc], 0x1
  583866: 33 c0                        	xor	eax, eax
  583868: 89 42 10                     	mov	dword ptr [edx + 0x10], eax
  58386b: 89 85 6c ff ff ff            	mov	dword ptr [ebp - 0x94], eax
  583871: be 01 01 00 00               	mov	esi, 0x101
  583876: 66 89 72 14                  	mov	word ptr [edx + 0x14], si
  58387a: eb 02                        	jmp	0x58387e <.text+0x18287e>
  58387c: 33 d2                        	xor	edx, edx
  58387e: c7 45 fc 05 00 00 00         	mov	dword ptr [ebp - 0x4], 0x5
  583885: 89 95 78 ff ff ff            	mov	dword ptr [ebp - 0x88], edx
  58388b: 8d b5 7c ff ff ff            	lea	esi, [ebp - 0x84]
  583891: 83 c4 f4                     	add	esp, -0xc
  583894: 89 34 24                     	mov	dword ptr [esp], esi
  583897: c7 44 24 04 fc 4c c3 00      	mov	dword ptr [esp + 0x4], 0xc34cfc
  58389f: c7 44 24 08 ff ff ff ff      	mov	dword ptr [esp + 0x8], 0xffffffff
  5838a7: ff 15 f0 60 c2 00            	call	dword ptr [0xc260f0]
  5838ad: 83 c4 0c                     	add	esp, 0xc
  5838b0: c7 45 fc 06 00 00 00         	mov	dword ptr [ebp - 0x4], 0x6
  5838b7: 8b 8d 78 ff ff ff            	mov	ecx, dword ptr [ebp - 0x88]
  5838bd: 56                           	push	esi
  5838be: ff 15 74 60 c2 00            	call	dword ptr [0xc26074]
  5838c4: c7 45 fc 05 00 00 00         	mov	dword ptr [ebp - 0x4], 0x5
  5838cb: 8b 95 7c ff ff ff            	mov	edx, dword ptr [ebp - 0x84]
  5838d1: 83 c8 ff                     	or	eax, -0x1
  5838d4: f0                           	lock
  5838d5: 0f c1 02                     	xadd	dword ptr [edx], eax
  5838d8: 48                           	dec	eax
  5838d9: 85 c0                        	test	eax, eax
  5838db: 75 0b                        	jne	0x5838e8 <.text+0x1828e8>
  5838dd: 50                           	push	eax
  5838de: 89 14 24                     	mov	dword ptr [esp], edx
  5838e1: ff 15 88 61 c2 00            	call	dword ptr [0xc26188]
  5838e7: 59                           	pop	ecx
  5838e8: 8b 8d 78 ff ff ff            	mov	ecx, dword ptr [ebp - 0x88]
  5838ee: 0f b6 41 14                  	movzx	eax, byte ptr [ecx + 0x14]
  5838f2: 85 c0                        	test	eax, eax
  5838f4: 74 0e                        	je	0x583904 <.text+0x182904>
  5838f6: 6a 20                        	push	0x20
  5838f8: ff 15 70 60 c2 00            	call	dword ptr [0xc26070]
  5838fe: 8b 8d 78 ff ff ff            	mov	ecx, dword ptr [ebp - 0x88]
  583904: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  58390b: 8d 85 78 ff ff ff            	lea	eax, [ebp - 0x88]
  583911: 8b 51 0c                     	mov	edx, dword ptr [ecx + 0xc]
  583914: 89 85 70 ff ff ff            	mov	dword ptr [ebp - 0x90], eax
  58391a: 4a                           	dec	edx
  58391b: 89 51 0c                     	mov	dword ptr [ecx + 0xc], edx
  58391e: 0f 85 c1 00 00 00            	jne	0x5839e5 <.text+0x1829e5>
  583924: 0f b6 41 15                  	movzx	eax, byte ptr [ecx + 0x15]
  583928: 85 c0                        	test	eax, eax
  58392a: 0f 84 a2 00 00 00            	je	0x5839d2 <.text+0x1829d2>
  583930: c7 45 fc 01 00 00 00         	mov	dword ptr [ebp - 0x4], 0x1
  583937: 8d b5 6c ff ff ff            	lea	esi, [ebp - 0x94]
  58393d: 56                           	push	esi
  58393e: 83 c1 08                     	add	ecx, 0x8
  583941: ff 15 3c 61 c2 00            	call	dword ptr [0xc2613c]
  583947: c7 45 fc 02 00 00 00         	mov	dword ptr [ebp - 0x4], 0x2
  58394e: 8b 85 6c ff ff ff            	mov	eax, dword ptr [ebp - 0x94]
  583954: 8b 10                        	mov	edx, dword ptr [eax]
  583956: 8b 8d 6c ff ff ff            	mov	ecx, dword ptr [ebp - 0x94]
  58395c: 83 fa 01                     	cmp	edx, 0x1
  58395f: 75 0a                        	jne	0x58396b <.text+0x18296b>
  583961: 8b 41 0c                     	mov	eax, dword ptr [ecx + 0xc]
  583964: 8d 51 10                     	lea	edx, [ecx + 0x10]
  583967: 3b c2                        	cmp	eax, edx
  583969: 74 14                        	je	0x58397f <.text+0x18297f>
  58396b: ff 71 08                     	push	dword ptr [ecx + 0x8]
  58396e: 8b ce                        	mov	ecx, esi
  583970: ff 15 6c 60 c2 00            	call	dword ptr [0xc2606c]
  583976: 8b 85 6c ff ff ff            	mov	eax, dword ptr [ebp - 0x94]
  58397c: 8b 40 0c                     	mov	eax, dword ptr [eax + 0xc]
  58397f: 8b 95 70 ff ff ff            	mov	edx, dword ptr [ebp - 0x90]
  583985: 8b 0a                        	mov	ecx, dword ptr [edx]
  583987: 8b 71 10                     	mov	esi, dword ptr [ecx + 0x10]
  58398a: 83 c4 f8                     	add	esp, -0x8
  58398d: 89 34 24                     	mov	dword ptr [esp], esi
  583990: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  583994: ff 15 68 60 c2 00            	call	dword ptr [0xc26068]
  58399a: 83 c4 08                     	add	esp, 0x8
  58399d: c7 45 fc 01 00 00 00         	mov	dword ptr [ebp - 0x4], 0x1
  5839a4: 8b 95 6c ff ff ff            	mov	edx, dword ptr [ebp - 0x94]
  5839aa: 83 c8 ff                     	or	eax, -0x1
  5839ad: f0                           	lock
  5839ae: 0f c1 02                     	xadd	dword ptr [edx], eax
  5839b1: 48                           	dec	eax
  5839b2: 85 c0                        	test	eax, eax
  5839b4: 75 0b                        	jne	0x5839c1 <.text+0x1829c1>
  5839b6: 50                           	push	eax
  5839b7: 89 14 24                     	mov	dword ptr [esp], edx
  5839ba: ff 15 1c 61 c2 00            	call	dword ptr [0xc2611c]
  5839c0: 59                           	pop	ecx
  5839c1: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  5839c8: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  5839cf: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5839d2: 8b 85 70 ff ff ff            	mov	eax, dword ptr [ebp - 0x90]
  5839d8: 8b 08                        	mov	ecx, dword ptr [eax]
  5839da: 85 c9                        	test	ecx, ecx
  5839dc: 74 07                        	je	0x5839e5 <.text+0x1829e5>
  5839de: 6a 01                        	push	0x1
  5839e0: e8 cb 68 ff ff               	call	0x57a2b0 <.text+0x1792b0>
  5839e5: 8b bd 74 ff ff ff            	mov	edi, dword ptr [ebp - 0x8c]
  5839eb: 8b 77 68                     	mov	esi, dword ptr [edi + 0x68]
  5839ee: 85 f6                        	test	esi, esi
  5839f0: 0f 84 1f 06 00 00            	je	0x584015 <.text+0x183015>
  5839f6: f3 0f 10 55 84               	movss	xmm2, dword ptr [ebp - 0x7c]
  5839fb: 0f b6 4d a4                  	movzx	ecx, byte ptr [ebp - 0x5c]
  5839ff: f3 0f 10 4f 74               	movss	xmm1, dword ptr [edi + 0x74]
  583a04: 85 c9                        	test	ecx, ecx
  583a06: 0f 84 74 04 00 00            	je	0x583e80 <.text+0x182e80>
  583a0c: 83 3d a8 99 10 01 00         	cmp	dword ptr [0x11099a8], 0x0
  583a13: f2 0f 10 46 08               	movsd	xmm0, qword ptr [esi + 0x8]
  583a18: f2 0f 5c 45 88               	subsd	xmm0, qword ptr [ebp - 0x78]
  583a1d: 0f 28 f8                     	movaps	xmm7, xmm0
  583a20: f2 0f 59 f8                  	mulsd	xmm7, xmm0
  583a24: f2 0f 10 6e 10               	movsd	xmm5, qword ptr [esi + 0x10]
  583a29: f2 0f 5c 6d 90               	subsd	xmm5, qword ptr [ebp - 0x70]
  583a2e: 0f 28 dd                     	movaps	xmm3, xmm5
  583a31: f2 0f 59 dd                  	mulsd	xmm3, xmm5
  583a35: f2 0f 10 66 18               	movsd	xmm4, qword ptr [esi + 0x18]
  583a3a: f2 0f 5c 65 98               	subsd	xmm4, qword ptr [ebp - 0x68]
  583a3f: 0f 28 f4                     	movaps	xmm6, xmm4
  583a42: f2 0f 59 f4                  	mulsd	xmm6, xmm4
  583a46: f2 0f 58 fb                  	addsd	xmm7, xmm3
  583a4a: f2 0f 58 fe                  	addsd	xmm7, xmm6
  583a4e: f2 0f 5a df                  	cvtsd2ss	xmm3, xmm7
  583a52: f3 0f 11 9e b0 00 00 00      	movss	dword ptr [esi + 0xb0], xmm3
  583a5a: f3 0f 51 f3                  	sqrtss	xmm6, xmm3
  583a5e: f3 0f 5a fe                  	cvtss2sd	xmm7, xmm6
  583a62: f2 0f 10 35 20 49 c3 00      	movsd	xmm6, qword ptr [0xc34920]
  583a6a: f2 0f 5e f7                  	divsd	xmm6, xmm7
  583a6e: f2 0f 59 c6                  	mulsd	xmm0, xmm6
  583a72: f2 0f 11 45 a0               	movsd	qword ptr [ebp - 0x60], xmm0
  583a77: f2 0f 59 ee                  	mulsd	xmm5, xmm6
  583a7b: 8b 45 a0                     	mov	eax, dword ptr [ebp - 0x60]
  583a7e: 8b 55 a4                     	mov	edx, dword ptr [ebp - 0x5c]
  583a81: f2 0f 11 6d a8               	movsd	qword ptr [ebp - 0x58], xmm5
  583a86: f2 0f 59 f4                  	mulsd	xmm6, xmm4
  583a8a: f2 0f 11 75 b0               	movsd	qword ptr [ebp - 0x50], xmm6
  583a8f: 89 86 98 00 00 00            	mov	dword ptr [esi + 0x98], eax
  583a95: 8b 45 a8                     	mov	eax, dword ptr [ebp - 0x58]
  583a98: 89 96 9c 00 00 00            	mov	dword ptr [esi + 0x9c], edx
  583a9e: 8b 55 ac                     	mov	edx, dword ptr [ebp - 0x54]
  583aa1: 89 86 a0 00 00 00            	mov	dword ptr [esi + 0xa0], eax
  583aa7: 8b 45 b0                     	mov	eax, dword ptr [ebp - 0x50]
  583aaa: 89 96 a4 00 00 00            	mov	dword ptr [esi + 0xa4], edx
  583ab0: 8b 55 b4                     	mov	edx, dword ptr [ebp - 0x4c]
  583ab3: 89 86 a8 00 00 00            	mov	dword ptr [esi + 0xa8], eax
  583ab9: 89 96 ac 00 00 00            	mov	dword ptr [esi + 0xac], edx
  583abf: 75 46                        	jne	0x583b07 <.text+0x182b07>
  583ac1: f3 0f 10 46 2c               	movss	xmm0, dword ptr [esi + 0x2c]
  583ac6: f3 0f 59 c2                  	mulss	xmm0, xmm2
  583aca: f3 0f 5e c3                  	divss	xmm0, xmm3
  583ace: 0f 2f 05 d8 4b c3 00         	comiss	xmm0, dword ptr [0xc34bd8]
  583ad5: f3 0f 11 46 3c               	movss	dword ptr [esi + 0x3c], xmm0
  583ada: 77 0c                        	ja	0x583ae8 <.text+0x182ae8>
  583adc: c7 46 40 00 00 80 3f         	mov	dword ptr [esi + 0x40], 0x3f800000
  583ae3: e9 98 03 00 00               	jmp	0x583e80 <.text+0x182e80>
  583ae8: f3 0f 11 55 bc               	movss	dword ptr [ebp - 0x44], xmm2
  583aed: 89 4d c0                     	mov	dword ptr [ebp - 0x40], ecx
  583af0: e8 63 b3 50 00               	call	0xa8ee58 <.text+0x68de58>
  583af5: 8b 4d c0                     	mov	ecx, dword ptr [ebp - 0x40]
  583af8: f3 0f 10 55 bc               	movss	xmm2, dword ptr [ebp - 0x44]
  583afd: f3 0f 11 46 40               	movss	dword ptr [esi + 0x40], xmm0
  583b02: e9 79 03 00 00               	jmp	0x583e80 <.text+0x182e80>
  583b07: f3 0f 10 46 44               	movss	xmm0, dword ptr [esi + 0x44]
  583b0c: f3 0f 10 5e 28               	movss	xmm3, dword ptr [esi + 0x28]
  583b11: f3 0f 11 45 84               	movss	dword ptr [ebp - 0x7c], xmm0
  583b16: f3 0f 10 05 ac 79 10 01      	movss	xmm0, dword ptr [0x11079ac]
  583b1e: 66 0f ef c9                  	pxor	xmm1, xmm1
  583b22: 0f 2e c1                     	ucomiss	xmm0, xmm1
  583b25: 7a 02                        	jp	0x583b29 <.text+0x182b29>
  583b27: 74 2f                        	je	0x583b58 <.text+0x182b58>
  583b29: f3 0f 5a eb                  	cvtss2sd	xmm5, xmm3
  583b2d: f3 0f 5a e0                  	cvtss2sd	xmm4, xmm0
  583b31: f2 0f 10 05 20 49 c3 00      	movsd	xmm0, qword ptr [0xc34920]
  583b39: 0f 28 d8                     	movaps	xmm3, xmm0
  583b3c: f2 0f 10 0d 18 49 c3 00      	movsd	xmm1, qword ptr [0xc34918]
  583b44: f2 0f 5c e0                  	subsd	xmm4, xmm0
  583b48: f2 0f 5e e1                  	divsd	xmm4, xmm1
  583b4c: f2 0f 58 e3                  	addsd	xmm4, xmm3
  583b50: f2 0f 59 ec                  	mulsd	xmm5, xmm4
  583b54: f2 0f 5a dd                  	cvtsd2ss	xmm3, xmm5
  583b58: f3 0f 10 05 c4 4b c3 00      	movss	xmm0, dword ptr [0xc34bc4]
  583b60: f3 0f 11 55 bc               	movss	dword ptr [ebp - 0x44], xmm2
  583b65: 89 4d c0                     	mov	dword ptr [ebp - 0x40], ecx
  583b68: 66 0f ef c9                  	pxor	xmm1, xmm1
  583b6c: f3 0f 5c cb                  	subss	xmm1, xmm3
  583b70: f3 0f 10 1d c8 4b c3 00      	movss	xmm3, dword ptr [0xc34bc8]
  583b78: f3 0f 5e cb                  	divss	xmm1, xmm3
  583b7c: e8 d7 b2 50 00               	call	0xa8ee58 <.text+0x68de58>
  583b81: 0f 28 d8                     	movaps	xmm3, xmm0
  583b84: f3 0f 10 25 20 1e d7 00      	movss	xmm4, dword ptr [0xd71e20]
  583b8c: f3 0f 59 e4                  	mulss	xmm4, xmm4
  583b90: f3 0f 10 05 c4 4b c3 00      	movss	xmm0, dword ptr [0xc34bc4]
  583b98: f3 0f 11 65 80               	movss	dword ptr [ebp - 0x80], xmm4
  583b9d: f3 0f 59 dc                  	mulss	xmm3, xmm4
  583ba1: f3 0f 11 5d c4               	movss	dword ptr [ebp - 0x3c], xmm3
  583ba6: 66 0f ef c9                  	pxor	xmm1, xmm1
  583baa: f3 0f 5c 0d 1c 1e d7 00      	subss	xmm1, dword ptr [0xd71e1c]
  583bb2: f3 0f 5e 0d c8 4b c3 00      	divss	xmm1, dword ptr [0xc34bc8]
  583bba: e8 99 b2 50 00               	call	0xa8ee58 <.text+0x68de58>
  583bbf: 8b 4d c0                     	mov	ecx, dword ptr [ebp - 0x40]
  583bc2: f3 0f 10 55 bc               	movss	xmm2, dword ptr [ebp - 0x44]
  583bc7: f3 0f 10 5d c4               	movss	xmm3, dword ptr [ebp - 0x3c]
  583bcc: f3 0f 10 4d 80               	movss	xmm1, dword ptr [ebp - 0x80]
  583bd1: f3 0f 59 c8                  	mulss	xmm1, xmm0
  583bd5: 0f 2f cb                     	comiss	xmm1, xmm3
  583bd8: 0f 28 cb                     	movaps	xmm1, xmm3
  583bdb: f3 0f 10 25 cc 4b c3 00      	movss	xmm4, dword ptr [0xc34bcc]
  583be3: f3 0f 10 6d 84               	movss	xmm5, dword ptr [ebp - 0x7c]
  583be8: 76 03                        	jbe	0x583bed <.text+0x182bed>
  583bea: 0f 28 ec                     	movaps	xmm5, xmm4
  583bed: f3 0f 5c 2d d0 4b c3 00      	subss	xmm5, dword ptr [0xc34bd0]
  583bf5: f3 0f 5e 2d c4 4b c3 00      	divss	xmm5, dword ptr [0xc34bc4]
  583bfd: f3 0f 2c c5                  	cvttss2si	eax, xmm5
  583c01: 3d cd 00 00 00               	cmp	eax, 0xcd
  583c06: 7c 05                        	jl	0x583c0d <.text+0x182c0d>
  583c08: b8 cd 00 00 00               	mov	eax, 0xcd
  583c0d: f3 0f 5e 0c 85 a0 83 10 01   	divss	xmm1, dword ptr [4*eax + 0x11083a0]
  583c16: 0f 2f 0d d8 4b c3 00         	comiss	xmm1, dword ptr [0xc34bd8]
  583c1d: 89 45 b8                     	mov	dword ptr [ebp - 0x48], eax
  583c20: 0f 86 13 01 00 00            	jbe	0x583d39 <.text+0x182d39>
  583c26: f3 0f 51 c1                  	sqrtss	xmm0, xmm1
  583c2a: f3 0f 11 46 40               	movss	dword ptr [esi + 0x40], xmm0
  583c2f: 66 0f ef c9                  	pxor	xmm1, xmm1
  583c33: f3 0f 10 04 85 a0 83 10 01   	movss	xmm0, dword ptr [4*eax + 0x11083a0]
  583c3c: 0f 2f c8                     	comiss	xmm1, xmm0
  583c3f: 76 11                        	jbe	0x583c52 <.text+0x182c52>
  583c41: 33 c0                        	xor	eax, eax
  583c43: 89 85 70 ff ff ff            	mov	dword ptr [ebp - 0x90], eax
  583c49: 66 0f ef db                  	pxor	xmm3, xmm3
  583c4d: e9 e7 01 00 00               	jmp	0x583e39 <.text+0x182e39>
  583c52: f3 0f 5a d8                  	cvtss2sd	xmm3, xmm0
  583c56: f2 0f 10 0d f0 48 c3 00      	movsd	xmm1, qword ptr [0xc348f0]
  583c5e: 66 0f 2f cb                  	comisd	xmm1, xmm3
  583c62: 72 1d                        	jb	0x583c81 <.text+0x182c81>
  583c64: f2 0f 10 05 10 49 c3 00      	movsd	xmm0, qword ptr [0xc34910]
  583c6c: f2 0f 59 d8                  	mulsd	xmm3, xmm0
  583c70: f2 0f 5a db                  	cvtsd2ss	xmm3, xmm3
  583c74: f3 0f 11 9d 70 ff ff ff      	movss	dword ptr [ebp - 0x90], xmm3
  583c7c: e9 b8 01 00 00               	jmp	0x583e39 <.text+0x182e39>
  583c81: f2 0f 10 0d f0 48 c3 00      	movsd	xmm1, qword ptr [0xc348f0]
  583c89: 66 0f 2f d9                  	comisd	xmm3, xmm1
  583c8d: 0f 86 99 00 00 00            	jbe	0x583d2c <.text+0x182d2c>
  583c93: f3 0f 10 0d c8 4b c3 00      	movss	xmm1, dword ptr [0xc34bc8]
  583c9b: 0f 2f c8                     	comiss	xmm1, xmm0
  583c9e: 76 42                        	jbe	0x583ce2 <.text+0x182ce2>
  583ca0: f2 0f 10 05 08 49 c3 00      	movsd	xmm0, qword ptr [0xc34908]
  583ca8: f2 0f 5e d8                  	divsd	xmm3, xmm0
  583cac: f2 0f 10 0d f8 48 c3 00      	movsd	xmm1, qword ptr [0xc348f8]
  583cb4: f2 0f 2c c3                  	cvttsd2si	eax, xmm3
  583cb8: f3 0f 5a 24 85 e0 86 10 01   	cvtss2sd	xmm4, dword ptr [4*eax + 0x11086e0]
  583cc1: f2 0f 59 e1                  	mulsd	xmm4, xmm1
  583cc5: f2 0f 10 1d 00 49 c3 00      	movsd	xmm3, qword ptr [0xc34900]
  583ccd: f2 0f 5c e3                  	subsd	xmm4, xmm3
  583cd1: f2 0f 5a dc                  	cvtsd2ss	xmm3, xmm4
  583cd5: f3 0f 11 9d 70 ff ff ff      	movss	dword ptr [ebp - 0x90], xmm3
  583cdd: e9 57 01 00 00               	jmp	0x583e39 <.text+0x182e39>
  583ce2: f3 0f 10 0d d4 4b c3 00      	movss	xmm1, dword ptr [0xc34bd4]
  583cea: f3 0f 11 55 bc               	movss	dword ptr [ebp - 0x44], xmm2
  583cef: 89 4d c0                     	mov	dword ptr [ebp - 0x40], ecx
  583cf2: e8 61 b1 50 00               	call	0xa8ee58 <.text+0x68de58>
  583cf7: f3 0f 5a e0                  	cvtss2sd	xmm4, xmm0
  583cfb: 8b 4d c0                     	mov	ecx, dword ptr [ebp - 0x40]
  583cfe: f3 0f 10 55 bc               	movss	xmm2, dword ptr [ebp - 0x44]
  583d03: f2 0f 10 0d f8 48 c3 00      	movsd	xmm1, qword ptr [0xc348f8]
  583d0b: f2 0f 59 e1                  	mulsd	xmm4, xmm1
  583d0f: f2 0f 10 1d 00 49 c3 00      	movsd	xmm3, qword ptr [0xc34900]
  583d17: f2 0f 5c e3                  	subsd	xmm4, xmm3
  583d1b: f2 0f 5a dc                  	cvtsd2ss	xmm3, xmm4
  583d1f: f3 0f 11 9d 70 ff ff ff      	movss	dword ptr [ebp - 0x90], xmm3
  583d27: e9 0d 01 00 00               	jmp	0x583e39 <.text+0x182e39>
  583d2c: f3 0f 10 9d 70 ff ff ff      	movss	xmm3, dword ptr [ebp - 0x90]
  583d34: e9 00 01 00 00               	jmp	0x583e39 <.text+0x182e39>
  583d39: c7 46 40 00 00 80 3f         	mov	dword ptr [esi + 0x40], 0x3f800000
  583d40: 66 0f ef c9                  	pxor	xmm1, xmm1
  583d44: 0f 2f cb                     	comiss	xmm1, xmm3
  583d47: 76 11                        	jbe	0x583d5a <.text+0x182d5a>
  583d49: 33 c0                        	xor	eax, eax
  583d4b: 89 85 74 ff ff ff            	mov	dword ptr [ebp - 0x8c], eax
  583d51: 66 0f ef db                  	pxor	xmm3, xmm3
  583d55: e9 df 00 00 00               	jmp	0x583e39 <.text+0x182e39>
  583d5a: f3 0f 5a e3                  	cvtss2sd	xmm4, xmm3
  583d5e: f2 0f 10 0d f0 48 c3 00      	movsd	xmm1, qword ptr [0xc348f0]
  583d66: 66 0f 2f cc                  	comisd	xmm1, xmm4
  583d6a: 72 1d                        	jb	0x583d89 <.text+0x182d89>
  583d6c: f2 0f 10 05 10 49 c3 00      	movsd	xmm0, qword ptr [0xc34910]
  583d74: f2 0f 59 e0                  	mulsd	xmm4, xmm0
  583d78: f2 0f 5a dc                  	cvtsd2ss	xmm3, xmm4
  583d7c: f3 0f 11 9d 74 ff ff ff      	movss	dword ptr [ebp - 0x8c], xmm3
