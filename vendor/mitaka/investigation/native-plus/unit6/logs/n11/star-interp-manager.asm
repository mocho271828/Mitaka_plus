
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  7bd800: 55                           	push	ebp
  7bd801: 8b ec                        	mov	ebp, esp
  7bd803: 6a ff                        	push	-0x1
  7bd805: 68 a0 d8 7b 00               	push	0x7bd8a0
  7bd80a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  7bd810: 50                           	push	eax
  7bd811: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  7bd818: 83 ec 18                     	sub	esp, 0x18
  7bd81b: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  7bd81e: 89 7d e4                     	mov	dword ptr [ebp - 0x1c], edi
  7bd821: 89 75 e8                     	mov	dword ptr [ebp - 0x18], esi
  7bd824: a1 60 67 19 01               	mov	eax, dword ptr [0x1196760]
  7bd829: 85 c0                        	test	eax, eax
  7bd82b: 74 0e                        	je	0x7bd83b <.text+0x3bc83b>
  7bd82d: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  7bd830: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  7bd837: 8b e5                        	mov	esp, ebp
  7bd839: 5d                           	pop	ebp
  7bd83a: c3                           	ret
  7bd83b: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  7bd842: c7 45 dc 00 00 00 00         	mov	dword ptr [ebp - 0x24], 0x0
  7bd849: 50                           	push	eax
  7bd84a: c7 04 24 28 00 00 00         	mov	dword ptr [esp], 0x28
  7bd851: e8 b4 17 2d 00               	call	0xa8f00a <.text+0x68e00a>
  7bd856: 59                           	pop	ecx
  7bd857: 89 45 e0                     	mov	dword ptr [ebp - 0x20], eax
  7bd85a: 85 c0                        	test	eax, eax
  7bd85c: 74 1a                        	je	0x7bd878 <.text+0x3bc878>
  7bd85e: c7 45 dc 01 00 00 00         	mov	dword ptr [ebp - 0x24], 0x1
  7bd865: 8b c8                        	mov	ecx, eax
  7bd867: e8 44 00 00 00               	call	0x7bd8b0 <.text+0x3bc8b0>
  7bd86c: 8b 45 e0                     	mov	eax, dword ptr [ebp - 0x20]
  7bd86f: c7 45 dc 00 00 00 00         	mov	dword ptr [ebp - 0x24], 0x0
  7bd876: eb 02                        	jmp	0x7bd87a <.text+0x3bc87a>
  7bd878: 33 c0                        	xor	eax, eax
  7bd87a: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  7bd881: a3 60 67 19 01               	mov	dword ptr [0x1196760], eax
  7bd886: eb a5                        	jmp	0x7bd82d <.text+0x3bc82d>
  7bd888: 83 7d dc 00                  	cmp	dword ptr [ebp - 0x24], 0x0
  7bd88c: 74 09                        	je	0x7bd897 <.text+0x3bc897>
  7bd88e: ff 75 e0                     	push	dword ptr [ebp - 0x20]
  7bd891: e8 fc 16 2d 00               	call	0xa8ef92 <.text+0x68df92>
  7bd896: 59                           	pop	ecx
  7bd897: c3                           	ret
  7bd898: 90                           	nop
  7bd899: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  7bd8a0: b8 f8 ed 37 01               	mov	eax, 0x137edf8
  7bd8a5: e9 dc 16 2d 00               	jmp	0xa8ef86 <.text+0x68df86>
  7bd8aa: 90                           	nop
  7bd8ab: 90                           	nop
  7bd8ac: 90                           	nop
  7bd8ad: 90                           	nop
  7bd8ae: 90                           	nop
  7bd8af: 90                           	nop
  7bd8b0: 55                           	push	ebp
  7bd8b1: 8b ec                        	mov	ebp, esp
  7bd8b3: 6a ff                        	push	-0x1
  7bd8b5: 68 80 11 c1 00               	push	0xc11180
  7bd8ba: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  7bd8c0: 50                           	push	eax
  7bd8c1: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  7bd8c8: 83 ec 14                     	sub	esp, 0x14
  7bd8cb: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  7bd8ce: 89 7d e4                     	mov	dword ptr [ebp - 0x1c], edi
  7bd8d1: 89 75 e8                     	mov	dword ptr [ebp - 0x18], esi
  7bd8d4: 8b f1                        	mov	esi, ecx
  7bd8d6: 89 75 e0                     	mov	dword ptr [ebp - 0x20], esi
  7bd8d9: 6a 14                        	push	0x14
  7bd8db: e8 2a 17 2d 00               	call	0xa8f00a <.text+0x68e00a>
  7bd8e0: 59                           	pop	ecx
  7bd8e1: 85 c0                        	test	eax, eax
  7bd8e3: 74 06                        	je	0x7bd8eb <.text+0x3bc8eb>
  7bd8e5: c7 00 00 00 00 00            	mov	dword ptr [eax], 0x0
  7bd8eb: 8b d0                        	mov	edx, eax
  7bd8ed: 83 c2 04                     	add	edx, 0x4
  7bd8f0: 74 06                        	je	0x7bd8f8 <.text+0x3bc8f8>
  7bd8f2: c7 02 00 00 00 00            	mov	dword ptr [edx], 0x0
  7bd8f8: 8b d0                        	mov	edx, eax
  7bd8fa: 83 c2 08                     	add	edx, 0x8
  7bd8fd: 74 06                        	je	0x7bd905 <.text+0x3bc905>
  7bd8ff: c7 02 00 00 00 00            	mov	dword ptr [edx], 0x0
  7bd905: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  7bd90c: bb 01 00 00 00               	mov	ebx, 0x1
  7bd911: 88 58 10                     	mov	byte ptr [eax + 0x10], bl
  7bd914: 89 46 0c                     	mov	dword ptr [esi + 0xc], eax
  7bd917: 88 58 11                     	mov	byte ptr [eax + 0x11], bl
  7bd91a: 8b 46 0c                     	mov	eax, dword ptr [esi + 0xc]
  7bd91d: 89 40 04                     	mov	dword ptr [eax + 0x4], eax
  7bd920: 8b 56 0c                     	mov	edx, dword ptr [esi + 0xc]
  7bd923: 89 12                        	mov	dword ptr [edx], edx
  7bd925: 8b 4e 0c                     	mov	ecx, dword ptr [esi + 0xc]
  7bd928: 89 49 08                     	mov	dword ptr [ecx + 0x8], ecx
  7bd92b: 50                           	push	eax
  7bd92c: c7 46 10 00 00 00 00         	mov	dword ptr [esi + 0x10], 0x0
  7bd933: 8b 75 e0                     	mov	esi, dword ptr [ebp - 0x20]
  7bd936: c7 04 24 14 00 00 00         	mov	dword ptr [esp], 0x14
  7bd93d: e8 c8 16 2d 00               	call	0xa8f00a <.text+0x68e00a>
  7bd942: 59                           	pop	ecx
  7bd943: 85 c0                        	test	eax, eax
  7bd945: 74 06                        	je	0x7bd94d <.text+0x3bc94d>
  7bd947: c7 00 00 00 00 00            	mov	dword ptr [eax], 0x0
  7bd94d: 8b d0                        	mov	edx, eax
  7bd94f: 83 c2 04                     	add	edx, 0x4
  7bd952: 74 06                        	je	0x7bd95a <.text+0x3bc95a>
  7bd954: c7 02 00 00 00 00            	mov	dword ptr [edx], 0x0
  7bd95a: 8b d0                        	mov	edx, eax
  7bd95c: 83 c2 08                     	add	edx, 0x8
  7bd95f: 74 06                        	je	0x7bd967 <.text+0x3bc967>
  7bd961: c7 02 00 00 00 00            	mov	dword ptr [edx], 0x0
  7bd967: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  7bd96e: 88 58 10                     	mov	byte ptr [eax + 0x10], bl
  7bd971: 33 d2                        	xor	edx, edx
  7bd973: 89 46 18                     	mov	dword ptr [esi + 0x18], eax
  7bd976: 88 58 11                     	mov	byte ptr [eax + 0x11], bl
  7bd979: 8b 4e 18                     	mov	ecx, dword ptr [esi + 0x18]
  7bd97c: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  7bd97f: 89 49 04                     	mov	dword ptr [ecx + 0x4], ecx
  7bd982: 8b 46 18                     	mov	eax, dword ptr [esi + 0x18]
  7bd985: 89 00                        	mov	dword ptr [eax], eax
  7bd987: 8b 7e 18                     	mov	edi, dword ptr [esi + 0x18]
  7bd98a: 8b 45 e0                     	mov	eax, dword ptr [ebp - 0x20]
  7bd98d: 89 7f 08                     	mov	dword ptr [edi + 0x8], edi
  7bd990: 8b 7d e4                     	mov	edi, dword ptr [ebp - 0x1c]
  7bd993: 89 56 1c                     	mov	dword ptr [esi + 0x1c], edx
  7bd996: 8b 75 e8                     	mov	esi, dword ptr [ebp - 0x18]
  7bd999: 88 50 20                     	mov	byte ptr [eax + 0x20], dl
  7bd99c: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  7bd99f: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  7bd9a6: 8b e5                        	mov	esp, ebp
  7bd9a8: 5d                           	pop	ebp
  7bd9a9: c3                           	ret
  7bd9aa: 90                           	nop
  7bd9ab: 90                           	nop
  7bd9ac: 90                           	nop
  7bd9ad: 90                           	nop
  7bd9ae: 90                           	nop
  7bd9af: 90                           	nop
  7bd9b0: 8b 44 24 04                  	mov	eax, dword ptr [esp + 0x4]
  7bd9b4: c3                           	ret
  7bd9b5: 8d 74 26 00                  	lea	esi, [esi + eiz]
  7bd9b9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7bd9c0: 8b 54 24 04                  	mov	edx, dword ptr [esp + 0x4]
  7bd9c4: 8d 42 04                     	lea	eax, [edx + 0x4]
  7bd9c7: c3                           	ret
  7bd9c8: 90                           	nop
  7bd9c9: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  7bd9d0: 57                           	push	edi
  7bd9d1: 56                           	push	esi
  7bd9d2: 55                           	push	ebp
  7bd9d3: 53                           	push	ebx
  7bd9d4: 83 ec 10                     	sub	esp, 0x10
  7bd9d7: 8b d9                        	mov	ebx, ecx
  7bd9d9: 8b 44 24 24                  	mov	eax, dword ptr [esp + 0x24]
  7bd9dd: 85 c0                        	test	eax, eax
  7bd9df: 75 0a                        	jne	0x7bd9eb <.text+0x3bc9eb>
  7bd9e1: 83 c4 10                     	add	esp, 0x10
  7bd9e4: 5b                           	pop	ebx
  7bd9e5: 5d                           	pop	ebp
  7bd9e6: 5e                           	pop	esi
  7bd9e7: 5f                           	pop	edi
  7bd9e8: c2 04 00                     	ret	0x4
  7bd9eb: ff 70 1c                     	push	dword ptr [eax + 0x1c]
  7bd9ee: 8b cb                        	mov	ecx, ebx
  7bd9f0: e8 fb 09 00 00               	call	0x7be3f0 <.text+0x3bd3f0>
  7bd9f5: 8b e8                        	mov	ebp, eax
  7bd9f7: 8d 73 08                     	lea	esi, [ebx + 0x8]
  7bd9fa: 85 ed                        	test	ebp, ebp
  7bd9fc: 74 5c                        	je	0x7bda5a <.text+0x3bca5a>
  7bd9fe: 8b 4e 04                     	mov	ecx, dword ptr [esi + 0x4]
  7bda01: 8b 51 04                     	mov	edx, dword ptr [ecx + 0x4]
  7bda04: 0f be 7a 11                  	movsx	edi, byte ptr [edx + 0x11]
  7bda08: 8b c1                        	mov	eax, ecx
  7bda0a: 85 ff                        	test	edi, edi
  7bda0c: 75 16                        	jne	0x7bda24 <.text+0x3bca24>
  7bda0e: 3b 6a 0c                     	cmp	ebp, dword ptr [edx + 0xc]
  7bda11: 76 05                        	jbe	0x7bda18 <.text+0x3bca18>
  7bda13: 8b 52 08                     	mov	edx, dword ptr [edx + 0x8]
  7bda16: eb 04                        	jmp	0x7bda1c <.text+0x3bca1c>
  7bda18: 8b c2                        	mov	eax, edx
  7bda1a: 8b 12                        	mov	edx, dword ptr [edx]
  7bda1c: 0f be 7a 11                  	movsx	edi, byte ptr [edx + 0x11]
  7bda20: 85 ff                        	test	edi, edi
  7bda22: 74 ea                        	je	0x7bda0e <.text+0x3bca0e>
  7bda24: 3b c1                        	cmp	eax, ecx
  7bda26: 75 09                        	jne	0x7bda31 <.text+0x3bca31>
  7bda28: 89 34 24                     	mov	dword ptr [esp], esi
  7bda2b: 89 4c 24 04                  	mov	dword ptr [esp + 0x4], ecx
  7bda2f: eb 0c                        	jmp	0x7bda3d <.text+0x3bca3d>
  7bda31: 3b 68 0c                     	cmp	ebp, dword ptr [eax + 0xc]
  7bda34: 72 f2                        	jb	0x7bda28 <.text+0x3bca28>
  7bda36: 89 34 24                     	mov	dword ptr [esp], esi
  7bda39: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  7bda3d: 8d 44 24 08                  	lea	eax, [esp + 0x8]
  7bda41: ff 74 24 04                  	push	dword ptr [esp + 0x4]
  7bda45: 8b ce                        	mov	ecx, esi
  7bda47: ff 74 24 04                  	push	dword ptr [esp + 0x4]
  7bda4b: 50                           	push	eax
  7bda4c: e8 5f 11 00 00               	call	0x7bebb0 <.text+0x3bdbb0>
  7bda51: 6a 01                        	push	0x1
  7bda53: 8b 45 00                     	mov	eax, dword ptr [ebp]
  7bda56: 8b cd                        	mov	ecx, ebp
  7bda58: ff 10                        	call	dword ptr [eax]
  7bda5a: 8b 53 0c                     	mov	edx, dword ptr [ebx + 0xc]
  7bda5d: 8b 42 04                     	mov	eax, dword ptr [edx + 0x4]
  7bda60: 0f be 48 11                  	movsx	ecx, byte ptr [eax + 0x11]
  7bda64: 8b ea                        	mov	ebp, edx
  7bda66: 85 c9                        	test	ecx, ecx
  7bda68: 74 07                        	je	0x7bda71 <.text+0x3bca71>
  7bda6a: bb 01 00 00 00               	mov	ebx, 0x1
  7bda6f: eb 1f                        	jmp	0x7bda90 <.text+0x3bca90>
  7bda71: 8b 4c 24 24                  	mov	ecx, dword ptr [esp + 0x24]
  7bda75: 33 db                        	xor	ebx, ebx
  7bda77: 3b 48 0c                     	cmp	ecx, dword ptr [eax + 0xc]
  7bda7a: 8b e8                        	mov	ebp, eax
  7bda7c: 83 d3 00                     	adc	ebx, 0x0
  7bda7f: 74 04                        	je	0x7bda85 <.text+0x3bca85>
  7bda81: 8b 00                        	mov	eax, dword ptr [eax]
  7bda83: eb 03                        	jmp	0x7bda88 <.text+0x3bca88>
  7bda85: 8b 40 08                     	mov	eax, dword ptr [eax + 0x8]
  7bda88: 0f be 78 11                  	movsx	edi, byte ptr [eax + 0x11]
  7bda8c: 85 ff                        	test	edi, edi
  7bda8e: 74 e5                        	je	0x7bda75 <.text+0x3bca75>
  7bda90: 8b cd                        	mov	ecx, ebp
  7bda92: 85 db                        	test	ebx, ebx
  7bda94: 0f 84 84 00 00 00            	je	0x7bdb1e <.text+0x3bcb1e>
  7bda9a: 3b 2a                        	cmp	ebp, dword ptr [edx]
  7bda9c: 75 1d                        	jne	0x7bdabb <.text+0x3bcabb>
  7bda9e: 8d 14 24                     	lea	edx, [esp]
  7bdaa1: 8d 44 24 24                  	lea	eax, [esp + 0x24]
  7bdaa5: 50                           	push	eax
  7bdaa6: 8b ce                        	mov	ecx, esi
  7bdaa8: 55                           	push	ebp
  7bdaa9: 6a 01                        	push	0x1
  7bdaab: 52                           	push	edx
  7bdaac: e8 9f 00 00 00               	call	0x7bdb50 <.text+0x3bcb50>
  7bdab1: 83 c4 10                     	add	esp, 0x10
  7bdab4: 5b                           	pop	ebx
  7bdab5: 5d                           	pop	ebp
  7bdab6: 5e                           	pop	esi
  7bdab7: 5f                           	pop	edi
  7bdab8: c2 04 00                     	ret	0x4
  7bdabb: 0f be 45 11                  	movsx	eax, byte ptr [ebp + 0x11]
  7bdabf: 85 c0                        	test	eax, eax
  7bdac1: 74 0d                        	je	0x7bdad0 <.text+0x3bcad0>
  7bdac3: 8b 4d 08                     	mov	ecx, dword ptr [ebp + 0x8]
  7bdac6: 0f be 41 11                  	movsx	eax, byte ptr [ecx + 0x11]
  7bdaca: 85 c0                        	test	eax, eax
  7bdacc: 75 75                        	jne	0x7bdb43 <.text+0x3bcb43>
  7bdace: eb 4e                        	jmp	0x7bdb1e <.text+0x3bcb1e>
  7bdad0: 8b 55 00                     	mov	edx, dword ptr [ebp]
  7bdad3: 0f be 42 11                  	movsx	eax, byte ptr [edx + 0x11]
  7bdad7: 85 c0                        	test	eax, eax
  7bdad9: 75 1d                        	jne	0x7bdaf8 <.text+0x3bcaf8>
  7bdadb: 8b 42 08                     	mov	eax, dword ptr [edx + 0x8]
  7bdade: 8b ca                        	mov	ecx, edx
  7bdae0: 0f be 50 11                  	movsx	edx, byte ptr [eax + 0x11]
  7bdae4: 85 d2                        	test	edx, edx
  7bdae6: 75 36                        	jne	0x7bdb1e <.text+0x3bcb1e>
  7bdae8: 8b 49 08                     	mov	ecx, dword ptr [ecx + 0x8]
  7bdaeb: 8b 41 08                     	mov	eax, dword ptr [ecx + 0x8]
  7bdaee: 0f be 50 11                  	movsx	edx, byte ptr [eax + 0x11]
  7bdaf2: 85 d2                        	test	edx, edx
  7bdaf4: 74 f2                        	je	0x7bdae8 <.text+0x3bcae8>
  7bdaf6: eb 26                        	jmp	0x7bdb1e <.text+0x3bcb1e>
  7bdaf8: 8b 45 04                     	mov	eax, dword ptr [ebp + 0x4]
  7bdafb: 0f be 50 11                  	movsx	edx, byte ptr [eax + 0x11]
  7bdaff: 85 d2                        	test	edx, edx
  7bdb01: 75 11                        	jne	0x7bdb14 <.text+0x3bcb14>
  7bdb03: 3b 08                        	cmp	ecx, dword ptr [eax]
  7bdb05: 75 0d                        	jne	0x7bdb14 <.text+0x3bcb14>
  7bdb07: 8b c8                        	mov	ecx, eax
  7bdb09: 8b 40 04                     	mov	eax, dword ptr [eax + 0x4]
  7bdb0c: 0f be 50 11                  	movsx	edx, byte ptr [eax + 0x11]
  7bdb10: 85 d2                        	test	edx, edx
  7bdb12: 74 ef                        	je	0x7bdb03 <.text+0x3bcb03>
  7bdb14: 0f be 51 11                  	movsx	edx, byte ptr [ecx + 0x11]
  7bdb18: 85 d2                        	test	edx, edx
  7bdb1a: 75 27                        	jne	0x7bdb43 <.text+0x3bcb43>
  7bdb1c: 8b c8                        	mov	ecx, eax
  7bdb1e: 8b 41 0c                     	mov	eax, dword ptr [ecx + 0xc]
  7bdb21: 3b 44 24 24                  	cmp	eax, dword ptr [esp + 0x24]
  7bdb25: 73 12                        	jae	0x7bdb39 <.text+0x3bcb39>
  7bdb27: 8d 14 24                     	lea	edx, [esp]
  7bdb2a: 8d 44 24 24                  	lea	eax, [esp + 0x24]
  7bdb2e: 50                           	push	eax
  7bdb2f: 8b ce                        	mov	ecx, esi
  7bdb31: 55                           	push	ebp
  7bdb32: 53                           	push	ebx
  7bdb33: 52                           	push	edx
  7bdb34: e8 17 00 00 00               	call	0x7bdb50 <.text+0x3bcb50>
  7bdb39: 83 c4 10                     	add	esp, 0x10
  7bdb3c: 5b                           	pop	ebx
  7bdb3d: 5d                           	pop	ebp
  7bdb3e: 5e                           	pop	esi
  7bdb3f: 5f                           	pop	edi
  7bdb40: c2 04 00                     	ret	0x4
  7bdb43: ff 15 1c 56 c2 00            	call	dword ptr [0xc2561c]
  7bdb49: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  7bdb50: 55                           	push	ebp
  7bdb51: 8b ec                        	mov	ebp, esp
  7bdb53: 6a ff                        	push	-0x1
  7bdb55: 68 c0 11 c1 00               	push	0xc111c0
  7bdb5a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  7bdb60: 50                           	push	eax
  7bdb61: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  7bdb68: 81 ec a0 00 00 00            	sub	esp, 0xa0
  7bdb6e: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
  7bdb71: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  7bdb74: 89 7d e4                     	mov	dword ptr [ebp - 0x1c], edi
  7bdb77: 89 75 e8                     	mov	dword ptr [ebp - 0x18], esi
  7bdb7a: 8b d9                        	mov	ebx, ecx
  7bdb7c: a1 10 53 d8 00               	mov	eax, dword ptr [0xd85310]
  7bdb81: 89 85 68 ff ff ff            	mov	dword ptr [ebp - 0x98], eax
  7bdb87: 81 7b 08 fe ff ff 3f         	cmp	dword ptr [ebx + 0x8], 0x3ffffffe
  7bdb8e: 0f 82 31 01 00 00            	jb	0x7bdcc5 <.text+0x3bccc5>
  7bdb94: c7 45 94 0f 00 00 00         	mov	dword ptr [ebp - 0x6c], 0xf
  7bdb9b: 8d 4d 80                     	lea	ecx, [ebp - 0x80]
  7bdb9e: 33 d2                        	xor	edx, edx
  7bdba0: 89 55 90                     	mov	dword ptr [ebp - 0x70], edx
  7bdba3: c7 85 70 ff ff ff 13 00 00 00	mov	dword ptr [ebp - 0x90], 0x13
  7bdbad: 88 11                        	mov	byte ptr [ecx], dl
  7bdbaf: 8b 75 94                     	mov	esi, dword ptr [ebp - 0x6c]
  7bdbb2: 8b 45 80                     	mov	eax, dword ptr [ebp - 0x80]
  7bdbb5: 8d 9d 7c ff ff ff            	lea	ebx, [ebp - 0x84]
  7bdbbb: 89 9d 6c ff ff ff            	mov	dword ptr [ebp - 0x94], ebx
  7bdbc1: 83 fe 10                     	cmp	esi, 0x10
  7bdbc4: 0f 42 c1                     	cmovb	eax, ecx
  7bdbc7: ba cc a1 c2 00               	mov	edx, 0xc2a1cc
  7bdbcc: 3b d0                        	cmp	edx, eax
  7bdbce: 0f 83 6f 06 00 00            	jae	0x7be243 <.text+0x3bd243>
  7bdbd4: 33 c0                        	xor	eax, eax
  7bdbd6: 85 c0                        	test	eax, eax
  7bdbd8: 74 17                        	je	0x7bdbf1 <.text+0x3bcbf1>
  7bdbda: 6a 13                        	push	0x13
  7bdbdc: 83 fe 10                     	cmp	esi, 0x10
  7bdbdf: 0f 43 4d 80                  	cmovae	ecx, dword ptr [ebp - 0x80]
  7bdbe3: 2b d1                        	sub	edx, ecx
  7bdbe5: 8b cb                        	mov	ecx, ebx
  7bdbe7: 52                           	push	edx
  7bdbe8: 53                           	push	ebx
  7bdbe9: ff 15 cc 53 c2 00            	call	dword ptr [0xc253cc]
  7bdbef: eb 20                        	jmp	0x7bdc11 <.text+0x3bcc11>
  7bdbf1: c7 85 68 ff ff ff 13 00 00 00	mov	dword ptr [ebp - 0x98], 0x13
  7bdbfb: 83 fe 13                     	cmp	esi, 0x13
  7bdbfe: 0f 82 c2 04 00 00            	jb	0x7be0c6 <.text+0x3bd0c6>
  7bdc04: 83 bd 68 ff ff ff 00         	cmp	dword ptr [ebp - 0x98], 0x0
  7bdc0b: 0f 87 63 04 00 00            	ja	0x7be074 <.text+0x3bd074>
  7bdc11: c7 45 fc 04 00 00 00         	mov	dword ptr [ebp - 0x4], 0x4
  7bdc18: 8d bd 54 ff ff ff            	lea	edi, [ebp - 0xac]
  7bdc1e: 89 7d d0                     	mov	dword ptr [ebp - 0x30], edi
  7bdc21: 8b cf                        	mov	ecx, edi
  7bdc23: 89 5d d8                     	mov	dword ptr [ebp - 0x28], ebx
  7bdc26: ff 15 fc 55 c2 00            	call	dword ptr [0xc255fc]
  7bdc2c: c7 45 fc 05 00 00 00         	mov	dword ptr [ebp - 0x4], 0x5
  7bdc33: 8b 45 d0                     	mov	eax, dword ptr [ebp - 0x30]
  7bdc36: 8b 55 d8                     	mov	edx, dword ptr [ebp - 0x28]
  7bdc39: 8b 35 d0 53 c2 00            	mov	esi, dword ptr [0xc253d0]
  7bdc3f: 8b 36                        	mov	esi, dword ptr [esi]
  7bdc41: 33 db                        	xor	ebx, ebx
  7bdc43: c7 00 2c a1 d3 00            	mov	dword ptr [eax], 0xd3a12c
  7bdc49: 8d 85 60 ff ff ff            	lea	eax, [ebp - 0xa0]
  7bdc4f: 89 58 14                     	mov	dword ptr [eax + 0x14], ebx
  7bdc52: 89 45 d4                     	mov	dword ptr [ebp - 0x2c], eax
  7bdc55: c7 40 18 0f 00 00 00         	mov	dword ptr [eax + 0x18], 0xf
  7bdc5c: 88 9d 64 ff ff ff            	mov	byte ptr [ebp - 0x9c], bl
  7bdc62: 8b 5a 14                     	mov	ebx, dword ptr [edx + 0x14]
  7bdc65: 89 45 dc                     	mov	dword ptr [ebp - 0x24], eax
  7bdc68: 3b de                        	cmp	ebx, esi
  7bdc6a: 0f 43 de                     	cmovae	ebx, esi
  7bdc6d: 89 55 e0                     	mov	dword ptr [ebp - 0x20], edx
  7bdc70: 89 5d cc                     	mov	dword ptr [ebp - 0x34], ebx
  7bdc73: 3b c2                        	cmp	eax, edx
  7bdc75: 0f 84 76 03 00 00            	je	0x7bdff1 <.text+0x3bcff1>
  7bdc7b: 89 5d c8                     	mov	dword ptr [ebp - 0x38], ebx
  7bdc7e: 83 fb fe                     	cmp	ebx, -0x2
  7bdc81: 76 0c                        	jbe	0x7bdc8f <.text+0x3bcc8f>
  7bdc83: ff 15 d4 53 c2 00            	call	dword ptr [0xc253d4]
  7bdc89: 8b 45 d4                     	mov	eax, dword ptr [ebp - 0x2c]
  7bdc8c: 8b 5d c8                     	mov	ebx, dword ptr [ebp - 0x38]
  7bdc8f: 8b 48 18                     	mov	ecx, dword ptr [eax + 0x18]
  7bdc92: 3b cb                        	cmp	ecx, ebx
  7bdc94: 0f 82 02 02 00 00            	jb	0x7bde9c <.text+0x3bce9c>
  7bdc9a: 85 db                        	test	ebx, ebx
  7bdc9c: 0f 84 de 01 00 00            	je	0x7bde80 <.text+0x3bce80>
  7bdca2: 85 db                        	test	ebx, ebx
  7bdca4: 0f 87 82 01 00 00            	ja	0x7bde2c <.text+0x3bce2c>
  7bdcaa: c7 45 fc 04 00 00 00         	mov	dword ptr [ebp - 0x4], 0x4
  7bdcb1: 68 38 03 d7 00               	push	0xd70338
  7bdcb6: 8b 45 d0                     	mov	eax, dword ptr [ebp - 0x30]
  7bdcb9: 57                           	push	edi
  7bdcba: c7 00 38 a1 d3 00            	mov	dword ptr [eax], 0xd3a138
  7bdcc0: e8 51 13 2d 00               	call	0xa8f016 <.text+0x68e016>
  7bdcc5: 6a 14                        	push	0x14
  7bdcc7: 8b 73 04                     	mov	esi, dword ptr [ebx + 0x4]
  7bdcca: e8 3b 13 2d 00               	call	0xa8f00a <.text+0x68e00a>
  7bdccf: 59                           	pop	ecx
  7bdcd0: 8b 55 10                     	mov	edx, dword ptr [ebp + 0x10]
  7bdcd3: 85 c0                        	test	eax, eax
  7bdcd5: 74 18                        	je	0x7bdcef <.text+0x3bccef>
  7bdcd7: 8b 7d 14                     	mov	edi, dword ptr [ebp + 0x14]
  7bdcda: 89 30                        	mov	dword ptr [eax], esi
  7bdcdc: 89 50 04                     	mov	dword ptr [eax + 0x4], edx
  7bdcdf: 89 70 08                     	mov	dword ptr [eax + 0x8], esi
  7bdce2: 8b 37                        	mov	esi, dword ptr [edi]
  7bdce4: 89 70 0c                     	mov	dword ptr [eax + 0xc], esi
  7bdce7: 33 c9                        	xor	ecx, ecx
  7bdce9: 88 48 10                     	mov	byte ptr [eax + 0x10], cl
  7bdcec: 88 48 11                     	mov	byte ptr [eax + 0x11], cl
  7bdcef: 8b 4b 04                     	mov	ecx, dword ptr [ebx + 0x4]
  7bdcf2: ff 43 08                     	inc	dword ptr [ebx + 0x8]
  7bdcf5: 3b d1                        	cmp	edx, ecx
  7bdcf7: 0f 84 da 06 00 00            	je	0x7be3d7 <.text+0x3bd3d7>
  7bdcfd: 0f b6 4d 0c                  	movzx	ecx, byte ptr [ebp + 0xc]
  7bdd01: 85 c9                        	test	ecx, ecx
  7bdd03: 74 0f                        	je	0x7bdd14 <.text+0x3bcd14>
  7bdd05: 89 02                        	mov	dword ptr [edx], eax
  7bdd07: 8b 4b 04                     	mov	ecx, dword ptr [ebx + 0x4]
  7bdd0a: 3b 11                        	cmp	edx, dword ptr [ecx]
  7bdd0c: 0f 84 4f 05 00 00            	je	0x7be261 <.text+0x3bd261>
  7bdd12: eb 0f                        	jmp	0x7bdd23 <.text+0x3bcd23>
  7bdd14: 89 42 08                     	mov	dword ptr [edx + 0x8], eax
  7bdd17: 8b 4b 04                     	mov	ecx, dword ptr [ebx + 0x4]
  7bdd1a: 3b 51 08                     	cmp	edx, dword ptr [ecx + 0x8]
  7bdd1d: 0f 84 ac 06 00 00            	je	0x7be3cf <.text+0x3bd3cf>
  7bdd23: 8b 50 04                     	mov	edx, dword ptr [eax + 0x4]
  7bdd26: 0f be 72 10                  	movsx	esi, byte ptr [edx + 0x10]
  7bdd2a: 8b c8                        	mov	ecx, eax
  7bdd2c: 85 f6                        	test	esi, esi
  7bdd2e: 0f 85 a9 00 00 00            	jne	0x7bdddd <.text+0x3bcddd>
  7bdd34: 8b 71 04                     	mov	esi, dword ptr [ecx + 0x4]
  7bdd37: 8b 56 04                     	mov	edx, dword ptr [esi + 0x4]
  7bdd3a: 8b 3a                        	mov	edi, dword ptr [edx]
  7bdd3c: 89 95 64 ff ff ff            	mov	dword ptr [ebp - 0x9c], edx
  7bdd42: 3b f7                        	cmp	esi, edi
  7bdd44: 0f 84 92 05 00 00            	je	0x7be2dc <.text+0x3bd2dc>
  7bdd4a: 0f be 57 10                  	movsx	edx, byte ptr [edi + 0x10]
  7bdd4e: 85 d2                        	test	edx, edx
  7bdd50: 75 1d                        	jne	0x7bdd6f <.text+0x3bcd6f>
  7bdd52: ba 01 00 00 00               	mov	edx, 0x1
  7bdd57: 88 56 10                     	mov	byte ptr [esi + 0x10], dl
  7bdd5a: 88 57 10                     	mov	byte ptr [edi + 0x10], dl
  7bdd5d: 8b 71 04                     	mov	esi, dword ptr [ecx + 0x4]
  7bdd60: 8b 7e 04                     	mov	edi, dword ptr [esi + 0x4]
  7bdd63: c6 47 10 00                  	mov	byte ptr [edi + 0x10], 0x0
  7bdd67: 8b 49 04                     	mov	ecx, dword ptr [ecx + 0x4]
  7bdd6a: 8b 49 04                     	mov	ecx, dword ptr [ecx + 0x4]
  7bdd6d: eb 5f                        	jmp	0x7bddce <.text+0x3bcdce>
  7bdd6f: 8b 16                        	mov	edx, dword ptr [esi]
  7bdd71: 3b ca                        	cmp	ecx, edx
  7bdd73: 0f 84 05 05 00 00            	je	0x7be27e <.text+0x3bd27e>
  7bdd79: c6 46 10 01                  	mov	byte ptr [esi + 0x10], 0x1
  7bdd7d: 8b 51 04                     	mov	edx, dword ptr [ecx + 0x4]
  7bdd80: 8b 72 04                     	mov	esi, dword ptr [edx + 0x4]
  7bdd83: c6 46 10 00                  	mov	byte ptr [esi + 0x10], 0x0
  7bdd87: 8b 79 04                     	mov	edi, dword ptr [ecx + 0x4]
  7bdd8a: 8b 77 04                     	mov	esi, dword ptr [edi + 0x4]
  7bdd8d: 8b 56 08                     	mov	edx, dword ptr [esi + 0x8]
  7bdd90: 8b 3a                        	mov	edi, dword ptr [edx]
  7bdd92: 89 7e 08                     	mov	dword ptr [esi + 0x8], edi
  7bdd95: 8b 3a                        	mov	edi, dword ptr [edx]
  7bdd97: 89 bd 60 ff ff ff            	mov	dword ptr [ebp - 0xa0], edi
  7bdd9d: 0f be 7f 11                  	movsx	edi, byte ptr [edi + 0x11]
  7bdda1: 85 ff                        	test	edi, edi
  7bdda3: 0f 84 c7 04 00 00            	je	0x7be270 <.text+0x3bd270>
  7bdda9: 8b 7e 04                     	mov	edi, dword ptr [esi + 0x4]
  7bddac: 89 7a 04                     	mov	dword ptr [edx + 0x4], edi
  7bddaf: 8b 7b 04                     	mov	edi, dword ptr [ebx + 0x4]
  7bddb2: 3b 77 04                     	cmp	esi, dword ptr [edi + 0x4]
  7bddb5: 0f 84 ad 04 00 00            	je	0x7be268 <.text+0x3bd268>
  7bddbb: 8b 7e 04                     	mov	edi, dword ptr [esi + 0x4]
  7bddbe: 3b 37                        	cmp	esi, dword ptr [edi]
  7bddc0: 74 05                        	je	0x7bddc7 <.text+0x3bcdc7>
  7bddc2: 89 57 08                     	mov	dword ptr [edi + 0x8], edx
  7bddc5: eb 02                        	jmp	0x7bddc9 <.text+0x3bcdc9>
  7bddc7: 89 17                        	mov	dword ptr [edi], edx
  7bddc9: 89 32                        	mov	dword ptr [edx], esi
  7bddcb: 89 56 04                     	mov	dword ptr [esi + 0x4], edx
  7bddce: 8b 51 04                     	mov	edx, dword ptr [ecx + 0x4]
  7bddd1: 0f be 72 10                  	movsx	esi, byte ptr [edx + 0x10]
  7bddd5: 85 f6                        	test	esi, esi
  7bddd7: 0f 84 57 ff ff ff            	je	0x7bdd34 <.text+0x3bcd34>
  7bdddd: 8b 75 08                     	mov	esi, dword ptr [ebp + 0x8]
  7bdde0: 8b 53 04                     	mov	edx, dword ptr [ebx + 0x4]
  7bdde3: 8b 7a 04                     	mov	edi, dword ptr [edx + 0x4]
  7bdde6: c6 47 10 01                  	mov	byte ptr [edi + 0x10], 0x1
  7bddea: 89 46 04                     	mov	dword ptr [esi + 0x4], eax
  7bdded: 89 1e                        	mov	dword ptr [esi], ebx
  7bddef: 8b 8d 68 ff ff ff            	mov	ecx, dword ptr [ebp - 0x98]
  7bddf5: e8 c6 10 2d 00               	call	0xa8eec0 <.text+0x68dec0>
  7bddfa: 8b 7d e4                     	mov	edi, dword ptr [ebp - 0x1c]
  7bddfd: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  7bde00: 8b c6                        	mov	eax, esi
  7bde02: 8b 75 e8                     	mov	esi, dword ptr [ebp - 0x18]
  7bde05: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  7bde08: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  7bde0f: 8b e5                        	mov	esp, ebp
  7bde11: 5d                           	pop	ebp
  7bde12: c2 10 00                     	ret	0x10
  7bde15: 8d 8d 7c ff ff ff            	lea	ecx, [ebp - 0x84]
  7bde1b: ff 15 bc 53 c2 00            	call	dword ptr [0xc253bc]
  7bde21: c3                           	ret
  7bde22: 8b 4d d0                     	mov	ecx, dword ptr [ebp - 0x30]
  7bde25: ff 15 d4 55 c2 00            	call	dword ptr [0xc255d4]
  7bde2b: c3                           	ret
  7bde2c: 8b 50 18                     	mov	edx, dword ptr [eax + 0x18]
  7bde2f: 83 fa 10                     	cmp	edx, 0x10
  7bde32: 72 05                        	jb	0x7bde39 <.text+0x3bce39>
  7bde34: 8b 48 04                     	mov	ecx, dword ptr [eax + 0x4]
  7bde37: eb 06                        	jmp	0x7bde3f <.text+0x3bce3f>
  7bde39: 8b 4d dc                     	mov	ecx, dword ptr [ebp - 0x24]
  7bde3c: 83 c1 04                     	add	ecx, 0x4
  7bde3f: 8b 45 d8                     	mov	eax, dword ptr [ebp - 0x28]
  7bde42: 83 78 18 10                  	cmp	dword ptr [eax + 0x18], 0x10
  7bde46: 72 05                        	jb	0x7bde4d <.text+0x3bce4d>
  7bde48: 8b 40 04                     	mov	eax, dword ptr [eax + 0x4]
  7bde4b: eb 06                        	jmp	0x7bde53 <.text+0x3bce53>
  7bde4d: 8b 45 e0                     	mov	eax, dword ptr [ebp - 0x20]
  7bde50: 83 c0 04                     	add	eax, 0x4
  7bde53: 8b 5d cc                     	mov	ebx, dword ptr [ebp - 0x34]
  7bde56: 53                           	push	ebx
  7bde57: 50                           	push	eax
  7bde58: 52                           	push	edx
  7bde59: 51                           	push	ecx
  7bde5a: ff 15 00 56 c2 00            	call	dword ptr [0xc25600]
  7bde60: 83 c4 10                     	add	esp, 0x10
  7bde63: 8b 45 d4                     	mov	eax, dword ptr [ebp - 0x2c]
  7bde66: 83 78 18 10                  	cmp	dword ptr [eax + 0x18], 0x10
  7bde6a: 89 58 14                     	mov	dword ptr [eax + 0x14], ebx
  7bde6d: 72 05                        	jb	0x7bde74 <.text+0x3bce74>
  7bde6f: 8b 40 04                     	mov	eax, dword ptr [eax + 0x4]
  7bde72: eb 03                        	jmp	0x7bde77 <.text+0x3bce77>
  7bde74: 83 c0 04                     	add	eax, 0x4
  7bde77: c6 04 18 00                  	mov	byte ptr [eax + ebx], 0x0
  7bde7b: e9 2a fe ff ff               	jmp	0x7bdcaa <.text+0x3bccaa>
  7bde80: c7 40 14 00 00 00 00         	mov	dword ptr [eax + 0x14], 0x0
  7bde87: 83 f9 10                     	cmp	ecx, 0x10
  7bde8a: 72 05                        	jb	0x7bde91 <.text+0x3bce91>
  7bde8c: 8b 40 04                     	mov	eax, dword ptr [eax + 0x4]
  7bde8f: eb 03                        	jmp	0x7bde94 <.text+0x3bce94>
  7bde91: 83 c0 04                     	add	eax, 0x4
  7bde94: c6 00 00                     	mov	byte ptr [eax], 0x0
  7bde97: e9 0e fe ff ff               	jmp	0x7bdcaa <.text+0x3bccaa>
  7bde9c: 89 45 c0                     	mov	dword ptr [ebp - 0x40], eax
  7bde9f: 8b 40 14                     	mov	eax, dword ptr [eax + 0x14]
  7bdea2: 89 45 c4                     	mov	dword ptr [ebp - 0x3c], eax
  7bdea5: 8b f3                        	mov	esi, ebx
  7bdea7: 83 ce 0f                     	or	esi, 0xf
  7bdeaa: 83 fe fe                     	cmp	esi, -0x2
  7bdead: 0f 87 34 01 00 00            	ja	0x7bdfe7 <.text+0x3bcfe7>
  7bdeb3: 8b d9                        	mov	ebx, ecx
  7bdeb5: d1 eb                        	shr	ebx
  7bdeb7: b8 ab aa aa aa               	mov	eax, 0xaaaaaaab
  7bdebc: f7 e6                        	mul	esi
  7bdebe: d1 ea                        	shr	edx
  7bdec0: 3b da                        	cmp	ebx, edx
  7bdec2: 77 05                        	ja	0x7bdec9 <.text+0x3bcec9>
  7bdec4: 89 75 b8                     	mov	dword ptr [ebp - 0x48], esi
  7bdec7: eb 11                        	jmp	0x7bdeda <.text+0x3bceda>
  7bdec9: 8b c3                        	mov	eax, ebx
  7bdecb: f7 d8                        	neg	eax
  7bdecd: 83 c0 fe                     	add	eax, -0x2
  7bded0: 3b c8                        	cmp	ecx, eax
  7bded2: 77 f0                        	ja	0x7bdec4 <.text+0x3bcec4>
  7bded4: 8d 34 19                     	lea	esi, [ecx + ebx]
  7bded7: 89 75 b8                     	mov	dword ptr [ebp - 0x48], esi
  7bdeda: c7 45 fc 06 00 00 00         	mov	dword ptr [ebp - 0x4], 0x6
  7bdee1: c7 45 bc 00 00 00 00         	mov	dword ptr [ebp - 0x44], 0x0
  7bdee8: 46                           	inc	esi
  7bdee9: 75 06                        	jne	0x7bdef1 <.text+0x3bcef1>
  7bdeeb: 33 c0                        	xor	eax, eax
  7bdeed: 33 f6                        	xor	esi, esi
  7bdeef: eb 36                        	jmp	0x7bdf27 <.text+0x3bcf27>
  7bdef1: 33 d2                        	xor	edx, edx
  7bdef3: b8 ff ff ff ff               	mov	eax, 0xffffffff
  7bdef8: f7 f6                        	div	esi
  7bdefa: 83 f8 01                     	cmp	eax, 0x1
  7bdefd: 73 28                        	jae	0x7bdf27 <.text+0x3bcf27>
  7bdeff: c7 45 b4 00 00 00 00         	mov	dword ptr [ebp - 0x4c], 0x0
  7bdf06: 8d 5d a4                     	lea	ebx, [ebp - 0x5c]
  7bdf09: 8b cb                        	mov	ecx, ebx
  7bdf0b: 8d 45 b4                     	lea	eax, [ebp - 0x4c]
  7bdf0e: 50                           	push	eax
  7bdf0f: ff 15 f0 55 c2 00            	call	dword ptr [0xc255f0]
  7bdf15: c7 45 a4 20 a1 d3 00         	mov	dword ptr [ebp - 0x5c], 0xd3a120
  7bdf1c: 68 18 01 d7 00               	push	0xd70118
  7bdf21: 53                           	push	ebx
  7bdf22: e8 ef 10 2d 00               	call	0xa8f016 <.text+0x68e016>
  7bdf27: 50                           	push	eax
  7bdf28: 89 34 24                     	mov	dword ptr [esp], esi
  7bdf2b: e8 da 10 2d 00               	call	0xa8f00a <.text+0x68e00a>
  7bdf30: 59                           	pop	ecx
  7bdf31: c7 45 fc 05 00 00 00         	mov	dword ptr [ebp - 0x4], 0x5
  7bdf38: 89 45 bc                     	mov	dword ptr [ebp - 0x44], eax
  7bdf3b: c7 45 fc 05 00 00 00         	mov	dword ptr [ebp - 0x4], 0x5
  7bdf42: 8b 55 c4                     	mov	edx, dword ptr [ebp - 0x3c]
  7bdf45: 85 d2                        	test	edx, edx
  7bdf47: 77 72                        	ja	0x7bdfbb <.text+0x3bcfbb>
  7bdf49: 8b 45 d4                     	mov	eax, dword ptr [ebp - 0x2c]
  7bdf4c: 83 78 18 10                  	cmp	dword ptr [eax + 0x18], 0x10
  7bdf50: 73 5b                        	jae	0x7bdfad <.text+0x3bcfad>
  7bdf52: 8b 5d bc                     	mov	ebx, dword ptr [ebp - 0x44]
  7bdf55: 8b 4d b8                     	mov	ecx, dword ptr [ebp - 0x48]
  7bdf58: 8b 7d c4                     	mov	edi, dword ptr [ebp - 0x3c]
  7bdf5b: 8d 70 04                     	lea	esi, [eax + 0x4]
  7bdf5e: 33 d2                        	xor	edx, edx
  7bdf60: 88 16                        	mov	byte ptr [esi], dl
  7bdf62: 89 58 04                     	mov	dword ptr [eax + 0x4], ebx
  7bdf65: 89 48 18                     	mov	dword ptr [eax + 0x18], ecx
  7bdf68: 89 78 14                     	mov	dword ptr [eax + 0x14], edi
  7bdf6b: 83 f9 10                     	cmp	ecx, 0x10
  7bdf6e: 0f 43 f3                     	cmovae	esi, ebx
  7bdf71: 8b 5d c8                     	mov	ebx, dword ptr [ebp - 0x38]
  7bdf74: 88 14 3e                     	mov	byte ptr [esi + edi], dl
  7bdf77: 8d bd 54 ff ff ff            	lea	edi, [ebp - 0xac]
  7bdf7d: e9 20 fd ff ff               	jmp	0x7bdca2 <.text+0x3bcca2>
  7bdf82: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
  7bdf85: c7 45 fc 08 00 00 00         	mov	dword ptr [ebp - 0x4], 0x8
  7bdf8c: 8b 45 c8                     	mov	eax, dword ptr [ebp - 0x38]
  7bdf8f: 8b 4d c0                     	mov	ecx, dword ptr [ebp - 0x40]
  7bdf92: 89 45 b8                     	mov	dword ptr [ebp - 0x48], eax
  7bdf95: 40                           	inc	eax
  7bdf96: 50                           	push	eax
  7bdf97: ff 15 d8 53 c2 00            	call	dword ptr [0xc253d8]
  7bdf9d: c7 45 fc 07 00 00 00         	mov	dword ptr [ebp - 0x4], 0x7
  7bdfa4: 89 45 bc                     	mov	dword ptr [ebp - 0x44], eax
  7bdfa7: b8 3b df 7b 00               	mov	eax, 0x7bdf3b
  7bdfac: c3                           	ret
  7bdfad: ff 70 04                     	push	dword ptr [eax + 0x4]
  7bdfb0: e8 dd 0f 2d 00               	call	0xa8ef92 <.text+0x68df92>
  7bdfb5: 59                           	pop	ecx
  7bdfb6: 8b 45 d4                     	mov	eax, dword ptr [ebp - 0x2c]
  7bdfb9: eb 97                        	jmp	0x7bdf52 <.text+0x3bcf52>
  7bdfbb: 8b 45 d4                     	mov	eax, dword ptr [ebp - 0x2c]
  7bdfbe: 83 78 18 10                  	cmp	dword ptr [eax + 0x18], 0x10
  7bdfc2: 72 05                        	jb	0x7bdfc9 <.text+0x3bcfc9>
  7bdfc4: 8b 40 04                     	mov	eax, dword ptr [eax + 0x4]
  7bdfc7: eb 06                        	jmp	0x7bdfcf <.text+0x3bcfcf>
  7bdfc9: 8b 45 c0                     	mov	eax, dword ptr [ebp - 0x40]
  7bdfcc: 83 c0 04                     	add	eax, 0x4
  7bdfcf: 8b 4d b8                     	mov	ecx, dword ptr [ebp - 0x48]
  7bdfd2: 52                           	push	edx
  7bdfd3: 50                           	push	eax
  7bdfd4: 41                           	inc	ecx
  7bdfd5: 51                           	push	ecx
  7bdfd6: ff 75 bc                     	push	dword ptr [ebp - 0x44]
  7bdfd9: ff 15 00 56 c2 00            	call	dword ptr [0xc25600]
  7bdfdf: 83 c4 10                     	add	esp, 0x10
  7bdfe2: e9 62 ff ff ff               	jmp	0x7bdf49 <.text+0x3bcf49>
  7bdfe7: 89 5d b8                     	mov	dword ptr [ebp - 0x48], ebx
  7bdfea: 8b f3                        	mov	esi, ebx
  7bdfec: e9 e9 fe ff ff               	jmp	0x7bdeda <.text+0x3bceda>
  7bdff1: 8b 50 14                     	mov	edx, dword ptr [eax + 0x14]
  7bdff4: 3b d3                        	cmp	edx, ebx
  7bdff6: 73 0c                        	jae	0x7be004 <.text+0x3bd004>
  7bdff8: ff 15 dc 53 c2 00            	call	dword ptr [0xc253dc]
  7bdffe: 8b 45 d4                     	mov	eax, dword ptr [ebp - 0x2c]
  7be001: 8b 50 14                     	mov	edx, dword ptr [eax + 0x14]
  7be004: 2b d3                        	sub	edx, ebx
  7be006: 3b d6                        	cmp	edx, esi
  7be008: 0f 42 f2                     	cmovb	esi, edx
  7be00b: 85 f6                        	test	esi, esi
  7be00d: 0f 86 97 fc ff ff            	jbe	0x7bdcaa <.text+0x3bccaa>
  7be013: 8b 48 18                     	mov	ecx, dword ptr [eax + 0x18]
  7be016: 89 4d a4                     	mov	dword ptr [ebp - 0x5c], ecx
  7be019: 83 f9 10                     	cmp	ecx, 0x10
  7be01c: 72 05                        	jb	0x7be023 <.text+0x3bd023>
  7be01e: 8b 40 04                     	mov	eax, dword ptr [eax + 0x4]
  7be021: eb 06                        	jmp	0x7be029 <.text+0x3bd029>
  7be023: 8d 85 64 ff ff ff            	lea	eax, [ebp - 0x9c]
  7be029: 83 c4 f0                     	add	esp, -0x10
  7be02c: 8d 0c 03                     	lea	ecx, [ebx + eax]
  7be02f: 89 0c 24                     	mov	dword ptr [esp], ecx
  7be032: 2b d6                        	sub	edx, esi
  7be034: 8b 4d a4                     	mov	ecx, dword ptr [ebp - 0x5c]
  7be037: 89 54 24 0c                  	mov	dword ptr [esp + 0xc], edx
  7be03b: 2b cb                        	sub	ecx, ebx
  7be03d: 03 de                        	add	ebx, esi
  7be03f: 03 d8                        	add	ebx, eax
  7be041: 89 4c 24 04                  	mov	dword ptr [esp + 0x4], ecx
  7be045: 89 5c 24 08                  	mov	dword ptr [esp + 0x8], ebx
  7be049: ff 15 f8 55 c2 00            	call	dword ptr [0xc255f8]
  7be04f: 83 c4 10                     	add	esp, 0x10
  7be052: 8b 45 d4                     	mov	eax, dword ptr [ebp - 0x2c]
  7be055: 8b 50 14                     	mov	edx, dword ptr [eax + 0x14]
  7be058: 2b d6                        	sub	edx, esi
  7be05a: 83 78 18 10                  	cmp	dword ptr [eax + 0x18], 0x10
  7be05e: 89 50 14                     	mov	dword ptr [eax + 0x14], edx
  7be061: 72 05                        	jb	0x7be068 <.text+0x3bd068>
  7be063: 8b 40 04                     	mov	eax, dword ptr [eax + 0x4]
  7be066: eb 03                        	jmp	0x7be06b <.text+0x3bd06b>
  7be068: 83 c0 04                     	add	eax, 0x4
  7be06b: c6 04 10 00                  	mov	byte ptr [eax + edx], 0x0
  7be06f: e9 36 fc ff ff               	jmp	0x7bdcaa <.text+0x3bccaa>
  7be074: 8b 95 6c ff ff ff            	mov	edx, dword ptr [ebp - 0x94]
  7be07a: 8b 42 18                     	mov	eax, dword ptr [edx + 0x18]
  7be07d: 83 f8 10                     	cmp	eax, 0x10
  7be080: 72 05                        	jb	0x7be087 <.text+0x3bd087>
  7be082: 8b 52 04                     	mov	edx, dword ptr [edx + 0x4]
  7be085: eb 03                        	jmp	0x7be08a <.text+0x3bd08a>
  7be087: 83 c2 04                     	add	edx, 0x4
  7be08a: ff b5 70 ff ff ff            	push	dword ptr [ebp - 0x90]
  7be090: 68 cc a1 c2 00               	push	0xc2a1cc
  7be095: 50                           	push	eax
  7be096: 52                           	push	edx
  7be097: ff 15 00 56 c2 00            	call	dword ptr [0xc25600]
  7be09d: 83 c4 10                     	add	esp, 0x10
  7be0a0: 8b 85 6c ff ff ff            	mov	eax, dword ptr [ebp - 0x94]
  7be0a6: 83 78 18 10                  	cmp	dword ptr [eax + 0x18], 0x10
  7be0aa: 8b 95 70 ff ff ff            	mov	edx, dword ptr [ebp - 0x90]
  7be0b0: 89 50 14                     	mov	dword ptr [eax + 0x14], edx
  7be0b3: 72 05                        	jb	0x7be0ba <.text+0x3bd0ba>
  7be0b5: 8b 40 04                     	mov	eax, dword ptr [eax + 0x4]
  7be0b8: eb 03                        	jmp	0x7be0bd <.text+0x3bd0bd>
  7be0ba: 83 c0 04                     	add	eax, 0x4
  7be0bd: c6 04 10 00                  	mov	byte ptr [eax + edx], 0x0
  7be0c1: e9 4b fb ff ff               	jmp	0x7bdc11 <.text+0x3bcc11>
  7be0c6: 8b 45 90                     	mov	eax, dword ptr [ebp - 0x70]
  7be0c9: 89 9d 5c ff ff ff            	mov	dword ptr [ebp - 0xa4], ebx
  7be0cf: 8b d6                        	mov	edx, esi
  7be0d1: 89 85 64 ff ff ff            	mov	dword ptr [ebp - 0x9c], eax
  7be0d7: b9 1f 00 00 00               	mov	ecx, 0x1f
  7be0dc: d1 ea                        	shr	edx
  7be0de: c7 85 60 ff ff ff 13 00 00 00	mov	dword ptr [ebp - 0xa0], 0x13
  7be0e8: 83 fa 0a                     	cmp	edx, 0xa
  7be0eb: 77 0c                        	ja	0x7be0f9 <.text+0x3bd0f9>
  7be0ed: c7 85 54 ff ff ff 1f 00 00 00	mov	dword ptr [ebp - 0xac], 0x1f
  7be0f7: eb 14                        	jmp	0x7be10d <.text+0x3bd10d>
  7be0f9: 8b c2                        	mov	eax, edx
  7be0fb: f7 d8                        	neg	eax
  7be0fd: 83 c0 fe                     	add	eax, -0x2
  7be100: 3b f0                        	cmp	esi, eax
  7be102: 77 e9                        	ja	0x7be0ed <.text+0x3bd0ed>
  7be104: 8d 0c 16                     	lea	ecx, [esi + edx]
  7be107: 89 8d 54 ff ff ff            	mov	dword ptr [ebp - 0xac], ecx
  7be10d: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  7be114: c7 85 58 ff ff ff 00 00 00 00	mov	dword ptr [ebp - 0xa8], 0x0
  7be11e: 41                           	inc	ecx
  7be11f: 75 04                        	jne	0x7be125 <.text+0x3bd125>
  7be121: 33 c9                        	xor	ecx, ecx
  7be123: eb 36                        	jmp	0x7be15b <.text+0x3bd15b>
  7be125: 33 d2                        	xor	edx, edx
  7be127: b8 ff ff ff ff               	mov	eax, 0xffffffff
  7be12c: f7 f1                        	div	ecx
  7be12e: 83 f8 01                     	cmp	eax, 0x1
  7be131: 73 28                        	jae	0x7be15b <.text+0x3bd15b>
  7be133: c7 45 b0 00 00 00 00         	mov	dword ptr [ebp - 0x50], 0x0
  7be13a: 8d 5d 98                     	lea	ebx, [ebp - 0x68]
  7be13d: 8b cb                        	mov	ecx, ebx
  7be13f: 8d 45 b0                     	lea	eax, [ebp - 0x50]
  7be142: 50                           	push	eax
  7be143: ff 15 f0 55 c2 00            	call	dword ptr [0xc255f0]
  7be149: c7 45 98 20 a1 d3 00         	mov	dword ptr [ebp - 0x68], 0xd3a120
  7be150: 68 18 01 d7 00               	push	0xd70118
  7be155: 53                           	push	ebx
  7be156: e8 bb 0e 2d 00               	call	0xa8f016 <.text+0x68e016>
  7be15b: 50                           	push	eax
  7be15c: 89 0c 24                     	mov	dword ptr [esp], ecx
  7be15f: e8 a6 0e 2d 00               	call	0xa8f00a <.text+0x68e00a>
  7be164: 59                           	pop	ecx
  7be165: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  7be16c: 89 85 58 ff ff ff            	mov	dword ptr [ebp - 0xa8], eax
  7be172: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  7be179: 8b 85 64 ff ff ff            	mov	eax, dword ptr [ebp - 0x9c]
  7be17f: 85 c0                        	test	eax, eax
  7be181: 0f 87 8a 00 00 00            	ja	0x7be211 <.text+0x3bd211>
  7be187: 8b bd 5c ff ff ff            	mov	edi, dword ptr [ebp - 0xa4]
  7be18d: 83 7f 18 10                  	cmp	dword ptr [edi + 0x18], 0x10
  7be191: 73 6d                        	jae	0x7be200 <.text+0x3bd200>
  7be193: 8b 8d 58 ff ff ff            	mov	ecx, dword ptr [ebp - 0xa8]
  7be199: 8b 95 54 ff ff ff            	mov	edx, dword ptr [ebp - 0xac]
  7be19f: 8b b5 64 ff ff ff            	mov	esi, dword ptr [ebp - 0x9c]
  7be1a5: 8d 5f 04                     	lea	ebx, [edi + 0x4]
  7be1a8: 33 c0                        	xor	eax, eax
  7be1aa: 88 03                        	mov	byte ptr [ebx], al
  7be1ac: 89 4f 04                     	mov	dword ptr [edi + 0x4], ecx
  7be1af: 89 57 18                     	mov	dword ptr [edi + 0x18], edx
  7be1b2: 89 77 14                     	mov	dword ptr [edi + 0x14], esi
  7be1b5: 83 fa 10                     	cmp	edx, 0x10
  7be1b8: 0f 43 d9                     	cmovae	ebx, ecx
  7be1bb: 88 04 33                     	mov	byte ptr [ebx + esi], al
  7be1be: 8d 9d 7c ff ff ff            	lea	ebx, [ebp - 0x84]
  7be1c4: e9 3b fa ff ff               	jmp	0x7bdc04 <.text+0x3bcc04>
  7be1c9: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
  7be1cc: c7 45 fc 02 00 00 00         	mov	dword ptr [ebp - 0x4], 0x2
  7be1d3: 8b 85 60 ff ff ff            	mov	eax, dword ptr [ebp - 0xa0]
  7be1d9: 8b 8d 5c ff ff ff            	mov	ecx, dword ptr [ebp - 0xa4]
  7be1df: 89 85 54 ff ff ff            	mov	dword ptr [ebp - 0xac], eax
  7be1e5: 40                           	inc	eax
  7be1e6: 50                           	push	eax
  7be1e7: ff 15 d8 53 c2 00            	call	dword ptr [0xc253d8]
  7be1ed: c7 45 fc 01 00 00 00         	mov	dword ptr [ebp - 0x4], 0x1
  7be1f4: 89 85 58 ff ff ff            	mov	dword ptr [ebp - 0xa8], eax
  7be1fa: b8 72 e1 7b 00               	mov	eax, 0x7be172
  7be1ff: c3                           	ret
  7be200: ff 77 04                     	push	dword ptr [edi + 0x4]
  7be203: e8 8a 0d 2d 00               	call	0xa8ef92 <.text+0x68df92>
  7be208: 59                           	pop	ecx
  7be209: 8b bd 5c ff ff ff            	mov	edi, dword ptr [ebp - 0xa4]
  7be20f: eb 82                        	jmp	0x7be193 <.text+0x3bd193>
  7be211: 8b 95 5c ff ff ff            	mov	edx, dword ptr [ebp - 0xa4]
  7be217: 83 7a 18 10                  	cmp	dword ptr [edx + 0x18], 0x10
  7be21b: 72 05                        	jb	0x7be222 <.text+0x3bd222>
  7be21d: 8b 52 04                     	mov	edx, dword ptr [edx + 0x4]
  7be220: eb 03                        	jmp	0x7be225 <.text+0x3bd225>
  7be222: 83 c2 04                     	add	edx, 0x4
  7be225: 8b 8d 54 ff ff ff            	mov	ecx, dword ptr [ebp - 0xac]
  7be22b: 50                           	push	eax
  7be22c: 52                           	push	edx
  7be22d: 41                           	inc	ecx
  7be22e: 51                           	push	ecx
  7be22f: ff b5 58 ff ff ff            	push	dword ptr [ebp - 0xa8]
  7be235: ff 15 00 56 c2 00            	call	dword ptr [0xc25600]
  7be23b: 83 c4 10                     	add	esp, 0x10
  7be23e: e9 44 ff ff ff               	jmp	0x7be187 <.text+0x3bd187>
  7be243: 83 fe 10                     	cmp	esi, 0x10
  7be246: 8b c1                        	mov	eax, ecx
  7be248: 0f 43 45 80                  	cmovae	eax, dword ptr [ebp - 0x80]
  7be24c: 03 45 90                     	add	eax, dword ptr [ebp - 0x70]
  7be24f: 3b c2                        	cmp	eax, edx
  7be251: 0f 86 7d f9 ff ff            	jbe	0x7bdbd4 <.text+0x3bcbd4>
  7be257: b8 01 00 00 00               	mov	eax, 0x1
  7be25c: e9 75 f9 ff ff               	jmp	0x7bdbd6 <.text+0x3bcbd6>
  7be261: 89 01                        	mov	dword ptr [ecx], eax
  7be263: e9 bb fa ff ff               	jmp	0x7bdd23 <.text+0x3bcd23>
  7be268: 89 57 04                     	mov	dword ptr [edi + 0x4], edx
  7be26b: e9 59 fb ff ff               	jmp	0x7bddc9 <.text+0x3bcdc9>
  7be270: 8b bd 60 ff ff ff            	mov	edi, dword ptr [ebp - 0xa0]
  7be276: 89 77 04                     	mov	dword ptr [edi + 0x4], esi
  7be279: e9 2b fb ff ff               	jmp	0x7bdda9 <.text+0x3bcda9>
  7be27e: 8b 7a 08                     	mov	edi, dword ptr [edx + 0x8]
  7be281: 8b ce                        	mov	ecx, esi
  7be283: 89 3e                        	mov	dword ptr [esi], edi
  7be285: 8b 7a 08                     	mov	edi, dword ptr [edx + 0x8]
  7be288: 89 bd 58 ff ff ff            	mov	dword ptr [ebp - 0xa8], edi
  7be28e: 0f be 7f 11                  	movsx	edi, byte ptr [edi + 0x11]
  7be292: 85 ff                        	test	edi, edi
  7be294: 74 32                        	je	0x7be2c8 <.text+0x3bd2c8>
  7be296: 8b bd 64 ff ff ff            	mov	edi, dword ptr [ebp - 0x9c]
  7be29c: 89 7a 04                     	mov	dword ptr [edx + 0x4], edi
  7be29f: 8b 7b 04                     	mov	edi, dword ptr [ebx + 0x4]
  7be2a2: 3b 77 04                     	cmp	esi, dword ptr [edi + 0x4]
  7be2a5: 74 1c                        	je	0x7be2c3 <.text+0x3bd2c3>
  7be2a7: 8b 7e 04                     	mov	edi, dword ptr [esi + 0x4]
  7be2aa: 3b 77 08                     	cmp	esi, dword ptr [edi + 0x8]
  7be2ad: 74 04                        	je	0x7be2b3 <.text+0x3bd2b3>
  7be2af: 89 17                        	mov	dword ptr [edi], edx
  7be2b1: eb 03                        	jmp	0x7be2b6 <.text+0x3bd2b6>
  7be2b3: 89 57 08                     	mov	dword ptr [edi + 0x8], edx
  7be2b6: 89 72 08                     	mov	dword ptr [edx + 0x8], esi
  7be2b9: 8b f2                        	mov	esi, edx
  7be2bb: 89 51 04                     	mov	dword ptr [ecx + 0x4], edx
  7be2be: e9 b6 fa ff ff               	jmp	0x7bdd79 <.text+0x3bcd79>
  7be2c3: 89 57 04                     	mov	dword ptr [edi + 0x4], edx
  7be2c6: eb ee                        	jmp	0x7be2b6 <.text+0x3bd2b6>
  7be2c8: 8b bd 58 ff ff ff            	mov	edi, dword ptr [ebp - 0xa8]
  7be2ce: 89 77 04                     	mov	dword ptr [edi + 0x4], esi
  7be2d1: 8b 7e 04                     	mov	edi, dword ptr [esi + 0x4]
  7be2d4: 89 bd 64 ff ff ff            	mov	dword ptr [ebp - 0x9c], edi
  7be2da: eb ba                        	jmp	0x7be296 <.text+0x3bd296>
  7be2dc: 8b 7a 08                     	mov	edi, dword ptr [edx + 0x8]
  7be2df: 0f be 57 10                  	movsx	edx, byte ptr [edi + 0x10]
  7be2e3: 85 d2                        	test	edx, edx
  7be2e5: 75 22                        	jne	0x7be309 <.text+0x3bd309>
  7be2e7: ba 01 00 00 00               	mov	edx, 0x1
  7be2ec: 88 56 10                     	mov	byte ptr [esi + 0x10], dl
  7be2ef: 8b f7                        	mov	esi, edi
  7be2f1: 88 56 10                     	mov	byte ptr [esi + 0x10], dl
  7be2f4: 8b 79 04                     	mov	edi, dword ptr [ecx + 0x4]
  7be2f7: 8b 57 04                     	mov	edx, dword ptr [edi + 0x4]
  7be2fa: c6 42 10 00                  	mov	byte ptr [edx + 0x10], 0x0
  7be2fe: 8b 49 04                     	mov	ecx, dword ptr [ecx + 0x4]
  7be301: 8b 49 04                     	mov	ecx, dword ptr [ecx + 0x4]
  7be304: e9 c5 fa ff ff               	jmp	0x7bddce <.text+0x3bcdce>
  7be309: 8b 56 08                     	mov	edx, dword ptr [esi + 0x8]
  7be30c: 3b ca                        	cmp	ecx, edx
  7be30e: 74 64                        	je	0x7be374 <.text+0x3bd374>
  7be310: c6 46 10 01                  	mov	byte ptr [esi + 0x10], 0x1
  7be314: 8b 51 04                     	mov	edx, dword ptr [ecx + 0x4]
  7be317: 8b 72 04                     	mov	esi, dword ptr [edx + 0x4]
  7be31a: c6 46 10 00                  	mov	byte ptr [esi + 0x10], 0x0
  7be31e: 8b 79 04                     	mov	edi, dword ptr [ecx + 0x4]
  7be321: 8b 77 04                     	mov	esi, dword ptr [edi + 0x4]
  7be324: 8b 16                        	mov	edx, dword ptr [esi]
  7be326: 8b 7a 08                     	mov	edi, dword ptr [edx + 0x8]
  7be329: 89 3e                        	mov	dword ptr [esi], edi
  7be32b: 8b 7a 08                     	mov	edi, dword ptr [edx + 0x8]
  7be32e: 89 bd 5c ff ff ff            	mov	dword ptr [ebp - 0xa4], edi
  7be334: 0f be 7f 11                  	movsx	edi, byte ptr [edi + 0x11]
  7be338: 85 ff                        	test	edi, edi
  7be33a: 74 2d                        	je	0x7be369 <.text+0x3bd369>
  7be33c: 8b 7e 04                     	mov	edi, dword ptr [esi + 0x4]
  7be33f: 89 7a 04                     	mov	dword ptr [edx + 0x4], edi
  7be342: 8b 7b 04                     	mov	edi, dword ptr [ebx + 0x4]
  7be345: 3b 77 04                     	cmp	esi, dword ptr [edi + 0x4]
  7be348: 74 1a                        	je	0x7be364 <.text+0x3bd364>
  7be34a: 8b 7e 04                     	mov	edi, dword ptr [esi + 0x4]
  7be34d: 3b 77 08                     	cmp	esi, dword ptr [edi + 0x8]
  7be350: 74 04                        	je	0x7be356 <.text+0x3bd356>
  7be352: 89 17                        	mov	dword ptr [edi], edx
  7be354: eb 03                        	jmp	0x7be359 <.text+0x3bd359>
  7be356: 89 57 08                     	mov	dword ptr [edi + 0x8], edx
  7be359: 89 72 08                     	mov	dword ptr [edx + 0x8], esi
  7be35c: 89 56 04                     	mov	dword ptr [esi + 0x4], edx
  7be35f: e9 6a fa ff ff               	jmp	0x7bddce <.text+0x3bcdce>
  7be364: 89 57 04                     	mov	dword ptr [edi + 0x4], edx
  7be367: eb f0                        	jmp	0x7be359 <.text+0x3bd359>
  7be369: 8b bd 5c ff ff ff            	mov	edi, dword ptr [ebp - 0xa4]
  7be36f: 89 77 04                     	mov	dword ptr [edi + 0x4], esi
  7be372: eb c8                        	jmp	0x7be33c <.text+0x3bd33c>
  7be374: 8b 3a                        	mov	edi, dword ptr [edx]
  7be376: 8b ce                        	mov	ecx, esi
  7be378: 89 7e 08                     	mov	dword ptr [esi + 0x8], edi
  7be37b: 8b 3a                        	mov	edi, dword ptr [edx]
  7be37d: 89 bd 54 ff ff ff            	mov	dword ptr [ebp - 0xac], edi
  7be383: 0f be 7f 11                  	movsx	edi, byte ptr [edi + 0x11]
  7be387: 85 ff                        	test	edi, edi
  7be389: 74 30                        	je	0x7be3bb <.text+0x3bd3bb>
  7be38b: 8b bd 64 ff ff ff            	mov	edi, dword ptr [ebp - 0x9c]
  7be391: 89 7a 04                     	mov	dword ptr [edx + 0x4], edi
  7be394: 8b 7b 04                     	mov	edi, dword ptr [ebx + 0x4]
  7be397: 3b 77 04                     	cmp	esi, dword ptr [edi + 0x4]
  7be39a: 74 1a                        	je	0x7be3b6 <.text+0x3bd3b6>
  7be39c: 8b 7e 04                     	mov	edi, dword ptr [esi + 0x4]
  7be39f: 3b 37                        	cmp	esi, dword ptr [edi]
  7be3a1: 74 05                        	je	0x7be3a8 <.text+0x3bd3a8>
  7be3a3: 89 57 08                     	mov	dword ptr [edi + 0x8], edx
  7be3a6: eb 02                        	jmp	0x7be3aa <.text+0x3bd3aa>
  7be3a8: 89 17                        	mov	dword ptr [edi], edx
  7be3aa: 89 32                        	mov	dword ptr [edx], esi
  7be3ac: 8b f2                        	mov	esi, edx
  7be3ae: 89 51 04                     	mov	dword ptr [ecx + 0x4], edx
  7be3b1: e9 5a ff ff ff               	jmp	0x7be310 <.text+0x3bd310>
  7be3b6: 89 57 04                     	mov	dword ptr [edi + 0x4], edx
  7be3b9: eb ef                        	jmp	0x7be3aa <.text+0x3bd3aa>
  7be3bb: 8b bd 54 ff ff ff            	mov	edi, dword ptr [ebp - 0xac]
  7be3c1: 89 77 04                     	mov	dword ptr [edi + 0x4], esi
  7be3c4: 8b 7e 04                     	mov	edi, dword ptr [esi + 0x4]
  7be3c7: 89 bd 64 ff ff ff            	mov	dword ptr [ebp - 0x9c], edi
  7be3cd: eb bc                        	jmp	0x7be38b <.text+0x3bd38b>
  7be3cf: 89 41 08                     	mov	dword ptr [ecx + 0x8], eax
  7be3d2: e9 4c f9 ff ff               	jmp	0x7bdd23 <.text+0x3bcd23>
  7be3d7: 89 41 04                     	mov	dword ptr [ecx + 0x4], eax
  7be3da: 8b 53 04                     	mov	edx, dword ptr [ebx + 0x4]
  7be3dd: 89 02                        	mov	dword ptr [edx], eax
  7be3df: 8b 4b 04                     	mov	ecx, dword ptr [ebx + 0x4]
  7be3e2: 89 41 08                     	mov	dword ptr [ecx + 0x8], eax
  7be3e5: e9 39 f9 ff ff               	jmp	0x7bdd23 <.text+0x3bcd23>
  7be3ea: 90                           	nop
  7be3eb: 90                           	nop
  7be3ec: 90                           	nop
  7be3ed: 90                           	nop
  7be3ee: 90                           	nop
  7be3ef: 90                           	nop
  7be3f0: 83 ec 0c                     	sub	esp, 0xc
  7be3f3: 83 7c 24 10 00               	cmp	dword ptr [esp + 0x10], 0x0
  7be3f8: 75 08                        	jne	0x7be402 <.text+0x3bd402>
  7be3fa: 33 c0                        	xor	eax, eax
  7be3fc: 83 c4 0c                     	add	esp, 0xc
  7be3ff: c2 04 00                     	ret	0x4
  7be402: 8b 51 0c                     	mov	edx, dword ptr [ecx + 0xc]
  7be405: 8b 02                        	mov	eax, dword ptr [edx]
  7be407: 3b c2                        	cmp	eax, edx
  7be409: 0f 84 94 00 00 00            	je	0x7be4a3 <.text+0x3bd4a3>
  7be40f: 0f 84 b3 00 00 00            	je	0x7be4c8 <.text+0x3bd4c8>
  7be415: 89 74 24 08                  	mov	dword ptr [esp + 0x8], esi
  7be419: 8b 74 24 10                  	mov	esi, dword ptr [esp + 0x10]
  7be41d: 89 7c 24 04                  	mov	dword ptr [esp + 0x4], edi
  7be421: 8b f9                        	mov	edi, ecx
  7be423: 89 1c 24                     	mov	dword ptr [esp], ebx
  7be426: 8b d8                        	mov	ebx, eax
  7be428: 56                           	push	esi
  7be429: 8b 53 0c                     	mov	edx, dword ptr [ebx + 0xc]
  7be42c: 8b 4a 1c                     	mov	ecx, dword ptr [edx + 0x1c]
  7be42f: 8b 11                        	mov	edx, dword ptr [ecx]
  7be431: ff 12                        	call	dword ptr [edx]
  7be433: 0f b6 c0                     	movzx	eax, al
  7be436: 85 c0                        	test	eax, eax
  7be438: 75 71                        	jne	0x7be4ab <.text+0x3bd4ab>
  7be43a: 0f be 53 11                  	movsx	edx, byte ptr [ebx + 0x11]
  7be43e: 85 d2                        	test	edx, edx
  7be440: 0f 85 82 00 00 00            	jne	0x7be4c8 <.text+0x3bd4c8>
  7be446: 8b 43 08                     	mov	eax, dword ptr [ebx + 0x8]
  7be449: 0f be 50 11                  	movsx	edx, byte ptr [eax + 0x11]
  7be44d: 85 d2                        	test	edx, edx
  7be44f: 75 1a                        	jne	0x7be46b <.text+0x3bd46b>
  7be451: 8b 10                        	mov	edx, dword ptr [eax]
  7be453: 0f be 52 11                  	movsx	edx, byte ptr [edx + 0x11]
  7be457: 8b d8                        	mov	ebx, eax
  7be459: 85 d2                        	test	edx, edx
  7be45b: 75 36                        	jne	0x7be493 <.text+0x3bd493>
  7be45d: 8b 1b                        	mov	ebx, dword ptr [ebx]
  7be45f: 8b 13                        	mov	edx, dword ptr [ebx]
  7be461: 0f be 52 11                  	movsx	edx, byte ptr [edx + 0x11]
  7be465: 85 d2                        	test	edx, edx
  7be467: 74 f4                        	je	0x7be45d <.text+0x3bd45d>
  7be469: eb 28                        	jmp	0x7be493 <.text+0x3bd493>
  7be46b: 8b 43 04                     	mov	eax, dword ptr [ebx + 0x4]
  7be46e: 0f be 50 11                  	movsx	edx, byte ptr [eax + 0x11]
  7be472: 85 d2                        	test	edx, edx
  7be474: 75 12                        	jne	0x7be488 <.text+0x3bd488>
  7be476: 3b 58 08                     	cmp	ebx, dword ptr [eax + 0x8]
  7be479: 75 0d                        	jne	0x7be488 <.text+0x3bd488>
  7be47b: 8b d8                        	mov	ebx, eax
  7be47d: 8b 40 04                     	mov	eax, dword ptr [eax + 0x4]
  7be480: 0f be 50 11                  	movsx	edx, byte ptr [eax + 0x11]
  7be484: 85 d2                        	test	edx, edx
  7be486: 74 ee                        	je	0x7be476 <.text+0x3bd476>
  7be488: 8b f6                        	mov	esi, esi
  7be48a: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7be491: 8b d8                        	mov	ebx, eax
  7be493: 3b 5f 0c                     	cmp	ebx, dword ptr [edi + 0xc]
  7be496: 75 90                        	jne	0x7be428 <.text+0x3bd428>
  7be498: 8b 74 24 08                  	mov	esi, dword ptr [esp + 0x8]
  7be49c: 8b 7c 24 04                  	mov	edi, dword ptr [esp + 0x4]
  7be4a0: 8b 1c 24                     	mov	ebx, dword ptr [esp]
  7be4a3: 33 c0                        	xor	eax, eax
  7be4a5: 83 c4 0c                     	add	esp, 0xc
  7be4a8: c2 04 00                     	ret	0x4
  7be4ab: 8b 74 24 08                  	mov	esi, dword ptr [esp + 0x8]
  7be4af: 8b c3                        	mov	eax, ebx
  7be4b1: 8b 1c 24                     	mov	ebx, dword ptr [esp]
  7be4b4: 8b cf                        	mov	ecx, edi
  7be4b6: 3b 41 0c                     	cmp	eax, dword ptr [ecx + 0xc]
  7be4b9: 8b 7c 24 04                  	mov	edi, dword ptr [esp + 0x4]
  7be4bd: 74 09                        	je	0x7be4c8 <.text+0x3bd4c8>
  7be4bf: 8b 40 0c                     	mov	eax, dword ptr [eax + 0xc]
  7be4c2: 83 c4 0c                     	add	esp, 0xc
  7be4c5: c2 04 00                     	ret	0x4
  7be4c8: ff 15 1c 56 c2 00            	call	dword ptr [0xc2561c]
  7be4ce: 8b f6                        	mov	esi, esi
  7be4d0: 57                           	push	edi
  7be4d1: 56                           	push	esi
  7be4d2: 53                           	push	ebx
  7be4d3: 83 ec 10                     	sub	esp, 0x10
  7be4d6: 8b f1                        	mov	esi, ecx
  7be4d8: 0f b6 46 20                  	movzx	eax, byte ptr [esi + 0x20]
  7be4dc: 85 c0                        	test	eax, eax
  7be4de: 75 70                        	jne	0x7be550 <.text+0x3bd550>
  7be4e0: 8b 44 24 20                  	mov	eax, dword ptr [esp + 0x20]
  7be4e4: 50                           	push	eax
  7be4e5: 8b ce                        	mov	ecx, esi
  7be4e7: e8 04 ff ff ff               	call	0x7be3f0 <.text+0x3bd3f0>
  7be4ec: 8b d8                        	mov	ebx, eax
  7be4ee: 85 db                        	test	ebx, ebx
  7be4f0: 74 5e                        	je	0x7be550 <.text+0x3bd550>
  7be4f2: 83 c6 08                     	add	esi, 0x8
  7be4f5: 8b 4e 04                     	mov	ecx, dword ptr [esi + 0x4]
  7be4f8: 8b 41 04                     	mov	eax, dword ptr [ecx + 0x4]
  7be4fb: 0f be 78 11                  	movsx	edi, byte ptr [eax + 0x11]
  7be4ff: 8b d1                        	mov	edx, ecx
  7be501: 85 ff                        	test	edi, edi
  7be503: 75 16                        	jne	0x7be51b <.text+0x3bd51b>
  7be505: 3b 58 0c                     	cmp	ebx, dword ptr [eax + 0xc]
  7be508: 76 05                        	jbe	0x7be50f <.text+0x3bd50f>
  7be50a: 8b 40 08                     	mov	eax, dword ptr [eax + 0x8]
  7be50d: eb 04                        	jmp	0x7be513 <.text+0x3bd513>
  7be50f: 8b d0                        	mov	edx, eax
  7be511: 8b 00                        	mov	eax, dword ptr [eax]
  7be513: 0f be 78 11                  	movsx	edi, byte ptr [eax + 0x11]
  7be517: 85 ff                        	test	edi, edi
  7be519: 74 ea                        	je	0x7be505 <.text+0x3bd505>
  7be51b: 3b d1                        	cmp	edx, ecx
  7be51d: 75 09                        	jne	0x7be528 <.text+0x3bd528>
  7be51f: 89 34 24                     	mov	dword ptr [esp], esi
  7be522: 89 4c 24 04                  	mov	dword ptr [esp + 0x4], ecx
  7be526: eb 0c                        	jmp	0x7be534 <.text+0x3bd534>
  7be528: 3b 5a 0c                     	cmp	ebx, dword ptr [edx + 0xc]
  7be52b: 72 f2                        	jb	0x7be51f <.text+0x3bd51f>
  7be52d: 89 34 24                     	mov	dword ptr [esp], esi
  7be530: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  7be534: 8d 44 24 08                  	lea	eax, [esp + 0x8]
  7be538: ff 74 24 04                  	push	dword ptr [esp + 0x4]
  7be53c: 8b ce                        	mov	ecx, esi
  7be53e: ff 74 24 04                  	push	dword ptr [esp + 0x4]
  7be542: 50                           	push	eax
  7be543: e8 68 06 00 00               	call	0x7bebb0 <.text+0x3bdbb0>
  7be548: 6a 01                        	push	0x1
  7be54a: 8b 03                        	mov	eax, dword ptr [ebx]
  7be54c: 8b cb                        	mov	ecx, ebx
  7be54e: ff 10                        	call	dword ptr [eax]
  7be550: 0f b6 44 24 24               	movzx	eax, byte ptr [esp + 0x24]
  7be555: 85 c0                        	test	eax, eax
  7be557: 74 0b                        	je	0x7be564 <.text+0x3bd564>
  7be559: 8b 44 24 20                  	mov	eax, dword ptr [esp + 0x20]
  7be55d: 50                           	push	eax
  7be55e: e8 2f 0a 2d 00               	call	0xa8ef92 <.text+0x68df92>
  7be563: 59                           	pop	ecx
  7be564: 83 c4 10                     	add	esp, 0x10
  7be567: 5b                           	pop	ebx
  7be568: 5e                           	pop	esi
  7be569: 5f                           	pop	edi
  7be56a: c2 08 00                     	ret	0x8
  7be56d: 8d 76 00                     	lea	esi, [esi]
  7be570: 57                           	push	edi
  7be571: 56                           	push	esi
  7be572: 55                           	push	ebp
  7be573: 53                           	push	ebx
  7be574: 83 ec 14                     	sub	esp, 0x14
  7be577: 8b d9                        	mov	ebx, ecx
  7be579: 8b 6c 24 28                  	mov	ebp, dword ptr [esp + 0x28]
  7be57d: 55                           	push	ebp
  7be57e: e8 6d fe ff ff               	call	0x7be3f0 <.text+0x3bd3f0>
  7be583: 89 44 24 10                  	mov	dword ptr [esp + 0x10], eax
  7be587: 85 c0                        	test	eax, eax
  7be589: 0f 84 f0 00 00 00            	je	0x7be67f <.text+0x3bd67f>
  7be58f: 83 c3 14                     	add	ebx, 0x14
  7be592: 8b 53 04                     	mov	edx, dword ptr [ebx + 0x4]
  7be595: 8b 7a 04                     	mov	edi, dword ptr [edx + 0x4]
  7be598: 0f be 77 11                  	movsx	esi, byte ptr [edi + 0x11]
  7be59c: 8b ca                        	mov	ecx, edx
  7be59e: 85 f6                        	test	esi, esi
  7be5a0: 74 07                        	je	0x7be5a9 <.text+0x3bd5a9>
  7be5a2: be 01 00 00 00               	mov	esi, 0x1
  7be5a7: eb 1f                        	jmp	0x7be5c8 <.text+0x3bd5c8>
  7be5a9: 33 f6                        	xor	esi, esi
  7be5ab: 3b 47 0c                     	cmp	eax, dword ptr [edi + 0xc]
  7be5ae: 8b cf                        	mov	ecx, edi
  7be5b0: 83 d6 00                     	adc	esi, 0x0
  7be5b3: 74 04                        	je	0x7be5b9 <.text+0x3bd5b9>
  7be5b5: 8b 3f                        	mov	edi, dword ptr [edi]
  7be5b7: eb 03                        	jmp	0x7be5bc <.text+0x3bd5bc>
  7be5b9: 8b 7f 08                     	mov	edi, dword ptr [edi + 0x8]
  7be5bc: 0f be 6f 11                  	movsx	ebp, byte ptr [edi + 0x11]
  7be5c0: 85 ed                        	test	ebp, ebp
  7be5c2: 74 e5                        	je	0x7be5a9 <.text+0x3bd5a9>
  7be5c4: 8b 6c 24 28                  	mov	ebp, dword ptr [esp + 0x28]
  7be5c8: 8b f9                        	mov	edi, ecx
  7be5ca: 85 f6                        	test	esi, esi
  7be5cc: 0f 84 95 00 00 00            	je	0x7be667 <.text+0x3bd667>
  7be5d2: 3b 0a                        	cmp	ecx, dword ptr [edx]
  7be5d4: 75 18                        	jne	0x7be5ee <.text+0x3bd5ee>
  7be5d6: 8d 14 24                     	lea	edx, [esp]
  7be5d9: 8d 44 24 10                  	lea	eax, [esp + 0x10]
  7be5dd: 50                           	push	eax
  7be5de: 51                           	push	ecx
  7be5df: 6a 01                        	push	0x1
  7be5e1: 52                           	push	edx
  7be5e2: 8b cb                        	mov	ecx, ebx
  7be5e4: e8 67 f5 ff ff               	call	0x7bdb50 <.text+0x3bcb50>
  7be5e9: e9 91 00 00 00               	jmp	0x7be67f <.text+0x3bd67f>
  7be5ee: 0f be 51 11                  	movsx	edx, byte ptr [ecx + 0x11]
  7be5f2: 85 d2                        	test	edx, edx
  7be5f4: 74 11                        	je	0x7be607 <.text+0x3bd607>
  7be5f6: 8b 79 08                     	mov	edi, dword ptr [ecx + 0x8]
  7be5f9: 0f be 57 11                  	movsx	edx, byte ptr [edi + 0x11]
  7be5fd: 85 d2                        	test	edx, edx
  7be5ff: 0f 85 94 00 00 00            	jne	0x7be699 <.text+0x3bd699>
  7be605: eb 60                        	jmp	0x7be667 <.text+0x3bd667>
  7be607: 8b 11                        	mov	edx, dword ptr [ecx]
  7be609: 89 14 24                     	mov	dword ptr [esp], edx
  7be60c: 0f be 52 11                  	movsx	edx, byte ptr [edx + 0x11]
  7be610: 85 d2                        	test	edx, edx
  7be612: 75 1e                        	jne	0x7be632 <.text+0x3bd632>
  7be614: 8b 3c 24                     	mov	edi, dword ptr [esp]
  7be617: 8b 57 08                     	mov	edx, dword ptr [edi + 0x8]
  7be61a: 0f be 52 11                  	movsx	edx, byte ptr [edx + 0x11]
  7be61e: 85 d2                        	test	edx, edx
  7be620: 75 45                        	jne	0x7be667 <.text+0x3bd667>
  7be622: 8b 7f 08                     	mov	edi, dword ptr [edi + 0x8]
  7be625: 8b 57 08                     	mov	edx, dword ptr [edi + 0x8]
  7be628: 0f be 52 11                  	movsx	edx, byte ptr [edx + 0x11]
  7be62c: 85 d2                        	test	edx, edx
  7be62e: 74 f2                        	je	0x7be622 <.text+0x3bd622>
  7be630: eb 35                        	jmp	0x7be667 <.text+0x3bd667>
  7be632: 8b 51 04                     	mov	edx, dword ptr [ecx + 0x4]
  7be635: 89 14 24                     	mov	dword ptr [esp], edx
  7be638: 0f be 52 11                  	movsx	edx, byte ptr [edx + 0x11]
  7be63c: 85 d2                        	test	edx, edx
  7be63e: 75 1c                        	jne	0x7be65c <.text+0x3bd65c>
  7be640: 8b 2c 24                     	mov	ebp, dword ptr [esp]
  7be643: 3b 7d 00                     	cmp	edi, dword ptr [ebp]
  7be646: 75 0d                        	jne	0x7be655 <.text+0x3bd655>
  7be648: 8b fd                        	mov	edi, ebp
  7be64a: 8b 6d 04                     	mov	ebp, dword ptr [ebp + 0x4]
  7be64d: 0f be 55 11                  	movsx	edx, byte ptr [ebp + 0x11]
  7be651: 85 d2                        	test	edx, edx
  7be653: 74 ee                        	je	0x7be643 <.text+0x3bd643>
  7be655: 89 2c 24                     	mov	dword ptr [esp], ebp
  7be658: 8b 6c 24 28                  	mov	ebp, dword ptr [esp + 0x28]
  7be65c: 0f be 57 11                  	movsx	edx, byte ptr [edi + 0x11]
  7be660: 85 d2                        	test	edx, edx
  7be662: 75 35                        	jne	0x7be699 <.text+0x3bd699>
  7be664: 8b 3c 24                     	mov	edi, dword ptr [esp]
  7be667: 3b 47 0c                     	cmp	eax, dword ptr [edi + 0xc]
  7be66a: 76 13                        	jbe	0x7be67f <.text+0x3bd67f>
  7be66c: 8d 54 24 08                  	lea	edx, [esp + 0x8]
  7be670: 8d 44 24 10                  	lea	eax, [esp + 0x10]
  7be674: 50                           	push	eax
  7be675: 51                           	push	ecx
  7be676: 56                           	push	esi
  7be677: 52                           	push	edx
  7be678: 8b cb                        	mov	ecx, ebx
  7be67a: e8 d1 f4 ff ff               	call	0x7bdb50 <.text+0x3bcb50>
  7be67f: 0f b6 44 24 2c               	movzx	eax, byte ptr [esp + 0x2c]
  7be684: 85 c0                        	test	eax, eax
  7be686: 74 07                        	je	0x7be68f <.text+0x3bd68f>
  7be688: 55                           	push	ebp
  7be689: e8 04 09 2d 00               	call	0xa8ef92 <.text+0x68df92>
  7be68e: 59                           	pop	ecx
  7be68f: 83 c4 14                     	add	esp, 0x14
  7be692: 5b                           	pop	ebx
  7be693: 5d                           	pop	ebp
  7be694: 5e                           	pop	esi
  7be695: 5f                           	pop	edi
  7be696: c2 08 00                     	ret	0x8
  7be699: ff 15 1c 56 c2 00            	call	dword ptr [0xc2561c]
  7be69f: 90                           	nop
  7be6a0: 57                           	push	edi
  7be6a1: 56                           	push	esi
  7be6a2: 55                           	push	ebp
  7be6a3: 53                           	push	ebx
  7be6a4: 83 ec 30                     	sub	esp, 0x30
  7be6a7: f2 0f 10 44 24 44            	movsd	xmm0, qword ptr [esp + 0x44]
  7be6ad: f2 0f 11 01                  	movsd	qword ptr [ecx], xmm0
  7be6b1: b8 01 00 00 00               	mov	eax, 0x1
  7be6b6: 88 41 20                     	mov	byte ptr [ecx + 0x20], al
  7be6b9: 8d 71 08                     	lea	esi, [ecx + 0x8]
  7be6bc: 8b 5e 08                     	mov	ebx, dword ptr [esi + 0x8]
  7be6bf: 85 db                        	test	ebx, ebx
  7be6c1: 0f 45 d8                     	cmovne	ebx, eax
  7be6c4: 8b 46 04                     	mov	eax, dword ptr [esi + 0x4]
  7be6c7: 8b 28                        	mov	ebp, dword ptr [eax]
  7be6c9: 3b e8                        	cmp	ebp, eax
  7be6cb: 0f 84 84 00 00 00            	je	0x7be755 <.text+0x3bd755>
  7be6d1: 0f 84 42 02 00 00            	je	0x7be919 <.text+0x3bd919>
  7be6d7: 8b f9                        	mov	edi, ecx
  7be6d9: 8b 4d 0c                     	mov	ecx, dword ptr [ebp + 0xc]
  7be6dc: 85 c9                        	test	ecx, ecx
  7be6de: 74 13                        	je	0x7be6f3 <.text+0x3bd6f3>
  7be6e0: 8b 01                        	mov	eax, dword ptr [ecx]
  7be6e2: 83 c4 f8                     	add	esp, -0x8
  7be6e5: f2 0f 10 44 24 4c            	movsd	xmm0, qword ptr [esp + 0x4c]
  7be6eb: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  7be6f0: ff 50 04                     	call	dword ptr [eax + 0x4]
  7be6f3: 0f be 45 11                  	movsx	eax, byte ptr [ebp + 0x11]
  7be6f7: 85 c0                        	test	eax, eax
  7be6f9: 0f 85 1a 02 00 00            	jne	0x7be919 <.text+0x3bd919>
  7be6ff: 8b 55 08                     	mov	edx, dword ptr [ebp + 0x8]
  7be702: 0f be 42 11                  	movsx	eax, byte ptr [edx + 0x11]
  7be706: 85 c0                        	test	eax, eax
  7be708: 75 1c                        	jne	0x7be726 <.text+0x3bd726>
  7be70a: 8b 02                        	mov	eax, dword ptr [edx]
  7be70c: 8b ea                        	mov	ebp, edx
  7be70e: 0f be 50 11                  	movsx	edx, byte ptr [eax + 0x11]
  7be712: 85 d2                        	test	edx, edx
  7be714: 75 38                        	jne	0x7be74e <.text+0x3bd74e>
  7be716: 8b 6d 00                     	mov	ebp, dword ptr [ebp]
  7be719: 8b 45 00                     	mov	eax, dword ptr [ebp]
  7be71c: 0f be 50 11                  	movsx	edx, byte ptr [eax + 0x11]
  7be720: 85 d2                        	test	edx, edx
  7be722: 74 f2                        	je	0x7be716 <.text+0x3bd716>
  7be724: eb 28                        	jmp	0x7be74e <.text+0x3bd74e>
  7be726: 8b 45 04                     	mov	eax, dword ptr [ebp + 0x4]
  7be729: 0f be 50 11                  	movsx	edx, byte ptr [eax + 0x11]
  7be72d: 85 d2                        	test	edx, edx
  7be72f: 75 12                        	jne	0x7be743 <.text+0x3bd743>
  7be731: 3b 68 08                     	cmp	ebp, dword ptr [eax + 0x8]
  7be734: 75 0d                        	jne	0x7be743 <.text+0x3bd743>
  7be736: 8b e8                        	mov	ebp, eax
  7be738: 8b 40 04                     	mov	eax, dword ptr [eax + 0x4]
  7be73b: 0f be 50 11                  	movsx	edx, byte ptr [eax + 0x11]
  7be73f: 85 d2                        	test	edx, edx
  7be741: 74 ee                        	je	0x7be731 <.text+0x3bd731>
  7be743: 8b f6                        	mov	esi, esi
  7be745: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7be74c: 8b e8                        	mov	ebp, eax
  7be74e: 3b 6e 04                     	cmp	ebp, dword ptr [esi + 0x4]
  7be751: 75 86                        	jne	0x7be6d9 <.text+0x3bd6d9>
  7be753: 8b cf                        	mov	ecx, edi
  7be755: 8d 69 14                     	lea	ebp, [ecx + 0x14]
  7be758: 8b 45 04                     	mov	eax, dword ptr [ebp + 0x4]
  7be75b: 8b 38                        	mov	edi, dword ptr [eax]
  7be75d: 3b f8                        	cmp	edi, eax
  7be75f: 0f 84 e5 00 00 00            	je	0x7be84a <.text+0x3bd84a>
  7be765: 0f 84 ae 01 00 00            	je	0x7be919 <.text+0x3bd919>
  7be76b: 89 6c 24 2c                  	mov	dword ptr [esp + 0x2c], ebp
  7be76f: 89 5c 24 14                  	mov	dword ptr [esp + 0x14], ebx
  7be773: 89 74 24 28                  	mov	dword ptr [esp + 0x28], esi
  7be777: 89 4c 24 24                  	mov	dword ptr [esp + 0x24], ecx
  7be77b: 8b 44 24 28                  	mov	eax, dword ptr [esp + 0x28]
  7be77f: 8b 40 04                     	mov	eax, dword ptr [eax + 0x4]
  7be782: 8b 50 04                     	mov	edx, dword ptr [eax + 0x4]
  7be785: 0f be 6a 11                  	movsx	ebp, byte ptr [edx + 0x11]
  7be789: 8b d8                        	mov	ebx, eax
  7be78b: 8b cb                        	mov	ecx, ebx
  7be78d: 85 ed                        	test	ebp, ebp
  7be78f: 75 33                        	jne	0x7be7c4 <.text+0x3bd7c4>
  7be791: 8b 77 0c                     	mov	esi, dword ptr [edi + 0xc]
  7be794: 89 74 24 20                  	mov	dword ptr [esp + 0x20], esi
  7be798: 8b f2                        	mov	esi, edx
  7be79a: 89 54 24 1c                  	mov	dword ptr [esp + 0x1c], edx
  7be79e: 8b 54 24 20                  	mov	edx, dword ptr [esp + 0x20]
  7be7a2: 89 44 24 18                  	mov	dword ptr [esp + 0x18], eax
  7be7a6: 3b 56 0c                     	cmp	edx, dword ptr [esi + 0xc]
  7be7a9: 76 05                        	jbe	0x7be7b0 <.text+0x3bd7b0>
  7be7ab: 8b 76 08                     	mov	esi, dword ptr [esi + 0x8]
  7be7ae: eb 04                        	jmp	0x7be7b4 <.text+0x3bd7b4>
  7be7b0: 8b de                        	mov	ebx, esi
  7be7b2: 8b 36                        	mov	esi, dword ptr [esi]
  7be7b4: 0f be 46 11                  	movsx	eax, byte ptr [esi + 0x11]
  7be7b8: 85 c0                        	test	eax, eax
  7be7ba: 74 ea                        	je	0x7be7a6 <.text+0x3bd7a6>
  7be7bc: 8b 54 24 1c                  	mov	edx, dword ptr [esp + 0x1c]
  7be7c0: 8b 44 24 18                  	mov	eax, dword ptr [esp + 0x18]
  7be7c4: 3b d8                        	cmp	ebx, eax
  7be7c6: 75 04                        	jne	0x7be7cc <.text+0x3bd7cc>
  7be7c8: 8b d9                        	mov	ebx, ecx
  7be7ca: eb 08                        	jmp	0x7be7d4 <.text+0x3bd7d4>
  7be7cc: 8b 77 0c                     	mov	esi, dword ptr [edi + 0xc]
  7be7cf: 3b 73 0c                     	cmp	esi, dword ptr [ebx + 0xc]
  7be7d2: 72 f4                        	jb	0x7be7c8 <.text+0x3bd7c8>
  7be7d4: 3b d8                        	cmp	ebx, eax
  7be7d6: 0f 85 c5 00 00 00            	jne	0x7be8a1 <.text+0x3bd8a1>
  7be7dc: 0f be 47 11                  	movsx	eax, byte ptr [edi + 0x11]
  7be7e0: 85 c0                        	test	eax, eax
  7be7e2: 0f 85 31 01 00 00            	jne	0x7be919 <.text+0x3bd919>
  7be7e8: 8b 57 08                     	mov	edx, dword ptr [edi + 0x8]
  7be7eb: 0f be 42 11                  	movsx	eax, byte ptr [edx + 0x11]
  7be7ef: 85 c0                        	test	eax, eax
  7be7f1: 75 1a                        	jne	0x7be80d <.text+0x3bd80d>
  7be7f3: 8b 02                        	mov	eax, dword ptr [edx]
  7be7f5: 8b fa                        	mov	edi, edx
  7be7f7: 0f be 50 11                  	movsx	edx, byte ptr [eax + 0x11]
  7be7fb: 85 d2                        	test	edx, edx
  7be7fd: 75 30                        	jne	0x7be82f <.text+0x3bd82f>
  7be7ff: 8b 3f                        	mov	edi, dword ptr [edi]
  7be801: 8b 07                        	mov	eax, dword ptr [edi]
  7be803: 0f be 50 11                  	movsx	edx, byte ptr [eax + 0x11]
  7be807: 85 d2                        	test	edx, edx
  7be809: 74 f4                        	je	0x7be7ff <.text+0x3bd7ff>
  7be80b: eb 22                        	jmp	0x7be82f <.text+0x3bd82f>
  7be80d: 8b 47 04                     	mov	eax, dword ptr [edi + 0x4]
  7be810: 0f be 50 11                  	movsx	edx, byte ptr [eax + 0x11]
  7be814: 85 d2                        	test	edx, edx
  7be816: 75 12                        	jne	0x7be82a <.text+0x3bd82a>
  7be818: 3b 78 08                     	cmp	edi, dword ptr [eax + 0x8]
  7be81b: 75 0d                        	jne	0x7be82a <.text+0x3bd82a>
  7be81d: 8b f8                        	mov	edi, eax
  7be81f: 8b 40 04                     	mov	eax, dword ptr [eax + 0x4]
  7be822: 0f be 50 11                  	movsx	edx, byte ptr [eax + 0x11]
  7be826: 85 d2                        	test	edx, edx
  7be828: 74 ee                        	je	0x7be818 <.text+0x3bd818>
  7be82a: 8d 76 00                     	lea	esi, [esi]
  7be82d: 8b f8                        	mov	edi, eax
  7be82f: 8b 44 24 2c                  	mov	eax, dword ptr [esp + 0x2c]
  7be833: 8b 40 04                     	mov	eax, dword ptr [eax + 0x4]
  7be836: 3b f8                        	cmp	edi, eax
  7be838: 0f 85 3d ff ff ff            	jne	0x7be77b <.text+0x3bd77b>
  7be83e: 8b 6c 24 2c                  	mov	ebp, dword ptr [esp + 0x2c]
  7be842: 8b 5c 24 14                  	mov	ebx, dword ptr [esp + 0x14]
  7be846: 8b 4c 24 24                  	mov	ecx, dword ptr [esp + 0x24]
  7be84a: 8b 70 04                     	mov	esi, dword ptr [eax + 0x4]
  7be84d: 0f be 56 11                  	movsx	edx, byte ptr [esi + 0x11]
  7be851: 8b fe                        	mov	edi, esi
  7be853: 85 d2                        	test	edx, edx
  7be855: 75 28                        	jne	0x7be87f <.text+0x3bd87f>
  7be857: 89 4c 24 24                  	mov	dword ptr [esp + 0x24], ecx
  7be85b: ff 77 08                     	push	dword ptr [edi + 0x8]
  7be85e: 8b cd                        	mov	ecx, ebp
  7be860: e8 fb 02 00 00               	call	0x7beb60 <.text+0x3bdb60>
  7be865: 56                           	push	esi
  7be866: 8b 3f                        	mov	edi, dword ptr [edi]
  7be868: e8 25 07 2d 00               	call	0xa8ef92 <.text+0x68df92>
  7be86d: 59                           	pop	ecx
  7be86e: 0f be 47 11                  	movsx	eax, byte ptr [edi + 0x11]
  7be872: 8b f7                        	mov	esi, edi
  7be874: 85 c0                        	test	eax, eax
  7be876: 74 e3                        	je	0x7be85b <.text+0x3bd85b>
  7be878: 8b 4c 24 24                  	mov	ecx, dword ptr [esp + 0x24]
  7be87c: 8b 45 04                     	mov	eax, dword ptr [ebp + 0x4]
  7be87f: 89 40 04                     	mov	dword ptr [eax + 0x4], eax
  7be882: 8b 45 04                     	mov	eax, dword ptr [ebp + 0x4]
  7be885: 33 d2                        	xor	edx, edx
  7be887: 89 55 08                     	mov	dword ptr [ebp + 0x8], edx
  7be88a: 89 00                        	mov	dword ptr [eax], eax
  7be88c: 8b 6d 04                     	mov	ebp, dword ptr [ebp + 0x4]
  7be88f: 89 6d 08                     	mov	dword ptr [ebp + 0x8], ebp
  7be892: 88 51 20                     	mov	byte ptr [ecx + 0x20], dl
  7be895: 8b c3                        	mov	eax, ebx
  7be897: 83 c4 30                     	add	esp, 0x30
  7be89a: 5b                           	pop	ebx
  7be89b: 5d                           	pop	ebp
  7be89c: 5e                           	pop	esi
  7be89d: 5f                           	pop	edi
  7be89e: c2 08 00                     	ret	0x8
  7be8a1: 8b 5f 0c                     	mov	ebx, dword ptr [edi + 0xc]
  7be8a4: 89 5c 24 10                  	mov	dword ptr [esp + 0x10], ebx
  7be8a8: 85 ed                        	test	ebp, ebp
  7be8aa: 75 18                        	jne	0x7be8c4 <.text+0x3bd8c4>
  7be8ac: 8b eb                        	mov	ebp, ebx
  7be8ae: 3b 6a 0c                     	cmp	ebp, dword ptr [edx + 0xc]
  7be8b1: 76 05                        	jbe	0x7be8b8 <.text+0x3bd8b8>
  7be8b3: 8b 52 08                     	mov	edx, dword ptr [edx + 0x8]
  7be8b6: eb 04                        	jmp	0x7be8bc <.text+0x3bd8bc>
  7be8b8: 8b ca                        	mov	ecx, edx
  7be8ba: 8b 12                        	mov	edx, dword ptr [edx]
  7be8bc: 0f be 5a 11                  	movsx	ebx, byte ptr [edx + 0x11]
  7be8c0: 85 db                        	test	ebx, ebx
  7be8c2: 74 ea                        	je	0x7be8ae <.text+0x3bd8ae>
  7be8c4: 3b c8                        	cmp	ecx, eax
  7be8c6: 75 0d                        	jne	0x7be8d5 <.text+0x3bd8d5>
  7be8c8: 8b 54 24 28                  	mov	edx, dword ptr [esp + 0x28]
  7be8cc: 89 14 24                     	mov	dword ptr [esp], edx
  7be8cf: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  7be8d3: eb 14                        	jmp	0x7be8e9 <.text+0x3bd8e9>
  7be8d5: 8b 54 24 10                  	mov	edx, dword ptr [esp + 0x10]
  7be8d9: 3b 51 0c                     	cmp	edx, dword ptr [ecx + 0xc]
  7be8dc: 72 ea                        	jb	0x7be8c8 <.text+0x3bd8c8>
  7be8de: 8b 44 24 28                  	mov	eax, dword ptr [esp + 0x28]
  7be8e2: 89 04 24                     	mov	dword ptr [esp], eax
  7be8e5: 89 4c 24 04                  	mov	dword ptr [esp + 0x4], ecx
  7be8e9: 8d 44 24 08                  	lea	eax, [esp + 0x8]
  7be8ed: ff 74 24 04                  	push	dword ptr [esp + 0x4]
  7be8f1: ff 74 24 04                  	push	dword ptr [esp + 0x4]
  7be8f5: 50                           	push	eax
  7be8f6: 8b 4c 24 34                  	mov	ecx, dword ptr [esp + 0x34]
  7be8fa: e8 b1 02 00 00               	call	0x7bebb0 <.text+0x3bdbb0>
  7be8ff: 83 7c 24 10 00               	cmp	dword ptr [esp + 0x10], 0x0
  7be904: 0f 84 d2 fe ff ff            	je	0x7be7dc <.text+0x3bd7dc>
  7be90a: 8b 4c 24 10                  	mov	ecx, dword ptr [esp + 0x10]
  7be90e: 6a 01                        	push	0x1
  7be910: 8b 01                        	mov	eax, dword ptr [ecx]
  7be912: ff 10                        	call	dword ptr [eax]
  7be914: e9 c3 fe ff ff               	jmp	0x7be7dc <.text+0x3bd7dc>
  7be919: ff 15 1c 56 c2 00            	call	dword ptr [0xc2561c]
  7be91f: 90                           	nop
  7be920: dd 01                        	fld	qword ptr [ecx]
  7be922: c3                           	ret
  7be923: 8d b6 00 00 00 00            	lea	esi, [esi]
  7be929: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7be930: 57                           	push	edi
  7be931: 53                           	push	ebx
  7be932: 8b 7c 24 0c                  	mov	edi, dword ptr [esp + 0xc]
  7be936: 57                           	push	edi
  7be937: e8 b4 fa ff ff               	call	0x7be3f0 <.text+0x3bd3f0>
  7be93c: 8b d8                        	mov	ebx, eax
  7be93e: 57                           	push	edi
  7be93f: b8 01 00 00 00               	mov	eax, 0x1
  7be944: 85 db                        	test	ebx, ebx
  7be946: 0f 45 d8                     	cmovne	ebx, eax
  7be949: e8 44 06 2d 00               	call	0xa8ef92 <.text+0x68df92>
  7be94e: 8b c3                        	mov	eax, ebx
  7be950: 59                           	pop	ecx
  7be951: 5b                           	pop	ebx
  7be952: 5f                           	pop	edi
  7be953: c2 04 00                     	ret	0x4
  7be956: 8d 76 00                     	lea	esi, [esi]
  7be959: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7be960: ff 74 24 04                  	push	dword ptr [esp + 0x4]
  7be964: e8 87 fa ff ff               	call	0x7be3f0 <.text+0x3bd3f0>
  7be969: 85 c0                        	test	eax, eax
  7be96b: 74 07                        	je	0x7be974 <.text+0x3bd974>
  7be96d: 8b 10                        	mov	edx, dword ptr [eax]
  7be96f: 8b c8                        	mov	ecx, eax
  7be971: ff 52 08                     	call	dword ptr [edx + 0x8]
  7be974: c2 04 00                     	ret	0x4
  7be977: 8b f6                        	mov	esi, esi
  7be979: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7be980: 55                           	push	ebp
  7be981: 8b ec                        	mov	ebp, esp
  7be983: 6a ff                        	push	-0x1
  7be985: 68 e0 11 c1 00               	push	0xc111e0
  7be98a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  7be990: 50                           	push	eax
  7be991: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  7be998: 83 ec 18                     	sub	esp, 0x18
  7be99b: 89 5d e4                     	mov	dword ptr [ebp - 0x1c], ebx
  7be99e: 89 7d dc                     	mov	dword ptr [ebp - 0x24], edi
  7be9a1: 89 75 e0                     	mov	dword ptr [ebp - 0x20], esi
  7be9a4: 8b d9                        	mov	ebx, ecx
  7be9a6: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  7be9a9: c7 45 fc 01 00 00 00         	mov	dword ptr [ebp - 0x4], 0x1
  7be9b0: 8d 73 08                     	lea	esi, [ebx + 0x8]
  7be9b3: 8b 46 04                     	mov	eax, dword ptr [esi + 0x4]
  7be9b6: 8b 38                        	mov	edi, dword ptr [eax]
  7be9b8: 3b f8                        	cmp	edi, eax
  7be9ba: 0f 84 87 00 00 00            	je	0x7bea47 <.text+0x3bda47>
  7be9c0: 3b 7e 04                     	cmp	edi, dword ptr [esi + 0x4]
  7be9c3: 0f 84 76 01 00 00            	je	0x7beb3f <.text+0x3bdb3f>
  7be9c9: 8b 4f 0c                     	mov	ecx, dword ptr [edi + 0xc]
  7be9cc: 85 c9                        	test	ecx, ecx
  7be9ce: 74 0e                        	je	0x7be9de <.text+0x3bd9de>
