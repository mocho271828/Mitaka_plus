
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  549970: 83 ec 18                     	sub	esp, 0x18
  549973: f6 05 28 1e d7 00 03         	test	byte ptr [0xd71e28], 0x3
  54997a: 75 04                        	jne	0x549980 <.text+0x148980>
  54997c: 83 c4 18                     	add	esp, 0x18
  54997f: c3                           	ret
  549980: 68 48 30 c3 00               	push	0xc33048
  549985: b9 60 74 10 01               	mov	ecx, 0x1107460
  54998a: e8 51 1d 01 00               	call	0x55b6e0 <.text+0x15a6e0>
  54998f: 89 04 24                     	mov	dword ptr [esp], eax
  549992: 68 4c 30 c3 00               	push	0xc3304c
  549997: b9 60 74 10 01               	mov	ecx, 0x1107460
  54999c: e8 3f 1d 01 00               	call	0x55b6e0 <.text+0x15a6e0>
  5499a1: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  5499a5: 68 54 30 c3 00               	push	0xc33054
  5499aa: b9 60 74 10 01               	mov	ecx, 0x1107460
  5499af: e8 2c 1d 01 00               	call	0x55b6e0 <.text+0x15a6e0>
  5499b4: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  5499b8: 68 60 30 c3 00               	push	0xc33060
  5499bd: b9 60 74 10 01               	mov	ecx, 0x1107460
  5499c2: e8 19 1d 01 00               	call	0x55b6e0 <.text+0x15a6e0>
  5499c7: 89 44 24 0c                  	mov	dword ptr [esp + 0xc], eax
  5499cb: 89 74 24 14                  	mov	dword ptr [esp + 0x14], esi
  5499cf: 89 7c 24 10                  	mov	dword ptr [esp + 0x10], edi
  5499d3: 33 c0                        	xor	eax, eax
  5499d5: 8b f0                        	mov	esi, eax
  5499d7: 8b 3c b4                     	mov	edi, dword ptr [esp + 4*esi]
  5499da: 68 68 30 c3 00               	push	0xc33068
  5499df: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  5499e4: e8 37 41 ff ff               	call	0x53db20 <.text+0x13cb20>
  5499e9: 57                           	push	edi
  5499ea: 50                           	push	eax
  5499eb: ff 74 24 24                  	push	dword ptr [esp + 0x24]
  5499ef: e8 cc 91 ff ff               	call	0x542bc0 <.text+0x141bc0>
  5499f4: 83 c4 0c                     	add	esp, 0xc
  5499f7: 46                           	inc	esi
  5499f8: 83 fe 04                     	cmp	esi, 0x4
  5499fb: 7c da                        	jl	0x5499d7 <.text+0x1489d7>
  5499fd: 8b 74 24 14                  	mov	esi, dword ptr [esp + 0x14]
  549a01: 8b 7c 24 10                  	mov	edi, dword ptr [esp + 0x10]
  549a05: 83 c4 18                     	add	esp, 0x18
  549a08: c3                           	ret
  549a09: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  549a10: 55                           	push	ebp
  549a11: 8b ec                        	mov	ebp, esp
  549a13: 6a ff                        	push	-0x1
  549a15: 68 f0 9d 54 00               	push	0x549df0
  549a1a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  549a20: 50                           	push	eax
  549a21: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  549a28: 83 ec 48                     	sub	esp, 0x48
  549a2b: 89 5d e8                     	mov	dword ptr [ebp - 0x18], ebx
  549a2e: 89 7d e0                     	mov	dword ptr [ebp - 0x20], edi
  549a31: 89 75 e4                     	mov	dword ptr [ebp - 0x1c], esi
  549a34: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  549a39: 8b 55 08                     	mov	edx, dword ptr [ebp + 0x8]
  549a3c: a1 10 53 d8 00               	mov	eax, dword ptr [0xd85310]
  549a41: 89 45 ec                     	mov	dword ptr [ebp - 0x14], eax
  549a44: 52                           	push	edx
  549a45: e8 06 4c ff ff               	call	0x53e650 <.text+0x13d650>
  549a4a: 8b f8                        	mov	edi, eax
  549a4c: 85 ff                        	test	edi, edi
  549a4e: 0f 84 81 03 00 00            	je	0x549dd5 <.text+0x148dd5>
  549a54: 8b cf                        	mov	ecx, edi
  549a56: e8 15 2f ff ff               	call	0x53c970 <.text+0x13b970>
  549a5b: 50                           	push	eax
  549a5c: 68 e1 0d 00 00               	push	0xde1
  549a61: ff 15 f8 58 c2 00            	call	dword ptr [0xc258f8]
  549a67: be 00 00 80 3f               	mov	esi, 0x3f800000
  549a6c: 33 db                        	xor	ebx, ebx
  549a6e: 83 c4 f0                     	add	esp, -0x10
  549a71: 89 5c 24 04                  	mov	dword ptr [esp + 0x4], ebx
  549a75: c7 04 24 00 00 34 43         	mov	dword ptr [esp], 0x43340000
  549a7c: 89 5c 24 08                  	mov	dword ptr [esp + 0x8], ebx
  549a80: c7 44 24 0c 00 00 80 3f      	mov	dword ptr [esp + 0xc], 0x3f800000
  549a88: ff 15 60 59 c2 00            	call	dword ptr [0xc25960]
  549a8e: 8b cf                        	mov	ecx, edi
  549a90: e8 fb 2c ff ff               	call	0x53c790 <.text+0x13b790>
  549a95: dd 5d d8                     	fstp	qword ptr [ebp - 0x28]
  549a98: f2 0f 10 4d d8               	movsd	xmm1, qword ptr [ebp - 0x28]
  549a9d: f2 0f 10 05 90 2a c3 00      	movsd	xmm0, qword ptr [0xc32a90]
  549aa5: f2 0f 11 45 d0               	movsd	qword ptr [ebp - 0x30], xmm0
  549aaa: 68 e2 0b 00 00               	push	0xbe2
  549aaf: f2 0f 58 c8                  	addsd	xmm1, xmm0
  549ab3: f2 0f 5e c1                  	divsd	xmm0, xmm1
  549ab7: f2 0f 11 45 ac               	movsd	qword ptr [ebp - 0x54], xmm0
  549abc: ff 15 18 59 c2 00            	call	dword ptr [0xc25918]
  549ac2: 68 e1 0d 00 00               	push	0xde1
  549ac7: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  549acd: 68 71 0b 00 00               	push	0xb71
  549ad2: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  549ad8: 68 a1 0b 00 00               	push	0xba1
  549add: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  549ae3: 0f b6 05 cc 9b 10 01         	movzx	eax, byte ptr [0x1109bcc]
  549aea: 85 c0                        	test	eax, eax
  549aec: 74 09                        	je	0x549af7 <.text+0x148af7>
  549aee: 83 3d c0 9b 10 01 00         	cmp	dword ptr [0x1109bc0], 0x0
  549af5: 74 0b                        	je	0x549b02 <.text+0x148b02>
  549af7: 68 50 0b 00 00               	push	0xb50
  549afc: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  549b02: 68 e2 0b 00 00               	push	0xbe2
  549b07: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  549b0d: ff 15 04 59 c2 00            	call	dword ptr [0xc25904]
  549b13: f2 0f 5a 45 ac               	cvtsd2ss	xmm0, qword ptr [ebp - 0x54]
  549b18: 83 c4 f4                     	add	esp, -0xc
  549b1b: f3 0f 11 44 24 08            	movss	dword ptr [esp + 0x8], xmm0
  549b21: 89 34 24                     	mov	dword ptr [esp], esi
  549b24: 89 74 24 04                  	mov	dword ptr [esp + 0x4], esi
  549b28: ff 15 50 59 c2 00            	call	dword ptr [0xc25950]
  549b2e: 68 44 0b 00 00               	push	0xb44
  549b33: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  549b39: 53                           	push	ebx
  549b3a: 53                           	push	ebx
  549b3b: e8 f0 33 ef ff               	call	0x43cf30 <.text+0x3bf30>
  549b40: 83 c4 08                     	add	esp, 0x8
  549b43: ff 15 08 59 c2 00            	call	dword ptr [0xc25908]
  549b49: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  549b50: c7 45 c8 00 00 00 00         	mov	dword ptr [ebp - 0x38], 0x0
  549b57: e8 74 0b 08 00               	call	0x5ca6d0 <.text+0x1c96d0>
  549b5c: 8b c8                        	mov	ecx, eax
  549b5e: e8 4d 17 08 00               	call	0x5cb2b0 <.text+0x1ca2b0>
  549b63: 0f b6 c0                     	movzx	eax, al
  549b66: 85 c0                        	test	eax, eax
  549b68: 0f 85 29 02 00 00            	jne	0x549d97 <.text+0x148d97>
  549b6e: 8b c3                        	mov	eax, ebx
  549b70: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  549b77: 83 7d c8 00                  	cmp	dword ptr [ebp - 0x38], 0x0
  549b7b: 0f 85 e4 01 00 00            	jne	0x549d65 <.text+0x148d65>
  549b81: 85 c0                        	test	eax, eax
  549b83: 0f 84 2f 01 00 00            	je	0x549cb8 <.text+0x148cb8>
  549b89: ff 35 78 73 10 01            	push	dword ptr [0x1107378]
  549b8f: 68 e1 0d 00 00               	push	0xde1
  549b94: ff 15 f8 58 c2 00            	call	dword ptr [0xc258f8]
  549b9a: 68 e2 0b 00 00               	push	0xbe2
  549b9f: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  549ba5: 68 01 03 00 00               	push	0x301
  549baa: 68 00 03 00 00               	push	0x300
  549baf: ff 15 78 59 c2 00            	call	dword ptr [0xc25978]
  549bb5: 68 b8 d5 c2 00               	push	0xc2d5b8
  549bba: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  549bbf: e8 5c 3f ff ff               	call	0x53db20 <.text+0x13cb20>
  549bc4: 50                           	push	eax
  549bc5: b9 e0 70 10 01               	mov	ecx, 0x11070e0
  549bca: e8 e1 51 ff ff               	call	0x53edb0 <.text+0x13ddb0>
  549bcf: dd 5d d8                     	fstp	qword ptr [ebp - 0x28]
  549bd2: f2 0f 10 4d d8               	movsd	xmm1, qword ptr [ebp - 0x28]
  549bd7: f3 0f 10 05 f8 2d c3 00      	movss	xmm0, dword ptr [0xc32df8]
  549bdf: 0f b6 05 ac 73 10 01         	movzx	eax, byte ptr [0x11073ac]
