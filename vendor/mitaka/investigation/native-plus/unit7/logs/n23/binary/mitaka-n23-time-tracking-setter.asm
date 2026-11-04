
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  5114b0: 0f b6 44 24 04               	movzx	eax, byte ptr [esp + 0x4]
  5114b5: a2 44 1b 08 01               	mov	byte ptr [0x1081b44], al
  5114ba: c3                           	ret
  5114bb: 90                           	nop
  5114bc: 8d 74 26 00                  	lea	esi, [esi + eiz]
  5114c0: 0f b6 05 44 1b 08 01         	movzx	eax, byte ptr [0x1081b44]
  5114c7: c3                           	ret
  5114c8: 90                           	nop
  5114c9: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  5114d0: 55                           	push	ebp
  5114d1: 8b ec                        	mov	ebp, esp
  5114d3: 83 e4 f8                     	and	esp, -0x8
  5114d6: 57                           	push	edi
  5114d7: 53                           	push	ebx
  5114d8: 83 ec 28                     	sub	esp, 0x28
  5114db: ff 15 bc 56 c2 00            	call	dword ptr [0xc256bc]
  5114e1: e8 8a df 0b 00               	call	0x5cf470 <.text+0x1ce470>
  5114e6: 8b c8                        	mov	ecx, eax
  5114e8: e8 a3 62 0c 00               	call	0x5d7790 <.text+0x1d6790>
  5114ed: dd 5c 24 08                  	fstp	qword ptr [esp + 0x8]
  5114f1: f2 0f 10 44 24 08            	movsd	xmm0, qword ptr [esp + 0x8]
  5114f7: f2 0f 5a c0                  	cvtsd2ss	xmm0, xmm0
  5114fb: f3 0f 5e 05 08 0f c3 00      	divss	xmm0, dword ptr [0xc30f08]
  511503: 80 3d 60 93 fe 00 01         	cmp	byte ptr [0xfe9360], 0x1
  51150a: f3 0f 11 05 94 19 d7 00      	movss	dword ptr [0xd71994], xmm0
  511512: 0f 84 07 04 00 00            	je	0x51191f <.text+0x11091f>
  511518: a1 f8 1a 08 01               	mov	eax, dword ptr [0x1081af8]
  51151d: 83 c4 f8                     	add	esp, -0x8
  511520: f3 0f 11 04 24               	movss	dword ptr [esp], xmm0
  511525: b9 b4 1a 08 01               	mov	ecx, 0x1081ab4
  51152a: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  51152e: e8 9d b0 08 00               	call	0x59c5d0 <.text+0x19b5d0>
  511533: d9 5c 24 10                  	fstp	dword ptr [esp + 0x10]
  511537: ff 35 f4 1a 08 01            	push	dword ptr [0x1081af4]
  51153d: ff 35 94 19 d7 00            	push	dword ptr [0xd71994]
  511543: b9 c4 1a 08 01               	mov	ecx, 0x1081ac4
  511548: e8 83 b0 08 00               	call	0x59c5d0 <.text+0x19b5d0>
  51154d: d9 5c 24 08                  	fstp	dword ptr [esp + 0x8]
  511551: f3 0f 10 5c 24 08            	movss	xmm3, dword ptr [esp + 0x8]
  511557: f2 0f 10 15 d0 0e c3 00      	movsd	xmm2, qword ptr [0xc30ed0]
  51155f: f3 0f 10 44 24 10            	movss	xmm0, dword ptr [esp + 0x10]
  511565: 0f 54 05 c0 0e c3 00         	andps	xmm0, xmmword ptr [0xc30ec0]
  51156c: f3 0f 5a c8                  	cvtss2sd	xmm1, xmm0
  511570: f2 0f 11 54 24 20            	movsd	qword ptr [esp + 0x20], xmm2
  511576: 66 0f 2f ca                  	comisd	xmm1, xmm2
  51157a: 77 1a                        	ja	0x511596 <.text+0x110596>
  51157c: 0f 54 1d c0 0e c3 00         	andps	xmm3, xmmword ptr [0xc30ec0]
  511583: f3 0f 5a c3                  	cvtss2sd	xmm0, xmm3
  511587: 66 0f 2f 44 24 20            	comisd	xmm0, qword ptr [esp + 0x20]
  51158d: 77 07                        	ja	0x511596 <.text+0x110596>
  51158f: 33 ff                        	xor	edi, edi
  511591: e9 a2 00 00 00               	jmp	0x511638 <.text+0x110638>
  511596: e8 05 22 03 00               	call	0x5437a0 <.text+0x1427a0>
  51159b: d9 5c 24 14                  	fstp	dword ptr [esp + 0x14]
  51159f: e8 0c 22 03 00               	call	0x5437b0 <.text+0x1427b0>
  5115a4: d9 5c 24 08                  	fstp	dword ptr [esp + 0x8]
  5115a8: f3 0f 10 64 24 08            	movss	xmm4, dword ptr [esp + 0x8]
  5115ae: f3 0f 58 25 d0 1a 08 01      	addss	xmm4, dword ptr [0x1081ad0]
  5115b6: f3 0f 10 44 24 14            	movss	xmm0, dword ptr [esp + 0x14]
  5115bc: f3 0f 58 05 c0 1a 08 01      	addss	xmm0, dword ptr [0x1081ac0]
  5115c4: 0f 28 d8                     	movaps	xmm3, xmm0
  5115c7: 66 0f ef d2                  	pxor	xmm2, xmm2
  5115cb: f3 0f 10 0d 0c 0f c3 00      	movss	xmm1, dword ptr [0xc30f0c]
  5115d3: 0f 2f c1                     	comiss	xmm0, xmm1
  5115d6: f3 0f 10 2d 10 0f c3 00      	movss	xmm5, dword ptr [0xc30f10]
  5115de: f3 0f 5c d9                  	subss	xmm3, xmm1
  5115e2: 77 03                        	ja	0x5115e7 <.text+0x1105e7>
  5115e4: 0f 28 d8                     	movaps	xmm3, xmm0
  5115e7: 0f 2f d3                     	comiss	xmm2, xmm3
  5115ea: 8d 5c 24 18                  	lea	ebx, [esp + 0x18]
  5115ee: f3 0f 58 cb                  	addss	xmm1, xmm3
  5115f2: f3 0f 5d ec                  	minss	xmm5, xmm4
  5115f6: 77 03                        	ja	0x5115fb <.text+0x1105fb>
  5115f8: 0f 28 cb                     	movaps	xmm1, xmm3
  5115fb: f3 0f 5a f1                  	cvtss2sd	xmm6, xmm1
  5115ff: f2 0f 11 74 24 18            	movsd	qword ptr [esp + 0x18], xmm6
  511605: 66 0f ef e4                  	pxor	xmm4, xmm4
  511609: f3 0f 5f e5                  	maxss	xmm4, xmm5
  51160d: f3 0f 11 64 24 10            	movss	dword ptr [esp + 0x10], xmm4
  511613: 53                           	push	ebx
  511614: e8 a7 21 03 00               	call	0x5437c0 <.text+0x1427c0>
  511619: f3 0f 5a 44 24 14            	cvtss2sd	xmm0, dword ptr [esp + 0x14]
  51161f: f2 0f 11 44 24 1c            	movsd	qword ptr [esp + 0x1c], xmm0
  511625: 53                           	push	ebx
  511626: e8 b5 21 03 00               	call	0x5437e0 <.text+0x1427e0>
  51162b: 83 c4 08                     	add	esp, 0x8
  51162e: e8 4d 33 f7 ff               	call	0x484980 <.text+0x83980>
  511633: bf 01 00 00 00               	mov	edi, 0x1
  511638: ff 35 fc 1a 08 01            	push	dword ptr [0x1081afc]
  51163e: 68 8f c2 75 3c               	push	0x3c75c28f
  511643: b9 d4 1a 08 01               	mov	ecx, 0x1081ad4
  511648: e8 83 af 08 00               	call	0x59c5d0 <.text+0x19b5d0>
  51164d: d9 5c 24 08                  	fstp	dword ptr [esp + 0x8]
  511651: f3 0f 10 44 24 08            	movss	xmm0, dword ptr [esp + 0x8]
  511657: 0f 54 05 c0 0e c3 00         	andps	xmm0, xmmword ptr [0xc30ec0]
  51165e: f3 0f 5a c0                  	cvtss2sd	xmm0, xmm0
