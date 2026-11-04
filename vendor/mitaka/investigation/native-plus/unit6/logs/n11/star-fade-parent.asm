
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  471100: 6a 02                        	push	0x2
  471102: 53                           	push	ebx
  471103: e8 28 b2 12 00               	call	0x59c330 <.text+0x19b330>
  471108: 83 c4 0c                     	add	esp, 0xc
  47110b: e8 10 f4 0e 00               	call	0x560520 <.text+0x15f520>
  471110: dd 9c 24 b8 01 00 00         	fstp	qword ptr [esp + 0x1b8]
  471117: f2 0f 10 84 24 b8 01 00 00   	movsd	xmm0, qword ptr [esp + 0x1b8]
  471120: f2 0f 5a c0                  	cvtsd2ss	xmm0, xmm0
  471124: f3 0f 5a c8                  	cvtss2sd	xmm1, xmm0
  471128: f2 0f 11 4c 24 08            	movsd	qword ptr [esp + 0x8], xmm1
  47112e: f2 0f 11 8c 24 c0 01 00 00   	movsd	qword ptr [esp + 0x1c0], xmm1
  471137: c7 44 24 04 bc ca c2 00      	mov	dword ptr [esp + 0x4], 0xc2cabc
  47113f: 89 1c 24                     	mov	dword ptr [esp], ebx
  471142: ff 15 30 56 c2 00            	call	dword ptr [0xc25630]
  471148: 6a 01                        	push	0x1
  47114a: 6a 02                        	push	0x2
  47114c: 53                           	push	ebx
  47114d: e8 de b1 12 00               	call	0x59c330 <.text+0x19b330>
  471152: 83 c4 0c                     	add	esp, 0xc
  471155: f2 0f 10 84 24 c0 01 00 00   	movsd	xmm0, qword ptr [esp + 0x1c0]
  47115e: e8 07 dd 61 00               	call	0xa8ee6a <.text+0x68de6a>
  471163: f2 0f 5a c8                  	cvtsd2ss	xmm1, xmm0
  471167: f3 0f 11 8c 24 c0 01 00 00   	movss	dword ptr [esp + 0x1c0], xmm1
  471170: b9 40 79 10 01               	mov	ecx, 0x1107940
  471175: e8 c6 8a 11 00               	call	0x589c40 <.text+0x188c40>
  47117a: d9 9c 24 b8 01 00 00         	fstp	dword ptr [esp + 0x1b8]
  471181: f3 0f 10 8c 24 b8 01 00 00   	movss	xmm1, dword ptr [esp + 0x1b8]
  47118a: f3 0f 5a 84 24 c0 01 00 00   	cvtss2sd	xmm0, dword ptr [esp + 0x1c0]
  471193: f3 0f 5a c9                  	cvtss2sd	xmm1, xmm1
  471197: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  47119d: f2 0f 11 4c 24 10            	movsd	qword ptr [esp + 0x10], xmm1
  4711a3: c7 44 24 04 d0 ca c2 00      	mov	dword ptr [esp + 0x4], 0xc2cad0
  4711ab: 89 1c 24                     	mov	dword ptr [esp], ebx
  4711ae: ff 15 30 56 c2 00            	call	dword ptr [0xc25630]
  4711b4: 6a 01                        	push	0x1
  4711b6: 6a 02                        	push	0x2
  4711b8: 53                           	push	ebx
  4711b9: e8 72 b1 12 00               	call	0x59c330 <.text+0x19b330>
  4711be: ff 35 8c 91 fe 00            	push	dword ptr [0xfe918c]
  4711c4: ff 35 88 91 fe 00            	push	dword ptr [0xfe9188]
  4711ca: 68 f8 ca c2 00               	push	0xc2caf8
  4711cf: 53                           	push	ebx
  4711d0: ff 15 30 56 c2 00            	call	dword ptr [0xc25630]
  4711d6: 6a 00                        	push	0x0
  4711d8: 6a 02                        	push	0x2
  4711da: 53                           	push	ebx
  4711db: e8 50 b1 12 00               	call	0x59c330 <.text+0x19b330>
  4711e0: 83 c4 28                     	add	esp, 0x28
  4711e3: ff 15 08 59 c2 00            	call	dword ptr [0xc25908]
  4711e9: 68 71 0b 00 00               	push	0xb71
  4711ee: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  4711f4: 8b 8c 24 c8 01 00 00         	mov	ecx, dword ptr [esp + 0x1c8]
  4711fb: e8 c0 dc 61 00               	call	0xa8eec0 <.text+0x68dec0>
  471200: 81 c4 fc 01 00 00            	add	esp, 0x1fc
  471206: 5b                           	pop	ebx
  471207: 8b e5                        	mov	esp, ebp
  471209: 5d                           	pop	ebp
  47120a: c3                           	ret
  47120b: 90                           	nop
  47120c: 8d 74 26 00                  	lea	esi, [esi + eiz]
  471210: 55                           	push	ebp
  471211: 8b ec                        	mov	ebp, esp
  471213: 6a ff                        	push	-0x1
  471215: 68 d0 37 bf 00               	push	0xbf37d0
  47121a: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  471220: 50                           	push	eax
  471221: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  471228: 83 ec 18                     	sub	esp, 0x18
  47122b: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  47122e: 89 7d e4                     	mov	dword ptr [ebp - 0x1c], edi
  471231: 89 75 e8                     	mov	dword ptr [ebp - 0x18], esi
  471234: 68 71 0b 00 00               	push	0xb71
  471239: ff 15 18 59 c2 00            	call	dword ptr [0xc25918]
  47123f: 68 50 0b 00 00               	push	0xb50
  471244: ff 15 18 59 c2 00            	call	dword ptr [0xc25918]
  47124a: 68 e2 0b 00 00               	push	0xbe2
  47124f: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  471255: ff 15 04 59 c2 00            	call	dword ptr [0xc25904]
  47125b: ff 15 c8 58 c2 00            	call	dword ptr [0xc258c8]
  471261: 33 db                        	xor	ebx, ebx
  471263: 83 c4 f4                     	add	esp, -0xc
  471266: 89 1c 24                     	mov	dword ptr [esp], ebx
  471269: 89 5c 24 04                  	mov	dword ptr [esp + 0x4], ebx
  47126d: 66 0f ef c0                  	pxor	xmm0, xmm0
  471271: f3 0f 5c 05 28 75 10 01      	subss	xmm0, dword ptr [0x1107528]
  471279: f3 0f 11 44 24 08            	movss	dword ptr [esp + 0x8], xmm0
  47127f: ff 15 4c 59 c2 00            	call	dword ptr [0xc2594c]
  471285: f3 0f 10 05 2c 75 10 01      	movss	xmm0, dword ptr [0x110752c]
  47128d: f3 0f 5e 05 d8 bf c2 00      	divss	xmm0, dword ptr [0xc2bfd8]
  471295: 83 c4 f4                     	add	esp, -0xc
  471298: f3 0f 11 04 24               	movss	dword ptr [esp], xmm0
  47129d: f3 0f 11 44 24 04            	movss	dword ptr [esp + 0x4], xmm0
  4712a3: f3 0f 11 44 24 08            	movss	dword ptr [esp + 0x8], xmm0
  4712a9: ff 15 50 59 c2 00            	call	dword ptr [0xc25950]
  4712af: b8 00 00 40 41               	mov	eax, 0x41400000
  4712b4: 50                           	push	eax
  4712b5: 50                           	push	eax
  4712b6: 50                           	push	eax
  4712b7: ff 15 50 59 c2 00            	call	dword ptr [0xc25950]
  4712bd: e8 ee f1 0e 00               	call	0x5604b0 <.text+0x15f4b0>
  4712c2: 0f be c0                     	movsx	eax, al
  4712c5: 83 f8 4c                     	cmp	eax, 0x4c
  4712c8: 0f 84 f2 00 00 00            	je	0x4713c0 <.text+0x703c0>
  4712ce: 83 f8 52                     	cmp	eax, 0x52
  4712d1: 0f 84 bf 00 00 00            	je	0x471396 <.text+0x70396>
  4712d7: 8d 75 dc                     	lea	esi, [ebp - 0x24]
  4712da: 53                           	push	ebx
  4712db: 53                           	push	ebx
  4712dc: 68 24 cc c2 00               	push	0xc2cc24
  4712e1: 68 2c cb c2 00               	push	0xc2cb2c
  4712e6: 56                           	push	esi
  4712e7: ff 15 b8 60 c2 00            	call	dword ptr [0xc260b8]
  4712ed: 83 c4 14                     	add	esp, 0x14
  4712f0: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  4712f7: 8d 45 e0                     	lea	eax, [ebp - 0x20]
  4712fa: 50                           	push	eax
  4712fb: 8b ce                        	mov	ecx, esi
  4712fd: ff 15 3c 61 c2 00            	call	dword ptr [0xc2613c]
  471303: c7 45 fc 01 00 00 00         	mov	dword ptr [ebp - 0x4], 0x1
  47130a: 8b 45 e0                     	mov	eax, dword ptr [ebp - 0x20]
  47130d: 8b 50 0c                     	mov	edx, dword ptr [eax + 0xc]
  471310: 83 c4 f4                     	add	esp, -0xc
  471313: 89 14 24                     	mov	dword ptr [esp], edx
  471316: c6 44 24 04 02               	mov	byte ptr [esp + 0x4], 0x2
  47131b: c6 44 24 08 01               	mov	byte ptr [esp + 0x8], 0x1
  471320: e8 0b b0 12 00               	call	0x59c330 <.text+0x19b330>
  471325: 83 c4 0c                     	add	esp, 0xc
  471328: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  47132f: 8b 55 e0                     	mov	edx, dword ptr [ebp - 0x20]
  471332: 83 c8 ff                     	or	eax, -0x1
  471335: f0                           	lock
  471336: 0f c1 02                     	xadd	dword ptr [edx], eax
  471339: 48                           	dec	eax
  47133a: 85 c0                        	test	eax, eax
  47133c: 75 0b                        	jne	0x471349 <.text+0x70349>
  47133e: 50                           	push	eax
  47133f: 89 14 24                     	mov	dword ptr [esp], edx
  471342: ff 15 1c 61 c2 00            	call	dword ptr [0xc2611c]
  471348: 59                           	pop	ecx
  471349: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  471350: 8b 55 dc                     	mov	edx, dword ptr [ebp - 0x24]
  471353: 83 c8 ff                     	or	eax, -0x1
  471356: f0                           	lock
  471357: 0f c1 02                     	xadd	dword ptr [edx], eax
  47135a: 48                           	dec	eax
  47135b: 85 c0                        	test	eax, eax
  47135d: 75 08                        	jne	0x471367 <.text+0x70367>
  47135f: 52                           	push	edx
  471360: ff 15 88 61 c2 00            	call	dword ptr [0xc26188]
  471366: 59                           	pop	ecx
  471367: ff 15 08 59 c2 00            	call	dword ptr [0xc25908]
  47136d: 68 71 0b 00 00               	push	0xb71
  471372: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  471378: 8b 75 e8                     	mov	esi, dword ptr [ebp - 0x18]
  47137b: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  47137e: 8b 4d f4                     	mov	ecx, dword ptr [ebp - 0xc]
  471381: 64 89 0d 00 00 00 00         	mov	dword ptr fs:[0x0], ecx
  471388: 8b e5                        	mov	esp, ebp
  47138a: 5d                           	pop	ebp
  47138b: c3                           	ret
  47138c: 8d 4d dc                     	lea	ecx, [ebp - 0x24]
  47138f: ff 15 8c 61 c2 00            	call	dword ptr [0xc2618c]
  471395: c3                           	ret
  471396: 53                           	push	ebx
  471397: 68 00 00 80 bf               	push	0xbf800000
  47139c: 53                           	push	ebx
  47139d: ff 15 4c 59 c2 00            	call	dword ptr [0xc2594c]
  4713a3: 83 c4 f4                     	add	esp, -0xc
  4713a6: c7 44 24 04 00 00 80 3f      	mov	dword ptr [esp + 0x4], 0x3f800000
  4713ae: 89 1c 24                     	mov	dword ptr [esp], ebx
  4713b1: 89 5c 24 08                  	mov	dword ptr [esp + 0x8], ebx
  4713b5: ff 15 88 59 c2 00            	call	dword ptr [0xc25988]
  4713bb: e9 17 ff ff ff               	jmp	0x4712d7 <.text+0x702d7>
  4713c0: be 00 00 80 3f               	mov	esi, 0x3f800000
  4713c5: 83 c4 f4                     	add	esp, -0xc
  4713c8: 89 1c 24                     	mov	dword ptr [esp], ebx
  4713cb: c7 44 24 04 00 00 80 3f      	mov	dword ptr [esp + 0x4], 0x3f800000
  4713d3: 89 5c 24 08                  	mov	dword ptr [esp + 0x8], ebx
  4713d7: ff 15 4c 59 c2 00            	call	dword ptr [0xc2594c]
  4713dd: 83 c4 f4                     	add	esp, -0xc
  4713e0: 89 34 24                     	mov	dword ptr [esp], esi
  4713e3: 89 5c 24 04                  	mov	dword ptr [esp + 0x4], ebx
  4713e7: 89 5c 24 08                  	mov	dword ptr [esp + 0x8], ebx
  4713eb: ff 15 88 59 c2 00            	call	dword ptr [0xc25988]
  4713f1: e9 e1 fe ff ff               	jmp	0x4712d7 <.text+0x702d7>
  4713f6: 90                           	nop
  4713f7: 90                           	nop
  4713f8: 90                           	nop
  4713f9: 90                           	nop
  4713fa: 90                           	nop
  4713fb: 90                           	nop
  4713fc: 90                           	nop
  4713fd: 90                           	nop
  4713fe: 90                           	nop
  4713ff: 90                           	nop
  471400: 8b 44 24 04                  	mov	eax, dword ptr [esp + 0x4]
  471404: 83 c4 f8                     	add	esp, -0x8
  471407: 89 04 24                     	mov	dword ptr [esp], eax
  47140a: b9 40 79 10 01               	mov	ecx, 0x1107940
  47140f: c7 44 24 04 00 00 80 3f      	mov	dword ptr [esp + 0x4], 0x3f800000
  471417: e8 c4 18 11 00               	call	0x582ce0 <.text+0x181ce0>
  47141c: c3                           	ret
  47141d: 8d 76 00                     	lea	esi, [esi]
  471420: 55                           	push	ebp
  471421: 8b ec                        	mov	ebp, esp
  471423: 83 e4 c0                     	and	esp, -0x40
  471426: 57                           	push	edi
  471427: 56                           	push	esi
  471428: 53                           	push	ebx
  471429: 83 ec 34                     	sub	esp, 0x34
  47142c: ff 15 04 59 c2 00            	call	dword ptr [0xc25904]
  471432: 0f 28 05 70 b7 c2 00         	movaps	xmm0, xmmword ptr [0xc2b770]
  471439: 0f 29 44 24 20               	movaps	xmmword ptr [esp + 0x20], xmm0
  47143e: 8d 44 24 20                  	lea	eax, [esp + 0x20]
  471442: 50                           	push	eax
  471443: 68 03 12 00 00               	push	0x1203
  471448: 68 00 40 00 00               	push	0x4000
  47144d: ff 15 80 59 c2 00            	call	dword ptr [0xc25980]
  471453: 8b 75 08                     	mov	esi, dword ptr [ebp + 0x8]
  471456: f2 0f 10 46 70               	movsd	xmm0, qword ptr [esi + 0x70]
  47145b: 83 c4 e8                     	add	esp, -0x18
  47145e: f2 0f 11 04 24               	movsd	qword ptr [esp], xmm0
  471463: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  471469: f2 0f 11 44 24 10            	movsd	qword ptr [esp + 0x10], xmm0
  47146f: ff 15 8c 59 c2 00            	call	dword ptr [0xc2598c]
  471475: ff 15 98 7a c2 00            	call	dword ptr [0xc27a98]
  47147b: f2 0f 2a c8                  	cvtsi2sd	xmm1, eax
  47147f: f2 0f 10 05 28 ba c2 00      	movsd	xmm0, qword ptr [0xc2ba28]
  471487: f2 0f 11 44 24 18            	movsd	qword ptr [esp + 0x18], xmm0
  47148d: c1 e8 1f                     	shr	eax, 0x1f
  471490: f2 0f 58 0c c5 80 b7 c2 00   	addsd	xmm1, qword ptr [8*eax + 0xc2b780]
  471499: f2 0f 5e c8                  	divsd	xmm1, xmm0
  47149d: f2 0f 11 0d 98 90 fe 00      	movsd	qword ptr [0xfe9098], xmm1
  4714a5: 83 c4 f8                     	add	esp, -0x8
  4714a8: c7 44 24 04 00 00 80 3f      	mov	dword ptr [esp + 0x4], 0x3f800000
  4714b0: b9 40 79 10 01               	mov	ecx, 0x1107940
  4714b5: 89 34 24                     	mov	dword ptr [esp], esi
  4714b8: e8 23 18 11 00               	call	0x582ce0 <.text+0x181ce0>
  4714bd: ff 15 98 7a c2 00            	call	dword ptr [0xc27a98]
  4714c3: f2 0f 2a c0                  	cvtsi2sd	xmm0, eax
  4714c7: f2 0f 10 0e                  	movsd	xmm1, qword ptr [esi]
  4714cb: c1 e8 1f                     	shr	eax, 0x1f
  4714ce: f2 0f 58 04 c5 80 b7 c2 00   	addsd	xmm0, qword ptr [8*eax + 0xc2b780]
  4714d7: f2 0f 5e 44 24 18            	divsd	xmm0, qword ptr [esp + 0x18]
  4714dd: f2 0f 11 05 98 90 fe 00      	movsd	qword ptr [0xfe9098], xmm0
  4714e5: 81 c4 b0 fc ff ff            	add	esp, 0xfffffcb0
  4714eb: 8b d4                        	mov	edx, esp
  4714ed: f2 0f 11 0a                  	movsd	qword ptr [edx], xmm1
  4714f1: f2 0f 10 56 48               	movsd	xmm2, qword ptr [esi + 0x48]
  4714f6: f2 0f 11 52 48               	movsd	qword ptr [edx + 0x48], xmm2
  4714fb: b8 40 00 00 00               	mov	eax, 0x40
  471500: f2 0f 10 04 06               	movsd	xmm0, qword ptr [esi + eax]
  471505: f2 0f 11 04 02               	movsd	qword ptr [edx + eax], xmm0
  47150a: f2 0f 10 4c 06 f8            	movsd	xmm1, qword ptr [esi + eax - 0x8]
  471510: f2 0f 11 4c 02 f8            	movsd	qword ptr [edx + eax - 0x8], xmm1
  471516: f2 0f 10 54 06 f0            	movsd	xmm2, qword ptr [esi + eax - 0x10]
  47151c: f2 0f 11 54 02 f0            	movsd	qword ptr [edx + eax - 0x10], xmm2
  471522: f2 0f 10 5c 06 e8            	movsd	xmm3, qword ptr [esi + eax - 0x18]
  471528: f2 0f 11 5c 02 e8            	movsd	qword ptr [edx + eax - 0x18], xmm3
  47152e: 83 e8 20                     	sub	eax, 0x20
  471531: 75 cd                        	jne	0x471500 <.text+0x70500>
  471533: 8b 46 50                     	mov	eax, dword ptr [esi + 0x50]
  471536: 8b 4e 54                     	mov	ecx, dword ptr [esi + 0x54]
  471539: 8b 5e 58                     	mov	ebx, dword ptr [esi + 0x58]
  47153c: 8b 7e 5c                     	mov	edi, dword ptr [esi + 0x5c]
  47153f: f2 0f 10 46 68               	movsd	xmm0, qword ptr [esi + 0x68]
  471544: f2 0f 10 4e 70               	movsd	xmm1, qword ptr [esi + 0x70]
  471549: f2 0f 11 42 68               	movsd	qword ptr [edx + 0x68], xmm0
  47154e: f2 0f 11 4a 70               	movsd	qword ptr [edx + 0x70], xmm1
  471553: 89 42 50                     	mov	dword ptr [edx + 0x50], eax
  471556: 8b 46 60                     	mov	eax, dword ptr [esi + 0x60]
  471559: 89 4a 54                     	mov	dword ptr [edx + 0x54], ecx
  47155c: 8b 4e 64                     	mov	ecx, dword ptr [esi + 0x64]
  47155f: 89 5a 58                     	mov	dword ptr [edx + 0x58], ebx
  471562: 8b 5e 78                     	mov	ebx, dword ptr [esi + 0x78]
  471565: 89 7a 5c                     	mov	dword ptr [edx + 0x5c], edi
  471568: 8b 7e 7c                     	mov	edi, dword ptr [esi + 0x7c]
  47156b: 89 42 60                     	mov	dword ptr [edx + 0x60], eax
  47156e: 89 4a 64                     	mov	dword ptr [edx + 0x64], ecx
  471571: 89 5a 78                     	mov	dword ptr [edx + 0x78], ebx
  471574: 89 7a 7c                     	mov	dword ptr [edx + 0x7c], edi
  471577: 8d ba 80 00 00 00            	lea	edi, [edx + 0x80]
  47157d: 8d 9e 80 00 00 00            	lea	ebx, [esi + 0x80]
  471583: 3b fb                        	cmp	edi, ebx
  471585: 76 0b                        	jbe	0x471592 <.text+0x70592>
  471587: 8b c3                        	mov	eax, ebx
  471589: 2b c7                        	sub	eax, edi
  47158b: f7 d8                        	neg	eax
  47158d: 83 f8 18                     	cmp	eax, 0x18
  471590: 73 0b                        	jae	0x47159d <.text+0x7059d>
  471592: 3b df                        	cmp	ebx, edi
  471594: 76 07                        	jbe	0x47159d <.text+0x7059d>
  471596: 8b c3                        	mov	eax, ebx
  471598: 2b c7                        	sub	eax, edi
  47159a: 83 f8 18                     	cmp	eax, 0x18
  47159d: 8b 03                        	mov	eax, dword ptr [ebx]
  47159f: 8b 4b 04                     	mov	ecx, dword ptr [ebx + 0x4]
  4715a2: 89 82 80 00 00 00            	mov	dword ptr [edx + 0x80], eax
  4715a8: 8b 43 08                     	mov	eax, dword ptr [ebx + 0x8]
  4715ab: 89 4f 04                     	mov	dword ptr [edi + 0x4], ecx
  4715ae: 8b 4b 0c                     	mov	ecx, dword ptr [ebx + 0xc]
  4715b1: 89 47 08                     	mov	dword ptr [edi + 0x8], eax
  4715b4: 8b 43 10                     	mov	eax, dword ptr [ebx + 0x10]
  4715b7: 89 4f 0c                     	mov	dword ptr [edi + 0xc], ecx
  4715ba: 89 47 10                     	mov	dword ptr [edi + 0x10], eax
  4715bd: 8b 43 14                     	mov	eax, dword ptr [ebx + 0x14]
  4715c0: f2 0f 10 43 18               	movsd	xmm0, qword ptr [ebx + 0x18]
  4715c5: 8b 4b 24                     	mov	ecx, dword ptr [ebx + 0x24]
  4715c8: f2 0f 10 4b 38               	movsd	xmm1, qword ptr [ebx + 0x38]
  4715cd: f2 0f 10 53 58               	movsd	xmm2, qword ptr [ebx + 0x58]
  4715d2: f2 0f 11 47 18               	movsd	qword ptr [edi + 0x18], xmm0
  4715d7: f2 0f 11 4f 38               	movsd	qword ptr [edi + 0x38], xmm1
  4715dc: 89 47 14                     	mov	dword ptr [edi + 0x14], eax
  4715df: 8b 43 20                     	mov	eax, dword ptr [ebx + 0x20]
  4715e2: 89 47 20                     	mov	dword ptr [edi + 0x20], eax
  4715e5: 8b 43 28                     	mov	eax, dword ptr [ebx + 0x28]
  4715e8: 89 4f 24                     	mov	dword ptr [edi + 0x24], ecx
  4715eb: 8b 4b 2c                     	mov	ecx, dword ptr [ebx + 0x2c]
  4715ee: 89 47 28                     	mov	dword ptr [edi + 0x28], eax
  4715f1: 8b 43 30                     	mov	eax, dword ptr [ebx + 0x30]
  4715f4: 89 4f 2c                     	mov	dword ptr [edi + 0x2c], ecx
  4715f7: 8b 4b 34                     	mov	ecx, dword ptr [ebx + 0x34]
  4715fa: 89 47 30                     	mov	dword ptr [edi + 0x30], eax
  4715fd: 8b 43 40                     	mov	eax, dword ptr [ebx + 0x40]
  471600: 89 4f 34                     	mov	dword ptr [edi + 0x34], ecx
  471603: 8b 4b 44                     	mov	ecx, dword ptr [ebx + 0x44]
  471606: 89 47 40                     	mov	dword ptr [edi + 0x40], eax
  471609: 8b 43 48                     	mov	eax, dword ptr [ebx + 0x48]
  47160c: 89 4f 44                     	mov	dword ptr [edi + 0x44], ecx
  47160f: 8b 4b 4c                     	mov	ecx, dword ptr [ebx + 0x4c]
  471612: 89 47 48                     	mov	dword ptr [edi + 0x48], eax
  471615: 8b 43 50                     	mov	eax, dword ptr [ebx + 0x50]
  471618: 89 4f 4c                     	mov	dword ptr [edi + 0x4c], ecx
  47161b: 8b 4b 54                     	mov	ecx, dword ptr [ebx + 0x54]
  47161e: 89 47 50                     	mov	dword ptr [edi + 0x50], eax
  471621: 89 4f 54                     	mov	dword ptr [edi + 0x54], ecx
  471624: f2 0f 11 92 d8 00 00 00      	movsd	qword ptr [edx + 0xd8], xmm2
  47162c: 8d 8e e0 00 00 00            	lea	ecx, [esi + 0xe0]
  471632: 8d 82 e0 00 00 00            	lea	eax, [edx + 0xe0]
  471638: 89 8c 24 54 03 00 00         	mov	dword ptr [esp + 0x354], ecx
  47163f: 3b c1                        	cmp	eax, ecx
  471641: 76 09                        	jbe	0x47164c <.text+0x7064c>
  471643: 2b c8                        	sub	ecx, eax
  471645: f7 d9                        	neg	ecx
  471647: 83 f9 48                     	cmp	ecx, 0x48
  47164a: 73 17                        	jae	0x471663 <.text+0x70663>
  47164c: 3b 84 24 54 03 00 00         	cmp	eax, dword ptr [esp + 0x354]
  471653: 73 58                        	jae	0x4716ad <.text+0x706ad>
  471655: 8b 8c 24 54 03 00 00         	mov	ecx, dword ptr [esp + 0x354]
  47165c: 2b c8                        	sub	ecx, eax
  47165e: 83 f9 48                     	cmp	ecx, 0x48
  471661: 72 4a                        	jb	0x4716ad <.text+0x706ad>
  471663: 83 e0 0f                     	and	eax, 0xf
  471666: 8b c8                        	mov	ecx, eax
  471668: f7 d9                        	neg	ecx
  47166a: 83 c1 02                     	add	ecx, 0x2
  47166d: 83 e1 03                     	and	ecx, 0x3
  471670: f7 d9                        	neg	ecx
  471672: 83 c1 12                     	add	ecx, 0x12
  471675: f6 c3 0f                     	test	bl, 0xf
  471678: 74 15                        	je	0x47168f <.text+0x7068f>
  47167a: f3 0f 6f 44 83 60            	movdqu	xmm0, xmmword ptr [ebx + 4*eax + 0x60]
  471680: 66 0f 7f 44 87 60            	movdqa	xmmword ptr [edi + 4*eax + 0x60], xmm0
  471686: 83 c0 04                     	add	eax, 0x4
  471689: 3b c1                        	cmp	eax, ecx
  47168b: 72 ed                        	jb	0x47167a <.text+0x7067a>
  47168d: eb 13                        	jmp	0x4716a2 <.text+0x706a2>
  47168f: 66 0f 6f 44 83 60            	movdqa	xmm0, xmmword ptr [ebx + 4*eax + 0x60]
  471695: 66 0f 7f 44 87 60            	movdqa	xmmword ptr [edi + 4*eax + 0x60], xmm0
  47169b: 83 c0 04                     	add	eax, 0x4
  47169e: 3b c1                        	cmp	eax, ecx
  4716a0: 72 ed                        	jb	0x47168f <.text+0x7068f>
  4716a2: 83 f9 12                     	cmp	ecx, 0x12
  4716a5: 0f 82 3d 0a 00 00            	jb	0x4720e8 <.text+0x710e8>
  4716ab: eb 10                        	jmp	0x4716bd <.text+0x706bd>
  4716ad: 33 c0                        	xor	eax, eax
  4716af: 8b 4c 83 60                  	mov	ecx, dword ptr [ebx + 4*eax + 0x60]
  4716b3: 89 4c 87 60                  	mov	dword ptr [edi + 4*eax + 0x60], ecx
  4716b7: 40                           	inc	eax
  4716b8: 83 f8 12                     	cmp	eax, 0x12
  4716bb: 72 f2                        	jb	0x4716af <.text+0x706af>
  4716bd: f2 0f 10 83 a8 00 00 00      	movsd	xmm0, qword ptr [ebx + 0xa8]
  4716c5: f2 0f 10 8b b0 00 00 00      	movsd	xmm1, qword ptr [ebx + 0xb0]
  4716cd: f2 0f 11 82 28 01 00 00      	movsd	qword ptr [edx + 0x128], xmm0
  4716d5: f2 0f 11 8a 30 01 00 00      	movsd	qword ptr [edx + 0x130], xmm1
  4716dd: 8d 82 38 01 00 00            	lea	eax, [edx + 0x138]
  4716e3: 89 84 24 64 03 00 00         	mov	dword ptr [esp + 0x364], eax
  4716ea: 8d be 38 01 00 00            	lea	edi, [esi + 0x138]
  4716f0: 3b c7                        	cmp	eax, edi
  4716f2: 76 10                        	jbe	0x471704 <.text+0x70704>
  4716f4: 8b c7                        	mov	eax, edi
  4716f6: 2b 84 24 64 03 00 00         	sub	eax, dword ptr [esp + 0x364]
  4716fd: f7 d8                        	neg	eax
  4716ff: 83 f8 18                     	cmp	eax, 0x18
  471702: 73 15                        	jae	0x471719 <.text+0x70719>
  471704: 3b bc 24 64 03 00 00         	cmp	edi, dword ptr [esp + 0x364]
  47170b: 76 0c                        	jbe	0x471719 <.text+0x70719>
  47170d: 8b c7                        	mov	eax, edi
  47170f: 2b 84 24 64 03 00 00         	sub	eax, dword ptr [esp + 0x364]
  471716: 83 f8 18                     	cmp	eax, 0x18
  471719: 8b 84 24 64 03 00 00         	mov	eax, dword ptr [esp + 0x364]
  471720: 8b 0f                        	mov	ecx, dword ptr [edi]
  471722: 89 8a 38 01 00 00            	mov	dword ptr [edx + 0x138], ecx
  471728: 8b 4f 04                     	mov	ecx, dword ptr [edi + 0x4]
  47172b: 89 48 04                     	mov	dword ptr [eax + 0x4], ecx
  47172e: 8b 4f 08                     	mov	ecx, dword ptr [edi + 0x8]
  471731: 89 48 08                     	mov	dword ptr [eax + 0x8], ecx
  471734: 8b 4f 0c                     	mov	ecx, dword ptr [edi + 0xc]
  471737: 89 48 0c                     	mov	dword ptr [eax + 0xc], ecx
  47173a: 8b 4f 10                     	mov	ecx, dword ptr [edi + 0x10]
  47173d: 89 48 10                     	mov	dword ptr [eax + 0x10], ecx
  471740: 8b 4f 14                     	mov	ecx, dword ptr [edi + 0x14]
  471743: f2 0f 10 47 18               	movsd	xmm0, qword ptr [edi + 0x18]
  471748: f2 0f 10 4f 38               	movsd	xmm1, qword ptr [edi + 0x38]
  47174d: f2 0f 10 57 58               	movsd	xmm2, qword ptr [edi + 0x58]
  471752: f2 0f 11 40 18               	movsd	qword ptr [eax + 0x18], xmm0
  471757: f2 0f 11 48 38               	movsd	qword ptr [eax + 0x38], xmm1
  47175c: 89 48 14                     	mov	dword ptr [eax + 0x14], ecx
  47175f: 8b 4f 20                     	mov	ecx, dword ptr [edi + 0x20]
  471762: 89 48 20                     	mov	dword ptr [eax + 0x20], ecx
  471765: 8b 4f 24                     	mov	ecx, dword ptr [edi + 0x24]
  471768: 89 48 24                     	mov	dword ptr [eax + 0x24], ecx
  47176b: 8b 4f 28                     	mov	ecx, dword ptr [edi + 0x28]
  47176e: 89 48 28                     	mov	dword ptr [eax + 0x28], ecx
  471771: 8b 4f 2c                     	mov	ecx, dword ptr [edi + 0x2c]
  471774: 89 48 2c                     	mov	dword ptr [eax + 0x2c], ecx
  471777: 8b 4f 30                     	mov	ecx, dword ptr [edi + 0x30]
  47177a: 89 48 30                     	mov	dword ptr [eax + 0x30], ecx
  47177d: 8b 4f 34                     	mov	ecx, dword ptr [edi + 0x34]
  471780: 89 48 34                     	mov	dword ptr [eax + 0x34], ecx
  471783: 8b 4f 40                     	mov	ecx, dword ptr [edi + 0x40]
  471786: 89 48 40                     	mov	dword ptr [eax + 0x40], ecx
  471789: 8b 4f 44                     	mov	ecx, dword ptr [edi + 0x44]
  47178c: 89 48 44                     	mov	dword ptr [eax + 0x44], ecx
  47178f: 8b 4f 48                     	mov	ecx, dword ptr [edi + 0x48]
  471792: 89 48 48                     	mov	dword ptr [eax + 0x48], ecx
  471795: 8b 4f 4c                     	mov	ecx, dword ptr [edi + 0x4c]
  471798: 89 48 4c                     	mov	dword ptr [eax + 0x4c], ecx
  47179b: 8b 4f 50                     	mov	ecx, dword ptr [edi + 0x50]
  47179e: 89 48 50                     	mov	dword ptr [eax + 0x50], ecx
  4717a1: 8b 4f 54                     	mov	ecx, dword ptr [edi + 0x54]
  4717a4: 89 48 54                     	mov	dword ptr [eax + 0x54], ecx
  4717a7: f2 0f 11 92 90 01 00 00      	movsd	qword ptr [edx + 0x190], xmm2
  4717af: 8d 8e 98 01 00 00            	lea	ecx, [esi + 0x198]
  4717b5: 89 8c 24 58 03 00 00         	mov	dword ptr [esp + 0x358], ecx
  4717bc: 8d 82 98 01 00 00            	lea	eax, [edx + 0x198]
  4717c2: 89 84 24 60 03 00 00         	mov	dword ptr [esp + 0x360], eax
  4717c9: 3b c1                        	cmp	eax, ecx
  4717cb: 76 10                        	jbe	0x4717dd <.text+0x707dd>
  4717cd: 8b c1                        	mov	eax, ecx
  4717cf: 2b 84 24 60 03 00 00         	sub	eax, dword ptr [esp + 0x360]
  4717d6: f7 d8                        	neg	eax
  4717d8: 83 f8 48                     	cmp	eax, 0x48
  4717db: 73 26                        	jae	0x471803 <.text+0x70803>
  4717dd: 8b 84 24 60 03 00 00         	mov	eax, dword ptr [esp + 0x360]
  4717e4: 3b 84 24 58 03 00 00         	cmp	eax, dword ptr [esp + 0x358]
  4717eb: 0f 83 03 01 00 00            	jae	0x4718f4 <.text+0x708f4>
  4717f1: 8b c1                        	mov	eax, ecx
  4717f3: 2b 84 24 60 03 00 00         	sub	eax, dword ptr [esp + 0x360]
  4717fa: 83 f8 48                     	cmp	eax, 0x48
  4717fd: 0f 82 f1 00 00 00            	jb	0x4718f4 <.text+0x708f4>
  471803: 8b 84 24 60 03 00 00         	mov	eax, dword ptr [esp + 0x360]
  47180a: 83 e0 0f                     	and	eax, 0xf
  47180d: 89 84 24 60 03 00 00         	mov	dword ptr [esp + 0x360], eax
  471814: 89 94 24 5c 03 00 00         	mov	dword ptr [esp + 0x35c], edx
  47181b: 89 b4 24 50 03 00 00         	mov	dword ptr [esp + 0x350], esi
  471822: f7 d8                        	neg	eax
  471824: 8b b4 24 64 03 00 00         	mov	esi, dword ptr [esp + 0x364]
  47182b: 83 c0 10                     	add	eax, 0x10
  47182e: c1 e8 02                     	shr	eax, 0x2
  471831: 89 84 24 60 03 00 00         	mov	dword ptr [esp + 0x360], eax
  471838: 33 c0                        	xor	eax, eax
  47183a: 8b 8c 24 60 03 00 00         	mov	ecx, dword ptr [esp + 0x360]
  471841: 8b 54 87 60                  	mov	edx, dword ptr [edi + 4*eax + 0x60]
  471845: 89 54 86 60                  	mov	dword ptr [esi + 4*eax + 0x60], edx
  471849: 40                           	inc	eax
  47184a: 3b c1                        	cmp	eax, ecx
  47184c: 72 f3                        	jb	0x471841 <.text+0x70841>
  47184e: 8b 94 24 5c 03 00 00         	mov	edx, dword ptr [esp + 0x35c]
  471855: 8b b4 24 50 03 00 00         	mov	esi, dword ptr [esp + 0x350]
  47185c: 89 8c 24 60 03 00 00         	mov	dword ptr [esp + 0x360], ecx
  471863: 8b c1                        	mov	eax, ecx
  471865: f7 d8                        	neg	eax
  471867: 83 c0 02                     	add	eax, 0x2
  47186a: 83 e0 03                     	and	eax, 0x3
  47186d: f7 d8                        	neg	eax
  47186f: 83 c0 12                     	add	eax, 0x12
  471872: 89 84 24 5c 03 00 00         	mov	dword ptr [esp + 0x35c], eax
  471879: 8d 84 8e 38 01 00 00         	lea	eax, [esi + 4*ecx + 0x138]
  471880: a8 0f                        	test	al, 0xf
  471882: 74 2a                        	je	0x4718ae <.text+0x708ae>
  471884: 8b 84 24 5c 03 00 00         	mov	eax, dword ptr [esp + 0x35c]
  47188b: 89 b4 24 50 03 00 00         	mov	dword ptr [esp + 0x350], esi
  471892: 8b b4 24 64 03 00 00         	mov	esi, dword ptr [esp + 0x364]
  471899: f3 0f 6f 44 8f 60            	movdqu	xmm0, xmmword ptr [edi + 4*ecx + 0x60]
  47189f: 66 0f 7f 44 8e 60            	movdqa	xmmword ptr [esi + 4*ecx + 0x60], xmm0
  4718a5: 83 c1 04                     	add	ecx, 0x4
  4718a8: 3b c8                        	cmp	ecx, eax
  4718aa: 72 ed                        	jb	0x471899 <.text+0x70899>
  4718ac: eb 28                        	jmp	0x4718d6 <.text+0x708d6>
  4718ae: 8b 84 24 5c 03 00 00         	mov	eax, dword ptr [esp + 0x35c]
  4718b5: 89 b4 24 50 03 00 00         	mov	dword ptr [esp + 0x350], esi
  4718bc: 8b b4 24 64 03 00 00         	mov	esi, dword ptr [esp + 0x364]
  4718c3: 66 0f 6f 44 8f 60            	movdqa	xmm0, xmmword ptr [edi + 4*ecx + 0x60]
  4718c9: 66 0f 7f 44 8e 60            	movdqa	xmmword ptr [esi + 4*ecx + 0x60], xmm0
  4718cf: 83 c1 04                     	add	ecx, 0x4
  4718d2: 3b c8                        	cmp	ecx, eax
  4718d4: 72 ed                        	jb	0x4718c3 <.text+0x708c3>
  4718d6: 8b b4 24 50 03 00 00         	mov	esi, dword ptr [esp + 0x350]
  4718dd: 89 84 24 5c 03 00 00         	mov	dword ptr [esp + 0x35c], eax
  4718e4: 83 bc 24 5c 03 00 00 12      	cmp	dword ptr [esp + 0x35c], 0x12
  4718ec: 0f 82 09 08 00 00            	jb	0x4720fb <.text+0x710fb>
  4718f2: eb 25                        	jmp	0x471919 <.text+0x70919>
  4718f4: 89 b4 24 50 03 00 00         	mov	dword ptr [esp + 0x350], esi
  4718fb: 8b b4 24 64 03 00 00         	mov	esi, dword ptr [esp + 0x364]
  471902: 33 c0                        	xor	eax, eax
  471904: 8b 4c 87 60                  	mov	ecx, dword ptr [edi + 4*eax + 0x60]
  471908: 89 4c 86 60                  	mov	dword ptr [esi + 4*eax + 0x60], ecx
  47190c: 40                           	inc	eax
  47190d: 83 f8 12                     	cmp	eax, 0x12
  471910: 72 f2                        	jb	0x471904 <.text+0x70904>
  471912: 8b b4 24 50 03 00 00         	mov	esi, dword ptr [esp + 0x350]
  471919: f2 0f 10 87 a8 00 00 00      	movsd	xmm0, qword ptr [edi + 0xa8]
  471921: f2 0f 10 8f b0 00 00 00      	movsd	xmm1, qword ptr [edi + 0xb0]
  471929: 8b 8e f0 01 00 00            	mov	ecx, dword ptr [esi + 0x1f0]
  47192f: 8b 86 f4 01 00 00            	mov	eax, dword ptr [esi + 0x1f4]
  471935: f2 0f 11 82 e0 01 00 00      	movsd	qword ptr [edx + 0x1e0], xmm0
  47193d: f2 0f 11 8a e8 01 00 00      	movsd	qword ptr [edx + 0x1e8], xmm1
  471945: 89 8a f0 01 00 00            	mov	dword ptr [edx + 0x1f0], ecx
  47194b: 8b 8e f8 01 00 00            	mov	ecx, dword ptr [esi + 0x1f8]
  471951: 89 82 f4 01 00 00            	mov	dword ptr [edx + 0x1f4], eax
  471957: 8b 86 fc 01 00 00            	mov	eax, dword ptr [esi + 0x1fc]
  47195d: 89 8a f8 01 00 00            	mov	dword ptr [edx + 0x1f8], ecx
  471963: 8b 8e 00 02 00 00            	mov	ecx, dword ptr [esi + 0x200]
  471969: 89 82 fc 01 00 00            	mov	dword ptr [edx + 0x1fc], eax
  47196f: 8b 86 04 02 00 00            	mov	eax, dword ptr [esi + 0x204]
  471975: 89 8a 00 02 00 00            	mov	dword ptr [edx + 0x200], ecx
  47197b: 8b 8e 08 02 00 00            	mov	ecx, dword ptr [esi + 0x208]
  471981: 89 82 04 02 00 00            	mov	dword ptr [edx + 0x204], eax
  471987: 8b 86 0c 02 00 00            	mov	eax, dword ptr [esi + 0x20c]
  47198d: 89 8a 08 02 00 00            	mov	dword ptr [edx + 0x208], ecx
  471993: 8b 8e 10 02 00 00            	mov	ecx, dword ptr [esi + 0x210]
  471999: 89 82 0c 02 00 00            	mov	dword ptr [edx + 0x20c], eax
  47199f: 8b 86 14 02 00 00            	mov	eax, dword ptr [esi + 0x214]
  4719a5: 89 8a 10 02 00 00            	mov	dword ptr [edx + 0x210], ecx
  4719ab: 8b 8e 18 02 00 00            	mov	ecx, dword ptr [esi + 0x218]
  4719b1: 89 82 14 02 00 00            	mov	dword ptr [edx + 0x214], eax
  4719b7: 8b 86 1c 02 00 00            	mov	eax, dword ptr [esi + 0x21c]
  4719bd: 89 8a 18 02 00 00            	mov	dword ptr [edx + 0x218], ecx
  4719c3: 8b 8e 20 02 00 00            	mov	ecx, dword ptr [esi + 0x220]
  4719c9: 89 82 1c 02 00 00            	mov	dword ptr [edx + 0x21c], eax
  4719cf: 8b 86 24 02 00 00            	mov	eax, dword ptr [esi + 0x224]
  4719d5: 89 8a 20 02 00 00            	mov	dword ptr [edx + 0x220], ecx
  4719db: 8b 8e 2c 02 00 00            	mov	ecx, dword ptr [esi + 0x22c]
  4719e1: 89 82 24 02 00 00            	mov	dword ptr [edx + 0x224], eax
  4719e7: 0f b6 86 28 02 00 00         	movzx	eax, byte ptr [esi + 0x228]
  4719ee: 88 82 28 02 00 00            	mov	byte ptr [edx + 0x228], al
  4719f4: 8b 86 30 02 00 00            	mov	eax, dword ptr [esi + 0x230]
  4719fa: 89 8a 2c 02 00 00            	mov	dword ptr [edx + 0x22c], ecx
  471a00: 89 82 30 02 00 00            	mov	dword ptr [edx + 0x230], eax
  471a06: b8 80 00 00 00               	mov	eax, 0x80
  471a0b: f2 0f 10 84 06 30 02 00 00   	movsd	xmm0, qword ptr [esi + eax + 0x230]
  471a14: f2 0f 11 84 02 30 02 00 00   	movsd	qword ptr [edx + eax + 0x230], xmm0
  471a1d: f2 0f 10 8c 06 28 02 00 00   	movsd	xmm1, qword ptr [esi + eax + 0x228]
  471a26: f2 0f 11 8c 02 28 02 00 00   	movsd	qword ptr [edx + eax + 0x228], xmm1
  471a2f: f2 0f 10 94 06 20 02 00 00   	movsd	xmm2, qword ptr [esi + eax + 0x220]
  471a38: f2 0f 11 94 02 20 02 00 00   	movsd	qword ptr [edx + eax + 0x220], xmm2
  471a41: f2 0f 10 9c 06 18 02 00 00   	movsd	xmm3, qword ptr [esi + eax + 0x218]
  471a4a: f2 0f 11 9c 02 18 02 00 00   	movsd	qword ptr [edx + eax + 0x218], xmm3
  471a53: 83 e8 20                     	sub	eax, 0x20
  471a56: 75 b3                        	jne	0x471a0b <.text+0x70a0b>
  471a58: b8 80 00 00 00               	mov	eax, 0x80
  471a5d: f2 0f 10 84 06 b0 02 00 00   	movsd	xmm0, qword ptr [esi + eax + 0x2b0]
  471a66: f2 0f 11 84 02 b0 02 00 00   	movsd	qword ptr [edx + eax + 0x2b0], xmm0
  471a6f: f2 0f 10 8c 06 a8 02 00 00   	movsd	xmm1, qword ptr [esi + eax + 0x2a8]
  471a78: f2 0f 11 8c 02 a8 02 00 00   	movsd	qword ptr [edx + eax + 0x2a8], xmm1
  471a81: f2 0f 10 94 06 a0 02 00 00   	movsd	xmm2, qword ptr [esi + eax + 0x2a0]
  471a8a: f2 0f 11 94 02 a0 02 00 00   	movsd	qword ptr [edx + eax + 0x2a0], xmm2
  471a93: f2 0f 10 9c 06 98 02 00 00   	movsd	xmm3, qword ptr [esi + eax + 0x298]
  471a9c: f2 0f 11 9c 02 98 02 00 00   	movsd	qword ptr [edx + eax + 0x298], xmm3
  471aa5: 83 e8 20                     	sub	eax, 0x20
  471aa8: 75 b3                        	jne	0x471a5d <.text+0x70a5d>
  471aaa: f2 0f 10 86 38 03 00 00      	movsd	xmm0, qword ptr [esi + 0x338]
  471ab2: f2 0f 11 82 38 03 00 00      	movsd	qword ptr [edx + 0x338], xmm0
  471aba: f2 0f 10 8e 40 03 00 00      	movsd	xmm1, qword ptr [esi + 0x340]
  471ac2: f2 0f 11 8a 40 03 00 00      	movsd	qword ptr [edx + 0x340], xmm1
  471aca: 0f b6 86 48 03 00 00         	movzx	eax, byte ptr [esi + 0x348]
  471ad1: 88 82 48 03 00 00            	mov	byte ptr [edx + 0x348], al
  471ad7: e8 74 06 00 00               	call	0x472150 <.text+0x71150>
  471adc: 81 c4 50 03 00 00            	add	esp, 0x350
  471ae2: ff 15 98 7a c2 00            	call	dword ptr [0xc27a98]
  471ae8: f2 0f 2a c0                  	cvtsi2sd	xmm0, eax
  471aec: c1 e8 1f                     	shr	eax, 0x1f
  471aef: f2 0f 58 04 c5 80 b7 c2 00   	addsd	xmm0, qword ptr [8*eax + 0xc2b780]
  471af8: f2 0f 5e 44 24 18            	divsd	xmm0, qword ptr [esp + 0x18]
  471afe: f2 0f 11 05 98 90 fe 00      	movsd	qword ptr [0xfe9098], xmm0
  471b06: 68 00 01 00 00               	push	0x100
  471b0b: ff 15 90 59 c2 00            	call	dword ptr [0xc25990]
  471b11: f2 0f 10 06                  	movsd	xmm0, qword ptr [esi]
  471b15: 81 c4 b0 fc ff ff            	add	esp, 0xfffffcb0
  471b1b: 8b d4                        	mov	edx, esp
  471b1d: f2 0f 11 02                  	movsd	qword ptr [edx], xmm0
  471b21: f2 0f 10 4e 48               	movsd	xmm1, qword ptr [esi + 0x48]
  471b26: f2 0f 11 4a 48               	movsd	qword ptr [edx + 0x48], xmm1
  471b2b: b8 40 00 00 00               	mov	eax, 0x40
  471b30: f2 0f 10 04 06               	movsd	xmm0, qword ptr [esi + eax]
  471b35: f2 0f 11 04 02               	movsd	qword ptr [edx + eax], xmm0
  471b3a: f2 0f 10 4c 06 f8            	movsd	xmm1, qword ptr [esi + eax - 0x8]
  471b40: f2 0f 11 4c 02 f8            	movsd	qword ptr [edx + eax - 0x8], xmm1
  471b46: f2 0f 10 54 06 f0            	movsd	xmm2, qword ptr [esi + eax - 0x10]
  471b4c: f2 0f 11 54 02 f0            	movsd	qword ptr [edx + eax - 0x10], xmm2
  471b52: f2 0f 10 5c 06 e8            	movsd	xmm3, qword ptr [esi + eax - 0x18]
  471b58: f2 0f 11 5c 02 e8            	movsd	qword ptr [edx + eax - 0x18], xmm3
  471b5e: 83 e8 20                     	sub	eax, 0x20
  471b61: 75 cd                        	jne	0x471b30 <.text+0x70b30>
  471b63: 8b 46 50                     	mov	eax, dword ptr [esi + 0x50]
  471b66: 8b 4e 54                     	mov	ecx, dword ptr [esi + 0x54]
  471b69: f2 0f 10 46 68               	movsd	xmm0, qword ptr [esi + 0x68]
  471b6e: f2 0f 10 4e 70               	movsd	xmm1, qword ptr [esi + 0x70]
  471b73: f2 0f 11 42 68               	movsd	qword ptr [edx + 0x68], xmm0
  471b78: f2 0f 11 4a 70               	movsd	qword ptr [edx + 0x70], xmm1
  471b7d: 89 42 50                     	mov	dword ptr [edx + 0x50], eax
  471b80: 8b 46 58                     	mov	eax, dword ptr [esi + 0x58]
  471b83: 89 4a 54                     	mov	dword ptr [edx + 0x54], ecx
  471b86: 8b 4e 5c                     	mov	ecx, dword ptr [esi + 0x5c]
  471b89: 89 42 58                     	mov	dword ptr [edx + 0x58], eax
  471b8c: 8b 46 60                     	mov	eax, dword ptr [esi + 0x60]
  471b8f: 89 4a 5c                     	mov	dword ptr [edx + 0x5c], ecx
  471b92: 8b 4e 64                     	mov	ecx, dword ptr [esi + 0x64]
  471b95: 89 42 60                     	mov	dword ptr [edx + 0x60], eax
  471b98: 8b 46 78                     	mov	eax, dword ptr [esi + 0x78]
  471b9b: 89 4a 64                     	mov	dword ptr [edx + 0x64], ecx
  471b9e: 8b 4e 7c                     	mov	ecx, dword ptr [esi + 0x7c]
  471ba1: 89 42 78                     	mov	dword ptr [edx + 0x78], eax
  471ba4: 89 4a 7c                     	mov	dword ptr [edx + 0x7c], ecx
  471ba7: 8d 82 80 00 00 00            	lea	eax, [edx + 0x80]
  471bad: 3b c3                        	cmp	eax, ebx
  471baf: 76 0b                        	jbe	0x471bbc <.text+0x70bbc>
  471bb1: 8b cb                        	mov	ecx, ebx
  471bb3: 2b c8                        	sub	ecx, eax
  471bb5: f7 d9                        	neg	ecx
  471bb7: 83 f9 18                     	cmp	ecx, 0x18
  471bba: 73 0b                        	jae	0x471bc7 <.text+0x70bc7>
  471bbc: 3b d8                        	cmp	ebx, eax
  471bbe: 76 07                        	jbe	0x471bc7 <.text+0x70bc7>
  471bc0: 8b cb                        	mov	ecx, ebx
  471bc2: 2b c8                        	sub	ecx, eax
  471bc4: 83 f9 18                     	cmp	ecx, 0x18
  471bc7: 8b 0b                        	mov	ecx, dword ptr [ebx]
  471bc9: 89 8a 80 00 00 00            	mov	dword ptr [edx + 0x80], ecx
  471bcf: 8b 4b 04                     	mov	ecx, dword ptr [ebx + 0x4]
  471bd2: 89 48 04                     	mov	dword ptr [eax + 0x4], ecx
  471bd5: 8b 4b 08                     	mov	ecx, dword ptr [ebx + 0x8]
  471bd8: 89 48 08                     	mov	dword ptr [eax + 0x8], ecx
  471bdb: 8b 4b 0c                     	mov	ecx, dword ptr [ebx + 0xc]
  471bde: 89 48 0c                     	mov	dword ptr [eax + 0xc], ecx
  471be1: 8b 4b 10                     	mov	ecx, dword ptr [ebx + 0x10]
  471be4: 89 48 10                     	mov	dword ptr [eax + 0x10], ecx
  471be7: 8b 4b 14                     	mov	ecx, dword ptr [ebx + 0x14]
  471bea: f2 0f 10 43 18               	movsd	xmm0, qword ptr [ebx + 0x18]
  471bef: f2 0f 10 4b 38               	movsd	xmm1, qword ptr [ebx + 0x38]
  471bf4: f2 0f 10 53 58               	movsd	xmm2, qword ptr [ebx + 0x58]
  471bf9: f2 0f 11 40 18               	movsd	qword ptr [eax + 0x18], xmm0
  471bfe: f2 0f 11 48 38               	movsd	qword ptr [eax + 0x38], xmm1
  471c03: 89 48 14                     	mov	dword ptr [eax + 0x14], ecx
  471c06: 8b 4b 20                     	mov	ecx, dword ptr [ebx + 0x20]
  471c09: 89 48 20                     	mov	dword ptr [eax + 0x20], ecx
  471c0c: 8b 4b 24                     	mov	ecx, dword ptr [ebx + 0x24]
  471c0f: 89 48 24                     	mov	dword ptr [eax + 0x24], ecx
  471c12: 8b 4b 28                     	mov	ecx, dword ptr [ebx + 0x28]
  471c15: 89 48 28                     	mov	dword ptr [eax + 0x28], ecx
  471c18: 8b 4b 2c                     	mov	ecx, dword ptr [ebx + 0x2c]
  471c1b: 89 48 2c                     	mov	dword ptr [eax + 0x2c], ecx
  471c1e: 8b 4b 30                     	mov	ecx, dword ptr [ebx + 0x30]
  471c21: 89 48 30                     	mov	dword ptr [eax + 0x30], ecx
  471c24: 8b 4b 34                     	mov	ecx, dword ptr [ebx + 0x34]
  471c27: 89 48 34                     	mov	dword ptr [eax + 0x34], ecx
  471c2a: 8b 4b 40                     	mov	ecx, dword ptr [ebx + 0x40]
  471c2d: 89 48 40                     	mov	dword ptr [eax + 0x40], ecx
  471c30: 8b 4b 44                     	mov	ecx, dword ptr [ebx + 0x44]
  471c33: 89 48 44                     	mov	dword ptr [eax + 0x44], ecx
  471c36: 8b 4b 48                     	mov	ecx, dword ptr [ebx + 0x48]
  471c39: 89 48 48                     	mov	dword ptr [eax + 0x48], ecx
  471c3c: 8b 4b 4c                     	mov	ecx, dword ptr [ebx + 0x4c]
  471c3f: 89 48 4c                     	mov	dword ptr [eax + 0x4c], ecx
  471c42: 8b 4b 50                     	mov	ecx, dword ptr [ebx + 0x50]
  471c45: 89 48 50                     	mov	dword ptr [eax + 0x50], ecx
  471c48: 8b 4b 54                     	mov	ecx, dword ptr [ebx + 0x54]
  471c4b: 89 48 54                     	mov	dword ptr [eax + 0x54], ecx
  471c4e: f2 0f 11 92 d8 00 00 00      	movsd	qword ptr [edx + 0xd8], xmm2
  471c56: 8d 8a e0 00 00 00            	lea	ecx, [edx + 0xe0]
  471c5c: 3b 8c 24 54 03 00 00         	cmp	ecx, dword ptr [esp + 0x354]
  471c63: 89 8c 24 5c 03 00 00         	mov	dword ptr [esp + 0x35c], ecx
  471c6a: 76 15                        	jbe	0x471c81 <.text+0x70c81>
  471c6c: 8b 8c 24 54 03 00 00         	mov	ecx, dword ptr [esp + 0x354]
  471c73: 2b 8c 24 5c 03 00 00         	sub	ecx, dword ptr [esp + 0x35c]
  471c7a: f7 d9                        	neg	ecx
  471c7c: 83 f9 48                     	cmp	ecx, 0x48
  471c7f: 73 20                        	jae	0x471ca1 <.text+0x70ca1>
  471c81: 8b 8c 24 54 03 00 00         	mov	ecx, dword ptr [esp + 0x354]
  471c88: 3b 8c 24 5c 03 00 00         	cmp	ecx, dword ptr [esp + 0x35c]
  471c8f: 0f 86 85 00 00 00            	jbe	0x471d1a <.text+0x70d1a>
  471c95: 2b 8c 24 5c 03 00 00         	sub	ecx, dword ptr [esp + 0x35c]
  471c9c: 83 f9 48                     	cmp	ecx, 0x48
  471c9f: 72 79                        	jb	0x471d1a <.text+0x70d1a>
  471ca1: 8b 8c 24 5c 03 00 00         	mov	ecx, dword ptr [esp + 0x35c]
  471ca8: 83 e1 0f                     	and	ecx, 0xf
  471cab: 89 8c 24 5c 03 00 00         	mov	dword ptr [esp + 0x35c], ecx
  471cb2: f7 d9                        	neg	ecx
  471cb4: 83 c1 02                     	add	ecx, 0x2
  471cb7: 83 e1 03                     	and	ecx, 0x3
  471cba: f7 d9                        	neg	ecx
  471cbc: 83 c1 12                     	add	ecx, 0x12
  471cbf: f6 c3 0f                     	test	bl, 0xf
  471cc2: 74 23                        	je	0x471ce7 <.text+0x70ce7>
  471cc4: 89 b4 24 50 03 00 00         	mov	dword ptr [esp + 0x350], esi
  471ccb: 8b b4 24 5c 03 00 00         	mov	esi, dword ptr [esp + 0x35c]
  471cd2: f3 0f 6f 44 b3 60            	movdqu	xmm0, xmmword ptr [ebx + 4*esi + 0x60]
  471cd8: 66 0f 7f 44 b0 60            	movdqa	xmmword ptr [eax + 4*esi + 0x60], xmm0
  471cde: 83 c6 04                     	add	esi, 0x4
  471ce1: 3b f1                        	cmp	esi, ecx
  471ce3: 72 ed                        	jb	0x471cd2 <.text+0x70cd2>
  471ce5: eb 21                        	jmp	0x471d08 <.text+0x70d08>
  471ce7: 89 b4 24 50 03 00 00         	mov	dword ptr [esp + 0x350], esi
  471cee: 8b b4 24 5c 03 00 00         	mov	esi, dword ptr [esp + 0x35c]
  471cf5: 66 0f 6f 44 b3 60            	movdqa	xmm0, xmmword ptr [ebx + 4*esi + 0x60]
  471cfb: 66 0f 7f 44 b0 60            	movdqa	xmmword ptr [eax + 4*esi + 0x60], xmm0
  471d01: 83 c6 04                     	add	esi, 0x4
  471d04: 3b f1                        	cmp	esi, ecx
  471d06: 72 ed                        	jb	0x471cf5 <.text+0x70cf5>
  471d08: 8b b4 24 50 03 00 00         	mov	esi, dword ptr [esp + 0x350]
  471d0f: 83 f9 12                     	cmp	ecx, 0x12
  471d12: 0f 82 06 04 00 00            	jb	0x47211e <.text+0x7111e>
  471d18: eb 1e                        	jmp	0x471d38 <.text+0x70d38>
  471d1a: 89 b4 24 50 03 00 00         	mov	dword ptr [esp + 0x350], esi
  471d21: 33 c9                        	xor	ecx, ecx
  471d23: 8b 74 8b 60                  	mov	esi, dword ptr [ebx + 4*ecx + 0x60]
  471d27: 89 74 88 60                  	mov	dword ptr [eax + 4*ecx + 0x60], esi
  471d2b: 41                           	inc	ecx
  471d2c: 83 f9 12                     	cmp	ecx, 0x12
  471d2f: 72 f2                        	jb	0x471d23 <.text+0x70d23>
  471d31: 8b b4 24 50 03 00 00         	mov	esi, dword ptr [esp + 0x350]
  471d38: f2 0f 10 83 a8 00 00 00      	movsd	xmm0, qword ptr [ebx + 0xa8]
  471d40: f2 0f 10 8b b0 00 00 00      	movsd	xmm1, qword ptr [ebx + 0xb0]
  471d48: f2 0f 11 82 28 01 00 00      	movsd	qword ptr [edx + 0x128], xmm0
  471d50: f2 0f 11 8a 30 01 00 00      	movsd	qword ptr [edx + 0x130], xmm1
  471d58: 8d 8a 38 01 00 00            	lea	ecx, [edx + 0x138]
  471d5e: 3b cf                        	cmp	ecx, edi
  471d60: 76 0b                        	jbe	0x471d6d <.text+0x70d6d>
  471d62: 8b c7                        	mov	eax, edi
  471d64: 2b c1                        	sub	eax, ecx
  471d66: f7 d8                        	neg	eax
  471d68: 83 f8 18                     	cmp	eax, 0x18
  471d6b: 73 0b                        	jae	0x471d78 <.text+0x70d78>
  471d6d: 3b f9                        	cmp	edi, ecx
  471d6f: 76 07                        	jbe	0x471d78 <.text+0x70d78>
  471d71: 8b c7                        	mov	eax, edi
  471d73: 2b c1                        	sub	eax, ecx
  471d75: 83 f8 18                     	cmp	eax, 0x18
  471d78: 8b 07                        	mov	eax, dword ptr [edi]
  471d7a: 8b 5f 04                     	mov	ebx, dword ptr [edi + 0x4]
  471d7d: 89 82 38 01 00 00            	mov	dword ptr [edx + 0x138], eax
  471d83: 8b 47 08                     	mov	eax, dword ptr [edi + 0x8]
  471d86: 89 59 04                     	mov	dword ptr [ecx + 0x4], ebx
  471d89: 8b 5f 0c                     	mov	ebx, dword ptr [edi + 0xc]
  471d8c: 89 41 08                     	mov	dword ptr [ecx + 0x8], eax
  471d8f: 8b 47 10                     	mov	eax, dword ptr [edi + 0x10]
  471d92: 89 59 0c                     	mov	dword ptr [ecx + 0xc], ebx
  471d95: 89 41 10                     	mov	dword ptr [ecx + 0x10], eax
  471d98: 8b 47 14                     	mov	eax, dword ptr [edi + 0x14]
  471d9b: f2 0f 10 47 18               	movsd	xmm0, qword ptr [edi + 0x18]
  471da0: 8b 5f 24                     	mov	ebx, dword ptr [edi + 0x24]
  471da3: f2 0f 10 4f 38               	movsd	xmm1, qword ptr [edi + 0x38]
  471da8: f2 0f 10 57 58               	movsd	xmm2, qword ptr [edi + 0x58]
  471dad: f2 0f 11 41 18               	movsd	qword ptr [ecx + 0x18], xmm0
  471db2: f2 0f 11 49 38               	movsd	qword ptr [ecx + 0x38], xmm1
  471db7: 89 41 14                     	mov	dword ptr [ecx + 0x14], eax
  471dba: 8b 47 20                     	mov	eax, dword ptr [edi + 0x20]
  471dbd: 89 41 20                     	mov	dword ptr [ecx + 0x20], eax
  471dc0: 8b 47 28                     	mov	eax, dword ptr [edi + 0x28]
  471dc3: 89 59 24                     	mov	dword ptr [ecx + 0x24], ebx
  471dc6: 8b 5f 2c                     	mov	ebx, dword ptr [edi + 0x2c]
  471dc9: 89 41 28                     	mov	dword ptr [ecx + 0x28], eax
  471dcc: 8b 47 30                     	mov	eax, dword ptr [edi + 0x30]
  471dcf: 89 59 2c                     	mov	dword ptr [ecx + 0x2c], ebx
  471dd2: 8b 5f 34                     	mov	ebx, dword ptr [edi + 0x34]
  471dd5: 89 41 30                     	mov	dword ptr [ecx + 0x30], eax
  471dd8: 8b 47 40                     	mov	eax, dword ptr [edi + 0x40]
  471ddb: 89 59 34                     	mov	dword ptr [ecx + 0x34], ebx
  471dde: 8b 5f 44                     	mov	ebx, dword ptr [edi + 0x44]
  471de1: 89 41 40                     	mov	dword ptr [ecx + 0x40], eax
  471de4: 8b 47 48                     	mov	eax, dword ptr [edi + 0x48]
  471de7: 89 59 44                     	mov	dword ptr [ecx + 0x44], ebx
  471dea: 8b 5f 4c                     	mov	ebx, dword ptr [edi + 0x4c]
  471ded: 89 41 48                     	mov	dword ptr [ecx + 0x48], eax
  471df0: 8b 47 50                     	mov	eax, dword ptr [edi + 0x50]
  471df3: 89 59 4c                     	mov	dword ptr [ecx + 0x4c], ebx
  471df6: 8b 5f 54                     	mov	ebx, dword ptr [edi + 0x54]
  471df9: 89 41 50                     	mov	dword ptr [ecx + 0x50], eax
  471dfc: 89 59 54                     	mov	dword ptr [ecx + 0x54], ebx
  471dff: f2 0f 11 92 90 01 00 00      	movsd	qword ptr [edx + 0x190], xmm2
  471e07: 8d 9a 98 01 00 00            	lea	ebx, [edx + 0x198]
  471e0d: 3b 9c 24 58 03 00 00         	cmp	ebx, dword ptr [esp + 0x358]
  471e14: 76 10                        	jbe	0x471e26 <.text+0x70e26>
  471e16: 8b 84 24 58 03 00 00         	mov	eax, dword ptr [esp + 0x358]
  471e1d: 2b c3                        	sub	eax, ebx
  471e1f: f7 d8                        	neg	eax
  471e21: 83 f8 48                     	cmp	eax, 0x48
  471e24: 73 1f                        	jae	0x471e45 <.text+0x70e45>
  471e26: 3b 9c 24 58 03 00 00         	cmp	ebx, dword ptr [esp + 0x358]
  471e2d: 0f 83 a8 00 00 00            	jae	0x471edb <.text+0x70edb>
  471e33: 8b 84 24 58 03 00 00         	mov	eax, dword ptr [esp + 0x358]
  471e3a: 2b c3                        	sub	eax, ebx
  471e3c: 83 f8 48                     	cmp	eax, 0x48
  471e3f: 0f 82 96 00 00 00            	jb	0x471edb <.text+0x70edb>
  471e45: 83 e3 0f                     	and	ebx, 0xf
  471e48: 89 b4 24 50 03 00 00         	mov	dword ptr [esp + 0x350], esi
  471e4f: f7 db                        	neg	ebx
  471e51: 83 c3 10                     	add	ebx, 0x10
  471e54: c1 eb 02                     	shr	ebx, 0x2
  471e57: 33 c0                        	xor	eax, eax
  471e59: 8b 74 87 60                  	mov	esi, dword ptr [edi + 4*eax + 0x60]
  471e5d: 89 74 81 60                  	mov	dword ptr [ecx + 4*eax + 0x60], esi
  471e61: 40                           	inc	eax
  471e62: 3b c3                        	cmp	eax, ebx
  471e64: 72 f3                        	jb	0x471e59 <.text+0x70e59>
  471e66: 8b b4 24 50 03 00 00         	mov	esi, dword ptr [esp + 0x350]
  471e6d: 8b c3                        	mov	eax, ebx
  471e6f: f7 d8                        	neg	eax
  471e71: 83 c0 02                     	add	eax, 0x2
  471e74: 83 e0 03                     	and	eax, 0x3
  471e77: f7 d8                        	neg	eax
  471e79: 83 c0 12                     	add	eax, 0x12
  471e7c: 89 84 24 50 03 00 00         	mov	dword ptr [esp + 0x350], eax
  471e83: 8d 84 9e 38 01 00 00         	lea	eax, [esi + 4*ebx + 0x138]
  471e8a: a8 0f                        	test	al, 0xf
  471e8c: 74 1c                        	je	0x471eaa <.text+0x70eaa>
  471e8e: 8b 84 24 50 03 00 00         	mov	eax, dword ptr [esp + 0x350]
  471e95: f3 0f 6f 44 9f 60            	movdqu	xmm0, xmmword ptr [edi + 4*ebx + 0x60]
  471e9b: 66 0f 7f 44 99 60            	movdqa	xmmword ptr [ecx + 4*ebx + 0x60], xmm0
  471ea1: 83 c3 04                     	add	ebx, 0x4
  471ea4: 3b d8                        	cmp	ebx, eax
  471ea6: 72 ed                        	jb	0x471e95 <.text+0x70e95>
  471ea8: eb 1a                        	jmp	0x471ec4 <.text+0x70ec4>
  471eaa: 8b 84 24 50 03 00 00         	mov	eax, dword ptr [esp + 0x350]
  471eb1: 66 0f 6f 44 9f 60            	movdqa	xmm0, xmmword ptr [edi + 4*ebx + 0x60]
  471eb7: 66 0f 7f 44 99 60            	movdqa	xmmword ptr [ecx + 4*ebx + 0x60], xmm0
  471ebd: 83 c3 04                     	add	ebx, 0x4
  471ec0: 3b d8                        	cmp	ebx, eax
  471ec2: 72 ed                        	jb	0x471eb1 <.text+0x70eb1>
  471ec4: 89 84 24 50 03 00 00         	mov	dword ptr [esp + 0x350], eax
  471ecb: 83 bc 24 50 03 00 00 12      	cmp	dword ptr [esp + 0x350], 0x12
  471ed3: 0f 82 5f 02 00 00            	jb	0x472138 <.text+0x71138>
  471ed9: eb 10                        	jmp	0x471eeb <.text+0x70eeb>
  471edb: 33 c0                        	xor	eax, eax
  471edd: 8b 5c 87 60                  	mov	ebx, dword ptr [edi + 4*eax + 0x60]
  471ee1: 89 5c 81 60                  	mov	dword ptr [ecx + 4*eax + 0x60], ebx
  471ee5: 40                           	inc	eax
  471ee6: 83 f8 12                     	cmp	eax, 0x12
  471ee9: 72 f2                        	jb	0x471edd <.text+0x70edd>
  471eeb: f2 0f 10 87 a8 00 00 00      	movsd	xmm0, qword ptr [edi + 0xa8]
  471ef3: f2 0f 10 8f b0 00 00 00      	movsd	xmm1, qword ptr [edi + 0xb0]
  471efb: 8b be f0 01 00 00            	mov	edi, dword ptr [esi + 0x1f0]
  471f01: 8b 86 f4 01 00 00            	mov	eax, dword ptr [esi + 0x1f4]
  471f07: 8b 8e f8 01 00 00            	mov	ecx, dword ptr [esi + 0x1f8]
  471f0d: 8b 9e fc 01 00 00            	mov	ebx, dword ptr [esi + 0x1fc]
  471f13: f2 0f 11 82 e0 01 00 00      	movsd	qword ptr [edx + 0x1e0], xmm0
  471f1b: f2 0f 11 8a e8 01 00 00      	movsd	qword ptr [edx + 0x1e8], xmm1
  471f23: 89 ba f0 01 00 00            	mov	dword ptr [edx + 0x1f0], edi
  471f29: 8b be 00 02 00 00            	mov	edi, dword ptr [esi + 0x200]
  471f2f: 89 82 f4 01 00 00            	mov	dword ptr [edx + 0x1f4], eax
  471f35: 8b 86 04 02 00 00            	mov	eax, dword ptr [esi + 0x204]
  471f3b: 89 8a f8 01 00 00            	mov	dword ptr [edx + 0x1f8], ecx
  471f41: 8b 8e 08 02 00 00            	mov	ecx, dword ptr [esi + 0x208]
  471f47: 89 9a fc 01 00 00            	mov	dword ptr [edx + 0x1fc], ebx
  471f4d: 8b 9e 0c 02 00 00            	mov	ebx, dword ptr [esi + 0x20c]
  471f53: 89 ba 00 02 00 00            	mov	dword ptr [edx + 0x200], edi
  471f59: 8b be 10 02 00 00            	mov	edi, dword ptr [esi + 0x210]
  471f5f: 89 82 04 02 00 00            	mov	dword ptr [edx + 0x204], eax
  471f65: 8b 86 14 02 00 00            	mov	eax, dword ptr [esi + 0x214]
  471f6b: 89 8a 08 02 00 00            	mov	dword ptr [edx + 0x208], ecx
  471f71: 8b 8e 18 02 00 00            	mov	ecx, dword ptr [esi + 0x218]
  471f77: 89 9a 0c 02 00 00            	mov	dword ptr [edx + 0x20c], ebx
  471f7d: 8b 9e 1c 02 00 00            	mov	ebx, dword ptr [esi + 0x21c]
  471f83: 89 ba 10 02 00 00            	mov	dword ptr [edx + 0x210], edi
  471f89: 8b be 20 02 00 00            	mov	edi, dword ptr [esi + 0x220]
  471f8f: 89 82 14 02 00 00            	mov	dword ptr [edx + 0x214], eax
  471f95: 8b 86 24 02 00 00            	mov	eax, dword ptr [esi + 0x224]
  471f9b: 89 8a 18 02 00 00            	mov	dword ptr [edx + 0x218], ecx
  471fa1: 0f b6 8e 28 02 00 00         	movzx	ecx, byte ptr [esi + 0x228]
  471fa8: 89 9a 1c 02 00 00            	mov	dword ptr [edx + 0x21c], ebx
  471fae: 8b 9e 2c 02 00 00            	mov	ebx, dword ptr [esi + 0x22c]
  471fb4: 89 ba 20 02 00 00            	mov	dword ptr [edx + 0x220], edi
  471fba: 89 82 24 02 00 00            	mov	dword ptr [edx + 0x224], eax
  471fc0: 8b 86 30 02 00 00            	mov	eax, dword ptr [esi + 0x230]
  471fc6: 88 8a 28 02 00 00            	mov	byte ptr [edx + 0x228], cl
  471fcc: 89 9a 2c 02 00 00            	mov	dword ptr [edx + 0x22c], ebx
  471fd2: 89 82 30 02 00 00            	mov	dword ptr [edx + 0x230], eax
  471fd8: b8 80 00 00 00               	mov	eax, 0x80
  471fdd: f2 0f 10 84 06 30 02 00 00   	movsd	xmm0, qword ptr [esi + eax + 0x230]
  471fe6: f2 0f 11 84 02 30 02 00 00   	movsd	qword ptr [edx + eax + 0x230], xmm0
  471fef: f2 0f 10 8c 06 28 02 00 00   	movsd	xmm1, qword ptr [esi + eax + 0x228]
  471ff8: f2 0f 11 8c 02 28 02 00 00   	movsd	qword ptr [edx + eax + 0x228], xmm1
  472001: f2 0f 10 94 06 20 02 00 00   	movsd	xmm2, qword ptr [esi + eax + 0x220]
  47200a: f2 0f 11 94 02 20 02 00 00   	movsd	qword ptr [edx + eax + 0x220], xmm2
  472013: f2 0f 10 9c 06 18 02 00 00   	movsd	xmm3, qword ptr [esi + eax + 0x218]
  47201c: f2 0f 11 9c 02 18 02 00 00   	movsd	qword ptr [edx + eax + 0x218], xmm3
  472025: 83 e8 20                     	sub	eax, 0x20
  472028: 75 b3                        	jne	0x471fdd <.text+0x70fdd>
  47202a: b8 80 00 00 00               	mov	eax, 0x80
  47202f: f2 0f 10 84 06 b0 02 00 00   	movsd	xmm0, qword ptr [esi + eax + 0x2b0]
  472038: f2 0f 11 84 02 b0 02 00 00   	movsd	qword ptr [edx + eax + 0x2b0], xmm0
  472041: f2 0f 10 8c 06 a8 02 00 00   	movsd	xmm1, qword ptr [esi + eax + 0x2a8]
  47204a: f2 0f 11 8c 02 a8 02 00 00   	movsd	qword ptr [edx + eax + 0x2a8], xmm1
  472053: f2 0f 10 94 06 a0 02 00 00   	movsd	xmm2, qword ptr [esi + eax + 0x2a0]
  47205c: f2 0f 11 94 02 a0 02 00 00   	movsd	qword ptr [edx + eax + 0x2a0], xmm2
  472065: f2 0f 10 9c 06 98 02 00 00   	movsd	xmm3, qword ptr [esi + eax + 0x298]
  47206e: f2 0f 11 9c 02 98 02 00 00   	movsd	qword ptr [edx + eax + 0x298], xmm3
  472077: 83 e8 20                     	sub	eax, 0x20
  47207a: 75 b3                        	jne	0x47202f <.text+0x7102f>
  47207c: f2 0f 10 86 38 03 00 00      	movsd	xmm0, qword ptr [esi + 0x338]
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
