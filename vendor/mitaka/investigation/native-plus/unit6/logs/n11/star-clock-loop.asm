
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5bed60: e9 03 ff ff ff               	jmp	0x5bec68 <.text+0x1bdc68>
  5bed65: 8b 46 14                     	mov	eax, dword ptr [esi + 0x14]
  5bed68: 8d 54 30 04                  	lea	edx, [eax + esi + 0x4]
  5bed6c: 3b d3                        	cmp	edx, ebx
  5bed6e: 0f 86 6b fe ff ff            	jbe	0x5bebdf <.text+0x1bdbdf>
  5bed74: b8 01 00 00 00               	mov	eax, 0x1
  5bed79: e9 63 fe ff ff               	jmp	0x5bebe1 <.text+0x1bdbe1>
  5bed7e: 8b f6                        	mov	esi, esi
  5bed80: b8 70 c5 2b 01               	mov	eax, 0x12bc570
  5bed85: e9 fc 01 4d 00               	jmp	0xa8ef86 <.text+0x68df86>
  5bed8a: 90                           	nop
  5bed8b: 90                           	nop
  5bed8c: 90                           	nop
  5bed8d: 90                           	nop
  5bed8e: 90                           	nop
  5bed8f: 90                           	nop
  5bed90: ff 74 24 08                  	push	dword ptr [esp + 0x8]
  5bed94: ff 74 24 08                  	push	dword ptr [esp + 0x8]
  5bed98: e8 b3 fa fd ff               	call	0x59e850 <.text+0x19d850>
  5bed9d: 83 c4 08                     	add	esp, 0x8
  5beda0: c2 08 00                     	ret	0x8
  5beda3: 8d b6 00 00 00 00            	lea	esi, [esi]
  5beda9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  5bedb0: e8 eb a2 ff ff               	call	0x5b90a0 <.text+0x1b80a0>
  5bedb5: 0f b6 54 24 04               	movzx	edx, byte ptr [esp + 0x4]
  5bedba: 52                           	push	edx
  5bedbb: 8b c8                        	mov	ecx, eax
  5bedbd: e8 ce af ff ff               	call	0x5b9d90 <.text+0x1b8d90>
  5bedc2: c2 04 00                     	ret	0x4
  5bedc5: 8d 74 26 00                  	lea	esi, [esi + eiz]
  5bedc9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  5bedd0: 55                           	push	ebp
  5bedd1: 8b ec                        	mov	ebp, esp
  5bedd3: 6a ff                        	push	-0x1
  5bedd5: 68 00 c2 bf 00               	push	0xbfc200
  5bedda: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  5bede0: 50                           	push	eax
  5bede1: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  5bede8: 81 ec 80 00 00 00            	sub	esp, 0x80
  5bedee: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
  5bedf1: 89 5d e0                     	mov	dword ptr [ebp - 0x20], ebx
  5bedf4: 89 7d d8                     	mov	dword ptr [ebp - 0x28], edi
  5bedf7: 89 75 dc                     	mov	dword ptr [ebp - 0x24], esi
  5bedfa: a1 10 53 d8 00               	mov	eax, dword ptr [0xd85310]
  5bedff: 89 45 ec                     	mov	dword ptr [ebp - 0x14], eax
  5bee02: e8 59 43 21 00               	call	0x7d3160 <.text+0x3d2160>
  5bee07: 8b 10                        	mov	edx, dword ptr [eax]
  5bee09: 8b c8                        	mov	ecx, eax
  5bee0b: ff 12                        	call	dword ptr [edx]
  5bee0d: e8 9e f8 19 00               	call	0x75e6b0 <.text+0x35d6b0>
  5bee12: 0f b6 c0                     	movzx	eax, al
  5bee15: 85 c0                        	test	eax, eax
  5bee17: 74 0c                        	je	0x5bee25 <.text+0x1bde25>
  5bee19: e8 52 96 01 00               	call	0x5d8470 <.text+0x1d7470>
  5bee1e: 8b c8                        	mov	ecx, eax
  5bee20: e8 bb 9d 01 00               	call	0x5d8be0 <.text+0x1d7be0>
  5bee25: e8 46 06 01 00               	call	0x5cf470 <.text+0x1ce470>
  5bee2a: 8b c8                        	mov	ecx, eax
  5bee2c: e8 5f 4a 01 00               	call	0x5d3890 <.text+0x1d2890>
  5bee31: e8 3a 06 01 00               	call	0x5cf470 <.text+0x1ce470>
  5bee36: 8b c8                        	mov	ecx, eax
  5bee38: e8 53 89 01 00               	call	0x5d7790 <.text+0x1d6790>
  5bee3d: 83 3d 30 4c 19 01 00         	cmp	dword ptr [0x1194c30], 0x0
  5bee44: d9 1d 94 19 d7 00            	fstp	dword ptr [0xd71994]
  5bee4a: 0f 85 ed 04 00 00            	jne	0x5bf33d <.text+0x1be33d>
  5bee50: 33 db                        	xor	ebx, ebx
  5bee52: e8 69 74 00 00               	call	0x5c62c0 <.text+0x1c52c0>
  5bee57: 8b c8                        	mov	ecx, eax
  5bee59: e8 42 75 00 00               	call	0x5c63a0 <.text+0x1c53a0>
  5bee5e: 0f b6 c0                     	movzx	eax, al
  5bee61: 85 c0                        	test	eax, eax
  5bee63: 74 1f                        	je	0x5bee84 <.text+0x1bde84>
  5bee65: e8 56 74 00 00               	call	0x5c62c0 <.text+0x1c52c0>
  5bee6a: 8b c8                        	mov	ecx, eax
  5bee6c: e8 9f 75 00 00               	call	0x5c6410 <.text+0x1c5410>
  5bee71: 0f b6 c0                     	movzx	eax, al
  5bee74: 85 c0                        	test	eax, eax
  5bee76: 74 0c                        	je	0x5bee84 <.text+0x1bde84>
  5bee78: e8 43 74 00 00               	call	0x5c62c0 <.text+0x1c52c0>
  5bee7d: 8b c8                        	mov	ecx, eax
  5bee7f: e8 0c 7a 00 00               	call	0x5c6890 <.text+0x1c5890>
  5bee84: e8 f7 37 4a 00               	call	0xa62680 <.text+0x661680>
  5bee89: c6 40 60 01                  	mov	byte ptr [eax + 0x60], 0x1
  5bee8d: e8 ee 37 4a 00               	call	0xa62680 <.text+0x661680>
  5bee92: 8b f0                        	mov	esi, eax
  5bee94: c7 45 a8 0f 00 00 00         	mov	dword ptr [ebp - 0x58], 0xf
  5bee9b: 89 5d a4                     	mov	dword ptr [ebp - 0x5c], ebx
  5bee9e: 8d 55 94                     	lea	edx, [ebp - 0x6c]
  5beea1: c7 45 e8 2e 00 00 00         	mov	dword ptr [ebp - 0x18], 0x2e
  5beea8: 88 1a                        	mov	byte ptr [edx], bl
  5beeaa: 8b 7d a8                     	mov	edi, dword ptr [ebp - 0x58]
  5beead: 8b 4d 94                     	mov	ecx, dword ptr [ebp - 0x6c]
  5beeb0: 8d 45 90                     	lea	eax, [ebp - 0x70]
  5beeb3: 89 45 c4                     	mov	dword ptr [ebp - 0x3c], eax
  5beeb6: b8 90 63 c3 00               	mov	eax, 0xc36390
  5beebb: 89 45 e4                     	mov	dword ptr [ebp - 0x1c], eax
  5beebe: 83 ff 10                     	cmp	edi, 0x10
  5beec1: 0f 42 ca                     	cmovb	ecx, edx
  5beec4: 3b c1                        	cmp	eax, ecx
  5beec6: 0f 83 52 04 00 00            	jae	0x5bf31e <.text+0x1be31e>
  5beecc: 8b d3                        	mov	edx, ebx
  5beece: 85 d2                        	test	edx, edx
  5beed0: 0f 84 85 00 00 00            	je	0x5bef5b <.text+0x1bdf5b>
  5beed6: 8d 55 94                     	lea	edx, [ebp - 0x6c]
  5beed9: 83 ff 10                     	cmp	edi, 0x10
  5beedc: 0f 43 55 94                  	cmovae	edx, dword ptr [ebp - 0x6c]
  5beee0: 2b c2                        	sub	eax, edx
  5beee2: 8b 55 a4                     	mov	edx, dword ptr [ebp - 0x5c]
  5beee5: 89 45 b4                     	mov	dword ptr [ebp - 0x4c], eax
  5beee8: 3b d0                        	cmp	edx, eax
  5beeea: 72 11                        	jb	0x5beefd <.text+0x1bdefd>
  5beeec: 8b ca                        	mov	ecx, edx
  5beeee: 2b c8                        	sub	ecx, eax
  5beef0: bf 2e 00 00 00               	mov	edi, 0x2e
  5beef5: 83 f9 2e                     	cmp	ecx, 0x2e
  5beef8: 0f 47 cf                     	cmova	ecx, edi
  5beefb: eb 1b                        	jmp	0x5bef18 <.text+0x1bdf18>
  5beefd: ff 15 dc 53 c2 00            	call	dword ptr [0xc253dc]
  5bef03: 8b 55 a4                     	mov	edx, dword ptr [ebp - 0x5c]
  5bef06: 8b 45 b4                     	mov	eax, dword ptr [ebp - 0x4c]
  5bef09: 8b ca                        	mov	ecx, edx
  5bef0b: 2b c8                        	sub	ecx, eax
  5bef0d: bf 2e 00 00 00               	mov	edi, 0x2e
  5bef12: 83 f9 2e                     	cmp	ecx, 0x2e
  5bef15: 0f 47 cf                     	cmova	ecx, edi
  5bef18: 03 c1                        	add	eax, ecx
  5bef1a: 8b 0d d0 53 c2 00            	mov	ecx, dword ptr [0xc253d0]
  5bef20: 8b 39                        	mov	edi, dword ptr [ecx]
  5bef22: 3b d0                        	cmp	edx, eax
  5bef24: 73 0f                        	jae	0x5bef35 <.text+0x1bdf35>
  5bef26: 89 45 ac                     	mov	dword ptr [ebp - 0x54], eax
  5bef29: ff 15 dc 53 c2 00            	call	dword ptr [0xc253dc]
  5bef2f: 8b 45 ac                     	mov	eax, dword ptr [ebp - 0x54]
  5bef32: 8b 55 a4                     	mov	edx, dword ptr [ebp - 0x5c]
  5bef35: 8b ca                        	mov	ecx, edx
  5bef37: 2b c8                        	sub	ecx, eax
  5bef39: 3b cf                        	cmp	ecx, edi
  5bef3b: 0f 42 f9                     	cmovb	edi, ecx
  5bef3e: 85 ff                        	test	edi, edi
  5bef40: 0f 87 dd 01 00 00            	ja	0x5bf123 <.text+0x1be123>
  5bef46: 8b 45 b4                     	mov	eax, dword ptr [ebp - 0x4c]
  5bef49: 3b d0                        	cmp	edx, eax
  5bef4b: 0f 42 c2                     	cmovb	eax, edx
  5bef4e: 85 c0                        	test	eax, eax
  5bef50: 89 45 ac                     	mov	dword ptr [ebp - 0x54], eax
  5bef53: 0f 87 86 01 00 00            	ja	0x5bf0df <.text+0x1be0df>
  5bef59: eb 1a                        	jmp	0x5bef75 <.text+0x1bdf75>
  5bef5b: c7 45 c0 2e 00 00 00         	mov	dword ptr [ebp - 0x40], 0x2e
  5bef62: 83 ff 2e                     	cmp	edi, 0x2e
  5bef65: 0f 82 6c 02 00 00            	jb	0x5bf1d7 <.text+0x1be1d7>
  5bef6b: 83 7d c0 00                  	cmp	dword ptr [ebp - 0x40], 0x0
  5bef6f: 0f 87 1f 02 00 00            	ja	0x5bf194 <.text+0x1be194>
  5bef75: c7 45 fc 04 00 00 00         	mov	dword ptr [ebp - 0x4], 0x4
  5bef7c: 8d 55 ac                     	lea	edx, [ebp - 0x54]
  5bef7f: 6a 00                        	push	0x0
