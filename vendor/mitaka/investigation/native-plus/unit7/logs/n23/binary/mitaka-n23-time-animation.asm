
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5ec120: 53                           	push	ebx
  5ec121: 8b dc                        	mov	ebx, esp
  5ec123: 83 e4 c0                     	and	esp, -0x40
  5ec126: 55                           	push	ebp
  5ec127: 55                           	push	ebp
  5ec128: 8b 6b 04                     	mov	ebp, dword ptr [ebx + 0x4]
  5ec12b: 89 6c 24 04                  	mov	dword ptr [esp + 0x4], ebp
  5ec12f: 8b ec                        	mov	ebp, esp
  5ec131: 6a ff                        	push	-0x1
  5ec133: 68 40 d8 bf 00               	push	0xbfd840
  5ec138: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  5ec13e: 50                           	push	eax
  5ec13f: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  5ec146: 83 ec 2c                     	sub	esp, 0x2c
  5ec149: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  5ec14c: 89 7d d0                     	mov	dword ptr [ebp - 0x30], edi
  5ec14f: 89 75 d4                     	mov	dword ptr [ebp - 0x2c], esi
  5ec152: 89 4d d8                     	mov	dword ptr [ebp - 0x28], ecx
  5ec155: e8 96 02 fb ff               	call	0x59c3f0 <.text+0x19b3f0>
  5ec15a: dd 5d c8                     	fstp	qword ptr [ebp - 0x38]
  5ec15d: f2 0f 10 4d c8               	movsd	xmm1, qword ptr [ebp - 0x38]
  5ec162: f2 0f 10 43 08               	movsd	xmm0, qword ptr [ebx + 0x8]
  5ec167: 66 0f 2e c1                  	ucomisd	xmm0, xmm1
  5ec16b: 7a 06                        	jp	0x5ec173 <.text+0x1eb173>
  5ec16d: 0f 84 34 01 00 00            	je	0x5ec2a7 <.text+0x1eb2a7>
  5ec173: 0f b6 43 18                  	movzx	eax, byte ptr [ebx + 0x18]
  5ec177: 85 c0                        	test	eax, eax
  5ec179: 74 60                        	je	0x5ec1db <.text+0x1eb1db>
  5ec17b: c7 45 fc 02 00 00 00         	mov	dword ptr [ebp - 0x4], 0x2
  5ec182: c7 45 c8 00 00 00 00         	mov	dword ptr [ebp - 0x38], 0x0
  5ec189: 50                           	push	eax
  5ec18a: c7 04 24 40 00 00 00         	mov	dword ptr [esp], 0x40
  5ec191: e8 74 2e 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5ec196: 59                           	pop	ecx
  5ec197: 8b f8                        	mov	edi, eax
  5ec199: 89 7d cc                     	mov	dword ptr [ebp - 0x34], edi
  5ec19c: 85 ff                        	test	edi, edi
  5ec19e: 74 37                        	je	0x5ec1d7 <.text+0x1eb1d7>
  5ec1a0: f2 0f 10 43 08               	movsd	xmm0, qword ptr [ebx + 0x8]
  5ec1a5: f2 0f 10 4b 10               	movsd	xmm1, qword ptr [ebx + 0x10]
  5ec1aa: c7 45 c8 01 00 00 00         	mov	dword ptr [ebp - 0x38], 0x1
  5ec1b1: 83 c4 ec                     	add	esp, -0x14
  5ec1b4: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  5ec1b9: f2 0f 11 4c 24 08            	movsd	qword ptr [esp + 0x8], xmm1
  5ec1bf: 8b cf                        	mov	ecx, edi
  5ec1c1: c7 44 24 10 00 00 00 00      	mov	dword ptr [esp + 0x10], 0x0
  5ec1c9: e8 c2 38 1d 00               	call	0x7bfa90 <.text+0x3bea90>
  5ec1ce: c7 45 c8 00 00 00 00         	mov	dword ptr [ebp - 0x38], 0x0
  5ec1d5: eb 62                        	jmp	0x5ec239 <.text+0x1eb239>
  5ec1d7: 33 ff                        	xor	edi, edi
  5ec1d9: eb 5e                        	jmp	0x5ec239 <.text+0x1eb239>
  5ec1db: c7 45 fc 01 00 00 00         	mov	dword ptr [ebp - 0x4], 0x1
  5ec1e2: c7 45 c8 00 00 00 00         	mov	dword ptr [ebp - 0x38], 0x0
  5ec1e9: 50                           	push	eax
  5ec1ea: c7 04 24 40 00 00 00         	mov	dword ptr [esp], 0x40
  5ec1f1: e8 14 2e 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5ec1f6: 59                           	pop	ecx
  5ec1f7: 8b f8                        	mov	edi, eax
  5ec1f9: 89 7d cc                     	mov	dword ptr [ebp - 0x34], edi
  5ec1fc: 85 ff                        	test	edi, edi
  5ec1fe: 74 37                        	je	0x5ec237 <.text+0x1eb237>
  5ec200: f2 0f 10 43 08               	movsd	xmm0, qword ptr [ebx + 0x8]
  5ec205: f2 0f 10 4b 10               	movsd	xmm1, qword ptr [ebx + 0x10]
  5ec20a: c7 45 c8 01 00 00 00         	mov	dword ptr [ebp - 0x38], 0x1
  5ec211: 83 c4 ec                     	add	esp, -0x14
  5ec214: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  5ec219: f2 0f 11 4c 24 08            	movsd	qword ptr [esp + 0x8], xmm1
  5ec21f: 8b cf                        	mov	ecx, edi
  5ec221: c7 44 24 10 00 00 00 00      	mov	dword ptr [esp + 0x10], 0x0
  5ec229: e8 22 3a 1d 00               	call	0x7bfc50 <.text+0x3bec50>
  5ec22e: c7 45 c8 00 00 00 00         	mov	dword ptr [ebp - 0x38], 0x0
  5ec235: eb 02                        	jmp	0x5ec239 <.text+0x1eb239>
  5ec237: 33 ff                        	xor	edi, edi
  5ec239: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5ec240: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  5ec247: c7 45 c8 00 00 00 00         	mov	dword ptr [ebp - 0x38], 0x0
  5ec24e: 50                           	push	eax
  5ec24f: c7 04 24 18 00 00 00         	mov	dword ptr [esp], 0x18
  5ec256: e8 af 2d 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5ec25b: 59                           	pop	ecx
  5ec25c: 8b f0                        	mov	esi, eax
  5ec25e: 89 75 cc                     	mov	dword ptr [ebp - 0x34], esi
  5ec261: 85 f6                        	test	esi, esi
  5ec263: 74 23                        	je	0x5ec288 <.text+0x1eb288>
  5ec265: 8b 45 d8                     	mov	eax, dword ptr [ebp - 0x28]
  5ec268: c7 06 a8 29 2d 01            	mov	dword ptr [esi], 0x12d29a8
  5ec26e: 89 46 04                     	mov	dword ptr [esi + 0x4], eax
  5ec271: 33 d2                        	xor	edx, edx
  5ec273: c7 46 14 40 c0 5e 00         	mov	dword ptr [esi + 0x14], 0x5ec040
  5ec27a: 89 55 c8                     	mov	dword ptr [ebp - 0x38], edx
  5ec27d: 89 56 08                     	mov	dword ptr [esi + 0x8], edx
  5ec280: 89 56 0c                     	mov	dword ptr [esi + 0xc], edx
  5ec283: 89 56 10                     	mov	dword ptr [esi + 0x10], edx
  5ec286: eb 02                        	jmp	0x5ec28a <.text+0x1eb28a>
  5ec288: 33 f6                        	xor	esi, esi
  5ec28a: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5ec291: e8 5a 01 fb ff               	call	0x59c3f0 <.text+0x19b3f0>
  5ec296: 8b 07                        	mov	eax, dword ptr [edi]
  5ec298: 83 c4 f4                     	add	esp, -0xc
  5ec29b: dd 5c 24 04                  	fstp	qword ptr [esp + 0x4]
  5ec29f: 8b cf                        	mov	ecx, edi
  5ec2a1: 89 34 24                     	mov	dword ptr [esp], esi
  5ec2a4: ff 50 0c                     	call	dword ptr [eax + 0xc]
  5ec2a7: 8b 7d d0                     	mov	edi, dword ptr [ebp - 0x30]
  5ec2aa: 8b 75 d4                     	mov	esi, dword ptr [ebp - 0x2c]
  5ec2ad: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  5ec2b0: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  5ec2b7: 8b e5                        	mov	esp, ebp
  5ec2b9: 5d                           	pop	ebp
  5ec2ba: 8b e3                        	mov	esp, ebx
  5ec2bc: 5b                           	pop	ebx
  5ec2bd: c2 14 00                     	ret	0x14
  5ec2c0: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5ec2c3: 83 7d c8 00                  	cmp	dword ptr [ebp - 0x38], 0x0
  5ec2c7: 0f 84 65 15 61 00            	je	0xbfd832
  5ec2cd: ff 75 cc                     	push	dword ptr [ebp - 0x34]
  5ec2d0: e8 bd 2c 4a 00               	call	0xa8ef92 <.text+0x68df92>
  5ec2d5: 59                           	pop	ecx
  5ec2d6: e9 57 15 61 00               	jmp	0xbfd832
  5ec2db: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5ec2de: 83 7d c8 00                  	cmp	dword ptr [ebp - 0x38], 0x0
  5ec2e2: 0f 84 4a 15 61 00            	je	0xbfd832
  5ec2e8: ff 75 cc                     	push	dword ptr [ebp - 0x34]
  5ec2eb: e8 a2 2c 4a 00               	call	0xa8ef92 <.text+0x68df92>
  5ec2f0: 59                           	pop	ecx
  5ec2f1: e9 3c 15 61 00               	jmp	0xbfd832
  5ec2f6: 90                           	nop
  5ec2f7: 90                           	nop
  5ec2f8: 90                           	nop
  5ec2f9: 90                           	nop
  5ec2fa: 90                           	nop
  5ec2fb: 90                           	nop
  5ec2fc: 90                           	nop
  5ec2fd: 90                           	nop
  5ec2fe: 90                           	nop
  5ec2ff: 90                           	nop
  5ec300: 55                           	push	ebp
  5ec301: 8b ec                        	mov	ebp, esp
  5ec303: 6a ff                        	push	-0x1
  5ec305: 68 60 d8 bf 00               	push	0xbfd860
  5ec30a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  5ec310: 50                           	push	eax
  5ec311: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  5ec318: 83 ec 18                     	sub	esp, 0x18
  5ec31b: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  5ec31e: 89 7d e4                     	mov	dword ptr [ebp - 0x1c], edi
  5ec321: 89 75 e8                     	mov	dword ptr [ebp - 0x18], esi
  5ec324: 8b f9                        	mov	edi, ecx
  5ec326: 8b 75 08                     	mov	esi, dword ptr [ebp + 0x8]
  5ec329: 85 f6                        	test	esi, esi
  5ec32b: 74 64                        	je	0x5ec391 <.text+0x1eb391>
  5ec32d: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  5ec334: c7 45 dc 00 00 00 00         	mov	dword ptr [ebp - 0x24], 0x0
  5ec33b: 50                           	push	eax
  5ec33c: c7 04 24 18 00 00 00         	mov	dword ptr [esp], 0x18
  5ec343: e8 c2 2c 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5ec348: 59                           	pop	ecx
  5ec349: 8b d8                        	mov	ebx, eax
  5ec34b: 89 5d e0                     	mov	dword ptr [ebp - 0x20], ebx
  5ec34e: 85 db                        	test	ebx, ebx
  5ec350: 74 20                        	je	0x5ec372 <.text+0x1eb372>
  5ec352: c7 03 a8 29 2d 01            	mov	dword ptr [ebx], 0x12d29a8
  5ec358: 89 7b 04                     	mov	dword ptr [ebx + 0x4], edi
  5ec35b: 33 c0                        	xor	eax, eax
  5ec35d: 89 43 08                     	mov	dword ptr [ebx + 0x8], eax
  5ec360: c7 43 14 40 c0 5e 00         	mov	dword ptr [ebx + 0x14], 0x5ec040
  5ec367: 89 45 dc                     	mov	dword ptr [ebp - 0x24], eax
  5ec36a: 89 43 0c                     	mov	dword ptr [ebx + 0xc], eax
  5ec36d: 89 43 10                     	mov	dword ptr [ebx + 0x10], eax
  5ec370: eb 02                        	jmp	0x5ec374 <.text+0x1eb374>
  5ec372: 33 db                        	xor	ebx, ebx
  5ec374: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5ec37b: e8 70 00 fb ff               	call	0x59c3f0 <.text+0x19b3f0>
  5ec380: 8b 06                        	mov	eax, dword ptr [esi]
  5ec382: 83 c4 f4                     	add	esp, -0xc
  5ec385: dd 5c 24 04                  	fstp	qword ptr [esp + 0x4]
  5ec389: 8b ce                        	mov	ecx, esi
  5ec38b: 89 1c 24                     	mov	dword ptr [esp], ebx
  5ec38e: ff 50 0c                     	call	dword ptr [eax + 0xc]
  5ec391: 8b 7d e4                     	mov	edi, dword ptr [ebp - 0x1c]
  5ec394: 8b 75 e8                     	mov	esi, dword ptr [ebp - 0x18]
  5ec397: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5ec39a: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  5ec39d: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  5ec3a4: 8b e5                        	mov	esp, ebp
  5ec3a6: 5d                           	pop	ebp
  5ec3a7: c2 04 00                     	ret	0x4
  5ec3aa: 90                           	nop
  5ec3ab: 90                           	nop
  5ec3ac: 90                           	nop
  5ec3ad: 90                           	nop
  5ec3ae: 90                           	nop
  5ec3af: 90                           	nop
