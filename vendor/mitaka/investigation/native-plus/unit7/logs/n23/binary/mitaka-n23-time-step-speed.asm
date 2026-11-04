
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5ec3b0: ff 74 24 04                  	push	dword ptr [esp + 0x4]
  5ec3b4: e8 77 8f e9 ff               	call	0x485330 <.text+0x84330>
  5ec3b9: 59                           	pop	ecx
  5ec3ba: c2 04 00                     	ret	0x4
  5ec3bd: 8d 76 00                     	lea	esi, [esi]
  5ec3c0: 0f be 05 60 0e d7 00         	movsx	eax, byte ptr [0xd70e60]
  5ec3c7: c3                           	ret
  5ec3c8: 90                           	nop
  5ec3c9: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  5ec3d0: 0f be 15 60 0e d7 00         	movsx	edx, byte ptr [0xd70e60]
  5ec3d7: 33 c0                        	xor	eax, eax
  5ec3d9: 4a                           	dec	edx
  5ec3da: 0f 4e d0                     	cmovle	edx, eax
  5ec3dd: 88 15 60 0e d7 00            	mov	byte ptr [0xd70e60], dl
  5ec3e3: c3                           	ret
  5ec3e4: 8d b6 00 00 00 00            	lea	esi, [esi]
  5ec3ea: 8d bf 00 00 00 00            	lea	edi, [edi]
  5ec3f0: 0f be 15 60 0e d7 00         	movsx	edx, byte ptr [0xd70e60]
  5ec3f7: 42                           	inc	edx
  5ec3f8: b8 09 00 00 00               	mov	eax, 0x9
  5ec3fd: 83 fa 0a                     	cmp	edx, 0xa
  5ec400: 0f 4d d0                     	cmovge	edx, eax
  5ec403: 88 15 60 0e d7 00            	mov	byte ptr [0xd70e60], dl
  5ec409: c3                           	ret
  5ec40a: 8d b6 00 00 00 00            	lea	esi, [esi]
  5ec410: 83 ec 08                     	sub	esp, 0x8
  5ec413: f2 0f 10 44 24 0c            	movsd	xmm0, qword ptr [esp + 0xc]
  5ec419: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  5ec41e: e8 2d 8f e9 ff               	call	0x485350 <.text+0x84350>
  5ec423: 83 c4 08                     	add	esp, 0x8
  5ec426: c2 08 00                     	ret	0x8
  5ec429: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  5ec430: dd 05 c0 90 fe 00            	fld	qword ptr [0xfe90c0]
  5ec436: c3                           	ret
  5ec437: 8b f6                        	mov	esi, esi
  5ec439: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  5ec440: 55                           	push	ebp
  5ec441: 8b ec                        	mov	ebp, esp
  5ec443: 6a ff                        	push	-0x1
  5ec445: 68 90 d8 bf 00               	push	0xbfd890
  5ec44a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  5ec450: 50                           	push	eax
  5ec451: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  5ec458: 83 ec 78                     	sub	esp, 0x78
  5ec45b: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
  5ec45e: 89 5d e8                     	mov	dword ptr [ebp - 0x18], ebx
  5ec461: 89 7d e0                     	mov	dword ptr [ebp - 0x20], edi
  5ec464: 89 75 e4                     	mov	dword ptr [ebp - 0x1c], esi
  5ec467: a1 10 53 d8 00               	mov	eax, dword ptr [0xd85310]
  5ec46c: 89 4d bc                     	mov	dword ptr [ebp - 0x44], ecx
  5ec46f: 89 45 ec                     	mov	dword ptr [ebp - 0x14], eax
  5ec472: 6a 00                        	push	0x0
  5ec474: e8 47 8c e9 ff               	call	0x4850c0 <.text+0x840c0>
  5ec479: 59                           	pop	ecx
  5ec47a: 8b 45 08                     	mov	eax, dword ptr [ebp + 0x8]
  5ec47d: a3 3c 1b 08 01               	mov	dword ptr [0x1081b3c], eax
  5ec482: e8 39 9e fd ff               	call	0x5c62c0 <.text+0x1c52c0>
  5ec487: 8b c8                        	mov	ecx, eax
  5ec489: e8 52 9f fd ff               	call	0x5c63e0 <.text+0x1c53e0>
  5ec48e: 0f b6 c0                     	movzx	eax, al
  5ec491: 85 c0                        	test	eax, eax
  5ec493: 74 13                        	je	0x5ec4a8 <.text+0x1eb4a8>
  5ec495: e8 26 9e fd ff               	call	0x5c62c0 <.text+0x1c52c0>
  5ec49a: 8b c8                        	mov	ecx, eax
  5ec49c: e8 cf a3 fd ff               	call	0x5c6870 <.text+0x1c5870>
  5ec4a1: 0f b6 c0                     	movzx	eax, al
  5ec4a4: 85 c0                        	test	eax, eax
  5ec4a6: 74 21                        	je	0x5ec4c9 <.text+0x1eb4c9>
  5ec4a8: 8b 4d ec                     	mov	ecx, dword ptr [ebp - 0x14]
  5ec4ab: e8 10 2a 4a 00               	call	0xa8eec0 <.text+0x68dec0>
  5ec4b0: 8b 7d e0                     	mov	edi, dword ptr [ebp - 0x20]
  5ec4b3: 8b 75 e4                     	mov	esi, dword ptr [ebp - 0x1c]
  5ec4b6: 8b 5d e8                     	mov	ebx, dword ptr [ebp - 0x18]
  5ec4b9: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  5ec4bc: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  5ec4c3: 8b e5                        	mov	esp, ebp
  5ec4c5: 5d                           	pop	ebp
  5ec4c6: c2 04 00                     	ret	0x4
  5ec4c9: e8 b2 61 47 00               	call	0xa62680 <.text+0x661680>
  5ec4ce: 8b f8                        	mov	edi, eax
  5ec4d0: c7 45 94 0f 00 00 00         	mov	dword ptr [ebp - 0x6c], 0xf
  5ec4d7: 8d 45 80                     	lea	eax, [ebp - 0x80]
  5ec4da: 33 db                        	xor	ebx, ebx
  5ec4dc: b9 a4 78 c3 00               	mov	ecx, 0xc378a4
  5ec4e1: c7 45 b8 0d 00 00 00         	mov	dword ptr [ebp - 0x48], 0xd
  5ec4e8: 89 5d 90                     	mov	dword ptr [ebp - 0x70], ebx
  5ec4eb: 88 18                        	mov	byte ptr [eax], bl
  5ec4ed: 8b 75 80                     	mov	esi, dword ptr [ebp - 0x80]
  5ec4f0: 8d 95 7c ff ff ff            	lea	edx, [ebp - 0x84]
  5ec4f6: 89 55 b0                     	mov	dword ptr [ebp - 0x50], edx
  5ec4f9: 8b 55 94                     	mov	edx, dword ptr [ebp - 0x6c]
  5ec4fc: 89 4d b4                     	mov	dword ptr [ebp - 0x4c], ecx
  5ec4ff: 83 fa 10                     	cmp	edx, 0x10
  5ec502: 0f 42 f0                     	cmovb	esi, eax
  5ec505: 3b ce                        	cmp	ecx, esi
  5ec507: 0f 83 ec 03 00 00            	jae	0x5ec8f9 <.text+0x1eb8f9>
  5ec50d: 8b c3                        	mov	eax, ebx
  5ec50f: 85 c0                        	test	eax, eax
  5ec511: 0f 84 8a 00 00 00            	je	0x5ec5a1 <.text+0x1eb5a1>
  5ec517: 8d 45 80                     	lea	eax, [ebp - 0x80]
  5ec51a: 83 fa 10                     	cmp	edx, 0x10
  5ec51d: 0f 43 45 80                  	cmovae	eax, dword ptr [ebp - 0x80]
  5ec521: be a4 78 c3 00               	mov	esi, 0xc378a4
  5ec526: 2b f0                        	sub	esi, eax
  5ec528: 8b 45 90                     	mov	eax, dword ptr [ebp - 0x70]
  5ec52b: 89 75 a4                     	mov	dword ptr [ebp - 0x5c], esi
  5ec52e: 3b c6                        	cmp	eax, esi
  5ec530: 72 11                        	jb	0x5ec543 <.text+0x1eb543>
  5ec532: 8b d0                        	mov	edx, eax
  5ec534: 2b d6                        	sub	edx, esi
  5ec536: b9 0d 00 00 00               	mov	ecx, 0xd
  5ec53b: 83 fa 0d                     	cmp	edx, 0xd
  5ec53e: 0f 47 d1                     	cmova	edx, ecx
  5ec541: eb 1b                        	jmp	0x5ec55e <.text+0x1eb55e>
  5ec543: ff 15 dc 53 c2 00            	call	dword ptr [0xc253dc]
  5ec549: 8b 45 90                     	mov	eax, dword ptr [ebp - 0x70]
  5ec54c: 8b 75 a4                     	mov	esi, dword ptr [ebp - 0x5c]
  5ec54f: 8b d0                        	mov	edx, eax
  5ec551: 2b d6                        	sub	edx, esi
  5ec553: b9 0d 00 00 00               	mov	ecx, 0xd
  5ec558: 83 fa 0d                     	cmp	edx, 0xd
  5ec55b: 0f 47 d1                     	cmova	edx, ecx
  5ec55e: 03 f2                        	add	esi, edx
  5ec560: 8b 15 d0 53 c2 00            	mov	edx, dword ptr [0xc253d0]
  5ec566: 8b 12                        	mov	edx, dword ptr [edx]
  5ec568: 3b c6                        	cmp	eax, esi
  5ec56a: 73 0f                        	jae	0x5ec57b <.text+0x1eb57b>
  5ec56c: 89 55 a0                     	mov	dword ptr [ebp - 0x60], edx
  5ec56f: ff 15 dc 53 c2 00            	call	dword ptr [0xc253dc]
  5ec575: 8b 55 a0                     	mov	edx, dword ptr [ebp - 0x60]
  5ec578: 8b 45 90                     	mov	eax, dword ptr [ebp - 0x70]
  5ec57b: 8b c8                        	mov	ecx, eax
  5ec57d: 2b ce                        	sub	ecx, esi
  5ec57f: 3b ca                        	cmp	ecx, edx
  5ec581: 0f 42 d1                     	cmovb	edx, ecx
  5ec584: 85 d2                        	test	edx, edx
  5ec586: 0f 87 44 01 00 00            	ja	0x5ec6d0 <.text+0x1eb6d0>
  5ec58c: 8b 55 a4                     	mov	edx, dword ptr [ebp - 0x5c]
  5ec58f: 3b c2                        	cmp	eax, edx
  5ec591: 0f 42 d0                     	cmovb	edx, eax
  5ec594: 85 d2                        	test	edx, edx
  5ec596: 89 55 98                     	mov	dword ptr [ebp - 0x68], edx
  5ec599: 0f 87 ed 00 00 00            	ja	0x5ec68c <.text+0x1eb68c>
  5ec59f: eb 1a                        	jmp	0x5ec5bb <.text+0x1eb5bb>
  5ec5a1: c7 45 ac 0d 00 00 00         	mov	dword ptr [ebp - 0x54], 0xd
  5ec5a8: 83 fa 0d                     	cmp	edx, 0xd
  5ec5ab: 0f 82 fe 01 00 00            	jb	0x5ec7af <.text+0x1eb7af>
  5ec5b1: 83 7d ac 00                  	cmp	dword ptr [ebp - 0x54], 0x0
  5ec5b5: 0f 87 b1 01 00 00            	ja	0x5ec76c <.text+0x1eb76c>
  5ec5bb: c7 45 fc 04 00 00 00         	mov	dword ptr [ebp - 0x4], 0x4
  5ec5c2: 8b 4d bc                     	mov	ecx, dword ptr [ebp - 0x44]
  5ec5c5: 8d 75 98                     	lea	esi, [ebp - 0x68]
  5ec5c8: 56                           	push	esi
  5ec5c9: e8 b2 d1 ff ff               	call	0x5e9780 <.text+0x1e8780>
  5ec5ce: c7 45 fc 05 00 00 00         	mov	dword ptr [ebp - 0x4], 0x5
  5ec5d5: 8d 45 b4                     	lea	eax, [ebp - 0x4c]
  5ec5d8: 8d 95 7c ff ff ff            	lea	edx, [ebp - 0x84]
  5ec5de: 83 c4 f4                     	add	esp, -0xc
  5ec5e1: 89 04 24                     	mov	dword ptr [esp], eax
  5ec5e4: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  5ec5e8: 89 74 24 08                  	mov	dword ptr [esp + 0x8], esi
  5ec5ec: ff 15 f0 53 c2 00            	call	dword ptr [0xc253f0]
  5ec5f2: 83 c4 0c                     	add	esp, 0xc
  5ec5f5: c7 45 fc 06 00 00 00         	mov	dword ptr [ebp - 0x4], 0x6
  5ec5fc: 8d 55 b4                     	lea	edx, [ebp - 0x4c]
  5ec5ff: 83 c4 e4                     	add	esp, -0x1c
  5ec602: 8b c4                        	mov	eax, esp
  5ec604: 83 c4 f4                     	add	esp, -0xc
  5ec607: 89 04 24                     	mov	dword ptr [esp], eax
  5ec60a: c7 44 24 08 b4 78 c3 00      	mov	dword ptr [esp + 0x8], 0xc378b4
  5ec612: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  5ec616: ff 15 c0 53 c2 00            	call	dword ptr [0xc253c0]
  5ec61c: 83 c4 0c                     	add	esp, 0xc
  5ec61f: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
