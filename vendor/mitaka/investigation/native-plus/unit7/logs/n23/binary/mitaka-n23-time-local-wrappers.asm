
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  667560: 55                           	push	ebp
  667561: 8b ec                        	mov	ebp, esp
  667563: 83 e4 c0                     	and	esp, -0x40
  667566: 57                           	push	edi
  667567: 56                           	push	esi
  667568: 53                           	push	ebx
  667569: 83 ec 34                     	sub	esp, 0x34
  66756c: 8b 7d 08                     	mov	edi, dword ptr [ebp + 0x8]
  66756f: 6a 00                        	push	0x0
  667571: 6a 01                        	push	0x1
  667573: 57                           	push	edi
  667574: e8 f7 7e 22 00               	call	0x88f470 <.text+0x48e470>
  667579: 83 c4 0c                     	add	esp, 0xc
  66757c: 89 44 24 18                  	mov	dword ptr [esp + 0x18], eax
  667580: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  667588: 89 3c 24                     	mov	dword ptr [esp], edi
  66758b: 66 0f ef c0                  	pxor	xmm0, xmm0
  66758f: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  667595: e8 56 7e 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  66759a: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  66759e: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6675a4: c7 44 24 04 03 00 00 00      	mov	dword ptr [esp + 0x4], 0x3
  6675ac: 89 3c 24                     	mov	dword ptr [esp], edi
  6675af: f2 0f 2c f0                  	cvttsd2si	esi, xmm0
  6675b3: 66 0f ef c0                  	pxor	xmm0, xmm0
  6675b7: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6675bd: e8 2e 7e 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6675c2: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6675c6: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6675cc: c7 44 24 04 04 00 00 00      	mov	dword ptr [esp + 0x4], 0x4
  6675d4: 89 3c 24                     	mov	dword ptr [esp], edi
  6675d7: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  6675db: 66 0f ef c0                  	pxor	xmm0, xmm0
  6675df: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6675e5: 89 44 24 1c                  	mov	dword ptr [esp + 0x1c], eax
  6675e9: e8 02 7e 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6675ee: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6675f2: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6675f8: c7 44 24 04 05 00 00 00      	mov	dword ptr [esp + 0x4], 0x5
  667600: 89 3c 24                     	mov	dword ptr [esp], edi
  667603: f2 0f 2c d8                  	cvttsd2si	ebx, xmm0
  667607: 66 0f ef c0                  	pxor	xmm0, xmm0
  66760b: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  667611: e8 da 7d 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  667616: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  66761a: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  667620: c7 44 24 04 06 00 00 00      	mov	dword ptr [esp + 0x4], 0x6
  667628: 89 3c 24                     	mov	dword ptr [esp], edi
  66762b: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  66762f: 66 0f ef c0                  	pxor	xmm0, xmm0
  667633: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  667639: 89 44 24 24                  	mov	dword ptr [esp + 0x24], eax
  66763d: e8 ae 7d 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  667642: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  667646: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  66764c: c7 44 24 04 07 00 00 00      	mov	dword ptr [esp + 0x4], 0x7
  667654: 89 3c 24                     	mov	dword ptr [esp], edi
  667657: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  66765b: 66 0f ef c0                  	pxor	xmm0, xmm0
  66765f: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  667665: 89 44 24 20                  	mov	dword ptr [esp + 0x20], eax
  667669: e8 82 7d 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  66766e: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  667672: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  667678: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  66767c: 50                           	push	eax
  66767d: ff 74 24 24                  	push	dword ptr [esp + 0x24]
  667681: ff 74 24 2c                  	push	dword ptr [esp + 0x2c]
  667685: 53                           	push	ebx
  667686: ff 74 24 2c                  	push	dword ptr [esp + 0x2c]
  66768a: 56                           	push	esi
  66768b: 8b 4c 24 30                  	mov	ecx, dword ptr [esp + 0x30]
  66768f: e8 5c 3d f8 ff               	call	0x5eb3f0 <.text+0x1ea3f0>
  667694: 33 c0                        	xor	eax, eax
  667696: 83 c4 34                     	add	esp, 0x34
  667699: 5b                           	pop	ebx
  66769a: 5e                           	pop	esi
  66769b: 5f                           	pop	edi
  66769c: 8b e5                        	mov	esp, ebp
  66769e: 5d                           	pop	ebp
  66769f: c3                           	ret
  6676a0: 55                           	push	ebp
  6676a1: 8b ec                        	mov	ebp, esp
  6676a3: 83 e4 c0                     	and	esp, -0x40
  6676a6: 57                           	push	edi
  6676a7: 56                           	push	esi
  6676a8: 83 ec 38                     	sub	esp, 0x38
  6676ab: 8b 7d 08                     	mov	edi, dword ptr [ebp + 0x8]
  6676ae: 6a 00                        	push	0x0
  6676b0: 6a 01                        	push	0x1
  6676b2: 57                           	push	edi
  6676b3: e8 b8 7d 22 00               	call	0x88f470 <.text+0x48e470>
  6676b8: 83 c4 0c                     	add	esp, 0xc
  6676bb: 8b f0                        	mov	esi, eax
  6676bd: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  6676c5: 89 3c 24                     	mov	dword ptr [esp], edi
  6676c8: 66 0f ef c0                  	pxor	xmm0, xmm0
  6676cc: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6676d2: e8 19 7d 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6676d7: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6676db: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6676e1: c7 44 24 04 03 00 00 00      	mov	dword ptr [esp + 0x4], 0x3
  6676e9: 89 3c 24                     	mov	dword ptr [esp], edi
  6676ec: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  6676f0: 66 0f ef c0                  	pxor	xmm0, xmm0
  6676f4: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6676fa: 89 44 24 18                  	mov	dword ptr [esp + 0x18], eax
  6676fe: e8 ed 7c 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  667703: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  667707: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  66770d: c7 44 24 04 04 00 00 00      	mov	dword ptr [esp + 0x4], 0x4
  667715: 89 3c 24                     	mov	dword ptr [esp], edi
  667718: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  66771c: 66 0f ef c0                  	pxor	xmm0, xmm0
  667720: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  667726: 89 44 24 1c                  	mov	dword ptr [esp + 0x1c], eax
  66772a: e8 c1 7c 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  66772f: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  667733: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  667739: c7 44 24 04 05 00 00 00      	mov	dword ptr [esp + 0x4], 0x5
  667741: 89 3c 24                     	mov	dword ptr [esp], edi
  667744: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  667748: 66 0f ef c0                  	pxor	xmm0, xmm0
  66774c: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  667752: 89 44 24 20                  	mov	dword ptr [esp + 0x20], eax
  667756: e8 95 7c 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  66775b: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  66775f: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  667765: c7 44 24 04 06 00 00 00      	mov	dword ptr [esp + 0x4], 0x6
  66776d: 89 3c 24                     	mov	dword ptr [esp], edi
  667770: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  667774: 66 0f ef c0                  	pxor	xmm0, xmm0
  667778: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  66777e: 89 44 24 24                  	mov	dword ptr [esp + 0x24], eax
  667782: e8 69 7c 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  667787: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  66778b: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  667791: c7 44 24 04 07 00 00 00      	mov	dword ptr [esp + 0x4], 0x7
  667799: 89 3c 24                     	mov	dword ptr [esp], edi
  66779c: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  6677a0: 66 0f ef c0                  	pxor	xmm0, xmm0
  6677a4: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6677aa: 89 44 24 28                  	mov	dword ptr [esp + 0x28], eax
  6677ae: e8 3d 7c 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6677b3: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6677b7: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6677bd: 8d 4c 24 24                  	lea	ecx, [esp + 0x24]
  6677c1: 8d 54 24 10                  	lea	edx, [esp + 0x10]
  6677c5: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  6677c9: 89 44 24 10                  	mov	dword ptr [esp + 0x10], eax
  6677cd: 8d 44 24 28                  	lea	eax, [esp + 0x28]
  6677d1: 52                           	push	edx
  6677d2: 50                           	push	eax
  6677d3: 51                           	push	ecx
  6677d4: 8b ce                        	mov	ecx, esi
  6677d6: 8d 54 24 2c                  	lea	edx, [esp + 0x2c]
  6677da: 52                           	push	edx
  6677db: 8d 44 24 2c                  	lea	eax, [esp + 0x2c]
  6677df: 50                           	push	eax
  6677e0: 8d 54 24 2c                  	lea	edx, [esp + 0x2c]
  6677e4: 52                           	push	edx
  6677e5: e8 a6 3c f8 ff               	call	0x5eb490 <.text+0x1ea490>
  6677ea: f2 0f 2a 44 24 18            	cvtsi2sd	xmm0, dword ptr [esp + 0x18]
  6677f0: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  6677f6: 89 3c 24                     	mov	dword ptr [esp], edi
  6677f9: e8 22 80 22 00               	call	0x88f820 <.text+0x48e820>
  6677fe: f2 0f 2a 44 24 1c            	cvtsi2sd	xmm0, dword ptr [esp + 0x1c]
  667804: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  66780a: 89 3c 24                     	mov	dword ptr [esp], edi
  66780d: e8 0e 80 22 00               	call	0x88f820 <.text+0x48e820>
  667812: f2 0f 2a 44 24 20            	cvtsi2sd	xmm0, dword ptr [esp + 0x20]
  667818: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  66781e: 89 3c 24                     	mov	dword ptr [esp], edi
  667821: e8 fa 7f 22 00               	call	0x88f820 <.text+0x48e820>
  667826: f2 0f 2a 44 24 24            	cvtsi2sd	xmm0, dword ptr [esp + 0x24]
  66782c: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  667832: 89 3c 24                     	mov	dword ptr [esp], edi
  667835: e8 e6 7f 22 00               	call	0x88f820 <.text+0x48e820>
  66783a: f2 0f 2a 44 24 28            	cvtsi2sd	xmm0, dword ptr [esp + 0x28]
  667840: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  667846: 89 3c 24                     	mov	dword ptr [esp], edi
  667849: e8 d2 7f 22 00               	call	0x88f820 <.text+0x48e820>
  66784e: f2 0f 2a 44 24 10            	cvtsi2sd	xmm0, dword ptr [esp + 0x10]
  667854: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  66785a: 89 3c 24                     	mov	dword ptr [esp], edi
  66785d: e8 be 7f 22 00               	call	0x88f820 <.text+0x48e820>
  667862: b8 06 00 00 00               	mov	eax, 0x6
  667867: 83 c4 38                     	add	esp, 0x38
  66786a: 5e                           	pop	esi
  66786b: 5f                           	pop	edi
  66786c: 8b e5                        	mov	esp, ebp
  66786e: 5d                           	pop	ebp
  66786f: c3                           	ret
  667870: 55                           	push	ebp
  667871: 8b ec                        	mov	ebp, esp
  667873: 83 e4 c0                     	and	esp, -0x40
  667876: 57                           	push	edi
  667877: 56                           	push	esi
  667878: 53                           	push	ebx
  667879: 83 ec 34                     	sub	esp, 0x34
  66787c: 8b 7d 08                     	mov	edi, dword ptr [ebp + 0x8]
  66787f: 6a 00                        	push	0x0
  667881: 6a 01                        	push	0x1
  667883: 57                           	push	edi
  667884: e8 e7 7b 22 00               	call	0x88f470 <.text+0x48e470>
  667889: 83 c4 0c                     	add	esp, 0xc
  66788c: 89 44 24 18                  	mov	dword ptr [esp + 0x18], eax
  667890: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  667898: 89 3c 24                     	mov	dword ptr [esp], edi
  66789b: 66 0f ef c0                  	pxor	xmm0, xmm0
  66789f: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6678a5: e8 46 7b 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6678aa: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6678ae: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6678b4: c7 44 24 04 03 00 00 00      	mov	dword ptr [esp + 0x4], 0x3
  6678bc: 89 3c 24                     	mov	dword ptr [esp], edi
  6678bf: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  6678c3: 66 0f ef c0                  	pxor	xmm0, xmm0
  6678c7: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6678cd: 89 44 24 28                  	mov	dword ptr [esp + 0x28], eax
  6678d1: e8 1a 7b 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6678d6: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6678da: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6678e0: c7 44 24 04 04 00 00 00      	mov	dword ptr [esp + 0x4], 0x4
  6678e8: 89 3c 24                     	mov	dword ptr [esp], edi
  6678eb: f2 0f 2c d8                  	cvttsd2si	ebx, xmm0
  6678ef: 66 0f ef c0                  	pxor	xmm0, xmm0
  6678f3: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6678f9: e8 f2 7a 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6678fe: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  667902: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  667908: c7 44 24 04 05 00 00 00      	mov	dword ptr [esp + 0x4], 0x5
  667910: 89 3c 24                     	mov	dword ptr [esp], edi
  667913: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  667917: 66 0f ef c0                  	pxor	xmm0, xmm0
  66791b: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  667921: 89 44 24 24                  	mov	dword ptr [esp + 0x24], eax
  667925: e8 c6 7a 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  66792a: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  66792e: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  667934: c7 44 24 04 06 00 00 00      	mov	dword ptr [esp + 0x4], 0x6
  66793c: 89 3c 24                     	mov	dword ptr [esp], edi
  66793f: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  667943: 66 0f ef c0                  	pxor	xmm0, xmm0
  667947: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  66794d: 89 44 24 20                  	mov	dword ptr [esp + 0x20], eax
  667951: e8 9a 7a 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  667956: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  66795a: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  667960: c7 44 24 04 07 00 00 00      	mov	dword ptr [esp + 0x4], 0x7
  667968: 89 3c 24                     	mov	dword ptr [esp], edi
  66796b: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  66796f: 66 0f ef c0                  	pxor	xmm0, xmm0
  667973: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  667979: 89 44 24 1c                  	mov	dword ptr [esp + 0x1c], eax
  66797d: e8 6e 7a 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  667982: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  667986: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  66798c: c7 44 24 04 08 00 00 00      	mov	dword ptr [esp + 0x4], 0x8
  667994: 89 3c 24                     	mov	dword ptr [esp], edi
  667997: f2 0f 2c f0                  	cvttsd2si	esi, xmm0
  66799b: 66 0f ef c0                  	pxor	xmm0, xmm0
  66799f: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6679a5: e8 46 7a 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6679aa: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6679ae: 6a 01                        	push	0x1
  6679b0: 6a 09                        	push	0x9
  6679b2: 57                           	push	edi
  6679b3: e8 48 7b 22 00               	call	0x88f500 <.text+0x48e500>
  6679b8: 83 c4 0c                     	add	esp, 0xc
  6679bb: 83 c4 dc                     	add	esp, -0x24
  6679be: dd 44 24 34                  	fld	qword ptr [esp + 0x34]
  6679c2: 8b 54 24 4c                  	mov	edx, dword ptr [esp + 0x4c]
  6679c6: 8b 7c 24 44                  	mov	edi, dword ptr [esp + 0x44]
  6679ca: 8b 4c 24 40                  	mov	ecx, dword ptr [esp + 0x40]
  6679ce: dd 5c 24 18                  	fstp	qword ptr [esp + 0x18]
  6679d2: 89 14 24                     	mov	dword ptr [esp], edx
  6679d5: 85 c0                        	test	eax, eax
  6679d7: 89 5c 24 04                  	mov	dword ptr [esp + 0x4], ebx
  6679db: 8b 5c 24 48                  	mov	ebx, dword ptr [esp + 0x48]
  6679df: 89 5c 24 08                  	mov	dword ptr [esp + 0x8], ebx
  6679e3: 89 7c 24 0c                  	mov	dword ptr [esp + 0xc], edi
  6679e7: 89 4c 24 10                  	mov	dword ptr [esp + 0x10], ecx
  6679eb: 8b 4c 24 3c                  	mov	ecx, dword ptr [esp + 0x3c]
  6679ef: 89 74 24 14                  	mov	dword ptr [esp + 0x14], esi
  6679f3: be 01 00 00 00               	mov	esi, 0x1
  6679f8: 0f 45 c6                     	cmovne	eax, esi
  6679fb: 88 44 24 20                  	mov	byte ptr [esp + 0x20], al
  6679ff: e8 1c 3b f8 ff               	call	0x5eb520 <.text+0x1ea520>
  667a04: 33 c0                        	xor	eax, eax
  667a06: 83 c4 34                     	add	esp, 0x34
  667a09: 5b                           	pop	ebx
  667a0a: 5e                           	pop	esi
  667a0b: 5f                           	pop	edi
  667a0c: 8b e5                        	mov	esp, ebp
  667a0e: 5d                           	pop	ebp
  667a0f: c3                           	ret
