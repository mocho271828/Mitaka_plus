
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  4850c0: 0f b6 44 24 04               	movzx	eax, byte ptr [esp + 0x4]
  4850c5: 50                           	push	eax
  4850c6: e8 e5 c3 08 00               	call	0x5114b0 <.text+0x1104b0>
  4850cb: 59                           	pop	ecx
  4850cc: c3                           	ret
  4850cd: 8d 76 00                     	lea	esi, [esi]
  4850d0: 55                           	push	ebp
  4850d1: 0f be 05 60 93 fe 00         	movsx	eax, byte ptr [0xfe9360]
  4850d8: 85 c0                        	test	eax, eax
  4850da: 74 02                        	je	0x4850de <.text+0x840de>
  4850dc: 5d                           	pop	ebp
  4850dd: c3                           	ret
  4850de: bd 00 00 34 42               	mov	ebp, 0x42340000
  4850e3: 55                           	push	ebp
  4850e4: e8 47 e7 0b 00               	call	0x543830 <.text+0x142830>
  4850e9: 59                           	pop	ecx
  4850ea: 0f b6 05 58 4c 19 01         	movzx	eax, byte ptr [0x1194c58]
  4850f1: 85 c0                        	test	eax, eax
  4850f3: 74 10                        	je	0x485105 <.text+0x84105>
  4850f5: e8 c6 11 14 00               	call	0x5c62c0 <.text+0x1c52c0>
  4850fa: 6a 00                        	push	0x0
  4850fc: 55                           	push	ebp
  4850fd: e8 7e 1f 14 00               	call	0x5c7080 <.text+0x1c6080>
  485102: 83 c4 08                     	add	esp, 0x8
  485105: 5d                           	pop	ebp
  485106: c3                           	ret
  485107: 8b f6                        	mov	esi, esi
  485109: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  485110: 0f b6 44 24 04               	movzx	eax, byte ptr [esp + 0x4]
  485115: a2 78 93 fe 00               	mov	byte ptr [0xfe9378], al
  48511a: c3                           	ret
  48511b: 90                           	nop
  48511c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  485120: 0f b6 44 24 04               	movzx	eax, byte ptr [esp + 0x4]
  485125: a2 28 1e d7 00               	mov	byte ptr [0xd71e28], al
  48512a: c3                           	ret
  48512b: 90                           	nop
  48512c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  485130: 0f be 4c 24 04               	movsx	ecx, byte ptr [esp + 0x4]
  485135: 0f be 05 28 1e d7 00         	movsx	eax, byte ptr [0xd71e28]
  48513c: 8b d0                        	mov	edx, eax
  48513e: 0b d1                        	or	edx, ecx
  485140: f7 d1                        	not	ecx
  485142: 23 c1                        	and	eax, ecx
  485144: 0f b6 4c 24 08               	movzx	ecx, byte ptr [esp + 0x8]
  485149: 85 c9                        	test	ecx, ecx
  48514b: 0f 45 c2                     	cmovne	eax, edx
  48514e: a2 28 1e d7 00               	mov	byte ptr [0xd71e28], al
  485153: c3                           	ret
  485154: 8d b6 00 00 00 00            	lea	esi, [esi]
  48515a: 8d bf 00 00 00 00            	lea	edi, [edi]
  485160: 0f b6 44 24 04               	movzx	eax, byte ptr [esp + 0x4]
  485165: a2 2c 1e d7 00               	mov	byte ptr [0xd71e2c], al
  48516a: c3                           	ret
  48516b: 90                           	nop
  48516c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  485170: 55                           	push	ebp
  485171: 8b ec                        	mov	ebp, esp
  485173: 6a ff                        	push	-0x1
  485175: 68 d0 3c bf 00               	push	0xbf3cd0
  48517a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  485180: 50                           	push	eax
  485181: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  485188: 83 ec 4c                     	sub	esp, 0x4c
  48518b: 89 5d e8                     	mov	dword ptr [ebp - 0x18], ebx
  48518e: 89 7d e0                     	mov	dword ptr [ebp - 0x20], edi
  485191: 89 75 e4                     	mov	dword ptr [ebp - 0x1c], esi
  485194: 0f be 4d 08                  	movsx	ecx, byte ptr [ebp + 0x8]
  485198: 0f b6 55 0c                  	movzx	edx, byte ptr [ebp + 0xc]
  48519c: a1 10 53 d8 00               	mov	eax, dword ptr [0xd85310]
  4851a1: 89 45 ec                     	mov	dword ptr [ebp - 0x14], eax
  4851a4: 85 d2                        	test	edx, edx
  4851a6: 74 4a                        	je	0x4851f2 <.text+0x841f2>
  4851a8: 8d 45 c4                     	lea	eax, [ebp - 0x3c]
  4851ab: 51                           	push	ecx
  4851ac: 50                           	push	eax
  4851ad: b9 c0 76 10 01               	mov	ecx, 0x11076c0
  4851b2: e8 39 61 0e 00               	call	0x56b2f0 <.text+0x16a2f0>
  4851b7: c7 45 fc 01 00 00 00         	mov	dword ptr [ebp - 0x4], 0x1
  4851be: 83 7d dc 10                  	cmp	dword ptr [ebp - 0x24], 0x10
  4851c2: 8d 45 c8                     	lea	eax, [ebp - 0x38]
  4851c5: 0f 43 45 c8                  	cmovae	eax, dword ptr [ebp - 0x38]
  4851c9: 50                           	push	eax
  4851ca: b9 c0 76 10 01               	mov	ecx, 0x11076c0
  4851cf: e8 8c 67 0e 00               	call	0x56b960 <.text+0x16a960>
  4851d4: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  4851db: 83 7d dc 10                  	cmp	dword ptr [ebp - 0x24], 0x10
  4851df: 73 6f                        	jae	0x485250 <.text+0x84250>
  4851e1: c7 45 dc 0f 00 00 00         	mov	dword ptr [ebp - 0x24], 0xf
  4851e8: 33 c0                        	xor	eax, eax
  4851ea: 89 45 d8                     	mov	dword ptr [ebp - 0x28], eax
  4851ed: 88 45 c8                     	mov	byte ptr [ebp - 0x38], al
  4851f0: eb 48                        	jmp	0x48523a <.text+0x8423a>
  4851f2: 8d 45 a8                     	lea	eax, [ebp - 0x58]
  4851f5: 51                           	push	ecx
  4851f6: 50                           	push	eax
  4851f7: b9 c0 76 10 01               	mov	ecx, 0x11076c0
  4851fc: e8 ef 60 0e 00               	call	0x56b2f0 <.text+0x16a2f0>
