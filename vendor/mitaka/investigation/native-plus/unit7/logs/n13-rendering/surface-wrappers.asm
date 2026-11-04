
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  542bc0: 55                           	push	ebp
  542bc1: 8b ec                        	mov	ebp, esp
  542bc3: 83 e4 f8                     	and	esp, -0x8
  542bc6: 57                           	push	edi
  542bc7: 56                           	push	esi
  542bc8: 53                           	push	ebx
  542bc9: 81 ec a4 01 00 00            	sub	esp, 0x1a4
  542bcf: 8b 5d 0c                     	mov	ebx, dword ptr [ebp + 0xc]
  542bd2: 8d bc 24 d0 00 00 00         	lea	edi, [esp + 0xd0]
  542bd9: 53                           	push	ebx
  542bda: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  542bdf: 57                           	push	edi
  542be0: e8 6b bf ff ff               	call	0x53eb50 <.text+0x13db50>
  542be5: 8b 84 24 d0 00 00 00         	mov	eax, dword ptr [esp + 0xd0]
  542bec: 8b 94 24 d4 00 00 00         	mov	edx, dword ptr [esp + 0xd4]
  542bf3: 8b b4 24 d8 00 00 00         	mov	esi, dword ptr [esp + 0xd8]
  542bfa: 8b 8c 24 e4 00 00 00         	mov	ecx, dword ptr [esp + 0xe4]
  542c01: 89 84 24 e8 00 00 00         	mov	dword ptr [esp + 0xe8], eax
  542c08: 8b 84 24 dc 00 00 00         	mov	eax, dword ptr [esp + 0xdc]
  542c0f: 89 94 24 ec 00 00 00         	mov	dword ptr [esp + 0xec], edx
  542c16: 8b 94 24 e0 00 00 00         	mov	edx, dword ptr [esp + 0xe0]
  542c1d: 89 b4 24 f0 00 00 00         	mov	dword ptr [esp + 0xf0], esi
  542c24: 89 84 24 f4 00 00 00         	mov	dword ptr [esp + 0xf4], eax
  542c2b: 89 94 24 f8 00 00 00         	mov	dword ptr [esp + 0xf8], edx
  542c32: 89 8c 24 fc 00 00 00         	mov	dword ptr [esp + 0xfc], ecx
  542c39: 53                           	push	ebx
  542c3a: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  542c3f: e8 6c c1 ff ff               	call	0x53edb0 <.text+0x13ddb0>
  542c44: dd 9c 24 98 01 00 00         	fstp	qword ptr [esp + 0x198]
  542c4b: f2 0f 10 8c 24 98 01 00 00   	movsd	xmm1, qword ptr [esp + 0x198]
  542c54: f3 0f 5a 05 2c 71 10 01      	cvtss2sd	xmm0, dword ptr [0x110712c]
  542c5c: f2 0f 59 c8                  	mulsd	xmm1, xmm0
  542c60: 8b 75 10                     	mov	esi, dword ptr [ebp + 0x10]
  542c63: f2 0f 11 8c 24 78 01 00 00   	movsd	qword ptr [esp + 0x178], xmm1
  542c6c: 56                           	push	esi
  542c6d: b9 60 74 10 01               	mov	ecx, 0x1107460
  542c72: 57                           	push	edi
  542c73: e8 18 64 01 00               	call	0x559090 <.text+0x158090>
  542c78: 8b 84 24 d0 00 00 00         	mov	eax, dword ptr [esp + 0xd0]
  542c7f: 8b 94 24 d4 00 00 00         	mov	edx, dword ptr [esp + 0xd4]
  542c86: 8b bc 24 d8 00 00 00         	mov	edi, dword ptr [esp + 0xd8]
  542c8d: 8b 8c 24 e4 00 00 00         	mov	ecx, dword ptr [esp + 0xe4]
  542c94: 89 84 24 00 01 00 00         	mov	dword ptr [esp + 0x100], eax
  542c9b: 8b 84 24 dc 00 00 00         	mov	eax, dword ptr [esp + 0xdc]
  542ca2: 89 94 24 04 01 00 00         	mov	dword ptr [esp + 0x104], edx
  542ca9: 8b 94 24 e0 00 00 00         	mov	edx, dword ptr [esp + 0xe0]
  542cb0: 89 bc 24 08 01 00 00         	mov	dword ptr [esp + 0x108], edi
  542cb7: 89 84 24 0c 01 00 00         	mov	dword ptr [esp + 0x10c], eax
  542cbe: 89 94 24 10 01 00 00         	mov	dword ptr [esp + 0x110], edx
  542cc5: 89 8c 24 14 01 00 00         	mov	dword ptr [esp + 0x114], ecx
  542ccc: 56                           	push	esi
  542ccd: b9 60 74 10 01               	mov	ecx, 0x1107460
  542cd2: e8 09 6a 01 00               	call	0x5596e0 <.text+0x1586e0>
  542cd7: dd 9c 24 98 01 00 00         	fstp	qword ptr [esp + 0x198]
  542cde: f2 0f 10 8c 24 98 01 00 00   	movsd	xmm1, qword ptr [esp + 0x198]
  542ce7: f3 0f 5a 05 2c 71 10 01      	cvtss2sd	xmm0, dword ptr [0x110712c]
  542cef: f2 0f 59 c8                  	mulsd	xmm1, xmm0
  542cf3: f2 0f 11 8c 24 80 01 00 00   	movsd	qword ptr [esp + 0x180], xmm1
  542cfc: b9 e0 77 10 01               	mov	ecx, 0x11077e0
  542d01: 66 0f ef c9                  	pxor	xmm1, xmm1
  542d05: f2 0f 11 8c 24 90 01 00 00   	movsd	qword ptr [esp + 0x190], xmm1
  542d0e: f2 0f 11 8c 24 d0 00 00 00   	movsd	qword ptr [esp + 0xd0], xmm1
  542d17: 8b 84 24 d0 00 00 00         	mov	eax, dword ptr [esp + 0xd0]
  542d1e: 8b 94 24 d4 00 00 00         	mov	edx, dword ptr [esp + 0xd4]
  542d25: f2 0f 11 8c 24 d8 00 00 00   	movsd	qword ptr [esp + 0xd8], xmm1
  542d2e: 8b b4 24 d8 00 00 00         	mov	esi, dword ptr [esp + 0xd8]
  542d35: 8b bc 24 dc 00 00 00         	mov	edi, dword ptr [esp + 0xdc]
  542d3c: f2 0f 11 8c 24 e0 00 00 00   	movsd	qword ptr [esp + 0xe0], xmm1
  542d45: 89 84 24 18 01 00 00         	mov	dword ptr [esp + 0x118], eax
  542d4c: 8b 84 24 e0 00 00 00         	mov	eax, dword ptr [esp + 0xe0]
  542d53: 89 94 24 1c 01 00 00         	mov	dword ptr [esp + 0x11c], edx
  542d5a: 8b 94 24 e4 00 00 00         	mov	edx, dword ptr [esp + 0xe4]
  542d61: 89 b4 24 20 01 00 00         	mov	dword ptr [esp + 0x120], esi
  542d68: 89 bc 24 24 01 00 00         	mov	dword ptr [esp + 0x124], edi
  542d6f: 89 84 24 28 01 00 00         	mov	dword ptr [esp + 0x128], eax
  542d76: 89 94 24 2c 01 00 00         	mov	dword ptr [esp + 0x12c], edx
  542d7d: e8 0e 2c 03 00               	call	0x575990 <.text+0x174990>
  542d82: dd 9c 24 98 01 00 00         	fstp	qword ptr [esp + 0x198]
  542d89: f2 0f 10 8c 24 98 01 00 00   	movsd	xmm1, qword ptr [esp + 0x198]
  542d92: f3 0f 5a 05 2c 71 10 01      	cvtss2sd	xmm0, dword ptr [0x110712c]
  542d9a: f2 0f 59 c8                  	mulsd	xmm1, xmm0
  542d9e: f2 0f 11 8c 24 88 01 00 00   	movsd	qword ptr [esp + 0x188], xmm1
  542da7: 53                           	push	ebx
  542da8: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  542dad: e8 9e b8 ff ff               	call	0x53e650 <.text+0x13d650>
  542db2: 8d 54 24 40                  	lea	edx, [esp + 0x40]
  542db6: 52                           	push	edx
  542db7: 8b c8                        	mov	ecx, eax
  542db9: e8 d2 7d ff ff               	call	0x53ab90 <.text+0x139b90>
  542dbe: 53                           	push	ebx
  542dbf: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  542dc4: e8 87 b8 ff ff               	call	0x53e650 <.text+0x13d650>
  542dc9: 8d bc 24 88 00 00 00         	lea	edi, [esp + 0x88]
  542dd0: 57                           	push	edi
  542dd1: 8b c8                        	mov	ecx, eax
  542dd3: e8 98 7e ff ff               	call	0x53ac70 <.text+0x139c70>
  542dd8: 53                           	push	ebx
  542dd9: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  542dde: e8 6d b8 ff ff               	call	0x53e650 <.text+0x13d650>
  542de3: 8b c8                        	mov	ecx, eax
  542de5: 8d 84 24 30 01 00 00         	lea	eax, [esp + 0x130]
  542dec: 8d b4 24 48 01 00 00         	lea	esi, [esp + 0x148]
  542df3: 8d 94 24 60 01 00 00         	lea	edx, [esp + 0x160]
  542dfa: 52                           	push	edx
  542dfb: 56                           	push	esi
  542dfc: 50                           	push	eax
  542dfd: e8 ee 7e ff ff               	call	0x53acf0 <.text+0x139cf0>
  542e02: 8b 75 08                     	mov	esi, dword ptr [ebp + 0x8]
  542e05: 0f be 05 60 93 fe 00         	movsx	eax, byte ptr [0xfe9360]
  542e0c: f3 0f 10 86 2c 02 00 00      	movss	xmm0, dword ptr [esi + 0x22c]
  542e14: f3 0f 11 84 24 a0 01 00 00   	movss	dword ptr [esp + 0x1a0], xmm0
  542e1d: 85 c0                        	test	eax, eax
  542e1f: 75 2b                        	jne	0x542e4c <.text+0x141e4c>
  542e21: e8 da 09 00 00               	call	0x543800 <.text+0x142800>
  542e26: d9 9c 24 98 01 00 00         	fstp	dword ptr [esp + 0x198]
  542e2d: f3 0f 10 84 24 98 01 00 00   	movss	xmm0, dword ptr [esp + 0x198]
  542e36: f3 0f 10 8c 24 a0 01 00 00   	movss	xmm1, dword ptr [esp + 0x1a0]
  542e3f: f3 0f 5e c8                  	divss	xmm1, xmm0
  542e43: f3 0f 11 8c 24 a0 01 00 00   	movss	dword ptr [esp + 0x1a0], xmm1
  542e4c: 53                           	push	ebx
  542e4d: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  542e52: e8 f9 b7 ff ff               	call	0x53e650 <.text+0x13d650>
  542e57: 85 c0                        	test	eax, eax
  542e59: 74 19                        	je	0x542e74 <.text+0x141e74>
  542e5b: 53                           	push	ebx
  542e5c: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  542e61: e8 ea b7 ff ff               	call	0x53e650 <.text+0x13d650>
  542e66: 8b c8                        	mov	ecx, eax
  542e68: e8 23 99 ff ff               	call	0x53c790 <.text+0x13b790>
  542e6d: dd 9c 24 90 01 00 00         	fstp	qword ptr [esp + 0x190]
  542e74: f2 0f 5a 84 24 90 01 00 00   	cvtsd2ss	xmm0, qword ptr [esp + 0x190]
  542e7d: 0f b6 05 28 1e d7 00         	movzx	eax, byte ptr [0xd71e28]
  542e84: f3 0f 10 8c 24 a0 01 00 00   	movss	xmm1, dword ptr [esp + 0x1a0]
  542e8d: f3 0f 11 44 24 10            	movss	dword ptr [esp + 0x10], xmm0
  542e93: f3 0f 11 4c 24 2c            	movss	dword ptr [esp + 0x2c], xmm1
  542e99: 89 34 24                     	mov	dword ptr [esp], esi
  542e9c: 8d b4 24 e8 00 00 00         	lea	esi, [esp + 0xe8]
  542ea3: 89 74 24 04                  	mov	dword ptr [esp + 0x4], esi
  542ea7: 8d 94 24 78 01 00 00         	lea	edx, [esp + 0x178]
  542eae: 89 54 24 08                  	mov	dword ptr [esp + 0x8], edx
  542eb2: 8d 8c 24 60 01 00 00         	lea	ecx, [esp + 0x160]
  542eb9: 89 4c 24 0c                  	mov	dword ptr [esp + 0xc], ecx
  542ebd: 8d 9c 24 00 01 00 00         	lea	ebx, [esp + 0x100]
  542ec4: 89 5c 24 14                  	mov	dword ptr [esp + 0x14], ebx
  542ec8: 8d b4 24 80 01 00 00         	lea	esi, [esp + 0x180]
  542ecf: 89 74 24 18                  	mov	dword ptr [esp + 0x18], esi
  542ed3: 8d 94 24 18 01 00 00         	lea	edx, [esp + 0x118]
  542eda: 89 54 24 1c                  	mov	dword ptr [esp + 0x1c], edx
  542ede: 8d 8c 24 88 01 00 00         	lea	ecx, [esp + 0x188]
  542ee5: 89 4c 24 20                  	mov	dword ptr [esp + 0x20], ecx
  542ee9: 8d 5c 24 40                  	lea	ebx, [esp + 0x40]
  542eed: 8b d0                        	mov	edx, eax
  542eef: 83 e2 01                     	and	edx, 0x1
  542ef2: 89 5c 24 24                  	mov	dword ptr [esp + 0x24], ebx
  542ef6: 89 7c 24 28                  	mov	dword ptr [esp + 0x28], edi
  542efa: bf 1e 00 00 00               	mov	edi, 0x1e
  542eff: 83 e0 02                     	and	eax, 0x2
  542f02: 89 7c 24 30                  	mov	dword ptr [esp + 0x30], edi
  542f06: 89 7c 24 34                  	mov	dword ptr [esp + 0x34], edi
  542f0a: d1 e8                        	shr	eax
  542f0c: 88 54 24 38                  	mov	byte ptr [esp + 0x38], dl
  542f10: 88 44 24 3c                  	mov	byte ptr [esp + 0x3c], al
  542f14: e8 97 6e f8 ff               	call	0x4c9db0 <.text+0xc8db0>
  542f19: 81 c4 a4 01 00 00            	add	esp, 0x1a4
  542f1f: 5b                           	pop	ebx
  542f20: 5e                           	pop	esi
  542f21: 5f                           	pop	edi
  542f22: 8b e5                        	mov	esp, ebp
  542f24: 5d                           	pop	ebp
  542f25: c3                           	ret
  542f26: 8d 76 00                     	lea	esi, [esi]
  542f29: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  542f30: 55                           	push	ebp
  542f31: 8b ec                        	mov	ebp, esp
  542f33: 83 e4 f8                     	and	esp, -0x8
  542f36: 57                           	push	edi
  542f37: 56                           	push	esi
  542f38: 53                           	push	ebx
  542f39: 81 ec c4 00 00 00            	sub	esp, 0xc4
  542f3f: 8b 7d 0c                     	mov	edi, dword ptr [ebp + 0xc]
  542f42: 8d 74 24 48                  	lea	esi, [esp + 0x48]
  542f46: 57                           	push	edi
  542f47: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  542f4c: 56                           	push	esi
  542f4d: e8 fe bb ff ff               	call	0x53eb50 <.text+0x13db50>
  542f52: 8b 44 24 48                  	mov	eax, dword ptr [esp + 0x48]
  542f56: 8b 54 24 4c                  	mov	edx, dword ptr [esp + 0x4c]
  542f5a: 8b 5c 24 50                  	mov	ebx, dword ptr [esp + 0x50]
  542f5e: 8b 4c 24 5c                  	mov	ecx, dword ptr [esp + 0x5c]
  542f62: 89 44 24 60                  	mov	dword ptr [esp + 0x60], eax
  542f66: 8b 44 24 54                  	mov	eax, dword ptr [esp + 0x54]
  542f6a: 89 54 24 64                  	mov	dword ptr [esp + 0x64], edx
  542f6e: 8b 54 24 58                  	mov	edx, dword ptr [esp + 0x58]
  542f72: 89 5c 24 68                  	mov	dword ptr [esp + 0x68], ebx
  542f76: 89 44 24 6c                  	mov	dword ptr [esp + 0x6c], eax
  542f7a: 89 54 24 70                  	mov	dword ptr [esp + 0x70], edx
  542f7e: 89 4c 24 74                  	mov	dword ptr [esp + 0x74], ecx
  542f82: 57                           	push	edi
  542f83: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  542f88: e8 23 be ff ff               	call	0x53edb0 <.text+0x13ddb0>
  542f8d: dd 1c 24                     	fstp	qword ptr [esp]
  542f90: f2 0f 10 0c 24               	movsd	xmm1, qword ptr [esp]
  542f95: f3 0f 5a 05 2c 71 10 01      	cvtss2sd	xmm0, dword ptr [0x110712c]
  542f9d: f2 0f 59 c8                  	mulsd	xmm1, xmm0
  542fa1: 8b 5d 10                     	mov	ebx, dword ptr [ebp + 0x10]
  542fa4: f2 0f 11 8c 24 a8 00 00 00   	movsd	qword ptr [esp + 0xa8], xmm1
  542fad: 53                           	push	ebx
  542fae: b9 60 74 10 01               	mov	ecx, 0x1107460
  542fb3: 56                           	push	esi
  542fb4: e8 d7 60 01 00               	call	0x559090 <.text+0x158090>
  542fb9: 8b 44 24 48                  	mov	eax, dword ptr [esp + 0x48]
  542fbd: 8b 54 24 4c                  	mov	edx, dword ptr [esp + 0x4c]
  542fc1: 8b 74 24 50                  	mov	esi, dword ptr [esp + 0x50]
  542fc5: 8b 4c 24 5c                  	mov	ecx, dword ptr [esp + 0x5c]
  542fc9: 89 44 24 78                  	mov	dword ptr [esp + 0x78], eax
  542fcd: 8b 44 24 54                  	mov	eax, dword ptr [esp + 0x54]
  542fd1: 89 54 24 7c                  	mov	dword ptr [esp + 0x7c], edx
  542fd5: 8b 54 24 58                  	mov	edx, dword ptr [esp + 0x58]
  542fd9: 89 b4 24 80 00 00 00         	mov	dword ptr [esp + 0x80], esi
  542fe0: 89 84 24 84 00 00 00         	mov	dword ptr [esp + 0x84], eax
  542fe7: 89 94 24 88 00 00 00         	mov	dword ptr [esp + 0x88], edx
  542fee: 89 8c 24 8c 00 00 00         	mov	dword ptr [esp + 0x8c], ecx
  542ff5: 53                           	push	ebx
  542ff6: b9 60 74 10 01               	mov	ecx, 0x1107460
  542ffb: e8 e0 66 01 00               	call	0x5596e0 <.text+0x1586e0>
  543000: dd 1c 24                     	fstp	qword ptr [esp]
  543003: f2 0f 10 0c 24               	movsd	xmm1, qword ptr [esp]
  543008: f3 0f 5a 05 2c 71 10 01      	cvtss2sd	xmm0, dword ptr [0x110712c]
  543010: f2 0f 59 c8                  	mulsd	xmm1, xmm0
  543014: f2 0f 11 8c 24 b0 00 00 00   	movsd	qword ptr [esp + 0xb0], xmm1
  54301d: b9 e0 77 10 01               	mov	ecx, 0x11077e0
  543022: 66 0f ef c9                  	pxor	xmm1, xmm1
  543026: f2 0f 11 4c 24 48            	movsd	qword ptr [esp + 0x48], xmm1
  54302c: 8b 44 24 48                  	mov	eax, dword ptr [esp + 0x48]
  543030: 8b 54 24 4c                  	mov	edx, dword ptr [esp + 0x4c]
  543034: f2 0f 11 4c 24 50            	movsd	qword ptr [esp + 0x50], xmm1
  54303a: 8b 5c 24 50                  	mov	ebx, dword ptr [esp + 0x50]
  54303e: 8b 74 24 54                  	mov	esi, dword ptr [esp + 0x54]
  543042: f2 0f 11 4c 24 58            	movsd	qword ptr [esp + 0x58], xmm1
  543048: 89 84 24 90 00 00 00         	mov	dword ptr [esp + 0x90], eax
  54304f: 8b 44 24 58                  	mov	eax, dword ptr [esp + 0x58]
  543053: 89 94 24 94 00 00 00         	mov	dword ptr [esp + 0x94], edx
  54305a: 8b 54 24 5c                  	mov	edx, dword ptr [esp + 0x5c]
  54305e: 89 9c 24 98 00 00 00         	mov	dword ptr [esp + 0x98], ebx
  543065: 89 b4 24 9c 00 00 00         	mov	dword ptr [esp + 0x9c], esi
  54306c: 89 84 24 a0 00 00 00         	mov	dword ptr [esp + 0xa0], eax
  543073: 89 94 24 a4 00 00 00         	mov	dword ptr [esp + 0xa4], edx
  54307a: e8 11 29 03 00               	call	0x575990 <.text+0x174990>
  54307f: dd 1c 24                     	fstp	qword ptr [esp]
  543082: f2 0f 10 0c 24               	movsd	xmm1, qword ptr [esp]
  543087: f3 0f 5a 05 2c 71 10 01      	cvtss2sd	xmm0, dword ptr [0x110712c]
  54308f: f2 0f 59 c8                  	mulsd	xmm1, xmm0
  543093: f2 0f 11 8c 24 b8 00 00 00   	movsd	qword ptr [esp + 0xb8], xmm1
  54309c: 57                           	push	edi
  54309d: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  5430a2: e8 a9 b5 ff ff               	call	0x53e650 <.text+0x13d650>
  5430a7: 8d 1c 24                     	lea	ebx, [esp]
  5430aa: 53                           	push	ebx
  5430ab: 8b c8                        	mov	ecx, eax
  5430ad: e8 de 7a ff ff               	call	0x53ab90 <.text+0x139b90>
  5430b2: 8d bc 24 a8 00 00 00         	lea	edi, [esp + 0xa8]
  5430b9: 8d 74 24 78                  	lea	esi, [esp + 0x78]
  5430bd: 8d 8c 24 b0 00 00 00         	lea	ecx, [esp + 0xb0]
  5430c4: 8d 94 24 90 00 00 00         	lea	edx, [esp + 0x90]
  5430cb: 8d 84 24 b8 00 00 00         	lea	eax, [esp + 0xb8]
  5430d2: 53                           	push	ebx
  5430d3: 50                           	push	eax
  5430d4: 52                           	push	edx
  5430d5: 51                           	push	ecx
  5430d6: 56                           	push	esi
  5430d7: 57                           	push	edi
  5430d8: 8d 5c 24 78                  	lea	ebx, [esp + 0x78]
  5430dc: 53                           	push	ebx
  5430dd: ff 75 08                     	push	dword ptr [ebp + 0x8]
  5430e0: e8 fb 56 f8 ff               	call	0x4c87e0 <.text+0xc77e0>
  5430e5: 83 c4 20                     	add	esp, 0x20
  5430e8: 81 c4 c4 00 00 00            	add	esp, 0xc4
  5430ee: 5b                           	pop	ebx
  5430ef: 5e                           	pop	esi
  5430f0: 5f                           	pop	edi
  5430f1: 8b e5                        	mov	esp, ebp
  5430f3: 5d                           	pop	ebp
  5430f4: c3                           	ret
  5430f5: 8d 74 26 00                  	lea	esi, [esi + eiz]
  5430f9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  543100: 55                           	push	ebp
  543101: 8b ec                        	mov	ebp, esp
  543103: 83 e4 f8                     	and	esp, -0x8
  543106: 57                           	push	edi
  543107: 56                           	push	esi
  543108: 53                           	push	ebx
  543109: 81 ec a4 01 00 00            	sub	esp, 0x1a4
  54310f: 8b 7d 0c                     	mov	edi, dword ptr [ebp + 0xc]
  543112: 8d b4 24 d0 00 00 00         	lea	esi, [esp + 0xd0]
  543119: 57                           	push	edi
  54311a: b9 60 74 10 01               	mov	ecx, 0x1107460
  54311f: 56                           	push	esi
  543120: e8 6b 5f 01 00               	call	0x559090 <.text+0x158090>
  543125: 8b 84 24 d0 00 00 00         	mov	eax, dword ptr [esp + 0xd0]
  54312c: 8b 94 24 d4 00 00 00         	mov	edx, dword ptr [esp + 0xd4]
  543133: 8b 9c 24 d8 00 00 00         	mov	ebx, dword ptr [esp + 0xd8]
  54313a: 8b 8c 24 e4 00 00 00         	mov	ecx, dword ptr [esp + 0xe4]
  543141: 89 84 24 e8 00 00 00         	mov	dword ptr [esp + 0xe8], eax
  543148: 8b 84 24 dc 00 00 00         	mov	eax, dword ptr [esp + 0xdc]
  54314f: 89 94 24 ec 00 00 00         	mov	dword ptr [esp + 0xec], edx
  543156: 8b 94 24 e0 00 00 00         	mov	edx, dword ptr [esp + 0xe0]
  54315d: 89 9c 24 f0 00 00 00         	mov	dword ptr [esp + 0xf0], ebx
  543164: 89 84 24 f4 00 00 00         	mov	dword ptr [esp + 0xf4], eax
  54316b: 89 94 24 f8 00 00 00         	mov	dword ptr [esp + 0xf8], edx
  543172: 89 8c 24 fc 00 00 00         	mov	dword ptr [esp + 0xfc], ecx
  543179: 57                           	push	edi
  54317a: b9 60 74 10 01               	mov	ecx, 0x1107460
  54317f: e8 5c 65 01 00               	call	0x5596e0 <.text+0x1586e0>
  543184: dd 9c 24 98 01 00 00         	fstp	qword ptr [esp + 0x198]
  54318b: f2 0f 10 8c 24 98 01 00 00   	movsd	xmm1, qword ptr [esp + 0x198]
  543194: f3 0f 5a 05 2c 71 10 01      	cvtss2sd	xmm0, dword ptr [0x110712c]
  54319c: f2 0f 59 c8                  	mulsd	xmm1, xmm0
  5431a0: 8b 5d 10                     	mov	ebx, dword ptr [ebp + 0x10]
  5431a3: f2 0f 11 8c 24 80 01 00 00   	movsd	qword ptr [esp + 0x180], xmm1
  5431ac: 53                           	push	ebx
  5431ad: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  5431b2: 56                           	push	esi
  5431b3: e8 98 b9 ff ff               	call	0x53eb50 <.text+0x13db50>
  5431b8: 8b 84 24 d0 00 00 00         	mov	eax, dword ptr [esp + 0xd0]
  5431bf: 8b 94 24 d4 00 00 00         	mov	edx, dword ptr [esp + 0xd4]
  5431c6: 8b b4 24 d8 00 00 00         	mov	esi, dword ptr [esp + 0xd8]
  5431cd: 8b 8c 24 e4 00 00 00         	mov	ecx, dword ptr [esp + 0xe4]
  5431d4: 89 84 24 00 01 00 00         	mov	dword ptr [esp + 0x100], eax
  5431db: 8b 84 24 dc 00 00 00         	mov	eax, dword ptr [esp + 0xdc]
  5431e2: 89 94 24 04 01 00 00         	mov	dword ptr [esp + 0x104], edx
  5431e9: 8b 94 24 e0 00 00 00         	mov	edx, dword ptr [esp + 0xe0]
  5431f0: 89 b4 24 08 01 00 00         	mov	dword ptr [esp + 0x108], esi
  5431f7: 89 84 24 0c 01 00 00         	mov	dword ptr [esp + 0x10c], eax
  5431fe: 89 94 24 10 01 00 00         	mov	dword ptr [esp + 0x110], edx
  543205: 89 8c 24 14 01 00 00         	mov	dword ptr [esp + 0x114], ecx
  54320c: 53                           	push	ebx
  54320d: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  543212: e8 99 bb ff ff               	call	0x53edb0 <.text+0x13ddb0>
  543217: dd 9c 24 98 01 00 00         	fstp	qword ptr [esp + 0x198]
  54321e: f2 0f 10 8c 24 98 01 00 00   	movsd	xmm1, qword ptr [esp + 0x198]
  543227: f3 0f 5a 05 2c 71 10 01      	cvtss2sd	xmm0, dword ptr [0x110712c]
  54322f: f2 0f 59 c8                  	mulsd	xmm1, xmm0
  543233: f2 0f 11 8c 24 88 01 00 00   	movsd	qword ptr [esp + 0x188], xmm1
  54323c: b9 e0 77 10 01               	mov	ecx, 0x11077e0
  543241: 66 0f ef c9                  	pxor	xmm1, xmm1
  543245: f2 0f 11 8c 24 d0 00 00 00   	movsd	qword ptr [esp + 0xd0], xmm1
  54324e: 8b 84 24 d0 00 00 00         	mov	eax, dword ptr [esp + 0xd0]
  543255: 8b 94 24 d4 00 00 00         	mov	edx, dword ptr [esp + 0xd4]
  54325c: f2 0f 11 8c 24 d8 00 00 00   	movsd	qword ptr [esp + 0xd8], xmm1
  543265: 8b 9c 24 d8 00 00 00         	mov	ebx, dword ptr [esp + 0xd8]
  54326c: 8b b4 24 dc 00 00 00         	mov	esi, dword ptr [esp + 0xdc]
  543273: f2 0f 11 8c 24 e0 00 00 00   	movsd	qword ptr [esp + 0xe0], xmm1
  54327c: 89 84 24 18 01 00 00         	mov	dword ptr [esp + 0x118], eax
  543283: 8b 84 24 e0 00 00 00         	mov	eax, dword ptr [esp + 0xe0]
  54328a: 89 94 24 1c 01 00 00         	mov	dword ptr [esp + 0x11c], edx
  543291: 8b 94 24 e4 00 00 00         	mov	edx, dword ptr [esp + 0xe4]
  543298: 89 9c 24 20 01 00 00         	mov	dword ptr [esp + 0x120], ebx
  54329f: 89 b4 24 24 01 00 00         	mov	dword ptr [esp + 0x124], esi
  5432a6: 89 84 24 28 01 00 00         	mov	dword ptr [esp + 0x128], eax
  5432ad: 89 94 24 2c 01 00 00         	mov	dword ptr [esp + 0x12c], edx
  5432b4: e8 d7 26 03 00               	call	0x575990 <.text+0x174990>
  5432b9: dd 9c 24 98 01 00 00         	fstp	qword ptr [esp + 0x198]
  5432c0: f2 0f 10 8c 24 98 01 00 00   	movsd	xmm1, qword ptr [esp + 0x198]
  5432c9: f3 0f 5a 05 2c 71 10 01      	cvtss2sd	xmm0, dword ptr [0x110712c]
  5432d1: f2 0f 59 c8                  	mulsd	xmm1, xmm0
  5432d5: f2 0f 11 8c 24 90 01 00 00   	movsd	qword ptr [esp + 0x190], xmm1
  5432de: 57                           	push	edi
  5432df: b9 60 74 10 01               	mov	ecx, 0x1107460
  5432e4: e8 97 59 01 00               	call	0x558c80 <.text+0x157c80>
  5432e9: 8d 74 24 40                  	lea	esi, [esp + 0x40]
  5432ed: 56                           	push	esi
  5432ee: 8b c8                        	mov	ecx, eax
  5432f0: e8 7b 2e 01 00               	call	0x556170 <.text+0x155170>
  5432f5: 57                           	push	edi
  5432f6: b9 60 74 10 01               	mov	ecx, 0x1107460
  5432fb: e8 80 59 01 00               	call	0x558c80 <.text+0x157c80>
  543300: 8d 9c 24 88 00 00 00         	lea	ebx, [esp + 0x88]
  543307: 53                           	push	ebx
  543308: 8b c8                        	mov	ecx, eax
  54330a: e8 c1 2e 01 00               	call	0x5561d0 <.text+0x1551d0>
  54330f: 57                           	push	edi
  543310: b9 60 74 10 01               	mov	ecx, 0x1107460
  543315: e8 66 59 01 00               	call	0x558c80 <.text+0x157c80>
  54331a: 8b c8                        	mov	ecx, eax
  54331c: 8d 84 24 30 01 00 00         	lea	eax, [esp + 0x130]
  543323: 8d 94 24 48 01 00 00         	lea	edx, [esp + 0x148]
  54332a: 8d bc 24 60 01 00 00         	lea	edi, [esp + 0x160]
  543331: 57                           	push	edi
  543332: 52                           	push	edx
  543333: 50                           	push	eax
  543334: e8 17 2f 01 00               	call	0x556250 <.text+0x155250>
  543339: 8b 55 08                     	mov	edx, dword ptr [ebp + 0x8]
  54333c: 0f be 05 60 93 fe 00         	movsx	eax, byte ptr [0xfe9360]
  543343: f3 0f 10 8a 2c 02 00 00      	movss	xmm1, dword ptr [edx + 0x22c]
  54334b: 85 c0                        	test	eax, eax
  54334d: 75 2e                        	jne	0x54337d <.text+0x14237d>
  54334f: f3 0f 11 8c 24 78 01 00 00   	movss	dword ptr [esp + 0x178], xmm1
  543358: e8 a3 04 00 00               	call	0x543800 <.text+0x142800>
  54335d: f3 0f 10 8c 24 78 01 00 00   	movss	xmm1, dword ptr [esp + 0x178]
  543366: 8b 55 08                     	mov	edx, dword ptr [ebp + 0x8]
  543369: d9 9c 24 98 01 00 00         	fstp	dword ptr [esp + 0x198]
  543370: f3 0f 10 84 24 98 01 00 00   	movss	xmm0, dword ptr [esp + 0x198]
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
  5433c1: 89 7c 24 18                  	mov	dword ptr [esp + 0x18], edi
  5433c5: 8d 94 24 18 01 00 00         	lea	edx, [esp + 0x118]
  5433cc: 89 54 24 1c                  	mov	dword ptr [esp + 0x1c], edx
  5433d0: 8d 8c 24 90 01 00 00         	lea	ecx, [esp + 0x190]
  5433d7: 89 4c 24 20                  	mov	dword ptr [esp + 0x20], ecx
  5433db: 89 74 24 24                  	mov	dword ptr [esp + 0x24], esi
  5433df: 89 5c 24 28                  	mov	dword ptr [esp + 0x28], ebx
  5433e3: be 1e 00 00 00               	mov	esi, 0x1e
  5433e8: 8b d8                        	mov	ebx, eax
  5433ea: 89 74 24 30                  	mov	dword ptr [esp + 0x30], esi
  5433ee: 89 74 24 34                  	mov	dword ptr [esp + 0x34], esi
  5433f2: 83 e3 01                     	and	ebx, 0x1
  5433f5: 83 e0 02                     	and	eax, 0x2
  5433f8: 88 5c 24 38                  	mov	byte ptr [esp + 0x38], bl
  5433fc: d1 e8                        	shr	eax
  5433fe: 88 44 24 3c                  	mov	byte ptr [esp + 0x3c], al
  543402: e8 a9 69 f8 ff               	call	0x4c9db0 <.text+0xc8db0>
  543407: 81 c4 a4 01 00 00            	add	esp, 0x1a4
  54340d: 5b                           	pop	ebx
  54340e: 5e                           	pop	esi
  54340f: 5f                           	pop	edi
  543410: 8b e5                        	mov	esp, ebp
  543412: 5d                           	pop	ebp
  543413: c3                           	ret
  543414: 8d b6 00 00 00 00            	lea	esi, [esi]
  54341a: 8d bf 00 00 00 00            	lea	edi, [edi]
  543420: f2 0f 10 05 70 25 c3 00      	movsd	xmm0, qword ptr [0xc32570]
  543428: f2 0f 11 05 40 71 10 01      	movsd	qword ptr [0x1107140], xmm0
  543430: c3                           	ret
  543431: 90                           	nop
  543432: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  543439: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  543440: f2 0f 10 05 78 25 c3 00      	movsd	xmm0, qword ptr [0xc32578]
  543448: f2 0f 11 05 48 71 10 01      	movsd	qword ptr [0x1107148], xmm0
  543450: c3                           	ret
  543451: 90                           	nop
  543452: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  543459: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  543460: f2 0f 10 05 80 25 c3 00      	movsd	xmm0, qword ptr [0xc32580]
  543468: e8 97 b9 54 00               	call	0xa8ee04 <.text+0x68de04>
  54346d: f2 0f 10 0d 40 71 10 01      	movsd	xmm1, qword ptr [0x1107140]
  543475: f2 0f 5e c8                  	divsd	xmm1, xmm0
  543479: f2 0f 11 0d 50 71 10 01      	movsd	qword ptr [0x1107150], xmm1
  543481: c3                           	ret
  543482: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  543489: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  543490: f2 0f 10 05 40 71 10 01      	movsd	xmm0, qword ptr [0x1107140]
  543498: f2 0f 59 05 88 25 c3 00      	mulsd	xmm0, qword ptr [0xc32588]
  5434a0: f2 0f 5a c8                  	cvtsd2ss	xmm1, xmm0
  5434a4: f3 0f 11 0d 58 71 10 01      	movss	dword ptr [0x1107158], xmm1
  5434ac: c3                           	ret
  5434ad: 8d 76 00                     	lea	esi, [esi]
  5434b0: f3 0f 10 05 70 26 c3 00      	movss	xmm0, dword ptr [0xc32670]
  5434b8: f3 0f 5e 05 58 71 10 01      	divss	xmm0, dword ptr [0x1107158]
  5434c0: f3 0f 11 05 5c 71 10 01      	movss	dword ptr [0x110715c], xmm0
  5434c8: c3                           	ret
  5434c9: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  5434d0: f2 0f 10 05 48 71 10 01      	movsd	xmm0, qword ptr [0x1107148]
  5434d8: f2 0f 59 05 90 25 c3 00      	mulsd	xmm0, qword ptr [0xc32590]
  5434e0: f2 0f 5a c8                  	cvtsd2ss	xmm1, xmm0
  5434e4: f3 0f 11 0d 60 71 10 01      	movss	dword ptr [0x1107160], xmm1
  5434ec: c3                           	ret
  5434ed: 8d 76 00                     	lea	esi, [esi]
  5434f0: f3 0f 10 05 74 26 c3 00      	movss	xmm0, dword ptr [0xc32674]
  5434f8: f3 0f 5e 05 60 71 10 01      	divss	xmm0, dword ptr [0x1107160]
  543500: f3 0f 11 05 64 71 10 01      	movss	dword ptr [0x1107164], xmm0
  543508: c3                           	ret
  543509: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  543510: f2 0f 10 05 50 71 10 01      	movsd	xmm0, qword ptr [0x1107150]
  543518: f2 0f 59 05 98 25 c3 00      	mulsd	xmm0, qword ptr [0xc32598]
  543520: f2 0f 5a c8                  	cvtsd2ss	xmm1, xmm0
  543524: f3 0f 11 0d 68 71 10 01      	movss	dword ptr [0x1107168], xmm1
  54352c: c3                           	ret
  54352d: 8d 76 00                     	lea	esi, [esi]
  543530: f3 0f 10 05 78 26 c3 00      	movss	xmm0, dword ptr [0xc32678]
  543538: f3 0f 5e 05 68 71 10 01      	divss	xmm0, dword ptr [0x1107168]
  543540: f3 0f 11 05 6c 71 10 01      	movss	dword ptr [0x110716c], xmm0
  543548: c3                           	ret
  543549: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  543550: f2 0f 10 05 40 71 10 01      	movsd	xmm0, qword ptr [0x1107140]
  543558: f2 0f 5e 05 50 71 10 01      	divsd	xmm0, qword ptr [0x1107150]
  543560: f2 0f 5a c8                  	cvtsd2ss	xmm1, xmm0
  543564: f3 0f 11 0d 70 71 10 01      	movss	dword ptr [0x1107170], xmm1
  54356c: c3                           	ret
  54356d: 8d 76 00                     	lea	esi, [esi]
  543570: f2 0f 10 05 50 71 10 01      	movsd	xmm0, qword ptr [0x1107150]
  543578: f2 0f 5e 05 40 71 10 01      	divsd	xmm0, qword ptr [0x1107140]
  543580: f2 0f 5a c8                  	cvtsd2ss	xmm1, xmm0
  543584: f3 0f 11 0d 74 71 10 01      	movss	dword ptr [0x1107174], xmm1
  54358c: c3                           	ret
  54358d: 8d 76 00                     	lea	esi, [esi]
  543590: f2 0f 10 05 50 71 10 01      	movsd	xmm0, qword ptr [0x1107150]
  543598: f2 0f 5e 05 48 71 10 01      	divsd	xmm0, qword ptr [0x1107148]
  5435a0: f2 0f 5a c8                  	cvtsd2ss	xmm1, xmm0
  5435a4: f3 0f 11 0d 78 71 10 01      	movss	dword ptr [0x1107178], xmm1
  5435ac: c3                           	ret
  5435ad: 8d 76 00                     	lea	esi, [esi]
  5435b0: f2 0f 10 05 48 71 10 01      	movsd	xmm0, qword ptr [0x1107148]
  5435b8: f2 0f 5e 05 50 71 10 01      	divsd	xmm0, qword ptr [0x1107150]
  5435c0: f2 0f 5a c8                  	cvtsd2ss	xmm1, xmm0
  5435c4: f3 0f 11 0d 7c 71 10 01      	movss	dword ptr [0x110717c], xmm1
  5435cc: c3                           	ret
  5435cd: 8d 76 00                     	lea	esi, [esi]
  5435d0: 0f bf 05 7c 26 c3 00         	movsx	eax, word ptr [0xc3267c]
  5435d7: f3 0f 2a c8                  	cvtsi2ss	xmm1, eax
  5435db: f3 0f 59 0d 90 26 c3 00      	mulss	xmm1, dword ptr [0xc32690]
  5435e3: 0f bf 15 7e 26 c3 00         	movsx	edx, word ptr [0xc3267e]
  5435ea: f3 0f 2a c2                  	cvtsi2ss	xmm0, edx
  5435ee: f3 0f 59 05 94 26 c3 00      	mulss	xmm0, dword ptr [0xc32694]
  5435f6: 0f bf 0d 86 26 c3 00         	movsx	ecx, word ptr [0xc32686]
  5435fd: f3 0f 2a d9                  	cvtsi2ss	xmm3, ecx
  543601: f3 0f 58 c8                  	addss	xmm1, xmm0
  543605: f3 0f 58 0d 98 26 c3 00      	addss	xmm1, dword ptr [0xc32698]
  54360d: 0f bf 05 88 26 c3 00         	movsx	eax, word ptr [0xc32688]
  543614: f3 0f 2a d0                  	cvtsi2ss	xmm2, eax
  543618: f3 0f 59 15 9c 26 c3 00      	mulss	xmm2, dword ptr [0xc3269c]
  543620: f3 0f 11 0d 80 71 10 01      	movss	dword ptr [0x1107180], xmm1
  543628: f3 0f 5c da                  	subss	xmm3, xmm2
  54362c: f3 0f 5c 1d a0 26 c3 00      	subss	xmm3, dword ptr [0xc326a0]
  543634: f3 0f 11 1d 84 71 10 01      	movss	dword ptr [0x1107184], xmm3
  54363c: c3                           	ret
  54363d: 8d 76 00                     	lea	esi, [esi]
  543640: 0f bf 05 a4 26 c3 00         	movsx	eax, word ptr [0xc326a4]
  543647: f3 0f 2a c8                  	cvtsi2ss	xmm1, eax
  54364b: f3 0f 59 0d b8 26 c3 00      	mulss	xmm1, dword ptr [0xc326b8]
  543653: 0f bf 15 a6 26 c3 00         	movsx	edx, word ptr [0xc326a6]
  54365a: f3 0f 2a c2                  	cvtsi2ss	xmm0, edx
  54365e: f3 0f 59 05 bc 26 c3 00      	mulss	xmm0, dword ptr [0xc326bc]
  543666: 0f bf 0d ae 26 c3 00         	movsx	ecx, word ptr [0xc326ae]
  54366d: f3 0f 2a d9                  	cvtsi2ss	xmm3, ecx
  543671: f3 0f 58 c8                  	addss	xmm1, xmm0
  543675: f3 0f 58 0d c0 26 c3 00      	addss	xmm1, dword ptr [0xc326c0]
  54367d: 0f bf 05 b0 26 c3 00         	movsx	eax, word ptr [0xc326b0]
  543684: f3 0f 2a d0                  	cvtsi2ss	xmm2, eax
  543688: f3 0f 59 15 c4 26 c3 00      	mulss	xmm2, dword ptr [0xc326c4]
  543690: f3 0f 11 0d 88 71 10 01      	movss	dword ptr [0x1107188], xmm1
  543698: f3 0f 58 da                  	addss	xmm3, xmm2
  54369c: f3 0f 11 1d 8c 71 10 01      	movss	dword ptr [0x110718c], xmm3
  5436a4: c3                           	ret
  5436a5: 8d 74 26 00                  	lea	esi, [esi + eiz]
  5436a9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  5436b0: f3 0f 10 05 c8 26 c3 00      	movss	xmm0, dword ptr [0xc326c8]
  5436b8: f3 0f 59 05 70 71 10 01      	mulss	xmm0, dword ptr [0x1107170]
  5436c0: f3 0f 11 05 90 71 10 01      	movss	dword ptr [0x1107190], xmm0
  5436c8: c3                           	ret
  5436c9: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  5436d0: f3 0f 5a 05 90 71 10 01      	cvtss2sd	xmm0, dword ptr [0x1107190]
  5436d8: f2 0f 59 05 a0 25 c3 00      	mulsd	xmm0, qword ptr [0xc325a0]
  5436e0: f2 0f 5a c8                  	cvtsd2ss	xmm1, xmm0
  5436e4: f3 0f 11 0d 94 71 10 01      	movss	dword ptr [0x1107194], xmm1
  5436ec: c3                           	ret
  5436ed: 8d 76 00                     	lea	esi, [esi]
  5436f0: c7 05 a0 71 10 01 00 00 80 3f	mov	dword ptr [0x11071a0], 0x3f800000
  5436fa: b8 66 66 66 3f               	mov	eax, 0x3f666666
  5436ff: c7 05 a4 71 10 01 cd cc 4c 3f	mov	dword ptr [0x11071a4], 0x3f4ccccd
  543709: a3 98 71 10 01               	mov	dword ptr [0x1107198], eax
  54370e: a3 9c 71 10 01               	mov	dword ptr [0x110719c], eax
  543713: c3                           	ret
  543714: 8d b6 00 00 00 00            	lea	esi, [esi]
  54371a: 8d bf 00 00 00 00            	lea	edi, [edi]
  543720: c7 05 a8 71 10 01 00 00 34 42	mov	dword ptr [0x11071a8], 0x42340000
  54372a: c3                           	ret
  54372b: 90                           	nop
  54372c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  543730: c7 05 b4 71 10 01 00 00 b4 41	mov	dword ptr [0x11071b4], 0x41b40000
  54373a: c3                           	ret
  54373b: 90                           	nop
  54373c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  543740: 83 ec 08                     	sub	esp, 0x8
  543743: f3 0f 10 05 e0 26 c3 00      	movss	xmm0, dword ptr [0xc326e0]
  54374b: f3 0f 59 05 38 75 10 01      	mulss	xmm0, dword ptr [0x1107538]
  543753: f3 0f 11 04 24               	movss	dword ptr [esp], xmm0
  543758: d9 04 24                     	fld	dword ptr [esp]
  54375b: 83 c4 08                     	add	esp, 0x8
  54375e: c3                           	ret
  54375f: 90                           	nop
  543760: d9 05 a8 71 10 01            	fld	dword ptr [0x11071a8]
  543766: c3                           	ret
  543767: 8b f6                        	mov	esi, esi
  543769: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  543770: d9 05 ac 71 10 01            	fld	dword ptr [0x11071ac]
  543776: c3                           	ret
  543777: 8b f6                        	mov	esi, esi
  543779: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  543780: d9 05 b0 71 10 01            	fld	dword ptr [0x11071b0]
  543786: c3                           	ret
  543787: 8b f6                        	mov	esi, esi
  543789: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  543790: 8b 44 24 04                  	mov	eax, dword ptr [esp + 0x4]
  543794: a3 ac 71 10 01               	mov	dword ptr [0x11071ac], eax
  543799: c3                           	ret
  54379a: 8d b6 00 00 00 00            	lea	esi, [esi]
  5437a0: d9 05 b4 1b d7 00            	fld	dword ptr [0xd71bb4]
  5437a6: c3                           	ret
  5437a7: 8b f6                        	mov	esi, esi
  5437a9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  5437b0: d9 05 b4 71 10 01            	fld	dword ptr [0x11071b4]
  5437b6: c3                           	ret
  5437b7: 8b f6                        	mov	esi, esi
  5437b9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  5437c0: 8b 44 24 04                  	mov	eax, dword ptr [esp + 0x4]
  5437c4: f2 0f 5a 00                  	cvtsd2ss	xmm0, qword ptr [eax]
  5437c8: f3 0f 11 05 b4 1b d7 00      	movss	dword ptr [0xd71bb4], xmm0
  5437d0: c3                           	ret
  5437d1: 90                           	nop
  5437d2: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  5437d9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  5437e0: 8b 44 24 04                  	mov	eax, dword ptr [esp + 0x4]
  5437e4: f2 0f 5a 00                  	cvtsd2ss	xmm0, qword ptr [eax]
  5437e8: f3 0f 11 05 b4 71 10 01      	movss	dword ptr [0x11071b4], xmm0
  5437f0: c3                           	ret
  5437f1: 90                           	nop
  5437f2: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  5437f9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  543800: 83 ec 08                     	sub	esp, 0x8
  543803: f3 0f 10 0d ac 71 10 01      	movss	xmm1, dword ptr [0x11071ac]
  54380b: f3 0f 10 05 e4 26 c3 00      	movss	xmm0, dword ptr [0xc326e4]
  543813: f3 0f 59 05 38 75 10 01      	mulss	xmm0, dword ptr [0x1107538]
  54381b: f3 0f 5e c8                  	divss	xmm1, xmm0
  54381f: f3 0f 11 0c 24               	movss	dword ptr [esp], xmm1
  543824: d9 04 24                     	fld	dword ptr [esp]
  543827: 83 c4 08                     	add	esp, 0x8
  54382a: c3                           	ret
  54382b: 90                           	nop
  54382c: 8d 74 26 00                  	lea	esi, [esi + eiz]
