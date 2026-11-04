
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  41e180: 55                           	push	ebp
  41e181: 8b ec                        	mov	ebp, esp
  41e183: 83 e4 f8                     	and	esp, -0x8
  41e186: 57                           	push	edi
  41e187: 56                           	push	esi
  41e188: 53                           	push	ebx
  41e189: 83 ec 1c                     	sub	esp, 0x1c
  41e18c: 8b 75 08                     	mov	esi, dword ptr [ebp + 0x8]
  41e18f: 8b 3e                        	mov	edi, dword ptr [esi]
  41e191: 0f be 46 04                  	movsx	eax, byte ptr [esi + 0x4]
  41e195: 0f be 56 05                  	movsx	edx, byte ptr [esi + 0x5]
  41e199: 0f be 4e 06                  	movsx	ecx, byte ptr [esi + 0x6]
  41e19d: 0f be 5e 07                  	movsx	ebx, byte ptr [esi + 0x7]
  41e1a1: f2 0f 10 46 08               	movsd	xmm0, qword ptr [esi + 0x8]
  41e1a6: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  41e1ab: 89 44 24 0c                  	mov	dword ptr [esp + 0xc], eax
  41e1af: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  41e1b3: 89 54 24 10                  	mov	dword ptr [esp + 0x10], edx
  41e1b7: 99                           	cdq
  41e1b8: 89 4c 24 14                  	mov	dword ptr [esp + 0x14], ecx
  41e1bc: 89 5c 24 18                  	mov	dword ptr [esp + 0x18], ebx
  41e1c0: 8b da                        	mov	ebx, edx
  41e1c2: b9 0c 00 00 00               	mov	ecx, 0xc
  41e1c7: 33 d2                        	xor	edx, edx
  41e1c9: 8b f1                        	mov	esi, ecx
  41e1cb: 52                           	push	edx
  41e1cc: 51                           	push	ecx
  41e1cd: 2b f0                        	sub	esi, eax
  41e1cf: 8b c2                        	mov	eax, edx
  41e1d1: 1b c3                        	sbb	eax, ebx
  41e1d3: 50                           	push	eax
  41e1d4: 56                           	push	esi
  41e1d5: 8b 74 24 1c                  	mov	esi, dword ptr [esp + 0x1c]
  41e1d9: e8 92 0e 67 00               	call	0xa8f070 <.text+0x68e070>
  41e1de: 85 f6                        	test	esi, esi
  41e1e0: 7f 2d                        	jg	0x41e20f <.text+0x1d20f>
  41e1e2: 8b 5c 24 08                  	mov	ebx, dword ptr [esp + 0x8]
  41e1e6: 89 44 24 0c                  	mov	dword ptr [esp + 0xc], eax
  41e1ea: 8b c7                        	mov	eax, edi
  41e1ec: 33 c9                        	xor	ecx, ecx
  41e1ee: 33 d2                        	xor	edx, edx
  41e1f0: 8d 7c 02 ff                  	lea	edi, [edx + eax - 0x1]
  41e1f4: 8d 34 cd 00 00 00 00         	lea	esi, [8*ecx]
  41e1fb: 8d 34 8e                     	lea	esi, [esi + 4*ecx]
  41e1fe: 8d 74 1e 0c                  	lea	esi, [esi + ebx + 0xc]
  41e202: 4a                           	dec	edx
  41e203: 41                           	inc	ecx
  41e204: 3b 4c 24 0c                  	cmp	ecx, dword ptr [esp + 0xc]
  41e208: 72 e6                        	jb	0x41e1f0 <.text+0x1d1f0>
  41e20a: 8b c6                        	mov	eax, esi
  41e20c: 99                           	cdq
  41e20d: 8b da                        	mov	ebx, edx
  41e20f: 8b c6                        	mov	eax, esi
  41e211: 6a 00                        	push	0x0
  41e213: 83 c0 ff                     	add	eax, -0x1
  41e216: 83 d3 ff                     	adc	ebx, -0x1
  41e219: 6a 0c                        	push	0xc
  41e21b: 53                           	push	ebx
  41e21c: 50                           	push	eax
  41e21d: e8 4e 0e 67 00               	call	0xa8f070 <.text+0x68e070>
  41e222: 83 fe 0c                     	cmp	esi, 0xc
  41e225: 7e 1e                        	jle	0x41e245 <.text+0x1d245>
  41e227: 8b df                        	mov	ebx, edi
  41e229: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  41e22d: 8b c6                        	mov	eax, esi
  41e22f: 33 c9                        	xor	ecx, ecx
  41e231: 33 d2                        	xor	edx, edx
  41e233: 8d 7c 19 01                  	lea	edi, [ecx + ebx + 0x1]
  41e237: 8d 74 02 f4                  	lea	esi, [edx + eax - 0xc]
  41e23b: 83 c2 f4                     	add	edx, -0xc
  41e23e: 41                           	inc	ecx
  41e23f: 3b 4c 24 08                  	cmp	ecx, dword ptr [esp + 0x8]
  41e243: 72 ee                        	jb	0x41e233 <.text+0x1d233>
  41e245: 8d 47 ff                     	lea	eax, [edi - 0x1]
  41e248: f2 0f 2a f0                  	cvtsi2sd	xmm6, eax
  41e24c: 8b c7                        	mov	eax, edi
  41e24e: 25 03 00 00 80               	and	eax, 0x80000003
  41e253: 7d 07                        	jge	0x41e25c <.text+0x1d25c>
  41e255: 83 e8 01                     	sub	eax, 0x1
  41e258: 83 c8 fc                     	or	eax, -0x4
  41e25b: 40                           	inc	eax
  41e25c: 85 c0                        	test	eax, eax
  41e25e: 75 3c                        	jne	0x41e29c <.text+0x1d29c>
  41e260: b8 1f 85 eb 51               	mov	eax, 0x51eb851f
  41e265: f7 ef                        	imul	edi
  41e267: 8b cf                        	mov	ecx, edi
  41e269: c1 f9 1f                     	sar	ecx, 0x1f
  41e26c: c1 fa 05                     	sar	edx, 0x5
  41e26f: 2b d1                        	sub	edx, ecx
  41e271: 6b da 64                     	imul	ebx, edx, 0x64
  41e274: 8b c7                        	mov	eax, edi
  41e276: 2b c3                        	sub	eax, ebx
  41e278: 75 1b                        	jne	0x41e295 <.text+0x1d295>
  41e27a: b8 1f 85 eb 51               	mov	eax, 0x51eb851f
  41e27f: f7 ef                        	imul	edi
  41e281: 8b cf                        	mov	ecx, edi
  41e283: c1 f9 1f                     	sar	ecx, 0x1f
  41e286: c1 fa 07                     	sar	edx, 0x7
  41e289: 2b d1                        	sub	edx, ecx
  41e28b: 69 da 90 01 00 00            	imul	ebx, edx, 0x190
  41e291: 2b fb                        	sub	edi, ebx
  41e293: 75 07                        	jne	0x41e29c <.text+0x1d29c>
  41e295: b8 01 00 00 00               	mov	eax, 0x1
  41e29a: eb 02                        	jmp	0x41e29e <.text+0x1d29e>
  41e29c: 33 c0                        	xor	eax, eax
  41e29e: f2 0f 10 25 78 98 c2 00      	movsd	xmm4, qword ptr [0xc29878]
  41e2a6: f2 0f 59 e6                  	mulsd	xmm4, xmm6
  41e2aa: f2 0f 10 1d a8 98 c2 00      	movsd	xmm3, qword ptr [0xc298a8]
  41e2b2: f2 0f 10 2d b0 98 c2 00      	movsd	xmm5, qword ptr [0xc298b0]
  41e2ba: 0f 54 dc                     	andps	xmm3, xmm4
  41e2bd: 0f 28 c3                     	movaps	xmm0, xmm3
  41e2c0: f2 0f 10 15 a8 98 c2 00      	movsd	xmm2, qword ptr [0xc298a8]
  41e2c8: 85 c0                        	test	eax, eax
  41e2ca: 66 0f ef c4                  	pxor	xmm0, xmm4
  41e2ce: f2 0f c2 c5 01               	cmpltsd	xmm0, xmm5
  41e2d3: 0f 54 c5                     	andps	xmm0, xmm5
  41e2d6: 0f 56 c3                     	orps	xmm0, xmm3
  41e2d9: 0f 28 f8                     	movaps	xmm7, xmm0
  41e2dc: f2 0f 58 fc                  	addsd	xmm7, xmm4
  41e2e0: f2 0f 5c f8                  	subsd	xmm7, xmm0
  41e2e4: 0f 28 cf                     	movaps	xmm1, xmm7
  41e2e7: f2 0f 5c cc                  	subsd	xmm1, xmm4
  41e2eb: f2 0f c2 cb 06               	cmpnlesd	xmm1, xmm3
  41e2f0: f2 0f 10 25 b8 98 c2 00      	movsd	xmm4, qword ptr [0xc298b8]
  41e2f8: 0f 54 cc                     	andps	xmm1, xmm4
  41e2fb: f2 0f 5c f9                  	subsd	xmm7, xmm1
  41e2ff: 0f 28 ce                     	movaps	xmm1, xmm6
  41e302: f2 0f 5e 35 88 98 c2 00      	divsd	xmm6, qword ptr [0xc29888]
  41e30a: f2 0f 5e 0d 80 98 c2 00      	divsd	xmm1, qword ptr [0xc29880]
  41e312: f2 0f 58 3d 90 98 c2 00      	addsd	xmm7, qword ptr [0xc29890]
  41e31a: 0f 54 d1                     	andps	xmm2, xmm1
  41e31d: 0f 28 c2                     	movaps	xmm0, xmm2
  41e320: 66 0f ef c1                  	pxor	xmm0, xmm1
  41e324: f2 0f c2 c5 01               	cmpltsd	xmm0, xmm5
  41e329: 0f 54 c5                     	andps	xmm0, xmm5
  41e32c: 0f 56 c2                     	orps	xmm0, xmm2
  41e32f: 0f 28 d8                     	movaps	xmm3, xmm0
  41e332: f2 0f 58 d9                  	addsd	xmm3, xmm1
  41e336: f2 0f 5c d8                  	subsd	xmm3, xmm0
  41e33a: 0f 28 c3                     	movaps	xmm0, xmm3
  41e33d: f2 0f 5c c1                  	subsd	xmm0, xmm1
  41e341: f2 0f c2 c2 06               	cmpnlesd	xmm0, xmm2
  41e346: 0f 54 c4                     	andps	xmm0, xmm4
  41e349: f2 0f 5c d8                  	subsd	xmm3, xmm0
  41e34d: f2 0f 5c fb                  	subsd	xmm7, xmm3
  41e351: f2 0f 10 05 a8 98 c2 00      	movsd	xmm0, qword ptr [0xc298a8]
  41e359: 0f 54 c6                     	andps	xmm0, xmm6
  41e35c: 0f 28 d0                     	movaps	xmm2, xmm0
  41e35f: 66 0f ef d6                  	pxor	xmm2, xmm6
  41e363: f2 0f c2 d5 01               	cmpltsd	xmm2, xmm5
  41e368: 0f 54 d5                     	andps	xmm2, xmm5
  41e36b: 0f 56 d0                     	orps	xmm2, xmm0
  41e36e: 0f 28 ca                     	movaps	xmm1, xmm2
  41e371: f2 0f 58 ce                  	addsd	xmm1, xmm6
  41e375: f2 0f 5c ca                  	subsd	xmm1, xmm2
  41e379: 0f 28 e9                     	movaps	xmm5, xmm1
  41e37c: f2 0f 5c ee                  	subsd	xmm5, xmm6
  41e380: f2 0f c2 e8 06               	cmpnlesd	xmm5, xmm0
  41e385: 0f 54 ec                     	andps	xmm5, xmm4
  41e388: f2 0f 5c cd                  	subsd	xmm1, xmm5
  41e38c: f2 0f 58 f9                  	addsd	xmm7, xmm1
  41e390: 74 0b                        	je	0x41e39d <.text+0x1d39d>
  41e392: f2 0f 2a 24 b5 94 9a c2 00   	cvtsi2sd	xmm4, dword ptr [4*esi + 0xc29a94]
  41e39b: eb 09                        	jmp	0x41e3a6 <.text+0x1d3a6>
  41e39d: f2 0f 2a 24 b5 64 9a c2 00   	cvtsi2sd	xmm4, dword ptr [4*esi + 0xc29a64]
  41e3a6: f2 0f 2a 44 24 10            	cvtsi2sd	xmm0, dword ptr [esp + 0x10]
  41e3ac: f2 0f 2a 4c 24 14            	cvtsi2sd	xmm1, dword ptr [esp + 0x14]
  41e3b2: f2 0f 5e 0d a0 98 c2 00      	divsd	xmm1, qword ptr [0xc298a0]
  41e3ba: f2 0f 2a 54 24 18            	cvtsi2sd	xmm2, dword ptr [esp + 0x18]
  41e3c0: f2 0f 5e 15 20 98 c2 00      	divsd	xmm2, qword ptr [0xc29820]
  41e3c8: f2 0f 5c 3d 98 98 c2 00      	subsd	xmm7, qword ptr [0xc29898]
  41e3d0: f2 0f 10 1c 24               	movsd	xmm3, qword ptr [esp]
  41e3d5: f2 0f 5e 1d 28 98 c2 00      	divsd	xmm3, qword ptr [0xc29828]
  41e3dd: f2 0f 58 f8                  	addsd	xmm7, xmm0
  41e3e1: f2 0f 58 f9                  	addsd	xmm7, xmm1
  41e3e5: f2 0f 58 fa                  	addsd	xmm7, xmm2
  41e3e9: f2 0f 58 fb                  	addsd	xmm7, xmm3
  41e3ed: f2 0f 58 fc                  	addsd	xmm7, xmm4
  41e3f1: f2 0f 11 7c 24 08            	movsd	qword ptr [esp + 0x8], xmm7
  41e3f7: dd 44 24 08                  	fld	qword ptr [esp + 0x8]
  41e3fb: 83 c4 1c                     	add	esp, 0x1c
  41e3fe: 5b                           	pop	ebx
  41e3ff: 5e                           	pop	esi
  41e400: 5f                           	pop	edi
  41e401: 8b e5                        	mov	esp, ebp
  41e403: 5d                           	pop	ebp
  41e404: c3                           	ret
  41e405: 8d 74 26 00                  	lea	esi, [esi + eiz]
  41e409: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  41e410: 55                           	push	ebp
  41e411: 8b ec                        	mov	ebp, esp
  41e413: 83 e4 f0                     	and	esp, -0x10
  41e416: 57                           	push	edi
  41e417: 56                           	push	esi
  41e418: 53                           	push	ebx
  41e419: 83 ec 44                     	sub	esp, 0x44
  41e41c: 8b 4d 0c                     	mov	ecx, dword ptr [ebp + 0xc]
  41e41f: f2 0f 10 15 c8 98 c2 00      	movsd	xmm2, qword ptr [0xc298c8]
  41e427: f2 0f 10 2d d0 98 c2 00      	movsd	xmm5, qword ptr [0xc298d0]
  41e42f: f2 0f 10 01                  	movsd	xmm0, qword ptr [ecx]
  41e433: f2 0f 5c 05 c0 98 c2 00      	subsd	xmm0, qword ptr [0xc298c0]
  41e43b: 0f 28 c8                     	movaps	xmm1, xmm0
  41e43e: f2 0f 5e ca                  	divsd	xmm1, xmm2
  41e442: b9 03 00 00 00               	mov	ecx, 0x3
  41e447: f2 0f 2c d9                  	cvttsd2si	ebx, xmm1
  41e44b: f2 0f 2a db                  	cvtsi2sd	xmm3, ebx
  41e44f: f2 0f 59 da                  	mulsd	xmm3, xmm2
  41e453: f2 0f 5c c3                  	subsd	xmm0, xmm3
  41e457: 0f 28 e0                     	movaps	xmm4, xmm0
  41e45a: f2 0f 5e e5                  	divsd	xmm4, xmm5
  41e45e: f2 0f 10 0d d8 98 c2 00      	movsd	xmm1, qword ptr [0xc298d8]
  41e466: f2 0f 2c f4                  	cvttsd2si	esi, xmm4
  41e46a: f2 0f 10 25 e0 98 c2 00      	movsd	xmm4, qword ptr [0xc298e0]
  41e472: 83 fe 04                     	cmp	esi, 0x4
  41e475: 0f 44 f1                     	cmove	esi, ecx
  41e478: 6b fe 64                     	imul	edi, esi, 0x64
  41e47b: f2 0f 2a f6                  	cvtsi2sd	xmm6, esi
  41e47f: f2 0f 59 f5                  	mulsd	xmm6, xmm5
  41e483: f2 0f 5c c6                  	subsd	xmm0, xmm6
  41e487: 0f 28 f8                     	movaps	xmm7, xmm0
  41e48a: f2 0f 5e f9                  	divsd	xmm7, xmm1
  41e48e: f2 0f 2c c7                  	cvttsd2si	eax, xmm7
  41e492: f2 0f 2a d0                  	cvtsi2sd	xmm2, eax
  41e496: f2 0f 59 d1                  	mulsd	xmm2, xmm1
  41e49a: f2 0f 5c c2                  	subsd	xmm0, xmm2
  41e49e: 0f 28 d8                     	movaps	xmm3, xmm0
  41e4a1: f2 0f 5e dc                  	divsd	xmm3, xmm4
  41e4a5: f2 0f 2c d3                  	cvttsd2si	edx, xmm3
  41e4a9: 83 fa 04                     	cmp	edx, 0x4
  41e4ac: 0f 44 d1                     	cmove	edx, ecx
  41e4af: 69 cb 90 01 00 00            	imul	ecx, ebx, 0x190
  41e4b5: f2 0f 2a ea                  	cvtsi2sd	xmm5, edx
  41e4b9: f2 0f 59 ec                  	mulsd	xmm5, xmm4
  41e4bd: 03 cf                        	add	ecx, edi
  41e4bf: 8d 04 81                     	lea	eax, [ecx + 4*eax]
  41e4c2: f2 0f 5c c5                  	subsd	xmm0, xmm5
  41e4c6: 8d 5c 10 01                  	lea	ebx, [eax + edx + 0x1]
  41e4ca: 8b c3                        	mov	eax, ebx
  41e4cc: 25 03 00 00 80               	and	eax, 0x80000003
  41e4d1: 7d 07                        	jge	0x41e4da <.text+0x1d4da>
  41e4d3: 83 e8 01                     	sub	eax, 0x1
  41e4d6: 83 c8 fc                     	or	eax, -0x4
  41e4d9: 40                           	inc	eax
  41e4da: 85 c0                        	test	eax, eax
  41e4dc: 75 3e                        	jne	0x41e51c <.text+0x1d51c>
  41e4de: b8 1f 85 eb 51               	mov	eax, 0x51eb851f
  41e4e3: f7 eb                        	imul	ebx
  41e4e5: 8b cb                        	mov	ecx, ebx
  41e4e7: c1 f9 1f                     	sar	ecx, 0x1f
  41e4ea: c1 fa 05                     	sar	edx, 0x5
  41e4ed: 2b d1                        	sub	edx, ecx
  41e4ef: 6b f2 64                     	imul	esi, edx, 0x64
  41e4f2: 8b fb                        	mov	edi, ebx
  41e4f4: 2b fe                        	sub	edi, esi
  41e4f6: 75 1d                        	jne	0x41e515 <.text+0x1d515>
  41e4f8: b8 1f 85 eb 51               	mov	eax, 0x51eb851f
  41e4fd: f7 eb                        	imul	ebx
  41e4ff: 8b cb                        	mov	ecx, ebx
  41e501: c1 f9 1f                     	sar	ecx, 0x1f
  41e504: c1 fa 07                     	sar	edx, 0x7
  41e507: 2b d1                        	sub	edx, ecx
  41e509: 69 f2 90 01 00 00            	imul	esi, edx, 0x190
  41e50f: 8b fb                        	mov	edi, ebx
  41e511: 2b fe                        	sub	edi, esi
  41e513: 75 07                        	jne	0x41e51c <.text+0x1d51c>
  41e515: be 01 00 00 00               	mov	esi, 0x1
  41e51a: eb 02                        	jmp	0x41e51e <.text+0x1d51e>
  41e51c: 33 f6                        	xor	esi, esi
  41e51e: 66 0f ef c9                  	pxor	xmm1, xmm1
  41e522: 66 0f 2f c8                  	comisd	xmm1, xmm0
  41e526: 76 09                        	jbe	0x41e531 <.text+0x1d531>
  41e528: f2 0f 58 05 e8 98 c2 00      	addsd	xmm0, qword ptr [0xc298e8]
  41e530: 4b                           	dec	ebx
  41e531: f2 0f 10 1d f0 98 c2 00      	movsd	xmm3, qword ptr [0xc298f0]
  41e539: 0f 28 d3                     	movaps	xmm2, xmm3
  41e53c: f2 0f 10 35 f8 98 c2 00      	movsd	xmm6, qword ptr [0xc298f8]
  41e544: 0f 28 ee                     	movaps	xmm5, xmm6
  41e547: f2 0f 2c c8                  	cvttsd2si	ecx, xmm0
  41e54b: f2 0f 2a c9                  	cvtsi2sd	xmm1, ecx
  41e54f: f2 0f 5c c1                  	subsd	xmm0, xmm1
  41e553: f2 0f 59 d0                  	mulsd	xmm2, xmm0
  41e557: f2 0f 2c d2                  	cvttsd2si	edx, xmm2
  41e55b: f2 0f 2a e2                  	cvtsi2sd	xmm4, edx
  41e55f: f2 0f 5e e3                  	divsd	xmm4, xmm3
  41e563: f2 0f 5c c4                  	subsd	xmm0, xmm4
  41e567: f2 0f 59 e8                  	mulsd	xmm5, xmm0
  41e56b: f2 0f 2c c5                  	cvttsd2si	eax, xmm5
  41e56f: f2 0f 2a f8                  	cvtsi2sd	xmm7, eax
  41e573: f2 0f 5e fe                  	divsd	xmm7, xmm6
  41e577: 89 44 24 30                  	mov	dword ptr [esp + 0x30], eax
  41e57b: f2 0f 5c c7                  	subsd	xmm0, xmm7
  41e57f: f2 0f 59 05 00 99 c2 00      	mulsd	xmm0, qword ptr [0xc29900]
  41e587: 0f 28 0d f0 97 c2 00         	movaps	xmm1, xmmword ptr [0xc297f0]
  41e58e: 0f 29 0c 24                  	movaps	xmmword ptr [esp], xmm1
  41e592: 0f 28 15 00 98 c2 00         	movaps	xmm2, xmmword ptr [0xc29800]
  41e599: 0f 29 54 24 10               	movaps	xmmword ptr [esp + 0x10], xmm2
  41e59e: 0f 28 1d 10 98 c2 00         	movaps	xmm3, xmmword ptr [0xc29810]
  41e5a5: 0f 29 5c 24 20               	movaps	xmmword ptr [esp + 0x20], xmm3
  41e5aa: 89 5c 24 34                  	mov	dword ptr [esp + 0x34], ebx
  41e5ae: b8 01 00 00 00               	mov	eax, 0x1
  41e5b3: 33 ff                        	xor	edi, edi
  41e5b5: 83 ff 01                     	cmp	edi, 0x1
  41e5b8: 74 55                        	je	0x41e60f <.text+0x1d60f>
  41e5ba: 8b 1c bc                     	mov	ebx, dword ptr [esp + 4*edi]
  41e5bd: 3b cb                        	cmp	ecx, ebx
  41e5bf: 7c 09                        	jl	0x41e5ca <.text+0x1d5ca>
  41e5c1: 2b cb                        	sub	ecx, ebx
  41e5c3: 40                           	inc	eax
  41e5c4: 47                           	inc	edi
  41e5c5: 83 ff 0c                     	cmp	edi, 0xc
  41e5c8: 7c eb                        	jl	0x41e5b5 <.text+0x1d5b5>
  41e5ca: 8b 5c 24 34                  	mov	ebx, dword ptr [esp + 0x34]
  41e5ce: 8b 75 08                     	mov	esi, dword ptr [ebp + 0x8]
  41e5d1: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  41e5d7: 89 1c 24                     	mov	dword ptr [esp], ebx
  41e5da: 88 44 24 04                  	mov	byte ptr [esp + 0x4], al
  41e5de: 8b c6                        	mov	eax, esi
  41e5e0: 88 54 24 06                  	mov	byte ptr [esp + 0x6], dl
  41e5e4: 41                           	inc	ecx
  41e5e5: 8b 54 24 30                  	mov	edx, dword ptr [esp + 0x30]
  41e5e9: 88 4c 24 05                  	mov	byte ptr [esp + 0x5], cl
  41e5ed: 88 54 24 07                  	mov	byte ptr [esp + 0x7], dl
  41e5f1: f2 0f 10 04 24               	movsd	xmm0, qword ptr [esp]
  41e5f6: f2 0f 11 06                  	movsd	qword ptr [esi], xmm0
  41e5fa: f2 0f 10 4c 24 08            	movsd	xmm1, qword ptr [esp + 0x8]
  41e600: f2 0f 11 4e 08               	movsd	qword ptr [esi + 0x8], xmm1
  41e605: 83 c4 44                     	add	esp, 0x44
  41e608: 5b                           	pop	ebx
  41e609: 5e                           	pop	esi
  41e60a: 5f                           	pop	edi
  41e60b: 8b e5                        	mov	esp, ebp
  41e60d: 5d                           	pop	ebp
  41e60e: c3                           	ret
  41e60f: 85 f6                        	test	esi, esi
  41e611: 74 a7                        	je	0x41e5ba <.text+0x1d5ba>
  41e613: bb 1d 00 00 00               	mov	ebx, 0x1d
  41e618: eb a3                        	jmp	0x41e5bd <.text+0x1d5bd>
  41e61a: 8d b6 00 00 00 00            	lea	esi, [esi]
  41e620: 55                           	push	ebp
  41e621: 8b ec                        	mov	ebp, esp
  41e623: 83 e4 f8                     	and	esp, -0x8
  41e626: 57                           	push	edi
  41e627: 56                           	push	esi
  41e628: 53                           	push	ebx
  41e629: 83 ec 2c                     	sub	esp, 0x2c
  41e62c: 8d 04 24                     	lea	eax, [esp]
  41e62f: 50                           	push	eax
  41e630: ff 15 a0 51 c2 00            	call	dword ptr [0xc251a0]
  41e636: 0f b7 1c 24                  	movzx	ebx, word ptr [esp]
  41e63a: 0f be 7c 24 02               	movsx	edi, byte ptr [esp + 0x2]
  41e63f: 0f be 74 24 06               	movsx	esi, byte ptr [esp + 0x6]
  41e644: 0f be 54 24 08               	movsx	edx, byte ptr [esp + 0x8]
  41e649: 0f be 4c 24 0a               	movsx	ecx, byte ptr [esp + 0xa]
  41e64e: 0f b7 44 24 0c               	movzx	eax, word ptr [esp + 0xc]
  41e653: f2 0f 2a c8                  	cvtsi2sd	xmm1, eax
  41e657: 89 5c 24 18                  	mov	dword ptr [esp + 0x18], ebx
  41e65b: 8b c7                        	mov	eax, edi
  41e65d: 89 74 24 20                  	mov	dword ptr [esp + 0x20], esi
  41e661: 0f b7 74 24 0e               	movzx	esi, word ptr [esp + 0xe]
  41e666: f2 0f 2a c6                  	cvtsi2sd	xmm0, esi
  41e66a: f2 0f 59 05 08 99 c2 00      	mulsd	xmm0, qword ptr [0xc29908]
  41e672: f2 0f 58 c8                  	addsd	xmm1, xmm0
  41e676: f2 0f 11 4c 24 10            	movsd	qword ptr [esp + 0x10], xmm1
  41e67c: 89 54 24 24                  	mov	dword ptr [esp + 0x24], edx
  41e680: 99                           	cdq
  41e681: b8 0c 00 00 00               	mov	eax, 0xc
  41e686: 33 f6                        	xor	esi, esi
  41e688: 2b c7                        	sub	eax, edi
  41e68a: 89 4c 24 28                  	mov	dword ptr [esp + 0x28], ecx
  41e68e: 89 5c 24 1c                  	mov	dword ptr [esp + 0x1c], ebx
  41e692: 8b df                        	mov	ebx, edi
  41e694: b9 00 00 00 00               	mov	ecx, 0x0
  41e699: 1b f2                        	sbb	esi, edx
  41e69b: 51                           	push	ecx
  41e69c: 6a 0c                        	push	0xc
  41e69e: 56                           	push	esi
  41e69f: 50                           	push	eax
  41e6a0: 8b 74 24 2c                  	mov	esi, dword ptr [esp + 0x2c]
  41e6a4: e8 c7 09 67 00               	call	0xa8f070 <.text+0x68e070>
  41e6a9: 85 ff                        	test	edi, edi
  41e6ab: 7f 26                        	jg	0x41e6d3 <.text+0x1d6d3>
  41e6ad: 89 44 24 1c                  	mov	dword ptr [esp + 0x1c], eax
  41e6b1: 8b 44 24 18                  	mov	eax, dword ptr [esp + 0x18]
  41e6b5: 33 c9                        	xor	ecx, ecx
  41e6b7: 33 d2                        	xor	edx, edx
  41e6b9: 8d 74 02 ff                  	lea	esi, [edx + eax - 0x1]
  41e6bd: 8d 1c cd 00 00 00 00         	lea	ebx, [8*ecx]
  41e6c4: 8d 1c 8b                     	lea	ebx, [ebx + 4*ecx]
  41e6c7: 8d 5c 3b 0c                  	lea	ebx, [ebx + edi + 0xc]
  41e6cb: 4a                           	dec	edx
  41e6cc: 41                           	inc	ecx
  41e6cd: 3b 4c 24 1c                  	cmp	ecx, dword ptr [esp + 0x1c]
  41e6d1: 72 e6                        	jb	0x41e6b9 <.text+0x1d6b9>
  41e6d3: 6a 00                        	push	0x0
  41e6d5: 8b fb                        	mov	edi, ebx
  41e6d7: 8b c3                        	mov	eax, ebx
  41e6d9: 99                           	cdq
  41e6da: 6a 0c                        	push	0xc
  41e6dc: 8b cb                        	mov	ecx, ebx
  41e6de: 83 c1 ff                     	add	ecx, -0x1
  41e6e1: 83 d2 ff                     	adc	edx, -0x1
  41e6e4: 52                           	push	edx
  41e6e5: 51                           	push	ecx
  41e6e6: e8 85 09 67 00               	call	0xa8f070 <.text+0x68e070>
  41e6eb: 83 fb 0c                     	cmp	ebx, 0xc
  41e6ee: 7e 1c                        	jle	0x41e70c <.text+0x1d70c>
  41e6f0: 89 44 24 18                  	mov	dword ptr [esp + 0x18], eax
  41e6f4: 8b c6                        	mov	eax, esi
  41e6f6: 33 c9                        	xor	ecx, ecx
  41e6f8: 33 d2                        	xor	edx, edx
  41e6fa: 8d 74 01 01                  	lea	esi, [ecx + eax + 0x1]
  41e6fe: 8d 5c 3a f4                  	lea	ebx, [edx + edi - 0xc]
  41e702: 83 c2 f4                     	add	edx, -0xc
  41e705: 41                           	inc	ecx
  41e706: 3b 4c 24 18                  	cmp	ecx, dword ptr [esp + 0x18]
  41e70a: 72 ee                        	jb	0x41e6fa <.text+0x1d6fa>
  41e70c: 8d 46 ff                     	lea	eax, [esi - 0x1]
  41e70f: f2 0f 2a f0                  	cvtsi2sd	xmm6, eax
  41e713: 8b c6                        	mov	eax, esi
  41e715: 25 03 00 00 80               	and	eax, 0x80000003
  41e71a: 7d 07                        	jge	0x41e723 <.text+0x1d723>
  41e71c: 83 e8 01                     	sub	eax, 0x1
  41e71f: 83 c8 fc                     	or	eax, -0x4
  41e722: 40                           	inc	eax
  41e723: 85 c0                        	test	eax, eax
  41e725: 75 3c                        	jne	0x41e763 <.text+0x1d763>
  41e727: b8 1f 85 eb 51               	mov	eax, 0x51eb851f
  41e72c: f7 ee                        	imul	esi
  41e72e: 8b ce                        	mov	ecx, esi
  41e730: c1 f9 1f                     	sar	ecx, 0x1f
  41e733: c1 fa 05                     	sar	edx, 0x5
  41e736: 2b d1                        	sub	edx, ecx
  41e738: 6b fa 64                     	imul	edi, edx, 0x64
  41e73b: 8b c6                        	mov	eax, esi
  41e73d: 2b c7                        	sub	eax, edi
  41e73f: 75 1b                        	jne	0x41e75c <.text+0x1d75c>
  41e741: b8 1f 85 eb 51               	mov	eax, 0x51eb851f
  41e746: f7 ee                        	imul	esi
  41e748: 8b ce                        	mov	ecx, esi
  41e74a: c1 f9 1f                     	sar	ecx, 0x1f
  41e74d: c1 fa 07                     	sar	edx, 0x7
  41e750: 2b d1                        	sub	edx, ecx
  41e752: 69 fa 90 01 00 00            	imul	edi, edx, 0x190
  41e758: 2b f7                        	sub	esi, edi
  41e75a: 75 07                        	jne	0x41e763 <.text+0x1d763>
  41e75c: b8 01 00 00 00               	mov	eax, 0x1
  41e761: eb 02                        	jmp	0x41e765 <.text+0x1d765>
  41e763: 33 c0                        	xor	eax, eax
  41e765: f2 0f 10 25 10 99 c2 00      	movsd	xmm4, qword ptr [0xc29910]
  41e76d: f2 0f 59 e6                  	mulsd	xmm4, xmm6
  41e771: f2 0f 10 1d 40 99 c2 00      	movsd	xmm3, qword ptr [0xc29940]
  41e779: f2 0f 10 2d 48 99 c2 00      	movsd	xmm5, qword ptr [0xc29948]
  41e781: 0f 54 dc                     	andps	xmm3, xmm4
  41e784: 0f 28 c3                     	movaps	xmm0, xmm3
  41e787: f2 0f 10 15 40 99 c2 00      	movsd	xmm2, qword ptr [0xc29940]
  41e78f: 85 c0                        	test	eax, eax
  41e791: 66 0f ef c4                  	pxor	xmm0, xmm4
  41e795: f2 0f c2 c5 01               	cmpltsd	xmm0, xmm5
  41e79a: 0f 54 c5                     	andps	xmm0, xmm5
  41e79d: 0f 56 c3                     	orps	xmm0, xmm3
  41e7a0: 0f 28 f8                     	movaps	xmm7, xmm0
  41e7a3: f2 0f 58 fc                  	addsd	xmm7, xmm4
  41e7a7: f2 0f 5c f8                  	subsd	xmm7, xmm0
  41e7ab: 0f 28 cf                     	movaps	xmm1, xmm7
  41e7ae: f2 0f 5c cc                  	subsd	xmm1, xmm4
  41e7b2: f2 0f c2 cb 06               	cmpnlesd	xmm1, xmm3
  41e7b7: f2 0f 10 25 50 99 c2 00      	movsd	xmm4, qword ptr [0xc29950]
  41e7bf: 0f 54 cc                     	andps	xmm1, xmm4
  41e7c2: f2 0f 5c f9                  	subsd	xmm7, xmm1
  41e7c6: 0f 28 ce                     	movaps	xmm1, xmm6
  41e7c9: f2 0f 5e 35 20 99 c2 00      	divsd	xmm6, qword ptr [0xc29920]
  41e7d1: f2 0f 5e 0d 18 99 c2 00      	divsd	xmm1, qword ptr [0xc29918]
  41e7d9: f2 0f 58 3d 28 99 c2 00      	addsd	xmm7, qword ptr [0xc29928]
  41e7e1: 0f 54 d1                     	andps	xmm2, xmm1
  41e7e4: 0f 28 c2                     	movaps	xmm0, xmm2
  41e7e7: 66 0f ef c1                  	pxor	xmm0, xmm1
  41e7eb: f2 0f c2 c5 01               	cmpltsd	xmm0, xmm5
  41e7f0: 0f 54 c5                     	andps	xmm0, xmm5
  41e7f3: 0f 56 c2                     	orps	xmm0, xmm2
  41e7f6: 0f 28 d8                     	movaps	xmm3, xmm0
  41e7f9: f2 0f 58 d9                  	addsd	xmm3, xmm1
  41e7fd: f2 0f 5c d8                  	subsd	xmm3, xmm0
