
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  4734d0: ff 15 60 59 c2 00            	call	dword ptr [0xc25960]
  4734d6: b8 0a d7 23 3c               	mov	eax, 0x3c23d70a
  4734db: 50                           	push	eax
  4734dc: 50                           	push	eax
  4734dd: 50                           	push	eax
  4734de: ff 15 50 59 c2 00            	call	dword ptr [0xc25950]
  4734e4: 8d 45 90                     	lea	eax, [ebp - 0x70]
  4734e7: 83 c4 ec                     	add	esp, -0x14
  4734ea: c7 44 24 04 ec c8 c2 00      	mov	dword ptr [esp + 0x4], 0xc2c8ec
  4734f2: 33 d2                        	xor	edx, edx
  4734f4: c7 44 24 08 f8 c8 c2 00      	mov	dword ptr [esp + 0x8], 0xc2c8f8
  4734fc: 89 04 24                     	mov	dword ptr [esp], eax
  4734ff: 89 54 24 0c                  	mov	dword ptr [esp + 0xc], edx
  473503: 89 54 24 10                  	mov	dword ptr [esp + 0x10], edx
  473507: ff 15 b8 60 c2 00            	call	dword ptr [0xc260b8]
  47350d: 83 c4 14                     	add	esp, 0x14
  473510: c7 45 fc 01 00 00 00         	mov	dword ptr [ebp - 0x4], 0x1
  473517: 8d 45 94                     	lea	eax, [ebp - 0x6c]
  47351a: 50                           	push	eax
  47351b: 8d 4d 90                     	lea	ecx, [ebp - 0x70]
  47351e: ff 15 3c 61 c2 00            	call	dword ptr [0xc2613c]
  473524: c7 45 fc 02 00 00 00         	mov	dword ptr [ebp - 0x4], 0x2
  47352b: 8b 45 94                     	mov	eax, dword ptr [ebp - 0x6c]
  47352e: 8b 50 0c                     	mov	edx, dword ptr [eax + 0xc]
  473531: 83 c4 f8                     	add	esp, -0x8
  473534: 89 14 24                     	mov	dword ptr [esp], edx
  473537: 89 7c 24 04                  	mov	dword ptr [esp + 0x4], edi
  47353b: e8 b0 36 06 00               	call	0x4d6bf0 <.text+0xd5bf0>
  473540: 83 c4 08                     	add	esp, 0x8
  473543: c7 45 fc 01 00 00 00         	mov	dword ptr [ebp - 0x4], 0x1
  47354a: 8b 55 94                     	mov	edx, dword ptr [ebp - 0x6c]
  47354d: 83 c8 ff                     	or	eax, -0x1
  473550: f0                           	lock
  473551: 0f c1 02                     	xadd	dword ptr [edx], eax
  473554: 48                           	dec	eax
  473555: 85 c0                        	test	eax, eax
  473557: 75 0b                        	jne	0x473564 <.text+0x72564>
  473559: 50                           	push	eax
  47355a: 89 14 24                     	mov	dword ptr [esp], edx
  47355d: ff 15 1c 61 c2 00            	call	dword ptr [0xc2611c]
  473563: 59                           	pop	ecx
  473564: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  47356b: 8b 55 90                     	mov	edx, dword ptr [ebp - 0x70]
  47356e: 83 c8 ff                     	or	eax, -0x1
  473571: f0                           	lock
  473572: 0f c1 02                     	xadd	dword ptr [edx], eax
  473575: 48                           	dec	eax
  473576: 85 c0                        	test	eax, eax
  473578: 75 0b                        	jne	0x473585 <.text+0x72585>
  47357a: 50                           	push	eax
  47357b: 89 14 24                     	mov	dword ptr [esp], edx
  47357e: ff 15 88 61 c2 00            	call	dword ptr [0xc26188]
  473584: 59                           	pop	ecx
  473585: ff 15 08 59 c2 00            	call	dword ptr [0xc25908]
  47358b: 83 c7 0f                     	add	edi, 0xf
  47358e: 83 ff 5a                     	cmp	edi, 0x5a
  473591: 0f 8e a9 fe ff ff            	jle	0x473440 <.text+0x72440>
  473597: ff 15 68 59 c2 00            	call	dword ptr [0xc25968]
  47359d: a1 d0 92 fe 00               	mov	eax, dword ptr [0xfe92d0]
  4735a2: e9 a4 fb ff ff               	jmp	0x47314b <.text+0x7214b>
  4735a7: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  4735aa: 8d 4d 90                     	lea	ecx, [ebp - 0x70]
  4735ad: ff 15 8c 61 c2 00            	call	dword ptr [0xc2618c]
  4735b3: c3                           	ret
  4735b4: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  4735b7: 8d 4d c8                     	lea	ecx, [ebp - 0x38]
  4735ba: ff 15 8c 61 c2 00            	call	dword ptr [0xc2618c]
  4735c0: c3                           	ret
  4735c1: 8b 5d ec                     	mov	ebx, dword ptr [ebp - 0x14]
  4735c4: 8d 4d c0                     	lea	ecx, [ebp - 0x40]
  4735c7: ff 15 8c 61 c2 00            	call	dword ptr [0xc2618c]
  4735cd: c3                           	ret
  4735ce: 90                           	nop
  4735cf: 90                           	nop
  4735d0: c3                           	ret
  4735d1: 90                           	nop
  4735d2: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  4735d9: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  4735e0: 53                           	push	ebx
  4735e1: 8b dc                        	mov	ebx, esp
  4735e3: 83 e4 f0                     	and	esp, -0x10
  4735e6: 55                           	push	ebp
  4735e7: 55                           	push	ebp
  4735e8: 8b 6b 04                     	mov	ebp, dword ptr [ebx + 0x4]
  4735eb: 89 6c 24 04                  	mov	dword ptr [esp + 0x4], ebp
  4735ef: 8b ec                        	mov	ebp, esp
  4735f1: 6a ff                        	push	-0x1
  4735f3: 68 60 38 bf 00               	push	0xbf3860
  4735f8: 64 a1 00 00 00 00            	mov	eax, dword ptr fs:[0x0]
  4735fe: 50                           	push	eax
  4735ff: 64 89 25 00 00 00 00         	mov	dword ptr fs:[0x0], esp
  473606: 81 ec bc 00 00 00            	sub	esp, 0xbc
  47360c: 89 65 f0                     	mov	dword ptr [ebp - 0x10], esp
  47360f: 89 5d ec                     	mov	dword ptr [ebp - 0x14], ebx
  473612: 89 7d a4                     	mov	dword ptr [ebp - 0x5c], edi
  473615: 89 75 c4                     	mov	dword ptr [ebp - 0x3c], esi
  473618: a1 10 53 d8 00               	mov	eax, dword ptr [0xd85310]
  47361d: 89 45 e4                     	mov	dword ptr [ebp - 0x1c], eax
  473620: c7 45 fc 00 00 00 00         	mov	dword ptr [ebp - 0x4], 0x0
  473627: 8b 93 10 02 00 00            	mov	edx, dword ptr [ebx + 0x210]
  47362d: 8b 8b 14 02 00 00            	mov	ecx, dword ptr [ebx + 0x214]
  473633: 8d 45 cc                     	lea	eax, [ebp - 0x34]
  473636: 83 c4 f4                     	add	esp, -0xc
  473639: 89 04 24                     	mov	dword ptr [esp], eax
  47363c: 89 54 24 04                  	mov	dword ptr [esp + 0x4], edx
  473640: 89 4c 24 08                  	mov	dword ptr [esp + 0x8], ecx
  473644: e8 a7 cb 0e 00               	call	0x5601f0 <.text+0x15f1f0>
  473649: 83 c4 0c                     	add	esp, 0xc
  47364c: 8b 45 cc                     	mov	eax, dword ptr [ebp - 0x34]
  47364f: 8b 55 d0                     	mov	edx, dword ptr [ebp - 0x30]
  473652: 8b 4d d4                     	mov	ecx, dword ptr [ebp - 0x2c]
  473655: 8b 75 d8                     	mov	esi, dword ptr [ebp - 0x28]
  473658: 8b 7d dc                     	mov	edi, dword ptr [ebp - 0x24]
  47365b: c6 83 50 03 00 00 01         	mov	byte ptr [ebx + 0x350], 0x1
  473662: 89 83 18 02 00 00            	mov	dword ptr [ebx + 0x218], eax
  473668: 8b 45 e0                     	mov	eax, dword ptr [ebp - 0x20]
  47366b: 89 93 1c 02 00 00            	mov	dword ptr [ebx + 0x21c], edx
  473671: 89 8b 20 02 00 00            	mov	dword ptr [ebx + 0x220], ecx
  473677: 50                           	push	eax
  473678: 89 b3 24 02 00 00            	mov	dword ptr [ebx + 0x224], esi
  47367e: 89 bb 28 02 00 00            	mov	dword ptr [ebx + 0x228], edi
  473684: 89 83 2c 02 00 00            	mov	dword ptr [ebx + 0x22c], eax
  47368a: 8d 93 18 02 00 00            	lea	edx, [ebx + 0x218]
  473690: 89 14 24                     	mov	dword ptr [esp], edx
  473693: e8 28 98 fc ff               	call	0x43cec0 <.text+0x3bec0>
  473698: 59                           	pop	ecx
  473699: 68 00 17 00 00               	push	0x1700
  47369e: ff 15 c4 58 c2 00            	call	dword ptr [0xc258c4]
  4736a4: 8d 83 40 02 00 00            	lea	eax, [ebx + 0x240]
  4736aa: 50                           	push	eax
  4736ab: 68 a6 0b 00 00               	push	0xba6
  4736b0: ff 15 94 59 c2 00            	call	dword ptr [0xc25994]
  4736b6: 8d 83 c0 02 00 00            	lea	eax, [ebx + 0x2c0]
  4736bc: 50                           	push	eax
  4736bd: 68 a7 0b 00 00               	push	0xba7
  4736c2: ff 15 94 59 c2 00            	call	dword ptr [0xc25994]
  4736c8: 8d 83 40 03 00 00            	lea	eax, [ebx + 0x340]
  4736ce: 50                           	push	eax
  4736cf: 68 a2 0b 00 00               	push	0xba2
  4736d4: ff 15 f0 58 c2 00            	call	dword ptr [0xc258f0]
  4736da: f2 0f 10 83 40 02 00 00      	movsd	xmm0, qword ptr [ebx + 0x240]
  4736e2: 66 0f 16 83 48 02 00 00      	movhpd	xmm0, qword ptr [ebx + 0x248] # xmm0 = xmm0[0],mem[0]
  4736ea: f2 0f 10 8b c0 02 00 00      	movsd	xmm1, qword ptr [ebx + 0x2c0]
  4736f2: 66 0f 16 8b c8 02 00 00      	movhpd	xmm1, qword ptr [ebx + 0x2c8] # xmm1 = xmm1[0],mem[0]
  4736fa: f2 0f 10 93 50 02 00 00      	movsd	xmm2, qword ptr [ebx + 0x250]
  473702: 66 0f 16 93 58 02 00 00      	movhpd	xmm2, qword ptr [ebx + 0x258] # xmm2 = xmm2[0],mem[0]
  47370a: f2 0f 10 9b d0 02 00 00      	movsd	xmm3, qword ptr [ebx + 0x2d0]
  473712: 66 0f 16 9b d8 02 00 00      	movhpd	xmm3, qword ptr [ebx + 0x2d8] # xmm3 = xmm3[0],mem[0]
  47371a: f2 0f 10 a3 60 02 00 00      	movsd	xmm4, qword ptr [ebx + 0x260]
  473722: 66 0f 16 a3 68 02 00 00      	movhpd	xmm4, qword ptr [ebx + 0x268] # xmm4 = xmm4[0],mem[0]
  47372a: f2 0f 10 ab e0 02 00 00      	movsd	xmm5, qword ptr [ebx + 0x2e0]
  473732: 66 0f 16 ab e8 02 00 00      	movhpd	xmm5, qword ptr [ebx + 0x2e8] # xmm5 = xmm5[0],mem[0]
  47373a: f2 0f 10 b3 70 02 00 00      	movsd	xmm6, qword ptr [ebx + 0x270]
  473742: 66 0f 16 b3 78 02 00 00      	movhpd	xmm6, qword ptr [ebx + 0x278] # xmm6 = xmm6[0],mem[0]
  47374a: f2 0f 10 bb f0 02 00 00      	movsd	xmm7, qword ptr [ebx + 0x2f0]
  473752: 66 0f 16 bb f8 02 00 00      	movhpd	xmm7, qword ptr [ebx + 0x2f8] # xmm7 = xmm7[0],mem[0]
  47375a: 0f 29 05 c0 76 fe 00         	movaps	xmmword ptr [0xfe76c0], xmm0
  473761: f2 0f 10 83 80 02 00 00      	movsd	xmm0, qword ptr [ebx + 0x280]
  473769: 66 0f 16 83 88 02 00 00      	movhpd	xmm0, qword ptr [ebx + 0x288] # xmm0 = xmm0[0],mem[0]
  473771: 0f 29 0d 40 77 fe 00         	movaps	xmmword ptr [0xfe7740], xmm1
  473778: f2 0f 10 8b 00 03 00 00      	movsd	xmm1, qword ptr [ebx + 0x300]
  473780: 66 0f 16 8b 08 03 00 00      	movhpd	xmm1, qword ptr [ebx + 0x308] # xmm1 = xmm1[0],mem[0]
  473788: 0f 29 15 d0 76 fe 00         	movaps	xmmword ptr [0xfe76d0], xmm2
  47378f: f2 0f 10 93 90 02 00 00      	movsd	xmm2, qword ptr [ebx + 0x290]
  473797: 66 0f 16 93 98 02 00 00      	movhpd	xmm2, qword ptr [ebx + 0x298] # xmm2 = xmm2[0],mem[0]
  47379f: 0f 29 1d 50 77 fe 00         	movaps	xmmword ptr [0xfe7750], xmm3
  4737a6: f2 0f 10 9b 10 03 00 00      	movsd	xmm3, qword ptr [ebx + 0x310]
  4737ae: 66 0f 16 9b 18 03 00 00      	movhpd	xmm3, qword ptr [ebx + 0x318] # xmm3 = xmm3[0],mem[0]
  4737b6: 0f 29 25 e0 76 fe 00         	movaps	xmmword ptr [0xfe76e0], xmm4
  4737bd: f2 0f 10 a3 a0 02 00 00      	movsd	xmm4, qword ptr [ebx + 0x2a0]
  4737c5: 66 0f 16 a3 a8 02 00 00      	movhpd	xmm4, qword ptr [ebx + 0x2a8] # xmm4 = xmm4[0],mem[0]
  4737cd: 0f 29 2d 60 77 fe 00         	movaps	xmmword ptr [0xfe7760], xmm5
  4737d4: f2 0f 10 ab 20 03 00 00      	movsd	xmm5, qword ptr [ebx + 0x320]
  4737dc: 66 0f 16 ab 28 03 00 00      	movhpd	xmm5, qword ptr [ebx + 0x328] # xmm5 = xmm5[0],mem[0]
  4737e4: 0f 29 35 f0 76 fe 00         	movaps	xmmword ptr [0xfe76f0], xmm6
  4737eb: f2 0f 10 b3 b0 02 00 00      	movsd	xmm6, qword ptr [ebx + 0x2b0]
  4737f3: 66 0f 16 b3 b8 02 00 00      	movhpd	xmm6, qword ptr [ebx + 0x2b8] # xmm6 = xmm6[0],mem[0]
  4737fb: 0f 29 3d 70 77 fe 00         	movaps	xmmword ptr [0xfe7770], xmm7
  473802: f3 0f 6f bb 40 03 00 00      	movdqu	xmm7, xmmword ptr [ebx + 0x340]
  47380a: 0f 29 05 00 77 fe 00         	movaps	xmmword ptr [0xfe7700], xmm0
  473811: f2 0f 10 83 30 03 00 00      	movsd	xmm0, qword ptr [ebx + 0x330]
  473819: 66 0f 16 83 38 03 00 00      	movhpd	xmm0, qword ptr [ebx + 0x338] # xmm0 = xmm0[0],mem[0]
  473821: 0f 29 0d 80 77 fe 00         	movaps	xmmword ptr [0xfe7780], xmm1
  473828: 0f 29 15 10 77 fe 00         	movaps	xmmword ptr [0xfe7710], xmm2
  47382f: 0f 29 1d 90 77 fe 00         	movaps	xmmword ptr [0xfe7790], xmm3
  473836: 0f 29 25 20 77 fe 00         	movaps	xmmword ptr [0xfe7720], xmm4
  47383d: 0f 29 2d a0 77 fe 00         	movaps	xmmword ptr [0xfe77a0], xmm5
  473844: 0f 29 35 30 77 fe 00         	movaps	xmmword ptr [0xfe7730], xmm6
  47384b: 0f 29 05 b0 77 fe 00         	movaps	xmmword ptr [0xfe77b0], xmm0
  473852: 66 0f 7f 3d 70 90 fe 00      	movdqa	xmmword ptr [0xfe9070], xmm7
  47385a: 8d 7b 08                     	lea	edi, [ebx + 0x8]
  47385d: 50                           	push	eax
  47385e: 89 3c 24                     	mov	dword ptr [esp], edi
  473861: e8 8a 7d 07 00               	call	0x4eb5f0 <.text+0xea5f0>
  473866: 59                           	pop	ecx
  473867: 50                           	push	eax
  473868: 89 3c 24                     	mov	dword ptr [esp], edi
  47386b: e8 20 44 07 00               	call	0x4e7c90 <.text+0xe6c90>
  473870: 59                           	pop	ecx
  473871: 50                           	push	eax
  473872: 89 3c 24                     	mov	dword ptr [esp], edi
  473875: e8 26 fd 0a 00               	call	0x5235a0 <.text+0x1225a0>
  47387a: 59                           	pop	ecx
  47387b: 50                           	push	eax
  47387c: 89 3c 24                     	mov	dword ptr [esp], edi
  47387f: e8 9c 0d 08 00               	call	0x4f4620 <.text+0xf3620>
  473884: 59                           	pop	ecx
  473885: c7 45 fc 02 00 00 00         	mov	dword ptr [ebp - 0x4], 0x2
  47388c: c7 85 6c ff ff ff 0f 00 00 00	mov	dword ptr [ebp - 0x94], 0xf
  473896: 33 c0                        	xor	eax, eax
  473898: 89 45 b4                     	mov	dword ptr [ebp - 0x4c], eax
  47389b: 89 45 ac                     	mov	dword ptr [ebp - 0x54], eax
  47389e: 89 85 68 ff ff ff            	mov	dword ptr [ebp - 0x98], eax
  4738a4: 8b 15 d0 53 c2 00            	mov	edx, dword ptr [0xc253d0]
  4738aa: 8b 35 30 ad 02 01            	mov	esi, dword ptr [0x102ad30]
  4738b0: 8b 3a                        	mov	edi, dword ptr [edx]
  4738b2: 8d 85 54 ff ff ff            	lea	eax, [ebp - 0xac]
  4738b8: 89 85 50 ff ff ff            	mov	dword ptr [ebp - 0xb0], eax
  4738be: c6 85 58 ff ff ff 00         	mov	byte ptr [ebp - 0xa8], 0x0
  4738c5: c7 85 70 ff ff ff 1c ad 02 01	mov	dword ptr [ebp - 0x90], 0x102ad1c
  4738cf: 8d 85 54 ff ff ff            	lea	eax, [ebp - 0xac]
  4738d5: 3b fe                        	cmp	edi, esi
  4738d7: 0f 42 f7                     	cmovb	esi, edi
  4738da: ba 1c ad 02 01               	mov	edx, 0x102ad1c
  4738df: 89 b5 44 ff ff ff            	mov	dword ptr [ebp - 0xbc], esi
  4738e5: 3b c2                        	cmp	eax, edx
  4738e7: 0f 84 48 0b 00 00            	je	0x474435 <.text+0x73435>
  4738ed: 89 b5 78 ff ff ff            	mov	dword ptr [ebp - 0x88], esi
  4738f3: 83 fe fe                     	cmp	esi, -0x2
  4738f6: 76 0c                        	jbe	0x473904 <.text+0x72904>
  4738f8: ff 15 d4 53 c2 00            	call	dword ptr [0xc253d4]
  4738fe: 8b b5 78 ff ff ff            	mov	esi, dword ptr [ebp - 0x88]
  473904: 8b bd 6c ff ff ff            	mov	edi, dword ptr [ebp - 0x94]
  47390a: 3b fe                        	cmp	edi, esi
  47390c: 0f 82 84 09 00 00            	jb	0x474296 <.text+0x73296>
  473912: 85 f6                        	test	esi, esi
  473914: 0f 84 59 09 00 00            	je	0x474273 <.text+0x73273>
  47391a: 85 f6                        	test	esi, esi
  47391c: 0f 87 f4 08 00 00            	ja	0x474216 <.text+0x73216>
  473922: c7 45 ac 01 00 00 00         	mov	dword ptr [ebp - 0x54], 0x1
  473929: 8d 85 54 ff ff ff            	lea	eax, [ebp - 0xac]
  47392f: 83 c4 f8                     	add	esp, -0x8
  473932: 89 04 24                     	mov	dword ptr [esp], eax
  473935: c7 44 24 04 4c cc c2 00      	mov	dword ptr [esp + 0x4], 0xc2cc4c
  47393d: ff 15 c8 53 c2 00            	call	dword ptr [0xc253c8]
  473943: 83 c4 08                     	add	esp, 0x8
  473946: 0f b6 c0                     	movzx	eax, al
  473949: 85 c0                        	test	eax, eax
  47394b: 0f 84 a0 05 00 00            	je	0x473ef1 <.text+0x72ef1>
  473951: be 01 00 00 00               	mov	esi, 0x1
  473956: 83 7d b4 00                  	cmp	dword ptr [ebp - 0x4c], 0x0
  47395a: 0f 85 56 05 00 00            	jne	0x473eb6 <.text+0x72eb6>
  473960: c7 45 fc ff ff ff ff         	mov	dword ptr [ebp - 0x4], 0xffffffff
  473967: 83 bd 6c ff ff ff 10         	cmp	dword ptr [ebp - 0x94], 0x10
  47396e: c7 45 ac 00 00 00 00         	mov	dword ptr [ebp - 0x54], 0x0
  473975: 0f 83 2a 05 00 00            	jae	0x473ea5 <.text+0x72ea5>
  47397b: c7 85 6c ff ff ff 0f 00 00 00	mov	dword ptr [ebp - 0x94], 0xf
  473985: 33 c0                        	xor	eax, eax
  473987: 85 f6                        	test	esi, esi
  473989: 89 85 68 ff ff ff            	mov	dword ptr [ebp - 0x98], eax
  47398f: 88 85 58 ff ff ff            	mov	byte ptr [ebp - 0xa8], al
  473995: 74 0a                        	je	0x4739a1 <.text+0x729a1>
  473997: 8d 43 08                     	lea	eax, [ebx + 0x8]
  47399a: 50                           	push	eax
  47399b: e8 e0 da 07 00               	call	0x4f1480 <.text+0xf0480>
  4739a0: 59                           	pop	ecx
  4739a1: 0f b6 05 44 93 fe 00         	movzx	eax, byte ptr [0xfe9344]
  4739a8: 6a 00                        	push	0x0
  4739aa: 50                           	push	eax
  4739ab: b9 40 79 10 01               	mov	ecx, 0x1107940
  4739b0: 8d 53 08                     	lea	edx, [ebx + 0x8]
  4739b3: 52                           	push	edx
  4739b4: e8 a7 09 11 00               	call	0x584360 <.text+0x183360>
  4739b9: 8d 43 08                     	lea	eax, [ebx + 0x8]
  4739bc: 50                           	push	eax
  4739bd: b9 80 af 02 01               	mov	ecx, 0x102af80
  4739c2: e8 49 cc 04 00               	call	0x4c0610 <.text+0xbf610>
  4739c7: 8d 43 08                     	lea	eax, [ebx + 0x8]
  4739ca: 50                           	push	eax
  4739cb: b9 80 af 02 01               	mov	ecx, 0x102af80
  4739d0: e8 0b d1 04 00               	call	0x4c0ae0 <.text+0xbfae0>
  4739d5: 0f be 05 68 93 fe 00         	movsx	eax, byte ptr [0xfe9368]
  4739dc: 83 f8 04                     	cmp	eax, 0x4
  4739df: 74 13                        	je	0x4739f4 <.text+0x729f4>
  4739e1: 83 f8 05                     	cmp	eax, 0x5
  4739e4: 74 0e                        	je	0x4739f4 <.text+0x729f4>
  4739e6: 8d 43 08                     	lea	eax, [ebx + 0x8]
  4739e9: 50                           	push	eax
  4739ea: b9 40 79 10 01               	mov	ecx, 0x1107940
  4739ef: e8 0c 43 11 00               	call	0x587d00 <.text+0x186d00>
  4739f4: 8d 43 08                     	lea	eax, [ebx + 0x8]
  4739f7: 50                           	push	eax
  4739f8: b9 80 1a 08 01               	mov	ecx, 0x1081a80
  4739fd: e8 ee 38 09 00               	call	0x5072f0 <.text+0x1062f0>
  473a02: 8d 43 08                     	lea	eax, [ebx + 0x8]
  473a05: 50                           	push	eax
  473a06: b9 68 af 02 01               	mov	ecx, 0x102af68
  473a0b: e8 70 79 03 00               	call	0x4ab380 <.text+0xaa380>
  473a10: 8d 43 08                     	lea	eax, [ebx + 0x8]
  473a13: 50                           	push	eax
  473a14: b9 c0 76 10 01               	mov	ecx, 0x11076c0
  473a19: e8 42 b9 0f 00               	call	0x56f360 <.text+0x16e360>
  473a1e: 8d 43 08                     	lea	eax, [ebx + 0x8]
  473a21: 50                           	push	eax
  473a22: b9 c0 76 10 01               	mov	ecx, 0x11076c0
  473a27: e8 44 a7 0f 00               	call	0x56e170 <.text+0x16d170>
  473a2c: 8d 43 08                     	lea	eax, [ebx + 0x8]
  473a2f: 50                           	push	eax
  473a30: e8 6b 4e 0a 00               	call	0x5188a0 <.text+0x1178a0>
  473a35: 8d 43 08                     	lea	eax, [ebx + 0x8]
  473a38: 50                           	push	eax
  473a39: e8 b2 27 0f 00               	call	0x5661f0 <.text+0x1651f0>
  473a3e: 83 c4 08                     	add	esp, 0x8
  473a41: e8 aa 14 14 00               	call	0x5b4ef0 <.text+0x1b3ef0>
  473a46: 83 c0 1c                     	add	eax, 0x1c
  473a49: 8b c8                        	mov	ecx, eax
  473a4b: e8 c0 f8 2d 00               	call	0x753310 <.text+0x352310>
  473a50: 0f b6 c0                     	movzx	eax, al
  473a53: 85 c0                        	test	eax, eax
  473a55: 0f 84 e5 03 00 00            	je	0x473e40 <.text+0x72e40>
  473a5b: e8 90 14 14 00               	call	0x5b4ef0 <.text+0x1b3ef0>
  473a60: 8b c8                        	mov	ecx, eax
  473a62: e8 19 19 14 00               	call	0x5b5380 <.text+0x1b4380>
  473a67: d9 5d 88                     	fstp	dword ptr [ebp - 0x78]
  473a6a: f3 0f 10 4d 88               	movss	xmm1, dword ptr [ebp - 0x78]
  473a6f: f3 0f 5a 83 34 02 00 00      	cvtss2sd	xmm0, dword ptr [ebx + 0x234]
  473a77: f2 0f 5e 05 68 ba c2 00      	divsd	xmm0, qword ptr [0xc2ba68]
  473a7f: f3 0f 5a c9                  	cvtss2sd	xmm1, xmm1
  473a83: f2 0f 10 15 60 ba c2 00      	movsd	xmm2, qword ptr [0xc2ba60]
  473a8b: f2 0f 5e d0                  	divsd	xmm2, xmm0
  473a8f: f2 0f 59 d1                  	mulsd	xmm2, xmm1
  473a93: f2 0f 5a da                  	cvtsd2ss	xmm3, xmm2
  473a97: 68 71 0b 00 00               	push	0xb71
  473a9c: f3 0f 11 5d 90               	movss	dword ptr [ebp - 0x70], xmm3
  473aa1: ff 15 1c 59 c2 00            	call	dword ptr [0xc2591c]
  473aa7: 0f be 05 60 93 fe 00         	movsx	eax, byte ptr [0xfe9360]
  473aae: 85 c0                        	test	eax, eax
  473ab0: 0f 85 84 00 00 00            	jne	0x473b3a <.text+0x72b3a>
  473ab6: e8 35 14 14 00               	call	0x5b4ef0 <.text+0x1b3ef0>
  473abb: 83 c0 1c                     	add	eax, 0x1c
  473abe: 8b c8                        	mov	ecx, eax
  473ac0: e8 9b f8 2d 00               	call	0x753360 <.text+0x352360>
  473ac5: 33 c0                        	xor	eax, eax
  473ac7: 33 f6                        	xor	esi, esi
  473ac9: 83 c4 f0                     	add	esp, -0x10
  473acc: d9 5c 24 0c                  	fstp	dword ptr [esp + 0xc]
  473ad0: c7 04 24 00 00 80 3f         	mov	dword ptr [esp], 0x3f800000
  473ad7: 89 74 24 08                  	mov	dword ptr [esp + 0x8], esi
  473adb: c7 44 24 04 00 00 80 3f      	mov	dword ptr [esp + 0x4], 0x3f800000
  473ae3: ff 15 70 59 c2 00            	call	dword ptr [0xc25970]
  473ae9: 6a 02                        	push	0x2
  473aeb: ff 15 d4 58 c2 00            	call	dword ptr [0xc258d4]
  473af1: 33 c0                        	xor	eax, eax
  473af3: 33 ff                        	xor	edi, edi
  473af5: f2 0f 2a cf                  	cvtsi2sd	xmm1, edi
  473af9: f2 0f 59 0d 88 ba c2 00      	mulsd	xmm1, qword ptr [0xc2ba88]
  473b01: f2 0f 5e 0d 90 ba c2 00      	divsd	xmm1, qword ptr [0xc2ba90]
  473b09: f2 0f 5a c1                  	cvtsd2ss	xmm0, xmm1
  473b0d: e8 34 b3 61 00               	call	0xa8ee46 <.text+0x68de46>
  473b12: 83 c4 f4                     	add	esp, -0xc
  473b15: f3 0f 11 0c 24               	movss	dword ptr [esp], xmm1
  473b1a: f3 0f 11 44 24 04            	movss	dword ptr [esp + 0x4], xmm0
  473b20: 89 74 24 08                  	mov	dword ptr [esp + 0x8], esi
  473b24: ff 15 54 59 c2 00            	call	dword ptr [0xc25954]
  473b2a: 83 c7 05                     	add	edi, 0x5
  473b2d: 81 ff 68 01 00 00            	cmp	edi, 0x168
  473b33: 7c c0                        	jl	0x473af5 <.text+0x72af5>
  473b35: e9 63 03 00 00               	jmp	0x473e9d <.text+0x72e9d>
  473b3a: f3 0f 5a 05 e8 90 fe 00      	cvtss2sd	xmm0, dword ptr [0xfe90e8]
  473b42: f2 0f 59 05 70 ba c2 00      	mulsd	xmm0, qword ptr [0xc2ba70]
  473b4a: f2 0f 5e 43 70               	divsd	xmm0, qword ptr [ebx + 0x70]
  473b4f: f2 0f 5a d0                  	cvtsd2ss	xmm2, xmm0
  473b53: 8b 83 40 01 00 00            	mov	eax, dword ptr [ebx + 0x140]
  473b59: 8b 93 44 01 00 00            	mov	edx, dword ptr [ebx + 0x144]
  473b5f: 8b 8b 48 01 00 00            	mov	ecx, dword ptr [ebx + 0x148]
  473b65: 8b b3 4c 01 00 00            	mov	esi, dword ptr [ebx + 0x14c]
  473b6b: 8b bb 50 01 00 00            	mov	edi, dword ptr [ebx + 0x150]
  473b71: f2 0f 10 0d 78 ba c2 00      	movsd	xmm1, qword ptr [0xc2ba78]
  473b79: f3 0f 5a da                  	cvtss2sd	xmm3, xmm2
  473b7d: 89 45 a8                     	mov	dword ptr [ebp - 0x58], eax
  473b80: 8b 83 54 01 00 00            	mov	eax, dword ptr [ebx + 0x154]
  473b86: 89 55 ac                     	mov	dword ptr [ebp - 0x54], edx
  473b89: 66 0f 2f cb                  	comisd	xmm1, xmm3
  473b8d: 89 4d b0                     	mov	dword ptr [ebp - 0x50], ecx
  473b90: 89 75 b4                     	mov	dword ptr [ebp - 0x4c], esi
  473b93: 89 7d b8                     	mov	dword ptr [ebp - 0x48], edi
  473b96: 89 45 bc                     	mov	dword ptr [ebp - 0x44], eax
  473b99: 0f 87 a1 02 00 00            	ja	0x473e40 <.text+0x72e40>
  473b9f: f3 0f 10 05 2c c0 c2 00      	movss	xmm0, dword ptr [0xc2c02c]
  473ba7: f3 0f 10 0d 20 c0 c2 00      	movss	xmm1, dword ptr [0xc2c020]
  473baf: f3 0f 11 45 84               	movss	dword ptr [ebp - 0x7c], xmm0
  473bb4: bf 00 00 80 3f               	mov	edi, 0x3f800000
  473bb9: 0f 2f ca                     	comiss	xmm1, xmm2
  473bbc: 76 19                        	jbe	0x473bd7 <.text+0x72bd7>
  473bbe: f2 0f 5c 1d 78 ba c2 00      	subsd	xmm3, qword ptr [0xc2ba78]
  473bc6: f2 0f 5e 1d 80 ba c2 00      	divsd	xmm3, qword ptr [0xc2ba80]
  473bce: f2 0f 5a c3                  	cvtsd2ss	xmm0, xmm3
