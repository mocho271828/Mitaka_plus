
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5ea930: 56                           	push	esi
  5ea931: 83 ec 30                     	sub	esp, 0x30
  5ea934: 8d 74 24 20                  	lea	esi, [esp + 0x20]
  5ea938: 56                           	push	esi
  5ea939: ff 15 70 56 c2 00            	call	dword ptr [0xc25670]
  5ea93f: 56                           	push	esi
  5ea940: ff 15 dc 56 c2 00            	call	dword ptr [0xc256dc]
  5ea946: 8b 70 14                     	mov	esi, dword ptr [eax + 0x14]
  5ea949: 81 c6 6c 07 00 00            	add	esi, 0x76c
  5ea94f: 89 74 24 08                  	mov	dword ptr [esp + 0x8], esi
  5ea953: 8b 50 10                     	mov	edx, dword ptr [eax + 0x10]
  5ea956: 42                           	inc	edx
  5ea957: 88 54 24 0c                  	mov	byte ptr [esp + 0xc], dl
  5ea95b: 8b 48 0c                     	mov	ecx, dword ptr [eax + 0xc]
  5ea95e: 88 4c 24 0d                  	mov	byte ptr [esp + 0xd], cl
  5ea962: 8b 50 08                     	mov	edx, dword ptr [eax + 0x8]
  5ea965: 88 54 24 0e                  	mov	byte ptr [esp + 0xe], dl
  5ea969: 8b 48 04                     	mov	ecx, dword ptr [eax + 0x4]
  5ea96c: 88 4c 24 0f                  	mov	byte ptr [esp + 0xf], cl
  5ea970: f2 0f 2a 00                  	cvtsi2sd	xmm0, dword ptr [eax]
  5ea974: 8d 44 24 08                  	lea	eax, [esp + 0x8]
  5ea978: f2 0f 11 44 24 10            	movsd	qword ptr [esp + 0x10], xmm0
  5ea97e: 50                           	push	eax
  5ea97f: e8 fc 37 e3 ff               	call	0x41e180 <.text+0x1d180>
  5ea984: dd 5c 24 34                  	fstp	qword ptr [esp + 0x34]
  5ea988: 8d 54 24 1c                  	lea	edx, [esp + 0x1c]
  5ea98c: 8d 44 24 34                  	lea	eax, [esp + 0x34]
  5ea990: 50                           	push	eax
  5ea991: 52                           	push	edx
  5ea992: e8 79 3a e3 ff               	call	0x41e410 <.text+0x1d410>
  5ea997: 83 c4 14                     	add	esp, 0x14
  5ea99a: 8b 54 24 40                  	mov	edx, dword ptr [esp + 0x40]
  5ea99e: 8b 44 24 3c                  	mov	eax, dword ptr [esp + 0x3c]
  5ea9a2: 8b 74 24 38                  	mov	esi, dword ptr [esp + 0x38]
  5ea9a6: 8b 4c 24 10                  	mov	ecx, dword ptr [esp + 0x10]
  5ea9aa: 89 0e                        	mov	dword ptr [esi], ecx
  5ea9ac: 0f be 4c 24 14               	movsx	ecx, byte ptr [esp + 0x14]
  5ea9b1: 8b 74 24 44                  	mov	esi, dword ptr [esp + 0x44]
  5ea9b5: 89 08                        	mov	dword ptr [eax], ecx
  5ea9b7: 0f be 44 24 15               	movsx	eax, byte ptr [esp + 0x15]
  5ea9bc: f2 0f 2c 4c 24 18            	cvttsd2si	ecx, qword ptr [esp + 0x18]
  5ea9c2: 89 02                        	mov	dword ptr [edx], eax
  5ea9c4: 0f be 54 24 16               	movsx	edx, byte ptr [esp + 0x16]
  5ea9c9: 0f be 44 24 17               	movsx	eax, byte ptr [esp + 0x17]
  5ea9ce: 89 16                        	mov	dword ptr [esi], edx
  5ea9d0: 8b 54 24 48                  	mov	edx, dword ptr [esp + 0x48]
  5ea9d4: 8b 74 24 4c                  	mov	esi, dword ptr [esp + 0x4c]
  5ea9d8: 89 02                        	mov	dword ptr [edx], eax
  5ea9da: 89 0e                        	mov	dword ptr [esi], ecx
  5ea9dc: 83 c4 30                     	add	esp, 0x30
  5ea9df: 5e                           	pop	esi
  5ea9e0: c2 18 00                     	ret	0x18
  5ea9e3: 8d b6 00 00 00 00            	lea	esi, [esi]
  5ea9e9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  5ea9f0: 57                           	push	edi
  5ea9f1: 83 ec 38                     	sub	esp, 0x38
  5ea9f4: 8d 7c 24 20                  	lea	edi, [esp + 0x20]
  5ea9f8: 57                           	push	edi
  5ea9f9: ff 15 70 56 c2 00            	call	dword ptr [0xc25670]
  5ea9ff: 57                           	push	edi
  5eaa00: ff 15 dc 56 c2 00            	call	dword ptr [0xc256dc]
  5eaa06: 8b 78 14                     	mov	edi, dword ptr [eax + 0x14]
  5eaa09: 81 c7 6c 07 00 00            	add	edi, 0x76c
  5eaa0f: 89 7c 24 08                  	mov	dword ptr [esp + 0x8], edi
  5eaa13: 8b 50 10                     	mov	edx, dword ptr [eax + 0x10]
  5eaa16: 42                           	inc	edx
  5eaa17: 88 54 24 0c                  	mov	byte ptr [esp + 0xc], dl
  5eaa1b: 8b 48 0c                     	mov	ecx, dword ptr [eax + 0xc]
  5eaa1e: 88 4c 24 0d                  	mov	byte ptr [esp + 0xd], cl
  5eaa22: 8b 50 08                     	mov	edx, dword ptr [eax + 0x8]
  5eaa25: 88 54 24 0e                  	mov	byte ptr [esp + 0xe], dl
  5eaa29: 8b 48 04                     	mov	ecx, dword ptr [eax + 0x4]
  5eaa2c: 88 4c 24 0f                  	mov	byte ptr [esp + 0xf], cl
  5eaa30: f2 0f 2a 00                  	cvtsi2sd	xmm0, dword ptr [eax]
  5eaa34: 8d 44 24 08                  	lea	eax, [esp + 0x8]
  5eaa38: f2 0f 11 44 24 10            	movsd	qword ptr [esp + 0x10], xmm0
  5eaa3e: 50                           	push	eax
  5eaa3f: e8 3c 37 e3 ff               	call	0x41e180 <.text+0x1d180>
  5eaa44: dd 5c 24 3c                  	fstp	qword ptr [esp + 0x3c]
  5eaa48: 83 c4 0c                     	add	esp, 0xc
  5eaa4b: ff 15 e0 56 c2 00            	call	dword ptr [0xc256e0]
  5eaa51: f2 0f 2a 00                  	cvtsi2sd	xmm0, dword ptr [eax]
  5eaa55: f2 0f 5e 05 80 75 c3 00      	divsd	xmm0, qword ptr [0xc37580]
  5eaa5d: f2 0f 5e 05 88 75 c3 00      	divsd	xmm0, qword ptr [0xc37588]
  5eaa65: f2 0f 10 4c 24 30            	movsd	xmm1, qword ptr [esp + 0x30]
  5eaa6b: 8d 54 24 10                  	lea	edx, [esp + 0x10]
  5eaa6f: 8d 44 24 28                  	lea	eax, [esp + 0x28]
  5eaa73: f2 0f 5c c8                  	subsd	xmm1, xmm0
  5eaa77: f2 0f 11 4c 24 28            	movsd	qword ptr [esp + 0x28], xmm1
  5eaa7d: 50                           	push	eax
  5eaa7e: 52                           	push	edx
  5eaa7f: e8 8c 39 e3 ff               	call	0x41e410 <.text+0x1d410>
  5eaa84: 83 c4 08                     	add	esp, 0x8
  5eaa87: 8b 54 24 48                  	mov	edx, dword ptr [esp + 0x48]
  5eaa8b: 8b 44 24 44                  	mov	eax, dword ptr [esp + 0x44]
  5eaa8f: 8b 7c 24 40                  	mov	edi, dword ptr [esp + 0x40]
  5eaa93: 8b 4c 24 10                  	mov	ecx, dword ptr [esp + 0x10]
  5eaa97: 89 0f                        	mov	dword ptr [edi], ecx
  5eaa99: 0f be 4c 24 14               	movsx	ecx, byte ptr [esp + 0x14]
  5eaa9e: 8b 7c 24 4c                  	mov	edi, dword ptr [esp + 0x4c]
  5eaaa2: 89 08                        	mov	dword ptr [eax], ecx
  5eaaa4: 0f be 44 24 15               	movsx	eax, byte ptr [esp + 0x15]
  5eaaa9: f2 0f 2c 4c 24 18            	cvttsd2si	ecx, qword ptr [esp + 0x18]
  5eaaaf: 89 02                        	mov	dword ptr [edx], eax
  5eaab1: 0f be 54 24 16               	movsx	edx, byte ptr [esp + 0x16]
  5eaab6: 0f be 44 24 17               	movsx	eax, byte ptr [esp + 0x17]
  5eaabb: 89 17                        	mov	dword ptr [edi], edx
  5eaabd: 8b 54 24 50                  	mov	edx, dword ptr [esp + 0x50]
  5eaac1: 8b 7c 24 54                  	mov	edi, dword ptr [esp + 0x54]
  5eaac5: 89 02                        	mov	dword ptr [edx], eax
  5eaac7: 89 0f                        	mov	dword ptr [edi], ecx
  5eaac9: 83 c4 38                     	add	esp, 0x38
  5eaacc: 5f                           	pop	edi
  5eaacd: c2 18 00                     	ret	0x18
  5eaad0: 53                           	push	ebx
  5eaad1: 83 ec 18                     	sub	esp, 0x18
  5eaad4: 8d 5c 24 10                  	lea	ebx, [esp + 0x10]
  5eaad8: 53                           	push	ebx
  5eaad9: ff 15 70 56 c2 00            	call	dword ptr [0xc25670]
  5eaadf: 53                           	push	ebx
  5eaae0: ff 15 dc 56 c2 00            	call	dword ptr [0xc256dc]
  5eaae6: 8b 50 14                     	mov	edx, dword ptr [eax + 0x14]
  5eaae9: 81 c2 6c 07 00 00            	add	edx, 0x76c
  5eaaef: 89 54 24 08                  	mov	dword ptr [esp + 0x8], edx
  5eaaf3: 8b 48 10                     	mov	ecx, dword ptr [eax + 0x10]
  5eaaf6: 41                           	inc	ecx
  5eaaf7: 88 4c 24 0c                  	mov	byte ptr [esp + 0xc], cl
  5eaafb: 8b 58 0c                     	mov	ebx, dword ptr [eax + 0xc]
  5eaafe: 88 5c 24 0d                  	mov	byte ptr [esp + 0xd], bl
  5eab02: 8b 50 08                     	mov	edx, dword ptr [eax + 0x8]
  5eab05: 88 54 24 0e                  	mov	byte ptr [esp + 0xe], dl
  5eab09: 8b 48 04                     	mov	ecx, dword ptr [eax + 0x4]
  5eab0c: 88 4c 24 0f                  	mov	byte ptr [esp + 0xf], cl
  5eab10: f2 0f 2a 00                  	cvtsi2sd	xmm0, dword ptr [eax]
  5eab14: 8d 44 24 08                  	lea	eax, [esp + 0x8]
  5eab18: f2 0f 11 44 24 10            	movsd	qword ptr [esp + 0x10], xmm0
  5eab1e: 50                           	push	eax
  5eab1f: e8 5c 36 e3 ff               	call	0x41e180 <.text+0x1d180>
  5eab24: 83 c4 0c                     	add	esp, 0xc
  5eab27: 83 c4 18                     	add	esp, 0x18
  5eab2a: 5b                           	pop	ebx
  5eab2b: c3                           	ret
  5eab2c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  5eab30: 83 ec 18                     	sub	esp, 0x18
  5eab33: 8b 44 24 1c                  	mov	eax, dword ptr [esp + 0x1c]
  5eab37: 3d 97 ed ff ff               	cmp	eax, 0xffffed97
  5eab3c: 74 5d                        	je	0x5eab9b <.text+0x1e9b9b>
  5eab3e: f2 0f 2a 44 24 30            	cvtsi2sd	xmm0, dword ptr [esp + 0x30]
  5eab44: 8b 4c 24 24                  	mov	ecx, dword ptr [esp + 0x24]
  5eab48: 8b 54 24 20                  	mov	edx, dword ptr [esp + 0x20]
  5eab4c: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  5eab52: 89 04 24                     	mov	dword ptr [esp], eax
  5eab55: 8b 44 24 28                  	mov	eax, dword ptr [esp + 0x28]
  5eab59: 88 54 24 04                  	mov	byte ptr [esp + 0x4], dl
  5eab5d: 88 4c 24 05                  	mov	byte ptr [esp + 0x5], cl
  5eab61: 88 44 24 06                  	mov	byte ptr [esp + 0x6], al
  5eab65: 8b 44 24 2c                  	mov	eax, dword ptr [esp + 0x2c]
  5eab69: 88 44 24 07                  	mov	byte ptr [esp + 0x7], al
  5eab6d: 6a 00                        	push	0x0
  5eab6f: e8 4c a5 e9 ff               	call	0x4850c0 <.text+0x840c0>
  5eab74: 8d 44 24 04                  	lea	eax, [esp + 0x4]
  5eab78: 50                           	push	eax
  5eab79: e8 02 36 e3 ff               	call	0x41e180 <.text+0x1d180>
  5eab7e: dd 5c 24 18                  	fstp	qword ptr [esp + 0x18]
  5eab82: 8d 44 24 18                  	lea	eax, [esp + 0x18]
  5eab86: 50                           	push	eax
  5eab87: e8 04 c4 e9 ff               	call	0x486f90 <.text+0x85f90>
  5eab8c: 83 c4 0c                     	add	esp, 0xc
  5eab8f: e8 dc d8 fe ff               	call	0x5d8470 <.text+0x1d7470>
  5eab94: 8b c8                        	mov	ecx, eax
  5eab96: e8 45 e0 fe ff               	call	0x5d8be0 <.text+0x1d7be0>
  5eab9b: 83 c4 18                     	add	esp, 0x18
  5eab9e: c2 18 00                     	ret	0x18
  5eaba1: 90                           	nop
  5eaba2: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  5eaba9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  5eabb0: 83 ec 18                     	sub	esp, 0x18
  5eabb3: e8 38 18 fb ff               	call	0x59c3f0 <.text+0x19b3f0>
  5eabb8: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  5eabbc: 8d 14 24                     	lea	edx, [esp]
  5eabbf: 8d 44 24 10                  	lea	eax, [esp + 0x10]
  5eabc3: 50                           	push	eax
  5eabc4: 52                           	push	edx
  5eabc5: e8 46 38 e3 ff               	call	0x41e410 <.text+0x1d410>
  5eabca: 83 c4 08                     	add	esp, 0x8
  5eabcd: 8b 44 24 20                  	mov	eax, dword ptr [esp + 0x20]
  5eabd1: 8b 4c 24 1c                  	mov	ecx, dword ptr [esp + 0x1c]
  5eabd5: 8b 14 24                     	mov	edx, dword ptr [esp]
  5eabd8: 89 11                        	mov	dword ptr [ecx], edx
  5eabda: 0f be 54 24 04               	movsx	edx, byte ptr [esp + 0x4]
  5eabdf: 8b 4c 24 24                  	mov	ecx, dword ptr [esp + 0x24]
  5eabe3: 89 10                        	mov	dword ptr [eax], edx
  5eabe5: 0f be 44 24 05               	movsx	eax, byte ptr [esp + 0x5]
  5eabea: 8b 54 24 28                  	mov	edx, dword ptr [esp + 0x28]
  5eabee: 89 01                        	mov	dword ptr [ecx], eax
  5eabf0: 0f be 44 24 06               	movsx	eax, byte ptr [esp + 0x6]
  5eabf5: 0f be 4c 24 07               	movsx	ecx, byte ptr [esp + 0x7]
  5eabfa: 89 02                        	mov	dword ptr [edx], eax
  5eabfc: 8b 44 24 2c                  	mov	eax, dword ptr [esp + 0x2c]
  5eac00: f2 0f 2c 54 24 08            	cvttsd2si	edx, qword ptr [esp + 0x8]
  5eac06: 89 08                        	mov	dword ptr [eax], ecx
  5eac08: 8b 4c 24 30                  	mov	ecx, dword ptr [esp + 0x30]
  5eac0c: 89 11                        	mov	dword ptr [ecx], edx
  5eac0e: 83 c4 18                     	add	esp, 0x18
  5eac11: c2 18 00                     	ret	0x18
  5eac14: 8d b6 00 00 00 00            	lea	esi, [esi]
  5eac1a: 8d bf 00 00 00 00            	lea	edi, [edi]
  5eac20: 53                           	push	ebx
  5eac21: 8b dc                        	mov	ebx, esp
  5eac23: 83 e4 c0                     	and	esp, -0x40
  5eac26: 55                           	push	ebp
  5eac27: 55                           	push	ebp
  5eac28: 8b 6b 04                     	mov	ebp, dword ptr [ebx + 0x4]
  5eac2b: 89 6c 24 04                  	mov	dword ptr [esp + 0x4], ebp
  5eac2f: 8b ec                        	mov	ebp, esp
  5eac31: 6a ff                        	push	-0x1
  5eac33: 68 c0 d7 bf 00               	push	0xbfd7c0
  5eac38: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  5eac3e: 50                           	push	eax
  5eac3f: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  5eac46: 83 ec 2c                     	sub	esp, 0x2c
  5eac49: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  5eac4c: 89 7d e0                     	mov	dword ptr [ebp - 0x20], edi
  5eac4f: 89 75 e4                     	mov	dword ptr [ebp - 0x1c], esi
  5eac52: f2 0f 2a 43 1c               	cvtsi2sd	xmm0, dword ptr [ebx + 0x1c]
  5eac57: 8b 73 08                     	mov	esi, dword ptr [ebx + 0x8]
  5eac5a: 8b 43 0c                     	mov	eax, dword ptr [ebx + 0xc]
  5eac5d: 8b 53 14                     	mov	edx, dword ptr [ebx + 0x14]
  5eac60: f2 0f 11 45 d0               	movsd	qword ptr [ebp - 0x30], xmm0
  5eac65: 89 4d e8                     	mov	dword ptr [ebp - 0x18], ecx
  5eac68: 8b 4b 18                     	mov	ecx, dword ptr [ebx + 0x18]
  5eac6b: 89 75 c8                     	mov	dword ptr [ebp - 0x38], esi
  5eac6e: 88 45 cc                     	mov	byte ptr [ebp - 0x34], al
  5eac71: 8b 43 10                     	mov	eax, dword ptr [ebx + 0x10]
  5eac74: 88 45 cd                     	mov	byte ptr [ebp - 0x33], al
  5eac77: 88 55 ce                     	mov	byte ptr [ebp - 0x32], dl
  5eac7a: 88 4d cf                     	mov	byte ptr [ebp - 0x31], cl
  5eac7d: 6a 00                        	push	0x0
  5eac7f: e8 3c a4 e9 ff               	call	0x4850c0 <.text+0x840c0>
  5eac84: 59                           	pop	ecx
  5eac85: 0f b6 43 28                  	movzx	eax, byte ptr [ebx + 0x28]
  5eac89: 85 c0                        	test	eax, eax
  5eac8b: 74 66                        	je	0x5eacf3 <.text+0x1e9cf3>
  5eac8d: c7 45 fc 02 00 00 00         	mov	dword ptr [ebp - 0x4], 0x2
  5eac94: c7 45 d8 00 00 00 00         	mov	dword ptr [ebp - 0x28], 0x0
  5eac9b: 50                           	push	eax
  5eac9c: c7 04 24 40 00 00 00         	mov	dword ptr [esp], 0x40
  5eaca3: e8 62 43 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5eaca8: 59                           	pop	ecx
  5eaca9: 8b f8                        	mov	edi, eax
  5eacab: 89 7d dc                     	mov	dword ptr [ebp - 0x24], edi
  5eacae: 85 ff                        	test	edi, edi
  5eacb0: 74 3d                        	je	0x5eacef <.text+0x1e9cef>
  5eacb2: c7 45 d8 01 00 00 00         	mov	dword ptr [ebp - 0x28], 0x1
  5eacb9: 8d 45 c8                     	lea	eax, [ebp - 0x38]
  5eacbc: 50                           	push	eax
  5eacbd: 89 04 24                     	mov	dword ptr [esp], eax
  5eacc0: e8 bb 34 e3 ff               	call	0x41e180 <.text+0x1d180>
  5eacc5: 59                           	pop	ecx
  5eacc6: f2 0f 10 43 20               	movsd	xmm0, qword ptr [ebx + 0x20]
  5eaccb: 83 c4 ec                     	add	esp, -0x14
  5eacce: dd 1c 24                     	fstp	qword ptr [esp]
  5eacd1: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  5eacd7: c7 44 24 10 00 00 00 00      	mov	dword ptr [esp + 0x10], 0x0
  5eacdf: 8b cf                        	mov	ecx, edi
  5eace1: e8 aa 4d 1d 00               	call	0x7bfa90 <.text+0x3bea90>
  5eace6: c7 45 d8 00 00 00 00         	mov	dword ptr [ebp - 0x28], 0x0
  5eaced: eb 68                        	jmp	0x5ead57 <.text+0x1e9d57>
  5eacef: 33 ff                        	xor	edi, edi
  5eacf1: eb 64                        	jmp	0x5ead57 <.text+0x1e9d57>
  5eacf3: c7 45 fc 01 00 00 00         	mov	dword ptr [ebp - 0x4], 0x1
  5eacfa: c7 45 d8 00 00 00 00         	mov	dword ptr [ebp - 0x28], 0x0
  5ead01: 50                           	push	eax
  5ead02: c7 04 24 40 00 00 00         	mov	dword ptr [esp], 0x40
  5ead09: e8 fc 42 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5ead0e: 59                           	pop	ecx
  5ead0f: 8b f8                        	mov	edi, eax
  5ead11: 89 7d dc                     	mov	dword ptr [ebp - 0x24], edi
  5ead14: 85 ff                        	test	edi, edi
  5ead16: 74 3d                        	je	0x5ead55 <.text+0x1e9d55>
  5ead18: c7 45 d8 01 00 00 00         	mov	dword ptr [ebp - 0x28], 0x1
  5ead1f: 8d 45 c8                     	lea	eax, [ebp - 0x38]
  5ead22: 50                           	push	eax
  5ead23: 89 04 24                     	mov	dword ptr [esp], eax
  5ead26: e8 55 34 e3 ff               	call	0x41e180 <.text+0x1d180>
  5ead2b: 59                           	pop	ecx
  5ead2c: f2 0f 10 43 20               	movsd	xmm0, qword ptr [ebx + 0x20]
