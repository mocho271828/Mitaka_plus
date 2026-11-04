
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5eb3f0: 83 ec 20                     	sub	esp, 0x20
  5eb3f3: f2 0f 2a 44 24 38            	cvtsi2sd	xmm0, dword ptr [esp + 0x38]
  5eb3f9: 8b 54 24 24                  	mov	edx, dword ptr [esp + 0x24]
  5eb3fd: 8b 4c 24 28                  	mov	ecx, dword ptr [esp + 0x28]
  5eb401: 8b 44 24 34                  	mov	eax, dword ptr [esp + 0x34]
  5eb405: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  5eb40b: 89 14 24                     	mov	dword ptr [esp], edx
  5eb40e: 8b 54 24 2c                  	mov	edx, dword ptr [esp + 0x2c]
  5eb412: 88 4c 24 04                  	mov	byte ptr [esp + 0x4], cl
  5eb416: 88 54 24 05                  	mov	byte ptr [esp + 0x5], dl
  5eb41a: 8b 54 24 30                  	mov	edx, dword ptr [esp + 0x30]
  5eb41e: 88 54 24 06                  	mov	byte ptr [esp + 0x6], dl
  5eb422: 88 44 24 07                  	mov	byte ptr [esp + 0x7], al
  5eb426: 6a 00                        	push	0x0
  5eb428: e8 93 9c e9 ff               	call	0x4850c0 <.text+0x840c0>
  5eb42d: 8d 44 24 04                  	lea	eax, [esp + 0x4]
  5eb431: 50                           	push	eax
  5eb432: e8 49 2d e3 ff               	call	0x41e180 <.text+0x1d180>
  5eb437: dd 5c 24 20                  	fstp	qword ptr [esp + 0x20]
  5eb43b: 83 c4 08                     	add	esp, 0x8
  5eb43e: ff 15 e0 56 c2 00            	call	dword ptr [0xc256e0]
  5eb444: f2 0f 2a 00                  	cvtsi2sd	xmm0, dword ptr [eax]
  5eb448: f2 0f 5e 05 90 75 c3 00      	divsd	xmm0, qword ptr [0xc37590]
  5eb450: f2 0f 5e 05 98 75 c3 00      	divsd	xmm0, qword ptr [0xc37598]
  5eb458: f2 0f 10 4c 24 18            	movsd	xmm1, qword ptr [esp + 0x18]
  5eb45e: 8d 44 24 10                  	lea	eax, [esp + 0x10]
  5eb462: f2 0f 58 c8                  	addsd	xmm1, xmm0
  5eb466: f2 0f 11 4c 24 10            	movsd	qword ptr [esp + 0x10], xmm1
  5eb46c: 50                           	push	eax
  5eb46d: e8 1e bb e9 ff               	call	0x486f90 <.text+0x85f90>
  5eb472: 59                           	pop	ecx
  5eb473: e8 f8 cf fe ff               	call	0x5d8470 <.text+0x1d7470>
  5eb478: 8b c8                        	mov	ecx, eax
  5eb47a: e8 61 d7 fe ff               	call	0x5d8be0 <.text+0x1d7be0>
  5eb47f: 83 c4 20                     	add	esp, 0x20
  5eb482: c2 18 00                     	ret	0x18
  5eb485: 8d 74 26 00                  	lea	esi, [esi + eiz]
  5eb489: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  5eb490: 83 ec 20                     	sub	esp, 0x20
  5eb493: e8 58 0f fb ff               	call	0x59c3f0 <.text+0x19b3f0>
  5eb498: dd 5c 24 18                  	fstp	qword ptr [esp + 0x18]
  5eb49c: ff 15 e0 56 c2 00            	call	dword ptr [0xc256e0]
  5eb4a2: f2 0f 2a 00                  	cvtsi2sd	xmm0, dword ptr [eax]
  5eb4a6: f2 0f 5e 05 a0 75 c3 00      	divsd	xmm0, qword ptr [0xc375a0]
  5eb4ae: f2 0f 5e 05 a8 75 c3 00      	divsd	xmm0, qword ptr [0xc375a8]
  5eb4b6: f2 0f 10 4c 24 18            	movsd	xmm1, qword ptr [esp + 0x18]
  5eb4bc: 8d 14 24                     	lea	edx, [esp]
  5eb4bf: 8d 44 24 10                  	lea	eax, [esp + 0x10]
  5eb4c3: f2 0f 5c c8                  	subsd	xmm1, xmm0
  5eb4c7: f2 0f 11 4c 24 10            	movsd	qword ptr [esp + 0x10], xmm1
  5eb4cd: 50                           	push	eax
  5eb4ce: 52                           	push	edx
  5eb4cf: e8 3c 2f e3 ff               	call	0x41e410 <.text+0x1d410>
  5eb4d4: 83 c4 08                     	add	esp, 0x8
  5eb4d7: 8b 44 24 28                  	mov	eax, dword ptr [esp + 0x28]
  5eb4db: 8b 4c 24 24                  	mov	ecx, dword ptr [esp + 0x24]
  5eb4df: 8b 14 24                     	mov	edx, dword ptr [esp]
  5eb4e2: 89 11                        	mov	dword ptr [ecx], edx
  5eb4e4: 0f be 54 24 04               	movsx	edx, byte ptr [esp + 0x4]
  5eb4e9: 8b 4c 24 2c                  	mov	ecx, dword ptr [esp + 0x2c]
  5eb4ed: 89 10                        	mov	dword ptr [eax], edx
  5eb4ef: 0f be 44 24 05               	movsx	eax, byte ptr [esp + 0x5]
  5eb4f4: 8b 54 24 30                  	mov	edx, dword ptr [esp + 0x30]
  5eb4f8: 89 01                        	mov	dword ptr [ecx], eax
  5eb4fa: 0f be 44 24 06               	movsx	eax, byte ptr [esp + 0x6]
  5eb4ff: 0f be 4c 24 07               	movsx	ecx, byte ptr [esp + 0x7]
  5eb504: 89 02                        	mov	dword ptr [edx], eax
  5eb506: 8b 44 24 34                  	mov	eax, dword ptr [esp + 0x34]
  5eb50a: f2 0f 2c 54 24 08            	cvttsd2si	edx, qword ptr [esp + 0x8]
  5eb510: 89 08                        	mov	dword ptr [eax], ecx
  5eb512: 8b 4c 24 38                  	mov	ecx, dword ptr [esp + 0x38]
  5eb516: 89 11                        	mov	dword ptr [ecx], edx
  5eb518: 83 c4 20                     	add	esp, 0x20
  5eb51b: c2 18 00                     	ret	0x18
  5eb51e: 8b f6                        	mov	esi, esi
  5eb520: 53                           	push	ebx
  5eb521: 8b dc                        	mov	ebx, esp
  5eb523: 83 e4 c0                     	and	esp, -0x40
  5eb526: 55                           	push	ebp
  5eb527: 55                           	push	ebp
  5eb528: 8b 6b 04                     	mov	ebp, dword ptr [ebx + 0x4]
  5eb52b: 89 6c 24 04                  	mov	dword ptr [esp + 0x4], ebp
  5eb52f: 8b ec                        	mov	ebp, esp
  5eb531: 6a ff                        	push	-0x1
  5eb533: 68 f0 d7 bf 00               	push	0xbfd7f0
  5eb538: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  5eb53e: 50                           	push	eax
  5eb53f: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  5eb546: 83 ec 6c                     	sub	esp, 0x6c
  5eb549: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  5eb54c: 89 7d a8                     	mov	dword ptr [ebp - 0x58], edi
  5eb54f: 89 75 ac                     	mov	dword ptr [ebp - 0x54], esi
  5eb552: f2 0f 2a 43 1c               	cvtsi2sd	xmm0, dword ptr [ebx + 0x1c]
  5eb557: 8b 73 08                     	mov	esi, dword ptr [ebx + 0x8]
  5eb55a: 8b 43 0c                     	mov	eax, dword ptr [ebx + 0xc]
  5eb55d: 8b 53 10                     	mov	edx, dword ptr [ebx + 0x10]
  5eb560: f2 0f 11 45 98               	movsd	qword ptr [ebp - 0x68], xmm0
  5eb565: 89 4d b0                     	mov	dword ptr [ebp - 0x50], ecx
  5eb568: 8b 4b 14                     	mov	ecx, dword ptr [ebx + 0x14]
  5eb56b: 89 75 90                     	mov	dword ptr [ebp - 0x70], esi
  5eb56e: 88 45 94                     	mov	byte ptr [ebp - 0x6c], al
  5eb571: 8b 43 18                     	mov	eax, dword ptr [ebx + 0x18]
  5eb574: 88 55 95                     	mov	byte ptr [ebp - 0x6b], dl
  5eb577: 88 4d 96                     	mov	byte ptr [ebp - 0x6a], cl
  5eb57a: 88 45 97                     	mov	byte ptr [ebp - 0x69], al
  5eb57d: 6a 00                        	push	0x0
  5eb57f: e8 3c 9b e9 ff               	call	0x4850c0 <.text+0x840c0>
  5eb584: 59                           	pop	ecx
  5eb585: 0f b6 43 28                  	movzx	eax, byte ptr [ebx + 0x28]
  5eb589: 85 c0                        	test	eax, eax
  5eb58b: 0f 84 96 00 00 00            	je	0x5eb627 <.text+0x1ea627>
  5eb591: c7 45 fc 02 00 00 00         	mov	dword ptr [ebp - 0x4], 0x2
  5eb598: c7 45 a0 00 00 00 00         	mov	dword ptr [ebp - 0x60], 0x0
  5eb59f: 50                           	push	eax
  5eb5a0: c7 04 24 40 00 00 00         	mov	dword ptr [esp], 0x40
  5eb5a7: e8 5e 3a 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5eb5ac: 59                           	pop	ecx
  5eb5ad: 8b f8                        	mov	edi, eax
  5eb5af: 89 7d a4                     	mov	dword ptr [ebp - 0x5c], edi
  5eb5b2: 85 ff                        	test	edi, edi
  5eb5b4: 74 6a                        	je	0x5eb620 <.text+0x1ea620>
  5eb5b6: c7 45 a0 01 00 00 00         	mov	dword ptr [ebp - 0x60], 0x1
  5eb5bd: 8d 45 90                     	lea	eax, [ebp - 0x70]
  5eb5c0: 50                           	push	eax
  5eb5c1: 89 04 24                     	mov	dword ptr [esp], eax
  5eb5c4: e8 b7 2b e3 ff               	call	0x41e180 <.text+0x1d180>
  5eb5c9: dd 5d 88                     	fstp	qword ptr [ebp - 0x78]
  5eb5cc: 83 c4 04                     	add	esp, 0x4
  5eb5cf: ff 15 e0 56 c2 00            	call	dword ptr [0xc256e0]
  5eb5d5: f2 0f 2a 00                  	cvtsi2sd	xmm0, dword ptr [eax]
  5eb5d9: f2 0f 5e 05 b0 75 c3 00      	divsd	xmm0, qword ptr [0xc375b0]
  5eb5e1: f2 0f 5e 05 b8 75 c3 00      	divsd	xmm0, qword ptr [0xc375b8]
  5eb5e9: f2 0f 10 4d 88               	movsd	xmm1, qword ptr [ebp - 0x78]
  5eb5ee: f2 0f 10 53 20               	movsd	xmm2, qword ptr [ebx + 0x20]
  5eb5f3: 83 c4 ec                     	add	esp, -0x14
  5eb5f6: f2 0f 11 54 24 08            	movsd	qword ptr [esp + 0x8], xmm2
  5eb5fc: f2 0f 58 c8                  	addsd	xmm1, xmm0
  5eb600: f2 0f 11 0c 24               	movsd	qword ptr [esp], xmm1
  5eb605: c7 44 24 10 00 00 00 00      	mov	dword ptr [esp + 0x10], 0x0
  5eb60d: 8b cf                        	mov	ecx, edi
  5eb60f: e8 7c 44 1d 00               	call	0x7bfa90 <.text+0x3bea90>
  5eb614: c7 45 a0 00 00 00 00         	mov	dword ptr [ebp - 0x60], 0x0
  5eb61b: e9 95 00 00 00               	jmp	0x5eb6b5 <.text+0x1ea6b5>
  5eb620: 33 ff                        	xor	edi, edi
  5eb622: e9 8e 00 00 00               	jmp	0x5eb6b5 <.text+0x1ea6b5>
  5eb627: c7 45 fc 01 00 00 00         	mov	dword ptr [ebp - 0x4], 0x1
  5eb62e: c7 45 a0 00 00 00 00         	mov	dword ptr [ebp - 0x60], 0x0
  5eb635: 50                           	push	eax
  5eb636: c7 04 24 40 00 00 00         	mov	dword ptr [esp], 0x40
  5eb63d: e8 c8 39 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5eb642: 59                           	pop	ecx
  5eb643: 8b f8                        	mov	edi, eax
  5eb645: 89 7d a4                     	mov	dword ptr [ebp - 0x5c], edi
  5eb648: 85 ff                        	test	edi, edi
  5eb64a: 74 67                        	je	0x5eb6b3 <.text+0x1ea6b3>
  5eb64c: c7 45 a0 01 00 00 00         	mov	dword ptr [ebp - 0x60], 0x1
  5eb653: 8d 45 90                     	lea	eax, [ebp - 0x70]
  5eb656: 50                           	push	eax
  5eb657: 89 04 24                     	mov	dword ptr [esp], eax
  5eb65a: e8 21 2b e3 ff               	call	0x41e180 <.text+0x1d180>
  5eb65f: dd 5d 88                     	fstp	qword ptr [ebp - 0x78]
  5eb662: 83 c4 04                     	add	esp, 0x4
  5eb665: ff 15 e0 56 c2 00            	call	dword ptr [0xc256e0]
  5eb66b: f2 0f 2a 00                  	cvtsi2sd	xmm0, dword ptr [eax]
  5eb66f: f2 0f 5e 05 b0 75 c3 00      	divsd	xmm0, qword ptr [0xc375b0]
  5eb677: f2 0f 5e 05 b8 75 c3 00      	divsd	xmm0, qword ptr [0xc375b8]
  5eb67f: f2 0f 10 4d 88               	movsd	xmm1, qword ptr [ebp - 0x78]
  5eb684: f2 0f 10 53 20               	movsd	xmm2, qword ptr [ebx + 0x20]
  5eb689: 83 c4 ec                     	add	esp, -0x14
  5eb68c: f2 0f 11 54 24 08            	movsd	qword ptr [esp + 0x8], xmm2
  5eb692: f2 0f 58 c8                  	addsd	xmm1, xmm0
  5eb696: f2 0f 11 0c 24               	movsd	qword ptr [esp], xmm1
  5eb69b: c7 44 24 10 00 00 00 00      	mov	dword ptr [esp + 0x10], 0x0
  5eb6a3: 8b cf                        	mov	ecx, edi
  5eb6a5: e8 a6 45 1d 00               	call	0x7bfc50 <.text+0x3bec50>
  5eb6aa: c7 45 a0 00 00 00 00         	mov	dword ptr [ebp - 0x60], 0x0
  5eb6b1: eb 02                        	jmp	0x5eb6b5 <.text+0x1ea6b5>
  5eb6b3: 33 ff                        	xor	edi, edi
  5eb6b5: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5eb6bc: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  5eb6c3: c7 45 88 00 00 00 00         	mov	dword ptr [ebp - 0x78], 0x0
  5eb6ca: 50                           	push	eax
  5eb6cb: c7 04 24 18 00 00 00         	mov	dword ptr [esp], 0x18
  5eb6d2: e8 33 39 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5eb6d7: 59                           	pop	ecx
  5eb6d8: 8b f0                        	mov	esi, eax
  5eb6da: 89 75 8c                     	mov	dword ptr [ebp - 0x74], esi
  5eb6dd: 85 f6                        	test	esi, esi
  5eb6df: 74 23                        	je	0x5eb704 <.text+0x1ea704>
  5eb6e1: 8b 45 b0                     	mov	eax, dword ptr [ebp - 0x50]
  5eb6e4: c7 06 a8 29 2d 01            	mov	dword ptr [esi], 0x12d29a8
  5eb6ea: 89 46 04                     	mov	dword ptr [esi + 0x4], eax
  5eb6ed: 33 d2                        	xor	edx, edx
  5eb6ef: c7 46 14 40 c0 5e 00         	mov	dword ptr [esi + 0x14], 0x5ec040
  5eb6f6: 89 55 88                     	mov	dword ptr [ebp - 0x78], edx
  5eb6f9: 89 56 08                     	mov	dword ptr [esi + 0x8], edx
  5eb6fc: 89 56 0c                     	mov	dword ptr [esi + 0xc], edx
  5eb6ff: 89 56 10                     	mov	dword ptr [esi + 0x10], edx
  5eb702: eb 02                        	jmp	0x5eb706 <.text+0x1ea706>
  5eb704: 33 f6                        	xor	esi, esi
  5eb706: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5eb70d: e8 de 0c fb ff               	call	0x59c3f0 <.text+0x19b3f0>
  5eb712: 8b 07                        	mov	eax, dword ptr [edi]
  5eb714: 83 c4 f4                     	add	esp, -0xc
  5eb717: dd 5c 24 04                  	fstp	qword ptr [esp + 0x4]
  5eb71b: 8b cf                        	mov	ecx, edi
  5eb71d: 89 34 24                     	mov	dword ptr [esp], esi
  5eb720: ff 50 0c                     	call	dword ptr [eax + 0xc]
  5eb723: 8b 7d a8                     	mov	edi, dword ptr [ebp - 0x58]
  5eb726: 8b 75 ac                     	mov	esi, dword ptr [ebp - 0x54]
  5eb729: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  5eb72c: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  5eb733: 8b e5                        	mov	esp, ebp
  5eb735: 5d                           	pop	ebp
  5eb736: 8b e3                        	mov	esp, ebx
  5eb738: 5b                           	pop	ebx
  5eb739: c2 24 00                     	ret	0x24
  5eb73c: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5eb73f: 83 7d a0 00                  	cmp	dword ptr [ebp - 0x60], 0x0
  5eb743: 0f 84 99 20 61 00            	je	0xbfd7e2
  5eb749: ff 75 a4                     	push	dword ptr [ebp - 0x5c]
  5eb74c: e8 41 38 4a 00               	call	0xa8ef92 <.text+0x68df92>
  5eb751: 59                           	pop	ecx
  5eb752: e9 8b 20 61 00               	jmp	0xbfd7e2
  5eb757: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5eb75a: 83 7d a0 00                  	cmp	dword ptr [ebp - 0x60], 0x0
  5eb75e: 0f 84 7e 20 61 00            	je	0xbfd7e2
