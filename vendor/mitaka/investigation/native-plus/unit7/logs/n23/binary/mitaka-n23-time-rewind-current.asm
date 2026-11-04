
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5ea326: 56                           	push	esi
  5ea327: e8 54 3e e3 ff               	call	0x41e180 <.text+0x1d180>
  5ea32c: dd 9d 48 ff ff ff            	fstp	qword ptr [ebp - 0xb8]
  5ea332: f2 0f 10 85 48 ff ff ff      	movsd	xmm0, qword ptr [ebp - 0xb8]
  5ea33a: 8d 45 c0                     	lea	eax, [ebp - 0x40]
  5ea33d: 50                           	push	eax
  5ea33e: 66 0f ef c9                  	pxor	xmm1, xmm1
  5ea342: f2 0f 5c 0d c0 90 fe 00      	subsd	xmm1, qword ptr [0xfe90c0]
  5ea34a: f2 0f 58 c8                  	addsd	xmm1, xmm0
  5ea34e: f2 0f 11 4d c0               	movsd	qword ptr [ebp - 0x40], xmm1
  5ea353: e8 38 cc e9 ff               	call	0x486f90 <.text+0x85f90>
  5ea358: e9 15 fa ff ff               	jmp	0x5e9d72 <.text+0x1e8d72>
  5ea35d: 90                           	nop
  5ea35e: 90                           	nop
  5ea35f: 90                           	nop
  5ea360: 55                           	push	ebp
  5ea361: 8b ec                        	mov	ebp, esp
  5ea363: 6a ff                        	push	-0x1
  5ea365: 68 90 d7 bf 00               	push	0xbfd790
  5ea36a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  5ea370: 50                           	push	eax
  5ea371: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  5ea378: 81 ec 98 00 00 00            	sub	esp, 0x98
  5ea37e: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
  5ea381: 89 5d e8                     	mov	dword ptr [ebp - 0x18], ebx
  5ea384: 89 7d e0                     	mov	dword ptr [ebp - 0x20], edi
  5ea387: 89 75 e4                     	mov	dword ptr [ebp - 0x1c], esi
  5ea38a: a1 10 53 d8 00               	mov	eax, dword ptr [0xd85310]
  5ea38f: 89 4d 9c                     	mov	dword ptr [ebp - 0x64], ecx
  5ea392: 89 45 ec                     	mov	dword ptr [ebp - 0x14], eax
  5ea395: 8d 5d d0                     	lea	ebx, [ebp - 0x30]
  5ea398: 53                           	push	ebx
  5ea399: ff 15 70 56 c2 00            	call	dword ptr [0xc25670]
  5ea39f: 53                           	push	ebx
  5ea3a0: ff 15 dc 56 c2 00            	call	dword ptr [0xc256dc]
  5ea3a6: 6a 00                        	push	0x0
  5ea3a8: 8b 70 14                     	mov	esi, dword ptr [eax + 0x14]
  5ea3ab: 81 c6 6c 07 00 00            	add	esi, 0x76c
  5ea3b1: 89 75 c0                     	mov	dword ptr [ebp - 0x40], esi
  5ea3b4: 8b 50 10                     	mov	edx, dword ptr [eax + 0x10]
  5ea3b7: 42                           	inc	edx
  5ea3b8: 88 55 c4                     	mov	byte ptr [ebp - 0x3c], dl
  5ea3bb: 8b 48 0c                     	mov	ecx, dword ptr [eax + 0xc]
  5ea3be: 88 4d c5                     	mov	byte ptr [ebp - 0x3b], cl
  5ea3c1: 8b 58 08                     	mov	ebx, dword ptr [eax + 0x8]
  5ea3c4: 88 5d c6                     	mov	byte ptr [ebp - 0x3a], bl
  5ea3c7: 8b 50 04                     	mov	edx, dword ptr [eax + 0x4]
  5ea3ca: 88 55 c7                     	mov	byte ptr [ebp - 0x39], dl
  5ea3cd: f2 0f 2a 00                  	cvtsi2sd	xmm0, dword ptr [eax]
  5ea3d1: f2 0f 11 45 c8               	movsd	qword ptr [ebp - 0x38], xmm0
  5ea3d6: e8 e5 ac e9 ff               	call	0x4850c0 <.text+0x840c0>
  5ea3db: 8d 45 c0                     	lea	eax, [ebp - 0x40]
  5ea3de: 50                           	push	eax
  5ea3df: e8 9c 3d e3 ff               	call	0x41e180 <.text+0x1d180>
  5ea3e4: dd 5d d8                     	fstp	qword ptr [ebp - 0x28]
  5ea3e7: 8d 45 d8                     	lea	eax, [ebp - 0x28]
  5ea3ea: 50                           	push	eax
  5ea3eb: e8 a0 cb e9 ff               	call	0x486f90 <.text+0x85f90>
  5ea3f0: 83 c4 14                     	add	esp, 0x14
  5ea3f3: e8 c8 be fd ff               	call	0x5c62c0 <.text+0x1c52c0>
  5ea3f8: 8b c8                        	mov	ecx, eax
  5ea3fa: e8 e1 bf fd ff               	call	0x5c63e0 <.text+0x1c53e0>
  5ea3ff: 0f b6 c0                     	movzx	eax, al
  5ea402: 85 c0                        	test	eax, eax
  5ea404: 74 13                        	je	0x5ea419 <.text+0x1e9419>
  5ea406: e8 b5 be fd ff               	call	0x5c62c0 <.text+0x1c52c0>
  5ea40b: 8b c8                        	mov	ecx, eax
  5ea40d: e8 5e c4 fd ff               	call	0x5c6870 <.text+0x1c5870>
  5ea412: 0f b6 c0                     	movzx	eax, al
  5ea415: 85 c0                        	test	eax, eax
  5ea417: 74 2b                        	je	0x5ea444 <.text+0x1e9444>
  5ea419: e8 52 e0 fe ff               	call	0x5d8470 <.text+0x1d7470>
  5ea41e: 8b c8                        	mov	ecx, eax
  5ea420: e8 bb e7 fe ff               	call	0x5d8be0 <.text+0x1d7be0>
  5ea425: 8b 4d ec                     	mov	ecx, dword ptr [ebp - 0x14]
  5ea428: e8 93 4a 4a 00               	call	0xa8eec0 <.text+0x68dec0>
  5ea42d: 8b 7d e0                     	mov	edi, dword ptr [ebp - 0x20]
  5ea430: 8b 75 e4                     	mov	esi, dword ptr [ebp - 0x1c]
  5ea433: 8b 5d e8                     	mov	ebx, dword ptr [ebp - 0x18]
  5ea436: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  5ea439: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
