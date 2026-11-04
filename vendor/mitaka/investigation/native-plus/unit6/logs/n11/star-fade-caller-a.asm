
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  472080: 38 03                        	cmp	byte ptr [ebx], al
  472082: 00 00                        	add	byte ptr [eax], al
  472084: f2 0f 11 82 38 03 00 00      	movsd	qword ptr [edx + 0x338], xmm0
  47208c: f2 0f 10 8e 40 03 00 00      	movsd	xmm1, qword ptr [esi + 0x340]
  472094: f2 0f 11 8a 40 03 00 00      	movsd	qword ptr [edx + 0x340], xmm1
  47209c: 0f b6 86 48 03 00 00         	movzx	eax, byte ptr [esi + 0x348]
  4720a3: 88 82 48 03 00 00            	mov	byte ptr [edx + 0x348], al
  4720a9: e8 32 15 00 00               	call	0x4735e0 <.text+0x725e0>
  4720ae: 81 c4 50 03 00 00            	add	esp, 0x350
  4720b4: ff 15 98 7a c2 00            	call	dword ptr [0xc27a98]
  4720ba: f2 0f 2a c0                  	cvtsi2sd	xmm0, eax
  4720be: c1 e8 1f                     	shr	eax, 0x1f
  4720c1: f2 0f 58 04 c5 80 b7 c2 00   	addsd	xmm0, qword ptr [8*eax + 0xc2b780]
  4720ca: f2 0f 5e 44 24 18            	divsd	xmm0, qword ptr [esp + 0x18]
  4720d0: f2 0f 11 05 98 90 fe 00      	movsd	qword ptr [0xfe9098], xmm0
  4720d8: ff 15 08 59 c2 00            	call	dword ptr [0xc25908]
  4720de: 83 c4 34                     	add	esp, 0x34
  4720e1: 5b                           	pop	ebx
  4720e2: 5e                           	pop	esi
  4720e3: 5f                           	pop	edi
  4720e4: 8b e5                        	mov	esp, ebp
  4720e6: 5d                           	pop	ebp
  4720e7: c3                           	ret
  4720e8: 8b 44 8b 60                  	mov	eax, dword ptr [ebx + 4*ecx + 0x60]
  4720ec: 89 44 8f 60                  	mov	dword ptr [edi + 4*ecx + 0x60], eax
  4720f0: 41                           	inc	ecx
  4720f1: 83 f9 12                     	cmp	ecx, 0x12
  4720f4: 72 f2                        	jb	0x4720e8 <.text+0x710e8>
  4720f6: e9 c2 f5 ff ff               	jmp	0x4716bd <.text+0x706bd>
  4720fb: 8b c8                        	mov	ecx, eax
  4720fd: 89 b4 24 50 03 00 00         	mov	dword ptr [esp + 0x350], esi
  472104: 8b b4 24 64 03 00 00         	mov	esi, dword ptr [esp + 0x364]
  47210b: 8b 44 8f 60                  	mov	eax, dword ptr [edi + 4*ecx + 0x60]
  47210f: 89 44 8e 60                  	mov	dword ptr [esi + 4*ecx + 0x60], eax
  472113: 41                           	inc	ecx
  472114: 83 f9 12                     	cmp	ecx, 0x12
  472117: 72 f2                        	jb	0x47210b <.text+0x7110b>
  472119: e9 f4 f7 ff ff               	jmp	0x471912 <.text+0x70912>
  47211e: 89 b4 24 50 03 00 00         	mov	dword ptr [esp + 0x350], esi
  472125: 8b 74 8b 60                  	mov	esi, dword ptr [ebx + 4*ecx + 0x60]
  472129: 89 74 88 60                  	mov	dword ptr [eax + 4*ecx + 0x60], esi
  47212d: 41                           	inc	ecx
  47212e: 83 f9 12                     	cmp	ecx, 0x12
  472131: 72 f2                        	jb	0x472125 <.text+0x71125>
  472133: e9 f9 fb ff ff               	jmp	0x471d31 <.text+0x70d31>
  472138: 8b d8                        	mov	ebx, eax
  47213a: 8b 44 9f 60                  	mov	eax, dword ptr [edi + 4*ebx + 0x60]
  47213e: 89 44 99 60                  	mov	dword ptr [ecx + 4*ebx + 0x60], eax
  472142: 43                           	inc	ebx
  472143: 83 fb 12                     	cmp	ebx, 0x12
  472146: 72 f2                        	jb	0x47213a <.text+0x7113a>
  472148: e9 9e fd ff ff               	jmp	0x471eeb <.text+0x70eeb>
  47214d: 8d 76 00                     	lea	esi, [esi]
  472150: 53                           	push	ebx
  472151: 8b dc                        	mov	ebx, esp
  472153: 83 e4 c0                     	and	esp, -0x40
  472156: 55                           	push	ebp
  472157: 55                           	push	ebp
  472158: 8b 6b 04                     	mov	ebp, dword ptr [ebx + 0x4]
  47215b: 89 6c 24 04                  	mov	dword ptr [esp + 0x4], ebp
  47215f: 8b ec                        	mov	ebp, esp
  472161: 6a ff                        	push	-0x1
  472163: 68 20 38 bf 00               	push	0xbf3820
  472168: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  47216e: 50                           	push	eax
  47216f: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  472176: 83 ec 6c                     	sub	esp, 0x6c
  472179: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  47217c: 89 7d b8                     	mov	dword ptr [ebp - 0x48], edi
  47217f: 89 75 bc                     	mov	dword ptr [ebp - 0x44], esi
  472182: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  472189: 8b 93 10 02 00 00            	mov	edx, dword ptr [ebx + 0x210]
  47218f: 8b 8b 14 02 00 00            	mov	ecx, dword ptr [ebx + 0x214]
  472195: 8d 45 a0                     	lea	eax, [ebp - 0x60]
  472198: 83 c4 f4                     	add	esp, -0xc
  47219b: 89 04 24                     	mov	dword ptr [esp], eax
  47219e: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  4721a2: 89 4c 24 08                  	mov	dword ptr [esp + 0x8], ecx
  4721a6: e8 85 e1 0e 00               	call	0x560330 <.text+0x15f330>
  4721ab: 83 c4 0c                     	add	esp, 0xc
  4721ae: 8b 45 a0                     	mov	eax, dword ptr [ebp - 0x60]
  4721b1: 8b 55 a4                     	mov	edx, dword ptr [ebp - 0x5c]
  4721b4: 8b 4d a8                     	mov	ecx, dword ptr [ebp - 0x58]
  4721b7: 8b 75 ac                     	mov	esi, dword ptr [ebp - 0x54]
  4721ba: 8b 7d b0                     	mov	edi, dword ptr [ebp - 0x50]
  4721bd: c6 83 50 03 00 00 00         	mov	byte ptr [ebx + 0x350], 0x0
  4721c4: 89 83 18 02 00 00            	mov	dword ptr [ebx + 0x218], eax
  4721ca: 8b 45 b4                     	mov	eax, dword ptr [ebp - 0x4c]
  4721cd: 89 93 1c 02 00 00            	mov	dword ptr [ebx + 0x21c], edx
  4721d3: 89 8b 20 02 00 00            	mov	dword ptr [ebx + 0x220], ecx
  4721d9: 50                           	push	eax
  4721da: 89 b3 24 02 00 00            	mov	dword ptr [ebx + 0x224], esi
  4721e0: 89 bb 28 02 00 00            	mov	dword ptr [ebx + 0x228], edi
  4721e6: 89 83 2c 02 00 00            	mov	dword ptr [ebx + 0x22c], eax
  4721ec: 8d 93 18 02 00 00            	lea	edx, [ebx + 0x218]
  4721f2: 89 14 24                     	mov	dword ptr [esp], edx
  4721f5: e8 c6 ac fc ff               	call	0x43cec0 <.text+0x3bec0>
  4721fa: 59                           	pop	ecx
  4721fb: 68 00 17 00 00               	push	0x1700
  472200: ff 15 c4 58 c2 00            	call	dword ptr [0xc258c4]
  472206: 8d 83 40 02 00 00            	lea	eax, [ebx + 0x240]
  47220c: 50                           	push	eax
  47220d: 68 a6 0b 00 00               	push	0xba6
  472212: ff 15 94 59 c2 00            	call	dword ptr [0xc25994]
  472218: 8d 83 c0 02 00 00            	lea	eax, [ebx + 0x2c0]
  47221e: 50                           	push	eax
  47221f: 68 a7 0b 00 00               	push	0xba7
  472224: ff 15 94 59 c2 00            	call	dword ptr [0xc25994]
  47222a: 8d 83 40 03 00 00            	lea	eax, [ebx + 0x340]
  472230: 50                           	push	eax
  472231: 68 a2 0b 00 00               	push	0xba2
  472236: ff 15 f0 58 c2 00            	call	dword ptr [0xc258f0]
  47223c: 0f be 05 64 0e d7 00         	movsx	eax, byte ptr [0xd70e64]
  472243: 85 c0                        	test	eax, eax
  472245: 0f 84 da 01 00 00            	je	0x472425 <.text+0x71425>
  47224b: 80 3d 60 93 fe 00 01         	cmp	byte ptr [0xfe9360], 0x1
  472252: 0f 84 a5 06 00 00            	je	0x4728fd <.text+0x718fd>
  472258: f3 0f 10 05 1c c0 c2 00      	movss	xmm0, dword ptr [0xc2c01c]
  472260: f3 0f 11 45 8c               	movss	dword ptr [ebp - 0x74], xmm0
  472265: f3 0f 11 45 88               	movss	dword ptr [ebp - 0x78], xmm0
  47226a: 0f b6 05 80 93 fe 00         	movzx	eax, byte ptr [0xfe9380]
  472271: 85 c0                        	test	eax, eax
  472273: 0f 85 97 00 00 00            	jne	0x472310 <.text+0x71310>
  472279: 6a 00                        	push	0x0
  47227b: 68 e1 0d 00 00               	push	0xde1
  472280: ff 15 f8 58 c2 00            	call	dword ptr [0xc258f8]
  472286: a1 c8 92 fe 00               	mov	eax, dword ptr [0xfe92c8]
  47228b: 85 c0                        	test	eax, eax
  47228d: 74 0a                        	je	0x472299 <.text+0x71299>
  47228f: 50                           	push	eax
  472290: 89 04 24                     	mov	dword ptr [esp], eax
  472293: e8 b8 bc 0a 00               	call	0x51df50 <.text+0x11cf50>
  472298: 59                           	pop	ecx
  472299: 0f be 05 64 0e d7 00         	movsx	eax, byte ptr [0xd70e64]
  4722a0: 83 f8 01                     	cmp	eax, 0x1
  4722a3: 74 44                        	je	0x4722e9 <.text+0x712e9>
  4722a5: 83 f8 02                     	cmp	eax, 0x2
  4722a8: 75 1d                        	jne	0x4722c7 <.text+0x712c7>
  4722aa: a1 24 1e d7 00               	mov	eax, dword ptr [0xd71e24]
  4722af: 83 c4 f8                     	add	esp, -0x8
  4722b2: c7 04 24 40 c8 c2 00         	mov	dword ptr [esp], 0xc2c840
  4722b9: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  4722bd: e8 6e bc 0a 00               	call	0x51df30 <.text+0x11cf30>
  4722c2: 83 c4 08                     	add	esp, 0x8
  4722c5: eb 3d                        	jmp	0x472304 <.text+0x71304>
  4722c7: 83 f8 03                     	cmp	eax, 0x3
  4722ca: 75 3d                        	jne	0x472309 <.text+0x71309>
  4722cc: a1 24 1e d7 00               	mov	eax, dword ptr [0xd71e24]
  4722d1: 83 c4 f8                     	add	esp, -0x8
  4722d4: c7 04 24 50 c8 c2 00         	mov	dword ptr [esp], 0xc2c850
  4722db: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  4722df: e8 4c bc 0a 00               	call	0x51df30 <.text+0x11cf30>
  4722e4: 83 c4 08                     	add	esp, 0x8
  4722e7: eb 1b                        	jmp	0x472304 <.text+0x71304>
  4722e9: a1 24 1e d7 00               	mov	eax, dword ptr [0xd71e24]
  4722ee: 83 c4 f8                     	add	esp, -0x8
  4722f1: c7 04 24 30 c8 c2 00         	mov	dword ptr [esp], 0xc2c830
  4722f8: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  4722fc: e8 2f bc 0a 00               	call	0x51df30 <.text+0x11cf30>
  472301: 83 c4 08                     	add	esp, 0x8
  472304: a3 c8 92 fe 00               	mov	dword ptr [0xfe92c8], eax
  472309: c6 05 80 93 fe 00 01         	mov	byte ptr [0xfe9380], 0x1
  472310: 68 e1 0d 00 00               	push	0xde1
  472315: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  47231b: 68 e2 0b 00 00               	push	0xbe2
  472320: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  472326: 6a 01                        	push	0x1
  472328: 68 02 03 00 00               	push	0x302
  47232d: ff 15 78 59 c2 00            	call	dword ptr [0xc25978]
  472333: 68 71 0b 00 00               	push	0xb71
  472338: ff 15 18 59 c2 00            	call	dword ptr [0xc25918]
  47233e: ff 35 c8 92 fe 00            	push	dword ptr [0xfe92c8]
  472344: 68 e1 0d 00 00               	push	0xde1
  472349: ff 15 f8 58 c2 00            	call	dword ptr [0xc258f8]
  47234f: f3 0f 10 45 8c               	movss	xmm0, dword ptr [ebp - 0x74]
  472354: be 00 00 80 3f               	mov	esi, 0x3f800000
  472359: 83 c4 f0                     	add	esp, -0x10
  47235c: f3 0f 11 44 24 0c            	movss	dword ptr [esp + 0xc], xmm0
  472362: c7 04 24 00 00 80 3f         	mov	dword ptr [esp], 0x3f800000
  472369: c7 44 24 04 00 00 80 3f      	mov	dword ptr [esp + 0x4], 0x3f800000
  472371: c7 44 24 08 00 00 80 3f      	mov	dword ptr [esp + 0x8], 0x3f800000
  472379: ff 15 70 59 c2 00            	call	dword ptr [0xc25970]
  47237f: ff 15 04 59 c2 00            	call	dword ptr [0xc25904]
  472385: e8 d6 ca 0a 00               	call	0x51ee60 <.text+0x11de60>
  47238a: f3 0f 10 45 88               	movss	xmm0, dword ptr [ebp - 0x78]
  47238f: 83 c4 f4                     	add	esp, -0xc
  472392: f3 0f 11 04 24               	movss	dword ptr [esp], xmm0
  472397: f3 0f 11 44 24 04            	movss	dword ptr [esp + 0x4], xmm0
  47239d: f3 0f 11 44 24 08            	movss	dword ptr [esp + 0x8], xmm0
  4723a3: ff 15 50 59 c2 00            	call	dword ptr [0xc25950]
  4723a9: 33 c0                        	xor	eax, eax
  4723ab: 83 c4 f0                     	add	esp, -0x10
  4723ae: c7 04 24 00 00 34 43         	mov	dword ptr [esp], 0x43340000
  4723b5: 89 44 24 04                  	mov	dword ptr [esp + 0x4], eax
  4723b9: 89 44 24 08                  	mov	dword ptr [esp + 0x8], eax
  4723bd: 89 74 24 0c                  	mov	dword ptr [esp + 0xc], esi
  4723c1: ff 15 60 59 c2 00            	call	dword ptr [0xc25960]
  4723c7: 68 00 09 00 00               	push	0x900
  4723cc: ff 15 7c 59 c2 00            	call	dword ptr [0xc2597c]
  4723d2: 83 c4 f4                     	add	esp, -0xc
  4723d5: c7 04 24 0a 00 00 00         	mov	dword ptr [esp], 0xa
  4723dc: c6 44 24 04 01               	mov	byte ptr [esp + 0x4], 0x1
  4723e1: c6 44 24 08 00               	mov	byte ptr [esp + 0x8], 0x0
  4723e6: e8 85 ac fc ff               	call	0x43d070 <.text+0x3c070>
  4723eb: 83 c4 0c                     	add	esp, 0xc
  4723ee: 68 01 09 00 00               	push	0x901
  4723f3: ff 15 7c 59 c2 00            	call	dword ptr [0xc2597c]
  4723f9: ff 15 08 59 c2 00            	call	dword ptr [0xc25908]
  4723ff: 68 71 0b 00 00               	push	0xb71
  472404: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  47240a: 68 e1 0d 00 00               	push	0xde1
  47240f: ff 15 18 59 c2 00            	call	dword ptr [0xc25918]
  472415: 68 03 03 00 00               	push	0x303
  47241a: 68 02 03 00 00               	push	0x302
  47241f: ff 15 78 59 c2 00            	call	dword ptr [0xc25978]
  472425: 0f b6 05 44 93 fe 00         	movzx	eax, byte ptr [0xfe9344]
  47242c: 8d 53 08                     	lea	edx, [ebx + 0x8]
  47242f: 6a 01                        	push	0x1
  472431: b9 40 79 10 01               	mov	ecx, 0x1107940
  472436: 50                           	push	eax
  472437: 52                           	push	edx
  472438: e8 23 1f 11 00               	call	0x584360 <.text+0x183360>
  47243d: 0f be 05 68 93 fe 00         	movsx	eax, byte ptr [0xfe9368]
  472444: 83 f8 04                     	cmp	eax, 0x4
  472447: 74 13                        	je	0x47245c <.text+0x7145c>
  472449: 83 f8 05                     	cmp	eax, 0x5
  47244c: 74 0e                        	je	0x47245c <.text+0x7145c>
  47244e: 8d 43 08                     	lea	eax, [ebx + 0x8]
  472451: 50                           	push	eax
  472452: b9 40 79 10 01               	mov	ecx, 0x1107940
  472457: e8 a4 58 11 00               	call	0x587d00 <.text+0x186d00>
  47245c: e8 8f 2a 14 00               	call	0x5b4ef0 <.text+0x1b3ef0>
  472461: 83 c0 04                     	add	eax, 0x4
  472464: 8b c8                        	mov	ecx, eax
  472466: e8 a5 0e 2e 00               	call	0x753310 <.text+0x352310>
  47246b: 0f b6 c0                     	movzx	eax, al
  47246e: 85 c0                        	test	eax, eax
  472470: 0f 84 00 02 00 00            	je	0x472676 <.text+0x71676>
  472476: 0f be 05 60 93 fe 00         	movsx	eax, byte ptr [0xfe9360]
  47247d: 85 c0                        	test	eax, eax
  47247f: 75 0a                        	jne	0x47248b <.text+0x7148b>
  472481: f2 0f 10 05 30 ba c2 00      	movsd	xmm0, qword ptr [0xc2ba30]
  472489: eb 11                        	jmp	0x47249c <.text+0x7149c>
  47248b: e8 20 e2 0e 00               	call	0x5606b0 <.text+0x15f6b0>
  472490: d9 5d 88                     	fstp	dword ptr [ebp - 0x78]
  472493: f3 0f 10 45 88               	movss	xmm0, dword ptr [ebp - 0x78]
  472498: f3 0f 5a c0                  	cvtss2sd	xmm0, xmm0
  47249c: f2 0f 5a c0                  	cvtsd2ss	xmm0, xmm0
  4724a0: f3 0f 11 45 9c               	movss	dword ptr [ebp - 0x64], xmm0
  4724a5: e8 46 2a 14 00               	call	0x5b4ef0 <.text+0x1b3ef0>
  4724aa: 8b c8                        	mov	ecx, eax
  4724ac: e8 4f 2e 14 00               	call	0x5b5300 <.text+0x1b4300>
  4724b1: d9 5d 88                     	fstp	dword ptr [ebp - 0x78]
  4724b4: f3 0f 10 4d 88               	movss	xmm1, dword ptr [ebp - 0x78]
  4724b9: f3 0f 5a 83 34 02 00 00      	cvtss2sd	xmm0, dword ptr [ebx + 0x234]
  4724c1: f2 0f 5e 05 40 ba c2 00      	divsd	xmm0, qword ptr [0xc2ba40]
  4724c9: f3 0f 5a c9                  	cvtss2sd	xmm1, xmm1
  4724cd: f2 0f 10 15 38 ba c2 00      	movsd	xmm2, qword ptr [0xc2ba38]
  4724d5: f2 0f 5e d0                  	divsd	xmm2, xmm0
  4724d9: f2 0f 59 d1                  	mulsd	xmm2, xmm1
  4724dd: f2 0f 5a da                  	cvtsd2ss	xmm3, xmm2
  4724e1: 50                           	push	eax
  4724e2: f3 0f 11 1c 24               	movss	dword ptr [esp], xmm3
  4724e7: ff 15 6c 59 c2 00            	call	dword ptr [0xc2596c]
  4724ed: e8 fe 29 14 00               	call	0x5b4ef0 <.text+0x1b3ef0>
  4724f2: 83 c0 04                     	add	eax, 0x4
  4724f5: 8b c8                        	mov	ecx, eax
  4724f7: e8 64 0e 2e 00               	call	0x753360 <.text+0x352360>
  4724fc: a1 20 91 fe 00               	mov	eax, dword ptr [0xfe9120]
  472501: 8b 15 24 91 fe 00            	mov	edx, dword ptr [0xfe9124]
  472507: 8b 0d 28 91 fe 00            	mov	ecx, dword ptr [0xfe9128]
  47250d: 83 c4 f0                     	add	esp, -0x10
  472510: d9 5c 24 0c                  	fstp	dword ptr [esp + 0xc]
  472514: 89 04 24                     	mov	dword ptr [esp], eax
  472517: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  47251b: 89 4c 24 08                  	mov	dword ptr [esp + 0x8], ecx
  47251f: ff 15 70 59 c2 00            	call	dword ptr [0xc25970]
  472525: ff 15 04 59 c2 00            	call	dword ptr [0xc25904]
  47252b: f2 0f 10 05 48 ba c2 00      	movsd	xmm0, qword ptr [0xc2ba48]
  472533: f2 0f 10 0d 58 ba c2 00      	movsd	xmm1, qword ptr [0xc2ba58]
  47253b: 83 c4 e0                     	add	esp, -0x20
  47253e: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  472543: f2 0f 11 4c 24 08            	movsd	qword ptr [esp + 0x8], xmm1
  472549: 66 0f ef d2                  	pxor	xmm2, xmm2
  47254d: f2 0f 11 54 24 10            	movsd	qword ptr [esp + 0x10], xmm2
  472553: f2 0f 11 54 24 18            	movsd	qword ptr [esp + 0x18], xmm2
  472559: ff 15 74 59 c2 00            	call	dword ptr [0xc25974]
  47255f: f3 0f 10 45 9c               	movss	xmm0, dword ptr [ebp - 0x64]
  472564: f3 0f 5e 05 fc bf c2 00      	divss	xmm0, dword ptr [0xc2bffc]
  47256c: f3 0f 11 45 98               	movss	dword ptr [ebp - 0x68], xmm0
  472571: 33 ff                        	xor	edi, edi
  472573: 33 f6                        	xor	esi, esi
  472575: f3 0f 2a c7                  	cvtsi2ss	xmm0, edi
  472579: f3 0f 5e 05 00 c0 c2 00      	divss	xmm0, dword ptr [0xc2c000]
  472581: f3 0f 59 05 f8 bf c2 00      	mulss	xmm0, dword ptr [0xc2bff8]
  472589: f3 0f 5a c8                  	cvtss2sd	xmm1, xmm0
  47258d: f2 0f 5c 0d 50 ba c2 00      	subsd	xmm1, qword ptr [0xc2ba50]
  472595: f2 0f 5a d1                  	cvtsd2ss	xmm2, xmm1
  472599: f3 0f 11 55 90               	movss	dword ptr [ebp - 0x70], xmm2
  47259e: ff 15 04 59 c2 00            	call	dword ptr [0xc25904]
  4725a4: f3 0f 10 45 90               	movss	xmm0, dword ptr [ebp - 0x70]
  4725a9: f3 0f 5c 05 04 c0 c2 00      	subss	xmm0, dword ptr [0xc2c004]
  4725b1: 83 c4 f0                     	add	esp, -0x10
  4725b4: f3 0f 11 04 24               	movss	dword ptr [esp], xmm0
  4725b9: c7 44 24 0c 00 00 80 3f      	mov	dword ptr [esp + 0xc], 0x3f800000
  4725c1: 89 74 24 04                  	mov	dword ptr [esp + 0x4], esi
  4725c5: 89 74 24 08                  	mov	dword ptr [esp + 0x8], esi
  4725c9: ff 15 60 59 c2 00            	call	dword ptr [0xc25960]
  4725cf: 83 c4 f0                     	add	esp, -0x10
  4725d2: c7 04 24 9a 99 99 3e         	mov	dword ptr [esp], 0x3e99999a
  4725d9: 89 74 24 08                  	mov	dword ptr [esp + 0x8], esi
  4725dd: c7 44 24 04 00 00 80 3f      	mov	dword ptr [esp + 0x4], 0x3f800000
  4725e5: 89 74 24 0c                  	mov	dword ptr [esp + 0xc], esi
  4725e9: ff 15 60 59 c2 00            	call	dword ptr [0xc25960]
  4725ef: f3 0f 10 45 9c               	movss	xmm0, dword ptr [ebp - 0x64]
  4725f4: 83 c4 f4                     	add	esp, -0xc
  4725f7: f3 0f 11 44 24 04            	movss	dword ptr [esp + 0x4], xmm0
  4725fd: 89 34 24                     	mov	dword ptr [esp], esi
  472600: 89 74 24 08                  	mov	dword ptr [esp + 0x8], esi
  472604: ff 15 4c 59 c2 00            	call	dword ptr [0xc2594c]
  47260a: 83 c4 f0                     	add	esp, -0x10
  47260d: c7 04 24 00 00 b4 42         	mov	dword ptr [esp], 0x42b40000
  472614: 89 74 24 08                  	mov	dword ptr [esp + 0x8], esi
  472618: c7 44 24 04 00 00 80 3f      	mov	dword ptr [esp + 0x4], 0x3f800000
  472620: 89 74 24 0c                  	mov	dword ptr [esp + 0xc], esi
  472624: ff 15 60 59 c2 00            	call	dword ptr [0xc25960]
  47262a: f3 0f 10 45 98               	movss	xmm0, dword ptr [ebp - 0x68]
  47262f: 83 c4 f4                     	add	esp, -0xc
  472632: f3 0f 11 04 24               	movss	dword ptr [esp], xmm0
  472637: f3 0f 11 44 24 04            	movss	dword ptr [esp + 0x4], xmm0
  47263d: f3 0f 11 44 24 08            	movss	dword ptr [esp + 0x8], xmm0
  472643: ff 15 50 59 c2 00            	call	dword ptr [0xc25950]
  472649: 83 c4 f8                     	add	esp, -0x8
  47264c: c7 04 24 e4 c8 c2 00         	mov	dword ptr [esp], 0xc2c8e4
