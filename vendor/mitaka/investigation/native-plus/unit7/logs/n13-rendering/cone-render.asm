
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  4c84e0: 0f ef d2                     	pxor	mm2, mm2
  4c84e3: f2 0f 5c d1                  	subsd	xmm2, xmm1
  4c84e7: 66 0f 2f d0                  	comisd	xmm2, xmm0
  4c84eb: 76 10                        	jbe	0x4c84fd <.text+0xc74fd>
  4c84ed: f2 0f 59 ed                  	mulsd	xmm5, xmm5
  4c84f1: f2 0f 11 2c 24               	movsd	qword ptr [esp], xmm5
  4c84f6: dd 04 24                     	fld	qword ptr [esp]
  4c84f9: 8b e5                        	mov	esp, ebp
  4c84fb: 5d                           	pop	ebp
  4c84fc: c3                           	ret
  4c84fd: f2 0f 59 ed                  	mulsd	xmm5, xmm5
  4c8501: f2 0f 11 6c 24 30            	movsd	qword ptr [esp + 0x30], xmm5
  4c8507: 0f 28 e0                     	movaps	xmm4, xmm0
  4c850a: 0f 28 d3                     	movaps	xmm2, xmm3
  4c850d: f2 0f 59 e0                  	mulsd	xmm4, xmm0
  4c8511: 0f 28 cc                     	movaps	xmm1, xmm4
  4c8514: f2 0f 58 c0                  	addsd	xmm0, xmm0
  4c8518: f2 0f 5c d5                  	subsd	xmm2, xmm5
  4c851c: f2 0f 5c cb                  	subsd	xmm1, xmm3
  4c8520: f2 0f 58 cd                  	addsd	xmm1, xmm5
  4c8524: f2 0f 5e c8                  	divsd	xmm1, xmm0
  4c8528: f2 0f 11 4c 24 20            	movsd	qword ptr [esp + 0x20], xmm1
  4c852e: f2 0f 58 d4                  	addsd	xmm2, xmm4
  4c8532: f2 0f 5e d0                  	divsd	xmm2, xmm0
  4c8536: f2 0f 11 54 24 28            	movsd	qword ptr [esp + 0x28], xmm2
  4c853c: 0f 28 f1                     	movaps	xmm6, xmm1
  4c853f: f2 0f 59 d2                  	mulsd	xmm2, xmm2
  4c8543: f2 0f 59 f1                  	mulsd	xmm6, xmm1
  4c8547: f2 0f 5c da                  	subsd	xmm3, xmm2
  4c854b: f2 0f 51 fb                  	sqrtsd	xmm7, xmm3
  4c854f: f2 0f 11 7c 24 10            	movsd	qword ptr [esp + 0x10], xmm7
  4c8555: f2 0f 5c ee                  	subsd	xmm5, xmm6
  4c8559: f2 0f 51 c5                  	sqrtsd	xmm0, xmm5
  4c855d: f2 0f 11 44 24 18            	movsd	qword ptr [esp + 0x18], xmm0
  4c8563: e8 ae 68 5c 00               	call	0xa8ee16 <.text+0x68de16>
  4c8568: f2 0f 10 4c 24 28            	movsd	xmm1, qword ptr [esp + 0x28]
  4c856e: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  4c8574: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  4c857a: e8 97 68 5c 00               	call	0xa8ee16 <.text+0x68de16>
  4c857f: f2 0f 10 5c 24 30            	movsd	xmm3, qword ptr [esp + 0x30]
  4c8585: f2 0f 59 5c 24 08            	mulsd	xmm3, qword ptr [esp + 0x8]
  4c858b: f2 0f 10 4c 24 20            	movsd	xmm1, qword ptr [esp + 0x20]
  4c8591: f2 0f 59 4c 24 18            	mulsd	xmm1, qword ptr [esp + 0x18]
  4c8597: f2 0f 10 54 24 28            	movsd	xmm2, qword ptr [esp + 0x28]
  4c859d: f2 0f 59 54 24 10            	mulsd	xmm2, qword ptr [esp + 0x10]
  4c85a3: f2 0f 5c d9                  	subsd	xmm3, xmm1
  4c85a7: f2 0f 5c da                  	subsd	xmm3, xmm2
  4c85ab: f2 0f 58 d8                  	addsd	xmm3, xmm0
  4c85af: f2 0f 5e 1d 28 e1 c2 00      	divsd	xmm3, qword ptr [0xc2e128]
  4c85b7: f2 0f 11 1c 24               	movsd	qword ptr [esp], xmm3
  4c85bc: dd 04 24                     	fld	qword ptr [esp]
  4c85bf: 8b e5                        	mov	esp, ebp
  4c85c1: 5d                           	pop	ebp
  4c85c2: c3                           	ret
  4c85c3: 66 0f ef c0                  	pxor	xmm0, xmm0
  4c85c7: f3 0f 11 04 24               	movss	dword ptr [esp], xmm0
  4c85cc: d9 04 24                     	fld	dword ptr [esp]
  4c85cf: 8b e5                        	mov	esp, ebp
  4c85d1: 5d                           	pop	ebp
  4c85d2: c3                           	ret
  4c85d3: 8d b6 00 00 00 00            	lea	esi, [esi]
  4c85d9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  4c85e0: 55                           	push	ebp
  4c85e1: 8b ec                        	mov	ebp, esp
  4c85e3: 83 e4 f8                     	and	esp, -0x8
  4c85e6: 83 ec 68                     	sub	esp, 0x68
  4c85e9: 8b 45 08                     	mov	eax, dword ptr [ebp + 0x8]
  4c85ec: 8b 90 38 01 00 00            	mov	edx, dword ptr [eax + 0x138]
  4c85f2: 8b 88 3c 01 00 00            	mov	ecx, dword ptr [eax + 0x13c]
  4c85f8: 89 54 24 40                  	mov	dword ptr [esp + 0x40], edx
  4c85fc: 8b 90 40 01 00 00            	mov	edx, dword ptr [eax + 0x140]
  4c8602: 89 4c 24 44                  	mov	dword ptr [esp + 0x44], ecx
  4c8606: 8b 88 44 01 00 00            	mov	ecx, dword ptr [eax + 0x144]
  4c860c: 89 54 24 48                  	mov	dword ptr [esp + 0x48], edx
  4c8610: 8b 90 48 01 00 00            	mov	edx, dword ptr [eax + 0x148]
  4c8616: 8b 80 4c 01 00 00            	mov	eax, dword ptr [eax + 0x14c]
  4c861c: 89 4c 24 4c                  	mov	dword ptr [esp + 0x4c], ecx
  4c8620: 89 54 24 50                  	mov	dword ptr [esp + 0x50], edx
  4c8624: 89 44 24 54                  	mov	dword ptr [esp + 0x54], eax
  4c8628: b9 60 74 10 01               	mov	ecx, 0x1107460
  4c862d: 68 f0 e1 c2 00               	push	0xc2e1f0
  4c8632: e8 a9 30 09 00               	call	0x55b6e0 <.text+0x15a6e0>
  4c8637: 8d 54 24 28                  	lea	edx, [esp + 0x28]
  4c863b: 50                           	push	eax
  4c863c: 52                           	push	edx
  4c863d: b9 60 74 10 01               	mov	ecx, 0x1107460
  4c8642: e8 49 0a 09 00               	call	0x559090 <.text+0x158090>
  4c8647: 68 f0 e1 c2 00               	push	0xc2e1f0
  4c864c: b9 60 74 10 01               	mov	ecx, 0x1107460
  4c8651: e8 8a 30 09 00               	call	0x55b6e0 <.text+0x15a6e0>
  4c8656: 50                           	push	eax
  4c8657: b9 60 74 10 01               	mov	ecx, 0x1107460
  4c865c: e8 7f 10 09 00               	call	0x5596e0 <.text+0x1586e0>
  4c8661: dd 5c 24 58                  	fstp	qword ptr [esp + 0x58]
  4c8665: f3 0f 5a 05 4c 9d 07 01      	cvtss2sd	xmm0, dword ptr [0x1079d4c]
  4c866d: f2 0f 10 4c 24 58            	movsd	xmm1, qword ptr [esp + 0x58]
  4c8673: f2 0f 59 c8                  	mulsd	xmm1, xmm0
  4c8677: f2 0f 11 4c 24 58            	movsd	qword ptr [esp + 0x58], xmm1
  4c867d: b9 e0 77 10 01               	mov	ecx, 0x11077e0
  4c8682: e8 09 d3 0a 00               	call	0x575990 <.text+0x174990>
  4c8687: dd 1c 24                     	fstp	qword ptr [esp]
  4c868a: f2 0f 10 04 24               	movsd	xmm0, qword ptr [esp]
  4c868f: 8d 04 24                     	lea	eax, [esp]
  4c8692: 50                           	push	eax
  4c8693: f2 0f 11 44 24 64            	movsd	qword ptr [esp + 0x64], xmm0
  4c8699: e8 b2 fe 07 00               	call	0x548550 <.text+0x147550>
  4c869e: f2 0f 10 44 24 64            	movsd	xmm0, qword ptr [esp + 0x64]
  4c86a4: 83 c4 04                     	add	esp, 0x4
  4c86a7: f3 0f 5a 2d 4c 9d 07 01      	cvtss2sd	xmm5, dword ptr [0x1079d4c]
  4c86af: f2 0f 59 c5                  	mulsd	xmm0, xmm5
  4c86b3: f2 0f 59 44 24 08            	mulsd	xmm0, qword ptr [esp + 0x8]
  4c86b9: f2 0f 10 6c 24 28            	movsd	xmm5, qword ptr [esp + 0x28]
  4c86bf: 0f 28 cd                     	movaps	xmm1, xmm5
  4c86c2: f2 0f 59 cd                  	mulsd	xmm1, xmm5
  4c86c6: f2 0f 10 5c 24 30            	movsd	xmm3, qword ptr [esp + 0x30]
  4c86cc: 0f 28 f3                     	movaps	xmm6, xmm3
  4c86cf: f2 0f 59 f3                  	mulsd	xmm6, xmm3
  4c86d3: f2 0f 10 64 24 38            	movsd	xmm4, qword ptr [esp + 0x38]
  4c86d9: 0f 28 d4                     	movaps	xmm2, xmm4
  4c86dc: f2 0f 59 d4                  	mulsd	xmm2, xmm4
  4c86e0: f2 0f 58 ce                  	addsd	xmm1, xmm6
  4c86e4: f2 0f 10 3d 38 e1 c2 00      	movsd	xmm7, qword ptr [0xc2e138]
  4c86ec: f2 0f 58 ca                  	addsd	xmm1, xmm2
  4c86f0: f2 0f 51 f1                  	sqrtsd	xmm6, xmm1
  4c86f4: f2 0f 5e fe                  	divsd	xmm7, xmm6
  4c86f8: f2 0f 59 ef                  	mulsd	xmm5, xmm7
  4c86fc: f2 0f 59 df                  	mulsd	xmm3, xmm7
  4c8700: f2 0f 59 e7                  	mulsd	xmm4, xmm7
  4c8704: 0f 28 fe                     	movaps	xmm7, xmm6
  4c8707: 0f 28 cb                     	movaps	xmm1, xmm3
  4c870a: 0f 28 d4                     	movaps	xmm2, xmm4
  4c870d: f2 0f 59 f8                  	mulsd	xmm7, xmm0
  4c8711: f2 0f 58 44 24 58            	addsd	xmm0, qword ptr [esp + 0x58]
  4c8717: f2 0f 5e f8                  	divsd	xmm7, xmm0
  4c871b: f2 0f 11 7c 24 60            	movsd	qword ptr [esp + 0x60], xmm7
  4c8721: 0f 28 c5                     	movaps	xmm0, xmm5
  4c8724: f2 0f 59 cf                  	mulsd	xmm1, xmm7
  4c8728: f2 0f 59 d7                  	mulsd	xmm2, xmm7
  4c872c: f2 0f 59 c7                  	mulsd	xmm0, xmm7
  4c8730: f2 0f 5c 74 24 60            	subsd	xmm6, qword ptr [esp + 0x60]
  4c8736: f2 0f 10 7c 24 40            	movsd	xmm7, qword ptr [esp + 0x40]
  4c873c: f2 0f 5c f8                  	subsd	xmm7, xmm0
  4c8740: f2 0f 59 ef                  	mulsd	xmm5, xmm7
  4c8744: f2 0f 59 ff                  	mulsd	xmm7, xmm7
  4c8748: f2 0f 10 44 24 48            	movsd	xmm0, qword ptr [esp + 0x48]
  4c874e: f2 0f 5c c1                  	subsd	xmm0, xmm1
  4c8752: f2 0f 59 d8                  	mulsd	xmm3, xmm0
  4c8756: f2 0f 59 c0                  	mulsd	xmm0, xmm0
  4c875a: f2 0f 58 eb                  	addsd	xmm5, xmm3
  4c875e: f2 0f 10 4c 24 50            	movsd	xmm1, qword ptr [esp + 0x50]
  4c8764: f2 0f 5c ca                  	subsd	xmm1, xmm2
  4c8768: f2 0f 59 e1                  	mulsd	xmm4, xmm1
  4c876c: f2 0f 59 c9                  	mulsd	xmm1, xmm1
  4c8770: f2 0f 58 f8                  	addsd	xmm7, xmm0
  4c8774: f2 0f 58 ec                  	addsd	xmm5, xmm4
  4c8778: 0f 28 dd                     	movaps	xmm3, xmm5
  4c877b: f2 0f 59 dd                  	mulsd	xmm3, xmm5
  4c877f: f2 0f 5e ee                  	divsd	xmm5, xmm6
  4c8783: f2 0f 59 6c 24 58            	mulsd	xmm5, qword ptr [esp + 0x58]
  4c8789: f2 0f 58 f9                  	addsd	xmm7, xmm1
  4c878d: f2 0f 5c fb                  	subsd	xmm7, xmm3
  4c8791: f2 0f 51 d7                  	sqrtsd	xmm2, xmm7
  4c8795: 66 0f ef c9                  	pxor	xmm1, xmm1
  4c8799: 66 0f 2e e9                  	ucomisd	xmm5, xmm1
  4c879d: 7a 02                        	jp	0x4c87a1 <.text+0xc77a1>
  4c879f: 74 2c                        	je	0x4c87cd <.text+0xc77cd>
  4c87a1: f2 0f 5e d5                  	divsd	xmm2, xmm5
  4c87a5: f2 0f 10 05 38 e1 c2 00      	movsd	xmm0, qword ptr [0xc2e138]
  4c87ad: 66 0f 2f c2                  	comisd	xmm0, xmm2
  4c87b1: 76 1a                        	jbe	0x4c87cd <.text+0xc77cd>
  4c87b3: f2 0f 10 05 38 e1 c2 00      	movsd	xmm0, qword ptr [0xc2e138]
  4c87bb: f2 0f 5c c2                  	subsd	xmm0, xmm2
  4c87bf: f2 0f 11 44 24 40            	movsd	qword ptr [esp + 0x40], xmm0
  4c87c5: dd 44 24 40                  	fld	qword ptr [esp + 0x40]
  4c87c9: 8b e5                        	mov	esp, ebp
  4c87cb: 5d                           	pop	ebp
  4c87cc: c3                           	ret
  4c87cd: f2 0f 11 4c 24 40            	movsd	qword ptr [esp + 0x40], xmm1
  4c87d3: dd 44 24 40                  	fld	qword ptr [esp + 0x40]
  4c87d7: 8b e5                        	mov	esp, ebp
  4c87d9: 5d                           	pop	ebp
  4c87da: c3                           	ret
  4c87db: 90                           	nop
  4c87dc: 8d 74 26 00                  	lea	esi, [esi + eiz]
  4c87e0: 55                           	push	ebp
  4c87e1: 8b ec                        	mov	ebp, esp
  4c87e3: 83 e4 f8                     	and	esp, -0x8
  4c87e6: 57                           	push	edi
  4c87e7: 56                           	push	esi
  4c87e8: 53                           	push	ebx
  4c87e9: 81 ec 34 02 00 00            	sub	esp, 0x234
  4c87ef: b9 e0 77 10 01               	mov	ecx, 0x11077e0
  4c87f4: e8 97 d1 0a 00               	call	0x575990 <.text+0x174990>
  4c87f9: dd 5c 24 08                  	fstp	qword ptr [esp + 0x8]
  4c87fd: 8d 84 24 80 00 00 00         	lea	eax, [esp + 0x80]
  4c8804: 50                           	push	eax
  4c8805: e8 46 fd 07 00               	call	0x548550 <.text+0x147550>
  4c880a: f3 0f 5a 3d 4c 9d 07 01      	cvtss2sd	xmm7, dword ptr [0x1079d4c]
  4c8812: f2 0f 59 bc 24 8c 00 00 00   	mulsd	xmm7, qword ptr [esp + 0x8c]
  4c881b: f2 0f 59 7c 24 0c            	mulsd	xmm7, qword ptr [esp + 0xc]
  4c8821: 8b 75 1c                     	mov	esi, dword ptr [ebp + 0x1c]
  4c8824: 8b 7d 18                     	mov	edi, dword ptr [ebp + 0x18]
  4c8827: 8b 5d 14                     	mov	ebx, dword ptr [ebp + 0x14]
  4c882a: f2 0f 10 03                  	movsd	xmm0, qword ptr [ebx]
  4c882e: f2 0f 5c 06                  	subsd	xmm0, qword ptr [esi]
  4c8832: f2 0f 10 4b 08               	movsd	xmm1, qword ptr [ebx + 0x8]
  4c8837: f2 0f 5c 4e 08               	subsd	xmm1, qword ptr [esi + 0x8]
  4c883c: f2 0f 10 53 10               	movsd	xmm2, qword ptr [ebx + 0x10]
  4c8841: f2 0f 5c 56 10               	subsd	xmm2, qword ptr [esi + 0x10]
  4c8846: f2 0f 11 7c 24 54            	movsd	qword ptr [esp + 0x54], xmm7
  4c884c: f2 0f 11 84 24 0c 01 00 00   	movsd	qword ptr [esp + 0x10c], xmm0
  4c8855: f2 0f 11 8c 24 14 01 00 00   	movsd	qword ptr [esp + 0x114], xmm1
  4c885e: f2 0f 11 94 24 1c 01 00 00   	movsd	qword ptr [esp + 0x11c], xmm2
  4c8867: 0f 28 f0                     	movaps	xmm6, xmm0
  4c886a: 0f 28 d9                     	movaps	xmm3, xmm1
  4c886d: 0f 28 ea                     	movaps	xmm5, xmm2
  4c8870: f2 0f 59 f0                  	mulsd	xmm6, xmm0
  4c8874: f2 0f 59 d9                  	mulsd	xmm3, xmm1
  4c8878: f2 0f 59 ea                  	mulsd	xmm5, xmm2
  4c887c: f2 0f 58 f3                  	addsd	xmm6, xmm3
  4c8880: f2 0f 58 f5                  	addsd	xmm6, xmm5
  4c8884: 0f 28 e8                     	movaps	xmm5, xmm0
  4c8887: f2 0f 51 e6                  	sqrtsd	xmm4, xmm6
  4c888b: f2 0f 11 64 24 04            	movsd	qword ptr [esp + 0x4], xmm4
  4c8891: 0f 28 dc                     	movaps	xmm3, xmm4
  4c8894: f2 0f 59 df                  	mulsd	xmm3, xmm7
  4c8898: f2 0f 5c 3f                  	subsd	xmm7, qword ptr [edi]
  4c889c: f2 0f 5e df                  	divsd	xmm3, xmm7
  4c88a0: f2 0f 10 3d 48 e1 c2 00      	movsd	xmm7, qword ptr [0xc2e148]
  4c88a8: f2 0f 5e fc                  	divsd	xmm7, xmm4
  4c88ac: f2 0f 11 5c 24 5c            	movsd	qword ptr [esp + 0x5c], xmm3
  4c88b2: 0f 28 e1                     	movaps	xmm4, xmm1
  4c88b5: f2 0f 59 ef                  	mulsd	xmm5, xmm7
  4c88b9: f2 0f 11 6c 24 64            	movsd	qword ptr [esp + 0x64], xmm5
  4c88bf: f2 0f 59 e7                  	mulsd	xmm4, xmm7
  4c88c3: 8b 44 24 64                  	mov	eax, dword ptr [esp + 0x64]
  4c88c7: 8b 54 24 68                  	mov	edx, dword ptr [esp + 0x68]
  4c88cb: f2 0f 11 64 24 14            	movsd	qword ptr [esp + 0x14], xmm4
  4c88d1: f2 0f 10 44 24 14            	movsd	xmm0, qword ptr [esp + 0x14]
  4c88d7: f2 0f 11 44 24 6c            	movsd	qword ptr [esp + 0x6c], xmm0
  4c88dd: 8b 4c 24 6c                  	mov	ecx, dword ptr [esp + 0x6c]
  4c88e1: f2 0f 59 fa                  	mulsd	xmm7, xmm2
  4c88e5: f2 0f 11 7c 24 1c            	movsd	qword ptr [esp + 0x1c], xmm7
  4c88eb: f2 0f 10 4c 24 1c            	movsd	xmm1, qword ptr [esp + 0x1c]
  4c88f1: f2 0f 11 4c 24 74            	movsd	qword ptr [esp + 0x74], xmm1
  4c88f7: 0f 28 f5                     	movaps	xmm6, xmm5
  4c88fa: f2 0f 59 e3                  	mulsd	xmm4, xmm3
  4c88fe: f2 0f 58 66 08               	addsd	xmm4, qword ptr [esi + 0x8]
  4c8903: f2 0f 11 a4 24 ac 00 00 00   	movsd	qword ptr [esp + 0xac], xmm4
  4c890c: f2 0f 59 f3                  	mulsd	xmm6, xmm3
  4c8910: f2 0f 58 36                  	addsd	xmm6, qword ptr [esi]
  4c8914: f2 0f 11 b4 24 b4 00 00 00   	movsd	qword ptr [esp + 0xb4], xmm6
  4c891d: f2 0f 59 fb                  	mulsd	xmm7, xmm3
  4c8921: f2 0f 58 7e 10               	addsd	xmm7, qword ptr [esi + 0x10]
  4c8926: f2 0f 11 bc 24 bc 00 00 00   	movsd	qword ptr [esp + 0xbc], xmm7
  4c892f: 89 84 24 24 01 00 00         	mov	dword ptr [esp + 0x124], eax
  4c8936: 8b 44 24 70                  	mov	eax, dword ptr [esp + 0x70]
  4c893a: 89 94 24 28 01 00 00         	mov	dword ptr [esp + 0x128], edx
  4c8941: 8b 54 24 74                  	mov	edx, dword ptr [esp + 0x74]
  4c8945: 89 8c 24 2c 01 00 00         	mov	dword ptr [esp + 0x12c], ecx
  4c894c: 8b 4c 24 78                  	mov	ecx, dword ptr [esp + 0x78]
  4c8950: 89 84 24 30 01 00 00         	mov	dword ptr [esp + 0x130], eax
  4c8957: 89 94 24 34 01 00 00         	mov	dword ptr [esp + 0x134], edx
  4c895e: 89 8c 24 38 01 00 00         	mov	dword ptr [esp + 0x138], ecx
  4c8965: 8d 94 24 0c 01 00 00         	lea	edx, [esp + 0x10c]
  4c896c: 8d 84 24 24 01 00 00         	lea	eax, [esp + 0x124]
  4c8973: 50                           	push	eax
  4c8974: 52                           	push	edx
  4c8975: e8 e6 f3 fc ff               	call	0x497d60 <.text+0x96d60>
  4c897a: 83 c4 0c                     	add	esp, 0xc
  4c897d: 8b 84 24 08 01 00 00         	mov	eax, dword ptr [esp + 0x108]
  4c8984: 8b 94 24 0c 01 00 00         	mov	edx, dword ptr [esp + 0x10c]
  4c898b: 8b 8c 24 10 01 00 00         	mov	ecx, dword ptr [esp + 0x110]
  4c8992: f2 0f 10 a4 24 28 01 00 00   	movsd	xmm4, qword ptr [esp + 0x128]
  4c899b: f2 0f 10 b4 24 30 01 00 00   	movsd	xmm6, qword ptr [esp + 0x130]
  4c89a4: f2 0f 10 94 24 20 01 00 00   	movsd	xmm2, qword ptr [esp + 0x120]
  4c89ad: 0f 28 ec                     	movaps	xmm5, xmm4
  4c89b0: 0f 28 c6                     	movaps	xmm0, xmm6
  4c89b3: 89 84 24 38 01 00 00         	mov	dword ptr [esp + 0x138], eax
  4c89ba: 8b 84 24 14 01 00 00         	mov	eax, dword ptr [esp + 0x114]
  4c89c1: 89 94 24 3c 01 00 00         	mov	dword ptr [esp + 0x13c], edx
  4c89c8: 8b 94 24 18 01 00 00         	mov	edx, dword ptr [esp + 0x118]
  4c89cf: f2 0f 10 9c 24 38 01 00 00   	movsd	xmm3, qword ptr [esp + 0x138]
  4c89d8: f2 0f 59 f3                  	mulsd	xmm6, xmm3
  4c89dc: f2 0f 59 e3                  	mulsd	xmm4, xmm3
  4c89e0: 89 8c 24 40 01 00 00         	mov	dword ptr [esp + 0x140], ecx
  4c89e7: 8b 8c 24 1c 01 00 00         	mov	ecx, dword ptr [esp + 0x11c]
  4c89ee: 89 84 24 44 01 00 00         	mov	dword ptr [esp + 0x144], eax
  4c89f5: f2 0f 10 bc 24 40 01 00 00   	movsd	xmm7, qword ptr [esp + 0x140]
  4c89fe: f2 0f 59 c7                  	mulsd	xmm0, xmm7
  4c8a02: f2 0f 59 fa                  	mulsd	xmm7, xmm2
  4c8a06: 89 94 24 48 01 00 00         	mov	dword ptr [esp + 0x148], edx
  4c8a0d: 89 8c 24 4c 01 00 00         	mov	dword ptr [esp + 0x14c], ecx
  4c8a14: f2 0f 10 8c 24 48 01 00 00   	movsd	xmm1, qword ptr [esp + 0x148]
  4c8a1d: f2 0f 59 e9                  	mulsd	xmm5, xmm1
  4c8a21: f2 0f 59 ca                  	mulsd	xmm1, xmm2
  4c8a25: f2 0f 5c fc                  	subsd	xmm7, xmm4
  4c8a29: f2 0f 11 bc 24 18 01 00 00   	movsd	qword ptr [esp + 0x118], xmm7
  4c8a32: f2 0f 5c e8                  	subsd	xmm5, xmm0
  4c8a36: f2 0f 10 44 24 50            	movsd	xmm0, qword ptr [esp + 0x50]
  4c8a3c: f2 0f 11 ac 24 08 01 00 00   	movsd	qword ptr [esp + 0x108], xmm5
  4c8a45: f2 0f 59 c0                  	mulsd	xmm0, xmm0
  4c8a49: 8b 84 24 08 01 00 00         	mov	eax, dword ptr [esp + 0x108]
  4c8a50: 8b 94 24 0c 01 00 00         	mov	edx, dword ptr [esp + 0x10c]
  4c8a57: f2 0f 11 44 24 78            	movsd	qword ptr [esp + 0x78], xmm0
  4c8a5d: f2 0f 5c f1                  	subsd	xmm6, xmm1
  4c8a61: f2 0f 11 b4 24 10 01 00 00   	movsd	qword ptr [esp + 0x110], xmm6
  4c8a6a: 8b 8c 24 10 01 00 00         	mov	ecx, dword ptr [esp + 0x110]
  4c8a71: 0f 28 c8                     	movaps	xmm1, xmm0
  4c8a74: f2 0f 5e 0c 24               	divsd	xmm1, qword ptr [esp]
  4c8a79: f2 0f 11 8c 24 c0 00 00 00   	movsd	qword ptr [esp + 0xc0], xmm1
  4c8a82: f2 0f 59 c9                  	mulsd	xmm1, xmm1
  4c8a86: 89 84 24 50 01 00 00         	mov	dword ptr [esp + 0x150], eax
  4c8a8d: 8b 84 24 14 01 00 00         	mov	eax, dword ptr [esp + 0x114]
  4c8a94: 89 94 24 54 01 00 00         	mov	dword ptr [esp + 0x154], edx
  4c8a9b: 8b 94 24 18 01 00 00         	mov	edx, dword ptr [esp + 0x118]
  4c8aa2: 89 8c 24 58 01 00 00         	mov	dword ptr [esp + 0x158], ecx
  4c8aa9: 8b 8c 24 1c 01 00 00         	mov	ecx, dword ptr [esp + 0x11c]
  4c8ab0: 89 84 24 5c 01 00 00         	mov	dword ptr [esp + 0x15c], eax
  4c8ab7: f2 0f 5c c1                  	subsd	xmm0, xmm1
  4c8abb: 89 94 24 60 01 00 00         	mov	dword ptr [esp + 0x160], edx
  4c8ac2: f2 0f 51 d0                  	sqrtsd	xmm2, xmm0
  4c8ac6: f2 0f 11 94 24 c8 00 00 00   	movsd	qword ptr [esp + 0xc8], xmm2
  4c8acf: 89 8c 24 64 01 00 00         	mov	dword ptr [esp + 0x164], ecx
  4c8ad6: 68 ff ff 0f 00               	push	0xfffff
  4c8adb: ff 15 30 59 c2 00            	call	dword ptr [0xc25930]
  4c8ae1: 6a 00                        	push	0x0
  4c8ae3: ff 15 c8 59 c2 00            	call	dword ptr [0xc259c8]
  4c8ae9: 68 44 0b 00 00               	push	0xb44
  4c8aee: ff 15 18 59 c2 00            	call	dword ptr [0xc25918]
  4c8af4: ff 15 04 59 c2 00            	call	dword ptr [0xc25904]
  4c8afa: 68 50 0b 00 00               	push	0xb50
  4c8aff: ff 15 18 59 c2 00            	call	dword ptr [0xc25918]
  4c8b05: 68 e2 0b 00 00               	push	0xbe2
  4c8b0a: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  4c8b10: 33 c0                        	xor	eax, eax
  4c8b12: 83 c4 f0                     	add	esp, -0x10
  4c8b15: c7 04 24 00 00 34 43         	mov	dword ptr [esp], 0x43340000
  4c8b1c: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  4c8b20: c7 44 24 0c 00 00 80 3f      	mov	dword ptr [esp + 0xc], 0x3f800000
  4c8b28: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  4c8b2c: ff 15 60 59 c2 00            	call	dword ptr [0xc25960]
  4c8b32: b8 00 00 80 bf               	mov	eax, 0xbf800000
  4c8b37: 50                           	push	eax
  4c8b38: 50                           	push	eax
  4c8b39: ff 15 f4 59 c2 00            	call	dword ptr [0xc259f4]
  4c8b3f: 68 37 80 00 00               	push	0x8037
  4c8b44: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  4c8b4a: 0f be 15 28 1e d7 00         	movsx	edx, byte ptr [0xd71e28]
  4c8b51: f6 c2 04                     	test	dl, 0x4
  4c8b54: 0f 85 bf 0a 00 00            	jne	0x4c9619 <.text+0xc8619>
  4c8b5a: f2 0f 10 5c 24 50            	movsd	xmm3, qword ptr [esp + 0x50]
  4c8b60: 8b 45 0c                     	mov	eax, dword ptr [ebp + 0xc]
  4c8b63: f2 0f 10 2b                  	movsd	xmm5, qword ptr [ebx]
  4c8b67: f2 0f 5c 2e                  	subsd	xmm5, qword ptr [esi]
  4c8b6b: 0f 28 d5                     	movaps	xmm2, xmm5
  4c8b6e: f2 0f 59 d5                  	mulsd	xmm2, xmm5
  4c8b72: f2 0f 10 4b 08               	movsd	xmm1, qword ptr [ebx + 0x8]
  4c8b77: f2 0f 5c 4e 08               	subsd	xmm1, qword ptr [esi + 0x8]
  4c8b7c: 0f 28 f9                     	movaps	xmm7, xmm1
  4c8b7f: f2 0f 59 f9                  	mulsd	xmm7, xmm1
  4c8b83: f2 0f 10 73 10               	movsd	xmm6, qword ptr [ebx + 0x10]
  4c8b88: f2 0f 5c 76 10               	subsd	xmm6, qword ptr [esi + 0x10]
  4c8b8d: f2 0f 10 27                  	movsd	xmm4, qword ptr [edi]
  4c8b91: f2 0f 11 b4 24 10 02 00 00   	movsd	qword ptr [esp + 0x210], xmm6
  4c8b9a: f2 0f 59 f6                  	mulsd	xmm6, xmm6
  4c8b9e: f2 0f 58 d7                  	addsd	xmm2, xmm7
  4c8ba2: f2 0f 10 38                  	movsd	xmm7, qword ptr [eax]
  4c8ba6: f2 0f 5c 3e                  	subsd	xmm7, qword ptr [esi]
  4c8baa: f2 0f 11 7c 24 18            	movsd	qword ptr [esp + 0x18], xmm7
  4c8bb0: f2 0f 59 ff                  	mulsd	xmm7, xmm7
  4c8bb4: f2 0f 58 d6                  	addsd	xmm2, xmm6
  4c8bb8: 0f 28 f3                     	movaps	xmm6, xmm3
  4c8bbb: f2 0f 51 c2                  	sqrtsd	xmm0, xmm2
  4c8bbf: f2 0f 59 f0                  	mulsd	xmm6, xmm0
  4c8bc3: f2 0f 10 50 10               	movsd	xmm2, qword ptr [eax + 0x10]
  4c8bc8: f2 0f 5c 56 10               	subsd	xmm2, qword ptr [esi + 0x10]
  4c8bcd: f2 0f 11 54 24 20            	movsd	qword ptr [esp + 0x20], xmm2
  4c8bd3: f2 0f 59 d2                  	mulsd	xmm2, xmm2
  4c8bd7: f2 0f 58 e3                  	addsd	xmm4, xmm3
  4c8bdb: f2 0f 5e f4                  	divsd	xmm6, xmm4
  4c8bdf: f2 0f 10 60 08               	movsd	xmm4, qword ptr [eax + 0x8]
  4c8be4: f2 0f 5c 66 08               	subsd	xmm4, qword ptr [esi + 0x8]
  4c8be9: f2 0f 11 a4 24 10 01 00 00   	movsd	qword ptr [esp + 0x110], xmm4
  4c8bf2: 0f 28 dc                     	movaps	xmm3, xmm4
  4c8bf5: f2 0f 59 dc                  	mulsd	xmm3, xmm4
  4c8bf9: f2 0f 58 fb                  	addsd	xmm7, xmm3
  4c8bfd: f2 0f 58 fa                  	addsd	xmm7, xmm2
  4c8c01: f2 0f 10 64 24 20            	movsd	xmm4, qword ptr [esp + 0x20]
  4c8c07: f2 0f 11 a4 24 18 01 00 00   	movsd	qword ptr [esp + 0x118], xmm4
  4c8c10: f2 0f 51 d7                  	sqrtsd	xmm2, xmm7
  4c8c14: 0f 28 da                     	movaps	xmm3, xmm2
  4c8c17: f2 0f 10 3d 48 e1 c2 00      	movsd	xmm7, qword ptr [0xc2e148]
  4c8c1f: f2 0f 5e f8                  	divsd	xmm7, xmm0
  4c8c23: f2 0f 59 ef                  	mulsd	xmm5, xmm7
  4c8c27: f2 0f 10 84 24 10 02 00 00   	movsd	xmm0, qword ptr [esp + 0x210]
  4c8c30: f2 0f 11 6c 24 60            	movsd	qword ptr [esp + 0x60], xmm5
  4c8c36: f2 0f 59 cf                  	mulsd	xmm1, xmm7
  4c8c3a: f2 0f 11 4c 24 68            	movsd	qword ptr [esp + 0x68], xmm1
  4c8c40: f2 0f 59 c7                  	mulsd	xmm0, xmm7
  4c8c44: f2 0f 11 44 24 70            	movsd	qword ptr [esp + 0x70], xmm0
  4c8c4a: f2 0f 59 ee                  	mulsd	xmm5, xmm6
  4c8c4e: f2 0f 59 ce                  	mulsd	xmm1, xmm6
  4c8c52: f2 0f 59 c6                  	mulsd	xmm0, xmm6
  4c8c56: f2 0f 58 2e                  	addsd	xmm5, qword ptr [esi]
  4c8c5a: f2 0f 58 4e 08               	addsd	xmm1, qword ptr [esi + 0x8]
  4c8c5f: f2 0f 58 46 10               	addsd	xmm0, qword ptr [esi + 0x10]
  4c8c64: f2 0f 11 8c 24 18 02 00 00   	movsd	qword ptr [esp + 0x218], xmm1
  4c8c6d: f2 0f 11 84 24 10 02 00 00   	movsd	qword ptr [esp + 0x210], xmm0
  4c8c76: f2 0f 10 44 24 78            	movsd	xmm0, qword ptr [esp + 0x78]
  4c8c7c: 0f 28 c8                     	movaps	xmm1, xmm0
  4c8c7f: f2 0f 5e ce                  	divsd	xmm1, xmm6
  4c8c83: f2 0f 11 8c 24 28 02 00 00   	movsd	qword ptr [esp + 0x228], xmm1
  4c8c8c: f2 0f 5c de                  	subsd	xmm3, xmm6
  4c8c90: 0f 28 f9                     	movaps	xmm7, xmm1
  4c8c93: f2 0f 59 f9                  	mulsd	xmm7, xmm1
  4c8c97: f2 0f 5c c7                  	subsd	xmm0, xmm7
  4c8c9b: f2 0f 51 f8                  	sqrtsd	xmm7, xmm0
  4c8c9f: f2 0f 10 44 24 18            	movsd	xmm0, qword ptr [esp + 0x18]
  4c8ca5: f2 0f 11 bc 24 20 02 00 00   	movsd	qword ptr [esp + 0x220], xmm7
  4c8cae: f2 0f 11 84 24 08 01 00 00   	movsd	qword ptr [esp + 0x108], xmm0
  4c8cb7: f2 0f 10 44 24 58            	movsd	xmm0, qword ptr [esp + 0x58]
  4c8cbd: 0f 28 e0                     	movaps	xmm4, xmm0
  4c8cc0: 66 0f 2f c2                  	comisd	xmm0, xmm2
  4c8cc4: f2 0f 5c e6                  	subsd	xmm4, xmm6
  4c8cc8: 77 03                        	ja	0x4c8ccd <.text+0xc7ccd>
  4c8cca: 0f 28 e3                     	movaps	xmm4, xmm3
  4c8ccd: f2 0f 11 a4 24 08 02 00 00   	movsd	qword ptr [esp + 0x208], xmm4
  4c8cd6: f2 0f 59 e1                  	mulsd	xmm4, xmm1
  4c8cda: f2 0f 5e e7                  	divsd	xmm4, xmm7
  4c8cde: f2 0f 11 a4 24 00 02 00 00   	movsd	qword ptr [esp + 0x200], xmm4
  4c8ce7: f6 c2 08                     	test	dl, 0x8
  4c8cea: 75 19                        	jne	0x4c8d05 <.text+0xc7d05>
  4c8cec: ff 15 08 59 c2 00            	call	dword ptr [0xc25908]
  4c8cf2: ff 15 34 59 c2 00            	call	dword ptr [0xc25934]
  4c8cf8: 81 c4 34 02 00 00            	add	esp, 0x234
  4c8cfe: 5b                           	pop	ebx
  4c8cff: 5e                           	pop	esi
  4c8d00: 5f                           	pop	edi
  4c8d01: 8b e5                        	mov	esp, ebp
  4c8d03: 5d                           	pop	ebp
  4c8d04: c3                           	ret
  4c8d05: bf 00 00 00 3f               	mov	edi, 0x3f000000
  4c8d0a: 83 c4 f0                     	add	esp, -0x10
  4c8d0d: f2 0f 11 ac 24 78 01 00 00   	movsd	qword ptr [esp + 0x178], xmm5
  4c8d16: f2 0f 11 b4 24 88 00 00 00   	movsd	qword ptr [esp + 0x88], xmm6
  4c8d1f: 89 7c 24 0c                  	mov	dword ptr [esp + 0xc], edi
  4c8d23: c7 04 24 00 00 80 3f         	mov	dword ptr [esp], 0x3f800000
  4c8d2a: 33 c0                        	xor	eax, eax
  4c8d2c: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  4c8d30: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  4c8d34: ff 15 70 59 c2 00            	call	dword ptr [0xc25970]
  4c8d3a: 6a 06                        	push	0x6
  4c8d3c: ff 15 d4 58 c2 00            	call	dword ptr [0xc258d4]
  4c8d42: f2 0f 10 ac 24 68 01 00 00   	movsd	xmm5, qword ptr [esp + 0x168]
  4c8d4b: 0f 28 fd                     	movaps	xmm7, xmm5
  4c8d4e: f2 0f 10 a4 24 18 02 00 00   	movsd	xmm4, qword ptr [esp + 0x218]
  4c8d57: 8b 45 0c                     	mov	eax, dword ptr [ebp + 0xc]
  4c8d5a: f2 0f 5c 38                  	subsd	xmm7, qword ptr [eax]
  4c8d5e: f2 0f 5c 60 08               	subsd	xmm4, qword ptr [eax + 0x8]
  4c8d63: f2 0f 10 9c 24 10 02 00 00   	movsd	xmm3, qword ptr [esp + 0x210]
  4c8d6c: f2 0f 5c 58 10               	subsd	xmm3, qword ptr [eax + 0x10]
  4c8d71: 8b 55 24                     	mov	edx, dword ptr [ebp + 0x24]
  4c8d74: 8b 4d 10                     	mov	ecx, dword ptr [ebp + 0x10]
  4c8d77: f2 0f 10 12                  	movsd	xmm2, qword ptr [edx]
  4c8d7b: f2 0f 10 4a 08               	movsd	xmm1, qword ptr [edx + 0x8]
  4c8d80: f2 0f 10 42 10               	movsd	xmm0, qword ptr [edx + 0x10]
  4c8d85: f2 0f 11 7c 24 48            	movsd	qword ptr [esp + 0x48], xmm7
  4c8d8b: f2 0f 11 64 24 50            	movsd	qword ptr [esp + 0x50], xmm4
  4c8d91: f2 0f 11 5c 24 58            	movsd	qword ptr [esp + 0x58], xmm3
  4c8d97: f2 0f 59 d7                  	mulsd	xmm2, xmm7
  4c8d9b: f2 0f 59 cc                  	mulsd	xmm1, xmm4
  4c8d9f: f2 0f 59 c3                  	mulsd	xmm0, xmm3
  4c8da3: 8d 5c 24 60                  	lea	ebx, [esp + 0x60]
  4c8da7: f2 0f 58 d1                  	addsd	xmm2, xmm1
  4c8dab: f2 0f 10 4a 18               	movsd	xmm1, qword ptr [edx + 0x18]
  4c8db0: f2 0f 59 cf                  	mulsd	xmm1, xmm7
  4c8db4: f2 0f 58 d0                  	addsd	xmm2, xmm0
  4c8db8: f2 0f 10 42 20               	movsd	xmm0, qword ptr [edx + 0x20]
  4c8dbd: f2 0f 59 c4                  	mulsd	xmm0, xmm4
  4c8dc1: f2 0f 58 c8                  	addsd	xmm1, xmm0
  4c8dc5: f2 0f 10 42 28               	movsd	xmm0, qword ptr [edx + 0x28]
  4c8dca: f2 0f 59 c3                  	mulsd	xmm0, xmm3
  4c8dce: f2 0f 58 c8                  	addsd	xmm1, xmm0
  4c8dd2: f2 0f 10 42 30               	movsd	xmm0, qword ptr [edx + 0x30]
  4c8dd7: f2 0f 59 c7                  	mulsd	xmm0, xmm7
  4c8ddb: f2 0f 10 7a 38               	movsd	xmm7, qword ptr [edx + 0x38]
  4c8de0: f2 0f 59 fc                  	mulsd	xmm7, xmm4
  4c8de4: f2 0f 10 62 40               	movsd	xmm4, qword ptr [edx + 0x40]
  4c8de9: f2 0f 59 e3                  	mulsd	xmm4, xmm3
  4c8ded: f2 0f 10 1d 48 e1 c2 00      	movsd	xmm3, qword ptr [0xc2e148]
  4c8df5: f2 0f 5e 19                  	divsd	xmm3, qword ptr [ecx]
  4c8df9: f2 0f 59 d3                  	mulsd	xmm2, xmm3
  4c8dfd: f2 0f 11 54 24 60            	movsd	qword ptr [esp + 0x60], xmm2
  4c8e03: f2 0f 59 cb                  	mulsd	xmm1, xmm3
  4c8e07: f2 0f 11 4c 24 68            	movsd	qword ptr [esp + 0x68], xmm1
  4c8e0d: f2 0f 58 c7                  	addsd	xmm0, xmm7
  4c8e11: f2 0f 58 c4                  	addsd	xmm0, xmm4
  4c8e15: f2 0f 59 d8                  	mulsd	xmm3, xmm0
  4c8e19: f2 0f 11 5c 24 70            	movsd	qword ptr [esp + 0x70], xmm3
  4c8e1f: 53                           	push	ebx
  4c8e20: ff 15 f8 59 c2 00            	call	dword ptr [0xc259f8]
  4c8e26: 83 c4 f0                     	add	esp, -0x10
  4c8e29: 33 c0                        	xor	eax, eax
  4c8e2b: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  4c8e2f: c7 04 24 00 00 80 3f         	mov	dword ptr [esp], 0x3f800000
  4c8e36: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  4c8e3a: 89 44 24 0c                  	mov	dword ptr [esp + 0xc], eax
  4c8e3e: ff 15 70 59 c2 00            	call	dword ptr [0xc25970]
  4c8e44: 8b 7d 24                     	mov	edi, dword ptr [ebp + 0x24]
  4c8e47: bb 40 00 00 00               	mov	ebx, 0x40
  4c8e4c: f2 0f 2a c3                  	cvtsi2sd	xmm0, ebx
  4c8e50: f2 0f 59 05 40 e1 c2 00      	mulsd	xmm0, qword ptr [0xc2e140]
  4c8e58: e8 b3 5f 5c 00               	call	0xa8ee10 <.text+0x68de10>
  4c8e5d: f2 0f 10 94 24 20 01 00 00   	movsd	xmm2, qword ptr [esp + 0x120]
  4c8e66: f2 0f 10 a4 24 28 02 00 00   	movsd	xmm4, qword ptr [esp + 0x228]
  4c8e6f: f2 0f 59 d4                  	mulsd	xmm2, xmm4
  4c8e73: f2 0f 58 16                  	addsd	xmm2, qword ptr [esi]
  4c8e77: f2 0f 10 ac 24 28 01 00 00   	movsd	xmm5, qword ptr [esp + 0x128]
  4c8e80: f2 0f 59 ec                  	mulsd	xmm5, xmm4
  4c8e84: f2 0f 58 6e 08               	addsd	xmm5, qword ptr [esi + 0x8]
  4c8e89: f2 0f 10 b4 24 30 01 00 00   	movsd	xmm6, qword ptr [esp + 0x130]
  4c8e92: f2 0f 10 bc 24 40 01 00 00   	movsd	xmm7, qword ptr [esp + 0x140]
  4c8e9b: f2 0f 10 9c 24 48 01 00 00   	movsd	xmm3, qword ptr [esp + 0x148]
  4c8ea4: 8b 45 0c                     	mov	eax, dword ptr [ebp + 0xc]
  4c8ea7: 8b 55 10                     	mov	edx, dword ptr [ebp + 0x10]
  4c8eaa: f2 0f 11 6c 24 18            	movsd	qword ptr [esp + 0x18], xmm5
  4c8eb0: f2 0f 59 f4                  	mulsd	xmm6, xmm4
  4c8eb4: f2 0f 59 f9                  	mulsd	xmm7, xmm1
  4c8eb8: f2 0f 59 d9                  	mulsd	xmm3, xmm1
  4c8ebc: f2 0f 58 76 10               	addsd	xmm6, qword ptr [esi + 0x10]
  4c8ec1: f2 0f 10 a4 24 58 01 00 00   	movsd	xmm4, qword ptr [esp + 0x158]
  4c8eca: f2 0f 10 ac 24 60 01 00 00   	movsd	xmm5, qword ptr [esp + 0x160]
  4c8ed3: f2 0f 11 74 24 20            	movsd	qword ptr [esp + 0x20], xmm6
  4c8ed9: f2 0f 59 e0                  	mulsd	xmm4, xmm0
  4c8edd: f2 0f 59 e8                  	mulsd	xmm5, xmm0
  4c8ee1: f2 0f 58 fc                  	addsd	xmm7, xmm4
  4c8ee5: f2 0f 58 dd                  	addsd	xmm3, xmm5
  4c8ee9: f2 0f 10 b4 24 38 01 00 00   	movsd	xmm6, qword ptr [esp + 0x138]
  4c8ef2: f2 0f 59 f1                  	mulsd	xmm6, xmm1
  4c8ef6: f2 0f 10 8c 24 50 01 00 00   	movsd	xmm1, qword ptr [esp + 0x150]
  4c8eff: f2 0f 59 c8                  	mulsd	xmm1, xmm0
  4c8f03: f2 0f 58 f1                  	addsd	xmm6, xmm1
  4c8f07: f2 0f 10 4f 20               	movsd	xmm1, qword ptr [edi + 0x20]
  4c8f0c: f2 0f 10 84 24 20 02 00 00   	movsd	xmm0, qword ptr [esp + 0x220]
  4c8f15: f2 0f 59 f0                  	mulsd	xmm6, xmm0
  4c8f19: f2 0f 59 f8                  	mulsd	xmm7, xmm0
  4c8f1d: f2 0f 59 d8                  	mulsd	xmm3, xmm0
  4c8f21: f2 0f 10 47 10               	movsd	xmm0, qword ptr [edi + 0x10]
  4c8f26: f2 0f 58 d6                  	addsd	xmm2, xmm6
  4c8f2a: f2 0f 5c 10                  	subsd	xmm2, qword ptr [eax]
  4c8f2e: f2 0f 10 6c 24 18            	movsd	xmm5, qword ptr [esp + 0x18]
  4c8f34: f2 0f 10 64 24 20            	movsd	xmm4, qword ptr [esp + 0x20]
  4c8f3a: f2 0f 10 77 28               	movsd	xmm6, qword ptr [edi + 0x28]
  4c8f3f: f2 0f 58 ef                  	addsd	xmm5, xmm7
  4c8f43: f2 0f 5c 68 08               	subsd	xmm5, qword ptr [eax + 0x8]
  4c8f48: f2 0f 59 cd                  	mulsd	xmm1, xmm5
  4c8f4c: 8d 8c 24 f0 00 00 00         	lea	ecx, [esp + 0xf0]
  4c8f53: f2 0f 10 7f 08               	movsd	xmm7, qword ptr [edi + 0x8]
  4c8f58: f2 0f 59 fd                  	mulsd	xmm7, xmm5
  4c8f5c: f2 0f 58 e3                  	addsd	xmm4, xmm3
  4c8f60: f2 0f 5c 60 10               	subsd	xmm4, qword ptr [eax + 0x10]
  4c8f65: f2 0f 59 c4                  	mulsd	xmm0, xmm4
  4c8f69: f2 0f 59 f4                  	mulsd	xmm6, xmm4
  4c8f6d: f2 0f 10 1f                  	movsd	xmm3, qword ptr [edi]
  4c8f71: f2 0f 59 da                  	mulsd	xmm3, xmm2
  4c8f75: f2 0f 58 df                  	addsd	xmm3, xmm7
  4c8f79: f2 0f 58 d8                  	addsd	xmm3, xmm0
  4c8f7d: f2 0f 10 47 18               	movsd	xmm0, qword ptr [edi + 0x18]
  4c8f82: f2 0f 59 c2                  	mulsd	xmm0, xmm2
  4c8f86: f2 0f 58 c1                  	addsd	xmm0, xmm1
  4c8f8a: f2 0f 10 4f 30               	movsd	xmm1, qword ptr [edi + 0x30]
  4c8f8f: f2 0f 59 ca                  	mulsd	xmm1, xmm2
  4c8f93: f2 0f 10 57 38               	movsd	xmm2, qword ptr [edi + 0x38]
  4c8f98: f2 0f 59 d5                  	mulsd	xmm2, xmm5
  4c8f9c: f2 0f 10 6f 40               	movsd	xmm5, qword ptr [edi + 0x40]
  4c8fa1: f2 0f 59 ec                  	mulsd	xmm5, xmm4
  4c8fa5: f2 0f 10 25 48 e1 c2 00      	movsd	xmm4, qword ptr [0xc2e148]
  4c8fad: f2 0f 5e 22                  	divsd	xmm4, qword ptr [edx]
  4c8fb1: f2 0f 59 dc                  	mulsd	xmm3, xmm4
  4c8fb5: f2 0f 11 9c 24 f0 00 00 00   	movsd	qword ptr [esp + 0xf0], xmm3
  4c8fbe: f2 0f 58 c6                  	addsd	xmm0, xmm6
  4c8fc2: f2 0f 59 c4                  	mulsd	xmm0, xmm4
  4c8fc6: f2 0f 11 84 24 f8 00 00 00   	movsd	qword ptr [esp + 0xf8], xmm0
  4c8fcf: f2 0f 58 ca                  	addsd	xmm1, xmm2
  4c8fd3: f2 0f 58 cd                  	addsd	xmm1, xmm5
  4c8fd7: f2 0f 59 e1                  	mulsd	xmm4, xmm1
  4c8fdb: f2 0f 11 a4 24 00 01 00 00   	movsd	qword ptr [esp + 0x100], xmm4
  4c8fe4: 51                           	push	ecx
  4c8fe5: ff 15 f8 59 c2 00            	call	dword ptr [0xc259f8]
  4c8feb: 4b                           	dec	ebx
  4c8fec: 0f 8d 5a fe ff ff            	jge	0x4c8e4c <.text+0xc7e4c>
  4c8ff2: bf 00 00 00 3f               	mov	edi, 0x3f000000
  4c8ff7: ff 15 e4 58 c2 00            	call	dword ptr [0xc258e4]
  4c8ffd: 83 c4 f0                     	add	esp, -0x10
  4c9000: 89 7c 24 0c                  	mov	dword ptr [esp + 0xc], edi
  4c9004: 33 c0                        	xor	eax, eax
  4c9006: c7 04 24 00 00 80 3f         	mov	dword ptr [esp], 0x3f800000
  4c900d: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  4c9011: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  4c9015: ff 15 70 59 c2 00            	call	dword ptr [0xc25970]
  4c901b: 6a 06                        	push	0x6
  4c901d: ff 15 d4 58 c2 00            	call	dword ptr [0xc258d4]
  4c9023: f2 0f 10 ac 24 68 01 00 00   	movsd	xmm5, qword ptr [esp + 0x168]
  4c902c: 0f 28 fd                     	movaps	xmm7, xmm5
  4c902f: f2 0f 10 a4 24 18 02 00 00   	movsd	xmm4, qword ptr [esp + 0x218]
  4c9038: 8b 45 0c                     	mov	eax, dword ptr [ebp + 0xc]
  4c903b: f2 0f 5c 38                  	subsd	xmm7, qword ptr [eax]
  4c903f: f2 0f 5c 60 08               	subsd	xmm4, qword ptr [eax + 0x8]
  4c9044: f2 0f 10 9c 24 10 02 00 00   	movsd	xmm3, qword ptr [esp + 0x210]
  4c904d: f2 0f 5c 58 10               	subsd	xmm3, qword ptr [eax + 0x10]
  4c9052: 8b 55 24                     	mov	edx, dword ptr [ebp + 0x24]
  4c9055: 8b 4d 10                     	mov	ecx, dword ptr [ebp + 0x10]
  4c9058: f2 0f 10 12                  	movsd	xmm2, qword ptr [edx]
  4c905c: f2 0f 10 4a 08               	movsd	xmm1, qword ptr [edx + 0x8]
  4c9061: f2 0f 10 42 10               	movsd	xmm0, qword ptr [edx + 0x10]
  4c9066: f2 0f 11 7c 24 60            	movsd	qword ptr [esp + 0x60], xmm7
  4c906c: f2 0f 11 64 24 68            	movsd	qword ptr [esp + 0x68], xmm4
  4c9072: f2 0f 11 5c 24 70            	movsd	qword ptr [esp + 0x70], xmm3
  4c9078: f2 0f 59 d7                  	mulsd	xmm2, xmm7
  4c907c: f2 0f 59 cc                  	mulsd	xmm1, xmm4
  4c9080: f2 0f 59 c3                  	mulsd	xmm0, xmm3
  4c9084: 8d 5c 24 48                  	lea	ebx, [esp + 0x48]
  4c9088: f2 0f 58 d1                  	addsd	xmm2, xmm1
  4c908c: f2 0f 10 4a 18               	movsd	xmm1, qword ptr [edx + 0x18]
  4c9091: f2 0f 59 cf                  	mulsd	xmm1, xmm7
  4c9095: f2 0f 58 d0                  	addsd	xmm2, xmm0
  4c9099: f2 0f 10 42 20               	movsd	xmm0, qword ptr [edx + 0x20]
  4c909e: f2 0f 59 c4                  	mulsd	xmm0, xmm4
  4c90a2: f2 0f 58 c8                  	addsd	xmm1, xmm0
  4c90a6: f2 0f 10 42 28               	movsd	xmm0, qword ptr [edx + 0x28]
  4c90ab: f2 0f 59 c3                  	mulsd	xmm0, xmm3
  4c90af: f2 0f 58 c8                  	addsd	xmm1, xmm0
  4c90b3: f2 0f 10 42 30               	movsd	xmm0, qword ptr [edx + 0x30]
  4c90b8: f2 0f 59 c7                  	mulsd	xmm0, xmm7
  4c90bc: f2 0f 10 7a 38               	movsd	xmm7, qword ptr [edx + 0x38]
  4c90c1: f2 0f 59 fc                  	mulsd	xmm7, xmm4
  4c90c5: f2 0f 10 62 40               	movsd	xmm4, qword ptr [edx + 0x40]
  4c90ca: f2 0f 59 e3                  	mulsd	xmm4, xmm3
  4c90ce: f2 0f 10 1d 48 e1 c2 00      	movsd	xmm3, qword ptr [0xc2e148]
  4c90d6: f2 0f 5e 19                  	divsd	xmm3, qword ptr [ecx]
  4c90da: f2 0f 59 d3                  	mulsd	xmm2, xmm3
  4c90de: f2 0f 11 54 24 48            	movsd	qword ptr [esp + 0x48], xmm2
  4c90e4: f2 0f 59 cb                  	mulsd	xmm1, xmm3
  4c90e8: f2 0f 11 4c 24 50            	movsd	qword ptr [esp + 0x50], xmm1
  4c90ee: f2 0f 58 c7                  	addsd	xmm0, xmm7
  4c90f2: f2 0f 58 c4                  	addsd	xmm0, xmm4
  4c90f6: f2 0f 59 d8                  	mulsd	xmm3, xmm0
  4c90fa: f2 0f 11 5c 24 58            	movsd	qword ptr [esp + 0x58], xmm3
  4c9100: 53                           	push	ebx
  4c9101: ff 15 f8 59 c2 00            	call	dword ptr [0xc259f8]
  4c9107: 83 c4 f0                     	add	esp, -0x10
  4c910a: 89 7c 24 0c                  	mov	dword ptr [esp + 0xc], edi
  4c910e: 33 c0                        	xor	eax, eax
  4c9110: c7 04 24 00 00 80 3f         	mov	dword ptr [esp], 0x3f800000
  4c9117: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  4c911b: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  4c911f: ff 15 70 59 c2 00            	call	dword ptr [0xc25970]
  4c9125: 8b 75 0c                     	mov	esi, dword ptr [ebp + 0xc]
  4c9128: 8b 7d 24                     	mov	edi, dword ptr [ebp + 0x24]
  4c912b: 33 db                        	xor	ebx, ebx
  4c912d: f2 0f 2a c3                  	cvtsi2sd	xmm0, ebx
  4c9131: f2 0f 59 05 40 e1 c2 00      	mulsd	xmm0, qword ptr [0xc2e140]
  4c9139: e8 d2 5c 5c 00               	call	0xa8ee10 <.text+0x68de10>
  4c913e: f2 0f 10 ac 24 20 01 00 00   	movsd	xmm5, qword ptr [esp + 0x120]
  4c9147: f2 0f 10 a4 24 08 02 00 00   	movsd	xmm4, qword ptr [esp + 0x208]
  4c9150: f2 0f 10 b4 24 28 01 00 00   	movsd	xmm6, qword ptr [esp + 0x128]
  4c9159: f2 0f 10 bc 24 30 01 00 00   	movsd	xmm7, qword ptr [esp + 0x130]
  4c9162: 8b 45 10                     	mov	eax, dword ptr [ebp + 0x10]
  4c9165: f2 0f 11 ac 24 78 01 00 00   	movsd	qword ptr [esp + 0x178], xmm5
  4c916e: f2 0f 11 b4 24 80 01 00 00   	movsd	qword ptr [esp + 0x180], xmm6
  4c9177: f2 0f 11 bc 24 70 01 00 00   	movsd	qword ptr [esp + 0x170], xmm7
  4c9180: 0f 28 dc                     	movaps	xmm3, xmm4
  4c9183: 0f 28 d4                     	movaps	xmm2, xmm4
  4c9186: f2 0f 59 e7                  	mulsd	xmm4, xmm7
  4c918a: f2 0f 10 bc 24 58 01 00 00   	movsd	xmm7, qword ptr [esp + 0x158]
  4c9193: f2 0f 11 a4 24 d8 01 00 00   	movsd	qword ptr [esp + 0x1d8], xmm4
  4c919c: f2 0f 59 dd                  	mulsd	xmm3, xmm5
  4c91a0: f2 0f 10 ac 24 68 01 00 00   	movsd	xmm5, qword ptr [esp + 0x168]
  4c91a9: f2 0f 11 9c 24 c8 01 00 00   	movsd	qword ptr [esp + 0x1c8], xmm3
  4c91b2: f2 0f 59 d6                  	mulsd	xmm2, xmm6
  4c91b6: f2 0f 10 b4 24 18 02 00 00   	movsd	xmm6, qword ptr [esp + 0x218]
  4c91bf: f2 0f 11 94 24 d0 01 00 00   	movsd	qword ptr [esp + 0x1d0], xmm2
  4c91c8: f2 0f 59 f8                  	mulsd	xmm7, xmm0
  4c91cc: f2 0f 11 bc 24 e8 01 00 00   	movsd	qword ptr [esp + 0x1e8], xmm7
  4c91d5: f2 0f 58 eb                  	addsd	xmm5, xmm3
  4c91d9: f2 0f 10 9c 24 10 02 00 00   	movsd	xmm3, qword ptr [esp + 0x210]
  4c91e2: f2 0f 58 f2                  	addsd	xmm6, xmm2
  4c91e6: f2 0f 10 94 24 50 01 00 00   	movsd	xmm2, qword ptr [esp + 0x150]
  4c91ef: f2 0f 59 d0                  	mulsd	xmm2, xmm0
  4c91f3: f2 0f 59 84 24 60 01 00 00   	mulsd	xmm0, qword ptr [esp + 0x160]
  4c91fc: f2 0f 11 94 24 c0 00 00 00   	movsd	qword ptr [esp + 0xc0], xmm2
  4c9205: f2 0f 11 84 24 f0 01 00 00   	movsd	qword ptr [esp + 0x1f0], xmm0
  4c920e: f2 0f 58 dc                  	addsd	xmm3, xmm4
  4c9212: f2 0f 10 a4 24 40 01 00 00   	movsd	xmm4, qword ptr [esp + 0x140]
  4c921b: f2 0f 11 9c 24 e0 01 00 00   	movsd	qword ptr [esp + 0x1e0], xmm3
  4c9224: f2 0f 59 e1                  	mulsd	xmm4, xmm1
  4c9228: f2 0f 10 9c 24 38 01 00 00   	movsd	xmm3, qword ptr [esp + 0x138]
  4c9231: f2 0f 59 d9                  	mulsd	xmm3, xmm1
  4c9235: f2 0f 59 8c 24 48 01 00 00   	mulsd	xmm1, qword ptr [esp + 0x148]
  4c923e: f2 0f 58 e7                  	addsd	xmm4, xmm7
  4c9242: f2 0f 10 bc 24 00 02 00 00   	movsd	xmm7, qword ptr [esp + 0x200]
  4c924b: f2 0f 58 da                  	addsd	xmm3, xmm2
  4c924f: f2 0f 10 56 10               	movsd	xmm2, qword ptr [esi + 0x10]
  4c9254: f2 0f 11 9c 24 c0 01 00 00   	movsd	qword ptr [esp + 0x1c0], xmm3
  4c925d: f2 0f 11 94 24 a8 01 00 00   	movsd	qword ptr [esp + 0x1a8], xmm2
  4c9266: f2 0f 5c 94 24 10 02 00 00   	subsd	xmm2, qword ptr [esp + 0x210]
  4c926f: f2 0f 58 c8                  	addsd	xmm1, xmm0
  4c9273: f2 0f 11 8c 24 b8 01 00 00   	movsd	qword ptr [esp + 0x1b8], xmm1
  4c927c: 0f 28 c7                     	movaps	xmm0, xmm7
  4c927f: f2 0f 59 c3                  	mulsd	xmm0, xmm3
  4c9283: 0f 28 df                     	movaps	xmm3, xmm7
  4c9286: f2 0f 59 f9                  	mulsd	xmm7, xmm1
  4c928a: f2 0f 59 dc                  	mulsd	xmm3, xmm4
  4c928e: f2 0f 10 8c 24 e0 01 00 00   	movsd	xmm1, qword ptr [esp + 0x1e0]
  4c9297: f2 0f 58 e8                  	addsd	xmm5, xmm0
  4c929b: f2 0f 11 ac 24 a8 00 00 00   	movsd	qword ptr [esp + 0xa8], xmm5
  4c92a4: f2 0f 10 ac 24 f0 01 00 00   	movsd	xmm5, qword ptr [esp + 0x1f0]
  4c92ad: f2 0f 11 ac 24 d0 00 00 00   	movsd	qword ptr [esp + 0xd0], xmm5
  4c92b6: f2 0f 58 f3                  	addsd	xmm6, xmm3
  4c92ba: f2 0f 10 ac 24 d0 01 00 00   	movsd	xmm5, qword ptr [esp + 0x1d0]
  4c92c3: f2 0f 11 b4 24 b0 00 00 00   	movsd	qword ptr [esp + 0xb0], xmm6
  4c92cc: f2 0f 10 30                  	movsd	xmm6, qword ptr [eax]
  4c92d0: f2 0f 11 b4 24 b0 01 00 00   	movsd	qword ptr [esp + 0x1b0], xmm6
  4c92d9: f2 0f 58 cf                  	addsd	xmm1, xmm7
  4c92dd: f2 0f 11 8c 24 e0 01 00 00   	movsd	qword ptr [esp + 0x1e0], xmm1
  4c92e6: f2 0f 11 8c 24 b8 00 00 00   	movsd	qword ptr [esp + 0xb8], xmm1
  4c92ef: f2 0f 10 8c 24 e8 01 00 00   	movsd	xmm1, qword ptr [esp + 0x1e8]
  4c92f8: f2 0f 11 8c 24 c8 00 00 00   	movsd	qword ptr [esp + 0xc8], xmm1
  4c9301: f2 0f 10 8c 24 c8 01 00 00   	movsd	xmm1, qword ptr [esp + 0x1c8]
  4c930a: f2 0f 58 c8                  	addsd	xmm1, xmm0
  4c930e: 0f 28 f1                     	movaps	xmm6, xmm1
  4c9311: f2 0f 10 46 08               	movsd	xmm0, qword ptr [esi + 0x8]
  4c9316: f2 0f 11 84 24 98 01 00 00   	movsd	qword ptr [esp + 0x198], xmm0
  4c931f: f2 0f 5c 84 24 18 02 00 00   	subsd	xmm0, qword ptr [esp + 0x218]
  4c9328: f2 0f 11 84 24 a0 01 00 00   	movsd	qword ptr [esp + 0x1a0], xmm0
  4c9331: f2 0f 58 eb                  	addsd	xmm5, xmm3
  4c9335: f2 0f 10 9c 24 d8 01 00 00   	movsd	xmm3, qword ptr [esp + 0x1d8]
  4c933e: f2 0f 58 df                  	addsd	xmm3, xmm7
  4c9342: f2 0f 10 3e                  	movsd	xmm7, qword ptr [esi]
  4c9346: f2 0f 11 bc 24 88 01 00 00   	movsd	qword ptr [esp + 0x188], xmm7
  4c934f: f2 0f 5c bc 24 68 01 00 00   	subsd	xmm7, qword ptr [esp + 0x168]
  4c9358: f2 0f 11 bc 24 f8 01 00 00   	movsd	qword ptr [esp + 0x1f8], xmm7
  4c9361: f2 0f 59 f7                  	mulsd	xmm6, xmm7
  4c9365: 0f 28 fd                     	movaps	xmm7, xmm5
  4c9368: f2 0f 59 f8                  	mulsd	xmm7, xmm0
  4c936c: 0f 28 c3                     	movaps	xmm0, xmm3
  4c936f: f2 0f 59 c2                  	mulsd	xmm0, xmm2
  4c9373: f2 0f 58 f7                  	addsd	xmm6, xmm7
  4c9377: f2 0f 58 f0                  	addsd	xmm6, xmm0
  4c937b: f2 0f 11 b4 24 90 01 00 00   	movsd	qword ptr [esp + 0x190], xmm6
  4c9384: 66 0f ef c0                  	pxor	xmm0, xmm0
  4c9388: 66 0f 2f f0                  	comisd	xmm6, xmm0
  4c938c: f2 0f 10 84 24 e0 01 00 00   	movsd	xmm0, qword ptr [esp + 0x1e0]
  4c9395: f2 0f 10 b4 24 f8 01 00 00   	movsd	xmm6, qword ptr [esp + 0x1f8]
  4c939e: 0f 82 85 01 00 00            	jb	0x4c9529 <.text+0xc8529>
  4c93a4: f2 0f 59 f6                  	mulsd	xmm6, xmm6
  4c93a8: f2 0f 59 d2                  	mulsd	xmm2, xmm2
  4c93ac: f2 0f 59 c9                  	mulsd	xmm1, xmm1
  4c93b0: f2 0f 59 ed                  	mulsd	xmm5, xmm5
  4c93b4: f2 0f 59 db                  	mulsd	xmm3, xmm3
  4c93b8: f2 0f 58 cd                  	addsd	xmm1, xmm5
  4c93bc: f2 0f 10 bc 24 a0 01 00 00   	movsd	xmm7, qword ptr [esp + 0x1a0]
  4c93c5: f2 0f 59 ff                  	mulsd	xmm7, xmm7
  4c93c9: f2 0f 58 cb                  	addsd	xmm1, xmm3
  4c93cd: f2 0f 58 f7                  	addsd	xmm6, xmm7
  4c93d1: f2 0f 58 f2                  	addsd	xmm6, xmm2
  4c93d5: f2 0f 10 94 24 90 01 00 00   	movsd	xmm2, qword ptr [esp + 0x190]
  4c93de: 0f 28 da                     	movaps	xmm3, xmm2
  4c93e1: f2 0f 5e d9                  	divsd	xmm3, xmm1
  4c93e5: f2 0f 59 da                  	mulsd	xmm3, xmm2
  4c93e9: f2 0f 10 8c 24 b0 01 00 00   	movsd	xmm1, qword ptr [esp + 0x1b0]
  4c93f2: f2 0f 59 c9                  	mulsd	xmm1, xmm1
  4c93f6: f2 0f 5c f3                  	subsd	xmm6, xmm3
  4c93fa: 66 0f 2f ce                  	comisd	xmm1, xmm6
  4c93fe: 0f 86 25 01 00 00            	jbe	0x4c9529 <.text+0xc8529>
  4c9404: f2 0f 10 84 24 88 01 00 00   	movsd	xmm0, qword ptr [esp + 0x188]
  4c940d: 8b 45 1c                     	mov	eax, dword ptr [ebp + 0x1c]
  4c9410: f2 0f 5c 00                  	subsd	xmm0, qword ptr [eax]
  4c9414: f2 0f 59 c0                  	mulsd	xmm0, xmm0
  4c9418: f2 0f 10 8c 24 98 01 00 00   	movsd	xmm1, qword ptr [esp + 0x198]
  4c9421: f2 0f 5c 48 08               	subsd	xmm1, qword ptr [eax + 0x8]
  4c9426: f2 0f 59 c9                  	mulsd	xmm1, xmm1
  4c942a: f2 0f 58 c1                  	addsd	xmm0, xmm1
  4c942e: f2 0f 10 94 24 a8 01 00 00   	movsd	xmm2, qword ptr [esp + 0x1a8]
  4c9437: f2 0f 5c 50 10               	subsd	xmm2, qword ptr [eax + 0x10]
  4c943c: f2 0f 59 d2                  	mulsd	xmm2, xmm2
  4c9440: f2 0f 58 c2                  	addsd	xmm0, xmm2
  4c9444: f2 0f 10 9c 24 28 02 00 00   	movsd	xmm3, qword ptr [esp + 0x228]
  4c944d: f2 0f 10 bc 24 78 01 00 00   	movsd	xmm7, qword ptr [esp + 0x178]
  4c9456: f2 0f 10 8c 24 70 01 00 00   	movsd	xmm1, qword ptr [esp + 0x170]
  4c945f: f2 0f 10 b4 24 c0 01 00 00   	movsd	xmm6, qword ptr [esp + 0x1c0]
  4c9468: f2 0f 51 e8                  	sqrtsd	xmm5, xmm0
  4c946c: f2 0f 5c 6c 24 78            	subsd	xmm5, qword ptr [esp + 0x78]
  4c9472: f2 0f 59 dd                  	mulsd	xmm3, xmm5
  4c9476: f2 0f 5e 9c 24 20 02 00 00   	divsd	xmm3, qword ptr [esp + 0x220]
  4c947f: f2 0f 59 fd                  	mulsd	xmm7, xmm5
  4c9483: f2 0f 59 cd                  	mulsd	xmm1, xmm5
  4c9487: f2 0f 59 f3                  	mulsd	xmm6, xmm3
  4c948b: f2 0f 59 e3                  	mulsd	xmm4, xmm3
  4c948f: f2 0f 59 9c 24 b8 01 00 00   	mulsd	xmm3, qword ptr [esp + 0x1b8]
  4c9498: f2 0f 58 bc 24 68 01 00 00   	addsd	xmm7, qword ptr [esp + 0x168]
  4c94a1: f2 0f 58 8c 24 10 02 00 00   	addsd	xmm1, qword ptr [esp + 0x210]
  4c94aa: f2 0f 10 84 24 80 01 00 00   	movsd	xmm0, qword ptr [esp + 0x180]
  4c94b3: f2 0f 59 c5                  	mulsd	xmm0, xmm5
  4c94b7: f2 0f 58 84 24 18 02 00 00   	addsd	xmm0, qword ptr [esp + 0x218]
  4c94c0: f2 0f 58 fe                  	addsd	xmm7, xmm6
  4c94c4: f2 0f 11 7c 24 18            	movsd	qword ptr [esp + 0x18], xmm7
  4c94ca: 8b 54 24 18                  	mov	edx, dword ptr [esp + 0x18]
  4c94ce: 8b 4c 24 1c                  	mov	ecx, dword ptr [esp + 0x1c]
  4c94d2: 89 94 24 a8 00 00 00         	mov	dword ptr [esp + 0xa8], edx
  4c94d9: f2 0f 58 c4                  	addsd	xmm0, xmm4
  4c94dd: f2 0f 11 44 24 20            	movsd	qword ptr [esp + 0x20], xmm0
  4c94e3: 8b 44 24 20                  	mov	eax, dword ptr [esp + 0x20]
  4c94e7: 8b 54 24 24                  	mov	edx, dword ptr [esp + 0x24]
  4c94eb: 89 8c 24 ac 00 00 00         	mov	dword ptr [esp + 0xac], ecx
  4c94f2: f2 0f 58 cb                  	addsd	xmm1, xmm3
  4c94f6: f2 0f 11 4c 24 28            	movsd	qword ptr [esp + 0x28], xmm1
  4c94fc: 8b 4c 24 28                  	mov	ecx, dword ptr [esp + 0x28]
  4c9500: 89 84 24 b0 00 00 00         	mov	dword ptr [esp + 0xb0], eax
  4c9507: 8b 44 24 2c                  	mov	eax, dword ptr [esp + 0x2c]
  4c950b: 89 94 24 b4 00 00 00         	mov	dword ptr [esp + 0xb4], edx
  4c9512: 89 8c 24 b8 00 00 00         	mov	dword ptr [esp + 0xb8], ecx
  4c9519: 89 84 24 bc 00 00 00         	mov	dword ptr [esp + 0xbc], eax
  4c9520: f2 0f 10 84 24 b8 00 00 00   	movsd	xmm0, qword ptr [esp + 0xb8]
  4c9529: f2 0f 5c 84 24 a8 01 00 00   	subsd	xmm0, qword ptr [esp + 0x1a8]
  4c9532: f2 0f 10 ac 24 a8 00 00 00   	movsd	xmm5, qword ptr [esp + 0xa8]
  4c953b: f2 0f 5c ac 24 88 01 00 00   	subsd	xmm5, qword ptr [esp + 0x188]
  4c9544: f2 0f 10 9c 24 b0 00 00 00   	movsd	xmm3, qword ptr [esp + 0xb0]
  4c954d: f2 0f 5c 9c 24 98 01 00 00   	subsd	xmm3, qword ptr [esp + 0x198]
  4c9556: 8d 84 24 c0 00 00 00         	lea	eax, [esp + 0xc0]
  4c955d: f2 0f 10 27                  	movsd	xmm4, qword ptr [edi]
  4c9561: f2 0f 59 e5                  	mulsd	xmm4, xmm5
  4c9565: f2 0f 10 77 08               	movsd	xmm6, qword ptr [edi + 0x8]
  4c956a: f2 0f 59 f3                  	mulsd	xmm6, xmm3
  4c956e: f2 0f 10 7f 10               	movsd	xmm7, qword ptr [edi + 0x10]
  4c9573: f2 0f 59 f8                  	mulsd	xmm7, xmm0
  4c9577: f2 0f 10 57 18               	movsd	xmm2, qword ptr [edi + 0x18]
  4c957c: f2 0f 59 d5                  	mulsd	xmm2, xmm5
  4c9580: f2 0f 10 4f 20               	movsd	xmm1, qword ptr [edi + 0x20]
  4c9585: f2 0f 59 cb                  	mulsd	xmm1, xmm3
  4c9589: f2 0f 58 e6                  	addsd	xmm4, xmm6
  4c958d: f2 0f 10 77 28               	movsd	xmm6, qword ptr [edi + 0x28]
  4c9592: f2 0f 59 f0                  	mulsd	xmm6, xmm0
  4c9596: f2 0f 58 e7                  	addsd	xmm4, xmm7
  4c959a: f2 0f 58 d1                  	addsd	xmm2, xmm1
  4c959e: f2 0f 10 4f 30               	movsd	xmm1, qword ptr [edi + 0x30]
  4c95a3: f2 0f 59 cd                  	mulsd	xmm1, xmm5
  4c95a7: f2 0f 10 6f 38               	movsd	xmm5, qword ptr [edi + 0x38]
  4c95ac: f2 0f 59 eb                  	mulsd	xmm5, xmm3
  4c95b0: f2 0f 10 5f 40               	movsd	xmm3, qword ptr [edi + 0x40]
  4c95b5: f2 0f 59 d8                  	mulsd	xmm3, xmm0
  4c95b9: f2 0f 10 05 48 e1 c2 00      	movsd	xmm0, qword ptr [0xc2e148]
  4c95c1: f2 0f 5e 84 24 b0 01 00 00   	divsd	xmm0, qword ptr [esp + 0x1b0]
  4c95ca: f2 0f 59 e0                  	mulsd	xmm4, xmm0
  4c95ce: f2 0f 11 a4 24 c0 00 00 00   	movsd	qword ptr [esp + 0xc0], xmm4
  4c95d7: f2 0f 58 d6                  	addsd	xmm2, xmm6
  4c95db: f2 0f 59 d0                  	mulsd	xmm2, xmm0
  4c95df: f2 0f 11 94 24 c8 00 00 00   	movsd	qword ptr [esp + 0xc8], xmm2
  4c95e8: f2 0f 58 cd                  	addsd	xmm1, xmm5
  4c95ec: f2 0f 58 cb                  	addsd	xmm1, xmm3
  4c95f0: f2 0f 59 c1                  	mulsd	xmm0, xmm1
  4c95f4: f2 0f 11 84 24 d0 00 00 00   	movsd	qword ptr [esp + 0xd0], xmm0
  4c95fd: 50                           	push	eax
  4c95fe: ff 15 f8 59 c2 00            	call	dword ptr [0xc259f8]
  4c9604: 43                           	inc	ebx
  4c9605: 83 fb 40                     	cmp	ebx, 0x40
  4c9608: 0f 8e 1f fb ff ff            	jle	0x4c912d <.text+0xc812d>
  4c960e: ff 15 e4 58 c2 00            	call	dword ptr [0xc258e4]
  4c9614: e9 d3 f6 ff ff               	jmp	0x4c8cec <.text+0xc7cec>
  4c9619: 8b 45 0c                     	mov	eax, dword ptr [ebp + 0xc]
  4c961c: f2 0f 10 84 24 b0 00 00 00   	movsd	xmm0, qword ptr [esp + 0xb0]
  4c9625: f2 0f 10 26                  	movsd	xmm4, qword ptr [esi]
  4c9629: f2 0f 10 30                  	movsd	xmm6, qword ptr [eax]
  4c962d: f2 0f 10 5e 08               	movsd	xmm3, qword ptr [esi + 0x8]
  4c9632: f2 0f 10 78 08               	movsd	xmm7, qword ptr [eax + 0x8]
  4c9637: f2 0f 10 56 10               	movsd	xmm2, qword ptr [esi + 0x10]
  4c963c: f2 0f 10 68 10               	movsd	xmm5, qword ptr [eax + 0x10]
  4c9641: f2 0f 5c f4                  	subsd	xmm6, xmm4
  4c9645: f2 0f 11 74 24 08            	movsd	qword ptr [esp + 0x8], xmm6
  4c964b: f2 0f 59 f6                  	mulsd	xmm6, xmm6
  4c964f: f2 0f 5c fb                  	subsd	xmm7, xmm3
  4c9653: f2 0f 11 7c 24 10            	movsd	qword ptr [esp + 0x10], xmm7
  4c9659: f2 0f 59 ff                  	mulsd	xmm7, xmm7
  4c965d: f2 0f 5c ea                  	subsd	xmm5, xmm2
  4c9661: 0f 28 cd                     	movaps	xmm1, xmm5
  4c9664: f2 0f 59 cd                  	mulsd	xmm1, xmm5
  4c9668: f2 0f 58 f7                  	addsd	xmm6, xmm7
  4c966c: f2 0f 5c c4                  	subsd	xmm0, xmm4
  4c9670: f2 0f 59 c0                  	mulsd	xmm0, xmm0
  4c9674: f2 0f 58 f1                  	addsd	xmm6, xmm1
  4c9678: f2 0f 10 a4 24 a8 00 00 00   	movsd	xmm4, qword ptr [esp + 0xa8]
  4c9681: f2 0f 11 34 24               	movsd	qword ptr [esp], xmm6
  4c9686: f2 0f 51 ce                  	sqrtsd	xmm1, xmm6
  4c968a: f2 0f 5c e3                  	subsd	xmm4, xmm3
  4c968e: f2 0f 59 e4                  	mulsd	xmm4, xmm4
  4c9692: f2 0f 10 9c 24 b8 00 00 00   	movsd	xmm3, qword ptr [esp + 0xb8]
  4c969b: f2 0f 5c da                  	subsd	xmm3, xmm2
  4c969f: f2 0f 59 db                  	mulsd	xmm3, xmm3
  4c96a3: f2 0f 58 c4                  	addsd	xmm0, xmm4
  4c96a7: f2 0f 58 c3                  	addsd	xmm0, xmm3
  4c96ab: f2 0f 10 1d 48 e1 c2 00      	movsd	xmm3, qword ptr [0xc2e148]
  4c96b3: f2 0f 51 d0                  	sqrtsd	xmm2, xmm0
  4c96b7: f2 0f 5e ca                  	divsd	xmm1, xmm2
  4c96bb: f2 0f 5c d9                  	subsd	xmm3, xmm1
  4c96bf: f2 0f 11 5c 24 48            	movsd	qword ptr [esp + 0x48], xmm3
  4c96c5: 66 0f ef c0                  	pxor	xmm0, xmm0
  4c96c9: 66 0f 2f d8                  	comisd	xmm3, xmm0
  4c96cd: 0f 82 f7 03 00 00            	jb	0x4c9aca <.text+0xc8aca>
  4c96d3: f2 0f 10 0d 48 e1 c2 00      	movsd	xmm1, qword ptr [0xc2e148]
  4c96db: 66 0f 2f 4c 24 48            	comisd	xmm1, qword ptr [esp + 0x48]
  4c96e1: 0f 86 e3 03 00 00            	jbe	0x4c9aca <.text+0xc8aca>
  4c96e7: f2 0f 10 8c 24 28 01 00 00   	movsd	xmm1, qword ptr [esp + 0x128]
  4c96f0: f2 0f 10 9c 24 30 01 00 00   	movsd	xmm3, qword ptr [esp + 0x130]
  4c96f9: f2 0f 59 eb                  	mulsd	xmm5, xmm3
  4c96fd: f2 0f 10 a4 24 20 01 00 00   	movsd	xmm4, qword ptr [esp + 0x120]
  4c9706: f2 0f 10 54 24 10            	movsd	xmm2, qword ptr [esp + 0x10]
  4c970c: f2 0f 59 d1                  	mulsd	xmm2, xmm1
  4c9710: f2 0f 58 d5                  	addsd	xmm2, xmm5
  4c9714: f2 0f 10 6c 24 08            	movsd	xmm5, qword ptr [esp + 0x8]
  4c971a: f2 0f 59 ec                  	mulsd	xmm5, xmm4
  4c971e: f2 0f 58 d5                  	addsd	xmm2, xmm5
  4c9722: f2 0f 11 54 24 10            	movsd	qword ptr [esp + 0x10], xmm2
  4c9728: 66 0f 2f d0                  	comisd	xmm2, xmm0
  4c972c: 0f 82 98 03 00 00            	jb	0x4c9aca <.text+0xc8aca>
  4c9732: f2 0f 59 c9                  	mulsd	xmm1, xmm1
  4c9736: f2 0f 59 db                  	mulsd	xmm3, xmm3
  4c973a: f2 0f 59 e4                  	mulsd	xmm4, xmm4
  4c973e: 8b 45 10                     	mov	eax, dword ptr [ebp + 0x10]
  4c9741: f2 0f 10 00                  	movsd	xmm0, qword ptr [eax]
  4c9745: f2 0f 59 c0                  	mulsd	xmm0, xmm0
  4c9749: f2 0f 58 cb                  	addsd	xmm1, xmm3
  4c974d: f2 0f 10 5c 24 10            	movsd	xmm3, qword ptr [esp + 0x10]
  4c9753: f2 0f 58 cc                  	addsd	xmm1, xmm4
  4c9757: 0f 28 e3                     	movaps	xmm4, xmm3
  4c975a: f2 0f 5e e1                  	divsd	xmm4, xmm1
  4c975e: f2 0f 59 e3                  	mulsd	xmm4, xmm3
  4c9762: f2 0f 10 0c 24               	movsd	xmm1, qword ptr [esp]
  4c9767: f2 0f 5c cc                  	subsd	xmm1, xmm4
  4c976b: 66 0f 2f c1                  	comisd	xmm0, xmm1
  4c976f: 0f 86 55 03 00 00            	jbe	0x4c9aca <.text+0xc8aca>
  4c9775: 6a 08                        	push	0x8
  4c9777: ff 15 d4 58 c2 00            	call	dword ptr [0xc258d4]
  4c977d: 8b 75 0c                     	mov	esi, dword ptr [ebp + 0xc]
  4c9780: 8b 7d 24                     	mov	edi, dword ptr [ebp + 0x24]
  4c9783: b8 40 00 00 00               	mov	eax, 0x40
  4c9788: 8b d8                        	mov	ebx, eax
  4c978a: f2 0f 2a c3                  	cvtsi2sd	xmm0, ebx
  4c978e: f2 0f 59 05 40 e1 c2 00      	mulsd	xmm0, qword ptr [0xc2e140]
  4c9796: e8 75 56 5c 00               	call	0xa8ee10 <.text+0x68de10>
  4c979b: f2 0f 10 94 24 20 01 00 00   	movsd	xmm2, qword ptr [esp + 0x120]
  4c97a4: f2 0f 10 9c 24 c0 00 00 00   	movsd	xmm3, qword ptr [esp + 0xc0]
  4c97ad: f2 0f 59 d3                  	mulsd	xmm2, xmm3
  4c97b1: f2 0f 10 ac 24 28 01 00 00   	movsd	xmm5, qword ptr [esp + 0x128]
  4c97ba: f2 0f 59 eb                  	mulsd	xmm5, xmm3
  4c97be: 33 c9                        	xor	ecx, ecx
  4c97c0: f2 0f 10 a4 24 30 01 00 00   	movsd	xmm4, qword ptr [esp + 0x130]
  4c97c9: f2 0f 59 e3                  	mulsd	xmm4, xmm3
  4c97cd: 8b 55 1c                     	mov	edx, dword ptr [ebp + 0x1c]
  4c97d0: f2 0f 58 12                  	addsd	xmm2, qword ptr [edx]
  4c97d4: f2 0f 58 6a 08               	addsd	xmm5, qword ptr [edx + 0x8]
  4c97d9: f2 0f 58 62 10               	addsd	xmm4, qword ptr [edx + 0x10]
  4c97de: f2 0f 10 bc 24 38 01 00 00   	movsd	xmm7, qword ptr [esp + 0x138]
  4c97e7: f2 0f 10 9c 24 40 01 00 00   	movsd	xmm3, qword ptr [esp + 0x140]
  4c97f0: f2 0f 10 b4 24 48 01 00 00   	movsd	xmm6, qword ptr [esp + 0x148]
  4c97f9: f2 0f 11 6c 24 20            	movsd	qword ptr [esp + 0x20], xmm5
  4c97ff: f2 0f 10 ac 24 58 01 00 00   	movsd	xmm5, qword ptr [esp + 0x158]
  4c9808: f2 0f 11 64 24 28            	movsd	qword ptr [esp + 0x28], xmm4
  4c980e: f2 0f 59 f9                  	mulsd	xmm7, xmm1
  4c9812: f2 0f 59 d9                  	mulsd	xmm3, xmm1
  4c9816: f2 0f 59 f1                  	mulsd	xmm6, xmm1
  4c981a: f2 0f 59 e8                  	mulsd	xmm5, xmm0
  4c981e: f2 0f 10 8c 24 50 01 00 00   	movsd	xmm1, qword ptr [esp + 0x150]
  4c9827: f2 0f 59 c8                  	mulsd	xmm1, xmm0
  4c982b: f2 0f 10 a4 24 60 01 00 00   	movsd	xmm4, qword ptr [esp + 0x160]
  4c9834: f2 0f 59 e0                  	mulsd	xmm4, xmm0
  4c9838: f2 0f 58 f9                  	addsd	xmm7, xmm1
  4c983c: f2 0f 10 84 24 c8 00 00 00   	movsd	xmm0, qword ptr [esp + 0xc8]
  4c9845: f2 0f 59 f8                  	mulsd	xmm7, xmm0
  4c9849: f2 0f 10 4c 24 28            	movsd	xmm1, qword ptr [esp + 0x28]
  4c984f: f2 0f 58 dd                  	addsd	xmm3, xmm5
  4c9853: f2 0f 59 d8                  	mulsd	xmm3, xmm0
  4c9857: f2 0f 58 f4                  	addsd	xmm6, xmm4
  4c985b: f2 0f 59 f0                  	mulsd	xmm6, xmm0
  4c985f: f2 0f 10 64 24 20            	movsd	xmm4, qword ptr [esp + 0x20]
  4c9865: f2 0f 10 ac 24 b0 00 00 00   	movsd	xmm5, qword ptr [esp + 0xb0]
  4c986e: f2 0f 58 d7                  	addsd	xmm2, xmm7
  4c9872: 0f 28 c2                     	movaps	xmm0, xmm2
  4c9875: f2 0f 58 e3                  	addsd	xmm4, xmm3
  4c9879: f2 0f 10 9c 24 a8 00 00 00   	movsd	xmm3, qword ptr [esp + 0xa8]
  4c9882: f2 0f 10 bc 24 b8 00 00 00   	movsd	xmm7, qword ptr [esp + 0xb8]
  4c988b: f2 0f 11 64 24 20            	movsd	qword ptr [esp + 0x20], xmm4
  4c9891: f2 0f 58 ce                  	addsd	xmm1, xmm6
  4c9895: f2 0f 10 74 24 48            	movsd	xmm6, qword ptr [esp + 0x48]
  4c989b: f2 0f 11 4c 24 28            	movsd	qword ptr [esp + 0x28], xmm1
  4c98a1: f2 0f 5c c5                  	subsd	xmm0, xmm5
  4c98a5: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  4c98aa: f2 0f 59 c6                  	mulsd	xmm0, xmm6
  4c98ae: f2 0f 5c e3                  	subsd	xmm4, xmm3
  4c98b2: f2 0f 11 64 24 08            	movsd	qword ptr [esp + 0x8], xmm4
  4c98b8: f2 0f 59 e6                  	mulsd	xmm4, xmm6
  4c98bc: f2 0f 5c cf                  	subsd	xmm1, xmm7
  4c98c0: f2 0f 11 4c 24 10            	movsd	qword ptr [esp + 0x10], xmm1
  4c98c6: f2 0f 59 ce                  	mulsd	xmm1, xmm6
  4c98ca: f2 0f 58 c5                  	addsd	xmm0, xmm5
  4c98ce: f2 0f 58 e3                  	addsd	xmm4, xmm3
  4c98d2: f2 0f 11 64 24 18            	movsd	qword ptr [esp + 0x18], xmm4
  4c98d8: f2 0f 58 cf                  	addsd	xmm1, xmm7
  4c98dc: 83 c4 f0                     	add	esp, -0x10
  4c98df: f2 0f 11 4c 24 40            	movsd	qword ptr [esp + 0x40], xmm1
  4c98e5: f2 0f 11 44 24 48            	movsd	qword ptr [esp + 0x48], xmm0
  4c98eb: f2 0f 11 54 24 50            	movsd	qword ptr [esp + 0x50], xmm2
  4c98f1: 89 4c 24 04                  	mov	dword ptr [esp + 0x4], ecx
  4c98f5: c7 04 24 00 00 80 3f         	mov	dword ptr [esp], 0x3f800000
  4c98fc: 89 4c 24 08                  	mov	dword ptr [esp + 0x8], ecx
  4c9900: c7 44 24 0c 00 00 00 3f      	mov	dword ptr [esp + 0xc], 0x3f000000
  4c9908: ff 15 70 59 c2 00            	call	dword ptr [0xc25970]
  4c990e: f2 0f 10 44 24 38            	movsd	xmm0, qword ptr [esp + 0x38]
  4c9914: f2 0f 5c 06                  	subsd	xmm0, qword ptr [esi]
  4c9918: f2 0f 10 37                  	movsd	xmm6, qword ptr [edi]
  4c991c: f2 0f 59 f0                  	mulsd	xmm6, xmm0
  4c9920: f2 0f 10 4c 24 30            	movsd	xmm1, qword ptr [esp + 0x30]
  4c9926: f2 0f 5c 4e 10               	subsd	xmm1, qword ptr [esi + 0x10]
  4c992b: f2 0f 10 6c 24 18            	movsd	xmm5, qword ptr [esp + 0x18]
  4c9931: f2 0f 5c 6e 08               	subsd	xmm5, qword ptr [esi + 0x8]
  4c9936: 8b 55 10                     	mov	edx, dword ptr [ebp + 0x10]
  4c9939: 8d 0c 24                     	lea	ecx, [esp]
  4c993c: f2 0f 10 7f 08               	movsd	xmm7, qword ptr [edi + 0x8]
  4c9941: f2 0f 59 fd                  	mulsd	xmm7, xmm5
  4c9945: f2 0f 10 67 10               	movsd	xmm4, qword ptr [edi + 0x10]
  4c994a: f2 0f 59 e1                  	mulsd	xmm4, xmm1
  4c994e: f2 0f 10 5f 20               	movsd	xmm3, qword ptr [edi + 0x20]
  4c9953: f2 0f 59 dd                  	mulsd	xmm3, xmm5
  4c9957: f2 0f 58 f7                  	addsd	xmm6, xmm7
  4c995b: f2 0f 10 7f 28               	movsd	xmm7, qword ptr [edi + 0x28]
  4c9960: f2 0f 59 f9                  	mulsd	xmm7, xmm1
  4c9964: f2 0f 58 f4                  	addsd	xmm6, xmm4
  4c9968: f2 0f 10 67 18               	movsd	xmm4, qword ptr [edi + 0x18]
  4c996d: f2 0f 59 e0                  	mulsd	xmm4, xmm0
  4c9971: f2 0f 58 e3                  	addsd	xmm4, xmm3
  4c9975: f2 0f 10 5f 30               	movsd	xmm3, qword ptr [edi + 0x30]
  4c997a: f2 0f 59 d8                  	mulsd	xmm3, xmm0
  4c997e: f2 0f 10 47 38               	movsd	xmm0, qword ptr [edi + 0x38]
  4c9983: f2 0f 59 c5                  	mulsd	xmm0, xmm5
  4c9987: f2 0f 10 6f 40               	movsd	xmm5, qword ptr [edi + 0x40]
  4c998c: f2 0f 59 e9                  	mulsd	xmm5, xmm1
  4c9990: f2 0f 10 0d 48 e1 c2 00      	movsd	xmm1, qword ptr [0xc2e148]
  4c9998: f2 0f 5e 0a                  	divsd	xmm1, qword ptr [edx]
  4c999c: f2 0f 59 f1                  	mulsd	xmm6, xmm1
  4c99a0: f2 0f 11 34 24               	movsd	qword ptr [esp], xmm6
  4c99a5: f2 0f 58 e7                  	addsd	xmm4, xmm7
  4c99a9: f2 0f 59 e1                  	mulsd	xmm4, xmm1
  4c99ad: f2 0f 11 64 24 08            	movsd	qword ptr [esp + 0x8], xmm4
  4c99b3: f2 0f 58 d8                  	addsd	xmm3, xmm0
  4c99b7: f2 0f 58 dd                  	addsd	xmm3, xmm5
  4c99bb: f2 0f 59 cb                  	mulsd	xmm1, xmm3
  4c99bf: f2 0f 11 4c 24 10            	movsd	qword ptr [esp + 0x10], xmm1
  4c99c5: 51                           	push	ecx
  4c99c6: ff 15 f8 59 c2 00            	call	dword ptr [0xc259f8]
  4c99cc: 83 c4 f0                     	add	esp, -0x10
  4c99cf: c7 04 24 00 00 80 3f         	mov	dword ptr [esp], 0x3f800000
  4c99d6: 33 d2                        	xor	edx, edx
  4c99d8: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  4c99dc: 89 54 24 08                  	mov	dword ptr [esp + 0x8], edx
  4c99e0: 89 54 24 0c                  	mov	dword ptr [esp + 0xc], edx
  4c99e4: ff 15 70 59 c2 00            	call	dword ptr [0xc25970]
  4c99ea: f2 0f 10 54 24 40            	movsd	xmm2, qword ptr [esp + 0x40]
  4c99f0: f2 0f 5c 16                  	subsd	xmm2, qword ptr [esi]
  4c99f4: f2 0f 10 5c 24 20            	movsd	xmm3, qword ptr [esp + 0x20]
  4c99fa: f2 0f 5c 5e 08               	subsd	xmm3, qword ptr [esi + 0x8]
  4c99ff: f2 0f 10 64 24 28            	movsd	xmm4, qword ptr [esp + 0x28]
  4c9a05: f2 0f 5c 66 10               	subsd	xmm4, qword ptr [esi + 0x10]
  4c9a0a: 8b 55 10                     	mov	edx, dword ptr [ebp + 0x10]
  4c9a0d: f2 0f 10 2f                  	movsd	xmm5, qword ptr [edi]
  4c9a11: f2 0f 59 ea                  	mulsd	xmm5, xmm2
  4c9a15: 8d 0c 24                     	lea	ecx, [esp]
  4c9a18: f2 0f 10 77 08               	movsd	xmm6, qword ptr [edi + 0x8]
  4c9a1d: f2 0f 59 f3                  	mulsd	xmm6, xmm3
  4c9a21: f2 0f 10 7f 10               	movsd	xmm7, qword ptr [edi + 0x10]
  4c9a26: f2 0f 59 fc                  	mulsd	xmm7, xmm4
  4c9a2a: f2 0f 10 4f 18               	movsd	xmm1, qword ptr [edi + 0x18]
  4c9a2f: f2 0f 59 ca                  	mulsd	xmm1, xmm2
  4c9a33: f2 0f 10 47 20               	movsd	xmm0, qword ptr [edi + 0x20]
  4c9a38: f2 0f 59 c3                  	mulsd	xmm0, xmm3
  4c9a3c: f2 0f 58 ee                  	addsd	xmm5, xmm6
  4c9a40: f2 0f 10 77 28               	movsd	xmm6, qword ptr [edi + 0x28]
  4c9a45: f2 0f 59 f4                  	mulsd	xmm6, xmm4
  4c9a49: f2 0f 58 ef                  	addsd	xmm5, xmm7
  4c9a4d: f2 0f 58 c8                  	addsd	xmm1, xmm0
  4c9a51: f2 0f 10 47 30               	movsd	xmm0, qword ptr [edi + 0x30]
  4c9a56: f2 0f 59 c2                  	mulsd	xmm0, xmm2
  4c9a5a: f2 0f 10 57 38               	movsd	xmm2, qword ptr [edi + 0x38]
  4c9a5f: f2 0f 59 d3                  	mulsd	xmm2, xmm3
  4c9a63: f2 0f 10 5f 40               	movsd	xmm3, qword ptr [edi + 0x40]
  4c9a68: f2 0f 59 dc                  	mulsd	xmm3, xmm4
  4c9a6c: f2 0f 10 25 48 e1 c2 00      	movsd	xmm4, qword ptr [0xc2e148]
  4c9a74: f2 0f 5e 22                  	divsd	xmm4, qword ptr [edx]
  4c9a78: f2 0f 59 ec                  	mulsd	xmm5, xmm4
  4c9a7c: f2 0f 11 2c 24               	movsd	qword ptr [esp], xmm5
  4c9a81: f2 0f 58 ce                  	addsd	xmm1, xmm6
  4c9a85: f2 0f 59 cc                  	mulsd	xmm1, xmm4
  4c9a89: f2 0f 11 4c 24 08            	movsd	qword ptr [esp + 0x8], xmm1
  4c9a8f: f2 0f 58 c2                  	addsd	xmm0, xmm2
  4c9a93: f2 0f 58 c3                  	addsd	xmm0, xmm3
  4c9a97: f2 0f 59 e0                  	mulsd	xmm4, xmm0
  4c9a9b: f2 0f 11 64 24 10            	movsd	qword ptr [esp + 0x10], xmm4
  4c9aa1: 51                           	push	ecx
  4c9aa2: ff 15 f8 59 c2 00            	call	dword ptr [0xc259f8]
  4c9aa8: 4b                           	dec	ebx
  4c9aa9: 0f 8d db fc ff ff            	jge	0x4c978a <.text+0xc878a>
  4c9aaf: 8b 5d 14                     	mov	ebx, dword ptr [ebp + 0x14]
  4c9ab2: 8b 7d 18                     	mov	edi, dword ptr [ebp + 0x18]
  4c9ab5: 8b 75 1c                     	mov	esi, dword ptr [ebp + 0x1c]
  4c9ab8: ff 15 e4 58 c2 00            	call	dword ptr [0xc258e4]
  4c9abe: 0f be 15 28 1e d7 00         	movsx	edx, byte ptr [0xd71e28]
  4c9ac5: e9 90 f0 ff ff               	jmp	0x4c8b5a <.text+0xc7b5a>
  4c9aca: 83 c4 f0                     	add	esp, -0x10
  4c9acd: c7 04 24 00 00 80 3f         	mov	dword ptr [esp], 0x3f800000
  4c9ad4: 33 c0                        	xor	eax, eax
  4c9ad6: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  4c9ada: c7 44 24 0c 00 00 00 3f      	mov	dword ptr [esp + 0xc], 0x3f000000
  4c9ae2: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  4c9ae6: ff 15 70 59 c2 00            	call	dword ptr [0xc25970]
  4c9aec: 6a 06                        	push	0x6
  4c9aee: ff 15 d4 58 c2 00            	call	dword ptr [0xc258d4]
  4c9af4: 8b 45 0c                     	mov	eax, dword ptr [ebp + 0xc]
  4c9af7: f2 0f 10 ac 24 b0 00 00 00   	movsd	xmm5, qword ptr [esp + 0xb0]
  4c9b00: f2 0f 5c 28                  	subsd	xmm5, qword ptr [eax]
  4c9b04: f2 0f 10 94 24 a8 00 00 00   	movsd	xmm2, qword ptr [esp + 0xa8]
  4c9b0d: f2 0f 5c 50 08               	subsd	xmm2, qword ptr [eax + 0x8]
  4c9b12: f2 0f 10 9c 24 b8 00 00 00   	movsd	xmm3, qword ptr [esp + 0xb8]
  4c9b1b: f2 0f 5c 58 10               	subsd	xmm3, qword ptr [eax + 0x10]
  4c9b20: 8b 55 24                     	mov	edx, dword ptr [ebp + 0x24]
  4c9b23: 8b 4d 10                     	mov	ecx, dword ptr [ebp + 0x10]
  4c9b26: 8d 44 24 30                  	lea	eax, [esp + 0x30]
  4c9b2a: f2 0f 10 22                  	movsd	xmm4, qword ptr [edx]
  4c9b2e: f2 0f 59 e5                  	mulsd	xmm4, xmm5
  4c9b32: f2 0f 10 72 08               	movsd	xmm6, qword ptr [edx + 0x8]
  4c9b37: f2 0f 59 f2                  	mulsd	xmm6, xmm2
  4c9b3b: f2 0f 10 7a 10               	movsd	xmm7, qword ptr [edx + 0x10]
  4c9b40: f2 0f 59 fb                  	mulsd	xmm7, xmm3
  4c9b44: f2 0f 10 4a 18               	movsd	xmm1, qword ptr [edx + 0x18]
  4c9b49: f2 0f 59 cd                  	mulsd	xmm1, xmm5
  4c9b4d: f2 0f 10 42 20               	movsd	xmm0, qword ptr [edx + 0x20]
  4c9b52: f2 0f 59 c2                  	mulsd	xmm0, xmm2
  4c9b56: f2 0f 58 e6                  	addsd	xmm4, xmm6
  4c9b5a: f2 0f 10 72 28               	movsd	xmm6, qword ptr [edx + 0x28]
  4c9b5f: f2 0f 59 f3                  	mulsd	xmm6, xmm3
  4c9b63: f2 0f 58 e7                  	addsd	xmm4, xmm7
  4c9b67: f2 0f 58 c8                  	addsd	xmm1, xmm0
  4c9b6b: f2 0f 10 42 30               	movsd	xmm0, qword ptr [edx + 0x30]
  4c9b70: f2 0f 59 c5                  	mulsd	xmm0, xmm5
  4c9b74: f2 0f 10 6a 38               	movsd	xmm5, qword ptr [edx + 0x38]
  4c9b79: f2 0f 59 ea                  	mulsd	xmm5, xmm2
  4c9b7d: f2 0f 10 52 40               	movsd	xmm2, qword ptr [edx + 0x40]
  4c9b82: f2 0f 59 d3                  	mulsd	xmm2, xmm3
  4c9b86: f2 0f 10 1d 48 e1 c2 00      	movsd	xmm3, qword ptr [0xc2e148]
  4c9b8e: f2 0f 5e 19                  	divsd	xmm3, qword ptr [ecx]
  4c9b92: f2 0f 59 e3                  	mulsd	xmm4, xmm3
  4c9b96: f2 0f 11 64 24 30            	movsd	qword ptr [esp + 0x30], xmm4
  4c9b9c: f2 0f 58 ce                  	addsd	xmm1, xmm6
  4c9ba0: f2 0f 59 cb                  	mulsd	xmm1, xmm3
  4c9ba4: f2 0f 11 4c 24 38            	movsd	qword ptr [esp + 0x38], xmm1
  4c9baa: f2 0f 58 c5                  	addsd	xmm0, xmm5
  4c9bae: f2 0f 58 c2                  	addsd	xmm0, xmm2
  4c9bb2: f2 0f 59 d8                  	mulsd	xmm3, xmm0
  4c9bb6: f2 0f 11 5c 24 40            	movsd	qword ptr [esp + 0x40], xmm3
  4c9bbc: 50                           	push	eax
  4c9bbd: ff 15 f8 59 c2 00            	call	dword ptr [0xc259f8]
  4c9bc3: 83 c4 f0                     	add	esp, -0x10
  4c9bc6: c7 04 24 00 00 80 3f         	mov	dword ptr [esp], 0x3f800000
  4c9bcd: 33 c0                        	xor	eax, eax
  4c9bcf: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  4c9bd3: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  4c9bd7: 89 44 24 0c                  	mov	dword ptr [esp + 0xc], eax
  4c9bdb: ff 15 70 59 c2 00            	call	dword ptr [0xc25970]
  4c9be1: 8b 7d 24                     	mov	edi, dword ptr [ebp + 0x24]
  4c9be4: b8 40 00 00 00               	mov	eax, 0x40
  4c9be9: 8b d8                        	mov	ebx, eax
  4c9beb: f2 0f 2a c3                  	cvtsi2sd	xmm0, ebx
  4c9bef: f2 0f 59 05 40 e1 c2 00      	mulsd	xmm0, qword ptr [0xc2e140]
  4c9bf7: e8 14 52 5c 00               	call	0xa8ee10 <.text+0x68de10>
  4c9bfc: f2 0f 10 94 24 20 01 00 00   	movsd	xmm2, qword ptr [esp + 0x120]
  4c9c05: f2 0f 10 a4 24 c0 00 00 00   	movsd	xmm4, qword ptr [esp + 0xc0]
  4c9c0e: f2 0f 59 d4                  	mulsd	xmm2, xmm4
  4c9c12: f2 0f 58 16                  	addsd	xmm2, qword ptr [esi]
  4c9c16: f2 0f 10 ac 24 28 01 00 00   	movsd	xmm5, qword ptr [esp + 0x128]
  4c9c1f: f2 0f 59 ec                  	mulsd	xmm5, xmm4
  4c9c23: f2 0f 58 6e 08               	addsd	xmm5, qword ptr [esi + 0x8]
  4c9c28: f2 0f 10 b4 24 30 01 00 00   	movsd	xmm6, qword ptr [esp + 0x130]
  4c9c31: f2 0f 10 bc 24 40 01 00 00   	movsd	xmm7, qword ptr [esp + 0x140]
  4c9c3a: f2 0f 10 9c 24 48 01 00 00   	movsd	xmm3, qword ptr [esp + 0x148]
  4c9c43: 8b 55 0c                     	mov	edx, dword ptr [ebp + 0xc]
  4c9c46: 8b 4d 10                     	mov	ecx, dword ptr [ebp + 0x10]
  4c9c49: f2 0f 11 2c 24               	movsd	qword ptr [esp], xmm5
  4c9c4e: f2 0f 59 f4                  	mulsd	xmm6, xmm4
  4c9c52: f2 0f 59 f9                  	mulsd	xmm7, xmm1
  4c9c56: f2 0f 59 d9                  	mulsd	xmm3, xmm1
  4c9c5a: f2 0f 58 76 10               	addsd	xmm6, qword ptr [esi + 0x10]
  4c9c5f: f2 0f 10 a4 24 58 01 00 00   	movsd	xmm4, qword ptr [esp + 0x158]
  4c9c68: f2 0f 10 ac 24 60 01 00 00   	movsd	xmm5, qword ptr [esp + 0x160]
  4c9c71: f2 0f 11 74 24 08            	movsd	qword ptr [esp + 0x8], xmm6
  4c9c77: f2 0f 59 e0                  	mulsd	xmm4, xmm0
  4c9c7b: f2 0f 59 e8                  	mulsd	xmm5, xmm0
  4c9c7f: f2 0f 58 fc                  	addsd	xmm7, xmm4
  4c9c83: f2 0f 58 dd                  	addsd	xmm3, xmm5
  4c9c87: f2 0f 10 b4 24 38 01 00 00   	movsd	xmm6, qword ptr [esp + 0x138]
  4c9c90: f2 0f 59 f1                  	mulsd	xmm6, xmm1
  4c9c94: f2 0f 10 8c 24 50 01 00 00   	movsd	xmm1, qword ptr [esp + 0x150]
  4c9c9d: f2 0f 59 c8                  	mulsd	xmm1, xmm0
  4c9ca1: f2 0f 58 f1                  	addsd	xmm6, xmm1
  4c9ca5: f2 0f 10 4f 20               	movsd	xmm1, qword ptr [edi + 0x20]
  4c9caa: f2 0f 10 84 24 c8 00 00 00   	movsd	xmm0, qword ptr [esp + 0xc8]
  4c9cb3: f2 0f 59 f0                  	mulsd	xmm6, xmm0
  4c9cb7: f2 0f 59 f8                  	mulsd	xmm7, xmm0
  4c9cbb: f2 0f 59 d8                  	mulsd	xmm3, xmm0
  4c9cbf: f2 0f 10 47 10               	movsd	xmm0, qword ptr [edi + 0x10]
  4c9cc4: f2 0f 58 d6                  	addsd	xmm2, xmm6
  4c9cc8: f2 0f 5c 12                  	subsd	xmm2, qword ptr [edx]
  4c9ccc: f2 0f 10 2c 24               	movsd	xmm5, qword ptr [esp]
  4c9cd1: f2 0f 10 64 24 08            	movsd	xmm4, qword ptr [esp + 0x8]
  4c9cd7: f2 0f 10 77 28               	movsd	xmm6, qword ptr [edi + 0x28]
  4c9cdc: f2 0f 58 ef                  	addsd	xmm5, xmm7
  4c9ce0: f2 0f 5c 6a 08               	subsd	xmm5, qword ptr [edx + 0x8]
  4c9ce5: f2 0f 59 cd                  	mulsd	xmm1, xmm5
  4c9ce9: f2 0f 10 7f 08               	movsd	xmm7, qword ptr [edi + 0x8]
  4c9cee: f2 0f 59 fd                  	mulsd	xmm7, xmm5
  4c9cf2: f2 0f 58 e3                  	addsd	xmm4, xmm3
  4c9cf6: f2 0f 5c 62 10               	subsd	xmm4, qword ptr [edx + 0x10]
  4c9cfb: f2 0f 59 c4                  	mulsd	xmm0, xmm4
  4c9cff: f2 0f 59 f4                  	mulsd	xmm6, xmm4
  4c9d03: f2 0f 10 1f                  	movsd	xmm3, qword ptr [edi]
  4c9d07: f2 0f 59 da                  	mulsd	xmm3, xmm2
  4c9d0b: 8d 94 24 d8 00 00 00         	lea	edx, [esp + 0xd8]
  4c9d12: f2 0f 58 df                  	addsd	xmm3, xmm7
  4c9d16: f2 0f 58 d8                  	addsd	xmm3, xmm0
  4c9d1a: f2 0f 10 47 18               	movsd	xmm0, qword ptr [edi + 0x18]
  4c9d1f: f2 0f 59 c2                  	mulsd	xmm0, xmm2
  4c9d23: f2 0f 58 c1                  	addsd	xmm0, xmm1
  4c9d27: f2 0f 10 4f 30               	movsd	xmm1, qword ptr [edi + 0x30]
  4c9d2c: f2 0f 59 ca                  	mulsd	xmm1, xmm2
  4c9d30: f2 0f 10 57 38               	movsd	xmm2, qword ptr [edi + 0x38]
  4c9d35: f2 0f 59 d5                  	mulsd	xmm2, xmm5
  4c9d39: f2 0f 10 6f 40               	movsd	xmm5, qword ptr [edi + 0x40]
  4c9d3e: f2 0f 59 ec                  	mulsd	xmm5, xmm4
  4c9d42: f2 0f 10 25 48 e1 c2 00      	movsd	xmm4, qword ptr [0xc2e148]
  4c9d4a: f2 0f 5e 21                  	divsd	xmm4, qword ptr [ecx]
  4c9d4e: f2 0f 59 dc                  	mulsd	xmm3, xmm4
  4c9d52: f2 0f 11 9c 24 d8 00 00 00   	movsd	qword ptr [esp + 0xd8], xmm3
  4c9d5b: f2 0f 58 c6                  	addsd	xmm0, xmm6
  4c9d5f: f2 0f 59 c4                  	mulsd	xmm0, xmm4
  4c9d63: f2 0f 11 84 24 e0 00 00 00   	movsd	qword ptr [esp + 0xe0], xmm0
  4c9d6c: f2 0f 58 ca                  	addsd	xmm1, xmm2
  4c9d70: f2 0f 58 cd                  	addsd	xmm1, xmm5
  4c9d74: f2 0f 59 e1                  	mulsd	xmm4, xmm1
  4c9d78: f2 0f 11 a4 24 e8 00 00 00   	movsd	qword ptr [esp + 0xe8], xmm4
  4c9d81: 52                           	push	edx
  4c9d82: ff 15 f8 59 c2 00            	call	dword ptr [0xc259f8]
  4c9d88: 4b                           	dec	ebx
  4c9d89: 0f 8d 5c fe ff ff            	jge	0x4c9beb <.text+0xc8beb>
  4c9d8f: 8b 5d 14                     	mov	ebx, dword ptr [ebp + 0x14]
  4c9d92: 8b 7d 18                     	mov	edi, dword ptr [ebp + 0x18]
  4c9d95: ff 15 e4 58 c2 00            	call	dword ptr [0xc258e4]
  4c9d9b: 0f be 15 28 1e d7 00         	movsx	edx, byte ptr [0xd71e28]
  4c9da2: e9 b3 ed ff ff               	jmp	0x4c8b5a <.text+0xc7b5a>
