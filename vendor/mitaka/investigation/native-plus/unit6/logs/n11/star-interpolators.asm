
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  7bf840: 00 00                        	add	byte ptr [eax], al
  7bf842: 50                           	push	eax
  7bf843: c7 04 24 14 00 00 00         	mov	dword ptr [esp], 0x14
  7bf84a: e8 bb f7 2c 00               	call	0xa8f00a <.text+0x68e00a>
  7bf84f: 59                           	pop	ecx
  7bf850: 89 45 e0                     	mov	dword ptr [ebp - 0x20], eax
  7bf853: 85 c0                        	test	eax, eax
  7bf855: 74 1c                        	je	0x7bf873 <.text+0x3be873>
  7bf857: 8b 55 08                     	mov	edx, dword ptr [ebp + 0x8]
  7bf85a: c7 00 dc f9 37 01            	mov	dword ptr [eax], 0x137f9dc
  7bf860: 89 50 04                     	mov	dword ptr [eax + 0x4], edx
  7bf863: 33 c9                        	xor	ecx, ecx
  7bf865: 89 4d dc                     	mov	dword ptr [ebp - 0x24], ecx
  7bf868: 89 48 08                     	mov	dword ptr [eax + 0x8], ecx
  7bf86b: 89 48 0c                     	mov	dword ptr [eax + 0xc], ecx
  7bf86e: 89 48 10                     	mov	dword ptr [eax + 0x10], ecx
  7bf871: eb 02                        	jmp	0x7bf875 <.text+0x3be875>
  7bf873: 33 c0                        	xor	eax, eax
  7bf875: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  7bf87c: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  7bf87f: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  7bf886: 8b e5                        	mov	esp, ebp
  7bf888: 5d                           	pop	ebp
  7bf889: c3                           	ret
  7bf88a: 90                           	nop
  7bf88b: 90                           	nop
  7bf88c: 90                           	nop
  7bf88d: 90                           	nop
  7bf88e: 90                           	nop
  7bf88f: 90                           	nop
  7bf890: 55                           	push	ebp
  7bf891: 8b ec                        	mov	ebp, esp
  7bf893: 6a ff                        	push	-0x1
  7bf895: 68 60 12 c1 00               	push	0xc11260
  7bf89a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  7bf8a0: 50                           	push	eax
  7bf8a1: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  7bf8a8: 83 ec 18                     	sub	esp, 0x18
  7bf8ab: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  7bf8ae: 89 7d e4                     	mov	dword ptr [ebp - 0x1c], edi
  7bf8b1: 89 75 e8                     	mov	dword ptr [ebp - 0x18], esi
  7bf8b4: c7 45 dc 00 00 00 00         	mov	dword ptr [ebp - 0x24], 0x0
  7bf8bb: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  7bf8c2: 50                           	push	eax
  7bf8c3: c7 04 24 14 00 00 00         	mov	dword ptr [esp], 0x14
  7bf8ca: e8 3b f7 2c 00               	call	0xa8f00a <.text+0x68e00a>
  7bf8cf: 59                           	pop	ecx
  7bf8d0: 89 45 e0                     	mov	dword ptr [ebp - 0x20], eax
  7bf8d3: 85 c0                        	test	eax, eax
  7bf8d5: 74 1c                        	je	0x7bf8f3 <.text+0x3be8f3>
  7bf8d7: 8b 55 08                     	mov	edx, dword ptr [ebp + 0x8]
  7bf8da: c7 00 dc f9 37 01            	mov	dword ptr [eax], 0x137f9dc
  7bf8e0: 33 c9                        	xor	ecx, ecx
  7bf8e2: 89 48 04                     	mov	dword ptr [eax + 0x4], ecx
  7bf8e5: 89 4d dc                     	mov	dword ptr [ebp - 0x24], ecx
  7bf8e8: 89 50 08                     	mov	dword ptr [eax + 0x8], edx
  7bf8eb: 89 48 0c                     	mov	dword ptr [eax + 0xc], ecx
  7bf8ee: 89 48 10                     	mov	dword ptr [eax + 0x10], ecx
  7bf8f1: eb 02                        	jmp	0x7bf8f5 <.text+0x3be8f5>
  7bf8f3: 33 c0                        	xor	eax, eax
  7bf8f5: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  7bf8fc: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  7bf8ff: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  7bf906: 8b e5                        	mov	esp, ebp
  7bf908: 5d                           	pop	ebp
  7bf909: c3                           	ret
  7bf90a: 90                           	nop
  7bf90b: 90                           	nop
  7bf90c: 90                           	nop
  7bf90d: 90                           	nop
  7bf90e: 90                           	nop
  7bf90f: 90                           	nop
  7bf910: 55                           	push	ebp
  7bf911: 8b ec                        	mov	ebp, esp
  7bf913: 6a ff                        	push	-0x1
  7bf915: 68 80 12 c1 00               	push	0xc11280
  7bf91a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  7bf920: 50                           	push	eax
  7bf921: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  7bf928: 83 ec 18                     	sub	esp, 0x18
  7bf92b: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  7bf92e: 89 7d e4                     	mov	dword ptr [ebp - 0x1c], edi
  7bf931: 89 75 e8                     	mov	dword ptr [ebp - 0x18], esi
  7bf934: c7 45 dc 00 00 00 00         	mov	dword ptr [ebp - 0x24], 0x0
  7bf93b: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  7bf942: 50                           	push	eax
  7bf943: c7 04 24 14 00 00 00         	mov	dword ptr [esp], 0x14
  7bf94a: e8 bb f6 2c 00               	call	0xa8f00a <.text+0x68e00a>
  7bf94f: 59                           	pop	ecx
  7bf950: 89 45 e0                     	mov	dword ptr [ebp - 0x20], eax
  7bf953: 85 c0                        	test	eax, eax
  7bf955: 74 1c                        	je	0x7bf973 <.text+0x3be973>
  7bf957: 8b 55 08                     	mov	edx, dword ptr [ebp + 0x8]
  7bf95a: c7 00 dc f9 37 01            	mov	dword ptr [eax], 0x137f9dc
  7bf960: 33 c9                        	xor	ecx, ecx
  7bf962: 89 48 04                     	mov	dword ptr [eax + 0x4], ecx
  7bf965: 89 4d dc                     	mov	dword ptr [ebp - 0x24], ecx
  7bf968: 89 48 08                     	mov	dword ptr [eax + 0x8], ecx
  7bf96b: 89 50 0c                     	mov	dword ptr [eax + 0xc], edx
  7bf96e: 89 48 10                     	mov	dword ptr [eax + 0x10], ecx
  7bf971: eb 02                        	jmp	0x7bf975 <.text+0x3be975>
  7bf973: 33 c0                        	xor	eax, eax
  7bf975: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  7bf97c: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  7bf97f: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  7bf986: 8b e5                        	mov	esp, ebp
  7bf988: 5d                           	pop	ebp
  7bf989: c3                           	ret
  7bf98a: 90                           	nop
  7bf98b: 90                           	nop
  7bf98c: 90                           	nop
  7bf98d: 90                           	nop
  7bf98e: 90                           	nop
  7bf98f: 90                           	nop
  7bf990: 55                           	push	ebp
  7bf991: 8b ec                        	mov	ebp, esp
  7bf993: 6a ff                        	push	-0x1
  7bf995: 68 a0 12 c1 00               	push	0xc112a0
  7bf99a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  7bf9a0: 50                           	push	eax
  7bf9a1: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  7bf9a8: 83 ec 18                     	sub	esp, 0x18
  7bf9ab: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  7bf9ae: 89 7d e4                     	mov	dword ptr [ebp - 0x1c], edi
  7bf9b1: 89 75 e8                     	mov	dword ptr [ebp - 0x18], esi
  7bf9b4: c7 45 dc 00 00 00 00         	mov	dword ptr [ebp - 0x24], 0x0
  7bf9bb: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  7bf9c2: 50                           	push	eax
  7bf9c3: c7 04 24 14 00 00 00         	mov	dword ptr [esp], 0x14
  7bf9ca: e8 3b f6 2c 00               	call	0xa8f00a <.text+0x68e00a>
  7bf9cf: 59                           	pop	ecx
  7bf9d0: 89 45 e0                     	mov	dword ptr [ebp - 0x20], eax
  7bf9d3: 85 c0                        	test	eax, eax
  7bf9d5: 74 1c                        	je	0x7bf9f3 <.text+0x3be9f3>
  7bf9d7: 8b 55 08                     	mov	edx, dword ptr [ebp + 0x8]
  7bf9da: c7 00 dc f9 37 01            	mov	dword ptr [eax], 0x137f9dc
  7bf9e0: 33 c9                        	xor	ecx, ecx
  7bf9e2: 89 48 04                     	mov	dword ptr [eax + 0x4], ecx
  7bf9e5: 89 4d dc                     	mov	dword ptr [ebp - 0x24], ecx
  7bf9e8: 89 48 08                     	mov	dword ptr [eax + 0x8], ecx
  7bf9eb: 89 48 0c                     	mov	dword ptr [eax + 0xc], ecx
  7bf9ee: 89 50 10                     	mov	dword ptr [eax + 0x10], edx
  7bf9f1: eb 02                        	jmp	0x7bf9f5 <.text+0x3be9f5>
  7bf9f3: 33 c0                        	xor	eax, eax
  7bf9f5: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  7bf9fc: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  7bf9ff: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  7bfa06: 8b e5                        	mov	esp, ebp
  7bfa08: 5d                           	pop	ebp
  7bfa09: c3                           	ret
  7bfa0a: 90                           	nop
  7bfa0b: 90                           	nop
  7bfa0c: 90                           	nop
  7bfa0d: 90                           	nop
  7bfa0e: 90                           	nop
  7bfa0f: 90                           	nop
  7bfa10: 56                           	push	esi
  7bfa11: 8b f1                        	mov	esi, ecx
  7bfa13: c7 06 e8 f9 37 01            	mov	dword ptr [esi], 0x137f9e8
  7bfa19: e8 22 1f 00 00               	call	0x7c1940 <.text+0x3c0940>
  7bfa1e: f6 44 24 08 01               	test	byte ptr [esp + 0x8], 0x1
  7bfa23: 75 06                        	jne	0x7bfa2b <.text+0x3bea2b>
  7bfa25: 8b c6                        	mov	eax, esi
  7bfa27: 5e                           	pop	esi
  7bfa28: c2 04 00                     	ret	0x4
  7bfa2b: 56                           	push	esi
  7bfa2c: e8 61 f5 2c 00               	call	0xa8ef92 <.text+0x68df92>
  7bfa31: 59                           	pop	ecx
  7bfa32: eb f1                        	jmp	0x7bfa25 <.text+0x3bea25>
  7bfa34: 8d b6 00 00 00 00            	lea	esi, [esi]
  7bfa3a: 8d bf 00 00 00 00            	lea	edi, [edi]
  7bfa40: 56                           	push	esi
  7bfa41: 8b f1                        	mov	esi, ecx
  7bfa43: c7 06 e8 f9 37 01            	mov	dword ptr [esi], 0x137f9e8
  7bfa49: e8 f2 1e 00 00               	call	0x7c1940 <.text+0x3c0940>
  7bfa4e: f6 44 24 08 01               	test	byte ptr [esp + 0x8], 0x1
  7bfa53: 75 06                        	jne	0x7bfa5b <.text+0x3bea5b>
  7bfa55: 8b c6                        	mov	eax, esi
  7bfa57: 5e                           	pop	esi
  7bfa58: c2 04 00                     	ret	0x4
  7bfa5b: 56                           	push	esi
  7bfa5c: e8 31 f5 2c 00               	call	0xa8ef92 <.text+0x68df92>
  7bfa61: 59                           	pop	ecx
  7bfa62: eb f1                        	jmp	0x7bfa55 <.text+0x3bea55>
  7bfa64: 8d b6 00 00 00 00            	lea	esi, [esi]
  7bfa6a: 8d bf 00 00 00 00            	lea	edi, [edi]
  7bfa70: c2 08 00                     	ret	0x8
  7bfa73: 8d b6 00 00 00 00            	lea	esi, [esi]
  7bfa79: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7bfa80: c3                           	ret
  7bfa81: 90                           	nop
  7bfa82: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  7bfa89: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7bfa90: 57                           	push	edi
  7bfa91: 8b f9                        	mov	edi, ecx
  7bfa93: e8 78 1e 00 00               	call	0x7c1910 <.text+0x3c0910>
  7bfa98: 8b 54 24 18                  	mov	edx, dword ptr [esp + 0x18]
  7bfa9c: f2 0f 10 4c 24 10            	movsd	xmm1, qword ptr [esp + 0x10]
  7bfaa2: f2 0f 10 44 24 08            	movsd	xmm0, qword ptr [esp + 0x8]
  7bfaa8: f2 0f 11 47 30               	movsd	qword ptr [edi + 0x30], xmm0
  7bfaad: f2 0f 11 4f 08               	movsd	qword ptr [edi + 0x8], xmm1
  7bfab2: c7 07 fc f9 37 01            	mov	dword ptr [edi], 0x137f9fc
  7bfab8: 89 57 18                     	mov	dword ptr [edi + 0x18], edx
  7bfabb: 8b c7                        	mov	eax, edi
  7bfabd: 5f                           	pop	edi
  7bfabe: c2 14 00                     	ret	0x14
  7bfac1: 90                           	nop
  7bfac2: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  7bfac9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7bfad0: c7 01 e8 f9 37 01            	mov	dword ptr [ecx], 0x137f9e8
  7bfad6: e8 65 1e 00 00               	call	0x7c1940 <.text+0x3c0940>
  7bfadb: c3                           	ret
  7bfadc: 8d 74 26 00                  	lea	esi, [esi + eiz]
  7bfae0: 55                           	push	ebp
  7bfae1: 8b ec                        	mov	ebp, esp
  7bfae3: 83 e4 c0                     	and	esp, -0x40
  7bfae6: 53                           	push	ebx
  7bfae7: 83 ec 3c                     	sub	esp, 0x3c
  7bfaea: 8b d9                        	mov	ebx, ecx
  7bfaec: 0f b6 43 20                  	movzx	eax, byte ptr [ebx + 0x20]
  7bfaf0: 85 c0                        	test	eax, eax
  7bfaf2: 74 0a                        	je	0x7bfafe <.text+0x3beafe>
  7bfaf4: 83 c4 3c                     	add	esp, 0x3c
  7bfaf7: 5b                           	pop	ebx
  7bfaf8: 8b e5                        	mov	esp, ebp
  7bfafa: 5d                           	pop	ebp
  7bfafb: c2 08 00                     	ret	0x8
  7bfafe: f2 0f 10 45 08               	movsd	xmm0, qword ptr [ebp + 0x8]
  7bfb03: 83 c4 f8                     	add	esp, -0x8
  7bfb06: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  7bfb0b: 8b cb                        	mov	ecx, ebx
  7bfb0d: e8 7e 1e 00 00               	call	0x7c1990 <.text+0x3c0990>
  7bfb12: dd 1c 24                     	fstp	qword ptr [esp]
  7bfb15: f2 0f 10 04 24               	movsd	xmm0, qword ptr [esp]
  7bfb1a: 66 0f 2e 05 58 c0 cb 00      	ucomisd	xmm0, qword ptr [0xcbc058]
  7bfb22: 7a 02                        	jp	0x7bfb26 <.text+0x3beb26>
  7bfb24: 74 4b                        	je	0x7bfb71 <.text+0x3beb71>
  7bfb26: f2 0f 59 05 50 c0 cb 00      	mulsd	xmm0, qword ptr [0xcbc050]
  7bfb2e: f2 0f 10 0d 48 c0 cb 00      	movsd	xmm1, qword ptr [0xcbc048]
  7bfb36: f2 0f 11 0c 24               	movsd	qword ptr [esp], xmm1
  7bfb3b: e8 ca f2 2c 00               	call	0xa8ee0a <.text+0x68de0a>
  7bfb40: f2 0f 10 0c 24               	movsd	xmm1, qword ptr [esp]
  7bfb45: f2 0f 59 c1                  	mulsd	xmm0, xmm1
  7bfb49: 8b 4b 1c                     	mov	ecx, dword ptr [ebx + 0x1c]
  7bfb4c: 8b 01                        	mov	eax, dword ptr [ecx]
  7bfb4e: f2 0f 5c c8                  	subsd	xmm1, xmm0
  7bfb52: f2 0f 59 4b 38               	mulsd	xmm1, qword ptr [ebx + 0x38]
  7bfb57: f2 0f 58 4b 28               	addsd	xmm1, qword ptr [ebx + 0x28]
  7bfb5c: 83 c4 f8                     	add	esp, -0x8
  7bfb5f: f2 0f 11 0c 24               	movsd	qword ptr [esp], xmm1
  7bfb64: ff 50 04                     	call	dword ptr [eax + 0x4]
  7bfb67: 83 c4 3c                     	add	esp, 0x3c
  7bfb6a: 5b                           	pop	ebx
  7bfb6b: 8b e5                        	mov	esp, ebp
  7bfb6d: 5d                           	pop	ebp
  7bfb6e: c2 08 00                     	ret	0x8
  7bfb71: 8b 4b 1c                     	mov	ecx, dword ptr [ebx + 0x1c]
  7bfb74: 8b 01                        	mov	eax, dword ptr [ecx]
  7bfb76: f2 0f 10 43 30               	movsd	xmm0, qword ptr [ebx + 0x30]
  7bfb7b: 83 c4 f8                     	add	esp, -0x8
  7bfb7e: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  7bfb83: ff 50 04                     	call	dword ptr [eax + 0x4]
  7bfb86: 83 c4 3c                     	add	esp, 0x3c
  7bfb89: 5b                           	pop	ebx
  7bfb8a: 8b e5                        	mov	esp, ebp
  7bfb8c: 5d                           	pop	ebp
  7bfb8d: c2 08 00                     	ret	0x8
  7bfb90: 57                           	push	edi
  7bfb91: 8b f9                        	mov	edi, ecx
  7bfb93: 8b 4f 1c                     	mov	ecx, dword ptr [edi + 0x1c]
  7bfb96: 85 c9                        	test	ecx, ecx
  7bfb98: 74 23                        	je	0x7bfbbd <.text+0x3bebbd>
  7bfb9a: 8b 01                        	mov	eax, dword ptr [ecx]
  7bfb9c: f2 0f 10 47 30               	movsd	xmm0, qword ptr [edi + 0x30]
  7bfba1: 83 c4 f8                     	add	esp, -0x8
  7bfba4: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  7bfba9: ff 50 04                     	call	dword ptr [eax + 0x4]
  7bfbac: e8 4f dc ff ff               	call	0x7bd800 <.text+0x3bc800>
  7bfbb1: 6a 00                        	push	0x0
  7bfbb3: ff 77 1c                     	push	dword ptr [edi + 0x1c]
  7bfbb6: 8b c8                        	mov	ecx, eax
  7bfbb8: e8 b3 e9 ff ff               	call	0x7be570 <.text+0x3bd570>
  7bfbbd: c6 47 20 01                  	mov	byte ptr [edi + 0x20], 0x1
  7bfbc1: 5f                           	pop	edi
  7bfbc2: c3                           	ret
  7bfbc3: 8d b6 00 00 00 00            	lea	esi, [esi]
  7bfbc9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7bfbd0: 55                           	push	ebp
  7bfbd1: 8b ec                        	mov	ebp, esp
  7bfbd3: 83 e4 f8                     	and	esp, -0x8
  7bfbd6: 57                           	push	edi
  7bfbd7: 56                           	push	esi
  7bfbd8: 8b f9                        	mov	edi, ecx
  7bfbda: ff 75 08                     	push	dword ptr [ebp + 0x8]
  7bfbdd: e8 9e 1e 00 00               	call	0x7c1a80 <.text+0x3c0a80>
  7bfbe2: f2 0f 10 45 0c               	movsd	xmm0, qword ptr [ebp + 0xc]
  7bfbe7: f2 0f 10 4f 30               	movsd	xmm1, qword ptr [edi + 0x30]
  7bfbec: f2 0f 11 47 28               	movsd	qword ptr [edi + 0x28], xmm0
  7bfbf1: f2 0f 5c c8                  	subsd	xmm1, xmm0
  7bfbf5: f2 0f 11 4f 38               	movsd	qword ptr [edi + 0x38], xmm1
  7bfbfa: 59                           	pop	ecx
  7bfbfb: 5f                           	pop	edi
  7bfbfc: 8b e5                        	mov	esp, ebp
  7bfbfe: 5d                           	pop	ebp
  7bfbff: c2 0c 00                     	ret	0xc
  7bfc02: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  7bfc09: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7bfc10: c2 0c 00                     	ret	0xc
  7bfc13: 8d b6 00 00 00 00            	lea	esi, [esi]
  7bfc19: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7bfc20: 56                           	push	esi
  7bfc21: 8b f1                        	mov	esi, ecx
  7bfc23: c7 06 e8 f9 37 01            	mov	dword ptr [esi], 0x137f9e8
  7bfc29: e8 12 1d 00 00               	call	0x7c1940 <.text+0x3c0940>
  7bfc2e: f6 44 24 08 01               	test	byte ptr [esp + 0x8], 0x1
  7bfc33: 75 06                        	jne	0x7bfc3b <.text+0x3bec3b>
  7bfc35: 8b c6                        	mov	eax, esi
  7bfc37: 5e                           	pop	esi
  7bfc38: c2 04 00                     	ret	0x4
  7bfc3b: 56                           	push	esi
  7bfc3c: e8 51 f3 2c 00               	call	0xa8ef92 <.text+0x68df92>
  7bfc41: 59                           	pop	ecx
  7bfc42: eb f1                        	jmp	0x7bfc35 <.text+0x3bec35>
  7bfc44: 8d b6 00 00 00 00            	lea	esi, [esi]
  7bfc4a: 8d bf 00 00 00 00            	lea	edi, [edi]
  7bfc50: 57                           	push	edi
  7bfc51: 8b f9                        	mov	edi, ecx
  7bfc53: e8 b8 1c 00 00               	call	0x7c1910 <.text+0x3c0910>
  7bfc58: 8b 54 24 18                  	mov	edx, dword ptr [esp + 0x18]
  7bfc5c: f2 0f 10 4c 24 10            	movsd	xmm1, qword ptr [esp + 0x10]
  7bfc62: f2 0f 10 44 24 08            	movsd	xmm0, qword ptr [esp + 0x8]
  7bfc68: f2 0f 11 47 30               	movsd	qword ptr [edi + 0x30], xmm0
  7bfc6d: f2 0f 11 4f 08               	movsd	qword ptr [edi + 0x8], xmm1
  7bfc72: c7 07 10 fa 37 01            	mov	dword ptr [edi], 0x137fa10
  7bfc78: 89 57 18                     	mov	dword ptr [edi + 0x18], edx
  7bfc7b: 8b c7                        	mov	eax, edi
  7bfc7d: 5f                           	pop	edi
  7bfc7e: c2 14 00                     	ret	0x14
  7bfc81: 90                           	nop
  7bfc82: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  7bfc89: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7bfc90: c7 01 e8 f9 37 01            	mov	dword ptr [ecx], 0x137f9e8
  7bfc96: e8 a5 1c 00 00               	call	0x7c1940 <.text+0x3c0940>
  7bfc9b: c3                           	ret
  7bfc9c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  7bfca0: 55                           	push	ebp
  7bfca1: 8b ec                        	mov	ebp, esp
  7bfca3: 83 e4 c0                     	and	esp, -0x40
  7bfca6: 57                           	push	edi
  7bfca7: 83 ec 3c                     	sub	esp, 0x3c
  7bfcaa: 8b f9                        	mov	edi, ecx
  7bfcac: 0f b6 47 20                  	movzx	eax, byte ptr [edi + 0x20]
  7bfcb0: 85 c0                        	test	eax, eax
  7bfcb2: 74 0a                        	je	0x7bfcbe <.text+0x3becbe>
  7bfcb4: 83 c4 3c                     	add	esp, 0x3c
  7bfcb7: 5f                           	pop	edi
  7bfcb8: 8b e5                        	mov	esp, ebp
  7bfcba: 5d                           	pop	ebp
  7bfcbb: c2 08 00                     	ret	0x8
  7bfcbe: f2 0f 10 45 08               	movsd	xmm0, qword ptr [ebp + 0x8]
  7bfcc3: 83 c4 f8                     	add	esp, -0x8
  7bfcc6: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  7bfccb: 8b cf                        	mov	ecx, edi
  7bfccd: e8 be 1c 00 00               	call	0x7c1990 <.text+0x3c0990>
  7bfcd2: dd 1c 24                     	fstp	qword ptr [esp]
  7bfcd5: f2 0f 10 04 24               	movsd	xmm0, qword ptr [esp]
  7bfcda: 66 0f 2e 05 60 c0 cb 00      	ucomisd	xmm0, qword ptr [0xcbc060]
  7bfce2: 7a 02                        	jp	0x7bfce6 <.text+0x3bece6>
  7bfce4: 74 28                        	je	0x7bfd0e <.text+0x3bed0e>
  7bfce6: 8b 4f 1c                     	mov	ecx, dword ptr [edi + 0x1c]
  7bfce9: 8b 01                        	mov	eax, dword ptr [ecx]
  7bfceb: f2 0f 10 4f 38               	movsd	xmm1, qword ptr [edi + 0x38]
  7bfcf0: f2 0f 59 c8                  	mulsd	xmm1, xmm0
  7bfcf4: f2 0f 58 4f 28               	addsd	xmm1, qword ptr [edi + 0x28]
  7bfcf9: 83 c4 f8                     	add	esp, -0x8
  7bfcfc: f2 0f 11 0c 24               	movsd	qword ptr [esp], xmm1
  7bfd01: ff 50 04                     	call	dword ptr [eax + 0x4]
  7bfd04: 83 c4 3c                     	add	esp, 0x3c
  7bfd07: 5f                           	pop	edi
  7bfd08: 8b e5                        	mov	esp, ebp
  7bfd0a: 5d                           	pop	ebp
  7bfd0b: c2 08 00                     	ret	0x8
  7bfd0e: 8b 4f 1c                     	mov	ecx, dword ptr [edi + 0x1c]
  7bfd11: 8b 01                        	mov	eax, dword ptr [ecx]
  7bfd13: f2 0f 10 47 30               	movsd	xmm0, qword ptr [edi + 0x30]
  7bfd18: 83 c4 f8                     	add	esp, -0x8
  7bfd1b: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  7bfd20: ff 50 04                     	call	dword ptr [eax + 0x4]
  7bfd23: 83 c4 3c                     	add	esp, 0x3c
  7bfd26: 5f                           	pop	edi
  7bfd27: 8b e5                        	mov	esp, ebp
  7bfd29: 5d                           	pop	ebp
  7bfd2a: c2 08 00                     	ret	0x8
  7bfd2d: 8d 76 00                     	lea	esi, [esi]
  7bfd30: 57                           	push	edi
  7bfd31: 8b f9                        	mov	edi, ecx
  7bfd33: 8b 4f 1c                     	mov	ecx, dword ptr [edi + 0x1c]
  7bfd36: 85 c9                        	test	ecx, ecx
  7bfd38: 74 23                        	je	0x7bfd5d <.text+0x3bed5d>
  7bfd3a: 8b 01                        	mov	eax, dword ptr [ecx]
  7bfd3c: f2 0f 10 47 30               	movsd	xmm0, qword ptr [edi + 0x30]
  7bfd41: 83 c4 f8                     	add	esp, -0x8
  7bfd44: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  7bfd49: ff 50 04                     	call	dword ptr [eax + 0x4]
  7bfd4c: e8 af da ff ff               	call	0x7bd800 <.text+0x3bc800>
  7bfd51: 6a 00                        	push	0x0
  7bfd53: ff 77 1c                     	push	dword ptr [edi + 0x1c]
  7bfd56: 8b c8                        	mov	ecx, eax
  7bfd58: e8 13 e8 ff ff               	call	0x7be570 <.text+0x3bd570>
  7bfd5d: c6 47 20 01                  	mov	byte ptr [edi + 0x20], 0x1
  7bfd61: 5f                           	pop	edi
  7bfd62: c3                           	ret
  7bfd63: 8d b6 00 00 00 00            	lea	esi, [esi]
  7bfd69: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7bfd70: 55                           	push	ebp
  7bfd71: 8b ec                        	mov	ebp, esp
  7bfd73: 83 e4 f8                     	and	esp, -0x8
  7bfd76: 57                           	push	edi
  7bfd77: 56                           	push	esi
  7bfd78: 8b f9                        	mov	edi, ecx
  7bfd7a: ff 75 08                     	push	dword ptr [ebp + 0x8]
  7bfd7d: e8 fe 1c 00 00               	call	0x7c1a80 <.text+0x3c0a80>
  7bfd82: f2 0f 10 45 0c               	movsd	xmm0, qword ptr [ebp + 0xc]
  7bfd87: f2 0f 10 4f 30               	movsd	xmm1, qword ptr [edi + 0x30]
  7bfd8c: f2 0f 11 47 28               	movsd	qword ptr [edi + 0x28], xmm0
  7bfd91: f2 0f 5c c8                  	subsd	xmm1, xmm0
  7bfd95: f2 0f 11 4f 38               	movsd	qword ptr [edi + 0x38], xmm1
  7bfd9a: 59                           	pop	ecx
  7bfd9b: 5f                           	pop	edi
  7bfd9c: 8b e5                        	mov	esp, ebp
  7bfd9e: 5d                           	pop	ebp
  7bfd9f: c2 0c 00                     	ret	0xc
  7bfda2: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  7bfda9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7bfdb0: 56                           	push	esi
  7bfdb1: 8b f1                        	mov	esi, ecx
  7bfdb3: c7 06 24 fa 37 01            	mov	dword ptr [esi], 0x137fa24
  7bfdb9: e8 82 1b 00 00               	call	0x7c1940 <.text+0x3c0940>
  7bfdbe: f6 44 24 08 01               	test	byte ptr [esp + 0x8], 0x1
  7bfdc3: 75 06                        	jne	0x7bfdcb <.text+0x3bedcb>
  7bfdc5: 8b c6                        	mov	eax, esi
  7bfdc7: 5e                           	pop	esi
  7bfdc8: c2 04 00                     	ret	0x4
  7bfdcb: 56                           	push	esi
  7bfdcc: e8 c1 f1 2c 00               	call	0xa8ef92 <.text+0x68df92>
  7bfdd1: 59                           	pop	ecx
  7bfdd2: eb f1                        	jmp	0x7bfdc5 <.text+0x3bedc5>
  7bfdd4: 8d b6 00 00 00 00            	lea	esi, [esi]
  7bfdda: 8d bf 00 00 00 00            	lea	edi, [edi]
  7bfde0: 56                           	push	esi
  7bfde1: 8b f1                        	mov	esi, ecx
  7bfde3: c7 06 24 fa 37 01            	mov	dword ptr [esi], 0x137fa24
  7bfde9: e8 52 1b 00 00               	call	0x7c1940 <.text+0x3c0940>
  7bfdee: f6 44 24 08 01               	test	byte ptr [esp + 0x8], 0x1
  7bfdf3: 75 06                        	jne	0x7bfdfb <.text+0x3bedfb>
  7bfdf5: 8b c6                        	mov	eax, esi
  7bfdf7: 5e                           	pop	esi
  7bfdf8: c2 04 00                     	ret	0x4
  7bfdfb: 56                           	push	esi
  7bfdfc: e8 91 f1 2c 00               	call	0xa8ef92 <.text+0x68df92>
  7bfe01: 59                           	pop	ecx
  7bfe02: eb f1                        	jmp	0x7bfdf5 <.text+0x3bedf5>
  7bfe04: 8d b6 00 00 00 00            	lea	esi, [esi]
  7bfe0a: 8d bf 00 00 00 00            	lea	edi, [edi]
  7bfe10: c2 08 00                     	ret	0x8
  7bfe13: 8d b6 00 00 00 00            	lea	esi, [esi]
  7bfe19: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7bfe20: c3                           	ret
  7bfe21: 90                           	nop
  7bfe22: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  7bfe29: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7bfe30: 53                           	push	ebx
  7bfe31: 8b d9                        	mov	ebx, ecx
  7bfe33: e8 d8 1a 00 00               	call	0x7c1910 <.text+0x3c0910>
  7bfe38: 8b 54 24 30                  	mov	edx, dword ptr [esp + 0x30]
  7bfe3c: f2 0f 10 64 24 28            	movsd	xmm4, qword ptr [esp + 0x28]
  7bfe42: f2 0f 10 5c 24 20            	movsd	xmm3, qword ptr [esp + 0x20]
  7bfe48: f2 0f 10 54 24 18            	movsd	xmm2, qword ptr [esp + 0x18]
  7bfe4e: f2 0f 10 4c 24 10            	movsd	xmm1, qword ptr [esp + 0x10]
  7bfe54: f2 0f 10 44 24 08            	movsd	xmm0, qword ptr [esp + 0x8]
  7bfe5a: f2 0f 11 43 48               	movsd	qword ptr [ebx + 0x48], xmm0
  7bfe5f: f2 0f 11 4b 50               	movsd	qword ptr [ebx + 0x50], xmm1
  7bfe64: f2 0f 11 53 58               	movsd	qword ptr [ebx + 0x58], xmm2
  7bfe69: f2 0f 11 5b 60               	movsd	qword ptr [ebx + 0x60], xmm3
  7bfe6e: f2 0f 11 63 08               	movsd	qword ptr [ebx + 0x8], xmm4
  7bfe73: c7 03 38 fa 37 01            	mov	dword ptr [ebx], 0x137fa38
  7bfe79: 89 53 18                     	mov	dword ptr [ebx + 0x18], edx
  7bfe7c: 8b c3                        	mov	eax, ebx
  7bfe7e: 5b                           	pop	ebx
  7bfe7f: c2 2c 00                     	ret	0x2c
  7bfe82: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  7bfe89: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7bfe90: c7 01 24 fa 37 01            	mov	dword ptr [ecx], 0x137fa24
  7bfe96: e8 a5 1a 00 00               	call	0x7c1940 <.text+0x3c0940>
  7bfe9b: c3                           	ret
  7bfe9c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  7bfea0: 55                           	push	ebp
  7bfea1: 8b ec                        	mov	ebp, esp
  7bfea3: 83 e4 c0                     	and	esp, -0x40
  7bfea6: 56                           	push	esi
  7bfea7: 83 ec 7c                     	sub	esp, 0x7c
  7bfeaa: 8b f1                        	mov	esi, ecx
  7bfeac: 0f b6 46 20                  	movzx	eax, byte ptr [esi + 0x20]
  7bfeb0: 85 c0                        	test	eax, eax
  7bfeb2: 74 0a                        	je	0x7bfebe <.text+0x3beebe>
  7bfeb4: 83 c4 7c                     	add	esp, 0x7c
  7bfeb7: 5e                           	pop	esi
  7bfeb8: 8b e5                        	mov	esp, ebp
  7bfeba: 5d                           	pop	ebp
  7bfebb: c2 08 00                     	ret	0x8
  7bfebe: f2 0f 10 45 08               	movsd	xmm0, qword ptr [ebp + 0x8]
  7bfec3: 83 c4 f8                     	add	esp, -0x8
  7bfec6: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  7bfecb: 8b ce                        	mov	ecx, esi
  7bfecd: e8 be 1a 00 00               	call	0x7c1990 <.text+0x3c0990>
  7bfed2: dd 5c 24 18                  	fstp	qword ptr [esp + 0x18]
  7bfed6: f2 0f 10 44 24 18            	movsd	xmm0, qword ptr [esp + 0x18]
  7bfedc: 66 0f 2e 05 78 c0 cb 00      	ucomisd	xmm0, qword ptr [0xcbc078]
  7bfee4: 7a 06                        	jp	0x7bfeec <.text+0x3beeec>
  7bfee6: 0f 84 8d 00 00 00            	je	0x7bff79 <.text+0x3bef79>
  7bfeec: f2 0f 59 05 70 c0 cb 00      	mulsd	xmm0, qword ptr [0xcbc070]
  7bfef4: f2 0f 10 0d 68 c0 cb 00      	movsd	xmm1, qword ptr [0xcbc068]
  7bfefc: f2 0f 11 4c 24 38            	movsd	qword ptr [esp + 0x38], xmm1
  7bff02: e8 03 ef 2c 00               	call	0xa8ee0a <.text+0x68de0a>
  7bff07: f2 0f 10 4c 24 38            	movsd	xmm1, qword ptr [esp + 0x38]
  7bff0d: f2 0f 59 c1                  	mulsd	xmm0, xmm1
  7bff11: 8d 4c 24 18                  	lea	ecx, [esp + 0x18]
  7bff15: 89 4c 24 10                  	mov	dword ptr [esp + 0x10], ecx
  7bff19: f2 0f 5c c8                  	subsd	xmm1, xmm0
  7bff1d: f2 0f 11 0c 24               	movsd	qword ptr [esp], xmm1
  7bff22: 8d 46 28                     	lea	eax, [esi + 0x28]
  7bff25: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  7bff29: 8d 56 48                     	lea	edx, [esi + 0x48]
  7bff2c: 89 54 24 0c                  	mov	dword ptr [esp + 0xc], edx
  7bff30: e8 8b 1d 00 00               	call	0x7c1cc0 <.text+0x3c0cc0>
  7bff35: 8b 4e 1c                     	mov	ecx, dword ptr [esi + 0x1c]
  7bff38: 8b 01                        	mov	eax, dword ptr [ecx]
  7bff3a: 83 c4 e0                     	add	esp, -0x20
  7bff3d: f2 0f 10 44 24 38            	movsd	xmm0, qword ptr [esp + 0x38]
  7bff43: f2 0f 10 4c 24 40            	movsd	xmm1, qword ptr [esp + 0x40]
  7bff49: f2 0f 10 54 24 48            	movsd	xmm2, qword ptr [esp + 0x48]
  7bff4f: f2 0f 10 5c 24 50            	movsd	xmm3, qword ptr [esp + 0x50]
  7bff55: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  7bff5a: f2 0f 11 4c 24 08            	movsd	qword ptr [esp + 0x8], xmm1
  7bff60: f2 0f 11 54 24 10            	movsd	qword ptr [esp + 0x10], xmm2
  7bff66: f2 0f 11 5c 24 18            	movsd	qword ptr [esp + 0x18], xmm3
  7bff6c: ff 50 04                     	call	dword ptr [eax + 0x4]
  7bff6f: 83 c4 7c                     	add	esp, 0x7c
  7bff72: 5e                           	pop	esi
  7bff73: 8b e5                        	mov	esp, ebp
  7bff75: 5d                           	pop	ebp
  7bff76: c2 08 00                     	ret	0x8
  7bff79: 8b 4e 1c                     	mov	ecx, dword ptr [esi + 0x1c]
  7bff7c: 8b 01                        	mov	eax, dword ptr [ecx]
  7bff7e: f2 0f 10 46 48               	movsd	xmm0, qword ptr [esi + 0x48]
  7bff83: f2 0f 10 4e 50               	movsd	xmm1, qword ptr [esi + 0x50]
  7bff88: f2 0f 10 56 58               	movsd	xmm2, qword ptr [esi + 0x58]
  7bff8d: f2 0f 10 5e 60               	movsd	xmm3, qword ptr [esi + 0x60]
  7bff92: 83 c4 e0                     	add	esp, -0x20
  7bff95: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  7bff9a: f2 0f 11 4c 24 08            	movsd	qword ptr [esp + 0x8], xmm1
  7bffa0: f2 0f 11 54 24 10            	movsd	qword ptr [esp + 0x10], xmm2
  7bffa6: f2 0f 11 5c 24 18            	movsd	qword ptr [esp + 0x18], xmm3
  7bffac: ff 50 04                     	call	dword ptr [eax + 0x4]
  7bffaf: 83 c4 7c                     	add	esp, 0x7c
  7bffb2: 5e                           	pop	esi
  7bffb3: 8b e5                        	mov	esp, ebp
  7bffb5: 5d                           	pop	ebp
  7bffb6: c2 08 00                     	ret	0x8
  7bffb9: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  7bffc0: 55                           	push	ebp
  7bffc1: 8b ec                        	mov	ebp, esp
  7bffc3: 83 e4 c0                     	and	esp, -0x40
  7bffc6: 56                           	push	esi
  7bffc7: 83 ec 3c                     	sub	esp, 0x3c
  7bffca: 8b f1                        	mov	esi, ecx
  7bffcc: 8b 4e 1c                     	mov	ecx, dword ptr [esi + 0x1c]
  7bffcf: 85 c9                        	test	ecx, ecx
  7bffd1: 74 44                        	je	0x7c0017 <.text+0x3bf017>
  7bffd3: 8b 01                        	mov	eax, dword ptr [ecx]
  7bffd5: f2 0f 10 46 48               	movsd	xmm0, qword ptr [esi + 0x48]
  7bffda: f2 0f 10 4e 50               	movsd	xmm1, qword ptr [esi + 0x50]
  7bffdf: f2 0f 10 56 58               	movsd	xmm2, qword ptr [esi + 0x58]
  7bffe4: f2 0f 10 5e 60               	movsd	xmm3, qword ptr [esi + 0x60]
  7bffe9: 83 c4 e0                     	add	esp, -0x20
  7bffec: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  7bfff1: f2 0f 11 4c 24 08            	movsd	qword ptr [esp + 0x8], xmm1
  7bfff7: f2 0f 11 54 24 10            	movsd	qword ptr [esp + 0x10], xmm2
  7bfffd: f2 0f 11 5c 24 18            	movsd	qword ptr [esp + 0x18], xmm3
  7c0003: ff 50 04                     	call	dword ptr [eax + 0x4]
  7c0006: e8 f5 d7 ff ff               	call	0x7bd800 <.text+0x3bc800>
  7c000b: 6a 00                        	push	0x0
  7c000d: ff 76 1c                     	push	dword ptr [esi + 0x1c]
  7c0010: 8b c8                        	mov	ecx, eax
  7c0012: e8 59 e5 ff ff               	call	0x7be570 <.text+0x3bd570>
  7c0017: c6 46 20 01                  	mov	byte ptr [esi + 0x20], 0x1
  7c001b: 83 c4 3c                     	add	esp, 0x3c
  7c001e: 5e                           	pop	esi
  7c001f: 8b e5                        	mov	esp, ebp
  7c0021: 5d                           	pop	ebp
  7c0022: c3                           	ret
  7c0023: 8d b6 00 00 00 00            	lea	esi, [esi]
  7c0029: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7c0030: 55                           	push	ebp
  7c0031: 8b ec                        	mov	ebp, esp
  7c0033: 83 e4 f8                     	and	esp, -0x8
  7c0036: 53                           	push	ebx
  7c0037: 56                           	push	esi
  7c0038: 8b d9                        	mov	ebx, ecx
  7c003a: ff 75 08                     	push	dword ptr [ebp + 0x8]
  7c003d: e8 3e 1a 00 00               	call	0x7c1a80 <.text+0x3c0a80>
  7c0042: f2 0f 10 75 24               	movsd	xmm6, qword ptr [ebp + 0x24]
  7c0047: f2 0f 10 65 1c               	movsd	xmm4, qword ptr [ebp + 0x1c]
  7c004c: f2 0f 10 55 14               	movsd	xmm2, qword ptr [ebp + 0x14]
  7c0051: f2 0f 10 45 0c               	movsd	xmm0, qword ptr [ebp + 0xc]
  7c0056: f2 0f 10 4b 48               	movsd	xmm1, qword ptr [ebx + 0x48]
  7c005b: f2 0f 10 5b 50               	movsd	xmm3, qword ptr [ebx + 0x50]
  7c0060: f2 0f 10 6b 58               	movsd	xmm5, qword ptr [ebx + 0x58]
  7c0065: f2 0f 10 7b 60               	movsd	xmm7, qword ptr [ebx + 0x60]
  7c006a: f2 0f 11 43 28               	movsd	qword ptr [ebx + 0x28], xmm0
  7c006f: f2 0f 11 53 30               	movsd	qword ptr [ebx + 0x30], xmm2
  7c0074: f2 0f 11 63 38               	movsd	qword ptr [ebx + 0x38], xmm4
  7c0079: f2 0f 11 73 40               	movsd	qword ptr [ebx + 0x40], xmm6
  7c007e: f2 0f 5c c8                  	subsd	xmm1, xmm0
  7c0082: f2 0f 11 4b 68               	movsd	qword ptr [ebx + 0x68], xmm1
  7c0087: f2 0f 5c da                  	subsd	xmm3, xmm2
  7c008b: f2 0f 11 5b 70               	movsd	qword ptr [ebx + 0x70], xmm3
  7c0090: f2 0f 5c ec                  	subsd	xmm5, xmm4
  7c0094: f2 0f 11 6b 78               	movsd	qword ptr [ebx + 0x78], xmm5
  7c0099: f2 0f 5c fe                  	subsd	xmm7, xmm6
  7c009d: f2 0f 11 bb 80 00 00 00      	movsd	qword ptr [ebx + 0x80], xmm7
  7c00a5: 59                           	pop	ecx
  7c00a6: 5b                           	pop	ebx
  7c00a7: 8b e5                        	mov	esp, ebp
  7c00a9: 5d                           	pop	ebp
  7c00aa: c2 24 00                     	ret	0x24
  7c00ad: 8d 76 00                     	lea	esi, [esi]
  7c00b0: c2 24 00                     	ret	0x24
  7c00b3: 8d b6 00 00 00 00            	lea	esi, [esi]
  7c00b9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7c00c0: 56                           	push	esi
  7c00c1: 8b f1                        	mov	esi, ecx
  7c00c3: c7 06 24 fa 37 01            	mov	dword ptr [esi], 0x137fa24
  7c00c9: e8 72 18 00 00               	call	0x7c1940 <.text+0x3c0940>
  7c00ce: f6 44 24 08 01               	test	byte ptr [esp + 0x8], 0x1
  7c00d3: 75 06                        	jne	0x7c00db <.text+0x3bf0db>
  7c00d5: 8b c6                        	mov	eax, esi
  7c00d7: 5e                           	pop	esi
  7c00d8: c2 04 00                     	ret	0x4
  7c00db: 56                           	push	esi
  7c00dc: e8 b1 ee 2c 00               	call	0xa8ef92 <.text+0x68df92>
  7c00e1: 59                           	pop	ecx
  7c00e2: eb f1                        	jmp	0x7c00d5 <.text+0x3bf0d5>
  7c00e4: 8d b6 00 00 00 00            	lea	esi, [esi]
  7c00ea: 8d bf 00 00 00 00            	lea	edi, [edi]
  7c00f0: 53                           	push	ebx
  7c00f1: 8b d9                        	mov	ebx, ecx
  7c00f3: e8 18 18 00 00               	call	0x7c1910 <.text+0x3c0910>
  7c00f8: 8b 54 24 30                  	mov	edx, dword ptr [esp + 0x30]
  7c00fc: f2 0f 10 64 24 28            	movsd	xmm4, qword ptr [esp + 0x28]
  7c0102: f2 0f 10 5c 24 20            	movsd	xmm3, qword ptr [esp + 0x20]
  7c0108: f2 0f 10 54 24 18            	movsd	xmm2, qword ptr [esp + 0x18]
  7c010e: f2 0f 10 4c 24 10            	movsd	xmm1, qword ptr [esp + 0x10]
  7c0114: f2 0f 10 44 24 08            	movsd	xmm0, qword ptr [esp + 0x8]
  7c011a: f2 0f 11 43 48               	movsd	qword ptr [ebx + 0x48], xmm0
  7c011f: f2 0f 11 4b 50               	movsd	qword ptr [ebx + 0x50], xmm1
  7c0124: f2 0f 11 53 58               	movsd	qword ptr [ebx + 0x58], xmm2
  7c0129: f2 0f 11 5b 60               	movsd	qword ptr [ebx + 0x60], xmm3
  7c012e: f2 0f 11 63 08               	movsd	qword ptr [ebx + 0x8], xmm4
  7c0133: c7 03 4c fa 37 01            	mov	dword ptr [ebx], 0x137fa4c
  7c0139: 89 53 18                     	mov	dword ptr [ebx + 0x18], edx
  7c013c: 8b c3                        	mov	eax, ebx
  7c013e: 5b                           	pop	ebx
  7c013f: c2 2c 00                     	ret	0x2c
  7c0142: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  7c0149: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7c0150: c7 01 24 fa 37 01            	mov	dword ptr [ecx], 0x137fa24
  7c0156: e8 e5 17 00 00               	call	0x7c1940 <.text+0x3c0940>
  7c015b: c3                           	ret
  7c015c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  7c0160: 55                           	push	ebp
  7c0161: 8b ec                        	mov	ebp, esp
  7c0163: 83 e4 c0                     	and	esp, -0x40
  7c0166: 56                           	push	esi
  7c0167: 83 ec 3c                     	sub	esp, 0x3c
  7c016a: 8b f1                        	mov	esi, ecx
  7c016c: 0f b6 46 20                  	movzx	eax, byte ptr [esi + 0x20]
  7c0170: 85 c0                        	test	eax, eax
  7c0172: 74 0a                        	je	0x7c017e <.text+0x3bf17e>
  7c0174: 83 c4 3c                     	add	esp, 0x3c
  7c0177: 5e                           	pop	esi
  7c0178: 8b e5                        	mov	esp, ebp
  7c017a: 5d                           	pop	ebp
  7c017b: c2 08 00                     	ret	0x8
  7c017e: f2 0f 10 45 08               	movsd	xmm0, qword ptr [ebp + 0x8]
  7c0183: 83 c4 f8                     	add	esp, -0x8
  7c0186: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  7c018b: 8b ce                        	mov	ecx, esi
  7c018d: e8 fe 17 00 00               	call	0x7c1990 <.text+0x3c0990>
  7c0192: dd 5c 24 18                  	fstp	qword ptr [esp + 0x18]
  7c0196: f2 0f 10 44 24 18            	movsd	xmm0, qword ptr [esp + 0x18]
  7c019c: 66 0f 2e 05 80 c0 cb 00      	ucomisd	xmm0, qword ptr [0xcbc080]
  7c01a4: 7a 02                        	jp	0x7c01a8 <.text+0x3bf1a8>
  7c01a6: 74 64                        	je	0x7c020c <.text+0x3bf20c>
  7c01a8: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  7c01ad: 8d 4c 24 18                  	lea	ecx, [esp + 0x18]
  7c01b1: 89 4c 24 10                  	mov	dword ptr [esp + 0x10], ecx
  7c01b5: 8d 46 28                     	lea	eax, [esi + 0x28]
  7c01b8: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  7c01bc: 8d 56 48                     	lea	edx, [esi + 0x48]
  7c01bf: 89 54 24 0c                  	mov	dword ptr [esp + 0xc], edx
  7c01c3: e8 f8 1a 00 00               	call	0x7c1cc0 <.text+0x3c0cc0>
  7c01c8: 8b 4e 1c                     	mov	ecx, dword ptr [esi + 0x1c]
  7c01cb: 8b 01                        	mov	eax, dword ptr [ecx]
  7c01cd: 83 c4 e0                     	add	esp, -0x20
  7c01d0: f2 0f 10 44 24 38            	movsd	xmm0, qword ptr [esp + 0x38]
  7c01d6: f2 0f 10 4c 24 40            	movsd	xmm1, qword ptr [esp + 0x40]
  7c01dc: f2 0f 10 54 24 48            	movsd	xmm2, qword ptr [esp + 0x48]
  7c01e2: f2 0f 10 5c 24 50            	movsd	xmm3, qword ptr [esp + 0x50]
  7c01e8: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  7c01ed: f2 0f 11 4c 24 08            	movsd	qword ptr [esp + 0x8], xmm1
  7c01f3: f2 0f 11 54 24 10            	movsd	qword ptr [esp + 0x10], xmm2
  7c01f9: f2 0f 11 5c 24 18            	movsd	qword ptr [esp + 0x18], xmm3
  7c01ff: ff 50 04                     	call	dword ptr [eax + 0x4]
  7c0202: 83 c4 3c                     	add	esp, 0x3c
  7c0205: 5e                           	pop	esi
  7c0206: 8b e5                        	mov	esp, ebp
  7c0208: 5d                           	pop	ebp
  7c0209: c2 08 00                     	ret	0x8
  7c020c: 8b 4e 1c                     	mov	ecx, dword ptr [esi + 0x1c]
  7c020f: 8b 01                        	mov	eax, dword ptr [ecx]
  7c0211: f2 0f 10 46 48               	movsd	xmm0, qword ptr [esi + 0x48]
  7c0216: f2 0f 10 4e 50               	movsd	xmm1, qword ptr [esi + 0x50]
  7c021b: f2 0f 10 56 58               	movsd	xmm2, qword ptr [esi + 0x58]
  7c0220: f2 0f 10 5e 60               	movsd	xmm3, qword ptr [esi + 0x60]
  7c0225: 83 c4 e0                     	add	esp, -0x20
  7c0228: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  7c022d: f2 0f 11 4c 24 08            	movsd	qword ptr [esp + 0x8], xmm1
  7c0233: f2 0f 11 54 24 10            	movsd	qword ptr [esp + 0x10], xmm2
  7c0239: f2 0f 11 5c 24 18            	movsd	qword ptr [esp + 0x18], xmm3
  7c023f: ff 50 04                     	call	dword ptr [eax + 0x4]
  7c0242: 83 c4 3c                     	add	esp, 0x3c
  7c0245: 5e                           	pop	esi
  7c0246: 8b e5                        	mov	esp, ebp
  7c0248: 5d                           	pop	ebp
  7c0249: c2 08 00                     	ret	0x8
  7c024c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  7c0250: 55                           	push	ebp
  7c0251: 8b ec                        	mov	ebp, esp
  7c0253: 83 e4 c0                     	and	esp, -0x40
  7c0256: 56                           	push	esi
  7c0257: 83 ec 3c                     	sub	esp, 0x3c
  7c025a: 8b f1                        	mov	esi, ecx
  7c025c: 8b 4e 1c                     	mov	ecx, dword ptr [esi + 0x1c]
  7c025f: 85 c9                        	test	ecx, ecx
  7c0261: 74 44                        	je	0x7c02a7 <.text+0x3bf2a7>
  7c0263: 8b 01                        	mov	eax, dword ptr [ecx]
  7c0265: f2 0f 10 46 48               	movsd	xmm0, qword ptr [esi + 0x48]
  7c026a: f2 0f 10 4e 50               	movsd	xmm1, qword ptr [esi + 0x50]
  7c026f: f2 0f 10 56 58               	movsd	xmm2, qword ptr [esi + 0x58]
  7c0274: f2 0f 10 5e 60               	movsd	xmm3, qword ptr [esi + 0x60]
  7c0279: 83 c4 e0                     	add	esp, -0x20
  7c027c: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  7c0281: f2 0f 11 4c 24 08            	movsd	qword ptr [esp + 0x8], xmm1
  7c0287: f2 0f 11 54 24 10            	movsd	qword ptr [esp + 0x10], xmm2
  7c028d: f2 0f 11 5c 24 18            	movsd	qword ptr [esp + 0x18], xmm3
  7c0293: ff 50 04                     	call	dword ptr [eax + 0x4]
  7c0296: e8 65 d5 ff ff               	call	0x7bd800 <.text+0x3bc800>
  7c029b: 6a 00                        	push	0x0
  7c029d: ff 76 1c                     	push	dword ptr [esi + 0x1c]
  7c02a0: 8b c8                        	mov	ecx, eax
  7c02a2: e8 c9 e2 ff ff               	call	0x7be570 <.text+0x3bd570>
  7c02a7: c6 46 20 01                  	mov	byte ptr [esi + 0x20], 0x1
  7c02ab: 83 c4 3c                     	add	esp, 0x3c
  7c02ae: 5e                           	pop	esi
  7c02af: 8b e5                        	mov	esp, ebp
  7c02b1: 5d                           	pop	ebp
  7c02b2: c3                           	ret
  7c02b3: 8d b6 00 00 00 00            	lea	esi, [esi]
  7c02b9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  7c02c0: 55                           	push	ebp
  7c02c1: 8b ec                        	mov	ebp, esp
  7c02c3: 83 e4 f8                     	and	esp, -0x8
  7c02c6: 53                           	push	ebx
  7c02c7: 56                           	push	esi
  7c02c8: 8b d9                        	mov	ebx, ecx
  7c02ca: ff 75 08                     	push	dword ptr [ebp + 0x8]
  7c02cd: e8 ae 17 00 00               	call	0x7c1a80 <.text+0x3c0a80>
  7c02d2: f2 0f 10 75 24               	movsd	xmm6, qword ptr [ebp + 0x24]
  7c02d7: f2 0f 10 65 1c               	movsd	xmm4, qword ptr [ebp + 0x1c]
  7c02dc: f2 0f 10 55 14               	movsd	xmm2, qword ptr [ebp + 0x14]
  7c02e1: f2 0f 10 45 0c               	movsd	xmm0, qword ptr [ebp + 0xc]
  7c02e6: f2 0f 10 4b 48               	movsd	xmm1, qword ptr [ebx + 0x48]
  7c02eb: f2 0f 10 5b 50               	movsd	xmm3, qword ptr [ebx + 0x50]
  7c02f0: f2 0f 10 6b 58               	movsd	xmm5, qword ptr [ebx + 0x58]
  7c02f5: f2 0f 10 7b 60               	movsd	xmm7, qword ptr [ebx + 0x60]
  7c02fa: f2 0f 11 43 28               	movsd	qword ptr [ebx + 0x28], xmm0
  7c02ff: f2 0f 11 53 30               	movsd	qword ptr [ebx + 0x30], xmm2
