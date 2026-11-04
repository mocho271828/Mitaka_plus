
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5cb3d0: 0f b6 54 24 04               	movzx	edx, byte ptr [esp + 0x4]
  5cb3d5: 0f be 0d 28 1e d7 00         	movsx	ecx, byte ptr [0xd71e28]
  5cb3dc: 8b c1                        	mov	eax, ecx
  5cb3de: 83 e0 01                     	and	eax, 0x1
  5cb3e1: 3b d0                        	cmp	edx, eax
  5cb3e3: 74 25                        	je	0x5cb40a <.text+0x1ca40a>
  5cb3e5: 85 d2                        	test	edx, edx
  5cb3e7: 74 0b                        	je	0x5cb3f4 <.text+0x1ca3f4>
  5cb3e9: 83 c9 01                     	or	ecx, 0x1
  5cb3ec: 51                           	push	ecx
  5cb3ed: e8 2e 9d eb ff               	call	0x485120 <.text+0x84120>
  5cb3f2: eb 09                        	jmp	0x5cb3fd <.text+0x1ca3fd>
  5cb3f4: 83 e1 fe                     	and	ecx, -0x2
  5cb3f7: 51                           	push	ecx
  5cb3f8: e8 23 9d eb ff               	call	0x485120 <.text+0x84120>
  5cb3fd: 59                           	pop	ecx
  5cb3fe: e8 6d d0 00 00               	call	0x5d8470 <.text+0x1d7470>
  5cb403: 8b c8                        	mov	ecx, eax
  5cb405: e8 d6 d7 00 00               	call	0x5d8be0 <.text+0x1d7be0>
  5cb40a: c2 04 00                     	ret	0x4
  5cb40d: 8d 76 00                     	lea	esi, [esi]
  5cb410: 0f b6 05 28 1e d7 00         	movzx	eax, byte ptr [0xd71e28]
  5cb417: 83 e0 01                     	and	eax, 0x1
  5cb41a: c3                           	ret
  5cb41b: 90                           	nop
  5cb41c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  5cb420: 0f be 0d 28 1e d7 00         	movsx	ecx, byte ptr [0xd71e28]
  5cb427: 8b c1                        	mov	eax, ecx
  5cb429: 83 e0 01                     	and	eax, 0x1
  5cb42c: 8b d0                        	mov	edx, eax
  5cb42e: 83 f2 01                     	xor	edx, 0x1
  5cb431: 3b c2                        	cmp	eax, edx
  5cb433: 74 25                        	je	0x5cb45a <.text+0x1ca45a>
  5cb435: 85 d2                        	test	edx, edx
  5cb437: 74 0b                        	je	0x5cb444 <.text+0x1ca444>
  5cb439: 83 c9 01                     	or	ecx, 0x1
  5cb43c: 51                           	push	ecx
  5cb43d: e8 de 9c eb ff               	call	0x485120 <.text+0x84120>
  5cb442: eb 09                        	jmp	0x5cb44d <.text+0x1ca44d>
  5cb444: 83 e1 fe                     	and	ecx, -0x2
  5cb447: 51                           	push	ecx
  5cb448: e8 d3 9c eb ff               	call	0x485120 <.text+0x84120>
  5cb44d: 59                           	pop	ecx
  5cb44e: e8 1d d0 00 00               	call	0x5d8470 <.text+0x1d7470>
  5cb453: 8b c8                        	mov	ecx, eax
  5cb455: e8 86 d7 00 00               	call	0x5d8be0 <.text+0x1d7be0>
  5cb45a: c3                           	ret
  5cb45b: 90                           	nop
  5cb45c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  5cb460: 0f b6 54 24 04               	movzx	edx, byte ptr [esp + 0x4]
  5cb465: 0f be 0d 28 1e d7 00         	movsx	ecx, byte ptr [0xd71e28]
  5cb46c: 8b c1                        	mov	eax, ecx
  5cb46e: 83 e0 02                     	and	eax, 0x2
  5cb471: d1 e8                        	shr	eax
  5cb473: 3b d0                        	cmp	edx, eax
  5cb475: 74 25                        	je	0x5cb49c <.text+0x1ca49c>
  5cb477: 85 d2                        	test	edx, edx
  5cb479: 74 0b                        	je	0x5cb486 <.text+0x1ca486>
  5cb47b: 83 c9 02                     	or	ecx, 0x2
  5cb47e: 51                           	push	ecx
  5cb47f: e8 9c 9c eb ff               	call	0x485120 <.text+0x84120>
  5cb484: eb 09                        	jmp	0x5cb48f <.text+0x1ca48f>
  5cb486: 83 e1 fd                     	and	ecx, -0x3
  5cb489: 51                           	push	ecx
  5cb48a: e8 91 9c eb ff               	call	0x485120 <.text+0x84120>
  5cb48f: 59                           	pop	ecx
  5cb490: e8 db cf 00 00               	call	0x5d8470 <.text+0x1d7470>
  5cb495: 8b c8                        	mov	ecx, eax
  5cb497: e8 44 d7 00 00               	call	0x5d8be0 <.text+0x1d7be0>
  5cb49c: c2 04 00                     	ret	0x4
  5cb49f: 90                           	nop
  5cb4a0: 0f b6 05 28 1e d7 00         	movzx	eax, byte ptr [0xd71e28]
  5cb4a7: 83 e0 02                     	and	eax, 0x2
  5cb4aa: d1 e8                        	shr	eax
  5cb4ac: c3                           	ret
  5cb4ad: 8d 76 00                     	lea	esi, [esi]
  5cb4b0: 57                           	push	edi
  5cb4b1: 0f be 3d 28 1e d7 00         	movsx	edi, byte ptr [0xd71e28]
  5cb4b8: 8b d7                        	mov	edx, edi
  5cb4ba: 83 e2 02                     	and	edx, 0x2
  5cb4bd: b8 01 00 00 00               	mov	eax, 0x1
  5cb4c2: d1 ea                        	shr	edx
  5cb4c4: 33 c9                        	xor	ecx, ecx
  5cb4c6: 85 d2                        	test	edx, edx
  5cb4c8: 0f 44 c8                     	cmove	ecx, eax
  5cb4cb: 3b d1                        	cmp	edx, ecx
  5cb4cd: 74 25                        	je	0x5cb4f4 <.text+0x1ca4f4>
  5cb4cf: 85 c9                        	test	ecx, ecx
  5cb4d1: 74 0b                        	je	0x5cb4de <.text+0x1ca4de>
  5cb4d3: 83 cf 02                     	or	edi, 0x2
  5cb4d6: 57                           	push	edi
  5cb4d7: e8 44 9c eb ff               	call	0x485120 <.text+0x84120>
  5cb4dc: eb 09                        	jmp	0x5cb4e7 <.text+0x1ca4e7>
  5cb4de: 83 e7 fd                     	and	edi, -0x3
  5cb4e1: 57                           	push	edi
  5cb4e2: e8 39 9c eb ff               	call	0x485120 <.text+0x84120>
  5cb4e7: 59                           	pop	ecx
  5cb4e8: e8 83 cf 00 00               	call	0x5d8470 <.text+0x1d7470>
  5cb4ed: 8b c8                        	mov	ecx, eax
  5cb4ef: e8 ec d6 00 00               	call	0x5d8be0 <.text+0x1d7be0>
  5cb4f4: 5f                           	pop	edi
  5cb4f5: c3                           	ret
  5cb4f6: 8d 76 00                     	lea	esi, [esi]
  5cb4f9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  5cb500: 0f b6 54 24 04               	movzx	edx, byte ptr [esp + 0x4]
  5cb505: 0f be 0d 28 1e d7 00         	movsx	ecx, byte ptr [0xd71e28]
  5cb50c: 8b c1                        	mov	eax, ecx
  5cb50e: 83 e0 04                     	and	eax, 0x4
  5cb511: c1 e8 02                     	shr	eax, 0x2
  5cb514: 3b d0                        	cmp	edx, eax
  5cb516: 74 25                        	je	0x5cb53d <.text+0x1ca53d>
  5cb518: 85 d2                        	test	edx, edx
  5cb51a: 74 0b                        	je	0x5cb527 <.text+0x1ca527>
  5cb51c: 83 c9 04                     	or	ecx, 0x4
  5cb51f: 51                           	push	ecx
  5cb520: e8 fb 9b eb ff               	call	0x485120 <.text+0x84120>
  5cb525: eb 09                        	jmp	0x5cb530 <.text+0x1ca530>
  5cb527: 83 e1 fb                     	and	ecx, -0x5
  5cb52a: 51                           	push	ecx
  5cb52b: e8 f0 9b eb ff               	call	0x485120 <.text+0x84120>
  5cb530: 59                           	pop	ecx
  5cb531: e8 3a cf 00 00               	call	0x5d8470 <.text+0x1d7470>
  5cb536: 8b c8                        	mov	ecx, eax
  5cb538: e8 a3 d6 00 00               	call	0x5d8be0 <.text+0x1d7be0>
  5cb53d: c2 04 00                     	ret	0x4
  5cb540: 0f b6 05 28 1e d7 00         	movzx	eax, byte ptr [0xd71e28]
  5cb547: 83 e0 04                     	and	eax, 0x4
  5cb54a: c1 e8 02                     	shr	eax, 0x2
  5cb54d: c3                           	ret
  5cb54e: 8b f6                        	mov	esi, esi
  5cb550: 57                           	push	edi
  5cb551: 0f be 3d 28 1e d7 00         	movsx	edi, byte ptr [0xd71e28]
  5cb558: 8b d7                        	mov	edx, edi
  5cb55a: 83 e2 04                     	and	edx, 0x4
  5cb55d: b8 01 00 00 00               	mov	eax, 0x1
  5cb562: c1 ea 02                     	shr	edx, 0x2
  5cb565: 33 c9                        	xor	ecx, ecx
  5cb567: 85 d2                        	test	edx, edx
  5cb569: 0f 44 c8                     	cmove	ecx, eax
  5cb56c: 3b d1                        	cmp	edx, ecx
  5cb56e: 74 25                        	je	0x5cb595 <.text+0x1ca595>
  5cb570: 85 c9                        	test	ecx, ecx
  5cb572: 74 0b                        	je	0x5cb57f <.text+0x1ca57f>
  5cb574: 83 cf 04                     	or	edi, 0x4
  5cb577: 57                           	push	edi
  5cb578: e8 a3 9b eb ff               	call	0x485120 <.text+0x84120>
  5cb57d: eb 09                        	jmp	0x5cb588 <.text+0x1ca588>
  5cb57f: 83 e7 fb                     	and	edi, -0x5
  5cb582: 57                           	push	edi
  5cb583: e8 98 9b eb ff               	call	0x485120 <.text+0x84120>
  5cb588: 59                           	pop	ecx
  5cb589: e8 e2 ce 00 00               	call	0x5d8470 <.text+0x1d7470>
  5cb58e: 8b c8                        	mov	ecx, eax
  5cb590: e8 4b d6 00 00               	call	0x5d8be0 <.text+0x1d7be0>
  5cb595: 5f                           	pop	edi
  5cb596: c3                           	ret
  5cb597: 8b f6                        	mov	esi, esi
  5cb599: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  5cb5a0: 0f b6 54 24 04               	movzx	edx, byte ptr [esp + 0x4]
  5cb5a5: 0f be 0d 28 1e d7 00         	movsx	ecx, byte ptr [0xd71e28]
  5cb5ac: 8b c1                        	mov	eax, ecx
  5cb5ae: 83 e0 08                     	and	eax, 0x8
  5cb5b1: c1 e8 03                     	shr	eax, 0x3
  5cb5b4: 3b d0                        	cmp	edx, eax
  5cb5b6: 74 25                        	je	0x5cb5dd <.text+0x1ca5dd>
  5cb5b8: 85 d2                        	test	edx, edx
  5cb5ba: 74 0b                        	je	0x5cb5c7 <.text+0x1ca5c7>
  5cb5bc: 83 c9 08                     	or	ecx, 0x8
  5cb5bf: 51                           	push	ecx
  5cb5c0: e8 5b 9b eb ff               	call	0x485120 <.text+0x84120>
  5cb5c5: eb 09                        	jmp	0x5cb5d0 <.text+0x1ca5d0>
  5cb5c7: 83 e1 f7                     	and	ecx, -0x9
  5cb5ca: 51                           	push	ecx
  5cb5cb: e8 50 9b eb ff               	call	0x485120 <.text+0x84120>
  5cb5d0: 59                           	pop	ecx
  5cb5d1: e8 9a ce 00 00               	call	0x5d8470 <.text+0x1d7470>
  5cb5d6: 8b c8                        	mov	ecx, eax
  5cb5d8: e8 03 d6 00 00               	call	0x5d8be0 <.text+0x1d7be0>
  5cb5dd: c2 04 00                     	ret	0x4
  5cb5e0: 0f b6 05 28 1e d7 00         	movzx	eax, byte ptr [0xd71e28]
  5cb5e7: 83 e0 08                     	and	eax, 0x8
  5cb5ea: c1 e8 03                     	shr	eax, 0x3
  5cb5ed: c3                           	ret
  5cb5ee: 8b f6                        	mov	esi, esi
  5cb5f0: 57                           	push	edi
  5cb5f1: 0f be 3d 28 1e d7 00         	movsx	edi, byte ptr [0xd71e28]
  5cb5f8: 8b d7                        	mov	edx, edi
  5cb5fa: 83 e2 08                     	and	edx, 0x8
  5cb5fd: b8 01 00 00 00               	mov	eax, 0x1
  5cb602: c1 ea 03                     	shr	edx, 0x3
  5cb605: 33 c9                        	xor	ecx, ecx
  5cb607: 85 d2                        	test	edx, edx
  5cb609: 0f 44 c8                     	cmove	ecx, eax
  5cb60c: 3b d1                        	cmp	edx, ecx
  5cb60e: 74 25                        	je	0x5cb635 <.text+0x1ca635>
  5cb610: 85 c9                        	test	ecx, ecx
  5cb612: 74 0b                        	je	0x5cb61f <.text+0x1ca61f>
  5cb614: 83 cf 08                     	or	edi, 0x8
  5cb617: 57                           	push	edi
  5cb618: e8 03 9b eb ff               	call	0x485120 <.text+0x84120>
  5cb61d: eb 09                        	jmp	0x5cb628 <.text+0x1ca628>
  5cb61f: 83 e7 f7                     	and	edi, -0x9
  5cb622: 57                           	push	edi
  5cb623: e8 f8 9a eb ff               	call	0x485120 <.text+0x84120>
  5cb628: 59                           	pop	ecx
  5cb629: e8 42 ce 00 00               	call	0x5d8470 <.text+0x1d7470>
  5cb62e: 8b c8                        	mov	ecx, eax
  5cb630: e8 ab d5 00 00               	call	0x5d8be0 <.text+0x1d7be0>
  5cb635: 5f                           	pop	edi
  5cb636: c3                           	ret
  5cb637: 8b f6                        	mov	esi, esi
  5cb639: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
