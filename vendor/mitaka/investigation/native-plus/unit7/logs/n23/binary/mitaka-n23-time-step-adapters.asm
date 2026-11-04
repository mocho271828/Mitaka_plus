
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5e8fc0: 53                           	push	ebx
  5e8fc1: 8b dc                        	mov	ebx, esp
  5e8fc3: 83 e4 f8                     	and	esp, -0x8
  5e8fc6: 55                           	push	ebp
  5e8fc7: 55                           	push	ebp
  5e8fc8: 8b 6b 04                     	mov	ebp, dword ptr [ebx + 0x4]
  5e8fcb: 89 6c 24 04                  	mov	dword ptr [esp + 0x4], ebp
  5e8fcf: 8b ec                        	mov	ebp, esp
  5e8fd1: 6a ff                        	push	-0x1
  5e8fd3: 68 f0 d6 bf 00               	push	0xbfd6f0
  5e8fd8: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  5e8fde: 50                           	push	eax
  5e8fdf: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  5e8fe6: 81 ec ac 00 00 00            	sub	esp, 0xac
  5e8fec: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
  5e8fef: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  5e8ff2: 89 7d ac                     	mov	dword ptr [ebp - 0x54], edi
  5e8ff5: 89 75 b4                     	mov	dword ptr [ebp - 0x4c], esi
  5e8ff8: a1 10 53 d8 00               	mov	eax, dword ptr [0xd85310]
  5e8ffd: 89 4d 84                     	mov	dword ptr [ebp - 0x7c], ecx
  5e9000: 89 45 bc                     	mov	dword ptr [ebp - 0x44], eax
  5e9003: b9 e0 ac 02 01               	mov	ecx, 0x102ace0
  5e9008: e8 b3 5e eb ff               	call	0x49eec0 <.text+0x9dec0>
  5e900d: 0f b6 c0                     	movzx	eax, al
  5e9010: 85 c0                        	test	eax, eax
  5e9012: 74 19                        	je	0x5e902d <.text+0x1e802d>
  5e9014: 8b 4d bc                     	mov	ecx, dword ptr [ebp - 0x44]
  5e9017: e8 a4 5e 4a 00               	call	0xa8eec0 <.text+0x68dec0>
  5e901c: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  5e901f: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  5e9026: 8b e5                        	mov	esp, ebp
  5e9028: 5d                           	pop	ebp
  5e9029: 8b e3                        	mov	esp, ebx
  5e902b: 5b                           	pop	ebx
  5e902c: c3                           	ret
  5e902d: e8 be 33 fb ff               	call	0x59c3f0 <.text+0x19b3f0>
  5e9032: dd 5d e0                     	fstp	qword ptr [ebp - 0x20]
  5e9035: 8d 75 c8                     	lea	esi, [ebp - 0x38]
  5e9038: 8d 45 e0                     	lea	eax, [ebp - 0x20]
  5e903b: 50                           	push	eax
  5e903c: 56                           	push	esi
  5e903d: e8 ce 53 e3 ff               	call	0x41e410 <.text+0x1d410>
  5e9042: 83 c4 08                     	add	esp, 0x8
  5e9045: 0f be 05 60 0e d7 00         	movsx	eax, byte ptr [0xd70e60]
  5e904c: 83 f8 0a                     	cmp	eax, 0xa
  5e904f: 0f 87 16 01 00 00            	ja	0x5e916b <.text+0x1e816b>
  5e9055: 8b 04 85 c8 76 c3 00         	mov	eax, dword ptr [4*eax + 0xc376c8]
  5e905c: ff e0                        	jmp	eax
  5e905e: f2 0f 2a 45 c8               	cvtsi2sd	xmm0, dword ptr [ebp - 0x38]
  5e9063: f2 0f 58 05 50 75 c3 00      	addsd	xmm0, qword ptr [0xc37550]
  5e906b: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e906f: 89 45 c8                     	mov	dword ptr [ebp - 0x38], eax
  5e9072: e9 f4 00 00 00               	jmp	0x5e916b <.text+0x1e816b>
  5e9077: f2 0f 2a 45 c8               	cvtsi2sd	xmm0, dword ptr [ebp - 0x38]
  5e907c: f2 0f 58 05 40 75 c3 00      	addsd	xmm0, qword ptr [0xc37540]
  5e9084: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e9088: 89 45 c8                     	mov	dword ptr [ebp - 0x38], eax
  5e908b: e9 db 00 00 00               	jmp	0x5e916b <.text+0x1e816b>
  5e9090: f2 0f 2a 45 c8               	cvtsi2sd	xmm0, dword ptr [ebp - 0x38]
  5e9095: f2 0f 58 05 58 75 c3 00      	addsd	xmm0, qword ptr [0xc37558]
  5e909d: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e90a1: 89 45 c8                     	mov	dword ptr [ebp - 0x38], eax
  5e90a4: e9 c2 00 00 00               	jmp	0x5e916b <.text+0x1e816b>
  5e90a9: 0f be 7d cc                  	movsx	edi, byte ptr [ebp - 0x34]
  5e90ad: f2 0f 2a c7                  	cvtsi2sd	xmm0, edi
  5e90b1: f2 0f 58 05 58 75 c3 00      	addsd	xmm0, qword ptr [0xc37558]
  5e90b9: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e90bd: 88 45 cc                     	mov	byte ptr [ebp - 0x34], al
  5e90c0: e9 a6 00 00 00               	jmp	0x5e916b <.text+0x1e816b>
  5e90c5: 0f be 7d cd                  	movsx	edi, byte ptr [ebp - 0x33]
  5e90c9: f2 0f 2a c7                  	cvtsi2sd	xmm0, edi
  5e90cd: f2 0f 58 05 48 75 c3 00      	addsd	xmm0, qword ptr [0xc37548]
  5e90d5: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e90d9: 88 45 cd                     	mov	byte ptr [ebp - 0x33], al
  5e90dc: e9 8a 00 00 00               	jmp	0x5e916b <.text+0x1e816b>
  5e90e1: 0f be 7d cd                  	movsx	edi, byte ptr [ebp - 0x33]
  5e90e5: f2 0f 2a c7                  	cvtsi2sd	xmm0, edi
  5e90e9: f2 0f 58 05 58 75 c3 00      	addsd	xmm0, qword ptr [0xc37558]
  5e90f1: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e90f5: 88 45 cd                     	mov	byte ptr [ebp - 0x33], al
  5e90f8: eb 71                        	jmp	0x5e916b <.text+0x1e816b>
  5e90fa: 0f be 7d ce                  	movsx	edi, byte ptr [ebp - 0x32]
  5e90fe: f2 0f 2a c7                  	cvtsi2sd	xmm0, edi
  5e9102: f2 0f 58 05 58 75 c3 00      	addsd	xmm0, qword ptr [0xc37558]
  5e910a: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e910e: 88 45 ce                     	mov	byte ptr [ebp - 0x32], al
  5e9111: eb 58                        	jmp	0x5e916b <.text+0x1e816b>
  5e9113: 0f be 7d cf                  	movsx	edi, byte ptr [ebp - 0x31]
  5e9117: f2 0f 2a c7                  	cvtsi2sd	xmm0, edi
  5e911b: f2 0f 58 05 40 75 c3 00      	addsd	xmm0, qword ptr [0xc37540]
  5e9123: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e9127: 88 45 cf                     	mov	byte ptr [ebp - 0x31], al
  5e912a: eb 3f                        	jmp	0x5e916b <.text+0x1e816b>
  5e912c: 0f be 7d cf                  	movsx	edi, byte ptr [ebp - 0x31]
  5e9130: f2 0f 2a c7                  	cvtsi2sd	xmm0, edi
  5e9134: f2 0f 58 05 58 75 c3 00      	addsd	xmm0, qword ptr [0xc37558]
  5e913c: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e9140: 88 45 cf                     	mov	byte ptr [ebp - 0x31], al
  5e9143: eb 26                        	jmp	0x5e916b <.text+0x1e816b>
  5e9145: f2 0f 10 05 40 75 c3 00      	movsd	xmm0, qword ptr [0xc37540]
  5e914d: f2 0f 58 45 d0               	addsd	xmm0, qword ptr [ebp - 0x30]
  5e9152: f2 0f 11 45 d0               	movsd	qword ptr [ebp - 0x30], xmm0
  5e9157: eb 12                        	jmp	0x5e916b <.text+0x1e816b>
  5e9159: f2 0f 10 05 58 75 c3 00      	movsd	xmm0, qword ptr [0xc37558]
  5e9161: f2 0f 58 45 d0               	addsd	xmm0, qword ptr [ebp - 0x30]
  5e9166: f2 0f 11 45 d0               	movsd	qword ptr [ebp - 0x30], xmm0
  5e916b: 6a 00                        	push	0x0
  5e916d: e8 4e bf e9 ff               	call	0x4850c0 <.text+0x840c0>
  5e9172: 59                           	pop	ecx
  5e9173: 80 3d 60 0e d7 00 0b         	cmp	byte ptr [0xd70e60], 0xb
  5e917a: 0f 84 c6 05 00 00            	je	0x5e9746 <.text+0x1e8746>
  5e9180: 56                           	push	esi
  5e9181: e8 fa 4f e3 ff               	call	0x41e180 <.text+0x1d180>
  5e9186: dd 5d d8                     	fstp	qword ptr [ebp - 0x28]
  5e9189: 8d 45 d8                     	lea	eax, [ebp - 0x28]
  5e918c: 50                           	push	eax
  5e918d: e8 fe dd e9 ff               	call	0x486f90 <.text+0x85f90>
  5e9192: 83 c4 08                     	add	esp, 0x8
  5e9195: e8 26 d1 fd ff               	call	0x5c62c0 <.text+0x1c52c0>
  5e919a: 8b c8                        	mov	ecx, eax
  5e919c: e8 3f d2 fd ff               	call	0x5c63e0 <.text+0x1c53e0>
  5e91a1: 0f b6 c0                     	movzx	eax, al
  5e91a4: 85 c0                        	test	eax, eax
  5e91a6: 74 13                        	je	0x5e91bb <.text+0x1e81bb>
  5e91a8: e8 13 d1 fd ff               	call	0x5c62c0 <.text+0x1c52c0>
  5e91ad: 8b c8                        	mov	ecx, eax
  5e91af: e8 bc d6 fd ff               	call	0x5c6870 <.text+0x1c5870>
  5e91b4: 0f b6 c0                     	movzx	eax, al
  5e91b7: 85 c0                        	test	eax, eax
  5e91b9: 74 2b                        	je	0x5e91e6 <.text+0x1e81e6>
  5e91bb: e8 b0 f2 fe ff               	call	0x5d8470 <.text+0x1d7470>
  5e91c0: 8b c8                        	mov	ecx, eax
  5e91c2: e8 19 fa fe ff               	call	0x5d8be0 <.text+0x1d7be0>
  5e91c7: 8b 4d bc                     	mov	ecx, dword ptr [ebp - 0x44]
  5e91ca: e8 f1 5c 4a 00               	call	0xa8eec0 <.text+0x68dec0>
  5e91cf: 8b 7d ac                     	mov	edi, dword ptr [ebp - 0x54]
  5e91d2: 8b 75 b4                     	mov	esi, dword ptr [ebp - 0x4c]
  5e91d5: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  5e91d8: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  5e91df: 8b e5                        	mov	esp, ebp
  5e91e1: 5d                           	pop	ebp
  5e91e2: 8b e3                        	mov	esp, ebx
  5e91e4: 5b                           	pop	ebx
  5e91e5: c3                           	ret
  5e91e6: e8 95 94 47 00               	call	0xa62680 <.text+0x661680>
  5e91eb: 8b f8                        	mov	edi, eax
  5e91ed: c7 85 60 ff ff ff 0f 00 00 00	mov	dword ptr [ebp - 0xa0], 0xf
  5e91f7: 8d b5 4c ff ff ff            	lea	esi, [ebp - 0xb4]
  5e91fd: 33 c0                        	xor	eax, eax
  5e91ff: b9 a4 78 c3 00               	mov	ecx, 0xc378a4
  5e9204: c7 45 b8 0d 00 00 00         	mov	dword ptr [ebp - 0x48], 0xd
  5e920b: 89 85 5c ff ff ff            	mov	dword ptr [ebp - 0xa4], eax
  5e9211: 88 06                        	mov	byte ptr [esi], al
  5e9213: 8b 85 60 ff ff ff            	mov	eax, dword ptr [ebp - 0xa0]
  5e9219: 8d 95 48 ff ff ff            	lea	edx, [ebp - 0xb8]
  5e921f: 89 55 98                     	mov	dword ptr [ebp - 0x68], edx
  5e9222: 8b 95 4c ff ff ff            	mov	edx, dword ptr [ebp - 0xb4]
  5e9228: 89 4d b0                     	mov	dword ptr [ebp - 0x50], ecx
  5e922b: 83 f8 10                     	cmp	eax, 0x10
  5e922e: 0f 42 d6                     	cmovb	edx, esi
  5e9231: 3b ca                        	cmp	ecx, edx
  5e9233: 0f 83 e0 04 00 00            	jae	0x5e9719 <.text+0x1e8719>
  5e9239: 33 d2                        	xor	edx, edx
  5e923b: 85 d2                        	test	edx, edx
  5e923d: 0f 84 b1 00 00 00            	je	0x5e92f4 <.text+0x1e82f4>
  5e9243: 83 f8 10                     	cmp	eax, 0x10
  5e9246: 8d 85 4c ff ff ff            	lea	eax, [ebp - 0xb4]
  5e924c: 0f 43 85 4c ff ff ff         	cmovae	eax, dword ptr [ebp - 0xb4]
  5e9253: be a4 78 c3 00               	mov	esi, 0xc378a4
  5e9258: 2b f0                        	sub	esi, eax
  5e925a: 8b 85 5c ff ff ff            	mov	eax, dword ptr [ebp - 0xa4]
  5e9260: 89 b5 78 ff ff ff            	mov	dword ptr [ebp - 0x88], esi
  5e9266: 3b c6                        	cmp	eax, esi
  5e9268: 72 11                        	jb	0x5e927b <.text+0x1e827b>
  5e926a: 8b d0                        	mov	edx, eax
  5e926c: 2b d6                        	sub	edx, esi
  5e926e: b9 0d 00 00 00               	mov	ecx, 0xd
  5e9273: 83 fa 0d                     	cmp	edx, 0xd
  5e9276: 0f 47 d1                     	cmova	edx, ecx
  5e9279: eb 21                        	jmp	0x5e929c <.text+0x1e829c>
  5e927b: ff 15 dc 53 c2 00            	call	dword ptr [0xc253dc]
  5e9281: 8b 85 5c ff ff ff            	mov	eax, dword ptr [ebp - 0xa4]
  5e9287: 8b b5 78 ff ff ff            	mov	esi, dword ptr [ebp - 0x88]
  5e928d: 8b d0                        	mov	edx, eax
  5e928f: 2b d6                        	sub	edx, esi
  5e9291: b9 0d 00 00 00               	mov	ecx, 0xd
  5e9296: 83 fa 0d                     	cmp	edx, 0xd
  5e9299: 0f 47 d1                     	cmova	edx, ecx
  5e929c: 03 f2                        	add	esi, edx
  5e929e: 8b 15 d0 53 c2 00            	mov	edx, dword ptr [0xc253d0]
  5e92a4: 8b 0a                        	mov	ecx, dword ptr [edx]
  5e92a6: 89 8d 70 ff ff ff            	mov	dword ptr [ebp - 0x90], ecx
  5e92ac: 3b c6                        	cmp	eax, esi
  5e92ae: 73 0c                        	jae	0x5e92bc <.text+0x1e82bc>
  5e92b0: ff 15 dc 53 c2 00            	call	dword ptr [0xc253dc]
  5e92b6: 8b 85 5c ff ff ff            	mov	eax, dword ptr [ebp - 0xa4]
  5e92bc: 8b 8d 70 ff ff ff            	mov	ecx, dword ptr [ebp - 0x90]
  5e92c2: 8b d0                        	mov	edx, eax
  5e92c4: 2b d6                        	sub	edx, esi
  5e92c6: 3b d1                        	cmp	edx, ecx
  5e92c8: 0f 42 ca                     	cmovb	ecx, edx
  5e92cb: 89 8d 70 ff ff ff            	mov	dword ptr [ebp - 0x90], ecx
  5e92d1: 85 c9                        	test	ecx, ecx
  5e92d3: 0f 87 93 01 00 00            	ja	0x5e946c <.text+0x1e846c>
  5e92d9: 8b 95 78 ff ff ff            	mov	edx, dword ptr [ebp - 0x88]
  5e92df: 3b c2                        	cmp	eax, edx
  5e92e1: 0f 42 d0                     	cmovb	edx, eax
  5e92e4: 85 d2                        	test	edx, edx
  5e92e6: 89 95 64 ff ff ff            	mov	dword ptr [ebp - 0x9c], edx
  5e92ec: 0f 87 0e 01 00 00            	ja	0x5e9400 <.text+0x1e8400>
  5e92f2: eb 1a                        	jmp	0x5e930e <.text+0x1e830e>
  5e92f4: c7 45 90 0d 00 00 00         	mov	dword ptr [ebp - 0x70], 0xd
  5e92fb: 83 f8 0d                     	cmp	eax, 0xd
  5e92fe: 0f 82 88 02 00 00            	jb	0x5e958c <.text+0x1e858c>
  5e9304: 83 7d 90 00                  	cmp	dword ptr [ebp - 0x70], 0x0
  5e9308: 0f 87 39 02 00 00            	ja	0x5e9547 <.text+0x1e8547>
  5e930e: c7 45 fc 04 00 00 00         	mov	dword ptr [ebp - 0x4], 0x4
  5e9315: 8b 4d 84                     	mov	ecx, dword ptr [ebp - 0x7c]
  5e9318: 8d b5 64 ff ff ff            	lea	esi, [ebp - 0x9c]
  5e931e: 56                           	push	esi
  5e931f: e8 5c 04 00 00               	call	0x5e9780 <.text+0x1e8780>
  5e9324: c7 45 fc 05 00 00 00         	mov	dword ptr [ebp - 0x4], 0x5
  5e932b: 8d 45 80                     	lea	eax, [ebp - 0x80]
  5e932e: 8d 95 48 ff ff ff            	lea	edx, [ebp - 0xb8]
  5e9334: 83 c4 f4                     	add	esp, -0xc
  5e9337: 89 04 24                     	mov	dword ptr [esp], eax
  5e933a: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  5e933e: 89 74 24 08                  	mov	dword ptr [esp + 0x8], esi
  5e9342: ff 15 f0 53 c2 00            	call	dword ptr [0xc253f0]
  5e9348: 83 c4 0c                     	add	esp, 0xc
  5e934b: c7 45 fc 06 00 00 00         	mov	dword ptr [ebp - 0x4], 0x6
  5e9352: 8d 55 80                     	lea	edx, [ebp - 0x80]
  5e9355: 83 c4 e4                     	add	esp, -0x1c
  5e9358: 8b c4                        	mov	eax, esp
  5e935a: 83 c4 f4                     	add	esp, -0xc
  5e935d: 89 04 24                     	mov	dword ptr [esp], eax
  5e9360: c7 44 24 08 b4 78 c3 00      	mov	dword ptr [esp + 0x8], 0xc378b4
  5e9368: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  5e936c: ff 15 c0 53 c2 00            	call	dword ptr [0xc253c0]
  5e9372: 83 c4 0c                     	add	esp, 0xc
  5e9375: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5e937c: 8b cf                        	mov	ecx, edi
  5e937e: e8 4d 77 47 00               	call	0xa60ad0 <.text+0x65fad0>
  5e9383: c7 45 fc 05 00 00 00         	mov	dword ptr [ebp - 0x4], 0x5
  5e938a: 83 7d 98 10                  	cmp	dword ptr [ebp - 0x68], 0x10
  5e938e: 0f 83 a5 01 00 00            	jae	0x5e9539 <.text+0x1e8539>
  5e9394: c7 45 fc 04 00 00 00         	mov	dword ptr [ebp - 0x4], 0x4
  5e939b: 33 c0                        	xor	eax, eax
  5e939d: 83 bd 7c ff ff ff 10         	cmp	dword ptr [ebp - 0x84], 0x10
  5e93a4: 89 45 94                     	mov	dword ptr [ebp - 0x6c], eax
  5e93a7: c7 45 98 0f 00 00 00         	mov	dword ptr [ebp - 0x68], 0xf
  5e93ae: 88 45 84                     	mov	byte ptr [ebp - 0x7c], al
  5e93b1: 0f 83 71 01 00 00            	jae	0x5e9528 <.text+0x1e8528>
  5e93b7: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5e93be: 33 c0                        	xor	eax, eax
  5e93c0: 83 bd 60 ff ff ff 10         	cmp	dword ptr [ebp - 0xa0], 0x10
  5e93c7: 89 85 78 ff ff ff            	mov	dword ptr [ebp - 0x88], eax
  5e93cd: c7 85 7c ff ff ff 0f 00 00 00	mov	dword ptr [ebp - 0x84], 0xf
  5e93d7: 88 85 68 ff ff ff            	mov	byte ptr [ebp - 0x98], al
  5e93dd: 0f 83 34 01 00 00            	jae	0x5e9517 <.text+0x1e8517>
  5e93e3: c7 85 60 ff ff ff 0f 00 00 00	mov	dword ptr [ebp - 0xa0], 0xf
  5e93ed: 33 c0                        	xor	eax, eax
  5e93ef: 89 85 5c ff ff ff            	mov	dword ptr [ebp - 0xa4], eax
  5e93f5: 88 85 4c ff ff ff            	mov	byte ptr [ebp - 0xb4], al
  5e93fb: e9 bb fd ff ff               	jmp	0x5e91bb <.text+0x1e81bb>
  5e9400: 8b 8d 60 ff ff ff            	mov	ecx, dword ptr [ebp - 0xa0]
  5e9406: 83 f9 10                     	cmp	ecx, 0x10
  5e9409: 72 08                        	jb	0x5e9413 <.text+0x1e8413>
  5e940b: 8b 95 4c ff ff ff            	mov	edx, dword ptr [ebp - 0xb4]
  5e9411: eb 06                        	jmp	0x5e9419 <.text+0x1e8419>
  5e9413: 8d 95 4c ff ff ff            	lea	edx, [ebp - 0xb4]
  5e9419: 8b b5 64 ff ff ff            	mov	esi, dword ptr [ebp - 0x9c]
  5e941f: 89 bd 6c ff ff ff            	mov	dword ptr [ebp - 0x94], edi
  5e9425: 8d 3c 16                     	lea	edi, [esi + edx]
  5e9428: 2b c6                        	sub	eax, esi
  5e942a: 50                           	push	eax
  5e942b: 57                           	push	edi
  5e942c: 8b bd 6c ff ff ff            	mov	edi, dword ptr [ebp - 0x94]
  5e9432: 51                           	push	ecx
  5e9433: 52                           	push	edx
  5e9434: ff 15 f8 55 c2 00            	call	dword ptr [0xc255f8]
  5e943a: 83 c4 10                     	add	esp, 0x10
  5e943d: 83 bd 60 ff ff ff 10         	cmp	dword ptr [ebp - 0xa0], 0x10
  5e9444: 8b 95 5c ff ff ff            	mov	edx, dword ptr [ebp - 0xa4]
  5e944a: 8d 85 4c ff ff ff            	lea	eax, [ebp - 0xb4]
  5e9450: 0f 43 85 4c ff ff ff         	cmovae	eax, dword ptr [ebp - 0xb4]
  5e9457: 2b 95 64 ff ff ff            	sub	edx, dword ptr [ebp - 0x9c]
  5e945d: 89 95 5c ff ff ff            	mov	dword ptr [ebp - 0xa4], edx
  5e9463: c6 04 10 00                  	mov	byte ptr [eax + edx], 0x0
  5e9467: e9 a2 fe ff ff               	jmp	0x5e930e <.text+0x1e830e>
  5e946c: 8b 85 60 ff ff ff            	mov	eax, dword ptr [ebp - 0xa0]
  5e9472: 89 85 64 ff ff ff            	mov	dword ptr [ebp - 0x9c], eax
  5e9478: 83 f8 10                     	cmp	eax, 0x10
  5e947b: 72 08                        	jb	0x5e9485 <.text+0x1e8485>
  5e947d: 8b 85 4c ff ff ff            	mov	eax, dword ptr [ebp - 0xb4]
  5e9483: eb 06                        	jmp	0x5e948b <.text+0x1e848b>
  5e9485: 8d 85 4c ff ff ff            	lea	eax, [ebp - 0xb4]
  5e948b: 89 bd 6c ff ff ff            	mov	dword ptr [ebp - 0x94], edi
  5e9491: 8b f9                        	mov	edi, ecx
  5e9493: 8d 0c 06                     	lea	ecx, [esi + eax]
  5e9496: 2b d7                        	sub	edx, edi
  5e9498: 89 8d 68 ff ff ff            	mov	dword ptr [ebp - 0x98], ecx
  5e949e: 8b 8d 64 ff ff ff            	mov	ecx, dword ptr [ebp - 0x9c]
  5e94a4: 52                           	push	edx
  5e94a5: 2b ce                        	sub	ecx, esi
  5e94a7: 03 f7                        	add	esi, edi
  5e94a9: 8b bd 6c ff ff ff            	mov	edi, dword ptr [ebp - 0x94]
  5e94af: 03 f0                        	add	esi, eax
  5e94b1: 56                           	push	esi
  5e94b2: 51                           	push	ecx
  5e94b3: ff b5 68 ff ff ff            	push	dword ptr [ebp - 0x98]
  5e94b9: ff 15 f8 55 c2 00            	call	dword ptr [0xc255f8]
  5e94bf: 83 c4 10                     	add	esp, 0x10
  5e94c2: 83 bd 60 ff ff ff 10         	cmp	dword ptr [ebp - 0xa0], 0x10
  5e94c9: 8b 95 5c ff ff ff            	mov	edx, dword ptr [ebp - 0xa4]
  5e94cf: 8d 85 4c ff ff ff            	lea	eax, [ebp - 0xb4]
  5e94d5: 0f 43 85 4c ff ff ff         	cmovae	eax, dword ptr [ebp - 0xb4]
  5e94dc: 2b 95 70 ff ff ff            	sub	edx, dword ptr [ebp - 0x90]
  5e94e2: 89 95 5c ff ff ff            	mov	dword ptr [ebp - 0xa4], edx
  5e94e8: c6 04 10 00                  	mov	byte ptr [eax + edx], 0x0
  5e94ec: 8b 85 5c ff ff ff            	mov	eax, dword ptr [ebp - 0xa4]
  5e94f2: e9 e2 fd ff ff               	jmp	0x5e92d9 <.text+0x1e82d9>
  5e94f7: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5e94fa: 8d 8d 48 ff ff ff            	lea	ecx, [ebp - 0xb8]
  5e9500: ff 15 bc 53 c2 00            	call	dword ptr [0xc253bc]
  5e9506: c3                           	ret
  5e9507: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5e950a: 8d 8d 64 ff ff ff            	lea	ecx, [ebp - 0x9c]
  5e9510: ff 15 bc 53 c2 00            	call	dword ptr [0xc253bc]
  5e9516: c3                           	ret
  5e9517: ff b5 4c ff ff ff            	push	dword ptr [ebp - 0xb4]
  5e951d: e8 70 5a 4a 00               	call	0xa8ef92 <.text+0x68df92>
  5e9522: 59                           	pop	ecx
  5e9523: e9 bb fe ff ff               	jmp	0x5e93e3 <.text+0x1e83e3>
  5e9528: ff b5 68 ff ff ff            	push	dword ptr [ebp - 0x98]
  5e952e: e8 5f 5a 4a 00               	call	0xa8ef92 <.text+0x68df92>
  5e9533: 59                           	pop	ecx
  5e9534: e9 7e fe ff ff               	jmp	0x5e93b7 <.text+0x1e83b7>
  5e9539: ff 75 84                     	push	dword ptr [ebp - 0x7c]
  5e953c: e8 51 5a 4a 00               	call	0xa8ef92 <.text+0x68df92>
  5e9541: 59                           	pop	ecx
  5e9542: e9 4d fe ff ff               	jmp	0x5e9394 <.text+0x1e8394>
  5e9547: 8b 4d 98                     	mov	ecx, dword ptr [ebp - 0x68]
  5e954a: 8b 51 18                     	mov	edx, dword ptr [ecx + 0x18]
  5e954d: 83 fa 10                     	cmp	edx, 0x10
  5e9550: 72 05                        	jb	0x5e9557 <.text+0x1e8557>
  5e9552: 8b 49 04                     	mov	ecx, dword ptr [ecx + 0x4]
  5e9555: eb 03                        	jmp	0x5e955a <.text+0x1e855a>
  5e9557: 83 c1 04                     	add	ecx, 0x4
  5e955a: ff 75 b8                     	push	dword ptr [ebp - 0x48]
  5e955d: ff 75 b0                     	push	dword ptr [ebp - 0x50]
  5e9560: 52                           	push	edx
  5e9561: 51                           	push	ecx
  5e9562: ff 15 00 56 c2 00            	call	dword ptr [0xc25600]
  5e9568: 83 c4 10                     	add	esp, 0x10
  5e956b: 8b 55 98                     	mov	edx, dword ptr [ebp - 0x68]
  5e956e: 83 7a 18 10                  	cmp	dword ptr [edx + 0x18], 0x10
  5e9572: 8b 4d b8                     	mov	ecx, dword ptr [ebp - 0x48]
  5e9575: 89 4a 14                     	mov	dword ptr [edx + 0x14], ecx
  5e9578: 72 05                        	jb	0x5e957f <.text+0x1e857f>
  5e957a: 8b 52 04                     	mov	edx, dword ptr [edx + 0x4]
  5e957d: eb 03                        	jmp	0x5e9582 <.text+0x1e8582>
  5e957f: 83 c2 04                     	add	edx, 0x4
  5e9582: 33 c0                        	xor	eax, eax
  5e9584: 88 04 0a                     	mov	byte ptr [edx + ecx], al
  5e9587: e9 82 fd ff ff               	jmp	0x5e930e <.text+0x1e830e>
  5e958c: 8b 8d 5c ff ff ff            	mov	ecx, dword ptr [ebp - 0xa4]
  5e9592: c7 45 88 0d 00 00 00         	mov	dword ptr [ebp - 0x78], 0xd
  5e9599: 8b f0                        	mov	esi, eax
  5e959b: d1 ee                        	shr	esi
  5e959d: 8d 95 48 ff ff ff            	lea	edx, [ebp - 0xb8]
  5e95a3: 89 55 80                     	mov	dword ptr [ebp - 0x80], edx
  5e95a6: 89 8d 78 ff ff ff            	mov	dword ptr [ebp - 0x88], ecx
  5e95ac: b9 0f 00 00 00               	mov	ecx, 0xf
  5e95b1: 83 fe 05                     	cmp	esi, 0x5
  5e95b4: 77 0c                        	ja	0x5e95c2 <.text+0x1e85c2>
  5e95b6: c7 85 68 ff ff ff 0f 00 00 00	mov	dword ptr [ebp - 0x98], 0xf
  5e95c0: eb 14                        	jmp	0x5e95d6 <.text+0x1e85d6>
  5e95c2: 8b d6                        	mov	edx, esi
  5e95c4: f7 da                        	neg	edx
  5e95c6: 83 c2 fe                     	add	edx, -0x2
  5e95c9: 3b c2                        	cmp	eax, edx
  5e95cb: 77 e9                        	ja	0x5e95b6 <.text+0x1e85b6>
  5e95cd: 8d 0c 30                     	lea	ecx, [eax + esi]
  5e95d0: 89 8d 68 ff ff ff            	mov	dword ptr [ebp - 0x98], ecx
  5e95d6: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  5e95dd: c7 85 70 ff ff ff 00 00 00 00	mov	dword ptr [ebp - 0x90], 0x0
  5e95e7: 41                           	inc	ecx
  5e95e8: 75 04                        	jne	0x5e95ee <.text+0x1e85ee>
  5e95ea: 33 c9                        	xor	ecx, ecx
  5e95ec: eb 36                        	jmp	0x5e9624 <.text+0x1e8624>
  5e95ee: 33 d2                        	xor	edx, edx
  5e95f0: b8 ff ff ff ff               	mov	eax, 0xffffffff
  5e95f5: f7 f1                        	div	ecx
  5e95f7: 83 f8 01                     	cmp	eax, 0x1
  5e95fa: 73 28                        	jae	0x5e9624 <.text+0x1e8624>
  5e95fc: c7 45 a8 00 00 00 00         	mov	dword ptr [ebp - 0x58], 0x0
  5e9603: 8d 75 9c                     	lea	esi, [ebp - 0x64]
  5e9606: 8b ce                        	mov	ecx, esi
  5e9608: 8d 45 a8                     	lea	eax, [ebp - 0x58]
  5e960b: 50                           	push	eax
  5e960c: ff 15 f0 55 c2 00            	call	dword ptr [0xc255f0]
  5e9612: c7 45 9c 20 a1 d3 00         	mov	dword ptr [ebp - 0x64], 0xd3a120
  5e9619: 68 18 01 d7 00               	push	0xd70118
  5e961e: 56                           	push	esi
  5e961f: e8 f2 59 4a 00               	call	0xa8f016 <.text+0x68e016>
  5e9624: 50                           	push	eax
  5e9625: 89 0c 24                     	mov	dword ptr [esp], ecx
  5e9628: e8 dd 59 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5e962d: 59                           	pop	ecx
  5e962e: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5e9635: 89 85 70 ff ff ff            	mov	dword ptr [ebp - 0x90], eax
  5e963b: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5e9642: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5e9645: 8b 95 78 ff ff ff            	mov	edx, dword ptr [ebp - 0x88]
  5e964b: 85 d2                        	test	edx, edx
  5e964d: 0f 87 97 00 00 00            	ja	0x5e96ea <.text+0x1e86ea>
  5e9653: 8b 45 80                     	mov	eax, dword ptr [ebp - 0x80]
  5e9656: 83 78 18 10                  	cmp	dword ptr [eax + 0x18], 0x10
  5e965a: 8b f0                        	mov	esi, eax
  5e965c: 73 7b                        	jae	0x5e96d9 <.text+0x1e86d9>
  5e965e: 8b 8d 68 ff ff ff            	mov	ecx, dword ptr [ebp - 0x98]
  5e9664: c7 46 18 0f 00 00 00         	mov	dword ptr [esi + 0x18], 0xf
  5e966b: 33 d2                        	xor	edx, edx
  5e966d: 89 56 14                     	mov	dword ptr [esi + 0x14], edx
  5e9670: 89 bd 6c ff ff ff            	mov	dword ptr [ebp - 0x94], edi
  5e9676: 8b bd 78 ff ff ff            	mov	edi, dword ptr [ebp - 0x88]
  5e967c: 88 56 04                     	mov	byte ptr [esi + 0x4], dl
  5e967f: 8b b5 70 ff ff ff            	mov	esi, dword ptr [ebp - 0x90]
  5e9685: 89 70 04                     	mov	dword ptr [eax + 0x4], esi
  5e9688: 89 48 18                     	mov	dword ptr [eax + 0x18], ecx
  5e968b: 89 78 14                     	mov	dword ptr [eax + 0x14], edi
  5e968e: 83 c0 04                     	add	eax, 0x4
  5e9691: 83 f9 10                     	cmp	ecx, 0x10
  5e9694: 0f 43 c6                     	cmovae	eax, esi
  5e9697: 88 14 38                     	mov	byte ptr [eax + edi], dl
  5e969a: 8b bd 6c ff ff ff            	mov	edi, dword ptr [ebp - 0x94]
  5e96a0: e9 5f fc ff ff               	jmp	0x5e9304 <.text+0x1e8304>
  5e96a5: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
  5e96a8: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5e96ab: c7 45 fc 02 00 00 00         	mov	dword ptr [ebp - 0x4], 0x2
  5e96b2: 8b 45 88                     	mov	eax, dword ptr [ebp - 0x78]
  5e96b5: 8b 4d 80                     	mov	ecx, dword ptr [ebp - 0x80]
  5e96b8: 89 85 68 ff ff ff            	mov	dword ptr [ebp - 0x98], eax
  5e96be: 40                           	inc	eax
  5e96bf: 50                           	push	eax
  5e96c0: ff 15 d8 53 c2 00            	call	dword ptr [0xc253d8]
  5e96c6: c7 45 fc 01 00 00 00         	mov	dword ptr [ebp - 0x4], 0x1
  5e96cd: 89 85 70 ff ff ff            	mov	dword ptr [ebp - 0x90], eax
  5e96d3: b8 3b 96 5e 00               	mov	eax, 0x5e963b
  5e96d8: c3                           	ret
  5e96d9: ff 70 04                     	push	dword ptr [eax + 0x4]
  5e96dc: e8 b1 58 4a 00               	call	0xa8ef92 <.text+0x68df92>
  5e96e1: 59                           	pop	ecx
  5e96e2: 8b 45 80                     	mov	eax, dword ptr [ebp - 0x80]
  5e96e5: e9 74 ff ff ff               	jmp	0x5e965e <.text+0x1e865e>
  5e96ea: 8b 4d 80                     	mov	ecx, dword ptr [ebp - 0x80]
  5e96ed: 83 79 18 10                  	cmp	dword ptr [ecx + 0x18], 0x10
  5e96f1: 72 05                        	jb	0x5e96f8 <.text+0x1e86f8>
  5e96f3: 8b 49 04                     	mov	ecx, dword ptr [ecx + 0x4]
  5e96f6: eb 03                        	jmp	0x5e96fb <.text+0x1e86fb>
  5e96f8: 83 c1 04                     	add	ecx, 0x4
  5e96fb: 8b b5 68 ff ff ff            	mov	esi, dword ptr [ebp - 0x98]
  5e9701: 52                           	push	edx
  5e9702: 46                           	inc	esi
  5e9703: 51                           	push	ecx
  5e9704: 56                           	push	esi
  5e9705: ff b5 70 ff ff ff            	push	dword ptr [ebp - 0x90]
  5e970b: ff 15 00 56 c2 00            	call	dword ptr [0xc25600]
  5e9711: 83 c4 10                     	add	esp, 0x10
  5e9714: e9 3a ff ff ff               	jmp	0x5e9653 <.text+0x1e8653>
  5e9719: 8d 95 4c ff ff ff            	lea	edx, [ebp - 0xb4]
  5e971f: 83 f8 10                     	cmp	eax, 0x10
  5e9722: 0f 43 95 4c ff ff ff         	cmovae	edx, dword ptr [ebp - 0xb4]
  5e9729: 03 95 5c ff ff ff            	add	edx, dword ptr [ebp - 0xa4]
  5e972f: b9 a4 78 c3 00               	mov	ecx, 0xc378a4
  5e9734: 3b d1                        	cmp	edx, ecx
  5e9736: 0f 86 fd fa ff ff            	jbe	0x5e9239 <.text+0x1e8239>
  5e973c: ba 01 00 00 00               	mov	edx, 0x1
  5e9741: e9 f5 fa ff ff               	jmp	0x5e923b <.text+0x1e823b>
  5e9746: 56                           	push	esi
  5e9747: e8 34 4a e3 ff               	call	0x41e180 <.text+0x1d180>
  5e974c: dd 9d 48 ff ff ff            	fstp	qword ptr [ebp - 0xb8]
  5e9752: f2 0f 10 85 48 ff ff ff      	movsd	xmm0, qword ptr [ebp - 0xb8]
  5e975a: f2 0f 10 0d c0 90 fe 00      	movsd	xmm1, qword ptr [0xfe90c0]
  5e9762: 8d 45 c0                     	lea	eax, [ebp - 0x40]
  5e9765: 50                           	push	eax
  5e9766: f2 0f 58 c8                  	addsd	xmm1, xmm0
  5e976a: f2 0f 11 4d c0               	movsd	qword ptr [ebp - 0x40], xmm1
  5e976f: e8 1c d8 e9 ff               	call	0x486f90 <.text+0x85f90>
  5e9774: e9 19 fa ff ff               	jmp	0x5e9192 <.text+0x1e8192>
  5e9779: 90                           	nop
  5e977a: 90                           	nop
  5e977b: 90                           	nop
  5e977c: 90                           	nop
  5e977d: 90                           	nop
  5e977e: 90                           	nop
  5e977f: 90                           	nop
  5e9780: 55                           	push	ebp
  5e9781: 8b ec                        	mov	ebp, esp
  5e9783: 6a ff                        	push	-0x1
  5e9785: 68 20 d7 bf 00               	push	0xbfd720
  5e978a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  5e9790: 50                           	push	eax
  5e9791: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  5e9798: 81 ec 60 01 00 00            	sub	esp, 0x160
  5e979e: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
  5e97a1: 89 5d dc                     	mov	dword ptr [ebp - 0x24], ebx
  5e97a4: 89 7d d4                     	mov	dword ptr [ebp - 0x2c], edi
  5e97a7: 89 75 d8                     	mov	dword ptr [ebp - 0x28], esi
  5e97aa: a1 10 53 d8 00               	mov	eax, dword ptr [0xd85310]
  5e97af: 89 45 ec                     	mov	dword ptr [ebp - 0x14], eax
  5e97b2: e8 39 2c fb ff               	call	0x59c3f0 <.text+0x19b3f0>
  5e97b7: dd 5d c8                     	fstp	qword ptr [ebp - 0x38]
  5e97ba: 8d 55 b8                     	lea	edx, [ebp - 0x48]
  5e97bd: 8d 45 c8                     	lea	eax, [ebp - 0x38]
  5e97c0: 50                           	push	eax
  5e97c1: 52                           	push	edx
  5e97c2: e8 49 4c e3 ff               	call	0x41e410 <.text+0x1d410>
  5e97c7: 0f be 7d bc                  	movsx	edi, byte ptr [ebp - 0x44]
  5e97cb: 0f be 75 bd                  	movsx	esi, byte ptr [ebp - 0x43]
  5e97cf: 0f be 4d be                  	movsx	ecx, byte ptr [ebp - 0x42]
  5e97d3: 0f be 55 bf                  	movsx	edx, byte ptr [ebp - 0x41]
  5e97d7: f2 0f 2c 45 c0               	cvttsd2si	eax, qword ptr [ebp - 0x40]
  5e97dc: 8d 9d 94 fe ff ff            	lea	ebx, [ebp - 0x16c]
  5e97e2: 50                           	push	eax
  5e97e3: 52                           	push	edx
  5e97e4: 51                           	push	ecx
  5e97e5: 56                           	push	esi
  5e97e6: 57                           	push	edi
  5e97e7: ff 75 b8                     	push	dword ptr [ebp - 0x48]
  5e97ea: 68 b8 78 c3 00               	push	0xc378b8
  5e97ef: 53                           	push	ebx
  5e97f0: ff 15 30 56 c2 00            	call	dword ptr [0xc25630]
  5e97f6: 83 c4 28                     	add	esp, 0x28
  5e97f9: 8b 75 08                     	mov	esi, dword ptr [ebp + 0x8]
  5e97fc: c7 46 18 0f 00 00 00         	mov	dword ptr [esi + 0x18], 0xf
  5e9803: 33 c0                        	xor	eax, eax
  5e9805: 89 46 14                     	mov	dword ptr [esi + 0x14], eax
  5e9808: 88 46 04                     	mov	byte ptr [esi + 0x4], al
  5e980b: 8b d3                        	mov	edx, ebx
  5e980d: 8b ca                        	mov	ecx, edx
  5e980f: 83 e2 f0                     	and	edx, -0x10
  5e9812: 66 0f ef c0                  	pxor	xmm0, xmm0
  5e9816: 66 0f 74 02                  	pcmpeqb	xmm0, xmmword ptr [edx]
  5e981a: 66 0f d7 c0                  	pmovmskb	eax, xmm0
  5e981e: 83 e1 0f                     	and	ecx, 0xf
  5e9821: d3 e8                        	shr	eax, cl
  5e9823: 0f bc c0                     	bsf	eax, eax
  5e9826: 75 09                        	jne	0x5e9831 <.text+0x1e8831>
  5e9828: 8b c2                        	mov	eax, edx
  5e982a: 03 d1                        	add	edx, ecx
  5e982c: e8 9f 7f 4a 00               	call	0xa917d0 <.text+0x6907d0>
  5e9831: 8b 4e 18                     	mov	ecx, dword ptr [esi + 0x18]
  5e9834: 89 75 e0                     	mov	dword ptr [ebp - 0x20], esi
  5e9837: 89 5d e4                     	mov	dword ptr [ebp - 0x1c], ebx
  5e983a: 83 f9 10                     	cmp	ecx, 0x10
  5e983d: 89 45 e8                     	mov	dword ptr [ebp - 0x18], eax
  5e9840: 72 05                        	jb	0x5e9847 <.text+0x1e8847>
  5e9842: 8b 56 04                     	mov	edx, dword ptr [esi + 0x4]
  5e9845: eb 03                        	jmp	0x5e984a <.text+0x1e884a>
  5e9847: 8d 56 04                     	lea	edx, [esi + 0x4]
  5e984a: 3b da                        	cmp	ebx, edx
  5e984c: 0f 83 22 03 00 00            	jae	0x5e9b74 <.text+0x1e8b74>
  5e9852: 33 d2                        	xor	edx, edx
  5e9854: 85 d2                        	test	edx, edx
  5e9856: 74 7a                        	je	0x5e98d2 <.text+0x1e88d2>
  5e9858: 83 f9 10                     	cmp	ecx, 0x10
  5e985b: 72 05                        	jb	0x5e9862 <.text+0x1e8862>
  5e985d: 8b 56 04                     	mov	edx, dword ptr [esi + 0x4]
  5e9860: eb 03                        	jmp	0x5e9865 <.text+0x1e8865>
  5e9862: 8d 56 04                     	lea	edx, [esi + 0x4]
  5e9865: 2b da                        	sub	ebx, edx
  5e9867: 8b 56 14                     	mov	edx, dword ptr [esi + 0x14]
  5e986a: 89 5d 98                     	mov	dword ptr [ebp - 0x68], ebx
  5e986d: 3b d3                        	cmp	edx, ebx
  5e986f: 72 0b                        	jb	0x5e987c <.text+0x1e887c>
  5e9871: 8b ca                        	mov	ecx, edx
  5e9873: 2b cb                        	sub	ecx, ebx
  5e9875: 3b c1                        	cmp	eax, ecx
  5e9877: 0f 42 c8                     	cmovb	ecx, eax
  5e987a: eb 1e                        	jmp	0x5e989a <.text+0x1e889a>
  5e987c: 89 45 94                     	mov	dword ptr [ebp - 0x6c], eax
  5e987f: ff 15 dc 53 c2 00            	call	dword ptr [0xc253dc]
  5e9885: 8b 45 94                     	mov	eax, dword ptr [ebp - 0x6c]
  5e9888: 8b 75 08                     	mov	esi, dword ptr [ebp + 0x8]
  5e988b: 8b 5d 98                     	mov	ebx, dword ptr [ebp - 0x68]
  5e988e: 8b 56 14                     	mov	edx, dword ptr [esi + 0x14]
  5e9891: 8b ca                        	mov	ecx, edx
  5e9893: 2b cb                        	sub	ecx, ebx
  5e9895: 3b c1                        	cmp	eax, ecx
  5e9897: 0f 42 c8                     	cmovb	ecx, eax
  5e989a: a1 d0 53 c2 00               	mov	eax, dword ptr [0xc253d0]
  5e989f: 8b 38                        	mov	edi, dword ptr [eax]
  5e98a1: 03 d9                        	add	ebx, ecx
  5e98a3: 3b d3                        	cmp	edx, ebx
  5e98a5: 73 0c                        	jae	0x5e98b3 <.text+0x1e88b3>
  5e98a7: ff 15 dc 53 c2 00            	call	dword ptr [0xc253dc]
  5e98ad: 8b 75 08                     	mov	esi, dword ptr [ebp + 0x8]
  5e98b0: 8b 56 14                     	mov	edx, dword ptr [esi + 0x14]
  5e98b3: 8b c2                        	mov	eax, edx
  5e98b5: 2b c3                        	sub	eax, ebx
  5e98b7: 3b c7                        	cmp	eax, edi
  5e98b9: 0f 42 f8                     	cmovb	edi, eax
  5e98bc: 85 ff                        	test	edi, edi
  5e98be: 0f 87 a3 00 00 00            	ja	0x5e9967 <.text+0x1e8967>
  5e98c4: 8b 5d 98                     	mov	ebx, dword ptr [ebp - 0x68]
  5e98c7: 3b d3                        	cmp	edx, ebx
  5e98c9: 0f 42 da                     	cmovb	ebx, edx
  5e98cc: 85 db                        	test	ebx, ebx
  5e98ce: 77 59                        	ja	0x5e9929 <.text+0x1e8929>
  5e98d0: eb 34                        	jmp	0x5e9906 <.text+0x1e8906>
  5e98d2: 89 45 d0                     	mov	dword ptr [ebp - 0x30], eax
  5e98d5: 83 f8 fe                     	cmp	eax, -0x2
  5e98d8: 76 12                        	jbe	0x5e98ec <.text+0x1e88ec>
  5e98da: 89 45 94                     	mov	dword ptr [ebp - 0x6c], eax
  5e98dd: ff 15 d4 53 c2 00            	call	dword ptr [0xc253d4]
  5e98e3: 8b 45 94                     	mov	eax, dword ptr [ebp - 0x6c]
  5e98e6: 8b 75 08                     	mov	esi, dword ptr [ebp + 0x8]
  5e98e9: 8b 4e 18                     	mov	ecx, dword ptr [esi + 0x18]
  5e98ec: 3b c8                        	cmp	ecx, eax
  5e98ee: 0f 82 24 01 00 00            	jb	0x5e9a18 <.text+0x1e8a18>
  5e98f4: 85 c0                        	test	eax, eax
  5e98f6: 0f 84 00 01 00 00            	je	0x5e99fc <.text+0x1e89fc>
  5e98fc: 83 7d d0 00                  	cmp	dword ptr [ebp - 0x30], 0x0
  5e9900: 0f 87 b1 00 00 00            	ja	0x5e99b7 <.text+0x1e89b7>
  5e9906: 8b 4d ec                     	mov	ecx, dword ptr [ebp - 0x14]
  5e9909: e8 b2 55 4a 00               	call	0xa8eec0 <.text+0x68dec0>
  5e990e: 8b 7d d4                     	mov	edi, dword ptr [ebp - 0x2c]
  5e9911: 8b 5d dc                     	mov	ebx, dword ptr [ebp - 0x24]
  5e9914: 8b c6                        	mov	eax, esi
  5e9916: 8b 75 d8                     	mov	esi, dword ptr [ebp - 0x28]
  5e9919: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  5e991c: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  5e9923: 8b e5                        	mov	esp, ebp
  5e9925: 5d                           	pop	ebp
  5e9926: c2 04 00                     	ret	0x4
  5e9929: 8b 4e 18                     	mov	ecx, dword ptr [esi + 0x18]
  5e992c: 83 f9 10                     	cmp	ecx, 0x10
  5e992f: 72 05                        	jb	0x5e9936 <.text+0x1e8936>
  5e9931: 8b 7e 04                     	mov	edi, dword ptr [esi + 0x4]
  5e9934: eb 03                        	jmp	0x5e9939 <.text+0x1e8939>
  5e9936: 8d 7e 04                     	lea	edi, [esi + 0x4]
  5e9939: 8d 04 3b                     	lea	eax, [ebx + edi]
  5e993c: 2b d3                        	sub	edx, ebx
  5e993e: 52                           	push	edx
  5e993f: 50                           	push	eax
  5e9940: 51                           	push	ecx
  5e9941: 57                           	push	edi
  5e9942: ff 15 f8 55 c2 00            	call	dword ptr [0xc255f8]
  5e9948: 83 c4 10                     	add	esp, 0x10
  5e994b: 8b 56 14                     	mov	edx, dword ptr [esi + 0x14]
  5e994e: 2b d3                        	sub	edx, ebx
  5e9950: 83 7e 18 10                  	cmp	dword ptr [esi + 0x18], 0x10
  5e9954: 89 56 14                     	mov	dword ptr [esi + 0x14], edx
  5e9957: 72 05                        	jb	0x5e995e <.text+0x1e895e>
  5e9959: 8b 46 04                     	mov	eax, dword ptr [esi + 0x4]
  5e995c: eb 03                        	jmp	0x5e9961 <.text+0x1e8961>
  5e995e: 8d 46 04                     	lea	eax, [esi + 0x4]
  5e9961: c6 04 10 00                  	mov	byte ptr [eax + edx], 0x0
  5e9965: eb 9f                        	jmp	0x5e9906 <.text+0x1e8906>
  5e9967: 8b 4e 18                     	mov	ecx, dword ptr [esi + 0x18]
  5e996a: 83 f9 10                     	cmp	ecx, 0x10
  5e996d: 72 05                        	jb	0x5e9974 <.text+0x1e8974>
  5e996f: 8b 56 04                     	mov	edx, dword ptr [esi + 0x4]
  5e9972: eb 03                        	jmp	0x5e9977 <.text+0x1e8977>
  5e9974: 8d 56 04                     	lea	edx, [esi + 0x4]
  5e9977: 89 75 94                     	mov	dword ptr [ebp - 0x6c], esi
  5e997a: 8d 34 13                     	lea	esi, [ebx + edx]
  5e997d: 2b cb                        	sub	ecx, ebx
  5e997f: 03 df                        	add	ebx, edi
  5e9981: 03 da                        	add	ebx, edx
  5e9983: 2b c7                        	sub	eax, edi
  5e9985: 50                           	push	eax
  5e9986: 53                           	push	ebx
  5e9987: 51                           	push	ecx
  5e9988: 56                           	push	esi
  5e9989: 8b 75 94                     	mov	esi, dword ptr [ebp - 0x6c]
  5e998c: ff 15 f8 55 c2 00            	call	dword ptr [0xc255f8]
  5e9992: 83 c4 10                     	add	esp, 0x10
  5e9995: 8b 56 14                     	mov	edx, dword ptr [esi + 0x14]
  5e9998: 2b d7                        	sub	edx, edi
  5e999a: 83 7e 18 10                  	cmp	dword ptr [esi + 0x18], 0x10
  5e999e: 89 56 14                     	mov	dword ptr [esi + 0x14], edx
  5e99a1: 72 05                        	jb	0x5e99a8 <.text+0x1e89a8>
  5e99a3: 8b 46 04                     	mov	eax, dword ptr [esi + 0x4]
  5e99a6: eb 03                        	jmp	0x5e99ab <.text+0x1e89ab>
  5e99a8: 8d 46 04                     	lea	eax, [esi + 0x4]
  5e99ab: c6 04 10 00                  	mov	byte ptr [eax + edx], 0x0
  5e99af: 8b 56 14                     	mov	edx, dword ptr [esi + 0x14]
  5e99b2: e9 0d ff ff ff               	jmp	0x5e98c4 <.text+0x1e88c4>
  5e99b7: 8b 4d e0                     	mov	ecx, dword ptr [ebp - 0x20]
  5e99ba: 8b 51 18                     	mov	edx, dword ptr [ecx + 0x18]
  5e99bd: 83 fa 10                     	cmp	edx, 0x10
  5e99c0: 72 05                        	jb	0x5e99c7 <.text+0x1e89c7>
  5e99c2: 8b 49 04                     	mov	ecx, dword ptr [ecx + 0x4]
  5e99c5: eb 03                        	jmp	0x5e99ca <.text+0x1e89ca>
  5e99c7: 83 c1 04                     	add	ecx, 0x4
  5e99ca: ff 75 e8                     	push	dword ptr [ebp - 0x18]
  5e99cd: ff 75 e4                     	push	dword ptr [ebp - 0x1c]
  5e99d0: 52                           	push	edx
  5e99d1: 51                           	push	ecx
  5e99d2: ff 15 00 56 c2 00            	call	dword ptr [0xc25600]
  5e99d8: 83 c4 10                     	add	esp, 0x10
  5e99db: 8b 55 e0                     	mov	edx, dword ptr [ebp - 0x20]
  5e99de: 83 7a 18 10                  	cmp	dword ptr [edx + 0x18], 0x10
  5e99e2: 8b 4d e8                     	mov	ecx, dword ptr [ebp - 0x18]
  5e99e5: 89 4a 14                     	mov	dword ptr [edx + 0x14], ecx
  5e99e8: 72 05                        	jb	0x5e99ef <.text+0x1e89ef>
  5e99ea: 8b 52 04                     	mov	edx, dword ptr [edx + 0x4]
  5e99ed: eb 03                        	jmp	0x5e99f2 <.text+0x1e89f2>
  5e99ef: 83 c2 04                     	add	edx, 0x4
  5e99f2: 33 c0                        	xor	eax, eax
  5e99f4: 88 04 0a                     	mov	byte ptr [edx + ecx], al
  5e99f7: e9 0a ff ff ff               	jmp	0x5e9906 <.text+0x1e8906>
  5e99fc: c7 46 14 00 00 00 00         	mov	dword ptr [esi + 0x14], 0x0
  5e9a03: 83 f9 10                     	cmp	ecx, 0x10
  5e9a06: 72 05                        	jb	0x5e9a0d <.text+0x1e8a0d>
  5e9a08: 8b 46 04                     	mov	eax, dword ptr [esi + 0x4]
  5e9a0b: eb 03                        	jmp	0x5e9a10 <.text+0x1e8a10>
  5e9a0d: 8d 46 04                     	lea	eax, [esi + 0x4]
  5e9a10: c6 00 00                     	mov	byte ptr [eax], 0x0
  5e9a13: e9 e4 fe ff ff               	jmp	0x5e98fc <.text+0x1e88fc>
  5e9a18: 8b 56 14                     	mov	edx, dword ptr [esi + 0x14]
  5e9a1b: 89 75 b0                     	mov	dword ptr [ebp - 0x50], esi
  5e9a1e: 8b f0                        	mov	esi, eax
  5e9a20: 89 45 a4                     	mov	dword ptr [ebp - 0x5c], eax
  5e9a23: 83 ce 0f                     	or	esi, 0xf
  5e9a26: 83 fe fe                     	cmp	esi, -0x2
  5e9a29: 89 55 b4                     	mov	dword ptr [ebp - 0x4c], edx
  5e9a2c: 0f 87 38 01 00 00            	ja	0x5e9b6a <.text+0x1e8b6a>
  5e9a32: 8b d9                        	mov	ebx, ecx
  5e9a34: d1 eb                        	shr	ebx
  5e9a36: b8 ab aa aa aa               	mov	eax, 0xaaaaaaab
  5e9a3b: f7 e6                        	mul	esi
  5e9a3d: d1 ea                        	shr	edx
  5e9a3f: 3b da                        	cmp	ebx, edx
  5e9a41: 77 05                        	ja	0x5e9a48 <.text+0x1e8a48>
  5e9a43: 89 75 a8                     	mov	dword ptr [ebp - 0x58], esi
  5e9a46: eb 11                        	jmp	0x5e9a59 <.text+0x1e8a59>
  5e9a48: 8b c3                        	mov	eax, ebx
  5e9a4a: f7 d8                        	neg	eax
  5e9a4c: 83 c0 fe                     	add	eax, -0x2
  5e9a4f: 3b c8                        	cmp	ecx, eax
  5e9a51: 77 f0                        	ja	0x5e9a43 <.text+0x1e8a43>
  5e9a53: 8d 34 19                     	lea	esi, [ecx + ebx]
  5e9a56: 89 75 a8                     	mov	dword ptr [ebp - 0x58], esi
  5e9a59: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  5e9a60: c7 45 ac 00 00 00 00         	mov	dword ptr [ebp - 0x54], 0x0
  5e9a67: 46                           	inc	esi
  5e9a68: 75 06                        	jne	0x5e9a70 <.text+0x1e8a70>
  5e9a6a: 33 c0                        	xor	eax, eax
  5e9a6c: 33 f6                        	xor	esi, esi
  5e9a6e: eb 36                        	jmp	0x5e9aa6 <.text+0x1e8aa6>
  5e9a70: 33 d2                        	xor	edx, edx
  5e9a72: b8 ff ff ff ff               	mov	eax, 0xffffffff
  5e9a77: f7 f6                        	div	esi
  5e9a79: 83 f8 01                     	cmp	eax, 0x1
  5e9a7c: 73 28                        	jae	0x5e9aa6 <.text+0x1e8aa6>
  5e9a7e: c7 45 a0 00 00 00 00         	mov	dword ptr [ebp - 0x60], 0x0
  5e9a85: 8d 5d 94                     	lea	ebx, [ebp - 0x6c]
  5e9a88: 8b cb                        	mov	ecx, ebx
  5e9a8a: 8d 45 a0                     	lea	eax, [ebp - 0x60]
  5e9a8d: 50                           	push	eax
  5e9a8e: ff 15 f0 55 c2 00            	call	dword ptr [0xc255f0]
  5e9a94: c7 45 94 20 a1 d3 00         	mov	dword ptr [ebp - 0x6c], 0xd3a120
  5e9a9b: 68 18 01 d7 00               	push	0xd70118
  5e9aa0: 53                           	push	ebx
  5e9aa1: e8 70 55 4a 00               	call	0xa8f016 <.text+0x68e016>
  5e9aa6: 50                           	push	eax
  5e9aa7: 89 34 24                     	mov	dword ptr [esp], esi
  5e9aaa: e8 5b 55 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5e9aaf: 59                           	pop	ecx
  5e9ab0: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5e9ab7: 89 45 ac                     	mov	dword ptr [ebp - 0x54], eax
  5e9aba: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5e9ac1: 8b 55 b4                     	mov	edx, dword ptr [ebp - 0x4c]
  5e9ac4: 85 d2                        	test	edx, edx
  5e9ac6: 77 79                        	ja	0x5e9b41 <.text+0x1e8b41>
  5e9ac8: 8b 75 b0                     	mov	esi, dword ptr [ebp - 0x50]
  5e9acb: 83 7e 18 10                  	cmp	dword ptr [esi + 0x18], 0x10
  5e9acf: 8b de                        	mov	ebx, esi
  5e9ad1: 73 60                        	jae	0x5e9b33 <.text+0x1e8b33>
  5e9ad3: 8b 4d ac                     	mov	ecx, dword ptr [ebp - 0x54]
  5e9ad6: 8b 55 a8                     	mov	edx, dword ptr [ebp - 0x58]
  5e9ad9: c7 43 18 0f 00 00 00         	mov	dword ptr [ebx + 0x18], 0xf
  5e9ae0: 33 c0                        	xor	eax, eax
  5e9ae2: 89 43 14                     	mov	dword ptr [ebx + 0x14], eax
  5e9ae5: 88 43 04                     	mov	byte ptr [ebx + 0x4], al
  5e9ae8: 8b 5d b4                     	mov	ebx, dword ptr [ebp - 0x4c]
  5e9aeb: 89 4e 04                     	mov	dword ptr [esi + 0x4], ecx
  5e9aee: 89 56 18                     	mov	dword ptr [esi + 0x18], edx
  5e9af1: 89 5e 14                     	mov	dword ptr [esi + 0x14], ebx
  5e9af4: 83 c6 04                     	add	esi, 0x4
  5e9af7: 83 fa 10                     	cmp	edx, 0x10
  5e9afa: 0f 43 f1                     	cmovae	esi, ecx
  5e9afd: 88 04 1e                     	mov	byte ptr [esi + ebx], al
  5e9b00: 8b 75 08                     	mov	esi, dword ptr [ebp + 0x8]
  5e9b03: e9 f4 fd ff ff               	jmp	0x5e98fc <.text+0x1e88fc>
  5e9b08: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
  5e9b0b: c7 45 fc 02 00 00 00         	mov	dword ptr [ebp - 0x4], 0x2
  5e9b12: 8b 45 a4                     	mov	eax, dword ptr [ebp - 0x5c]
  5e9b15: 8b 4d b0                     	mov	ecx, dword ptr [ebp - 0x50]
  5e9b18: 89 45 a8                     	mov	dword ptr [ebp - 0x58], eax
  5e9b1b: 40                           	inc	eax
  5e9b1c: 50                           	push	eax
  5e9b1d: ff 15 d8 53 c2 00            	call	dword ptr [0xc253d8]
  5e9b23: c7 45 fc 01 00 00 00         	mov	dword ptr [ebp - 0x4], 0x1
  5e9b2a: 89 45 ac                     	mov	dword ptr [ebp - 0x54], eax
  5e9b2d: b8 ba 9a 5e 00               	mov	eax, 0x5e9aba
  5e9b32: c3                           	ret
  5e9b33: ff 76 04                     	push	dword ptr [esi + 0x4]
  5e9b36: e8 57 54 4a 00               	call	0xa8ef92 <.text+0x68df92>
  5e9b3b: 59                           	pop	ecx
  5e9b3c: 8b 75 b0                     	mov	esi, dword ptr [ebp - 0x50]
  5e9b3f: eb 92                        	jmp	0x5e9ad3 <.text+0x1e8ad3>
  5e9b41: 8b 4d b0                     	mov	ecx, dword ptr [ebp - 0x50]
  5e9b44: 83 79 18 10                  	cmp	dword ptr [ecx + 0x18], 0x10
  5e9b48: 72 05                        	jb	0x5e9b4f <.text+0x1e8b4f>
  5e9b4a: 8b 49 04                     	mov	ecx, dword ptr [ecx + 0x4]
  5e9b4d: eb 03                        	jmp	0x5e9b52 <.text+0x1e8b52>
  5e9b4f: 83 c1 04                     	add	ecx, 0x4
  5e9b52: 8b 5d a8                     	mov	ebx, dword ptr [ebp - 0x58]
  5e9b55: 52                           	push	edx
  5e9b56: 43                           	inc	ebx
  5e9b57: 51                           	push	ecx
  5e9b58: 53                           	push	ebx
  5e9b59: ff 75 ac                     	push	dword ptr [ebp - 0x54]
  5e9b5c: ff 15 00 56 c2 00            	call	dword ptr [0xc25600]
  5e9b62: 83 c4 10                     	add	esp, 0x10
  5e9b65: e9 5e ff ff ff               	jmp	0x5e9ac8 <.text+0x1e8ac8>
  5e9b6a: 89 45 a8                     	mov	dword ptr [ebp - 0x58], eax
  5e9b6d: 8b f0                        	mov	esi, eax
  5e9b6f: e9 e5 fe ff ff               	jmp	0x5e9a59 <.text+0x1e8a59>
  5e9b74: 83 f9 10                     	cmp	ecx, 0x10
  5e9b77: 72 05                        	jb	0x5e9b7e <.text+0x1e8b7e>
  5e9b79: 8b 56 04                     	mov	edx, dword ptr [esi + 0x4]
  5e9b7c: eb 03                        	jmp	0x5e9b81 <.text+0x1e8b81>
  5e9b7e: 8d 56 04                     	lea	edx, [esi + 0x4]
  5e9b81: 03 56 14                     	add	edx, dword ptr [esi + 0x14]
  5e9b84: 3b d3                        	cmp	edx, ebx
  5e9b86: 0f 86 c6 fc ff ff            	jbe	0x5e9852 <.text+0x1e8852>
  5e9b8c: ba 01 00 00 00               	mov	edx, 0x1
  5e9b91: e9 be fc ff ff               	jmp	0x5e9854 <.text+0x1e8854>
  5e9b96: 90                           	nop
  5e9b97: 90                           	nop
  5e9b98: 90                           	nop
  5e9b99: 90                           	nop
  5e9b9a: 90                           	nop
  5e9b9b: 90                           	nop
  5e9b9c: 90                           	nop
  5e9b9d: 90                           	nop
  5e9b9e: 90                           	nop
  5e9b9f: 90                           	nop
  5e9ba0: 53                           	push	ebx
  5e9ba1: 8b dc                        	mov	ebx, esp
  5e9ba3: 83 e4 f8                     	and	esp, -0x8
  5e9ba6: 55                           	push	ebp
  5e9ba7: 55                           	push	ebp
  5e9ba8: 8b 6b 04                     	mov	ebp, dword ptr [ebx + 0x4]
  5e9bab: 89 6c 24 04                  	mov	dword ptr [esp + 0x4], ebp
  5e9baf: 8b ec                        	mov	ebp, esp
  5e9bb1: 6a ff                        	push	-0x1
  5e9bb3: 68 60 d7 bf 00               	push	0xbfd760
  5e9bb8: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  5e9bbe: 50                           	push	eax
  5e9bbf: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  5e9bc6: 81 ec ac 00 00 00            	sub	esp, 0xac
  5e9bcc: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
  5e9bcf: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  5e9bd2: 89 7d ac                     	mov	dword ptr [ebp - 0x54], edi
  5e9bd5: 89 75 b4                     	mov	dword ptr [ebp - 0x4c], esi
  5e9bd8: a1 10 53 d8 00               	mov	eax, dword ptr [0xd85310]
  5e9bdd: 89 4d 84                     	mov	dword ptr [ebp - 0x7c], ecx
  5e9be0: 89 45 bc                     	mov	dword ptr [ebp - 0x44], eax
  5e9be3: b9 e0 ac 02 01               	mov	ecx, 0x102ace0
  5e9be8: e8 d3 52 eb ff               	call	0x49eec0 <.text+0x9dec0>
  5e9bed: 0f b6 c0                     	movzx	eax, al
  5e9bf0: 85 c0                        	test	eax, eax
  5e9bf2: 74 19                        	je	0x5e9c0d <.text+0x1e8c0d>
  5e9bf4: 8b 4d bc                     	mov	ecx, dword ptr [ebp - 0x44]
  5e9bf7: e8 c4 52 4a 00               	call	0xa8eec0 <.text+0x68dec0>
  5e9bfc: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  5e9bff: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  5e9c06: 8b e5                        	mov	esp, ebp
  5e9c08: 5d                           	pop	ebp
  5e9c09: 8b e3                        	mov	esp, ebx
  5e9c0b: 5b                           	pop	ebx
  5e9c0c: c3                           	ret
  5e9c0d: e8 de 27 fb ff               	call	0x59c3f0 <.text+0x19b3f0>
  5e9c12: dd 5d e0                     	fstp	qword ptr [ebp - 0x20]
  5e9c15: 8d 75 c8                     	lea	esi, [ebp - 0x38]
  5e9c18: 8d 45 e0                     	lea	eax, [ebp - 0x20]
  5e9c1b: 50                           	push	eax
  5e9c1c: 56                           	push	esi
  5e9c1d: e8 ee 47 e3 ff               	call	0x41e410 <.text+0x1d410>
  5e9c22: 83 c4 08                     	add	esp, 0x8
  5e9c25: 0f be 05 60 0e d7 00         	movsx	eax, byte ptr [0xd70e60]
  5e9c2c: 83 f8 0a                     	cmp	eax, 0xa
  5e9c2f: 0f 87 16 01 00 00            	ja	0x5e9d4b <.text+0x1e8d4b>
  5e9c35: 8b 04 85 f4 76 c3 00         	mov	eax, dword ptr [4*eax + 0xc376f4]
  5e9c3c: ff e0                        	jmp	eax
  5e9c3e: f2 0f 2a 45 c8               	cvtsi2sd	xmm0, dword ptr [ebp - 0x38]
  5e9c43: f2 0f 58 05 78 75 c3 00      	addsd	xmm0, qword ptr [0xc37578]
  5e9c4b: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e9c4f: 89 45 c8                     	mov	dword ptr [ebp - 0x38], eax
  5e9c52: e9 f4 00 00 00               	jmp	0x5e9d4b <.text+0x1e8d4b>
  5e9c57: f2 0f 2a 45 c8               	cvtsi2sd	xmm0, dword ptr [ebp - 0x38]
  5e9c5c: f2 0f 58 05 68 75 c3 00      	addsd	xmm0, qword ptr [0xc37568]
  5e9c64: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e9c68: 89 45 c8                     	mov	dword ptr [ebp - 0x38], eax
  5e9c6b: e9 db 00 00 00               	jmp	0x5e9d4b <.text+0x1e8d4b>
  5e9c70: f2 0f 2a 45 c8               	cvtsi2sd	xmm0, dword ptr [ebp - 0x38]
  5e9c75: f2 0f 58 05 60 75 c3 00      	addsd	xmm0, qword ptr [0xc37560]
  5e9c7d: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e9c81: 89 45 c8                     	mov	dword ptr [ebp - 0x38], eax
  5e9c84: e9 c2 00 00 00               	jmp	0x5e9d4b <.text+0x1e8d4b>
  5e9c89: 0f be 7d cc                  	movsx	edi, byte ptr [ebp - 0x34]
  5e9c8d: f2 0f 2a c7                  	cvtsi2sd	xmm0, edi
  5e9c91: f2 0f 58 05 60 75 c3 00      	addsd	xmm0, qword ptr [0xc37560]
  5e9c99: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e9c9d: 88 45 cc                     	mov	byte ptr [ebp - 0x34], al
  5e9ca0: e9 a6 00 00 00               	jmp	0x5e9d4b <.text+0x1e8d4b>
  5e9ca5: 0f be 7d cd                  	movsx	edi, byte ptr [ebp - 0x33]
  5e9ca9: f2 0f 2a c7                  	cvtsi2sd	xmm0, edi
  5e9cad: f2 0f 58 05 70 75 c3 00      	addsd	xmm0, qword ptr [0xc37570]
  5e9cb5: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e9cb9: 88 45 cd                     	mov	byte ptr [ebp - 0x33], al
  5e9cbc: e9 8a 00 00 00               	jmp	0x5e9d4b <.text+0x1e8d4b>
  5e9cc1: 0f be 7d cd                  	movsx	edi, byte ptr [ebp - 0x33]
  5e9cc5: f2 0f 2a c7                  	cvtsi2sd	xmm0, edi
  5e9cc9: f2 0f 58 05 60 75 c3 00      	addsd	xmm0, qword ptr [0xc37560]
  5e9cd1: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e9cd5: 88 45 cd                     	mov	byte ptr [ebp - 0x33], al
  5e9cd8: eb 71                        	jmp	0x5e9d4b <.text+0x1e8d4b>
  5e9cda: 0f be 7d ce                  	movsx	edi, byte ptr [ebp - 0x32]
  5e9cde: f2 0f 2a c7                  	cvtsi2sd	xmm0, edi
  5e9ce2: f2 0f 58 05 60 75 c3 00      	addsd	xmm0, qword ptr [0xc37560]
  5e9cea: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e9cee: 88 45 ce                     	mov	byte ptr [ebp - 0x32], al
  5e9cf1: eb 58                        	jmp	0x5e9d4b <.text+0x1e8d4b>
  5e9cf3: 0f be 7d cf                  	movsx	edi, byte ptr [ebp - 0x31]
  5e9cf7: f2 0f 2a c7                  	cvtsi2sd	xmm0, edi
  5e9cfb: f2 0f 58 05 68 75 c3 00      	addsd	xmm0, qword ptr [0xc37568]
  5e9d03: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e9d07: 88 45 cf                     	mov	byte ptr [ebp - 0x31], al
  5e9d0a: eb 3f                        	jmp	0x5e9d4b <.text+0x1e8d4b>
  5e9d0c: 0f be 7d cf                  	movsx	edi, byte ptr [ebp - 0x31]
  5e9d10: f2 0f 2a c7                  	cvtsi2sd	xmm0, edi
  5e9d14: f2 0f 58 05 60 75 c3 00      	addsd	xmm0, qword ptr [0xc37560]
  5e9d1c: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  5e9d20: 88 45 cf                     	mov	byte ptr [ebp - 0x31], al
  5e9d23: eb 26                        	jmp	0x5e9d4b <.text+0x1e8d4b>
  5e9d25: f2 0f 10 05 68 75 c3 00      	movsd	xmm0, qword ptr [0xc37568]
  5e9d2d: f2 0f 58 45 d0               	addsd	xmm0, qword ptr [ebp - 0x30]
  5e9d32: f2 0f 11 45 d0               	movsd	qword ptr [ebp - 0x30], xmm0
  5e9d37: eb 12                        	jmp	0x5e9d4b <.text+0x1e8d4b>
  5e9d39: f2 0f 10 05 60 75 c3 00      	movsd	xmm0, qword ptr [0xc37560]
  5e9d41: f2 0f 58 45 d0               	addsd	xmm0, qword ptr [ebp - 0x30]
  5e9d46: f2 0f 11 45 d0               	movsd	qword ptr [ebp - 0x30], xmm0
  5e9d4b: 6a 00                        	push	0x0
  5e9d4d: e8 6e b3 e9 ff               	call	0x4850c0 <.text+0x840c0>
  5e9d52: 59                           	pop	ecx
  5e9d53: 80 3d 60 0e d7 00 0b         	cmp	byte ptr [0xd70e60], 0xb
  5e9d5a: 0f 84 c6 05 00 00            	je	0x5ea326 <.text+0x1e9326>
  5e9d60: 56                           	push	esi
  5e9d61: e8 1a 44 e3 ff               	call	0x41e180 <.text+0x1d180>
  5e9d66: dd 5d d8                     	fstp	qword ptr [ebp - 0x28]
  5e9d69: 8d 45 d8                     	lea	eax, [ebp - 0x28]
  5e9d6c: 50                           	push	eax
  5e9d6d: e8 1e d2 e9 ff               	call	0x486f90 <.text+0x85f90>
  5e9d72: 83 c4 08                     	add	esp, 0x8
  5e9d75: e8 46 c5 fd ff               	call	0x5c62c0 <.text+0x1c52c0>
  5e9d7a: 8b c8                        	mov	ecx, eax
  5e9d7c: e8 5f c6 fd ff               	call	0x5c63e0 <.text+0x1c53e0>
  5e9d81: 0f b6 c0                     	movzx	eax, al
  5e9d84: 85 c0                        	test	eax, eax
  5e9d86: 74 13                        	je	0x5e9d9b <.text+0x1e8d9b>
  5e9d88: e8 33 c5 fd ff               	call	0x5c62c0 <.text+0x1c52c0>
  5e9d8d: 8b c8                        	mov	ecx, eax
  5e9d8f: e8 dc ca fd ff               	call	0x5c6870 <.text+0x1c5870>
  5e9d94: 0f b6 c0                     	movzx	eax, al
  5e9d97: 85 c0                        	test	eax, eax
  5e9d99: 74 2b                        	je	0x5e9dc6 <.text+0x1e8dc6>
  5e9d9b: e8 d0 e6 fe ff               	call	0x5d8470 <.text+0x1d7470>
  5e9da0: 8b c8                        	mov	ecx, eax
  5e9da2: e8 39 ee fe ff               	call	0x5d8be0 <.text+0x1d7be0>
  5e9da7: 8b 4d bc                     	mov	ecx, dword ptr [ebp - 0x44]
  5e9daa: e8 11 51 4a 00               	call	0xa8eec0 <.text+0x68dec0>
  5e9daf: 8b 7d ac                     	mov	edi, dword ptr [ebp - 0x54]
  5e9db2: 8b 75 b4                     	mov	esi, dword ptr [ebp - 0x4c]
  5e9db5: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  5e9db8: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  5e9dbf: 8b e5                        	mov	esp, ebp
  5e9dc1: 5d                           	pop	ebp
  5e9dc2: 8b e3                        	mov	esp, ebx
  5e9dc4: 5b                           	pop	ebx
  5e9dc5: c3                           	ret
  5e9dc6: e8 b5 88 47 00               	call	0xa62680 <.text+0x661680>
  5e9dcb: 8b f8                        	mov	edi, eax
  5e9dcd: c7 85 60 ff ff ff 0f 00 00 00	mov	dword ptr [ebp - 0xa0], 0xf
  5e9dd7: 8d b5 4c ff ff ff            	lea	esi, [ebp - 0xb4]
  5e9ddd: 33 c0                        	xor	eax, eax
  5e9ddf: b9 a4 78 c3 00               	mov	ecx, 0xc378a4
  5e9de4: c7 45 b8 0d 00 00 00         	mov	dword ptr [ebp - 0x48], 0xd
  5e9deb: 89 85 5c ff ff ff            	mov	dword ptr [ebp - 0xa4], eax
  5e9df1: 88 06                        	mov	byte ptr [esi], al
  5e9df3: 8b 85 60 ff ff ff            	mov	eax, dword ptr [ebp - 0xa0]
  5e9df9: 8d 95 48 ff ff ff            	lea	edx, [ebp - 0xb8]
  5e9dff: 89 55 98                     	mov	dword ptr [ebp - 0x68], edx
  5e9e02: 8b 95 4c ff ff ff            	mov	edx, dword ptr [ebp - 0xb4]
  5e9e08: 89 4d b0                     	mov	dword ptr [ebp - 0x50], ecx
  5e9e0b: 83 f8 10                     	cmp	eax, 0x10
  5e9e0e: 0f 42 d6                     	cmovb	edx, esi
  5e9e11: 3b ca                        	cmp	ecx, edx
  5e9e13: 0f 83 e0 04 00 00            	jae	0x5ea2f9 <.text+0x1e92f9>
  5e9e19: 33 d2                        	xor	edx, edx
  5e9e1b: 85 d2                        	test	edx, edx
  5e9e1d: 0f 84 b1 00 00 00            	je	0x5e9ed4 <.text+0x1e8ed4>
  5e9e23: 83 f8 10                     	cmp	eax, 0x10
  5e9e26: 8d 85 4c ff ff ff            	lea	eax, [ebp - 0xb4]
  5e9e2c: 0f 43 85 4c ff ff ff         	cmovae	eax, dword ptr [ebp - 0xb4]
  5e9e33: be a4 78 c3 00               	mov	esi, 0xc378a4
  5e9e38: 2b f0                        	sub	esi, eax
  5e9e3a: 8b 85 5c ff ff ff            	mov	eax, dword ptr [ebp - 0xa4]
  5e9e40: 89 b5 78 ff ff ff            	mov	dword ptr [ebp - 0x88], esi
  5e9e46: 3b c6                        	cmp	eax, esi
  5e9e48: 72 11                        	jb	0x5e9e5b <.text+0x1e8e5b>
  5e9e4a: 8b d0                        	mov	edx, eax
  5e9e4c: 2b d6                        	sub	edx, esi
  5e9e4e: b9 0d 00 00 00               	mov	ecx, 0xd
  5e9e53: 83 fa 0d                     	cmp	edx, 0xd
  5e9e56: 0f 47 d1                     	cmova	edx, ecx
  5e9e59: eb 21                        	jmp	0x5e9e7c <.text+0x1e8e7c>
  5e9e5b: ff 15 dc 53 c2 00            	call	dword ptr [0xc253dc]
  5e9e61: 8b 85 5c ff ff ff            	mov	eax, dword ptr [ebp - 0xa4]
  5e9e67: 8b b5 78 ff ff ff            	mov	esi, dword ptr [ebp - 0x88]
  5e9e6d: 8b d0                        	mov	edx, eax
  5e9e6f: 2b d6                        	sub	edx, esi
  5e9e71: b9 0d 00 00 00               	mov	ecx, 0xd
  5e9e76: 83 fa 0d                     	cmp	edx, 0xd
  5e9e79: 0f 47 d1                     	cmova	edx, ecx
  5e9e7c: 03 f2                        	add	esi, edx
  5e9e7e: 8b 15 d0 53 c2 00            	mov	edx, dword ptr [0xc253d0]
  5e9e84: 8b 0a                        	mov	ecx, dword ptr [edx]
  5e9e86: 89 8d 70 ff ff ff            	mov	dword ptr [ebp - 0x90], ecx
  5e9e8c: 3b c6                        	cmp	eax, esi
  5e9e8e: 73 0c                        	jae	0x5e9e9c <.text+0x1e8e9c>
  5e9e90: ff 15 dc 53 c2 00            	call	dword ptr [0xc253dc]
  5e9e96: 8b 85 5c ff ff ff            	mov	eax, dword ptr [ebp - 0xa4]
  5e9e9c: 8b 8d 70 ff ff ff            	mov	ecx, dword ptr [ebp - 0x90]
  5e9ea2: 8b d0                        	mov	edx, eax
  5e9ea4: 2b d6                        	sub	edx, esi
  5e9ea6: 3b d1                        	cmp	edx, ecx
  5e9ea8: 0f 42 ca                     	cmovb	ecx, edx
  5e9eab: 89 8d 70 ff ff ff            	mov	dword ptr [ebp - 0x90], ecx
  5e9eb1: 85 c9                        	test	ecx, ecx
  5e9eb3: 0f 87 93 01 00 00            	ja	0x5ea04c <.text+0x1e904c>
  5e9eb9: 8b 95 78 ff ff ff            	mov	edx, dword ptr [ebp - 0x88]
  5e9ebf: 3b c2                        	cmp	eax, edx
  5e9ec1: 0f 42 d0                     	cmovb	edx, eax
  5e9ec4: 85 d2                        	test	edx, edx
  5e9ec6: 89 95 64 ff ff ff            	mov	dword ptr [ebp - 0x9c], edx
  5e9ecc: 0f 87 0e 01 00 00            	ja	0x5e9fe0 <.text+0x1e8fe0>
  5e9ed2: eb 1a                        	jmp	0x5e9eee <.text+0x1e8eee>
  5e9ed4: c7 45 90 0d 00 00 00         	mov	dword ptr [ebp - 0x70], 0xd
  5e9edb: 83 f8 0d                     	cmp	eax, 0xd
  5e9ede: 0f 82 88 02 00 00            	jb	0x5ea16c <.text+0x1e916c>
  5e9ee4: 83 7d 90 00                  	cmp	dword ptr [ebp - 0x70], 0x0
  5e9ee8: 0f 87 39 02 00 00            	ja	0x5ea127 <.text+0x1e9127>
  5e9eee: c7 45 fc 04 00 00 00         	mov	dword ptr [ebp - 0x4], 0x4
  5e9ef5: 8b 4d 84                     	mov	ecx, dword ptr [ebp - 0x7c]
  5e9ef8: 8d b5 64 ff ff ff            	lea	esi, [ebp - 0x9c]
  5e9efe: 56                           	push	esi
  5e9eff: e8 7c f8 ff ff               	call	0x5e9780 <.text+0x1e8780>
  5e9f04: c7 45 fc 05 00 00 00         	mov	dword ptr [ebp - 0x4], 0x5
  5e9f0b: 8d 45 80                     	lea	eax, [ebp - 0x80]
  5e9f0e: 8d 95 48 ff ff ff            	lea	edx, [ebp - 0xb8]
  5e9f14: 83 c4 f4                     	add	esp, -0xc
  5e9f17: 89 04 24                     	mov	dword ptr [esp], eax
  5e9f1a: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  5e9f1e: 89 74 24 08                  	mov	dword ptr [esp + 0x8], esi
  5e9f22: ff 15 f0 53 c2 00            	call	dword ptr [0xc253f0]
  5e9f28: 83 c4 0c                     	add	esp, 0xc
  5e9f2b: c7 45 fc 06 00 00 00         	mov	dword ptr [ebp - 0x4], 0x6
  5e9f32: 8d 55 80                     	lea	edx, [ebp - 0x80]
  5e9f35: 83 c4 e4                     	add	esp, -0x1c
  5e9f38: 8b c4                        	mov	eax, esp
  5e9f3a: 83 c4 f4                     	add	esp, -0xc
  5e9f3d: 89 04 24                     	mov	dword ptr [esp], eax
  5e9f40: c7 44 24 08 b4 78 c3 00      	mov	dword ptr [esp + 0x8], 0xc378b4
  5e9f48: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  5e9f4c: ff 15 c0 53 c2 00            	call	dword ptr [0xc253c0]
  5e9f52: 83 c4 0c                     	add	esp, 0xc
  5e9f55: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5e9f5c: 8b cf                        	mov	ecx, edi
  5e9f5e: e8 6d 6b 47 00               	call	0xa60ad0 <.text+0x65fad0>
  5e9f63: c7 45 fc 05 00 00 00         	mov	dword ptr [ebp - 0x4], 0x5
  5e9f6a: 83 7d 98 10                  	cmp	dword ptr [ebp - 0x68], 0x10
  5e9f6e: 0f 83 a5 01 00 00            	jae	0x5ea119 <.text+0x1e9119>
  5e9f74: c7 45 fc 04 00 00 00         	mov	dword ptr [ebp - 0x4], 0x4
  5e9f7b: 33 c0                        	xor	eax, eax
  5e9f7d: 83 bd 7c ff ff ff 10         	cmp	dword ptr [ebp - 0x84], 0x10
  5e9f84: 89 45 94                     	mov	dword ptr [ebp - 0x6c], eax
  5e9f87: c7 45 98 0f 00 00 00         	mov	dword ptr [ebp - 0x68], 0xf
  5e9f8e: 88 45 84                     	mov	byte ptr [ebp - 0x7c], al
  5e9f91: 0f 83 71 01 00 00            	jae	0x5ea108 <.text+0x1e9108>
  5e9f97: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5e9f9e: 33 c0                        	xor	eax, eax
  5e9fa0: 83 bd 60 ff ff ff 10         	cmp	dword ptr [ebp - 0xa0], 0x10
  5e9fa7: 89 85 78 ff ff ff            	mov	dword ptr [ebp - 0x88], eax
  5e9fad: c7 85 7c ff ff ff 0f 00 00 00	mov	dword ptr [ebp - 0x84], 0xf
  5e9fb7: 88 85 68 ff ff ff            	mov	byte ptr [ebp - 0x98], al
  5e9fbd: 0f 83 34 01 00 00            	jae	0x5ea0f7 <.text+0x1e90f7>
  5e9fc3: c7 85 60 ff ff ff 0f 00 00 00	mov	dword ptr [ebp - 0xa0], 0xf
  5e9fcd: 33 c0                        	xor	eax, eax
  5e9fcf: 89 85 5c ff ff ff            	mov	dword ptr [ebp - 0xa4], eax
  5e9fd5: 88 85 4c ff ff ff            	mov	byte ptr [ebp - 0xb4], al
  5e9fdb: e9 bb fd ff ff               	jmp	0x5e9d9b <.text+0x1e8d9b>
  5e9fe0: 8b 8d 60 ff ff ff            	mov	ecx, dword ptr [ebp - 0xa0]
  5e9fe6: 83 f9 10                     	cmp	ecx, 0x10
  5e9fe9: 72 08                        	jb	0x5e9ff3 <.text+0x1e8ff3>
  5e9feb: 8b 95 4c ff ff ff            	mov	edx, dword ptr [ebp - 0xb4]
  5e9ff1: eb 06                        	jmp	0x5e9ff9 <.text+0x1e8ff9>
  5e9ff3: 8d 95 4c ff ff ff            	lea	edx, [ebp - 0xb4]
  5e9ff9: 8b b5 64 ff ff ff            	mov	esi, dword ptr [ebp - 0x9c]
  5e9fff: 89 bd 6c ff ff ff            	mov	dword ptr [ebp - 0x94], edi
  5ea005: 8d 3c 16                     	lea	edi, [esi + edx]
  5ea008: 2b c6                        	sub	eax, esi
  5ea00a: 50                           	push	eax
  5ea00b: 57                           	push	edi
  5ea00c: 8b bd 6c ff ff ff            	mov	edi, dword ptr [ebp - 0x94]
  5ea012: 51                           	push	ecx
  5ea013: 52                           	push	edx
  5ea014: ff 15 f8 55 c2 00            	call	dword ptr [0xc255f8]
  5ea01a: 83 c4 10                     	add	esp, 0x10
  5ea01d: 83 bd 60 ff ff ff 10         	cmp	dword ptr [ebp - 0xa0], 0x10
  5ea024: 8b 95 5c ff ff ff            	mov	edx, dword ptr [ebp - 0xa4]
  5ea02a: 8d 85 4c ff ff ff            	lea	eax, [ebp - 0xb4]
  5ea030: 0f 43 85 4c ff ff ff         	cmovae	eax, dword ptr [ebp - 0xb4]
  5ea037: 2b 95 64 ff ff ff            	sub	edx, dword ptr [ebp - 0x9c]
  5ea03d: 89 95 5c ff ff ff            	mov	dword ptr [ebp - 0xa4], edx
  5ea043: c6 04 10 00                  	mov	byte ptr [eax + edx], 0x0
  5ea047: e9 a2 fe ff ff               	jmp	0x5e9eee <.text+0x1e8eee>
  5ea04c: 8b 85 60 ff ff ff            	mov	eax, dword ptr [ebp - 0xa0]
  5ea052: 89 85 64 ff ff ff            	mov	dword ptr [ebp - 0x9c], eax
  5ea058: 83 f8 10                     	cmp	eax, 0x10
  5ea05b: 72 08                        	jb	0x5ea065 <.text+0x1e9065>
  5ea05d: 8b 85 4c ff ff ff            	mov	eax, dword ptr [ebp - 0xb4]
  5ea063: eb 06                        	jmp	0x5ea06b <.text+0x1e906b>
  5ea065: 8d 85 4c ff ff ff            	lea	eax, [ebp - 0xb4]
  5ea06b: 89 bd 6c ff ff ff            	mov	dword ptr [ebp - 0x94], edi
  5ea071: 8b f9                        	mov	edi, ecx
  5ea073: 8d 0c 06                     	lea	ecx, [esi + eax]
  5ea076: 2b d7                        	sub	edx, edi
  5ea078: 89 8d 68 ff ff ff            	mov	dword ptr [ebp - 0x98], ecx
  5ea07e: 8b 8d 64 ff ff ff            	mov	ecx, dword ptr [ebp - 0x9c]
  5ea084: 52                           	push	edx
  5ea085: 2b ce                        	sub	ecx, esi
  5ea087: 03 f7                        	add	esi, edi
  5ea089: 8b bd 6c ff ff ff            	mov	edi, dword ptr [ebp - 0x94]
  5ea08f: 03 f0                        	add	esi, eax
  5ea091: 56                           	push	esi
  5ea092: 51                           	push	ecx
  5ea093: ff b5 68 ff ff ff            	push	dword ptr [ebp - 0x98]
  5ea099: ff 15 f8 55 c2 00            	call	dword ptr [0xc255f8]
  5ea09f: 83 c4 10                     	add	esp, 0x10
  5ea0a2: 83 bd 60 ff ff ff 10         	cmp	dword ptr [ebp - 0xa0], 0x10
  5ea0a9: 8b 95 5c ff ff ff            	mov	edx, dword ptr [ebp - 0xa4]
  5ea0af: 8d 85 4c ff ff ff            	lea	eax, [ebp - 0xb4]
  5ea0b5: 0f 43 85 4c ff ff ff         	cmovae	eax, dword ptr [ebp - 0xb4]
  5ea0bc: 2b 95 70 ff ff ff            	sub	edx, dword ptr [ebp - 0x90]
  5ea0c2: 89 95 5c ff ff ff            	mov	dword ptr [ebp - 0xa4], edx
  5ea0c8: c6 04 10 00                  	mov	byte ptr [eax + edx], 0x0
  5ea0cc: 8b 85 5c ff ff ff            	mov	eax, dword ptr [ebp - 0xa4]
  5ea0d2: e9 e2 fd ff ff               	jmp	0x5e9eb9 <.text+0x1e8eb9>
  5ea0d7: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5ea0da: 8d 8d 48 ff ff ff            	lea	ecx, [ebp - 0xb8]
  5ea0e0: ff 15 bc 53 c2 00            	call	dword ptr [0xc253bc]
  5ea0e6: c3                           	ret
  5ea0e7: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5ea0ea: 8d 8d 64 ff ff ff            	lea	ecx, [ebp - 0x9c]
  5ea0f0: ff 15 bc 53 c2 00            	call	dword ptr [0xc253bc]
  5ea0f6: c3                           	ret
  5ea0f7: ff b5 4c ff ff ff            	push	dword ptr [ebp - 0xb4]
  5ea0fd: e8 90 4e 4a 00               	call	0xa8ef92 <.text+0x68df92>
  5ea102: 59                           	pop	ecx
  5ea103: e9 bb fe ff ff               	jmp	0x5e9fc3 <.text+0x1e8fc3>
  5ea108: ff b5 68 ff ff ff            	push	dword ptr [ebp - 0x98]
  5ea10e: e8 7f 4e 4a 00               	call	0xa8ef92 <.text+0x68df92>
  5ea113: 59                           	pop	ecx
  5ea114: e9 7e fe ff ff               	jmp	0x5e9f97 <.text+0x1e8f97>
  5ea119: ff 75 84                     	push	dword ptr [ebp - 0x7c]
  5ea11c: e8 71 4e 4a 00               	call	0xa8ef92 <.text+0x68df92>
  5ea121: 59                           	pop	ecx
  5ea122: e9 4d fe ff ff               	jmp	0x5e9f74 <.text+0x1e8f74>
  5ea127: 8b 4d 98                     	mov	ecx, dword ptr [ebp - 0x68]
  5ea12a: 8b 51 18                     	mov	edx, dword ptr [ecx + 0x18]
  5ea12d: 83 fa 10                     	cmp	edx, 0x10
  5ea130: 72 05                        	jb	0x5ea137 <.text+0x1e9137>
  5ea132: 8b 49 04                     	mov	ecx, dword ptr [ecx + 0x4]
  5ea135: eb 03                        	jmp	0x5ea13a <.text+0x1e913a>
  5ea137: 83 c1 04                     	add	ecx, 0x4
  5ea13a: ff 75 b8                     	push	dword ptr [ebp - 0x48]
  5ea13d: ff 75 b0                     	push	dword ptr [ebp - 0x50]
  5ea140: 52                           	push	edx
  5ea141: 51                           	push	ecx
  5ea142: ff 15 00 56 c2 00            	call	dword ptr [0xc25600]
  5ea148: 83 c4 10                     	add	esp, 0x10
  5ea14b: 8b 55 98                     	mov	edx, dword ptr [ebp - 0x68]
  5ea14e: 83 7a 18 10                  	cmp	dword ptr [edx + 0x18], 0x10
  5ea152: 8b 4d b8                     	mov	ecx, dword ptr [ebp - 0x48]
  5ea155: 89 4a 14                     	mov	dword ptr [edx + 0x14], ecx
  5ea158: 72 05                        	jb	0x5ea15f <.text+0x1e915f>
  5ea15a: 8b 52 04                     	mov	edx, dword ptr [edx + 0x4]
  5ea15d: eb 03                        	jmp	0x5ea162 <.text+0x1e9162>
  5ea15f: 83 c2 04                     	add	edx, 0x4
  5ea162: 33 c0                        	xor	eax, eax
  5ea164: 88 04 0a                     	mov	byte ptr [edx + ecx], al
  5ea167: e9 82 fd ff ff               	jmp	0x5e9eee <.text+0x1e8eee>
  5ea16c: 8b 8d 5c ff ff ff            	mov	ecx, dword ptr [ebp - 0xa4]
  5ea172: c7 45 88 0d 00 00 00         	mov	dword ptr [ebp - 0x78], 0xd
  5ea179: 8b f0                        	mov	esi, eax
  5ea17b: d1 ee                        	shr	esi
  5ea17d: 8d 95 48 ff ff ff            	lea	edx, [ebp - 0xb8]
  5ea183: 89 55 80                     	mov	dword ptr [ebp - 0x80], edx
  5ea186: 89 8d 78 ff ff ff            	mov	dword ptr [ebp - 0x88], ecx
  5ea18c: b9 0f 00 00 00               	mov	ecx, 0xf
  5ea191: 83 fe 05                     	cmp	esi, 0x5
  5ea194: 77 0c                        	ja	0x5ea1a2 <.text+0x1e91a2>
  5ea196: c7 85 68 ff ff ff 0f 00 00 00	mov	dword ptr [ebp - 0x98], 0xf
  5ea1a0: eb 14                        	jmp	0x5ea1b6 <.text+0x1e91b6>
  5ea1a2: 8b d6                        	mov	edx, esi
  5ea1a4: f7 da                        	neg	edx
  5ea1a6: 83 c2 fe                     	add	edx, -0x2
  5ea1a9: 3b c2                        	cmp	eax, edx
  5ea1ab: 77 e9                        	ja	0x5ea196 <.text+0x1e9196>
  5ea1ad: 8d 0c 30                     	lea	ecx, [eax + esi]
  5ea1b0: 89 8d 68 ff ff ff            	mov	dword ptr [ebp - 0x98], ecx
  5ea1b6: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  5ea1bd: c7 85 70 ff ff ff 00 00 00 00	mov	dword ptr [ebp - 0x90], 0x0
  5ea1c7: 41                           	inc	ecx
  5ea1c8: 75 04                        	jne	0x5ea1ce <.text+0x1e91ce>
  5ea1ca: 33 c9                        	xor	ecx, ecx
  5ea1cc: eb 36                        	jmp	0x5ea204 <.text+0x1e9204>
  5ea1ce: 33 d2                        	xor	edx, edx
  5ea1d0: b8 ff ff ff ff               	mov	eax, 0xffffffff
  5ea1d5: f7 f1                        	div	ecx
  5ea1d7: 83 f8 01                     	cmp	eax, 0x1
  5ea1da: 73 28                        	jae	0x5ea204 <.text+0x1e9204>
  5ea1dc: c7 45 a8 00 00 00 00         	mov	dword ptr [ebp - 0x58], 0x0
  5ea1e3: 8d 75 9c                     	lea	esi, [ebp - 0x64]
  5ea1e6: 8b ce                        	mov	ecx, esi
  5ea1e8: 8d 45 a8                     	lea	eax, [ebp - 0x58]
  5ea1eb: 50                           	push	eax
  5ea1ec: ff 15 f0 55 c2 00            	call	dword ptr [0xc255f0]
  5ea1f2: c7 45 9c 20 a1 d3 00         	mov	dword ptr [ebp - 0x64], 0xd3a120
  5ea1f9: 68 18 01 d7 00               	push	0xd70118
  5ea1fe: 56                           	push	esi
  5ea1ff: e8 12 4e 4a 00               	call	0xa8f016 <.text+0x68e016>
  5ea204: 50                           	push	eax
  5ea205: 89 0c 24                     	mov	dword ptr [esp], ecx
  5ea208: e8 fd 4d 4a 00               	call	0xa8f00a <.text+0x68e00a>
  5ea20d: 59                           	pop	ecx
  5ea20e: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5ea215: 89 85 70 ff ff ff            	mov	dword ptr [ebp - 0x90], eax
  5ea21b: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  5ea222: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5ea225: 8b 95 78 ff ff ff            	mov	edx, dword ptr [ebp - 0x88]
  5ea22b: 85 d2                        	test	edx, edx
  5ea22d: 0f 87 97 00 00 00            	ja	0x5ea2ca <.text+0x1e92ca>
  5ea233: 8b 45 80                     	mov	eax, dword ptr [ebp - 0x80]
  5ea236: 83 78 18 10                  	cmp	dword ptr [eax + 0x18], 0x10
  5ea23a: 8b f0                        	mov	esi, eax
  5ea23c: 73 7b                        	jae	0x5ea2b9 <.text+0x1e92b9>
  5ea23e: 8b 8d 68 ff ff ff            	mov	ecx, dword ptr [ebp - 0x98]
  5ea244: c7 46 18 0f 00 00 00         	mov	dword ptr [esi + 0x18], 0xf
  5ea24b: 33 d2                        	xor	edx, edx
  5ea24d: 89 56 14                     	mov	dword ptr [esi + 0x14], edx
  5ea250: 89 bd 6c ff ff ff            	mov	dword ptr [ebp - 0x94], edi
  5ea256: 8b bd 78 ff ff ff            	mov	edi, dword ptr [ebp - 0x88]
  5ea25c: 88 56 04                     	mov	byte ptr [esi + 0x4], dl
  5ea25f: 8b b5 70 ff ff ff            	mov	esi, dword ptr [ebp - 0x90]
  5ea265: 89 70 04                     	mov	dword ptr [eax + 0x4], esi
  5ea268: 89 48 18                     	mov	dword ptr [eax + 0x18], ecx
  5ea26b: 89 78 14                     	mov	dword ptr [eax + 0x14], edi
  5ea26e: 83 c0 04                     	add	eax, 0x4
  5ea271: 83 f9 10                     	cmp	ecx, 0x10
  5ea274: 0f 43 c6                     	cmovae	eax, esi
  5ea277: 88 14 38                     	mov	byte ptr [eax + edi], dl
  5ea27a: 8b bd 6c ff ff ff            	mov	edi, dword ptr [ebp - 0x94]
  5ea280: e9 5f fc ff ff               	jmp	0x5e9ee4 <.text+0x1e8ee4>
  5ea285: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
  5ea288: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  5ea28b: c7 45 fc 02 00 00 00         	mov	dword ptr [ebp - 0x4], 0x2
  5ea292: 8b 45 88                     	mov	eax, dword ptr [ebp - 0x78]
  5ea295: 8b 4d 80                     	mov	ecx, dword ptr [ebp - 0x80]
  5ea298: 89 85 68 ff ff ff            	mov	dword ptr [ebp - 0x98], eax
  5ea29e: 40                           	inc	eax
  5ea29f: 50                           	push	eax
  5ea2a0: ff 15 d8 53 c2 00            	call	dword ptr [0xc253d8]
  5ea2a6: c7 45 fc 01 00 00 00         	mov	dword ptr [ebp - 0x4], 0x1
  5ea2ad: 89 85 70 ff ff ff            	mov	dword ptr [ebp - 0x90], eax
  5ea2b3: b8 1b a2 5e 00               	mov	eax, 0x5ea21b
  5ea2b8: c3                           	ret
  5ea2b9: ff 70 04                     	push	dword ptr [eax + 0x4]
  5ea2bc: e8 d1 4c 4a 00               	call	0xa8ef92 <.text+0x68df92>
  5ea2c1: 59                           	pop	ecx
  5ea2c2: 8b 45 80                     	mov	eax, dword ptr [ebp - 0x80]
  5ea2c5: e9 74 ff ff ff               	jmp	0x5ea23e <.text+0x1e923e>
  5ea2ca: 8b 4d 80                     	mov	ecx, dword ptr [ebp - 0x80]
  5ea2cd: 83 79 18 10                  	cmp	dword ptr [ecx + 0x18], 0x10
  5ea2d1: 72 05                        	jb	0x5ea2d8 <.text+0x1e92d8>
  5ea2d3: 8b 49 04                     	mov	ecx, dword ptr [ecx + 0x4]
  5ea2d6: eb 03                        	jmp	0x5ea2db <.text+0x1e92db>
  5ea2d8: 83 c1 04                     	add	ecx, 0x4
  5ea2db: 8b b5 68 ff ff ff            	mov	esi, dword ptr [ebp - 0x98]
  5ea2e1: 52                           	push	edx
  5ea2e2: 46                           	inc	esi
  5ea2e3: 51                           	push	ecx
  5ea2e4: 56                           	push	esi
  5ea2e5: ff b5 70 ff ff ff            	push	dword ptr [ebp - 0x90]
  5ea2eb: ff 15 00 56 c2 00            	call	dword ptr [0xc25600]
  5ea2f1: 83 c4 10                     	add	esp, 0x10
  5ea2f4: e9 3a ff ff ff               	jmp	0x5ea233 <.text+0x1e9233>
  5ea2f9: 8d 95 4c ff ff ff            	lea	edx, [ebp - 0xb4]
  5ea2ff: 83 f8 10                     	cmp	eax, 0x10
  5ea302: 0f 43 95 4c ff ff ff         	cmovae	edx, dword ptr [ebp - 0xb4]
  5ea309: 03 95 5c ff ff ff            	add	edx, dword ptr [ebp - 0xa4]
  5ea30f: b9 a4 78 c3 00               	mov	ecx, 0xc378a4
  5ea314: 3b d1                        	cmp	edx, ecx
  5ea316: 0f 86 fd fa ff ff            	jbe	0x5e9e19 <.text+0x1e8e19>
  5ea31c: ba 01 00 00 00               	mov	edx, 0x1
  5ea321: e9 f5 fa ff ff               	jmp	0x5e9e1b <.text+0x1e8e1b>
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
  5ea440: 8b e5                        	mov	esp, ebp
  5ea442: 5d                           	pop	ebp
  5ea443: c3                           	ret
  5ea444: e8 37 82 47 00               	call	0xa62680 <.text+0x661680>
  5ea449: 8b f0                        	mov	esi, eax
  5ea44b: c7 85 74 ff ff ff 0f 00 00 00	mov	dword ptr [ebp - 0x8c], 0xf
  5ea455: 8d 85 60 ff ff ff            	lea	eax, [ebp - 0xa0]
  5ea45b: 33 db                        	xor	ebx, ebx
  5ea45d: b9 a4 78 c3 00               	mov	ecx, 0xc378a4
  5ea462: c7 45 98 0d 00 00 00         	mov	dword ptr [ebp - 0x68], 0xd
  5ea469: 89 9d 70 ff ff ff            	mov	dword ptr [ebp - 0x90], ebx
  5ea46f: 88 18                        	mov	byte ptr [eax], bl
  5ea471: 8b bd 60 ff ff ff            	mov	edi, dword ptr [ebp - 0xa0]
  5ea477: 8d 95 5c ff ff ff            	lea	edx, [ebp - 0xa4]
  5ea47d: 89 55 90                     	mov	dword ptr [ebp - 0x70], edx
  5ea480: 8b 95 74 ff ff ff            	mov	edx, dword ptr [ebp - 0x8c]
  5ea486: 89 4d 94                     	mov	dword ptr [ebp - 0x6c], ecx
  5ea489: 83 fa 10                     	cmp	edx, 0x10
  5ea48c: 0f 42 f8                     	cmovb	edi, eax
  5ea48f: 3b cf                        	cmp	ecx, edi
  5ea491: 0f 83 68 04 00 00            	jae	0x5ea8ff <.text+0x1e98ff>
  5ea497: 8b c3                        	mov	eax, ebx
  5ea499: 85 c0                        	test	eax, eax
  5ea49b: 0f 84 97 00 00 00            	je	0x5ea538 <.text+0x1e9538>
  5ea4a1: 8d 85 60 ff ff ff            	lea	eax, [ebp - 0xa0]
  5ea4a7: 83 fa 10                     	cmp	edx, 0x10
  5ea4aa: 0f 43 85 60 ff ff ff         	cmovae	eax, dword ptr [ebp - 0xa0]
  5ea4b1: 2b c8                        	sub	ecx, eax
  5ea4b3: 8b 85 70 ff ff ff            	mov	eax, dword ptr [ebp - 0x90]
  5ea4b9: 3b c1                        	cmp	eax, ecx
  5ea4bb: 89 4d 80                     	mov	dword ptr [ebp - 0x80], ecx
  5ea4be: 72 11                        	jb	0x5ea4d1 <.text+0x1e94d1>
  5ea4c0: 8b d0                        	mov	edx, eax
  5ea4c2: 2b d1                        	sub	edx, ecx
  5ea4c4: bf 0d 00 00 00               	mov	edi, 0xd
  5ea4c9: 83 fa 0d                     	cmp	edx, 0xd
  5ea4cc: 0f 47 d7                     	cmova	edx, edi
  5ea4cf: eb 1e                        	jmp	0x5ea4ef <.text+0x1e94ef>
  5ea4d1: ff 15 dc 53 c2 00            	call	dword ptr [0xc253dc]
  5ea4d7: 8b 85 70 ff ff ff            	mov	eax, dword ptr [ebp - 0x90]
  5ea4dd: 8b 4d 80                     	mov	ecx, dword ptr [ebp - 0x80]
  5ea4e0: 8b d0                        	mov	edx, eax
  5ea4e2: 2b d1                        	sub	edx, ecx
  5ea4e4: bf 0d 00 00 00               	mov	edi, 0xd
  5ea4e9: 83 fa 0d                     	cmp	edx, 0xd
  5ea4ec: 0f 47 d7                     	cmova	edx, edi
  5ea4ef: 03 ca                        	add	ecx, edx
  5ea4f1: 8b 15 d0 53 c2 00            	mov	edx, dword ptr [0xc253d0]
  5ea4f7: 8b 3a                        	mov	edi, dword ptr [edx]
  5ea4f9: 3b c1                        	cmp	eax, ecx
  5ea4fb: 73 18                        	jae	0x5ea515 <.text+0x1e9515>
  5ea4fd: 89 8d 78 ff ff ff            	mov	dword ptr [ebp - 0x88], ecx
