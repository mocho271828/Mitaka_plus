
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  518fb0: 51                           	push	ecx
  518fb1: 8d 54 24 40                  	lea	edx, [esp + 0x40]
  518fb5: 52                           	push	edx
  518fb6: e8 95 f5 02 00               	call	0x548550 <.text+0x147550>
  518fbb: 59                           	pop	ecx
  518fbc: b9 e0 77 10 01               	mov	ecx, 0x11077e0
  518fc1: e8 fa c9 05 00               	call	0x5759c0 <.text+0x1749c0>
  518fc6: dd 9c 24 c8 00 00 00         	fstp	qword ptr [esp + 0xc8]
  518fcd: f2 0f 10 84 24 c8 00 00 00   	movsd	xmm0, qword ptr [esp + 0xc8]
  518fd6: f3 0f 5a 15 24 1c 08 01      	cvtss2sd	xmm2, dword ptr [0x1081c24]
  518fde: f2 0f 59 54 24 48            	mulsd	xmm2, qword ptr [esp + 0x48]
  518fe4: f2 0f 59 d0                  	mulsd	xmm2, xmm0
  518fe8: eb 18                        	jmp	0x519002 <.text+0x118002>
  518fea: f3 0f 10 0d 24 1c 08 01      	movss	xmm1, dword ptr [0x1081c24]
  518ff2: f3 0f 10 05 a8 12 c3 00      	movss	xmm0, dword ptr [0xc312a8]
  518ffa: f3 0f 59 c8                  	mulss	xmm1, xmm0
  518ffe: f3 0f 5a d1                  	cvtss2sd	xmm2, xmm1
  519002: f6 05 28 1e d7 00 0c         	test	byte ptr [0xd71e28], 0xc
  519009: 74 09                        	je	0x519014 <.text+0x118014>
  51900b: 83 3b 02                     	cmp	dword ptr [ebx], 0x2
  51900e: 0f 84 68 02 00 00            	je	0x51927c <.text+0x11827c>
  519014: f2 0f 59 94 24 50 01 00 00   	mulsd	xmm2, qword ptr [esp + 0x150]
  51901d: 8b 94 24 60 01 00 00         	mov	edx, dword ptr [esp + 0x160]
  519024: f2 0f 10 5a 08               	movsd	xmm3, qword ptr [edx + 0x8]
  519029: f2 0f 59 9c 24 38 01 00 00   	mulsd	xmm3, qword ptr [esp + 0x138]
  519032: f2 0f 10 4a 10               	movsd	xmm1, qword ptr [edx + 0x10]
  519037: f2 0f 59 8c 24 40 01 00 00   	mulsd	xmm1, qword ptr [esp + 0x140]
  519040: f2 0f 10 42 18               	movsd	xmm0, qword ptr [edx + 0x18]
  519045: f2 0f 59 84 24 48 01 00 00   	mulsd	xmm0, qword ptr [esp + 0x148]
  51904e: f2 0f 10 62 28               	movsd	xmm4, qword ptr [edx + 0x28]
  519053: f2 0f 59 a4 24 40 01 00 00   	mulsd	xmm4, qword ptr [esp + 0x140]
  51905c: f2 0f 10 6a 30               	movsd	xmm5, qword ptr [edx + 0x30]
  519061: f2 0f 59 ac 24 48 01 00 00   	mulsd	xmm5, qword ptr [esp + 0x148]
  51906a: f2 0f 10 72 40               	movsd	xmm6, qword ptr [edx + 0x40]
  51906f: f2 0f 59 b4 24 40 01 00 00   	mulsd	xmm6, qword ptr [esp + 0x140]
  519078: f2 0f 10 7a 48               	movsd	xmm7, qword ptr [edx + 0x48]
  51907d: f2 0f 59 bc 24 48 01 00 00   	mulsd	xmm7, qword ptr [esp + 0x148]
  519086: f2 0f 58 d9                  	addsd	xmm3, xmm1
  51908a: f2 0f 10 4a 20               	movsd	xmm1, qword ptr [edx + 0x20]
  51908f: f2 0f 59 8c 24 38 01 00 00   	mulsd	xmm1, qword ptr [esp + 0x138]
  519098: f2 0f 58 d8                  	addsd	xmm3, xmm0
  51909c: f2 0f 58 5a 50               	addsd	xmm3, qword ptr [edx + 0x50]
  5190a1: f2 0f 10 42 38               	movsd	xmm0, qword ptr [edx + 0x38]
  5190a6: f2 0f 59 84 24 38 01 00 00   	mulsd	xmm0, qword ptr [esp + 0x138]
  5190af: f2 0f 58 cc                  	addsd	xmm1, xmm4
  5190b3: f2 0f 58 cd                  	addsd	xmm1, xmm5
  5190b7: f2 0f 58 4a 58               	addsd	xmm1, qword ptr [edx + 0x58]
  5190bc: f2 0f 58 c6                  	addsd	xmm0, xmm6
  5190c0: f2 0f 58 c7                  	addsd	xmm0, xmm7
  5190c4: f2 0f 58 42 60               	addsd	xmm0, qword ptr [edx + 0x60]
  5190c9: 0f 28 e8                     	movaps	xmm5, xmm0
  5190cc: 66 0f ef e4                  	pxor	xmm4, xmm4
  5190d0: f3 0f 5c a2 20 02 00 00      	subss	xmm4, dword ptr [edx + 0x220]
  5190d8: f3 0f 5a f4                  	cvtss2sd	xmm6, xmm4
  5190dc: f2 0f 5c ea                  	subsd	xmm5, xmm2
  5190e0: 66 0f 2f ee                  	comisd	xmm5, xmm6
  5190e4: 77 27                        	ja	0x51910d <.text+0x11810d>
  5190e6: 83 bc 24 5c 01 00 00 00      	cmp	dword ptr [esp + 0x15c], 0x0
  5190ee: 74 21                        	je	0x519111 <.text+0x118111>
  5190f0: 0f 28 f2                     	movaps	xmm6, xmm2
  5190f3: f2 0f 58 f0                  	addsd	xmm6, xmm0
  5190f7: 66 0f ef e4                  	pxor	xmm4, xmm4
  5190fb: f3 0f 5c a2 24 02 00 00      	subss	xmm4, dword ptr [edx + 0x224]
  519103: f3 0f 5a ec                  	cvtss2sd	xmm5, xmm4
  519107: 66 0f 2f ee                  	comisd	xmm5, xmm6
  51910b: 76 04                        	jbe	0x519111 <.text+0x118111>
  51910d: 33 d2                        	xor	edx, edx
  51910f: eb 47                        	jmp	0x519158 <.text+0x118158>
  519111: 33 c0                        	xor	eax, eax
  519113: 8d 14 40                     	lea	edx, [eax + 2*eax]
  519116: f2 0f 10 b4 d4 d8 00 00 00   	movsd	xmm6, qword ptr [esp + 8*edx + 0xd8]
  51911f: f2 0f 59 f3                  	mulsd	xmm6, xmm3
  519123: f2 0f 10 a4 d4 e0 00 00 00   	movsd	xmm4, qword ptr [esp + 8*edx + 0xe0]
  51912c: f2 0f 59 e1                  	mulsd	xmm4, xmm1
  519130: f2 0f 58 f4                  	addsd	xmm6, xmm4
  519134: f2 0f 10 ac d4 e8 00 00 00   	movsd	xmm5, qword ptr [esp + 8*edx + 0xe8]
  51913d: f2 0f 59 e8                  	mulsd	xmm5, xmm0
  519141: f2 0f 58 f5                  	addsd	xmm6, xmm5
  519145: 66 0f 2f f2                  	comisd	xmm6, xmm2
  519149: 77 c2                        	ja	0x51910d <.text+0x11810d>
  51914b: 40                           	inc	eax
  51914c: 83 f8 04                     	cmp	eax, 0x4
  51914f: 7c c2                        	jl	0x519113 <.text+0x118113>
  519151: 8b f6                        	mov	esi, esi
  519153: ba 01 00 00 00               	mov	edx, 0x1
  519158: 85 d2                        	test	edx, edx
  51915a: 75 70                        	jne	0x5191cc <.text+0x1181cc>
  51915c: 47                           	inc	edi
  51915d: 3b fe                        	cmp	edi, esi
  51915f: 0f 8c 3c fb ff ff            	jl	0x518ca1 <.text+0x117ca1>
  519165: 8b bc 24 58 01 00 00         	mov	edi, dword ptr [esp + 0x158]
  51916c: 8b 0d 74 1c 08 01            	mov	ecx, dword ptr [0x1081c74]
  519172: 3b 0d 78 1c 08 01            	cmp	ecx, dword ptr [0x1081c78]
  519178: 0f 87 d6 01 00 00            	ja	0x519354 <.text+0x118354>
  51917e: 8d 04 fd 00 00 00 00         	lea	eax, [8*edi]
  519185: 8d 14 f9                     	lea	edx, [ecx + 8*edi]
  519188: 3b 15 78 1c 08 01            	cmp	edx, dword ptr [0x1081c78]
  51918e: 0f 87 c0 01 00 00            	ja	0x519354 <.text+0x118354>
  519194: 3b 15 74 1c 08 01            	cmp	edx, dword ptr [0x1081c74]
  51919a: 0f 82 b4 01 00 00            	jb	0x519354 <.text+0x118354>
  5191a0: c1 f8 03                     	sar	eax, 0x3
  5191a3: 50                           	push	eax
  5191a4: 52                           	push	edx
  5191a5: 51                           	push	ecx
  5191a6: e8 c5 0d 00 00               	call	0x519f70 <.text+0x118f70>
  5191ab: 83 c4 0c                     	add	esp, 0xc
  5191ae: 8b c7                        	mov	eax, edi
  5191b0: 81 c4 64 01 00 00            	add	esp, 0x164
  5191b6: 5b                           	pop	ebx
  5191b7: 5e                           	pop	esi
  5191b8: 5f                           	pop	edi
  5191b9: 8b e5                        	mov	esp, ebp
  5191bb: 5d                           	pop	ebp
  5191bc: c3                           	ret
  5191bd: b9 80 1a 08 01               	mov	ecx, 0x1081a80
  5191c2: e8 49 68 ff ff               	call	0x50fa10 <.text+0x10ea10>
  5191c7: e9 a2 fb ff ff               	jmp	0x518d6e <.text+0x117d6e>
  5191cc: 8d 54 24 68                  	lea	edx, [esp + 0x68]
  5191d0: 53                           	push	ebx
  5191d1: 52                           	push	edx
  5191d2: e8 09 2e 00 00               	call	0x51bfe0 <.text+0x11afe0>
  5191d7: 83 c4 08                     	add	esp, 0x8
  5191da: f2 0f 10 54 24 68            	movsd	xmm2, qword ptr [esp + 0x68]
  5191e0: 8b 94 24 60 01 00 00         	mov	edx, dword ptr [esp + 0x160]
  5191e7: f2 0f 59 52 38               	mulsd	xmm2, qword ptr [edx + 0x38]
  5191ec: f2 0f 10 44 24 70            	movsd	xmm0, qword ptr [esp + 0x70]
  5191f2: f2 0f 59 42 40               	mulsd	xmm0, qword ptr [edx + 0x40]
  5191f7: f2 0f 10 4c 24 78            	movsd	xmm1, qword ptr [esp + 0x78]
  5191fd: f2 0f 59 4a 48               	mulsd	xmm1, qword ptr [edx + 0x48]
  519202: f2 0f 58 d0                  	addsd	xmm2, xmm0
  519206: 8b 0d 78 1c 08 01            	mov	ecx, dword ptr [0x1081c78]
  51920c: f2 0f 58 d1                  	addsd	xmm2, xmm1
  519210: f2 0f 58 52 60               	addsd	xmm2, qword ptr [edx + 0x60]
  519215: 8b 15 74 1c 08 01            	mov	edx, dword ptr [0x1081c74]
  51921b: 2b ca                        	sub	ecx, edx
  51921d: c1 f9 03                     	sar	ecx, 0x3
  519220: 85 d2                        	test	edx, edx
  519222: 0f 44 ca                     	cmove	ecx, edx
  519225: 3b 8c 24 58 01 00 00         	cmp	ecx, dword ptr [esp + 0x158]
  51922c: 0f 86 22 01 00 00            	jbe	0x519354 <.text+0x118354>
  519232: 8b 84 24 58 01 00 00         	mov	eax, dword ptr [esp + 0x158]
  519239: 89 3c c2                     	mov	dword ptr [edx + 8*eax], edi
  51923c: f3 0f 5a 43 08               	cvtss2sd	xmm0, dword ptr [ebx + 0x8]
  519241: f2 0f 5c c2                  	subsd	xmm0, xmm2
  519245: 8b 0d 74 1c 08 01            	mov	ecx, dword ptr [0x1081c74]
  51924b: 8b 15 78 1c 08 01            	mov	edx, dword ptr [0x1081c78]
  519251: 2b d1                        	sub	edx, ecx
  519253: c1 fa 03                     	sar	edx, 0x3
  519256: 85 c9                        	test	ecx, ecx
  519258: 0f 44 d1                     	cmove	edx, ecx
  51925b: 3b c2                        	cmp	eax, edx
  51925d: 0f 83 f1 00 00 00            	jae	0x519354 <.text+0x118354>
  519263: f2 0f 5a c0                  	cvtsd2ss	xmm0, xmm0
  519267: 8b d0                        	mov	edx, eax
  519269: f3 0f 11 44 d1 04            	movss	dword ptr [ecx + 8*edx + 0x4], xmm0
  51926f: 42                           	inc	edx
  519270: 89 94 24 58 01 00 00         	mov	dword ptr [esp + 0x158], edx
  519277: e9 e0 fe ff ff               	jmp	0x51915c <.text+0x11815c>
  51927c: 8b 53 04                     	mov	edx, dword ptr [ebx + 0x4]
  51927f: 89 94 24 b0 00 00 00         	mov	dword ptr [esp + 0xb0], edx
  519286: 68 c0 d5 c2 00               	push	0xc2d5c0
  51928b: f2 0f 11 54 24 3c            	movsd	qword ptr [esp + 0x3c], xmm2
  519291: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  519296: e8 85 48 02 00               	call	0x53db20 <.text+0x13cb20>
  51929b: f2 0f 10 54 24 38            	movsd	xmm2, qword ptr [esp + 0x38]
  5192a1: 3b 84 24 b0 00 00 00         	cmp	eax, dword ptr [esp + 0xb0]
  5192a8: 0f 85 66 fd ff ff            	jne	0x519014 <.text+0x118014>
  5192ae: e9 19 ff ff ff               	jmp	0x5191cc <.text+0x1181cc>
  5192b3: 66 0f ef c0                  	pxor	xmm0, xmm0
  5192b7: 66 0f d6 44 24 10            	movq	qword ptr [esp + 0x10], xmm0
  5192bd: 8b 44 24 10                  	mov	eax, dword ptr [esp + 0x10]
  5192c1: 8b 4c 24 14                  	mov	ecx, dword ptr [esp + 0x14]
  5192c5: 89 84 24 d0 00 00 00         	mov	dword ptr [esp + 0xd0], eax
  5192cc: a1 78 1c 08 01               	mov	eax, dword ptr [0x1081c78]
  5192d1: 89 8c 24 d4 00 00 00         	mov	dword ptr [esp + 0xd4], ecx
  5192d8: 8b f8                        	mov	edi, eax
  5192da: 2b fa                        	sub	edi, edx
  5192dc: c1 ff 03                     	sar	edi, 0x3
  5192df: 85 d2                        	test	edx, edx
  5192e1: 0f 44 fa                     	cmove	edi, edx
  5192e4: 3b fe                        	cmp	edi, esi
  5192e6: 73 2e                        	jae	0x519316 <.text+0x118316>
  5192e8: 3b d0                        	cmp	edx, eax
  5192ea: 77 68                        	ja	0x519354 <.text+0x118354>
  5192ec: b9 70 1c 08 01               	mov	ecx, 0x1081c70
  5192f1: 8b f8                        	mov	edi, eax
  5192f3: 2b fa                        	sub	edi, edx
  5192f5: c1 ff 03                     	sar	edi, 0x3
  5192f8: 85 d2                        	test	edx, edx
  5192fa: 0f 45 d7                     	cmovne	edx, edi
  5192fd: f7 da                        	neg	edx
  5192ff: 8d bc 24 d0 00 00 00         	lea	edi, [esp + 0xd0]
  519306: 57                           	push	edi
  519307: 03 d6                        	add	edx, esi
  519309: 52                           	push	edx
  51930a: 50                           	push	eax
  51930b: 51                           	push	ecx
  51930c: e8 4f 00 00 00               	call	0x519360 <.text+0x118360>
