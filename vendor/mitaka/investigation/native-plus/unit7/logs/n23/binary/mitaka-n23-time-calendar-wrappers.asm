
/Users/kota/mitaka/mitaka_plus/Contents/SharedSupport/prefix/drive_c/Program Files/mitaka/mitakaPlus.exe:	file format coff-i386

Disassembly of section .text:

00401000 <.text>:
  666030: 55                           	push	ebp
  666031: 8b ec                        	mov	ebp, esp
  666033: 83 e4 c0                     	and	esp, -0x40
  666036: 57                           	push	edi
  666037: 56                           	push	esi
  666038: 83 ec 38                     	sub	esp, 0x38
  66603b: 8b 7d 08                     	mov	edi, dword ptr [ebp + 0x8]
  66603e: 6a 00                        	push	0x0
  666040: 6a 01                        	push	0x1
  666042: 57                           	push	edi
  666043: e8 28 94 22 00               	call	0x88f470 <.text+0x48e470>
  666048: 83 c4 0c                     	add	esp, 0xc
  66604b: 8b f0                        	mov	esi, eax
  66604d: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  666055: 89 3c 24                     	mov	dword ptr [esp], edi
  666058: 66 0f ef c0                  	pxor	xmm0, xmm0
  66605c: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  666062: e8 89 93 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  666067: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  66606b: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  666071: c7 44 24 04 03 00 00 00      	mov	dword ptr [esp + 0x4], 0x3
  666079: 89 3c 24                     	mov	dword ptr [esp], edi
  66607c: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  666080: 66 0f ef c0                  	pxor	xmm0, xmm0
  666084: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  66608a: 89 44 24 18                  	mov	dword ptr [esp + 0x18], eax
  66608e: e8 5d 93 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  666093: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  666097: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  66609d: c7 44 24 04 04 00 00 00      	mov	dword ptr [esp + 0x4], 0x4
  6660a5: 89 3c 24                     	mov	dword ptr [esp], edi
  6660a8: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  6660ac: 66 0f ef c0                  	pxor	xmm0, xmm0
  6660b0: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6660b6: 89 44 24 1c                  	mov	dword ptr [esp + 0x1c], eax
  6660ba: e8 31 93 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6660bf: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6660c3: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6660c9: c7 44 24 04 05 00 00 00      	mov	dword ptr [esp + 0x4], 0x5
  6660d1: 89 3c 24                     	mov	dword ptr [esp], edi
  6660d4: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  6660d8: 66 0f ef c0                  	pxor	xmm0, xmm0
  6660dc: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6660e2: 89 44 24 20                  	mov	dword ptr [esp + 0x20], eax
  6660e6: e8 05 93 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6660eb: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6660ef: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6660f5: c7 44 24 04 06 00 00 00      	mov	dword ptr [esp + 0x4], 0x6
  6660fd: 89 3c 24                     	mov	dword ptr [esp], edi
  666100: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  666104: 66 0f ef c0                  	pxor	xmm0, xmm0
  666108: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  66610e: 89 44 24 24                  	mov	dword ptr [esp + 0x24], eax
  666112: e8 d9 92 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  666117: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  66611b: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  666121: c7 44 24 04 07 00 00 00      	mov	dword ptr [esp + 0x4], 0x7
  666129: 89 3c 24                     	mov	dword ptr [esp], edi
  66612c: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  666130: 66 0f ef c0                  	pxor	xmm0, xmm0
  666134: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  66613a: 89 44 24 28                  	mov	dword ptr [esp + 0x28], eax
  66613e: e8 ad 92 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  666143: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  666147: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  66614d: 8d 4c 24 24                  	lea	ecx, [esp + 0x24]
  666151: 8d 54 24 10                  	lea	edx, [esp + 0x10]
  666155: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  666159: 89 44 24 10                  	mov	dword ptr [esp + 0x10], eax
  66615d: 8d 44 24 28                  	lea	eax, [esp + 0x28]
  666161: 52                           	push	edx
  666162: 50                           	push	eax
  666163: 51                           	push	ecx
  666164: 8b ce                        	mov	ecx, esi
  666166: 8d 54 24 2c                  	lea	edx, [esp + 0x2c]
  66616a: 52                           	push	edx
  66616b: 8d 44 24 2c                  	lea	eax, [esp + 0x2c]
  66616f: 50                           	push	eax
  666170: 8d 54 24 2c                  	lea	edx, [esp + 0x2c]
  666174: 52                           	push	edx
  666175: e8 b6 47 f8 ff               	call	0x5ea930 <.text+0x1e9930>
  66617a: f2 0f 2a 44 24 18            	cvtsi2sd	xmm0, dword ptr [esp + 0x18]
  666180: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  666186: 89 3c 24                     	mov	dword ptr [esp], edi
  666189: e8 92 96 22 00               	call	0x88f820 <.text+0x48e820>
  66618e: f2 0f 2a 44 24 1c            	cvtsi2sd	xmm0, dword ptr [esp + 0x1c]
  666194: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  66619a: 89 3c 24                     	mov	dword ptr [esp], edi
  66619d: e8 7e 96 22 00               	call	0x88f820 <.text+0x48e820>
  6661a2: f2 0f 2a 44 24 20            	cvtsi2sd	xmm0, dword ptr [esp + 0x20]
  6661a8: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  6661ae: 89 3c 24                     	mov	dword ptr [esp], edi
  6661b1: e8 6a 96 22 00               	call	0x88f820 <.text+0x48e820>
  6661b6: f2 0f 2a 44 24 24            	cvtsi2sd	xmm0, dword ptr [esp + 0x24]
  6661bc: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  6661c2: 89 3c 24                     	mov	dword ptr [esp], edi
  6661c5: e8 56 96 22 00               	call	0x88f820 <.text+0x48e820>
  6661ca: f2 0f 2a 44 24 28            	cvtsi2sd	xmm0, dword ptr [esp + 0x28]
  6661d0: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  6661d6: 89 3c 24                     	mov	dword ptr [esp], edi
  6661d9: e8 42 96 22 00               	call	0x88f820 <.text+0x48e820>
  6661de: f2 0f 2a 44 24 10            	cvtsi2sd	xmm0, dword ptr [esp + 0x10]
  6661e4: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  6661ea: 89 3c 24                     	mov	dword ptr [esp], edi
  6661ed: e8 2e 96 22 00               	call	0x88f820 <.text+0x48e820>
  6661f2: b8 06 00 00 00               	mov	eax, 0x6
  6661f7: 83 c4 38                     	add	esp, 0x38
  6661fa: 5e                           	pop	esi
  6661fb: 5f                           	pop	edi
  6661fc: 8b e5                        	mov	esp, ebp
  6661fe: 5d                           	pop	ebp
  6661ff: c3                           	ret
  666200: 55                           	push	ebp
  666201: 8b ec                        	mov	ebp, esp
  666203: 83 e4 c0                     	and	esp, -0x40
  666206: 57                           	push	edi
  666207: 56                           	push	esi
  666208: 83 ec 38                     	sub	esp, 0x38
  66620b: 8b 7d 08                     	mov	edi, dword ptr [ebp + 0x8]
  66620e: 6a 00                        	push	0x0
  666210: 6a 01                        	push	0x1
  666212: 57                           	push	edi
  666213: e8 58 92 22 00               	call	0x88f470 <.text+0x48e470>
  666218: 83 c4 0c                     	add	esp, 0xc
  66621b: 8b f0                        	mov	esi, eax
  66621d: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  666225: 89 3c 24                     	mov	dword ptr [esp], edi
  666228: 66 0f ef c0                  	pxor	xmm0, xmm0
  66622c: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  666232: e8 b9 91 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  666237: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  66623b: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  666241: c7 44 24 04 03 00 00 00      	mov	dword ptr [esp + 0x4], 0x3
  666249: 89 3c 24                     	mov	dword ptr [esp], edi
  66624c: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  666250: 66 0f ef c0                  	pxor	xmm0, xmm0
  666254: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  66625a: 89 44 24 18                  	mov	dword ptr [esp + 0x18], eax
  66625e: e8 8d 91 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  666263: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  666267: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  66626d: c7 44 24 04 04 00 00 00      	mov	dword ptr [esp + 0x4], 0x4
  666275: 89 3c 24                     	mov	dword ptr [esp], edi
  666278: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  66627c: 66 0f ef c0                  	pxor	xmm0, xmm0
  666280: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  666286: 89 44 24 1c                  	mov	dword ptr [esp + 0x1c], eax
  66628a: e8 61 91 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  66628f: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  666293: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  666299: c7 44 24 04 05 00 00 00      	mov	dword ptr [esp + 0x4], 0x5
  6662a1: 89 3c 24                     	mov	dword ptr [esp], edi
  6662a4: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  6662a8: 66 0f ef c0                  	pxor	xmm0, xmm0
  6662ac: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6662b2: 89 44 24 20                  	mov	dword ptr [esp + 0x20], eax
  6662b6: e8 35 91 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6662bb: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6662bf: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6662c5: c7 44 24 04 06 00 00 00      	mov	dword ptr [esp + 0x4], 0x6
  6662cd: 89 3c 24                     	mov	dword ptr [esp], edi
  6662d0: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  6662d4: 66 0f ef c0                  	pxor	xmm0, xmm0
  6662d8: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6662de: 89 44 24 24                  	mov	dword ptr [esp + 0x24], eax
  6662e2: e8 09 91 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6662e7: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6662eb: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6662f1: c7 44 24 04 07 00 00 00      	mov	dword ptr [esp + 0x4], 0x7
  6662f9: 89 3c 24                     	mov	dword ptr [esp], edi
  6662fc: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  666300: 66 0f ef c0                  	pxor	xmm0, xmm0
  666304: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  66630a: 89 44 24 28                  	mov	dword ptr [esp + 0x28], eax
  66630e: e8 dd 90 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  666313: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  666317: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  66631d: 8d 4c 24 24                  	lea	ecx, [esp + 0x24]
  666321: 8d 54 24 10                  	lea	edx, [esp + 0x10]
  666325: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  666329: 89 44 24 10                  	mov	dword ptr [esp + 0x10], eax
  66632d: 8d 44 24 28                  	lea	eax, [esp + 0x28]
  666331: 52                           	push	edx
  666332: 50                           	push	eax
  666333: 51                           	push	ecx
  666334: 8b ce                        	mov	ecx, esi
  666336: 8d 54 24 2c                  	lea	edx, [esp + 0x2c]
  66633a: 52                           	push	edx
  66633b: 8d 44 24 2c                  	lea	eax, [esp + 0x2c]
  66633f: 50                           	push	eax
  666340: 8d 54 24 2c                  	lea	edx, [esp + 0x2c]
  666344: 52                           	push	edx
  666345: e8 a6 46 f8 ff               	call	0x5ea9f0 <.text+0x1e99f0>
  66634a: f2 0f 2a 44 24 18            	cvtsi2sd	xmm0, dword ptr [esp + 0x18]
  666350: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  666356: 89 3c 24                     	mov	dword ptr [esp], edi
  666359: e8 c2 94 22 00               	call	0x88f820 <.text+0x48e820>
  66635e: f2 0f 2a 44 24 1c            	cvtsi2sd	xmm0, dword ptr [esp + 0x1c]
  666364: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  66636a: 89 3c 24                     	mov	dword ptr [esp], edi
  66636d: e8 ae 94 22 00               	call	0x88f820 <.text+0x48e820>
  666372: f2 0f 2a 44 24 20            	cvtsi2sd	xmm0, dword ptr [esp + 0x20]
  666378: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  66637e: 89 3c 24                     	mov	dword ptr [esp], edi
  666381: e8 9a 94 22 00               	call	0x88f820 <.text+0x48e820>
  666386: f2 0f 2a 44 24 24            	cvtsi2sd	xmm0, dword ptr [esp + 0x24]
  66638c: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  666392: 89 3c 24                     	mov	dword ptr [esp], edi
  666395: e8 86 94 22 00               	call	0x88f820 <.text+0x48e820>
  66639a: f2 0f 2a 44 24 28            	cvtsi2sd	xmm0, dword ptr [esp + 0x28]
  6663a0: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  6663a6: 89 3c 24                     	mov	dword ptr [esp], edi
  6663a9: e8 72 94 22 00               	call	0x88f820 <.text+0x48e820>
  6663ae: f2 0f 2a 44 24 10            	cvtsi2sd	xmm0, dword ptr [esp + 0x10]
  6663b4: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  6663ba: 89 3c 24                     	mov	dword ptr [esp], edi
  6663bd: e8 5e 94 22 00               	call	0x88f820 <.text+0x48e820>
  6663c2: b8 06 00 00 00               	mov	eax, 0x6
  6663c7: 83 c4 38                     	add	esp, 0x38
  6663ca: 5e                           	pop	esi
  6663cb: 5f                           	pop	edi
  6663cc: 8b e5                        	mov	esp, ebp
  6663ce: 5d                           	pop	ebp
  6663cf: c3                           	ret
  6663d0: 53                           	push	ebx
  6663d1: 83 ec 0c                     	sub	esp, 0xc
  6663d4: 8b 5c 24 14                  	mov	ebx, dword ptr [esp + 0x14]
  6663d8: 6a 00                        	push	0x0
  6663da: 6a 01                        	push	0x1
  6663dc: 53                           	push	ebx
  6663dd: e8 8e 90 22 00               	call	0x88f470 <.text+0x48e470>
  6663e2: 83 c4 0c                     	add	esp, 0xc
  6663e5: 8b c8                        	mov	ecx, eax
  6663e7: e8 e4 46 f8 ff               	call	0x5eaad0 <.text+0x1e9ad0>
  6663ec: dd 5c 24 04                  	fstp	qword ptr [esp + 0x4]
  6663f0: 89 1c 24                     	mov	dword ptr [esp], ebx
  6663f3: e8 28 94 22 00               	call	0x88f820 <.text+0x48e820>
  6663f8: b8 01 00 00 00               	mov	eax, 0x1
  6663fd: 83 c4 0c                     	add	esp, 0xc
  666400: 5b                           	pop	ebx
  666401: c3                           	ret
  666402: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  666409: 8d bc 27 00 00 00 00         	lea	edi, [edi + eiz]
  666410: 55                           	push	ebp
  666411: 8b ec                        	mov	ebp, esp
  666413: 83 e4 c0                     	and	esp, -0x40
  666416: 57                           	push	edi
  666417: 56                           	push	esi
  666418: 53                           	push	ebx
  666419: 83 ec 34                     	sub	esp, 0x34
  66641c: 8b 7d 08                     	mov	edi, dword ptr [ebp + 0x8]
  66641f: 6a 00                        	push	0x0
  666421: 6a 01                        	push	0x1
  666423: 57                           	push	edi
  666424: e8 47 90 22 00               	call	0x88f470 <.text+0x48e470>
  666429: 83 c4 0c                     	add	esp, 0xc
  66642c: 89 44 24 18                  	mov	dword ptr [esp + 0x18], eax
  666430: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  666438: 89 3c 24                     	mov	dword ptr [esp], edi
  66643b: 66 0f ef c0                  	pxor	xmm0, xmm0
  66643f: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  666445: e8 a6 8f 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  66644a: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  66644e: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  666454: c7 44 24 04 03 00 00 00      	mov	dword ptr [esp + 0x4], 0x3
  66645c: 89 3c 24                     	mov	dword ptr [esp], edi
  66645f: f2 0f 2c f0                  	cvttsd2si	esi, xmm0
  666463: 66 0f ef c0                  	pxor	xmm0, xmm0
  666467: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  66646d: e8 7e 8f 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  666472: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  666476: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  66647c: c7 44 24 04 04 00 00 00      	mov	dword ptr [esp + 0x4], 0x4
  666484: 89 3c 24                     	mov	dword ptr [esp], edi
  666487: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  66648b: 66 0f ef c0                  	pxor	xmm0, xmm0
  66648f: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  666495: 89 44 24 1c                  	mov	dword ptr [esp + 0x1c], eax
  666499: e8 52 8f 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  66649e: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6664a2: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6664a8: c7 44 24 04 05 00 00 00      	mov	dword ptr [esp + 0x4], 0x5
  6664b0: 89 3c 24                     	mov	dword ptr [esp], edi
  6664b3: f2 0f 2c d8                  	cvttsd2si	ebx, xmm0
  6664b7: 66 0f ef c0                  	pxor	xmm0, xmm0
  6664bb: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6664c1: e8 2a 8f 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6664c6: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6664ca: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6664d0: c7 44 24 04 06 00 00 00      	mov	dword ptr [esp + 0x4], 0x6
  6664d8: 89 3c 24                     	mov	dword ptr [esp], edi
  6664db: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  6664df: 66 0f ef c0                  	pxor	xmm0, xmm0
  6664e3: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6664e9: 89 44 24 24                  	mov	dword ptr [esp + 0x24], eax
  6664ed: e8 fe 8e 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6664f2: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6664f6: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6664fc: c7 44 24 04 07 00 00 00      	mov	dword ptr [esp + 0x4], 0x7
  666504: 89 3c 24                     	mov	dword ptr [esp], edi
  666507: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  66650b: 66 0f ef c0                  	pxor	xmm0, xmm0
  66650f: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  666515: 89 44 24 20                  	mov	dword ptr [esp + 0x20], eax
  666519: e8 d2 8e 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  66651e: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  666522: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  666528: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  66652c: 50                           	push	eax
  66652d: ff 74 24 24                  	push	dword ptr [esp + 0x24]
  666531: ff 74 24 2c                  	push	dword ptr [esp + 0x2c]
  666535: 53                           	push	ebx
  666536: ff 74 24 2c                  	push	dword ptr [esp + 0x2c]
  66653a: 56                           	push	esi
  66653b: 8b 4c 24 30                  	mov	ecx, dword ptr [esp + 0x30]
  66653f: e8 ec 45 f8 ff               	call	0x5eab30 <.text+0x1e9b30>
  666544: 33 c0                        	xor	eax, eax
  666546: 83 c4 34                     	add	esp, 0x34
  666549: 5b                           	pop	ebx
  66654a: 5e                           	pop	esi
  66654b: 5f                           	pop	edi
  66654c: 8b e5                        	mov	esp, ebp
  66654e: 5d                           	pop	ebp
  66654f: c3                           	ret
  666550: 55                           	push	ebp
  666551: 8b ec                        	mov	ebp, esp
  666553: 83 e4 c0                     	and	esp, -0x40
  666556: 57                           	push	edi
  666557: 56                           	push	esi
  666558: 83 ec 38                     	sub	esp, 0x38
  66655b: 8b 7d 08                     	mov	edi, dword ptr [ebp + 0x8]
  66655e: 6a 00                        	push	0x0
  666560: 6a 01                        	push	0x1
  666562: 57                           	push	edi
  666563: e8 08 8f 22 00               	call	0x88f470 <.text+0x48e470>
  666568: 83 c4 0c                     	add	esp, 0xc
  66656b: 8b f0                        	mov	esi, eax
  66656d: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  666575: 89 3c 24                     	mov	dword ptr [esp], edi
  666578: 66 0f ef c0                  	pxor	xmm0, xmm0
  66657c: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  666582: e8 69 8e 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  666587: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  66658b: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  666591: c7 44 24 04 03 00 00 00      	mov	dword ptr [esp + 0x4], 0x3
  666599: 89 3c 24                     	mov	dword ptr [esp], edi
  66659c: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  6665a0: 66 0f ef c0                  	pxor	xmm0, xmm0
  6665a4: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6665aa: 89 44 24 18                  	mov	dword ptr [esp + 0x18], eax
  6665ae: e8 3d 8e 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6665b3: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6665b7: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6665bd: c7 44 24 04 04 00 00 00      	mov	dword ptr [esp + 0x4], 0x4
  6665c5: 89 3c 24                     	mov	dword ptr [esp], edi
  6665c8: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  6665cc: 66 0f ef c0                  	pxor	xmm0, xmm0
  6665d0: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6665d6: 89 44 24 1c                  	mov	dword ptr [esp + 0x1c], eax
  6665da: e8 11 8e 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6665df: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6665e3: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6665e9: c7 44 24 04 05 00 00 00      	mov	dword ptr [esp + 0x4], 0x5
  6665f1: 89 3c 24                     	mov	dword ptr [esp], edi
  6665f4: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  6665f8: 66 0f ef c0                  	pxor	xmm0, xmm0
  6665fc: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  666602: 89 44 24 20                  	mov	dword ptr [esp + 0x20], eax
  666606: e8 e5 8d 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  66660b: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  66660f: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  666615: c7 44 24 04 06 00 00 00      	mov	dword ptr [esp + 0x4], 0x6
  66661d: 89 3c 24                     	mov	dword ptr [esp], edi
  666620: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  666624: 66 0f ef c0                  	pxor	xmm0, xmm0
  666628: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  66662e: 89 44 24 24                  	mov	dword ptr [esp + 0x24], eax
  666632: e8 b9 8d 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  666637: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  66663b: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  666641: c7 44 24 04 07 00 00 00      	mov	dword ptr [esp + 0x4], 0x7
  666649: 89 3c 24                     	mov	dword ptr [esp], edi
  66664c: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  666650: 66 0f ef c0                  	pxor	xmm0, xmm0
  666654: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  66665a: 89 44 24 28                  	mov	dword ptr [esp + 0x28], eax
  66665e: e8 8d 8d 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  666663: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  666667: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  66666d: 8d 4c 24 24                  	lea	ecx, [esp + 0x24]
  666671: 8d 54 24 10                  	lea	edx, [esp + 0x10]
  666675: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  666679: 89 44 24 10                  	mov	dword ptr [esp + 0x10], eax
  66667d: 8d 44 24 28                  	lea	eax, [esp + 0x28]
  666681: 52                           	push	edx
  666682: 50                           	push	eax
  666683: 51                           	push	ecx
  666684: 8b ce                        	mov	ecx, esi
  666686: 8d 54 24 2c                  	lea	edx, [esp + 0x2c]
  66668a: 52                           	push	edx
  66668b: 8d 44 24 2c                  	lea	eax, [esp + 0x2c]
  66668f: 50                           	push	eax
  666690: 8d 54 24 2c                  	lea	edx, [esp + 0x2c]
  666694: 52                           	push	edx
  666695: e8 16 45 f8 ff               	call	0x5eabb0 <.text+0x1e9bb0>
  66669a: f2 0f 2a 44 24 18            	cvtsi2sd	xmm0, dword ptr [esp + 0x18]
  6666a0: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  6666a6: 89 3c 24                     	mov	dword ptr [esp], edi
  6666a9: e8 72 91 22 00               	call	0x88f820 <.text+0x48e820>
  6666ae: f2 0f 2a 44 24 1c            	cvtsi2sd	xmm0, dword ptr [esp + 0x1c]
  6666b4: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  6666ba: 89 3c 24                     	mov	dword ptr [esp], edi
  6666bd: e8 5e 91 22 00               	call	0x88f820 <.text+0x48e820>
  6666c2: f2 0f 2a 44 24 20            	cvtsi2sd	xmm0, dword ptr [esp + 0x20]
  6666c8: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  6666ce: 89 3c 24                     	mov	dword ptr [esp], edi
  6666d1: e8 4a 91 22 00               	call	0x88f820 <.text+0x48e820>
  6666d6: f2 0f 2a 44 24 24            	cvtsi2sd	xmm0, dword ptr [esp + 0x24]
  6666dc: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  6666e2: 89 3c 24                     	mov	dword ptr [esp], edi
  6666e5: e8 36 91 22 00               	call	0x88f820 <.text+0x48e820>
  6666ea: f2 0f 2a 44 24 28            	cvtsi2sd	xmm0, dword ptr [esp + 0x28]
  6666f0: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  6666f6: 89 3c 24                     	mov	dword ptr [esp], edi
  6666f9: e8 22 91 22 00               	call	0x88f820 <.text+0x48e820>
  6666fe: f2 0f 2a 44 24 10            	cvtsi2sd	xmm0, dword ptr [esp + 0x10]
  666704: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  66670a: 89 3c 24                     	mov	dword ptr [esp], edi
  66670d: e8 0e 91 22 00               	call	0x88f820 <.text+0x48e820>
  666712: b8 06 00 00 00               	mov	eax, 0x6
  666717: 83 c4 38                     	add	esp, 0x38
  66671a: 5e                           	pop	esi
  66671b: 5f                           	pop	edi
  66671c: 8b e5                        	mov	esp, ebp
  66671e: 5d                           	pop	ebp
  66671f: c3                           	ret
  666720: 55                           	push	ebp
  666721: 8b ec                        	mov	ebp, esp
  666723: 83 e4 c0                     	and	esp, -0x40
  666726: 57                           	push	edi
  666727: 56                           	push	esi
  666728: 53                           	push	ebx
  666729: 83 ec 34                     	sub	esp, 0x34
  66672c: 8b 7d 08                     	mov	edi, dword ptr [ebp + 0x8]
  66672f: 6a 00                        	push	0x0
  666731: 6a 01                        	push	0x1
  666733: 57                           	push	edi
  666734: e8 37 8d 22 00               	call	0x88f470 <.text+0x48e470>
  666739: 83 c4 0c                     	add	esp, 0xc
  66673c: 89 44 24 18                  	mov	dword ptr [esp + 0x18], eax
  666740: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  666748: 89 3c 24                     	mov	dword ptr [esp], edi
  66674b: 66 0f ef c0                  	pxor	xmm0, xmm0
  66674f: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  666755: e8 96 8c 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  66675a: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  66675e: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  666764: c7 44 24 04 03 00 00 00      	mov	dword ptr [esp + 0x4], 0x3
  66676c: 89 3c 24                     	mov	dword ptr [esp], edi
  66676f: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  666773: 66 0f ef c0                  	pxor	xmm0, xmm0
  666777: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  66677d: 89 44 24 28                  	mov	dword ptr [esp + 0x28], eax
  666781: e8 6a 8c 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  666786: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  66678a: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  666790: c7 44 24 04 04 00 00 00      	mov	dword ptr [esp + 0x4], 0x4
  666798: 89 3c 24                     	mov	dword ptr [esp], edi
  66679b: f2 0f 2c d8                  	cvttsd2si	ebx, xmm0
  66679f: 66 0f ef c0                  	pxor	xmm0, xmm0
  6667a3: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6667a9: e8 42 8c 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6667ae: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6667b2: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6667b8: c7 44 24 04 05 00 00 00      	mov	dword ptr [esp + 0x4], 0x5
  6667c0: 89 3c 24                     	mov	dword ptr [esp], edi
  6667c3: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  6667c7: 66 0f ef c0                  	pxor	xmm0, xmm0
  6667cb: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6667d1: 89 44 24 24                  	mov	dword ptr [esp + 0x24], eax
  6667d5: e8 16 8c 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6667da: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6667de: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6667e4: c7 44 24 04 06 00 00 00      	mov	dword ptr [esp + 0x4], 0x6
  6667ec: 89 3c 24                     	mov	dword ptr [esp], edi
  6667ef: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  6667f3: 66 0f ef c0                  	pxor	xmm0, xmm0
  6667f7: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6667fd: 89 44 24 20                  	mov	dword ptr [esp + 0x20], eax
  666801: e8 ea 8b 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  666806: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  66680a: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  666810: c7 44 24 04 07 00 00 00      	mov	dword ptr [esp + 0x4], 0x7
  666818: 89 3c 24                     	mov	dword ptr [esp], edi
  66681b: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  66681f: 66 0f ef c0                  	pxor	xmm0, xmm0
  666823: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  666829: 89 44 24 1c                  	mov	dword ptr [esp + 0x1c], eax
  66682d: e8 be 8b 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  666832: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  666836: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  66683c: c7 44 24 04 08 00 00 00      	mov	dword ptr [esp + 0x4], 0x8
  666844: 89 3c 24                     	mov	dword ptr [esp], edi
  666847: f2 0f 2c f0                  	cvttsd2si	esi, xmm0
  66684b: 66 0f ef c0                  	pxor	xmm0, xmm0
  66684f: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  666855: e8 96 8b 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  66685a: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  66685e: 6a 01                        	push	0x1
  666860: 6a 09                        	push	0x9
  666862: 57                           	push	edi
  666863: e8 98 8c 22 00               	call	0x88f500 <.text+0x48e500>
  666868: 83 c4 0c                     	add	esp, 0xc
  66686b: 83 c4 dc                     	add	esp, -0x24
  66686e: dd 44 24 34                  	fld	qword ptr [esp + 0x34]
  666872: 8b 54 24 4c                  	mov	edx, dword ptr [esp + 0x4c]
  666876: 8b 7c 24 44                  	mov	edi, dword ptr [esp + 0x44]
  66687a: 8b 4c 24 40                  	mov	ecx, dword ptr [esp + 0x40]
  66687e: dd 5c 24 18                  	fstp	qword ptr [esp + 0x18]
  666882: 89 14 24                     	mov	dword ptr [esp], edx
  666885: 85 c0                        	test	eax, eax
  666887: 89 5c 24 04                  	mov	dword ptr [esp + 0x4], ebx
  66688b: 8b 5c 24 48                  	mov	ebx, dword ptr [esp + 0x48]
  66688f: 89 5c 24 08                  	mov	dword ptr [esp + 0x8], ebx
  666893: 89 7c 24 0c                  	mov	dword ptr [esp + 0xc], edi
  666897: 89 4c 24 10                  	mov	dword ptr [esp + 0x10], ecx
  66689b: 8b 4c 24 3c                  	mov	ecx, dword ptr [esp + 0x3c]
  66689f: 89 74 24 14                  	mov	dword ptr [esp + 0x14], esi
  6668a3: be 01 00 00 00               	mov	esi, 0x1
  6668a8: 0f 45 c6                     	cmovne	eax, esi
  6668ab: 88 44 24 20                  	mov	byte ptr [esp + 0x20], al
  6668af: e8 6c 43 f8 ff               	call	0x5eac20 <.text+0x1e9c20>
  6668b4: 33 c0                        	xor	eax, eax
  6668b6: 83 c4 34                     	add	esp, 0x34
  6668b9: 5b                           	pop	ebx
  6668ba: 5e                           	pop	esi
  6668bb: 5f                           	pop	edi
  6668bc: 8b e5                        	mov	esp, ebp
  6668be: 5d                           	pop	ebp
  6668bf: c3                           	ret
  6668c0: 56                           	push	esi
  6668c1: 55                           	push	ebp
  6668c2: 83 ec 18                     	sub	esp, 0x18
  6668c5: 8b 74 24 24                  	mov	esi, dword ptr [esp + 0x24]
  6668c9: 6a 00                        	push	0x0
  6668cb: 6a 01                        	push	0x1
  6668cd: 56                           	push	esi
  6668ce: e8 9d 8b 22 00               	call	0x88f470 <.text+0x48e470>
  6668d3: 83 c4 0c                     	add	esp, 0xc
  6668d6: 8b e8                        	mov	ebp, eax
  6668d8: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  6668e0: 89 34 24                     	mov	dword ptr [esp], esi
  6668e3: 66 0f ef c0                  	pxor	xmm0, xmm0
  6668e7: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  6668ed: e8 fe 8a 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  6668f2: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  6668f6: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  6668fc: 8b cd                        	mov	ecx, ebp
  6668fe: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  666902: 50                           	push	eax
  666903: e8 18 45 f8 ff               	call	0x5eae20 <.text+0x1e9e20>
  666908: 33 c0                        	xor	eax, eax
  66690a: 83 c4 18                     	add	esp, 0x18
  66690d: 5d                           	pop	ebp
  66690e: 5e                           	pop	esi
  66690f: c3                           	ret
  666910: 53                           	push	ebx
  666911: 83 ec 0c                     	sub	esp, 0xc
  666914: 8b 5c 24 14                  	mov	ebx, dword ptr [esp + 0x14]
  666918: 6a 00                        	push	0x0
  66691a: 6a 01                        	push	0x1
  66691c: 53                           	push	ebx
  66691d: e8 4e 8b 22 00               	call	0x88f470 <.text+0x48e470>
  666922: 83 c4 0c                     	add	esp, 0xc
  666925: 8b c8                        	mov	ecx, eax
  666927: e8 54 45 f8 ff               	call	0x5eae80 <.text+0x1e9e80>
  66692c: f2 0f 2a c0                  	cvtsi2sd	xmm0, eax
  666930: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  666936: 89 1c 24                     	mov	dword ptr [esp], ebx
  666939: e8 e2 8e 22 00               	call	0x88f820 <.text+0x48e820>
  66693e: b8 01 00 00 00               	mov	eax, 0x1
  666943: 83 c4 0c                     	add	esp, 0xc
  666946: 5b                           	pop	ebx
  666947: c3                           	ret
  666948: 90                           	nop
  666949: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  666950: 56                           	push	esi
  666951: 55                           	push	ebp
  666952: 83 ec 18                     	sub	esp, 0x18
  666955: 8b 74 24 24                  	mov	esi, dword ptr [esp + 0x24]
  666959: 6a 00                        	push	0x0
  66695b: 6a 01                        	push	0x1
  66695d: 56                           	push	esi
  66695e: e8 0d 8b 22 00               	call	0x88f470 <.text+0x48e470>
  666963: 83 c4 0c                     	add	esp, 0xc
  666966: 8b e8                        	mov	ebp, eax
  666968: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  666970: 89 34 24                     	mov	dword ptr [esp], esi
  666973: 66 0f ef c0                  	pxor	xmm0, xmm0
  666977: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  66697d: e8 6e 8a 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  666982: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  666986: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  66698c: 8b cd                        	mov	ecx, ebp
  66698e: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  666992: 50                           	push	eax
  666993: e8 18 45 f8 ff               	call	0x5eaeb0 <.text+0x1e9eb0>
  666998: 33 c0                        	xor	eax, eax
  66699a: 83 c4 18                     	add	esp, 0x18
  66699d: 5d                           	pop	ebp
  66699e: 5e                           	pop	esi
  66699f: c3                           	ret
  6669a0: 53                           	push	ebx
  6669a1: 83 ec 0c                     	sub	esp, 0xc
  6669a4: 8b 5c 24 14                  	mov	ebx, dword ptr [esp + 0x14]
  6669a8: 6a 00                        	push	0x0
  6669aa: 6a 01                        	push	0x1
  6669ac: 53                           	push	ebx
  6669ad: e8 be 8a 22 00               	call	0x88f470 <.text+0x48e470>
  6669b2: 83 c4 0c                     	add	esp, 0xc
  6669b5: 8b c8                        	mov	ecx, eax
  6669b7: e8 64 45 f8 ff               	call	0x5eaf20 <.text+0x1e9f20>
  6669bc: f2 0f 2a c0                  	cvtsi2sd	xmm0, eax
  6669c0: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  6669c6: 89 1c 24                     	mov	dword ptr [esp], ebx
  6669c9: e8 52 8e 22 00               	call	0x88f820 <.text+0x48e820>
  6669ce: b8 01 00 00 00               	mov	eax, 0x1
  6669d3: 83 c4 0c                     	add	esp, 0xc
  6669d6: 5b                           	pop	ebx
  6669d7: c3                           	ret
  6669d8: 90                           	nop
  6669d9: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
  6669e0: 56                           	push	esi
  6669e1: 55                           	push	ebp
  6669e2: 83 ec 18                     	sub	esp, 0x18
  6669e5: 8b 74 24 24                  	mov	esi, dword ptr [esp + 0x24]
  6669e9: 6a 00                        	push	0x0
  6669eb: 6a 01                        	push	0x1
  6669ed: 56                           	push	esi
  6669ee: e8 7d 8a 22 00               	call	0x88f470 <.text+0x48e470>
  6669f3: 83 c4 0c                     	add	esp, 0xc
  6669f6: 8b e8                        	mov	ebp, eax
  6669f8: c7 44 24 04 02 00 00 00      	mov	dword ptr [esp + 0x4], 0x2
  666a00: 89 34 24                     	mov	dword ptr [esp], esi
  666a03: 66 0f ef c0                  	pxor	xmm0, xmm0
  666a07: f2 0f 11 44 24 08            	movsd	qword ptr [esp + 0x8], xmm0
  666a0d: e8 de 89 22 00               	call	0x88f3f0 <.text+0x48e3f0>
  666a12: dd 5c 24 10                  	fstp	qword ptr [esp + 0x10]
  666a16: f2 0f 10 44 24 10            	movsd	xmm0, qword ptr [esp + 0x10]
  666a1c: 8b cd                        	mov	ecx, ebp
  666a1e: f2 0f 2c c0                  	cvttsd2si	eax, xmm0
  666a22: 50                           	push	eax
  666a23: e8 28 45 f8 ff               	call	0x5eaf50 <.text+0x1e9f50>
  666a28: 33 c0                        	xor	eax, eax
  666a2a: 83 c4 18                     	add	esp, 0x18
  666a2d: 5d                           	pop	ebp
  666a2e: 5e                           	pop	esi
  666a2f: c3                           	ret
  666a30: 53                           	push	ebx
  666a31: 83 ec 0c                     	sub	esp, 0xc
  666a34: 8b 5c 24 14                  	mov	ebx, dword ptr [esp + 0x14]
  666a38: 6a 00                        	push	0x0
  666a3a: 6a 01                        	push	0x1
  666a3c: 53                           	push	ebx
  666a3d: e8 2e 8a 22 00               	call	0x88f470 <.text+0x48e470>
  666a42: 83 c4 0c                     	add	esp, 0xc
  666a45: 8b c8                        	mov	ecx, eax
  666a47: e8 74 45 f8 ff               	call	0x5eafc0 <.text+0x1e9fc0>
  666a4c: f2 0f 2a c0                  	cvtsi2sd	xmm0, eax
  666a50: f2 0f 11 44 24 04            	movsd	qword ptr [esp + 0x4], xmm0
  666a56: 89 1c 24                     	mov	dword ptr [esp], ebx
  666a59: e8 c2 8d 22 00               	call	0x88f820 <.text+0x48e820>
  666a5e: b8 01 00 00 00               	mov	eax, 0x1
  666a63: 83 c4 0c                     	add	esp, 0xc
  666a66: 5b                           	pop	ebx
  666a67: c3                           	ret
  666a68: 90                           	nop
  666a69: 8d b4 26 00 00 00 00         	lea	esi, [esi + eiz]
