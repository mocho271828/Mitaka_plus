
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  753730: 55                           	push	ebp
  753731: 8b ec                        	mov	ebp, esp
  753733: 6a ff                        	push	-0x1
  753735: 68 20 d2 c0 00               	push	0xc0d220
  75373a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  753740: 50                           	push	eax
  753741: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  753748: 83 ec 10                     	sub	esp, 0x10
  75374b: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  75374e: 89 7d e4                     	mov	dword ptr [ebp - 0x1c], edi
  753751: 89 75 e8                     	mov	dword ptr [ebp - 0x18], esi
  753754: 0f b6 05 20 59 19 01         	movzx	eax, byte ptr [0x1195920]
  75375b: a8 01                        	test	al, 0x1
  75375d: 75 2b                        	jne	0x75378a <.text+0x35278a>
  75375f: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  753766: 83 c8 01                     	or	eax, 0x1
  753769: a2 20 59 19 01               	mov	byte ptr [0x1195920], al
  75376e: b9 28 59 19 01               	mov	ecx, 0x1195928
  753773: e8 28 00 00 00               	call	0x7537a0 <.text+0x3527a0>
  753778: 68 10 37 75 00               	push	0x753710
  75377d: e8 f2 b7 33 00               	call	0xa8ef74 <.text+0x68df74>
  753782: 59                           	pop	ecx
  753783: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  75378a: b8 28 59 19 01               	mov	eax, 0x1195928
  75378f: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  753792: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  753799: 8b e5                        	mov	esp, ebp
  75379b: 5d                           	pop	ebp
  75379c: c3                           	ret
  75379d: 90                           	nop
  75379e: 90                           	nop
  75379f: 90                           	nop
  7537a0: 55                           	push	ebp
  7537a1: 8b ec                        	mov	ebp, esp
  7537a3: 6a ff                        	push	-0x1
  7537a5: 68 50 d2 c0 00               	push	0xc0d250
  7537aa: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  7537b0: 50                           	push	eax
  7537b1: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  7537b8: 83 ec 68                     	sub	esp, 0x68
  7537bb: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
  7537be: 89 5d e0                     	mov	dword ptr [ebp - 0x20], ebx
  7537c1: 89 7d d8                     	mov	dword ptr [ebp - 0x28], edi
  7537c4: 89 75 dc                     	mov	dword ptr [ebp - 0x24], esi
  7537c7: a1 10 53 d8 00               	mov	eax, dword ptr [0xd85310]
  7537cc: 89 4d d4                     	mov	dword ptr [ebp - 0x2c], ecx
  7537cf: 89 45 ec                     	mov	dword ptr [ebp - 0x14], eax
  7537d2: 8b 55 d4                     	mov	edx, dword ptr [ebp - 0x2c]
  7537d5: f2 0f 10 05 60 97 cb 00      	movsd	xmm0, qword ptr [0xcb9760]
  7537dd: f2 0f 11 42 20               	movsd	qword ptr [edx + 0x20], xmm0
  7537e2: c7 02 9c ae 34 01            	mov	dword ptr [edx], 0x134ae9c
  7537e8: 89 15 58 59 19 01            	mov	dword ptr [0x1195958], edx
  7537ee: 66 0f ef c9                  	pxor	xmm1, xmm1
  7537f2: f2 0f 11 4a 08               	movsd	qword ptr [edx + 0x8], xmm1
  7537f7: f2 0f 11 4a 10               	movsd	qword ptr [edx + 0x10], xmm1
  7537fc: 33 db                        	xor	ebx, ebx
  7537fe: 66 89 5a 28                  	mov	word ptr [edx + 0x28], bx
  753802: c7 42 18 00 00 f0 41         	mov	dword ptr [edx + 0x18], 0x41f00000
  753809: 88 5a 2a                     	mov	byte ptr [edx + 0x2a], bl
  75380c: e8 6f ee 30 00               	call	0xa62680 <.text+0x661680>
  753811: 8b c8                        	mov	ecx, eax
  753813: e8 88 26 31 00               	call	0xa65ea0 <.text+0x664ea0>
  753818: 50                           	push	eax
  753819: e8 92 71 02 00               	call	0x77a9b0 <.text+0x3799b0>
  75381e: 59                           	pop	ecx
  75381f: e8 5c ee 30 00               	call	0xa62680 <.text+0x661680>
  753824: 8b f0                        	mov	esi, eax
  753826: c7 45 a4 0f 00 00 00         	mov	dword ptr [ebp - 0x5c], 0xf
  75382d: 89 5d a0                     	mov	dword ptr [ebp - 0x60], ebx
  753830: 8d 55 90                     	lea	edx, [ebp - 0x70]
  753833: c7 45 e8 30 00 00 00         	mov	dword ptr [ebp - 0x18], 0x30
  75383a: 88 1a                        	mov	byte ptr [edx], bl
  75383c: 8b 7d a4                     	mov	edi, dword ptr [ebp - 0x5c]
  75383f: 8b 4d 90                     	mov	ecx, dword ptr [ebp - 0x70]
  753842: 8d 45 8c                     	lea	eax, [ebp - 0x74]
  753845: 89 45 c0                     	mov	dword ptr [ebp - 0x40], eax
  753848: b8 a0 97 cb 00               	mov	eax, 0xcb97a0
  75384d: 89 45 e4                     	mov	dword ptr [ebp - 0x1c], eax
  753850: 83 ff 10                     	cmp	edi, 0x10
  753853: 0f 42 ca                     	cmovb	ecx, edx
  753856: 3b c1                        	cmp	eax, ecx
  753858: 0f 83 5f 03 00 00            	jae	0x753bbd <.text+0x352bbd>
  75385e: 8b d3                        	mov	edx, ebx
  753860: 85 d2                        	test	edx, edx
  753862: 0f 84 85 00 00 00            	je	0x7538ed <.text+0x3528ed>
  753868: 8d 55 90                     	lea	edx, [ebp - 0x70]
  75386b: 83 ff 10                     	cmp	edi, 0x10
  75386e: 0f 43 55 90                  	cmovae	edx, dword ptr [ebp - 0x70]
  753872: 2b c2                        	sub	eax, edx
  753874: 8b 55 a0                     	mov	edx, dword ptr [ebp - 0x60]
  753877: 89 45 b0                     	mov	dword ptr [ebp - 0x50], eax
  75387a: 3b d0                        	cmp	edx, eax
  75387c: 72 11                        	jb	0x75388f <.text+0x35288f>
  75387e: 8b ca                        	mov	ecx, edx
  753880: 2b c8                        	sub	ecx, eax
  753882: bf 30 00 00 00               	mov	edi, 0x30
  753887: 83 f9 30                     	cmp	ecx, 0x30
  75388a: 0f 47 cf                     	cmova	ecx, edi
  75388d: eb 1b                        	jmp	0x7538aa <.text+0x3528aa>
  75388f: ff 15 dc 53 c2 00            	call	dword ptr [0xc253dc]
  753895: 8b 55 a0                     	mov	edx, dword ptr [ebp - 0x60]
  753898: 8b 45 b0                     	mov	eax, dword ptr [ebp - 0x50]
  75389b: 8b ca                        	mov	ecx, edx
  75389d: 2b c8                        	sub	ecx, eax
  75389f: bf 30 00 00 00               	mov	edi, 0x30
  7538a4: 83 f9 30                     	cmp	ecx, 0x30
  7538a7: 0f 47 cf                     	cmova	ecx, edi
  7538aa: 03 c1                        	add	eax, ecx
  7538ac: 8b 0d d0 53 c2 00            	mov	ecx, dword ptr [0xc253d0]
  7538b2: 8b 39                        	mov	edi, dword ptr [ecx]
  7538b4: 3b d0                        	cmp	edx, eax
  7538b6: 73 0f                        	jae	0x7538c7 <.text+0x3528c7>
  7538b8: 89 45 a8                     	mov	dword ptr [ebp - 0x58], eax
  7538bb: ff 15 dc 53 c2 00            	call	dword ptr [0xc253dc]
  7538c1: 8b 45 a8                     	mov	eax, dword ptr [ebp - 0x58]
  7538c4: 8b 55 a0                     	mov	edx, dword ptr [ebp - 0x60]
  7538c7: 8b ca                        	mov	ecx, edx
  7538c9: 2b c8                        	sub	ecx, eax
  7538cb: 3b cf                        	cmp	ecx, edi
  7538cd: 0f 42 f9                     	cmovb	edi, ecx
  7538d0: 85 ff                        	test	edi, edi
  7538d2: 0f 87 ea 00 00 00            	ja	0x7539c2 <.text+0x3529c2>
  7538d8: 8b 45 b0                     	mov	eax, dword ptr [ebp - 0x50]
  7538db: 3b d0                        	cmp	edx, eax
  7538dd: 0f 42 c2                     	cmovb	eax, edx
  7538e0: 85 c0                        	test	eax, eax
  7538e2: 89 45 ac                     	mov	dword ptr [ebp - 0x54], eax
  7538e5: 0f 87 8f 00 00 00            	ja	0x75397a <.text+0x35297a>
  7538eb: eb 1a                        	jmp	0x753907 <.text+0x352907>
  7538ed: c7 45 bc 30 00 00 00         	mov	dword ptr [ebp - 0x44], 0x30
  7538f4: 83 ff 30                     	cmp	edi, 0x30
  7538f7: 0f 82 79 01 00 00            	jb	0x753a76 <.text+0x352a76>
  7538fd: 83 7d bc 00                  	cmp	dword ptr [ebp - 0x44], 0x0
  753901: 0f 87 2c 01 00 00            	ja	0x753a33 <.text+0x352a33>
  753907: c7 45 fc 04 00 00 00         	mov	dword ptr [ebp - 0x4], 0x4
  75390e: 8d 55 a8                     	lea	edx, [ebp - 0x58]
  753911: 6a 00                        	push	0x0
  753913: 6a 01                        	push	0x1
  753915: 8b ce                        	mov	ecx, esi
  753917: 8d 45 8c                     	lea	eax, [ebp - 0x74]
  75391a: 50                           	push	eax
  75391b: 52                           	push	edx
  75391c: e8 4f c5 30 00               	call	0xa5fe70 <.text+0x65ee70>
  753921: 83 7d c0 10                  	cmp	dword ptr [ebp - 0x40], 0x10
  753925: 0f 83 fa 00 00 00            	jae	0x753a25 <.text+0x352a25>
  75392b: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  753932: 83 7d a4 10                  	cmp	dword ptr [ebp - 0x5c], 0x10
  753936: 89 5d bc                     	mov	dword ptr [ebp - 0x44], ebx
  753939: c7 45 c0 0f 00 00 00         	mov	dword ptr [ebp - 0x40], 0xf
  753940: 88 5d ac                     	mov	byte ptr [ebp - 0x54], bl
  753943: 0f 83 ce 00 00 00            	jae	0x753a17 <.text+0x352a17>
  753949: c7 45 a4 0f 00 00 00         	mov	dword ptr [ebp - 0x5c], 0xf
  753950: 89 5d a0                     	mov	dword ptr [ebp - 0x60], ebx
  753953: 88 5d 90                     	mov	byte ptr [ebp - 0x70], bl
  753956: 8b 5d d4                     	mov	ebx, dword ptr [ebp - 0x2c]
  753959: 8b 4d ec                     	mov	ecx, dword ptr [ebp - 0x14]
  75395c: e8 5f b5 33 00               	call	0xa8eec0 <.text+0x68dec0>
  753961: 8b 7d d8                     	mov	edi, dword ptr [ebp - 0x28]
  753964: 8b 75 dc                     	mov	esi, dword ptr [ebp - 0x24]
  753967: 8b c3                        	mov	eax, ebx
  753969: 8b 5d e0                     	mov	ebx, dword ptr [ebp - 0x20]
  75396c: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  75396f: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  753976: 8b e5                        	mov	esp, ebp
  753978: 5d                           	pop	ebp
  753979: c3                           	ret
  75397a: 8b 4d a4                     	mov	ecx, dword ptr [ebp - 0x5c]
  75397d: 83 f9 10                     	cmp	ecx, 0x10
  753980: 72 05                        	jb	0x753987 <.text+0x352987>
  753982: 8b 45 90                     	mov	eax, dword ptr [ebp - 0x70]
  753985: eb 03                        	jmp	0x75398a <.text+0x35298a>
  753987: 8d 45 90                     	lea	eax, [ebp - 0x70]
  75398a: 89 75 a8                     	mov	dword ptr [ebp - 0x58], esi
  75398d: 8b 75 ac                     	mov	esi, dword ptr [ebp - 0x54]
  753990: 8d 3c 06                     	lea	edi, [esi + eax]
  753993: 2b d6                        	sub	edx, esi
  753995: 8b 75 a8                     	mov	esi, dword ptr [ebp - 0x58]
  753998: 52                           	push	edx
  753999: 57                           	push	edi
  75399a: 51                           	push	ecx
  75399b: 50                           	push	eax
  75399c: ff 15 f8 55 c2 00            	call	dword ptr [0xc255f8]
  7539a2: 83 c4 10                     	add	esp, 0x10
  7539a5: 83 7d a4 10                  	cmp	dword ptr [ebp - 0x5c], 0x10
  7539a9: 8b 55 a0                     	mov	edx, dword ptr [ebp - 0x60]
  7539ac: 8d 45 90                     	lea	eax, [ebp - 0x70]
  7539af: 0f 43 45 90                  	cmovae	eax, dword ptr [ebp - 0x70]
  7539b3: 2b 55 ac                     	sub	edx, dword ptr [ebp - 0x54]
  7539b6: 89 55 a0                     	mov	dword ptr [ebp - 0x60], edx
  7539b9: c6 04 10 00                  	mov	byte ptr [eax + edx], 0x0
  7539bd: e9 45 ff ff ff               	jmp	0x753907 <.text+0x352907>
  7539c2: 8b 55 a4                     	mov	edx, dword ptr [ebp - 0x5c]
  7539c5: 89 55 ac                     	mov	dword ptr [ebp - 0x54], edx
  7539c8: 83 fa 10                     	cmp	edx, 0x10
  7539cb: 72 05                        	jb	0x7539d2 <.text+0x3529d2>
  7539cd: 8b 55 90                     	mov	edx, dword ptr [ebp - 0x70]
  7539d0: eb 03                        	jmp	0x7539d5 <.text+0x3529d5>
  7539d2: 8d 55 90                     	lea	edx, [ebp - 0x70]
  7539d5: 89 75 a8                     	mov	dword ptr [ebp - 0x58], esi
  7539d8: 8d 34 10                     	lea	esi, [eax + edx]
  7539db: 2b cf                        	sub	ecx, edi
  7539dd: 8b 5d ac                     	mov	ebx, dword ptr [ebp - 0x54]
  7539e0: 51                           	push	ecx
  7539e1: 2b d8                        	sub	ebx, eax
  7539e3: 03 c7                        	add	eax, edi
  7539e5: 03 c2                        	add	eax, edx
  7539e7: 50                           	push	eax
  7539e8: 53                           	push	ebx
  7539e9: 33 db                        	xor	ebx, ebx
  7539eb: 56                           	push	esi
  7539ec: 8b 75 a8                     	mov	esi, dword ptr [ebp - 0x58]
  7539ef: ff 15 f8 55 c2 00            	call	dword ptr [0xc255f8]
  7539f5: 83 c4 10                     	add	esp, 0x10
  7539f8: 8b 45 a0                     	mov	eax, dword ptr [ebp - 0x60]
  7539fb: 2b c7                        	sub	eax, edi
  7539fd: 83 7d a4 10                  	cmp	dword ptr [ebp - 0x5c], 0x10
  753a01: 89 45 a0                     	mov	dword ptr [ebp - 0x60], eax
  753a04: 8d 7d 90                     	lea	edi, [ebp - 0x70]
  753a07: 0f 43 7d 90                  	cmovae	edi, dword ptr [ebp - 0x70]
  753a0b: c6 04 07 00                  	mov	byte ptr [edi + eax], 0x0
  753a0f: 8b 55 a0                     	mov	edx, dword ptr [ebp - 0x60]
  753a12: e9 c1 fe ff ff               	jmp	0x7538d8 <.text+0x3528d8>
  753a17: ff 75 90                     	push	dword ptr [ebp - 0x70]
  753a1a: e8 73 b5 33 00               	call	0xa8ef92 <.text+0x68df92>
  753a1f: 59                           	pop	ecx
  753a20: e9 24 ff ff ff               	jmp	0x753949 <.text+0x352949>
  753a25: ff 75 ac                     	push	dword ptr [ebp - 0x54]
  753a28: e8 65 b5 33 00               	call	0xa8ef92 <.text+0x68df92>
  753a2d: 59                           	pop	ecx
  753a2e: e9 f8 fe ff ff               	jmp	0x75392b <.text+0x35292b>
  753a33: 8b 4d c0                     	mov	ecx, dword ptr [ebp - 0x40]
  753a36: 8b 51 18                     	mov	edx, dword ptr [ecx + 0x18]
  753a39: 83 fa 10                     	cmp	edx, 0x10
  753a3c: 72 05                        	jb	0x753a43 <.text+0x352a43>
  753a3e: 8b 49 04                     	mov	ecx, dword ptr [ecx + 0x4]
  753a41: eb 03                        	jmp	0x753a46 <.text+0x352a46>
  753a43: 83 c1 04                     	add	ecx, 0x4
  753a46: ff 75 e8                     	push	dword ptr [ebp - 0x18]
  753a49: ff 75 e4                     	push	dword ptr [ebp - 0x1c]
  753a4c: 52                           	push	edx
  753a4d: 51                           	push	ecx
  753a4e: ff 15 00 56 c2 00            	call	dword ptr [0xc25600]
  753a54: 83 c4 10                     	add	esp, 0x10
  753a57: 8b 45 c0                     	mov	eax, dword ptr [ebp - 0x40]
  753a5a: 83 78 18 10                  	cmp	dword ptr [eax + 0x18], 0x10
  753a5e: 8b 55 e8                     	mov	edx, dword ptr [ebp - 0x18]
  753a61: 89 50 14                     	mov	dword ptr [eax + 0x14], edx
  753a64: 72 05                        	jb	0x753a6b <.text+0x352a6b>
  753a66: 8b 40 04                     	mov	eax, dword ptr [eax + 0x4]
  753a69: eb 03                        	jmp	0x753a6e <.text+0x352a6e>
  753a6b: 83 c0 04                     	add	eax, 0x4
  753a6e: 88 1c 10                     	mov	byte ptr [eax + edx], bl
  753a71: e9 91 fe ff ff               	jmp	0x753907 <.text+0x352907>
  753a76: 8b 55 a0                     	mov	edx, dword ptr [ebp - 0x60]
  753a79: c7 45 a8 30 00 00 00         	mov	dword ptr [ebp - 0x58], 0x30
  753a80: b9 3f 00 00 00               	mov	ecx, 0x3f
  753a85: 8d 45 8c                     	lea	eax, [ebp - 0x74]
  753a88: 89 45 b4                     	mov	dword ptr [ebp - 0x4c], eax
  753a8b: 89 55 b8                     	mov	dword ptr [ebp - 0x48], edx
  753a8e: 8b d7                        	mov	edx, edi
  753a90: d1 ea                        	shr	edx
  753a92: 83 fa 15                     	cmp	edx, 0x15
  753a95: 77 09                        	ja	0x753aa0 <.text+0x352aa0>
  753a97: c7 45 ac 3f 00 00 00         	mov	dword ptr [ebp - 0x54], 0x3f
  753a9e: eb 11                        	jmp	0x753ab1 <.text+0x352ab1>
  753aa0: 8b c2                        	mov	eax, edx
  753aa2: f7 d8                        	neg	eax
  753aa4: 83 c0 fe                     	add	eax, -0x2
  753aa7: 3b f8                        	cmp	edi, eax
  753aa9: 77 ec                        	ja	0x753a97 <.text+0x352a97>
  753aab: 8d 0c 17                     	lea	ecx, [edi + edx]
  753aae: 89 4d ac                     	mov	dword ptr [ebp - 0x54], ecx
  753ab1: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  753ab8: c7 45 b0 00 00 00 00         	mov	dword ptr [ebp - 0x50], 0x0
  753abf: 41                           	inc	ecx
  753ac0: 75 04                        	jne	0x753ac6 <.text+0x352ac6>
  753ac2: 8b cb                        	mov	ecx, ebx
  753ac4: eb 36                        	jmp	0x753afc <.text+0x352afc>
  753ac6: 33 d2                        	xor	edx, edx
  753ac8: b8 ff ff ff ff               	mov	eax, 0xffffffff
  753acd: f7 f1                        	div	ecx
  753acf: 83 f8 01                     	cmp	eax, 0x1
  753ad2: 73 28                        	jae	0x753afc <.text+0x352afc>
  753ad4: c7 45 d0 00 00 00 00         	mov	dword ptr [ebp - 0x30], 0x0
  753adb: 8d 5d c4                     	lea	ebx, [ebp - 0x3c]
  753ade: 8b cb                        	mov	ecx, ebx
  753ae0: 8d 45 d0                     	lea	eax, [ebp - 0x30]
  753ae3: 50                           	push	eax
  753ae4: ff 15 f0 55 c2 00            	call	dword ptr [0xc255f0]
  753aea: c7 45 c4 20 a1 d3 00         	mov	dword ptr [ebp - 0x3c], 0xd3a120
  753af1: 68 18 01 d7 00               	push	0xd70118
  753af6: 53                           	push	ebx
  753af7: e8 1a b5 33 00               	call	0xa8f016 <.text+0x68e016>
  753afc: 50                           	push	eax
  753afd: 89 0c 24                     	mov	dword ptr [esp], ecx
  753b00: e8 05 b5 33 00               	call	0xa8f00a <.text+0x68e00a>
  753b05: 59                           	pop	ecx
  753b06: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  753b0d: 89 45 b0                     	mov	dword ptr [ebp - 0x50], eax
  753b10: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  753b17: 8b 55 b8                     	mov	edx, dword ptr [ebp - 0x48]
  753b1a: 85 d2                        	test	edx, edx
  753b1c: 77 76                        	ja	0x753b94 <.text+0x352b94>
  753b1e: 8b 45 b4                     	mov	eax, dword ptr [ebp - 0x4c]
  753b21: 83 78 18 10                  	cmp	dword ptr [eax + 0x18], 0x10
  753b25: 8b f8                        	mov	edi, eax
  753b27: 73 5d                        	jae	0x753b86 <.text+0x352b86>
  753b29: 8b 4d b0                     	mov	ecx, dword ptr [ebp - 0x50]
  753b2c: 8b 55 ac                     	mov	edx, dword ptr [ebp - 0x54]
  753b2f: c7 47 18 0f 00 00 00         	mov	dword ptr [edi + 0x18], 0xf
  753b36: 33 db                        	xor	ebx, ebx
  753b38: 89 5f 14                     	mov	dword ptr [edi + 0x14], ebx
  753b3b: 88 5f 04                     	mov	byte ptr [edi + 0x4], bl
  753b3e: 8b 7d b8                     	mov	edi, dword ptr [ebp - 0x48]
  753b41: 89 48 04                     	mov	dword ptr [eax + 0x4], ecx
  753b44: 89 50 18                     	mov	dword ptr [eax + 0x18], edx
  753b47: 89 78 14                     	mov	dword ptr [eax + 0x14], edi
  753b4a: 83 c0 04                     	add	eax, 0x4
  753b4d: 83 fa 10                     	cmp	edx, 0x10
  753b50: 0f 43 c1                     	cmovae	eax, ecx
  753b53: 88 1c 38                     	mov	byte ptr [eax + edi], bl
  753b56: e9 a2 fd ff ff               	jmp	0x7538fd <.text+0x3528fd>
  753b5b: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
  753b5e: c7 45 fc 02 00 00 00         	mov	dword ptr [ebp - 0x4], 0x2
  753b65: 8b 45 a8                     	mov	eax, dword ptr [ebp - 0x58]
  753b68: 8b 4d b4                     	mov	ecx, dword ptr [ebp - 0x4c]
  753b6b: 89 45 ac                     	mov	dword ptr [ebp - 0x54], eax
  753b6e: 40                           	inc	eax
  753b6f: 50                           	push	eax
  753b70: ff 15 d8 53 c2 00            	call	dword ptr [0xc253d8]
  753b76: c7 45 fc 01 00 00 00         	mov	dword ptr [ebp - 0x4], 0x1
  753b7d: 89 45 b0                     	mov	dword ptr [ebp - 0x50], eax
  753b80: b8 10 3b 75 00               	mov	eax, 0x753b10
  753b85: c3                           	ret
  753b86: ff 70 04                     	push	dword ptr [eax + 0x4]
  753b89: e8 04 b4 33 00               	call	0xa8ef92 <.text+0x68df92>
  753b8e: 59                           	pop	ecx
  753b8f: 8b 45 b4                     	mov	eax, dword ptr [ebp - 0x4c]
  753b92: eb 95                        	jmp	0x753b29 <.text+0x352b29>
  753b94: 8b 4d b4                     	mov	ecx, dword ptr [ebp - 0x4c]
  753b97: 83 79 18 10                  	cmp	dword ptr [ecx + 0x18], 0x10
  753b9b: 72 05                        	jb	0x753ba2 <.text+0x352ba2>
  753b9d: 8b 49 04                     	mov	ecx, dword ptr [ecx + 0x4]
  753ba0: eb 03                        	jmp	0x753ba5 <.text+0x352ba5>
  753ba2: 83 c1 04                     	add	ecx, 0x4
  753ba5: 8b 5d ac                     	mov	ebx, dword ptr [ebp - 0x54]
  753ba8: 52                           	push	edx
  753ba9: 43                           	inc	ebx
  753baa: 51                           	push	ecx
  753bab: 53                           	push	ebx
  753bac: ff 75 b0                     	push	dword ptr [ebp - 0x50]
  753baf: ff 15 00 56 c2 00            	call	dword ptr [0xc25600]
  753bb5: 83 c4 10                     	add	esp, 0x10
  753bb8: e9 61 ff ff ff               	jmp	0x753b1e <.text+0x352b1e>
  753bbd: 8d 55 90                     	lea	edx, [ebp - 0x70]
  753bc0: 83 ff 10                     	cmp	edi, 0x10
  753bc3: 0f 43 55 90                  	cmovae	edx, dword ptr [ebp - 0x70]
  753bc7: 03 55 a0                     	add	edx, dword ptr [ebp - 0x60]
  753bca: 3b d0                        	cmp	edx, eax
  753bcc: 0f 86 8c fc ff ff            	jbe	0x75385e <.text+0x35285e>
  753bd2: ba 01 00 00 00               	mov	edx, 0x1
  753bd7: e9 84 fc ff ff               	jmp	0x753860 <.text+0x352860>
  753bdc: 90                           	nop
  753bdd: 90                           	nop
  753bde: 90                           	nop
  753bdf: 90                           	nop
  753be0: 55                           	push	ebp
  753be1: 8b e9                        	mov	ebp, ecx
  753be3: 0f b6 45 28                  	movzx	eax, byte ptr [ebp + 0x28]
  753be7: 85 c0                        	test	eax, eax
  753be9: 74 29                        	je	0x753c14 <.text+0x352c14>
  753beb: 0f b6 45 2a                  	movzx	eax, byte ptr [ebp + 0x2a]
  753bef: 85 c0                        	test	eax, eax
  753bf1: 0f 85 9a 00 00 00            	jne	0x753c91 <.text+0x352c91>
  753bf7: f3 0f 5a 45 18               	cvtss2sd	xmm0, dword ptr [ebp + 0x18]
  753bfc: f2 0f 10 0d 70 97 cb 00      	movsd	xmm1, qword ptr [0xcb9770]
  753c04: f2 0f 5e c8                  	divsd	xmm1, xmm0
  753c08: f2 0f 58 4d 08               	addsd	xmm1, qword ptr [ebp + 0x8]
  753c0d: f2 0f 11 4d 08               	movsd	qword ptr [ebp + 0x8], xmm1
  753c12: 5d                           	pop	ebp
  753c13: c3                           	ret
  753c14: 0f b6 45 2a                  	movzx	eax, byte ptr [ebp + 0x2a]
  753c18: 85 c0                        	test	eax, eax
  753c1a: 75 3f                        	jne	0x753c5b <.text+0x352c5b>
  753c1c: ff 15 98 7a c2 00            	call	dword ptr [0xc27a98]
  753c22: f2 0f 2a d0                  	cvtsi2sd	xmm2, eax
  753c26: c1 e8 1f                     	shr	eax, 0x1f
  753c29: f2 0f 58 14 c5 30 97 cb 00   	addsd	xmm2, qword ptr [8*eax + 0xcb9730]
  753c32: f2 0f 5e 15 68 97 cb 00      	divsd	xmm2, qword ptr [0xcb9768]
  753c3a: f2 0f 5c 55 10               	subsd	xmm2, qword ptr [ebp + 0x10]
  753c3f: 66 0f ef c9                  	pxor	xmm1, xmm1
  753c43: 0f 28 c2                     	movaps	xmm0, xmm2
  753c46: f2 0f 5c 45 08               	subsd	xmm0, qword ptr [ebp + 0x8]
  753c4b: f2 0f 11 55 08               	movsd	qword ptr [ebp + 0x8], xmm2
  753c50: f2 0f 5f c8                  	maxsd	xmm1, xmm0
  753c54: f2 0f 11 4d 20               	movsd	qword ptr [ebp + 0x20], xmm1
  753c59: 5d                           	pop	ebp
  753c5a: c3                           	ret
  753c5b: 66 0f ef c0                  	pxor	xmm0, xmm0
  753c5f: f2 0f 11 45 20               	movsd	qword ptr [ebp + 0x20], xmm0
  753c64: ff 15 98 7a c2 00            	call	dword ptr [0xc27a98]
  753c6a: f2 0f 2a c0                  	cvtsi2sd	xmm0, eax
  753c6e: c1 e8 1f                     	shr	eax, 0x1f
  753c71: f2 0f 58 04 c5 30 97 cb 00   	addsd	xmm0, qword ptr [8*eax + 0xcb9730]
  753c7a: f2 0f 5e 05 68 97 cb 00      	divsd	xmm0, qword ptr [0xcb9768]
  753c82: f2 0f 58 45 10               	addsd	xmm0, qword ptr [ebp + 0x10]
  753c87: f2 0f 5c 45 08               	subsd	xmm0, qword ptr [ebp + 0x8]
  753c8c: f2 0f 11 45 10               	movsd	qword ptr [ebp + 0x10], xmm0
  753c91: 5d                           	pop	ebp
  753c92: c3                           	ret
  753c93: 8d b6 00 00 00 00            	lea	esi, [esi]
  753c99: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  753ca0: f3 0f 10 4c 24 04            	movss	xmm1, dword ptr [esp + 0x4]
  753ca6: f3 0f 10 15 94 97 cb 00      	movss	xmm2, dword ptr [0xcb9794]
  753cae: 66 0f ef c0                  	pxor	xmm0, xmm0
  753cb2: 0f 2f c1                     	comiss	xmm0, xmm1
  753cb5: 73 03                        	jae	0x753cba <.text+0x352cba>
  753cb7: 0f 28 d1                     	movaps	xmm2, xmm1
  753cba: f3 0f 11 51 18               	movss	dword ptr [ecx + 0x18], xmm2
  753cbf: c2 04 00                     	ret	0x4
  753cc2: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  753cc9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  753cd0: d9 41 18                     	fld	dword ptr [ecx + 0x18]
  753cd3: c3                           	ret
  753cd4: 8d b6 00 00 00 00            	lea	esi, [esi]
  753cda: 8d bf 00 00 00 00            	lea	edi, [edi]
  753ce0: 0f b6 44 24 04               	movzx	eax, byte ptr [esp + 0x4]
  753ce5: 88 41 2a                     	mov	byte ptr [ecx + 0x2a], al
  753ce8: c2 04 00                     	ret	0x4
  753ceb: 90                           	nop
  753cec: 8d 74 26 00                  	lea	esi, [esi + eiz]
  753cf0: 0f b6 41 2a                  	movzx	eax, byte ptr [ecx + 0x2a]
  753cf4: c3                           	ret
  753cf5: 8d 74 26 00                  	lea	esi, [esi + eiz]
  753cf9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  753d00: 0f b6 44 24 04               	movzx	eax, byte ptr [esp + 0x4]
  753d05: 88 41 28                     	mov	byte ptr [ecx + 0x28], al
  753d08: c2 04 00                     	ret	0x4
  753d0b: 90                           	nop
  753d0c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  753d10: 0f b6 41 28                  	movzx	eax, byte ptr [ecx + 0x28]
  753d14: c3                           	ret
  753d15: 8d 74 26 00                  	lea	esi, [esi + eiz]
  753d19: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  753d20: f2 0f 10 44 24 04            	movsd	xmm0, qword ptr [esp + 0x4]
  753d26: f2 0f 11 41 20               	movsd	qword ptr [ecx + 0x20], xmm0
  753d2b: c2 08 00                     	ret	0x8
  753d2e: 8b f6                        	mov	esi, esi
  753d30: 83 ec 08                     	sub	esp, 0x8
  753d33: 0f b6 41 28                  	movzx	eax, byte ptr [ecx + 0x28]
  753d37: 85 c0                        	test	eax, eax
  753d39: 74 1d                        	je	0x753d58 <.text+0x352d58>
  753d3b: f3 0f 5a 41 18               	cvtss2sd	xmm0, dword ptr [ecx + 0x18]
  753d40: f2 0f 10 0d 78 97 cb 00      	movsd	xmm1, qword ptr [0xcb9778]
  753d48: f2 0f 5e c8                  	divsd	xmm1, xmm0
  753d4c: f2 0f 11 0c 24               	movsd	qword ptr [esp], xmm1
  753d51: dd 04 24                     	fld	qword ptr [esp]
  753d54: 83 c4 08                     	add	esp, 0x8
  753d57: c3                           	ret
  753d58: dd 41 20                     	fld	qword ptr [ecx + 0x20]
  753d5b: 83 c4 08                     	add	esp, 0x8
  753d5e: c3                           	ret
  753d5f: 90                           	nop
  753d60: 57                           	push	edi
  753d61: 8b f9                        	mov	edi, ecx
  753d63: ff 15 98 7a c2 00            	call	dword ptr [0xc27a98]
  753d69: f2 0f 2a c0                  	cvtsi2sd	xmm0, eax
  753d6d: f2 0f 10 54 24 08            	movsd	xmm2, qword ptr [esp + 0x8]
  753d73: f2 0f 11 57 08               	movsd	qword ptr [edi + 0x8], xmm2
  753d78: 0f 28 ca                     	movaps	xmm1, xmm2
  753d7b: c1 e8 1f                     	shr	eax, 0x1f
  753d7e: f2 0f 58 04 c5 40 97 cb 00   	addsd	xmm0, qword ptr [8*eax + 0xcb9740]
  753d87: f2 0f 5e 05 80 97 cb 00      	divsd	xmm0, qword ptr [0xcb9780]
  753d8f: f2 0f 5c c8                  	subsd	xmm1, xmm0
  753d93: f2 0f 11 4f 10               	movsd	qword ptr [edi + 0x10], xmm1
  753d98: 5f                           	pop	edi
  753d99: c2 08 00                     	ret	0x8
  753d9c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  753da0: dd 41 08                     	fld	qword ptr [ecx + 0x8]
  753da3: c3                           	ret
  753da4: 8d b6 00 00 00 00            	lea	esi, [esi]
  753daa: 8d bf 00 00 00 00            	lea	edi, [edi]
  753db0: 56                           	push	esi
  753db1: 83 ec 08                     	sub	esp, 0x8
  753db4: 8b f1                        	mov	esi, ecx
  753db6: 0f b6 46 28                  	movzx	eax, byte ptr [esi + 0x28]
  753dba: 85 c0                        	test	eax, eax
  753dbc: 74 08                        	je	0x753dc6 <.text+0x352dc6>
  753dbe: dd 46 08                     	fld	qword ptr [esi + 0x8]
  753dc1: 83 c4 08                     	add	esp, 0x8
  753dc4: 5e                           	pop	esi
  753dc5: c3                           	ret
  753dc6: ff 15 98 7a c2 00            	call	dword ptr [0xc27a98]
  753dcc: f2 0f 2a c0                  	cvtsi2sd	xmm0, eax
  753dd0: c1 e8 1f                     	shr	eax, 0x1f
  753dd3: f2 0f 58 04 c5 50 97 cb 00   	addsd	xmm0, qword ptr [8*eax + 0xcb9750]
  753ddc: f2 0f 5e 05 88 97 cb 00      	divsd	xmm0, qword ptr [0xcb9788]
  753de4: f2 0f 58 46 10               	addsd	xmm0, qword ptr [esi + 0x10]
  753de9: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  753dee: dd 04 24                     	fld	qword ptr [esp]
  753df1: 83 c4 08                     	add	esp, 0x8
  753df4: 5e                           	pop	esi
  753df5: c3                           	ret
  753df6: 8d 76 00                     	lea	esi, [esi]
  753df9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  753e00: 56                           	push	esi
  753e01: 8b f1                        	mov	esi, ecx
  753e03: e8 38 a9 00 00               	call	0x75e740 <.text+0x35d740>
  753e08: f6 44 24 08 01               	test	byte ptr [esp + 0x8], 0x1
  753e0d: 75 06                        	jne	0x753e15 <.text+0x352e15>
  753e0f: 8b c6                        	mov	eax, esi
  753e11: 5e                           	pop	esi
  753e12: c2 04 00                     	ret	0x4
  753e15: 56                           	push	esi
  753e16: e8 77 b1 33 00               	call	0xa8ef92 <.text+0x68df92>
  753e1b: 59                           	pop	ecx
  753e1c: eb f1                        	jmp	0x753e0f <.text+0x352e0f>
  753e1e: 8b f6                        	mov	esi, esi
  753e20: b9 80 59 19 01               	mov	ecx, 0x1195980
  753e25: e8 06 00 00 00               	call	0x753e30 <.text+0x352e30>
  753e2a: c3                           	ret
  753e2b: 90                           	nop
  753e2c: 8d 74 26 00                  	lea	esi, [esi + eiz]
