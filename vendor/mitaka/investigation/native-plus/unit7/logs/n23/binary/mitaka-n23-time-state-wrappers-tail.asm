
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  6681a0: 57                           	push	edi
  6681a1: 56                           	push	esi
  6681a2: 83 ec 10                     	sub	esp, 0x10
  6681a5: 8b 74 24 1c                  	mov	esi, dword ptr [esp + 0x1c]
  6681a9: 6a 00                        	push	0x0
  6681ab: 6a 01                        	push	0x1
  6681ad: 56                           	push	esi
  6681ae: e8 bd 72 22 00               	call	0x88f470 <.text+0x48e470>
  6681b3: 83 c4 0c                     	add	esp, 0xc
  6681b6: 8b f8                        	mov	edi, eax
  6681b8: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  6681c0: 89 34 24                     	mov	dword ptr [esp], esi
  6681c3: 66 0f ef c0                  	pxor	xmm0, xmm0
  6681c7: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6681cd: e8 1e 72 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6681d2: 83 c4 f8                     	add	esp, -0x8
  6681d5: dd 1c 24                     	fstp	qword ptr [esp]
  6681d8: 8b cf                        	mov	ecx, edi
  6681da: e8 31 42 f8 ff               	call	0x5ec410 <.text+0x1eb410>
  6681df: 33 c0                        	xor	eax, eax
  6681e1: 83 c4 10                     	add	esp, 0x10
  6681e4: 5e                           	pop	esi
  6681e5: 5f                           	pop	edi
  6681e6: c3                           	ret
  6681e7: 8b f6                        	mov	esi, esi
  6681e9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  6681f0: 53                           	push	ebx
  6681f1: 83 ec 0c                     	sub	esp, 0xc
  6681f4: 8b 5c 24 14                  	mov	ebx, dword ptr [esp + 0x14]
  6681f8: 6a 00                        	push	0x0
  6681fa: 6a 01                        	push	0x1
  6681fc: 53                           	push	ebx
  6681fd: e8 6e 72 22 00               	call	0x88f470 <.text+0x48e470>
  668202: 83 c4 0c                     	add	esp, 0xc
  668205: 8b c8                        	mov	ecx, eax
  668207: e8 24 42 f8 ff               	call	0x5ec430 <.text+0x1eb430>
  66820c: dd 5c 24 04                  	fstp	qword ptr [esp + 0x4]
  668210: 89 1c 24                     	mov	dword ptr [esp], ebx
  668213: e8 08 76 22 00               	call	0x88f820 <.text+0x48e820>
  668218: b8 01 00 00 00               	mov	eax, 0x1
  66821d: 83 c4 0c                     	add	esp, 0xc
  668220: 5b                           	pop	ebx
  668221: c3                           	ret
  668222: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  668229: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  668230: 56                           	push	esi
  668231: 55                           	push	ebp
  668232: 83 ec 18                     	sub	esp, 0x18
  668235: 8b 74 24 24                  	mov	esi, dword ptr [esp + 0x24]
  668239: 6a 00                        	push	0x0
  66823b: 6a 01                        	push	0x1
  66823d: 56                           	push	esi
  66823e: e8 2d 72 22 00               	call	0x88f470 <.text+0x48e470>
  668243: 83 c4 0c                     	add	esp, 0xc
  668246: 8b e8                        	mov	ebp, eax
  668248: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  668250: 89 34 24                     	mov	dword ptr [esp], esi
  668253: 66 0f ef c0                  	pxor	xmm0, xmm0
  668257: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  66825d: e8 8e 71 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  668262: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  668266: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  66826c: 8b cd                        	mov	ecx, ebp
  66826e: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  668272: 50                           	push	eax
  668273: e8 c8 41 f8 ff               	call	0x5ec440 <.text+0x1eb440>
  668278: 33 c0                        	xor	eax, eax
  66827a: 83 c4 18                     	add	esp, 0x18
  66827d: 5d                           	pop	ebp
  66827e: 5e                           	pop	esi
  66827f: c3                           	ret
  668280: 53                           	push	ebx
  668281: 83 ec 0c                     	sub	esp, 0xc
  668284: 8b 5c 24 14                  	mov	ebx, dword ptr [esp + 0x14]
  668288: 6a 00                        	push	0x0
  66828a: 6a 01                        	push	0x1
  66828c: 53                           	push	ebx
  66828d: e8 de 71 22 00               	call	0x88f470 <.text+0x48e470>
  668292: 83 c4 0c                     	add	esp, 0xc
  668295: 8b c8                        	mov	ecx, eax
  668297: e8 84 46 f8 ff               	call	0x5ec920 <.text+0x1eb920>
  66829c: f2 0f 2a c0                  	cvtsi2sd	xmm0, eax
  6682a0: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  6682a6: 89 1c 24                     	mov	dword ptr [esp], ebx
  6682a9: e8 72 75 22 00               	call	0x88f820 <.text+0x48e820>
  6682ae: b8 01 00 00 00               	mov	eax, 0x1
  6682b3: 83 c4 0c                     	add	esp, 0xc
  6682b6: 5b                           	pop	ebx
  6682b7: c3                           	ret
  6682b8: 90                           	nop
  6682b9: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  6682c0: 57                           	push	edi
  6682c1: 53                           	push	ebx
  6682c2: 8b 7c 24 0c                  	mov	edi, dword ptr [esp + 0xc]
  6682c6: 6a 00                        	push	0x0
  6682c8: 6a 01                        	push	0x1
  6682ca: 57                           	push	edi
  6682cb: e8 a0 71 22 00               	call	0x88f470 <.text+0x48e470>
  6682d0: 8b d8                        	mov	ebx, eax
  6682d2: 6a 00                        	push	0x0
  6682d4: 6a 02                        	push	0x2
  6682d6: 57                           	push	edi
  6682d7: e8 24 72 22 00               	call	0x88f500 <.text+0x48e500>
  6682dc: 83 c4 18                     	add	esp, 0x18
  6682df: ba 01 00 00 00               	mov	edx, 0x1
  6682e4: 85 c0                        	test	eax, eax
  6682e6: 0f 45 c2                     	cmovne	eax, edx
  6682e9: 8b cb                        	mov	ecx, ebx
  6682eb: 50                           	push	eax
  6682ec: e8 7f 46 f8 ff               	call	0x5ec970 <.text+0x1eb970>
  6682f1: 33 c0                        	xor	eax, eax
  6682f3: 5b                           	pop	ebx
  6682f4: 5f                           	pop	edi
  6682f5: c3                           	ret
  6682f6: 8d 76 00                     	lea	esi, [esi]
  6682f9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  668300: 53                           	push	ebx
  668301: 8b 5c 24 08                  	mov	ebx, dword ptr [esp + 0x8]
  668305: 6a 00                        	push	0x0
  668307: 6a 01                        	push	0x1
  668309: 53                           	push	ebx
  66830a: e8 61 71 22 00               	call	0x88f470 <.text+0x48e470>
  66830f: 83 c4 0c                     	add	esp, 0xc
  668312: 8b c8                        	mov	ecx, eax
  668314: e8 17 46 f8 ff               	call	0x5ec930 <.text+0x1eb930>
  668319: 0f b6 c0                     	movzx	eax, al
  66831c: 50                           	push	eax
  66831d: 53                           	push	ebx
  66831e: e8 ed 74 22 00               	call	0x88f810 <.text+0x48e810>
  668323: 83 c4 08                     	add	esp, 0x8
  668326: b8 01 00 00 00               	mov	eax, 0x1
  66832b: 5b                           	pop	ebx
  66832c: c3                           	ret
  66832d: 8d 76 00                     	lea	esi, [esi]
  668330: 6a 00                        	push	0x0
  668332: 6a 01                        	push	0x1
  668334: ff 74 24 0c                  	push	dword ptr [esp + 0xc]
  668338: e8 33 71 22 00               	call	0x88f470 <.text+0x48e470>
  66833d: 83 c4 0c                     	add	esp, 0xc
  668340: 8b c8                        	mov	ecx, eax
  668342: e8 f9 45 f8 ff               	call	0x5ec940 <.text+0x1eb940>
  668347: 33 c0                        	xor	eax, eax
  668349: c3                           	ret
  66834a: 8d b6 00 00 00 00            	lea	esi, [esi]
  668350: 57                           	push	edi
  668351: 53                           	push	ebx
  668352: 8b 7c 24 0c                  	mov	edi, dword ptr [esp + 0xc]
  668356: 6a 00                        	push	0x0
  668358: 6a 01                        	push	0x1
  66835a: 57                           	push	edi
  66835b: e8 10 71 22 00               	call	0x88f470 <.text+0x48e470>
  668360: 8b d8                        	mov	ebx, eax
  668362: 6a 00                        	push	0x0
  668364: 6a 02                        	push	0x2
  668366: 57                           	push	edi
  668367: e8 94 71 22 00               	call	0x88f500 <.text+0x48e500>
  66836c: 83 c4 18                     	add	esp, 0x18
  66836f: ba 01 00 00 00               	mov	edx, 0x1
  668374: 85 c0                        	test	eax, eax
  668376: 0f 45 c2                     	cmovne	eax, edx
  668379: 8b cb                        	mov	ecx, ebx
  66837b: 50                           	push	eax
  66837c: e8 df 4a f8 ff               	call	0x5ece60 <.text+0x1ebe60>
  668381: 33 c0                        	xor	eax, eax
  668383: 5b                           	pop	ebx
  668384: 5f                           	pop	edi
  668385: c3                           	ret
  668386: 8d 76 00                     	lea	esi, [esi]
  668389: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  668390: 53                           	push	ebx
  668391: 8b 5c 24 08                  	mov	ebx, dword ptr [esp + 0x8]
  668395: 6a 00                        	push	0x0
  668397: 6a 01                        	push	0x1
  668399: 53                           	push	ebx
  66839a: e8 d1 70 22 00               	call	0x88f470 <.text+0x48e470>
  66839f: 83 c4 0c                     	add	esp, 0xc
  6683a2: 8b c8                        	mov	ecx, eax
  6683a4: e8 d7 4a f8 ff               	call	0x5ece80 <.text+0x1ebe80>
  6683a9: 0f b6 c0                     	movzx	eax, al
  6683ac: 50                           	push	eax
  6683ad: 53                           	push	ebx
  6683ae: e8 5d 74 22 00               	call	0x88f810 <.text+0x48e810>
  6683b3: 83 c4 08                     	add	esp, 0x8
  6683b6: b8 01 00 00 00               	mov	eax, 0x1
  6683bb: 5b                           	pop	ebx
  6683bc: c3                           	ret
  6683bd: 8d 76 00                     	lea	esi, [esi]
  6683c0: 6a 00                        	push	0x0
  6683c2: 6a 01                        	push	0x1
  6683c4: ff 74 24 0c                  	push	dword ptr [esp + 0xc]
  6683c8: e8 a3 70 22 00               	call	0x88f470 <.text+0x48e470>
  6683cd: 83 c4 0c                     	add	esp, 0xc
  6683d0: 8b c8                        	mov	ecx, eax
  6683d2: e8 b9 4a f8 ff               	call	0x5ece90 <.text+0x1ebe90>
  6683d7: 33 c0                        	xor	eax, eax
  6683d9: c3                           	ret
  6683da: 8d b6 00 00 00 00            	lea	esi, [esi]
