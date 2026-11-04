
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  667e00: 56                           	push	esi
  667e01: 55                           	push	ebp
  667e02: 83 ec 18                     	sub	esp, 0x18
  667e05: 8b 74 24 24                  	mov	esi, dword ptr [esp + 0x24]
  667e09: 6a 00                        	push	0x0
  667e0b: 6a 01                        	push	0x1
  667e0d: 56                           	push	esi
  667e0e: e8 5d 76 22 00               	call	0x88f470 <.text+0x48e470>
  667e13: 83 c4 0c                     	add	esp, 0xc
  667e16: 8b e8                        	mov	ebp, eax
  667e18: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  667e20: 89 34 24                     	mov	dword ptr [esp], esi
  667e23: 66 0f ef c0                  	pxor	xmm0, xmm0
  667e27: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  667e2d: e8 be 75 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  667e32: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  667e36: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  667e3c: 8b cd                        	mov	ecx, ebp
  667e3e: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  667e42: 50                           	push	eax
  667e43: e8 c8 40 f8 ff               	call	0x5ebf10 <.text+0x1eaf10>
  667e48: 33 c0                        	xor	eax, eax
  667e4a: 83 c4 18                     	add	esp, 0x18
  667e4d: 5d                           	pop	ebp
  667e4e: 5e                           	pop	esi
  667e4f: c3                           	ret
  667e50: 53                           	push	ebx
  667e51: 83 ec 0c                     	sub	esp, 0xc
  667e54: 8b 5c 24 14                  	mov	ebx, dword ptr [esp + 0x14]
  667e58: 6a 00                        	push	0x0
  667e5a: 6a 01                        	push	0x1
  667e5c: 53                           	push	ebx
  667e5d: e8 0e 76 22 00               	call	0x88f470 <.text+0x48e470>
  667e62: 83 c4 0c                     	add	esp, 0xc
  667e65: 8b c8                        	mov	ecx, eax
  667e67: e8 74 41 f8 ff               	call	0x5ebfe0 <.text+0x1eafe0>
  667e6c: f2 0f 2a c0                  	cvtsi2sd	xmm0, eax
  667e70: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  667e76: 89 1c 24                     	mov	dword ptr [esp], ebx
  667e79: e8 a2 79 22 00               	call	0x88f820 <.text+0x48e820>
  667e7e: b8 01 00 00 00               	mov	eax, 0x1
  667e83: 83 c4 0c                     	add	esp, 0xc
  667e86: 5b                           	pop	ebx
  667e87: c3                           	ret
  667e88: 90                           	nop
  667e89: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  667e90: 57                           	push	edi
  667e91: 56                           	push	esi
  667e92: 83 ec 10                     	sub	esp, 0x10
  667e95: 8b 74 24 1c                  	mov	esi, dword ptr [esp + 0x1c]
  667e99: 6a 00                        	push	0x0
  667e9b: 6a 01                        	push	0x1
  667e9d: 56                           	push	esi
  667e9e: e8 cd 75 22 00               	call	0x88f470 <.text+0x48e470>
  667ea3: 83 c4 0c                     	add	esp, 0xc
  667ea6: 8b f8                        	mov	edi, eax
  667ea8: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  667eb0: 89 34 24                     	mov	dword ptr [esp], esi
  667eb3: 66 0f ef c0                  	pxor	xmm0, xmm0
  667eb7: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  667ebd: e8 2e 75 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  667ec2: 83 c4 f8                     	add	esp, -0x8
  667ec5: dd 1c 24                     	fstp	qword ptr [esp]
  667ec8: 8b cf                        	mov	ecx, edi
  667eca: e8 71 41 f8 ff               	call	0x5ec040 <.text+0x1eb040>
  667ecf: 33 c0                        	xor	eax, eax
  667ed1: 83 c4 10                     	add	esp, 0x10
  667ed4: 5e                           	pop	esi
  667ed5: 5f                           	pop	edi
  667ed6: c3                           	ret
  667ed7: 8b f6                        	mov	esi, esi
  667ed9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  667ee0: 53                           	push	ebx
  667ee1: 83 ec 0c                     	sub	esp, 0xc
  667ee4: 8b 5c 24 14                  	mov	ebx, dword ptr [esp + 0x14]
  667ee8: 6a 00                        	push	0x0
  667eea: 6a 01                        	push	0x1
  667eec: 53                           	push	ebx
  667eed: e8 7e 75 22 00               	call	0x88f470 <.text+0x48e470>
  667ef2: 83 c4 0c                     	add	esp, 0xc
  667ef5: 8b c8                        	mov	ecx, eax
  667ef7: e8 14 42 f8 ff               	call	0x5ec110 <.text+0x1eb110>
  667efc: dd 5c 24 04                  	fstp	qword ptr [esp + 0x4]
  667f00: 89 1c 24                     	mov	dword ptr [esp], ebx
  667f03: e8 18 79 22 00               	call	0x88f820 <.text+0x48e820>
  667f08: b8 01 00 00 00               	mov	eax, 0x1
  667f0d: 83 c4 0c                     	add	esp, 0xc
  667f10: 5b                           	pop	ebx
  667f11: c3                           	ret
  667f12: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  667f19: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  667f20: 55                           	push	ebp
  667f21: 8b ec                        	mov	ebp, esp
  667f23: 83 e4 c0                     	and	esp, -0x40
  667f26: 56                           	push	esi
  667f27: 53                           	push	ebx
  667f28: 83 ec 38                     	sub	esp, 0x38
  667f2b: 8b 75 08                     	mov	esi, dword ptr [ebp + 0x8]
  667f2e: 6a 00                        	push	0x0
  667f30: 6a 01                        	push	0x1
  667f32: 56                           	push	esi
  667f33: e8 38 75 22 00               	call	0x88f470 <.text+0x48e470>
  667f38: 83 c4 0c                     	add	esp, 0xc
  667f3b: 8b d8                        	mov	ebx, eax
  667f3d: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  667f45: 89 34 24                     	mov	dword ptr [esp], esi
  667f48: 66 0f ef c0                  	pxor	xmm0, xmm0
  667f4c: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  667f52: e8 99 74 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  667f57: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  667f5b: c7 44 24 04 03 00 00 00      	mov	dword ptr [esp + 0x4], 0x3
  667f63: 89 34 24                     	mov	dword ptr [esp], esi
  667f66: 66 0f ef c0                  	pxor	xmm0, xmm0
  667f6a: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  667f70: e8 7b 74 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  667f75: dd 5c 24 18                  	fstp	qword ptr [esp + 0x18]
  667f79: 6a 01                        	push	0x1
  667f7b: 6a 04                        	push	0x4
  667f7d: 56                           	push	esi
  667f7e: e8 7d 75 22 00               	call	0x88f500 <.text+0x48e500>
  667f83: 83 c4 0c                     	add	esp, 0xc
  667f86: 83 c4 ec                     	add	esp, -0x14
  667f89: dd 44 24 24                  	fld	qword ptr [esp + 0x24]
  667f8d: dd 44 24 2c                  	fld	qword ptr [esp + 0x2c]
  667f91: d9 c9                        	fxch	st(1)
  667f93: dd 1c 24                     	fstp	qword ptr [esp]
  667f96: dd 5c 24 08                  	fstp	qword ptr [esp + 0x8]
  667f9a: ba 01 00 00 00               	mov	edx, 0x1
  667f9f: 85 c0                        	test	eax, eax
  667fa1: 0f 45 c2                     	cmovne	eax, edx
  667fa4: 88 44 24 10                  	mov	byte ptr [esp + 0x10], al
  667fa8: 8b cb                        	mov	ecx, ebx
  667faa: e8 71 41 f8 ff               	call	0x5ec120 <.text+0x1eb120>
  667faf: 33 c0                        	xor	eax, eax
  667fb1: 83 c4 38                     	add	esp, 0x38
  667fb4: 5b                           	pop	ebx
  667fb5: 5e                           	pop	esi
  667fb6: 8b e5                        	mov	esp, ebp
  667fb8: 5d                           	pop	ebp
  667fb9: c3                           	ret
  667fba: 8d b6 00 00 00 00            	lea	esi, [esi]
  667fc0: 55                           	push	ebp
  667fc1: 8b ec                        	mov	ebp, esp
  667fc3: 83 e4 c0                     	and	esp, -0x40
  667fc6: 57                           	push	edi
  667fc7: 56                           	push	esi
  667fc8: 83 ec 38                     	sub	esp, 0x38
  667fcb: 8b 75 08                     	mov	esi, dword ptr [ebp + 0x8]
  667fce: 8d 7c 24 10                  	lea	edi, [esp + 0x10]
  667fd2: 57                           	push	edi
  667fd3: 6a 00                        	push	0x0
  667fd5: 68 78 a5 ca 00               	push	0xcaa578
  667fda: 6a 01                        	push	0x1
  667fdc: 56                           	push	esi
  667fdd: e8 be 93 22 00               	call	0x8913a0 <.text+0x4903a0>
  667fe2: 83 c4 14                     	add	esp, 0x14
  667fe5: 85 c0                        	test	eax, eax
  667fe7: 74 2b                        	je	0x668014 <.text+0x267014>
  667fe9: 57                           	push	edi
  667fea: 6a 00                        	push	0x0
  667fec: 68 b8 a0 c3 00               	push	0xc3a0b8
  667ff1: 6a 02                        	push	0x2
  667ff3: 56                           	push	esi
  667ff4: e8 a7 93 22 00               	call	0x8913a0 <.text+0x4903a0>
  667ff9: 83 c4 14                     	add	esp, 0x14
  667ffc: 85 c0                        	test	eax, eax
  667ffe: 74 14                        	je	0x668014 <.text+0x267014>
  668000: 57                           	push	edi
  668001: 6a 03                        	push	0x3
  668003: 56                           	push	esi
  668004: e8 97 90 22 00               	call	0x8910a0 <.text+0x4900a0>
  668009: 83 c4 0c                     	add	esp, 0xc
  66800c: 85 c0                        	test	eax, eax
  66800e: 0f 85 8c 00 00 00            	jne	0x6680a0 <.text+0x2670a0>
  668014: 6a 00                        	push	0x0
  668016: 6a 01                        	push	0x1
  668018: 56                           	push	esi
  668019: e8 52 74 22 00               	call	0x88f470 <.text+0x48e470>
  66801e: 83 c4 0c                     	add	esp, 0xc
  668021: 8b f8                        	mov	edi, eax
  668023: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  66802b: 89 34 24                     	mov	dword ptr [esp], esi
  66802e: 66 0f ef c0                  	pxor	xmm0, xmm0
  668032: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  668038: e8 b3 73 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  66803d: dd 5c 24 28                  	fstp	qword ptr [esp + 0x28]
  668041: c7 44 24 04 03 00 00 00      	mov	dword ptr [esp + 0x4], 0x3
  668049: 89 34 24                     	mov	dword ptr [esp], esi
  66804c: 66 0f ef c0                  	pxor	xmm0, xmm0
  668050: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  668056: e8 95 73 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  66805b: dd 5c 24 20                  	fstp	qword ptr [esp + 0x20]
  66805f: 6a 01                        	push	0x1
  668061: 6a 04                        	push	0x4
  668063: 56                           	push	esi
  668064: e8 97 74 22 00               	call	0x88f500 <.text+0x48e500>
  668069: 83 c4 0c                     	add	esp, 0xc
  66806c: 83 c4 ec                     	add	esp, -0x14
  66806f: dd 44 24 3c                  	fld	qword ptr [esp + 0x3c]
  668073: dd 44 24 34                  	fld	qword ptr [esp + 0x34]
  668077: d9 c9                        	fxch	st(1)
  668079: dd 1c 24                     	fstp	qword ptr [esp]
  66807c: dd 5c 24 08                  	fstp	qword ptr [esp + 0x8]
  668080: ba 01 00 00 00               	mov	edx, 0x1
  668085: 85 c0                        	test	eax, eax
  668087: 0f 45 c2                     	cmovne	eax, edx
  66808a: 88 44 24 10                  	mov	byte ptr [esp + 0x10], al
  66808e: 8b cf                        	mov	ecx, edi
  668090: e8 8b 40 f8 ff               	call	0x5ec120 <.text+0x1eb120>
  668095: 33 c0                        	xor	eax, eax
  668097: 83 c4 38                     	add	esp, 0x38
  66809a: 5e                           	pop	esi
  66809b: 5f                           	pop	edi
  66809c: 8b e5                        	mov	esp, ebp
  66809e: 5d                           	pop	ebp
  66809f: c3                           	ret
  6680a0: 6a 00                        	push	0x0
  6680a2: 6a 01                        	push	0x1
  6680a4: 56                           	push	esi
  6680a5: e8 c6 73 22 00               	call	0x88f470 <.text+0x48e470>
  6680aa: 8b f8                        	mov	edi, eax
  6680ac: 6a 00                        	push	0x0
  6680ae: 6a 02                        	push	0x2
  6680b0: 56                           	push	esi
  6680b1: e8 ba 73 22 00               	call	0x88f470 <.text+0x48e470>
  6680b6: 83 c4 18                     	add	esp, 0x18
  6680b9: 50                           	push	eax
  6680ba: 8b cf                        	mov	ecx, edi
  6680bc: e8 3f 42 f8 ff               	call	0x5ec300 <.text+0x1eb300>
  6680c1: 33 c0                        	xor	eax, eax
  6680c3: 83 c4 38                     	add	esp, 0x38
  6680c6: 5e                           	pop	esi
  6680c7: 5f                           	pop	edi
  6680c8: 8b e5                        	mov	esp, ebp
  6680ca: 5d                           	pop	ebp
  6680cb: c3                           	ret
  6680cc: 8d 74 26 00                  	lea	esi, [esi + eiz]
  6680d0: 56                           	push	esi
  6680d1: 55                           	push	ebp
  6680d2: 83 ec 18                     	sub	esp, 0x18
  6680d5: 8b 74 24 24                  	mov	esi, dword ptr [esp + 0x24]
  6680d9: 6a 00                        	push	0x0
  6680db: 6a 01                        	push	0x1
  6680dd: 56                           	push	esi
  6680de: e8 8d 73 22 00               	call	0x88f470 <.text+0x48e470>
  6680e3: 83 c4 0c                     	add	esp, 0xc
  6680e6: 8b e8                        	mov	ebp, eax
  6680e8: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  6680f0: 89 34 24                     	mov	dword ptr [esp], esi
  6680f3: 66 0f ef c0                  	pxor	xmm0, xmm0
  6680f7: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6680fd: e8 ee 72 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  668102: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  668106: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  66810c: 8b cd                        	mov	ecx, ebp
  66810e: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  668112: 50                           	push	eax
  668113: e8 98 42 f8 ff               	call	0x5ec3b0 <.text+0x1eb3b0>
  668118: 33 c0                        	xor	eax, eax
  66811a: 83 c4 18                     	add	esp, 0x18
  66811d: 5d                           	pop	ebp
  66811e: 5e                           	pop	esi
  66811f: c3                           	ret
  668120: 53                           	push	ebx
  668121: 83 ec 0c                     	sub	esp, 0xc
  668124: 8b 5c 24 14                  	mov	ebx, dword ptr [esp + 0x14]
  668128: 6a 00                        	push	0x0
  66812a: 6a 01                        	push	0x1
  66812c: 53                           	push	ebx
  66812d: e8 3e 73 22 00               	call	0x88f470 <.text+0x48e470>
  668132: 83 c4 0c                     	add	esp, 0xc
  668135: 8b c8                        	mov	ecx, eax
  668137: e8 84 42 f8 ff               	call	0x5ec3c0 <.text+0x1eb3c0>
  66813c: f2 0f 2a c0                  	cvtsi2sd	xmm0, eax
  668140: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  668146: 89 1c 24                     	mov	dword ptr [esp], ebx
  668149: e8 d2 76 22 00               	call	0x88f820 <.text+0x48e820>
  66814e: b8 01 00 00 00               	mov	eax, 0x1
  668153: 83 c4 0c                     	add	esp, 0xc
  668156: 5b                           	pop	ebx
  668157: c3                           	ret
  668158: 90                           	nop
  668159: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  668160: 6a 00                        	push	0x0
  668162: 6a 01                        	push	0x1
  668164: ff 74 24 0c                  	push	dword ptr [esp + 0xc]
  668168: e8 03 73 22 00               	call	0x88f470 <.text+0x48e470>
  66816d: 83 c4 0c                     	add	esp, 0xc
  668170: 8b c8                        	mov	ecx, eax
  668172: e8 59 42 f8 ff               	call	0x5ec3d0 <.text+0x1eb3d0>
  668177: 33 c0                        	xor	eax, eax
  668179: c3                           	ret
  66817a: 8d b6 00 00 00 00            	lea	esi, [esi]
  668180: 6a 00                        	push	0x0
  668182: 6a 01                        	push	0x1
  668184: ff 74 24 0c                  	push	dword ptr [esp + 0xc]
  668188: e8 e3 72 22 00               	call	0x88f470 <.text+0x48e470>
  66818d: 83 c4 0c                     	add	esp, 0xc
  668190: 8b c8                        	mov	ecx, eax
  668192: e8 59 42 f8 ff               	call	0x5ec3f0 <.text+0x1eb3f0>
  668197: 33 c0                        	xor	eax, eax
  668199: c3                           	ret
  66819a: 8d b6 00 00 00 00            	lea	esi, [esi]
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
