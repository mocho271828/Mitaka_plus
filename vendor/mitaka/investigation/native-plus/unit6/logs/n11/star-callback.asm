
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5e3dc0: f2 0f 10 4c 24 04            	movsd	xmm1, qword ptr [esp + 0x4]
  5e3dc6: 8b 41 08                     	mov	eax, dword ptr [ecx + 0x8]
  5e3dc9: 85 c0                        	test	eax, eax
  5e3dcb: 74 18                        	je	0x5e3de5 <.text+0x1e2de5>
  5e3dcd: 8b 49 04                     	mov	ecx, dword ptr [ecx + 0x4]
  5e3dd0: 66 0f ef c0                  	pxor	xmm0, xmm0
  5e3dd4: f2 0f c2 c8 04               	cmpneqsd	xmm1, xmm0
  5e3dd9: 66 0f 7e ca                  	movd	edx, xmm1
  5e3ddd: f7 da                        	neg	edx
  5e3ddf: 52                           	push	edx
  5e3de0: ff d0                        	call	eax
  5e3de2: c2 08 00                     	ret	0x8
  5e3de5: 8b 41 0c                     	mov	eax, dword ptr [ecx + 0xc]
  5e3de8: 85 c0                        	test	eax, eax
  5e3dea: 74 0d                        	je	0x5e3df9 <.text+0x1e2df9>
  5e3dec: 8b 49 04                     	mov	ecx, dword ptr [ecx + 0x4]
  5e3def: f2 0f 2c d1                  	cvttsd2si	edx, xmm1
  5e3df3: 52                           	push	edx
  5e3df4: ff d0                        	call	eax
  5e3df6: c2 08 00                     	ret	0x8
  5e3df9: 8b 41 10                     	mov	eax, dword ptr [ecx + 0x10]
  5e3dfc: 85 c0                        	test	eax, eax
  5e3dfe: 74 12                        	je	0x5e3e12 <.text+0x1e2e12>
  5e3e00: f2 0f 5a c1                  	cvtsd2ss	xmm0, xmm1
  5e3e04: 8b 49 04                     	mov	ecx, dword ptr [ecx + 0x4]
  5e3e07: 50                           	push	eax
  5e3e08: f3 0f 11 04 24               	movss	dword ptr [esp], xmm0
  5e3e0d: ff d0                        	call	eax
  5e3e0f: c2 08 00                     	ret	0x8
  5e3e12: 8b 41 14                     	mov	eax, dword ptr [ecx + 0x14]
  5e3e15: 85 c0                        	test	eax, eax
  5e3e17: 74 0d                        	je	0x5e3e26 <.text+0x1e2e26>
  5e3e19: 8b 49 04                     	mov	ecx, dword ptr [ecx + 0x4]
  5e3e1c: 83 c4 f8                     	add	esp, -0x8
  5e3e1f: f2 0f 11 0c 24               	movsd	qword ptr [esp], xmm1
  5e3e24: ff d0                        	call	eax
  5e3e26: c2 08 00                     	ret	0x8
  5e3e29: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  5e3e30: 57                           	push	edi
  5e3e31: 56                           	push	esi
  5e3e32: 55                           	push	ebp
  5e3e33: 8b f9                        	mov	edi, ecx
  5e3e35: 8b 74 24 10                  	mov	esi, dword ptr [esp + 0x10]
  5e3e39: 33 ed                        	xor	ebp, ebp
  5e3e3b: 55                           	push	ebp
  5e3e3c: 68 c8 2d d7 00               	push	0xd72dc8
  5e3e41: 68 78 13 d7 00               	push	0xd71378
  5e3e46: 55                           	push	ebp
  5e3e47: 56                           	push	esi
  5e3e48: e8 6b b4 4a 00               	call	0xa8f2b8 <.text+0x68e2b8>
  5e3e4d: 83 c4 14                     	add	esp, 0x14
  5e3e50: 85 c0                        	test	eax, eax
  5e3e52: 0f 84 91 00 00 00            	je	0x5e3ee9 <.text+0x1e2ee9>
  5e3e58: 55                           	push	ebp
  5e3e59: 68 c8 2d d7 00               	push	0xd72dc8
  5e3e5e: 68 78 13 d7 00               	push	0xd71378
  5e3e63: 55                           	push	ebp
  5e3e64: 56                           	push	esi
  5e3e65: e8 4e b4 4a 00               	call	0xa8f2b8 <.text+0x68e2b8>
  5e3e6a: 83 c4 14                     	add	esp, 0x14
  5e3e6d: 8b 40 04                     	mov	eax, dword ptr [eax + 0x4]
  5e3e70: 3b 47 04                     	cmp	eax, dword ptr [edi + 0x4]
  5e3e73: 75 74                        	jne	0x5e3ee9 <.text+0x1e2ee9>
  5e3e75: 55                           	push	ebp
  5e3e76: 68 c8 2d d7 00               	push	0xd72dc8
  5e3e7b: 68 78 13 d7 00               	push	0xd71378
  5e3e80: 55                           	push	ebp
  5e3e81: 56                           	push	esi
  5e3e82: e8 31 b4 4a 00               	call	0xa8f2b8 <.text+0x68e2b8>
  5e3e87: 83 c4 14                     	add	esp, 0x14
  5e3e8a: 8b 40 08                     	mov	eax, dword ptr [eax + 0x8]
  5e3e8d: 3b 47 08                     	cmp	eax, dword ptr [edi + 0x8]
  5e3e90: 75 57                        	jne	0x5e3ee9 <.text+0x1e2ee9>
  5e3e92: 55                           	push	ebp
  5e3e93: 68 c8 2d d7 00               	push	0xd72dc8
  5e3e98: 68 78 13 d7 00               	push	0xd71378
  5e3e9d: 55                           	push	ebp
  5e3e9e: 56                           	push	esi
  5e3e9f: e8 14 b4 4a 00               	call	0xa8f2b8 <.text+0x68e2b8>
  5e3ea4: 83 c4 14                     	add	esp, 0x14
  5e3ea7: 8b 40 0c                     	mov	eax, dword ptr [eax + 0xc]
  5e3eaa: 3b 47 0c                     	cmp	eax, dword ptr [edi + 0xc]
  5e3ead: 75 3a                        	jne	0x5e3ee9 <.text+0x1e2ee9>
  5e3eaf: 55                           	push	ebp
  5e3eb0: 68 c8 2d d7 00               	push	0xd72dc8
  5e3eb5: 68 78 13 d7 00               	push	0xd71378
  5e3eba: 55                           	push	ebp
  5e3ebb: 56                           	push	esi
  5e3ebc: e8 f7 b3 4a 00               	call	0xa8f2b8 <.text+0x68e2b8>
  5e3ec1: 83 c4 14                     	add	esp, 0x14
  5e3ec4: 8b 40 10                     	mov	eax, dword ptr [eax + 0x10]
  5e3ec7: 3b 47 10                     	cmp	eax, dword ptr [edi + 0x10]
  5e3eca: 75 1d                        	jne	0x5e3ee9 <.text+0x1e2ee9>
  5e3ecc: 55                           	push	ebp
  5e3ecd: 68 c8 2d d7 00               	push	0xd72dc8
  5e3ed2: 68 78 13 d7 00               	push	0xd71378
  5e3ed7: 55                           	push	ebp
  5e3ed8: 56                           	push	esi
  5e3ed9: e8 da b3 4a 00               	call	0xa8f2b8 <.text+0x68e2b8>
  5e3ede: 83 c4 14                     	add	esp, 0x14
  5e3ee1: 8b 40 14                     	mov	eax, dword ptr [eax + 0x14]
  5e3ee4: 3b 47 14                     	cmp	eax, dword ptr [edi + 0x14]
  5e3ee7: 74 08                        	je	0x5e3ef1 <.text+0x1e2ef1>
  5e3ee9: 33 c0                        	xor	eax, eax
  5e3eeb: 5d                           	pop	ebp
  5e3eec: 5e                           	pop	esi
  5e3eed: 5f                           	pop	edi
  5e3eee: c2 04 00                     	ret	0x4
