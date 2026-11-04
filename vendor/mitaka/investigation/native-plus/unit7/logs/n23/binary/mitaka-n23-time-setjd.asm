
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5ec040: 55                           	push	ebp
  5ec041: 8b ec                        	mov	ebp, esp
  5ec043: 6a ff                        	push	-0x1
  5ec045: 68 10 d8 bf 00               	push	0xbfd810
  5ec04a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  5ec050: 50                           	push	eax
  5ec051: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  5ec058: 83 ec 18                     	sub	esp, 0x18
  5ec05b: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  5ec05e: 89 7d e4                     	mov	dword ptr [ebp - 0x1c], edi
  5ec061: 89 75 e8                     	mov	dword ptr [ebp - 0x18], esi
  5ec064: 8b f1                        	mov	esi, ecx
  5ec066: e8 95 17 1d 00               	call	0x7bd800 <.text+0x3bc800>
  5ec06b: 8b d8                        	mov	ebx, eax
  5ec06d: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  5ec074: c7 45 dc 00 00 00 00         	mov	dword ptr [ebp - 0x24], 0x0
  5ec07b: 50                           	push	eax
  5ec07c: c7 04 24 18 00 00 00         	mov	dword ptr [esp], 0x18
  5ec083: e8 82 2f 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5ec088: 59                           	pop	ecx
  5ec089: 89 45 e0                     	mov	dword ptr [ebp - 0x20], eax
  5ec08c: 85 c0                        	test	eax, eax
  5ec08e: 74 20                        	je	0x5ec0b0 <.text+0x1eb0b0>
  5ec090: c7 00 a8 29 2d 01            	mov	dword ptr [eax], 0x12d29a8
  5ec096: 89 70 04                     	mov	dword ptr [eax + 0x4], esi
  5ec099: 33 d2                        	xor	edx, edx
  5ec09b: 89 50 08                     	mov	dword ptr [eax + 0x8], edx
  5ec09e: c7 40 14 40 c0 5e 00         	mov	dword ptr [eax + 0x14], 0x5ec040
  5ec0a5: 89 55 dc                     	mov	dword ptr [ebp - 0x24], edx
  5ec0a8: 89 50 0c                     	mov	dword ptr [eax + 0xc], edx
  5ec0ab: 89 50 10                     	mov	dword ptr [eax + 0x10], edx
  5ec0ae: eb 02                        	jmp	0x5ec0b2 <.text+0x1eb0b2>
  5ec0b0: 33 c0                        	xor	eax, eax
  5ec0b2: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5ec0b9: 6a 01                        	push	0x1
  5ec0bb: 50                           	push	eax
  5ec0bc: 8b cb                        	mov	ecx, ebx
  5ec0be: e8 0d 24 1d 00               	call	0x7be4d0 <.text+0x3bd4d0>
  5ec0c3: e8 28 03 fb ff               	call	0x59c3f0 <.text+0x19b3f0>
  5ec0c8: dd 5d dc                     	fstp	qword ptr [ebp - 0x24]
  5ec0cb: f2 0f 10 45 dc               	movsd	xmm0, qword ptr [ebp - 0x24]
  5ec0d0: 66 0f 2e 45 08               	ucomisd	xmm0, qword ptr [ebp + 0x8]
  5ec0d5: 7a 02                        	jp	0x5ec0d9 <.text+0x1eb0d9>
  5ec0d7: 74 1f                        	je	0x5ec0f8 <.text+0x1eb0f8>
  5ec0d9: 6a 00                        	push	0x0
  5ec0db: e8 e0 8f e9 ff               	call	0x4850c0 <.text+0x840c0>
  5ec0e0: 8d 45 08                     	lea	eax, [ebp + 0x8]
  5ec0e3: 50                           	push	eax
  5ec0e4: e8 a7 ae e9 ff               	call	0x486f90 <.text+0x85f90>
  5ec0e9: 83 c4 08                     	add	esp, 0x8
  5ec0ec: e8 7f c3 fe ff               	call	0x5d8470 <.text+0x1d7470>
  5ec0f1: 8b c8                        	mov	ecx, eax
  5ec0f3: e8 e8 ca fe ff               	call	0x5d8be0 <.text+0x1d7be0>
  5ec0f8: 8b 75 e8                     	mov	esi, dword ptr [ebp - 0x18]
  5ec0fb: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5ec0fe: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  5ec101: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  5ec108: 8b e5                        	mov	esp, ebp
  5ec10a: 5d                           	pop	ebp
  5ec10b: c2 08 00                     	ret	0x8
  5ec10e: 90                           	nop
  5ec10f: 90                           	nop
  5ec110: e8 db 02 fb ff               	call	0x59c3f0 <.text+0x19b3f0>
  5ec115: c3                           	ret
  5ec116: 8d 76 00                     	lea	esi, [esi]
  5ec119: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
