
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  511804: e8 07 74 0d 00               	call	0x5e8c10 <.text+0x1e7c10>
  511809: 8b c8                        	mov	ecx, eax
  51180b: e8 10 b1 0d 00               	call	0x5ec920 <.text+0x1eb920>
  511810: 8b d8                        	mov	ebx, eax
  511812: b9 e0 ac 02 01               	mov	ecx, 0x102ace0
  511817: e8 a4 d6 f8 ff               	call	0x49eec0 <.text+0x9dec0>
  51181c: 0f b6 c0                     	movzx	eax, al
  51181f: 85 c0                        	test	eax, eax
  511821: 0f 85 e1 00 00 00            	jne	0x511908 <.text+0x110908>
  511827: e8 94 4a 0b 00               	call	0x5c62c0 <.text+0x1c52c0>
  51182c: 8b c8                        	mov	ecx, eax
  51182e: e8 dd 4b 0b 00               	call	0x5c6410 <.text+0x1c5410>
  511833: 0f b6 c0                     	movzx	eax, al
  511836: 85 c0                        	test	eax, eax
  511838: 74 17                        	je	0x511851 <.text+0x110851>
  51183a: e8 81 4a 0b 00               	call	0x5c62c0 <.text+0x1c52c0>
  51183f: 8b c8                        	mov	ecx, eax
  511841: e8 2a 50 0b 00               	call	0x5c6870 <.text+0x1c5870>
  511846: 0f b6 c0                     	movzx	eax, al
  511849: 85 c0                        	test	eax, eax
  51184b: 0f 85 b7 00 00 00            	jne	0x511908 <.text+0x110908>
  511851: 0f b6 05 44 1b 08 01         	movzx	eax, byte ptr [0x1081b44]
  511858: 85 c0                        	test	eax, eax
  51185a: 74 41                        	je	0x51189d <.text+0x11089d>
  51185c: 0f b6 05 80 19 d7 00         	movzx	eax, byte ptr [0xd71980]
  511863: 85 c0                        	test	eax, eax
  511865: 75 1c                        	jne	0x511883 <.text+0x110883>
  511867: f2 0f 10 44 24 20            	movsd	xmm0, qword ptr [esp + 0x20]
  51186d: f2 0f 5c 05 a8 1a 08 01      	subsd	xmm0, qword ptr [0x1081aa8]
  511875: 66 0f 2f 05 e0 0e c3 00      	comisd	xmm0, qword ptr [0xc30ee0]
  51187d: 0f 86 85 00 00 00            	jbe	0x511908 <.text+0x110908>
  511883: c6 05 80 19 d7 00 00         	mov	byte ptr [0xd71980], 0x0
  51188a: e8 b1 37 f7 ff               	call	0x485040 <.text+0x84040>
  51188f: e8 dc 6b 0c 00               	call	0x5d8470 <.text+0x1d7470>
  511894: 8b c8                        	mov	ecx, eax
  511896: e8 45 73 0c 00               	call	0x5d8be0 <.text+0x1d7be0>
  51189b: eb 58                        	jmp	0x5118f5 <.text+0x1108f5>
  51189d: 85 db                        	test	ebx, ebx
  51189f: 75 12                        	jne	0x5118b3 <.text+0x1108b3>
  5118a1: f2 0f 10 05 e8 0e c3 00      	movsd	xmm0, qword ptr [0xc30ee8]
  5118a9: f2 0f 11 05 a8 1a 08 01      	movsd	qword ptr [0x1081aa8], xmm0
  5118b1: eb 55                        	jmp	0x511908 <.text+0x110908>
  5118b3: e8 38 ab 08 00               	call	0x59c3f0 <.text+0x19b3f0>
  5118b8: dd 5c 24 08                  	fstp	qword ptr [esp + 0x8]
  5118bc: f2 0f 10 4c 24 08            	movsd	xmm1, qword ptr [esp + 0x8]
  5118c2: f2 0f 2a d3                  	cvtsi2sd	xmm2, ebx
  5118c6: f2 0f 59 15 c0 90 fe 00      	mulsd	xmm2, qword ptr [0xfe90c0]
  5118ce: f2 0f 10 44 24 20            	movsd	xmm0, qword ptr [esp + 0x20]
  5118d4: f2 0f 5c 05 a8 1a 08 01      	subsd	xmm0, qword ptr [0x1081aa8]
  5118dc: f2 0f 59 d0                  	mulsd	xmm2, xmm0
  5118e0: f2 0f 58 d1                  	addsd	xmm2, xmm1
  5118e4: f2 0f 11 54 24 08            	movsd	qword ptr [esp + 0x8], xmm2
  5118ea: 8d 44 24 08                  	lea	eax, [esp + 0x8]
  5118ee: 50                           	push	eax
  5118ef: e8 9c 56 f7 ff               	call	0x486f90 <.text+0x85f90>
  5118f4: 59                           	pop	ecx
  5118f5: f2 0f 10 44 24 20            	movsd	xmm0, qword ptr [esp + 0x20]
  5118fb: f2 0f 11 05 a8 1a 08 01      	movsd	qword ptr [0x1081aa8], xmm0
  511903: bf 01 00 00 00               	mov	edi, 0x1
  511908: 8b 15 3c 1b 08 01            	mov	edx, dword ptr [0x1081b3c]
  51190e: 89 15 b0 1a 08 01            	mov	dword ptr [0x1081ab0], edx
  511914: 8b c7                        	mov	eax, edi
  511916: 83 c4 28                     	add	esp, 0x28
  511919: 5b                           	pop	ebx
  51191a: 5f                           	pop	edi
  51191b: 8b e5                        	mov	esp, ebp
  51191d: 5d                           	pop	ebp
  51191e: c3                           	ret
