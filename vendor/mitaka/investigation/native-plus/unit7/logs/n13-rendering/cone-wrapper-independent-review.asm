
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
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
